import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../models/routine_history_model.dart';
import '../models/task_model.dart';
import '../providers/diet_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';
import '../providers/history_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/weight_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../utils/number_format.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dark_hero_card.dart';
import '../widgets/sparkline.dart';

/// A glance, not a report.
///
/// This screen used to narrate the day in full sentences and then repeat the
/// same numbers in tiles below, so nothing stood out. It now shows one figure
/// per fact, the single next step, and the last seven days — anything that
/// needs reading rather than glancing lives on the History screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _historyDayCount = 7;
  static const _weightTrendDays = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMap = ref.watch(historyProvider);
    final tasks = ref.watch(routineProvider);
    final log = ref.watch(dailyLogProvider);
    final todayGym = ref.watch(todayGymProvider);
    ref.watch(gymSessionProvider);
    final gymController = ref.read(gymSessionProvider.notifier);
    final completedGymSets =
        gymController.completedSetCount(todayGym.exercises);
    final targetGymSets = gymController.targetSetCount(todayGym.exercises);
    ref.watch(weightProvider);
    final weightController = ref.read(weightProvider.notifier);
    final dailyLogs = ref.watch(dailyLogHistoryProvider).asData?.value ??
        const <DailyLogModel>[];

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
    final pastDays = _recentDays(
      tasks: tasks,
      historyMap: historyMap,
      dailyLogs: dailyLogs,
      todayId: todayId,
    );

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _TodayHero(
            date: today,
            completion: completion,
            done: doneCount,
            total: todayTasks.length,
          ),
          const SizedBox(height: 16),
          _FactGrid(
            calories: log.totalCalories,
            gymSetsDone: completedGymSets,
            gymSetsTotal: targetGymSets,
            weight: weightController.latestWeightLb,
            weightChange: weightController.changeOver(_weightTrendDays),
            weightTrend: [
              for (final entry in weightController.trend(_weightTrendDays))
                entry.weightLb,
            ],
            done: doneCount,
            total: todayTasks.length,
            onEditWeight: () => _showWeightDialog(
              context,
              ref,
              weightController.latestWeightLb,
            ),
          ),
          if (todayTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _NextStepRow(
              nextTask: nextTask,
              pendingCount: pendingCount,
              missedCount: missedCount,
            ),
          ],
          const SizedBox(height: 28),
          _MinimalHeading(
            title: 'Last 7 days',
            actionLabel: 'View all',
            onAction: () => _openHistory(context),
          ),
          const SizedBox(height: 14),
          if (pastDays.isEmpty)
            Text(
              'Past days appear here once you close out a day.',
              style: TextStyle(color: context.palette.mutedText),
            )
          else
            for (final day in pastDays) _HistoryRow(day: day),
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

  /// The most recent days that actually hold something — a routine marked
  /// either way, or a meal logged. Days before the account existed would
  /// otherwise read as a wall of 0/5.
  List<_DaySummary> _recentDays({
    required List<TaskModel> tasks,
    required Map<String, RoutineHistoryEntry> historyMap,
    required List<DailyLogModel> dailyLogs,
    required String todayId,
  }) {
    final logsByDate = {for (final log in dailyLogs) log.documentId: log};
    final dateIds = {
      for (final entry in historyMap.values)
        if (entry.dateId != todayId) entry.dateId,
      for (final log in dailyLogs)
        if (log.documentId != todayId && log.totalCalories > 0) log.documentId,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return [
      for (final dateId in dateIds.take(_historyDayCount))
        _DaySummary(
          date: DateTime.parse(dateId),
          done: historyMap.values
              .where((entry) =>
                  entry.dateId == dateId && entry.status == RoutineStatus.done)
              .length,
          total: _scheduledCount(tasks, historyMap, dateId),
          calories: logsByDate[dateId]?.totalCalories ?? 0,
        ),
    ];
  }

  /// Routines that were on the plan that day, plus any that were logged but
  /// have since been deleted or rescheduled — otherwise a day can report more
  /// done than it ever had scheduled.
  int _scheduledCount(
    List<TaskModel> tasks,
    Map<String, RoutineHistoryEntry> historyMap,
    String dateId,
  ) {
    final date = DateTime.parse(dateId);
    final scheduledIds = tasks
        .where((task) => task.runsOn(date))
        .map((task) => task.id)
        .toSet();
    final loggedIds = historyMap.values
        .where((entry) => entry.dateId == dateId)
        .map((entry) => entry.taskId)
        .toSet();
    return scheduledIds.union(loggedIds).length;
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
      ref.read(weightProvider.notifier).record(value);
    }
  }
}

/// One past day, already reduced to the numbers the strip shows.
class _DaySummary {
  const _DaySummary({
    required this.date,
    required this.done,
    required this.total,
    required this.calories,
  });

  final DateTime date;
  final int done;
  final int total;
  final int calories;

