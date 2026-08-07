import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../providers/diet_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../utils/number_format.dart';
import 'food_manager_modal.dart';

class QuickMealEntryCard extends ConsumerWidget {
  const QuickMealEntryCard({
    super.key,
    required this.slot,
  });

  final MealSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final log = ref.watch(dailyLogProvider);
    final mealItems = _itemsFor(log);
    final mealTotal = mealItems.fold<int>(
      0,
      (total, item) => total + item.totalCalories,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_slotLabel(slot)} food',
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$mealTotal kcal',
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openFoodModal(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add food'),
          ),
          if (mealItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (var i = 0; i < mealItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${mealItems[i].name} x${mealItems[i].quantity}',
                        style: TextStyle(
                          color: palette.bodyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${formatCount(mealItems[i].totalCalories)} kcal',
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove food',
                      onPressed: () {
                        ref.read(dailyLogProvider.notifier).removeMealItem(
                              slot,
                              i,
                            );
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.mutedText,
                        size: 18,
                      ),
                    ),
                  ],
                ),
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
