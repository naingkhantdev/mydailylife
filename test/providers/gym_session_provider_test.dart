import 'package:flutter_test/flutter_test.dart';

import 'package:mdr/providers/gym_session_provider.dart';

void main() {
  group('GymSessionController', () {
    test('uses default targets and toggles completed sets', () {
      final controller = GymSessionController();

      expect(controller.sessionFor('Bench').targetSets, 3);
      expect(controller.targetSetCount(['Bench']), 3);

      controller.toggleSet('Bench', 1);
      controller.toggleSet('Bench', 2);
      expect(controller.completedSetCount(['Bench']), 2);
      expect(controller.isExerciseComplete('Bench'), isFalse);

      controller.toggleSet('Bench', 2);
      expect(controller.completedSetCount(['Bench']), 1);
    });

    test('updates targets and removes completed sets outside the new target', () {
      final controller = GymSessionController();
      controller.markExerciseDone('Squat');

      controller.setTarget(exercise: 'Squat', sets: 2, reps: 8);

      final session = controller.sessionFor('Squat');
      expect(session.targetSets, 2);
      expect(session.targetReps, 8);
      expect(session.completedSets, {1, 2});
      expect(controller.isExerciseComplete('Squat'), isTrue);
    });

    test('requires every exercise for workout completion', () {
      final controller = GymSessionController();
      controller.markExerciseDone('Bench');

      expect(controller.isWorkoutComplete([]), isFalse);
      expect(controller.isWorkoutComplete(['Bench', 'Fly']), isFalse);

      controller.markExerciseDone('Fly');
      expect(controller.isWorkoutComplete(['Bench', 'Fly']), isTrue);
    });

    test('ignores invalid targets and set numbers', () {
      final controller = GymSessionController();
      controller.setTarget(exercise: 'Row', sets: 0, reps: 10);
      controller.toggleSet('Row', 4);

      expect(controller.sessionFor('Row').targetSets, 3);
      expect(controller.completedSetCount(['Row']), 0);
    });
  });
}
