import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gym_session_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../utils/gym_format.dart';
import '../widgets/empty_state.dart';

/// Every past day this exercise carried a weight or a ticked set, newest
/// first — so progress on one technique is readable without wading through
/// the rest of the split.
class GymTechniqueHistoryScreen extends ConsumerWidget {
  const GymTechniqueHistoryScreen({super.key, required this.exercise});

  final String exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gymSessionProvider);
    final history = ref.read(gymSessionProvider.notifier).history;
    final entries = [
      for (final log in history)
        if (log.exercises[exercise] case final session?
            when session.hasWeight || session.completedSets.isNotEmpty)
          (date: log.date, session: session),
    ];

    final bestWeightKg = entries.isEmpty
        ? 0.0
        : entries
            .map((entry) => entry.session.weightKg)
            .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(exercise)),
      body: entries.isEmpty
          ? EmptyState(
              icon: Icons.history_rounded,
              title: 'No history yet',
              message:
                  'Log a set or a weight for $exercise and it will show up here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _HistorySummary(
                  sessionCount: entries.length,
                  bestWeightKg: bestWeightKg,
                ),
                const SizedBox(height: 16),
                for (final entry in entries) ...[
                  _HistoryEntryCard(date: entry.date, session: entry.session),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.sessionCount,
    required this.bestWeightKg,
  });

  final int sessionCount;
  final double bestWeightKg;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.violetSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              value: '$sessionCount',
              label: sessionCount == 1 ? 'SESSION' : 'SESSIONS',
            ),
          ),
          Container(width: 1, height: 30, color: palette.border),
          Expanded(
            child: _SummaryStat(
              value:
                  bestWeightKg > 0 ? '${formatGymWeightKg(bestWeightKg)} kg' : '—',
              label: 'BEST LIFT',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: context.palette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: context.palette.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.date, required this.session});

  final DateTime date;
  final GymExerciseSession session;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isComplete = session.isComplete;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          _DateBadge(date: date),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gymWeekdayNames[date.weekday - 1],
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  session.hasWeight
                      ? '${session.completedSets.length}/${session.targetSets} sets · '
                          '${session.targetReps} reps · '
                          '${formatGymWeightKg(session.weightKg)} kg'
                      : '${session.completedSets.length}/${session.targetSets} sets · '
                          '${session.targetReps} reps',
                  style: TextStyle(color: palette.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            isComplete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isComplete ? palette.success : palette.mutedText,
          ),
        ],
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
