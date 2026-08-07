import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/routine_history_model.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

final historyProvider =
    StateNotifierProvider<HistoryController, Map<String, RoutineHistoryEntry>>(
  (ref) => HistoryController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  ),
);

final currentWeightLbProvider = StateProvider<double>((ref) => 190);

class HistoryController
    extends StateNotifier<Map<String, RoutineHistoryEntry>> {
  HistoryController({
    required FirestoreService firestoreService,
    required String userId,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        super(const {}) {
    _loadHistory();
  }

  final FirestoreService _firestoreService;
  final String _userId;

  void markDone(TaskModel task, {String remark = ''}) {
    _record(task: task, status: RoutineStatus.done, remark: remark);
  }

  void markMissed(TaskModel task, String remark) {
    _record(task: task, status: RoutineStatus.missed, remark: remark);
  }

  void clearToday(TaskModel task) {
    final key = _keyFor(DateTime.now(), task.id);
    final next = Map<String, RoutineHistoryEntry>.from(state);
    next.remove(key);
    state = next;
    _deleteEntry(key);
  }

  RoutineHistoryEntry? entryForToday(String taskId) {
    return state[_keyFor(DateTime.now(), taskId)];
  }

  List<RoutineHistoryEntry> get entries {
    final items = state.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  void _record({
    required TaskModel task,
    required RoutineStatus status,
    String remark = '',
  }) {
    final entry = RoutineHistoryEntry(
      taskId: task.id,
      taskTitle: task.title,
      date: DateTime.now(),
      status: status,
      remark: remark,
    );
    state = {
      ...state,
      entry.key: entry,
    };
    _saveEntry(entry);
  }

  Future<void> _loadHistory() async {
    try {
      final entries = await _firestoreService.getRoutineHistory(
        userId: _userId,
      );
      if (!mounted) {
        return;
      }
      state = {
        for (final entry in entries) entry.key: entry,
        ...state,
      };
    } catch (_) {
      // Keep locally entered history available if Firestore cannot be reached.
    }
  }

  Future<void> _saveEntry(RoutineHistoryEntry entry) async {
    try {
      await _firestoreService.saveRoutineHistoryEntry(
        userId: _userId,
        entry: entry,
      );
    } catch (_) {
      // The optimistic local entry remains visible and can be retried later.
    }
  }

  Future<void> _deleteEntry(String key) async {
    try {
      await _firestoreService.deleteRoutineHistoryEntry(
        userId: _userId,
        entryKey: key,
      );
    } catch (_) {
      // The local clear still takes effect for the current session.
    }
  }

  String _keyFor(DateTime date, String taskId) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day:$taskId';
  }
}
