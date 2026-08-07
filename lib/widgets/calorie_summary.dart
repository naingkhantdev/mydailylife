import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/number_format.dart';
import 'dark_hero_card.dart';

class CalorieSummary extends StatelessWidget {
  const CalorieSummary({
    super.key,
    required this.totalCalories,
    this.goalCalories = 2200,
  });

  final int totalCalories;
  final int goalCalories;

  @override
  Widget build(BuildContext context) {
    final progress = (totalCalories / goalCalories).clamp(0.0, 1.0);
    final remaining = goalCalories - totalCalories;
    final brief = remaining >= 0
        ? '$remaining kcal left in today\'s goal.'
        : '${-remaining} kcal over today\'s goal.';

    return DarkHeroCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DarkHeroBadge(
                  label: 'TODAY\'S INTAKE',
                  icon: Icons.local_fire_department_rounded,
                ),
                const SizedBox(height: 14),
                Text(
                  '${formatCount(totalCalories)} kcal',
                  style: const TextStyle(
                    color: AppColors.onInk,
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  brief,
                  style: const TextStyle(
                    color: AppColors.onInkMuted,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.onInkSurface,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.coral),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.onInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
