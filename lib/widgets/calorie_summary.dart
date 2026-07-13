import 'package:flutter/material.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calories today',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text('$totalCalories / $goalCalories kcal'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
