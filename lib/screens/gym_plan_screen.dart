import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';
import '../widgets/gym_technique_card.dart';

class GymPlanScreen extends ConsumerWidget {
  const GymPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(gymPlanProvider);
    final todayGym = ref.watch(todayGymProvider);
    ref.watch(gymSessionProvider);
    final sessionController = ref.read(gymSessionProvider.notifier);
    final completed = sessionController.completedSetCount(todayGym.exercises);
    final target = sessionController.targetSetCount(todayGym.exercises);

    return Scaffold(
      appBar: AppBar(title: const Text('Gym')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayGym.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayGym.focus,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: target == 0 ? 0 : completed / target,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completed / $target sets finished',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GymTechniqueCard(gymDay: todayGym),
          const SizedBox(height: 20),
          Text(
            'Weekly plan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          for (final day in plan) ...[
            _GymDaySummary(day: day, isToday: day.weekday == DateTime.now().weekday),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _GymDaySummary extends StatelessWidget {
  const _GymDaySummary({
    required this.day,
    required this.isToday,
  });

  final GymDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  day.focus,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          if (isToday)
            const Text(
              'Today',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}
