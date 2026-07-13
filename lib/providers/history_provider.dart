import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/routine_history_model.dart';
import '../models/task_model.dart';

final historyProvider =
    StateNotifierProvider<HistoryController, Map<String, RoutineHistoryEntry>>(
  (ref) => HistoryController(),
);

final currentWeightLbProvider = StateProvider<double>((ref) => 190);

class HistoryController
    extends StateNotifier<Map<String, RoutineHistoryEntry>> {
  HistoryController() : super(const {});

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
  }

  String _keyFor(DateTime date, String taskId) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day:$taskId';
  }
}