  double get completion => total == 0 ? 0 : done / total;
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.date,
    required this.completion,
    required this.done,
    required this.total,
  });

  final DateTime date;
  final double completion;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DarkHeroCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel(date).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.onInkFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  total == 0 ? 'Rest day' : '$done of $total',
                  style: const TextStyle(
                    color: AppColors.onInk,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  total == 0 ? 'nothing scheduled' : 'routines done',
                  style: const TextStyle(
                    color: AppColors.onInkMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: completion,
                  strokeWidth: 7,
                  backgroundColor: AppColors.onInkSurface,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(completion * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.onInk,
                      fontSize: 18,
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

  String _dateLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({
    required this.calories,
    required this.gymSetsDone,
    required this.gymSetsTotal,
    required this.weight,
    required this.weightChange,
    required this.weightTrend,
    required this.done,
    required this.total,
    required this.onEditWeight,
  });

  final int calories;
  final int gymSetsDone;
  final int gymSetsTotal;
  final double weight;
  final double? weightChange;
  final List<double> weightTrend;
  final int done;
  final int total;
  final VoidCallback onEditWeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
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
              iconColor: context.palette.coral,
              label: 'Calories',
              value: formatCount(calories),
              suffix: 'kcal',
            ),
            _FactTile(
              width: itemWidth,
              icon: Icons.fitness_center_rounded,
              iconColor: context.palette.violet,
              label: 'Gym sets',
              // Out of the exercises started, not the whole day's menu, so an
              // untouched day reads as a plain zero rather than 0/48.
              value: gymSetsTotal == 0 ? '0' : '$gymSetsDone/$gymSetsTotal',
              suffix: '',
            ),
            _FactTile(
              width: itemWidth,
              icon: Icons.task_alt_rounded,
              iconColor: context.palette.success,
              label: 'Routines',
              value: '$done/$total',
              suffix: '',
            ),
            _FactTile(
              width: itemWidth,
              icon: Icons.monitor_weight_outlined,
              iconColor: context.palette.blue,
              label: 'Weight',
              value: weight.toStringAsFixed(1),
              suffix: 'lb',
              note: _changeLabel(weightChange),
              // Losing weight is the usual goal here, so a fall reads as
              // progress. Never colour alone — the arrow carries it too.
              noteColor: weightChange == null || weightChange == 0
                  ? context.palette.mutedText
                  : weightChange! < 0
                      ? context.palette.success
                      : context.palette.coral,
              chart: weightTrend.length < 2
                  ? null
                  : Sparkline(
                      values: weightTrend,
                      color: context.palette.blue,
                    ),
              onTap: onEditWeight,
            ),
          ],
        );
      },
    );
  }

  String? _changeLabel(double? change) {
    if (change == null || change == 0) {
      return null;
    }
    final arrow = change < 0 ? '↓' : '↑';
    return '$arrow${change.abs().toStringAsFixed(1)}';
  }
}

/// Label, number, unit — in that order, once each.
///
/// The tile used to carry a 38px icon chip above an all-caps label above the
/// figure, which made four tiles read as four cards rather than four numbers.
class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.suffix,
    this.note,
    this.noteColor,
    this.chart,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String suffix;

  /// Short change indicator beside the label, e.g. a 30-day weight delta.
  final String? note;
  final Color? noteColor;

  /// Optional trend line filling the space after the unit. Kept in the value
  /// row so every tile stays the same height.
  final Widget? chart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: context.palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: iconColor),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: context.palette.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (note != null) ...[
                      Text(
                        note!,
                        style: TextStyle(
                          color: noteColor ?? context.palette.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Only the weight tile is editable, and every tile renders
                    // identically — nothing else says which one responds.
                    if (onTap != null)
                      Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: context.palette.mutedText,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // The figure and its unit share a baseline; the trend line
                    // must stay out of that Row, because a painted box has no
                    // text baseline to align against.
                    Expanded(
                      // Bottom-aligned with a nudge, not CrossAxisAlignment
                      // .baseline: a Flex cannot report intrinsic sizes under
                      // baseline alignment, and any ancestor that asks for one
                      // turns that into an assertion.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.palette.ink,
                                fontSize: 24,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (suffix.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                suffix,
                                style: TextStyle(
                                  color: context.palette.mutedText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (chart != null) ...[
                      const SizedBox(width: 8),
                      SizedBox(width: 46, height: 18, child: chart),
                    ],
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

/// The single next thing, on one line.
///
/// Replaces a card that explained the state in two sentences and then added a
/// line of reassurance about missed routines.
class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
    required this.nextTask,
    required this.pendingCount,
    required this.missedCount,
  });

  final TaskModel? nextTask;
  final int pendingCount;
  final int missedCount;

  @override
  Widget build(BuildContext context) {
    final task = nextTask;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: task == null
            ? context.palette.successSoft
            : context.palette.blueSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(
            task == null ? Icons.check_circle_rounded : Icons.near_me_rounded,
            size: 18,
            color: task == null
                ? context.palette.success
                : context.palette.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task == null ? 'Every routine has a status' : task.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _trailing(task),
            style: TextStyle(
              color: context.palette.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _trailing(TaskModel? task) {
    if (task != null && task.startTime.isNotEmpty) {
      return task.startTime;
    }
    if (missedCount > 0) {
      return '$missedCount missed';
    }
    return '$pendingCount open';
  }
}

/// Section title with an optional action, without the eyebrow line.
class _MinimalHeading extends StatelessWidget {
  const _MinimalHeading({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// One past day: label, completion bar, routines and calories.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.day});

  final _DaySummary day;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              _label(day.date),
              style: TextStyle(
                color: palette.bodyText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: day.completion,
                minHeight: 6,
                backgroundColor: palette.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  day.completion >= 1 ? palette.success : palette.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 42,
            child: Text(
              '${day.done}/${day.total}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              day.calories == 0 ? '—' : '${formatCount(day.calories)} kcal',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]} ${date.day}';
  }
}
