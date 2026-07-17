import 'package:flutter_test/flutter_test.dart';

import 'package:mdr/models/daily_log_model.dart';

void main() {
  group('DailyLogModel', () {
    test('calculates quantities and total daily calories', () {
      final log = DailyLogModel(
        date: DateTime(2026, 7, 17),
        breakfast: const [MealItem(name: 'Egg', calories: 78, quantity: 2)],
        lunch: const [MealItem(name: 'Rice', calories: 205)],
        dinner: const [MealItem(name: 'Chicken', calories: 165, quantity: 2)],
      );

      expect(log.totalCalories, 691);
      expect(log.documentId, '2026-07-17');
      expect(log.toMap()['total_calories'], 691);
    });

    test('round-trips notes and meal data through Firestore maps', () {
      final original = DailyLogModel(
        date: DateTime(2026, 1, 2),
        workNotes: 'Completed the report',
        studyNotes: 'Riverpod',
        gamingNotes: 'One match',
        breakfast: const [
          MealItem(name: 'Oatmeal', calories: 150, quantity: 2),
        ],
      );

      final restored = DailyLogModel.fromMap(original.date, original.toMap());

      expect(restored.workNotes, original.workNotes);
      expect(restored.studyNotes, original.studyNotes);
      expect(restored.gamingNotes, original.gamingNotes);
      expect(restored.breakfast.single.name, 'Oatmeal');
      expect(restored.breakfast.single.quantity, 2);
      expect(restored.totalCalories, 300);
    });

    test('uses safe defaults for incomplete stored data', () {
      final restored = DailyLogModel.fromMap(
        DateTime(2026, 7, 17),
        const {'breakfast': <dynamic>['invalid']},
      );

      expect(restored.workNotes, isEmpty);
      expect(restored.breakfast, isEmpty);
      expect(restored.totalCalories, 0);
    });
  });
}
