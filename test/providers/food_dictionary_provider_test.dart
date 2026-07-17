import 'package:flutter_test/flutter_test.dart';

import 'package:mdr/models/daily_log_model.dart';
import 'package:mdr/providers/food_dictionary_provider.dart';

void main() {
  group('FoodDictionaryController', () {
    test('remembers new foods without case-insensitive duplicates', () {
      final controller = FoodDictionaryController();
      final initialLength = controller.state.length;

      controller.remember(const MealItem(name: 'Dragon fruit', calories: 60));
      controller.remember(const MealItem(name: 'dragon FRUIT', calories: 70));

      expect(controller.state.length, initialLength + 1);
      expect(
        controller.state.where(
          (food) => food.name.toLowerCase() == 'dragon fruit',
        ),
        hasLength(1),
      );
    });

    test('updates and deletes foods case-insensitively', () {
      final controller = FoodDictionaryController();

      controller.upsert(
        const MealItem(name: 'Morning coffee', calories: 10),
        previousName: 'Coffee',
      );
      expect(
        controller.state.any((food) => food.name == 'Morning coffee'),
        isTrue,
      );
      expect(controller.state.any((food) => food.name == 'Coffee'), isFalse);

      controller.delete('MORNING COFFEE');
      expect(
        controller.state.any((food) => food.name == 'Morning coffee'),
        isFalse,
      );
    });
  });
}
