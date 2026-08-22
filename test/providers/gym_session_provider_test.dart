import 'package:flutter_test/flutter_test.dart';

import 'package:mdr/providers/gym_session_provider.dart';

void main() {
  group('GymSessionController', () {
    test('uses default targets and toggles completed sets', () {
      final controller = GymSessionController();

      expect(controller.sessionFor('Bench').targetSets, 3);
      // Nothing started yet, so there is no session to count sets out of.
      expect(controller.targetSetCount(['Bench']), 0);

      controller.toggleSet('Bench', 1);
      controller.toggleSet('Bench', 2);
      expect(controller.targetSetCount(['Bench']), 3);
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

    test('completes on the exercises actually started', () {
      final controller = GymSessionController();

      // A day seeds a menu, so an untouched one is not a finished one.
      expect(controller.isWorkoutComplete([]), isFalse);
      expect(controller.isWorkoutComplete(['Bench', 'Fly']), isFalse);

      controller.markExerciseDone('Bench');
      // Fly was never started, so it is not part of today's session.
      expect(controller.startedExercises(['Bench', 'Fly']), ['Bench']);
      expect(controller.isWorkoutComplete(['Bench', 'Fly']), isTrue);

      // Starting it puts the day back in progress until it is finished too.
      controller.toggleSet('Fly', 1);
      expect(controller.isWorkoutComplete(['Bench', 'Fly']), isFalse);
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
