import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dark_hero_card.dart';
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
      drawer: const AppDrawer(currentRoute: AppRoutes.gym),
      appBar: AppBar(
        title: const Text('Gym technique'),
        actions: [
          IconButton(
            tooltip: 'Manage techniques',
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(AppRoutes.gymTechniques),
            icon: const Icon(Icons.edit_note_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DarkHeroCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todayGym.title,
                  style: const TextStyle(
                    color: AppColors.onInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayGym.focus,
                  style: const TextStyle(color: AppColors.onInkMuted),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: target == 0 ? 0 : completed / target,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  backgroundColor: AppColors.onInkSurface,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed / $target sets finished',
                  style: const TextStyle(color: AppColors.onInkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GymTechniqueCard(gymDay: todayGym),
          const SizedBox(height: 20),
          Text(
            'Weekly plan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          for (final day in plan) ...[
            _GymDaySummary(
              day: day,
              isToday: day.weekday == DateTime.now().weekday,
            ),
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
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isToday ? context.palette.primary : context.palette.border,
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
                  style: TextStyle(
                    color: context.palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.focus,
                  style: TextStyle(color: context.palette.mutedText),
                ),
              ],
            ),
          ),
          if (isToday)
            Text(
              'Today',
              style: TextStyle(
                color: context.palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
