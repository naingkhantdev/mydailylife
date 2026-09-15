import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gym_session_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../utils/gym_format.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import 'gym_technique_history_screen.dart';

/// Every past training day, newest first — the sidebar's entry point into gym
/// history. Each day expands into the exercises trained that day; tapping one
/// drills into [GymTechniqueHistoryScreen] for that exercise specifically.
class GymHistoryScreen extends ConsumerWidget {
  const GymHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gymSessionProvider);
    final history = ref.read(gymSessionProvider.notifier).history;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.gymHistory),
      appBar: AppBar(title: const Text('Gym history')),
      body: history.isEmpty
          ? EmptyState(
              icon: Icons.history_rounded,
              title: 'No workouts logged yet',
              message:
                  'Tick a set or record a weight on a training day and it '
                  'will show up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                for (final log in history) ...[
                  _GymDayCard(log: log),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _GymDayCard extends StatelessWidget {
  const _GymDayCard({required this.log});

  final GymSessionLog log;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final exercises = log.exercises.entries.toList()
      ..sort((a, b) => b.value.weightKg.compareTo(a.value.weightKg));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DateBadge(date: log.date),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gymWeekdayNames[log.date.weekday - 1],
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercises.length} '
                      '${exercises.length == 1 ? 'exercise' : 'exercises'} · '
                      '${log.totalVolumeKg} kg lifted',
                      style: TextStyle(color: palette.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: palette.border),
          for (final entry in exercises)
            _ExerciseRow(exercise: entry.key, session: entry.value),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.session});

  final String exercise;
  final GymExerciseSession session;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GymTechniqueHistoryScreen(exercise: exercise),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              session.isComplete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: session.isComplete ? palette.success : palette.mutedText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exercise,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.bodyText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              session.hasWeight
                  ? '${session.completedSets.length}/${session.targetSets} · '
                      '${formatGymWeightKg(session.weightKg)} kg'
                  : '${session.completedSets.length}/${session.targetSets}',
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: palette.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 46,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.blueSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            gymMonthAbbreviations[date.month - 1],
            style: TextStyle(
              color: palette.primary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              color: palette.ink,
              fontSize: 18,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
