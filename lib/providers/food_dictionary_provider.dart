import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';

final foodDictionaryProvider =
    StateNotifierProvider<FoodDictionaryController, List<MealItem>>((ref) {
  return FoodDictionaryController();
});

class FoodDictionaryController extends StateNotifier<List<MealItem>> {
  FoodDictionaryController()
      : super(const [
          MealItem(name: 'Boiled egg', calories: 78),
          MealItem(name: 'Rice', calories: 205),
          MealItem(name: 'White rice', calories: 205),
          MealItem(name: 'Fried rice', calories: 333),
          MealItem(name: 'Chicken breast', calories: 165),
          MealItem(name: 'Chicken thigh', calories: 209),
          MealItem(name: 'Fried chicken', calories: 320),
          MealItem(name: 'Banana', calories: 105),
          MealItem(name: 'Oatmeal', calories: 150),
          MealItem(name: 'Milk', calories: 122),
          MealItem(name: 'Apple', calories: 95),
          MealItem(name: 'Protein shake', calories: 180),
          MealItem(name: 'Tuna', calories: 132),
          MealItem(name: 'Peanut butter', calories: 190),
          MealItem(name: 'Bread slice', calories: 80),
          MealItem(name: 'Noodles', calories: 220),
          MealItem(name: 'Instant noodles', calories: 380),
          MealItem(name: 'Potato', calories: 161),
          MealItem(name: 'Sweet potato', calories: 112),
          MealItem(name: 'Avocado', calories: 240),
          MealItem(name: 'Yogurt', calories: 150),
          MealItem(name: 'Cheese slice', calories: 113),
          MealItem(name: 'Beef', calories: 250),
          MealItem(name: 'Pork', calories: 242),
          MealItem(name: 'Salmon', calories: 208),
          MealItem(name: 'Shrimp', calories: 99),
          MealItem(name: 'Vegetables', calories: 80),
          MealItem(name: 'Salad', calories: 120),
          MealItem(name: 'Coffee', calories: 5),
          MealItem(name: 'Tea', calories: 2),
          MealItem(name: 'Orange juice', calories: 112),
        ]);

  void remember(MealItem item) {
    final exists = state.any(
      (food) => food.name.toLowerCase() == item.name.toLowerCase(),
    );
    if (exists) {
      return;
    }

    state = [...state, item];
  }

  void upsert(MealItem item, {String? previousName}) {
    final targetName = previousName ?? item.name;
    final next = [
      for (final food in state)
        if (food.name.toLowerCase() == targetName.toLowerCase()) item else food,
    ];
    final alreadyExists = next.any(
      (food) => food.name.toLowerCase() == item.name.toLowerCase(),
    );

    state = alreadyExists ? next : [...next, item];
  }

  void delete(String name) {
    state = [
      for (final food in state)
        if (food.name.toLowerCase() != name.toLowerCase()) food,
    ];
  }
}
