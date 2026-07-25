import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/routine_history_model.dart';
import '../models/task_model.dart';
import '../providers/diet_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';
import '../providers/history_provider.dart';
import '../providers/routine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dark_hero_card.dart';
import '../widgets/section_heading.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMap = ref.watch(historyProvider);
    final tasks = ref.watch(routineProvider);
    final log = ref.watch(dailyLogProvider);
    final todayGym = ref.watch(todayGymProvider);
    ref.watch(gymSessionProvider);
    final gymController = ref.read(gymSessionProvider.notifier);
    final completedGymSets = gymController.completedSetCount(todayGym.exercises);
    final targetGymSets = gymController.targetSetCount(todayGym.exercises);
    final weight = ref.watch(currentWeightLbProvider);
    final today = DateTime.now();
    final todayId = _dateId(today);
    final todayTasks = tasks.where((task) => task.runsOn(today)).toList();
    final todayEntries = {
      for (final task in todayTasks)
        task.id: historyMap['$todayId:${task.id}'],
    };
    final doneCount = todayEntries.values
        .where((entry) => entry?.status == RoutineStatus.done)
        .length;
    final missedCount = todayEntries.values
        .where((entry) => entry?.status == RoutineStatus.missed)
        .length;
    final pendingCount = todayTasks.length - doneCount - missedCount;
    final completion = todayTasks.isEmpty ? 0.0 : doneCount / todayTasks.length;
    final nextTask = _firstPendingTask(todayTasks, todayEntries);
    final doneRemarks = todayEntries.values
        .where((entry) =>
            entry?.status == RoutineStatus.done && entry!.remark.isNotEmpty)
        .cast<RoutineHistoryEntry>()
        .toList();
    final missedRemarks = todayEntries.values
        .where((entry) =>
            entry?.status == RoutineStatus.missed && entry!.remark.isNotEmpty)
        .cast<RoutineHistoryEntry>()
        .toList();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Open history',
            onPressed: () => _openHistory(context),
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _TodayHero(
            date: today,
            brief: _buildTodayBrief(
              total: todayTasks.length,
              done: doneCount,
              missed: missedCount,
              pending: pendingCount,
              calories: log.totalCalories,
              gymSetsDone: completedGymSets,
              gymSetsTotal: targetGymSets,
            ),
            completion: completion,
            done: doneCount,
            total: todayTasks.length,
          ),
          const SizedBox(height: 18),
          _FactGrid(
            calories: log.totalCalories,
            gymSetsDone: completedGymSets,
            gymSetsTotal: targetGymSets,
            weight: weight,
            done: doneCount,
            total: todayTasks.length,
            onEditWeight: () => _showWeightDialog(context, ref, weight),
          ),
          const SizedBox(height: 26),
          SectionHeading(
            eyebrow: 'TODAY\'S FACTS',
            title: 'What matters right now',
            actionLabel: 'View history',
            onAction: () => _openHistory(context),
          ),
          const SizedBox(height: 12),
          _FocusCard(
            nextTask: nextTask,
            pendingCount: pendingCount,
            missedCount: missedCount,
          ),
          if (doneRemarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InsightCard(
              icon: Icons.auto_awesome_rounded,
              color: AppColors.success,
              background: AppColors.successSoft,
              title: 'Wins worth remembering',
              entries: doneRemarks,
              emptyMessage: '',
            ),
          ],
          if (missedRemarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InsightCard(
              icon: Icons.lightbulb_outline_rounded,
              color: AppColors.warning,
              background: AppColors.warningSoft,
              title: 'What got in the way',
              entries: missedRemarks,
              emptyMessage: '',
            ),
          ],
          if (doneRemarks.isEmpty && missedRemarks.isEmpty) ...[
            const SizedBox(height: 12),
            const _EmptyReflectionCard(),
          ],
        ],
      ),
    );
  }

  TaskModel? _firstPendingTask(
    List<TaskModel> tasks,
    Map<String, RoutineHistoryEntry?> entries,
  ) {
    for (final task in tasks) {
      if (entries[task.id] == null) {
        return task;
      }
    }
    return null;
  }

  String _buildTodayBrief({
    required int total,
    required int done,
    required int missed,
    required int pending,
    required int calories,
    required int gymSetsDone,
    required int gymSetsTotal,
  }) {
    if (total == 0) {
      return 'Today is intentionally light. Use the space to recover and reset.';
    }
    if (done == 0 && missed == 0) {
      return 'Your day is ready: $total routines, $calories kcal logged, and '
          '$gymSetsDone of $gymSetsTotal gym sets complete.';
    }
    final routineFact = '$done of $total routines completed';
    final missedFact = missed == 0 ? '' : ', $missed missed';
    final pendingFact = pending == 0 ? '' : ', and $pending still open';
    return 'You have $routineFact$missedFact$pendingFact. '
        'You logged $calories kcal and finished $gymSetsDone of '
        '$gymSetsTotal gym sets.';
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.history);
  }

  String _dateId(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _showWeightDialog(
    BuildContext context,
    WidgetRef ref,
    double currentWeight,
  ) async {
    var enteredWeight = currentWeight.toStringAsFixed(1);
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update current weight'),
        content: TextFormField(
          initialValue: enteredWeight,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => enteredWeight = value,
          decoration: const InputDecoration(
            labelText: 'Weight in lb',
            prefixIcon: Icon(Icons.monitor_weight_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              double.tryParse(enteredWeight.trim()),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      ref.read(currentWeightLbProvider.notifier).state = value;
    }
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.date,
    required this.brief,
    required this.completion,
    required this.done,
    required this.total,
  });

  final DateTime date;
  final String brief;
  final double completion;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DarkHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DarkHeroBadge(label: _dateLabel(date).toUpperCase()),
              const Spacer(),
              const Icon(Icons.wb_sunny_outlined, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today, in brief',
                      style: TextStyle(
                        color: AppColors.onInk,
                        fontSize: 25,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      brief,
                      style: const TextStyle(
                        color: AppColors.onInkMuted,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: completion,
                      strokeWidth: 8,
                      backgroundColor: AppColors.onInkSurface,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(completion * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.onInk,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$done/$total done',
                            style: const TextStyle(
                              color: AppColors.onInkMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({
    required this.calories,
    required this.gymSetsDone,
    required this.gymSetsTotal,
    required this.weight,
    required this.done,
    required this.total,
    required this.onEditWeight,
  });

  final int calories;
  final int gymSetsDone;
  final int gymSetsTotal;
  final double weight;
  final int done;
  final int total;
  final VoidCallback onEditWeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final itemWidth = constraints.maxWidth >= 700
            ? (constraints.maxWidth - gap * 3) / 4
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _FactTile(
              width: itemWidth,
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.coral,
              iconBackground: AppColors.coralSoft,
              label: 'CALORIES',
              value: '$calories',
              suffix: 'kcal',
            ),
            _FactTile(
              width: itemWidth,
              icon: Icons.fitness_center_rounded,
              iconColor: AppColors.violet,
              iconBackground: AppColors.violetSoft,
              label: 'GYM SETS',
              value: '$gymSetsDone/$gymSetsTotal',
              suffix: 'today',
            ),
            _FactTile(
              width: itemWidth,
              icon: Icons.task_alt_rounded,
              iconColor: AppColors.success,
              iconBackground: AppColors.successSoft,
              label: 'ROUTINES',
              value: '$done/$total',
              suffix: 'done',
            ),
            _FactTile(
              width: itemWidth,
              icon: Icons.monitor_weight_outlined,
              iconColor: AppColors.blue,
              iconBackground: AppColors.blueSoft,
              label: 'WEIGHT',
              value: weight.toStringAsFixed(1),
              suffix: 'lb',
              onTap: onEditWeight,
            ),
          ],
        );
      },
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.suffix,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        suffix,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.nextTask,
    required this.pendingCount,
    required this.missedCount,
  });

  final TaskModel? nextTask;
  final int pendingCount;
  final int missedCount;

  @override
  Widget build(BuildContext context) {
    final isComplete = nextTask == null && pendingCount == 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.successSoft : AppColors.blueSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withOpacity(0.16)
              : AppColors.blue.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isComplete ? AppColors.success : AppColors.blue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isComplete ? Icons.celebration_rounded : Icons.near_me_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete ? 'Day reviewed' : 'Next clear step',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                      ? 'Everything scheduled has a status. Take a moment to notice the progress.'
                      : '${nextTask?.title ?? 'Review your remaining routines'} · '
                          '${nextTask?.startTime ?? '$pendingCount open'}',
                  style: const TextStyle(
                    color: AppColors.bodyText,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (missedCount > 0) ...[
                  const SizedBox(height: 5),
                  Text(
                    '$missedCount missed ${missedCount == 1 ? 'routine' : 'routines'} — use the note as information, not judgment.',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.entries,
    required this.emptyMessage,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final List<RoutineHistoryEntry> entries;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(emptyMessage),
            )
          else
            for (final entry in entries.take(3))
              Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${entry.taskTitle}: ${entry.remark}',
                        style: const TextStyle(
                          color: AppColors.bodyText,
                          fontSize: 13,
                          height: 1.4,
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

class _EmptyReflectionCard extends StatelessWidget {
  const _EmptyReflectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.violetSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: AppColors.violet),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add a short remark when you complete or miss a routine. Those small facts make your history genuinely useful.',
              style: TextStyle(
                color: AppColors.bodyText,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
