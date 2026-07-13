import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';

final routineProvider = Provider<List<TaskModel>>((ref) {
  return const [
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
});
