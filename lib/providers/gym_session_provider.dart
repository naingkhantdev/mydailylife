import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_session_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'sync_status_provider.dart';

export '../models/gym_session_model.dart'
    show GymExerciseSession, GymSessionLog;

/// Logged sets, keyed by `YYYY-MM-DD`. Reads and writes go through Firestore,
/// so a tick survives a refresh and past days stay available as history.
final gymSessionProvider =
    StateNotifierProvider<GymSessionController, Map<String, GymSessionLog>>(
  (ref) => GymSessionController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
    syncStatus: ref.watch(syncStatusProvider.notifier),
  ),
);

class GymSessionController extends StateNotifier<Map<String, GymSessionLog>> {
  GymSessionController({
    required FirestoreService firestoreService,
    required String userId,
    required SyncStatusController syncStatus,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _syncStatus = syncStatus,
        super(const {}) {
    _lifecycleListener = AppLifecycleListener(onResume: _followToday);
    _loadSessions();
    _followToday();
  }

  final FirestoreService _firestoreService;
  final String _userId;
  final SyncStatusController _syncStatus;
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription<GymSessionLog?>? _subscription;
  String? _watchedDateId;
  int _pendingWrites = 0;

  static const defaultTargetSets = GymExerciseSession.defaultTargetSets;
  static const defaultTargetReps = GymExerciseSession.defaultTargetReps;

  @override
  void dispose() {
    _subscription?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// Recomputed per call so a session left open past midnight rolls over to a
  /// fresh day instead of writing into yesterday's document.
  String get _todayId => GymSessionLog.dateIdFor(DateTime.now());

  GymSessionLog logFor(DateTime date) {
    final id = GymSessionLog.dateIdFor(date);
    return state[id] ?? GymSessionLog(date: date);
  }

  GymSessionLog get todayLog => logFor(DateTime.now());

  /// Past days first, newest to oldest — today is still in progress.
  List<GymSessionLog> get history {
    final logs = state.values
        .where((log) => log.documentId != _todayId)
        .toList()
      ..sort((a, b) => b.documentId.compareTo(a.documentId));
    return logs;
  }

  GymExerciseSession sessionFor(String exercise) {
    return todayLog.sessionFor(exercise);
  }

  /// The most recent earlier day this exercise carried a weight, so the card
  /// can show what there is to beat. Progressive overload is the point of the
  /// split, and it is invisible without the previous number in front of you.
  GymExerciseSession? lastLoggedSession(String exercise) {
    for (final log in history) {
      final session = log.exercises[exercise];
      if (session != null && session.hasWeight) {
        return session;
      }
    }
    return null;
  }

  bool isExerciseComplete(String exercise) => sessionFor(exercise).isComplete;

  bool isWorkoutComplete(List<String> exercises) {
    if (exercises.isEmpty) {
      return false;
    }
    return exercises.every(isExerciseComplete);
  }

  int completedSetCount(List<String> exercises) {
    return exercises.fold<int>(
      0,
      (total, exercise) => total + sessionFor(exercise).completedSets.length,
    );
  }

  int targetSetCount(List<String> exercises) {
    return exercises.fold<int>(
      0,
      (total, exercise) => total + sessionFor(exercise).targetSets,
    );
  }

  /// Kilograms moved today. Zero until a weight is recorded, which is why the
  /// UI hides it until then.
  ///
  /// Read off the day's log rather than the current plan, so an exercise you
  /// logged and then removed from the split still counts towards today.
  int get todayVolumeKg => todayLog.totalVolumeKg;

  /// The heaviest lifts recorded today, for the summary line.
  List<MapEntry<String, GymExerciseSession>> get todayLoadedExercises {
    return todayLog.loadedExercises;
  }

  void setTarget({
    required String exercise,
    required int sets,
    required int reps,
    double? weightKg,
  }) {
    if (sets <= 0 || reps <= 0) {
      return;
    }

    final current = sessionFor(exercise);
    _write(
      exercise,
      current.copyWith(
        targetSets: sets,
        targetReps: reps,
        weightKg: weightKg != null && weightKg >= 0 ? weightKg : null,
        completedSets: current.completedSets
            .where((setNumber) => setNumber <= sets)
            .toSet(),
      ),
    );
  }

  void toggleSet(String exercise, int setNumber) {
    final current = sessionFor(exercise);
    if (setNumber < 1 || setNumber > current.targetSets) {
      return;
    }

    final completedSets = {...current.completedSets};
    if (completedSets.contains(setNumber)) {
      completedSets.remove(setNumber);
    } else {
      completedSets.add(setNumber);
    }

    _write(exercise, current.copyWith(completedSets: completedSets));
  }

  void markExerciseDone(String exercise) {
    final current = sessionFor(exercise);
    _write(
      exercise,
      current.copyWith(
        completedSets: {
          for (var setNumber = 1; setNumber <= current.targetSets; setNumber++)
            setNumber,
        },
      ),
    );
  }

  /// Unticks every set of one exercise, keeping the target the user chose.
  void clearExercise(String exercise) {
    _write(exercise, sessionFor(exercise).copyWith(completedSets: const {}));
  }

  /// Applies the change locally first, then persists it, so a tick never waits
  /// on the network.
  void _write(String exercise, GymExerciseSession session) {
    final log = todayLog.withExercise(exercise, session);
    state = {
      ...state,
      log.documentId: log,
    };
    _saveLog(log);
  }

  /// Follows today's document, so a set ticked on another device lands here
  /// while the workout is still open — and so a day that turned over while
  /// the app was backgrounded starts watching the new document on resume.
  void _followToday() {
    final todayId = _todayId;
    if (_watchedDateId == todayId && _subscription != null) {
      return;
    }

    _watchedDateId = todayId;
    _subscription?.cancel();
    _subscription = _firestoreService
        .watchGymSession(userId: _userId, date: DateTime.now())
        .listen(
      (log) {
        // Ignore anything arriving while one of our own writes is still on its
        // way out, so a tick is never briefly undone on screen.
        if (!mounted || log == null || _pendingWrites > 0) {
          return;
        }
        state = {...state, log.documentId: log};
      },
      onError: (Object _) {
        // The local session stays usable when Firestore cannot be reached.
      },
    );
  }

  Future<void> _loadSessions() async {
    try {
      final logs = await _firestoreService.getGymSessions(userId: _userId);
      if (!mounted) {
        return;
      }
      // Merged per exercise rather than per day: a tick made while the load
      // was in flight must not drop the sets already saved for that day.
      final merged = {for (final log in logs) log.documentId: log};
      for (final local in state.values) {
        final remote = merged[local.documentId];
        merged[local.documentId] = remote == null
            ? local
            : GymSessionLog(
                date: local.date,
                exercises: {...remote.exercises, ...local.exercises},
              );
      }
      state = merged;
    } catch (_) {
      // Keep the session usable offline; the next tick retries the write.
    }
  }

  Future<void> _saveLog(GymSessionLog log) async {
    final pruned = log.pruned;
    _pendingWrites++;
    try {
      await _syncStatus.track(
        key: 'gym_session:${pruned.documentId}',
        write: () {
          if (pruned.isEmpty) {
            return _firestoreService.deleteGymSession(
              userId: _userId,
              dateId: pruned.documentId,
            );
          }
          return _firestoreService.saveGymSession(
            userId: _userId,
            log: pruned,
          );
        },
      );
    } finally {
      _pendingWrites--;
    }
  }
}
