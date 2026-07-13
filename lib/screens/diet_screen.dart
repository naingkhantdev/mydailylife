import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../providers/diet_provider.dart';
import '../widgets/calorie_summary.dart';
import '../widgets/meal_input_card.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(dailyLogProvider);
    final controller = ref.read(dailyLogProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Diet & Calories')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CalorieSummary(totalCalories: log.totalCalories),
          const SizedBox(height: 16),
          MealInputCard(
            title: 'Breakfast',
            items: log.breakfast,
            onAdd: (item) => controller.addMealItem(MealSlot.breakfast, item),
            onRemove: (index) =>
                controller.removeMealItem(MealSlot.breakfast, index),
          ),
          const SizedBox(height: 12),
          MealInputCard(
            title: 'Lunch',
            items: log.lunch,
            onAdd: (item) => controller.addMealItem(MealSlot.lunch, item),
            onRemove: (index) =>
                controller.removeMealItem(MealSlot.lunch, index),
          ),
          const SizedBox(height: 12),
          MealInputCard(
            title: 'Dinner',
            items: log.dinner,
            onAdd: (item) => controller.addMealItem(MealSlot.dinner, item),
            onRemove: (index) =>
                controller.removeMealItem(MealSlot.dinner, index),
          ),
        ],
      ),
    );
  }
}
