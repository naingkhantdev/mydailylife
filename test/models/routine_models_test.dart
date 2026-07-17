import 'package:flutter_test/flutter_test.dart';

import 'package:mdr/models/gym_technique_model.dart';
import 'package:mdr/models/routine_history_model.dart';
import 'package:mdr/models/task_model.dart';

void main() {
  group('TaskModel', () {
    test('checks recurring weekdays and round-trips stored data', () {
      const task = TaskModel(
        id: 'gym',
        title: 'Gym training',
        startTime: '06:00 PM',
        endTime: '07:30 PM',
        recurringDays: [1, 3, 5],
        category: RoutineCategory.gym,
      );

      expect(task.runsOn(DateTime(2026, 7, 17)), isTrue);
      expect(task.runsOn(DateTime(2026, 7, 18)), isFalse);

      final restored = TaskModel.fromMap(task.id, task.toMap());
      expect(restored.title, task.title);
      expect(restored.recurringDays, task.recurringDays);
      expect(restored.category, RoutineCategory.gym);
    });
  });

  group('RoutineHistoryEntry', () {
    test('creates stable date keys and round-trips stored data', () {
      final entry = RoutineHistoryEntry(
        taskId: 'study',
        taskTitle: 'Study',
        date: DateTime(2026, 2, 3, 20, 15),
        status: RoutineStatus.done,
        remark: 'Finished a chapter',
      );

      expect(entry.dateId, '2026-02-03');
      expect(entry.key, '2026-02-03:study');

      final restored = RoutineHistoryEntry.fromMap(entry.toMap());
      expect(restored.key, entry.key);
      expect(restored.status, RoutineStatus.done);
      expect(restored.remark, entry.remark);
    });
  });

  group('GymTechniqueModel', () {
    test('detects custom guides and round-trips stored data', () {
      const technique = GymTechniqueModel(
        id: 'bench-press',
        weekday: 1,
        name: 'Bench press',
        cue: 'Keep shoulder blades back',
      );

      expect(technique.hasCustomGuide, isTrue);

      final restored = GymTechniqueModel.fromMap(
        technique.id,
        technique.toMap(),
      );
      expect(restored.name, technique.name);
      expect(restored.weekday, 1);
      expect(restored.cue, technique.cue);
    });
  });
}
