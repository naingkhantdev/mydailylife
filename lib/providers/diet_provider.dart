import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'sync_status_provider.dart';

final dailyLogProvider =
    StateNotifierProvider<DailyLogController, DailyLogModel>((ref) {
  return DailyLogController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
    syncStatus: ref.watch(syncStatusProvider.notifier),
  );
});

final dailyLogHistoryProvider = FutureProvider<List<DailyLogModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getDailyLogs(
        userId: ref.watch(currentUserIdProvider),
      );
});

class DailyLogController extends StateNotifier<DailyLogModel> {
  DailyLogController({
    required FirestoreService firestoreService,
    required String userId,
    required SyncStatusController syncStatus,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _syncStatus = syncStatus,
        super(DailyLogModel(date: DateTime.now())) {
    _lifecycleListener = AppLifecycleListener(onResume: _rollOverIfNeeded);
    _listenToToday();
  }

  final FirestoreService _firestoreService;
  final String _userId;
  final SyncStatusController _syncStatus;
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription<DailyLogModel?>? _subscription;
  bool _saveInProgress = false;
  bool _saveQueued = false;

  @override
  void dispose() {
    _subscription?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void addMealItem(MealSlot slot, MealItem item) {
    _rollOverIfNeeded();
    switch (slot) {
      case MealSlot.breakfast:
        state = state.copyWith(breakfast: [...state.breakfast, item]);
      case MealSlot.lunch:
        state = state.copyWith(lunch: [...state.lunch, item]);
      case MealSlot.dinner:
        state = state.copyWith(dinner: [...state.dinner, item]);
    }
    _didChange();
  }

  void removeMealItem(MealSlot slot, int index) {
    List<MealItem> removeAt(List<MealItem> items) {
      return [
        for (var i = 0; i < items.length; i++)
          if (i != index) items[i],
      ];
    }

    _rollOverIfNeeded();
    switch (slot) {
      case MealSlot.breakfast:
        state = state.copyWith(breakfast: removeAt(state.breakfast));
      case MealSlot.lunch:
        state = state.copyWith(lunch: removeAt(state.lunch));
      case MealSlot.dinner:
        state = state.copyWith(dinner: removeAt(state.dinner));
    }
    _didChange();
  }

  void updateNotes({
    String? workNotes,
    String? studyNotes,
    String? gamingNotes,
  }) {
    _rollOverIfNeeded();
    state = state.copyWith(
      workNotes: workNotes,
      studyNotes: studyNotes,
      gamingNotes: gamingNotes,
    );
    _didChange();
  }

  void replace(DailyLogModel log) {
    state = log;
    _didChange();
  }

  void _didChange() {
    _queueSave();
  }

  /// Moves the log onto today's document when the date has changed under it.
  ///
  /// The controller is built once and its date came with it, so an app left
  /// open overnight used to write this morning's breakfast into yesterday's
  /// document. Checked before every edit, and again whenever the app is
  /// brought back to the foreground — which is how the day actually turns
  /// over on a phone.
  void _rollOverIfNeeded() {
    final now = DateTime.now();
    if (_dateId(now) == _dateId(state.date)) {
      return;
    }

    // Yesterday is already saved under its own id; start today clean and
    // follow the new document instead.
    state = DailyLogModel(date: now);
    _listenToToday();
  }

  /// Follows today's document rather than reading it once, so a meal logged on
  /// another device appears here without a restart.
  void _listenToToday() {
    _subscription?.cancel();
    final date = state.date;
    _subscription = _firestoreService
        .watchDailyLog(userId: _userId, date: date)
        .listen(
      (log) {
        // Drop anything that arrives for a day we have already left, or while
        // one of our own writes is still on its way out.
        if (!mounted ||
            log == null ||
            _saveInProgress ||
            _saveQueued ||
            _dateId(date) != _dateId(state.date)) {
          return;
        }
        state = log;
      },
      onError: (Object _) {
        // Keep the local day available when Firestore cannot be reached.
      },
    );
  }

  String _dateId(DateTime date) => DailyLogModel(date: date).documentId;

  Future<void> _queueSave() async {
    if (_saveInProgress) {
      _saveQueued = true;
      return;
    }

    _saveInProgress = true;
    do {
      _saveQueued = false;
      final logToSave = state;
      await _syncStatus.track(
        key: 'daily_log:${logToSave.documentId}',
        write: () => _firestoreService.saveDailyLog(
          userId: _userId,
          log: logToSave,
        ),
      );
    } while (mounted && _saveQueued);
    _saveInProgress = false;
  }
}
