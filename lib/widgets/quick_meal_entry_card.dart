import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../providers/diet_provider.dart';
import 'food_manager_modal.dart';

class QuickMealEntryCard extends ConsumerWidget {
  const QuickMealEntryCard({
    super.key,
    required this.slot,
  });

  final MealSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(dailyLogProvider);
    final mealItems = _itemsFor(log);
    final mealTotal = mealItems.fold<int>(
      0,
      (total, item) => total + item.totalCalories,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_slotLabel(slot)} food',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('$mealTotal kcal'),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openFoodModal(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Food'),
          ),
          if (mealItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < mealItems.length; i++)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${mealItems[i].name} x${mealItems[i].quantity}',
                    ),
                  ),
                  Text('${mealItems[i].totalCalories} kcal'),
                  IconButton(
                    tooltip: 'Remove food',
                    onPressed: () {
                      ref.read(dailyLogProvider.notifier).removeMealItem(
                            slot,
                            i,
                          );
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  List<MealItem> _itemsFor(DailyLogModel log) {
    switch (slot) {
      case MealSlot.breakfast:
        return log.breakfast;
      case MealSlot.lunch:
        return log.lunch;
      case MealSlot.dinner:
        return log.dinner;
    }
  }

  void _openFoodModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return FoodManagerModal(
          mealSlot: slot,
          onAddToMeal: (item) {
            ref.read(dailyLogProvider.notifier).addMealItem(slot, item);
          },
        );
      },
    );
  }

  String _slotLabel(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.dinner:
        return 'Dinner';
    }
  }
}
