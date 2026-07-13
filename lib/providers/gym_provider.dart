import 'package:flutter_riverpod/flutter_riverpod.dart';

final gymPlanProvider = Provider<List<GymDay>>((ref) {
  return const [
    GymDay(
      weekday: 1,
      title: 'Push 1',
      focus: 'Chest, Shoulders, Triceps',
      exercises: [
        'Bench press',
        'Incline dumbbell press',
        'Shoulder press',
        'Lateral raises',
        'Triceps pushdowns',
      ],
    ),
    GymDay(
      weekday: 2,
      title: 'Pull 1',
      focus: 'Back, Rear Delts, Biceps',
      exercises: [
        'Pull-ups or lat pulldown',
        'Barbell rows',
        'Seated cable rows',
        'Face pulls',
        'Biceps curls',
      ],
    ),
    GymDay(
      weekday: 3,
      title: 'Legs 1 & Core',
      focus: 'Quads, Calves, Abs',
      exercises: [
        'Squats',
        'Leg press',
        'Leg extensions',
        'Standing calf raises',
        'Plank',
      ],
    ),
    GymDay(
      weekday: 4,
      title: 'Push 2',
      focus: 'Chest, Shoulders, Triceps',
      exercises: [
        'Incline bench press',
        'Machine chest press',
        'Arnold press',
        'Cable fly',
        'Overhead triceps extension',
      ],
    ),
    GymDay(
      weekday: 5,
      title: 'Pull 2',
      focus: 'Back, Biceps',
      exercises: [
        'Deadlift or rack pull',
        'Chest-supported row',
        'Single-arm pulldown',
        'Hammer curls',
        'Preacher curls',
      ],
    ),
    GymDay(
      weekday: 6,
      title: 'Legs 2 & Core',
      focus: 'Hamstrings, Glutes, Abs',
      exercises: [
        'Romanian deadlift',
        'Hip thrust',
        'Hamstring curls',
        'Walking lunges',
        'Hanging knee raises',
      ],
    ),
    GymDay(
      weekday: 7,
      title: 'Rest & Recovery',
      focus: 'Mobility, walking, sleep',
      exercises: [
        'Light walk',
        'Stretching',
        'Meal prep',
      ],
    ),
  ];
});

final todayGymProvider = Provider<GymDay>((ref) {
  final plan = ref.watch(gymPlanProvider);
  final weekday = DateTime.now().weekday;
  return plan.firstWhere((day) => day.weekday == weekday);
});

class GymDay {
  const GymDay({
    required this.weekday,
    required this.title,
    required this.focus,
    required this.exercises,
  });

  final int weekday;
  final String title;
  final String focus;
  final List<String> exercises;
}
