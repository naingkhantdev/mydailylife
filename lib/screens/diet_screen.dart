import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../providers/diet_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/calorie_summary.dart';
import '../widgets/meal_input_card.dart';
import '../widgets/section_heading.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(dailyLogProvider);
    final controller = ref.read(dailyLogProvider.notifier);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.diet),
      appBar: AppBar(title: const Text('Diet & Calories')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          CalorieSummary(totalCalories: log.totalCalories),
          const SizedBox(height: 26),
          const SectionHeading(
            eyebrow: 'TODAY\'S MEALS',
            title: 'What you\'ve logged',
          ),
          const SizedBox(height: 14),
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
