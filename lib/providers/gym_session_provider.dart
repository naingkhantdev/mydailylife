import 'package:flutter_riverpod/flutter_riverpod.dart';

final gymSessionProvider =
    StateNotifierProvider<GymSessionController, Map<String, GymExerciseSession>>(
  (ref) => GymSessionController(),
);

class GymSessionController
    extends StateNotifier<Map<String, GymExerciseSession>> {
  GymSessionController() : super(const {});

  static const defaultTargetSets = 3;
  static const defaultTargetReps = 10;

  GymExerciseSession sessionFor(String exercise) {
    return state[exercise] ??
        GymExerciseSession.empty(
          targetSets: defaultTargetSets,
          targetReps: defaultTargetReps,
        );
  }

  bool isExerciseComplete(String exercise) {
    final session = sessionFor(exercise);
    return session.completedSets.length >= session.targetSets;
  }

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

  void setTarget({
    required String exercise,
    required int sets,
    required int reps,
  }) {
    if (sets <= 0 || reps <= 0) {
      return;
    }

    final current = sessionFor(exercise);
    state = {
      ...state,
      exercise: current.copyWith(
        targetSets: sets,
        targetReps: reps,
        completedSets: current.completedSets
            .where((setNumber) => setNumber <= sets)
            .toSet(),
      ),
    };
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

    state = {
      ...state,
      exercise: current.copyWith(completedSets: completedSets),
    };
  }

  void markExerciseDone(String exercise) {
    final current = sessionFor(exercise);
    state = {
      ...state,
      exercise: current.copyWith(
        completedSets: {
          for (var setNumber = 1; setNumber <= current.targetSets; setNumber++)
            setNumber,
        },
      ),
    };
  }
}

class GymExerciseSession {
  const GymExerciseSession({
    required this.targetSets,
    required this.targetReps,
    required this.completedSets,
  });

  factory GymExerciseSession.empty({
    required int targetSets,
    required int targetReps,
  }) {
    return GymExerciseSession(
      targetSets: targetSets,
      targetReps: targetReps,
      completedSets: const {},
    );
  }

  final int targetSets;
  final int targetReps;
  final Set<int> completedSets;

  GymExerciseSession copyWith({
    int? targetSets,
    int? targetReps,
    Set<int>? completedSets,
  }) {
    return GymExerciseSession(
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      completedSets: completedSets ?? this.completedSets,
    );
  }
}
