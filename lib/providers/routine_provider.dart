import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../services/firestore_service.dart';
import 'firestore_provider.dart';

final routineProvider =
    StateNotifierProvider<RoutineController, List<TaskModel>>((ref) {
  return RoutineController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

class RoutineController extends StateNotifier<List<TaskModel>> {
  RoutineController({
    required FirestoreService firestoreService,
    required String userId,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        super(_sorted(defaultRoutineTasks)) {
    _loadTasks();
  }

  final FirestoreService _firestoreService;
  final String _userId;
  bool _hasLocalChanges = false;

  Future<void> addTask(TaskModel task) async {
    _hasLocalChanges = true;
    state = _sorted([...state, task]);
    try {
      await _firestoreService.saveTask(userId: _userId, task: task);
    } catch (_) {
      // Keep the optimistic task available while offline.
    }
  }

  Future<void> updateTask(TaskModel task) async {
    _hasLocalChanges = true;
    state = _sorted([
      for (final current in state)
        if (current.id == task.id) task else current,
    ]);
    try {
      await _firestoreService.saveTask(userId: _userId, task: task);
    } catch (_) {
      // Keep the optimistic edit available while offline.
    }
  }

  Future<void> deleteTask(String taskId) async {
    _hasLocalChanges = true;
    state = [for (final task in state) if (task.id != taskId) task];
    try {
      await _firestoreService.deleteTask(userId: _userId, taskId: taskId);
    } catch (_) {
      // Keep the optimistic deletion for the current session.
    }
  }

  Future<void> _loadTasks() async {
    try {
      final savedTasks = await _firestoreService.getTasks(userId: _userId);
      if (!mounted || _hasLocalChanges) {
        return;
      }
      if (savedTasks.isEmpty) {
        await _firestoreService.saveTasks(
          userId: _userId,
          tasks: defaultRoutineTasks,
        );
        return;
      }
      state = _sorted(savedTasks);
    } catch (_) {
      // The unchanged built-in routine remains available while offline.
    }
  }

  static List<TaskModel> _sorted(List<TaskModel> tasks) {
    final sorted = [...tasks];
    sorted.sort((a, b) => _minutes(a.startTime).compareTo(_minutes(b.startTime)));
    return sorted;
  }

  static int _minutes(String label) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(label);
    if (match == null) return 0;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;
    if (hour == 12) hour = 0;
    if (period == 'PM') hour += 12;
    return hour * 60 + minute;
  }
}

const defaultRoutineTasks = [
  TaskModel(
    id: 'breakfast',
    title: 'Breakfast & Calorie Logging',
    startTime: '07:00 AM',
    endTime: '08:00 AM',
    recurringDays: [1, 2, 3, 4, 5, 6, 7],
    category: RoutineCategory.meal,
  ),
  TaskModel(
    id: 'work-focus',
    title: 'Work Focus Mode',
    startTime: '08:00 AM',
    endTime: '12:00 PM',
    recurringDays: [1, 2, 3, 4, 5, 6],
    category: RoutineCategory.work,
  ),
  TaskModel(
    id: 'lunch',
    title: 'Lunch, Calories & Mobile Legends',
    startTime: '12:00 PM',
    endTime: '01:00 PM',
    recurringDays: [1, 2, 3, 4, 5, 6, 7],
    category: RoutineCategory.meal,
  ),
  TaskModel(
    id: 'work-log',
    title: 'Afternoon Work',
    startTime: '01:00 PM',
    endTime: '05:00 PM',
    recurringDays: [1, 2, 3, 4, 5, 6],
    category: RoutineCategory.work,
  ),
  TaskModel(
    id: 'rest',
    title: 'Commute & Rest',
    startTime: '05:00 PM',
    endTime: '06:00 PM',
    recurringDays: [1, 2, 3, 4, 5, 6, 7],
    category: RoutineCategory.rest,
  ),
  TaskModel(
    id: 'gym',
    title: 'Gym Training',
    startTime: '06:00 PM',
    endTime: '07:30 PM',
    recurringDays: [1, 2, 3, 4, 5, 6],
    category: RoutineCategory.gym,
  ),
  TaskModel(
    id: 'dinner',
    title: 'Dinner & Calorie Logging',
    startTime: '07:30 PM',
    endTime: '08:00 PM',
    recurringDays: [1, 2, 3, 4, 5, 6, 7],
    category: RoutineCategory.meal,
  ),
  TaskModel(
    id: 'study',
    title: 'Flutter/Riverpod Study',
    startTime: '08:00 PM',
    endTime: '09:30 PM',
    recurringDays: [1, 2, 3, 4, 5, 6],
    category: RoutineCategory.study,
  ),
  TaskModel(
    id: 'gaming',
    title: 'Gaming Time',
    startTime: '09:30 PM',
    endTime: '11:00 PM',
    recurringDays: [1, 2, 3, 4, 5, 6],
    category: RoutineCategory.gaming,
  ),
];
