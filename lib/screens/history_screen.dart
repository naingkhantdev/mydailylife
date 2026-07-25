import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../models/routine_history_model.dart';
import '../models/task_model.dart';
import '../providers/diet_provider.dart';
import '../providers/history_provider.dart';
import '../providers/routine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_status_chip.dart';
import '../widgets/dark_hero_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_heading.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMap = ref.watch(historyProvider);
    final tasks = ref.watch(routineProvider);
    final dailyLogHistory = ref.watch(dailyLogHistoryProvider);
    final dailyLogs =
        dailyLogHistory.asData?.value ?? const <DailyLogModel>[];
    final dailyLogsByDate = {
      for (final log in dailyLogs) log.documentId: log,
    };
    final todayId = _dateId(DateTime.now());
    final dateIds = {
      for (final entry in historyMap.values)
        if (entry.dateId != todayId) entry.dateId,
      for (final dateId in dailyLogsByDate.keys)
        if (dateId != todayId) dateId,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    final pastEntries = historyMap.values
        .where((entry) => entry.dateId != todayId)
        .toList();
    final doneCount = pastEntries
        .where((entry) => entry.status == RoutineStatus.done)
        .length;
    final scheduledRoutineCount = dateIds.fold<int>(
      0,
      (total, dateId) =>
          total + _tasksForDate(tasks, historyMap, dateId).length,
    );
    final completionRate = scheduledRoutineCount == 0
        ? 0
        : (doneCount * 100 / scheduledRoutineCount).round();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.history),
      appBar: AppBar(title: const Text('History')),
      body: dateIds.isEmpty && dailyLogHistory.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dateIds.isEmpty
              ? const EmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'No past days yet',
                  message:
                      'Complete routines and add short remarks today. Past daily facts will appear here clearly by date.',
                )
              : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _HistoryHero(
                  trackedDays: dateIds.length,
                  completedFacts: doneCount,
                  completionRate: completionRate,
                ),
                const SizedBox(height: 26),
                const SectionHeading(
                  eyebrow: 'PAST DAILY FACTS',
                  title: 'Your days, clearly remembered',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Open a date to see what happened and the remarks you saved.',
                  style: TextStyle(color: AppColors.mutedText, height: 1.4),
                ),
                const SizedBox(height: 14),
                for (var index = 0; index < dateIds.length; index++) ...[
                  _DayHistoryCard(
                    dateId: dateIds[index],
                    tasks: _tasksForDate(
                      tasks,
                      historyMap,
                      dateIds[index],
                    ),
                    historyMap: historyMap,
                    dailyLog: dailyLogsByDate[dateIds[index]],
                    initiallyExpanded: index == 0,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  String _dateId(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  List<TaskModel> _tasksForDate(
    List<TaskModel> tasks,
    Map<String, RoutineHistoryEntry> historyMap,
    String dateId,
  ) {
    final scheduled = tasks
        .where((task) => task.runsOn(DateTime.parse(dateId)))
        .toList();
    final scheduledIds = scheduled.map((task) => task.id).toSet();
    final archived = historyMap.values
        .where((entry) =>
            entry.dateId == dateId && !scheduledIds.contains(entry.taskId))
        .map(
          (entry) => TaskModel(
            id: entry.taskId,
            title: entry.taskTitle,
            startTime: '',
            endTime: '',
            recurringDays: const [],
            category: RoutineCategory.routine,
          ),
        );
    return [...scheduled, ...archived];
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({
    required this.trackedDays,
    required this.completedFacts,
    required this.completionRate,
  });

  final int trackedDays;
  final int completedFacts;
  final int completionRate;

  @override
  Widget build(BuildContext context) {
    return DarkHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.gold, size: 28),
          const SizedBox(height: 14),
          const Text(
            'Patterns become visible\nwhen days are remembered.',
            style: TextStyle(
              color: AppColors.onInk,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroFact(value: '$trackedDays', label: 'TRACKED DAYS'),
              const _HeroDivider(),
              _HeroFact(value: '$completedFacts', label: 'WINS'),
              const _HeroDivider(),
              _HeroFact(value: '$completionRate%', label: 'COMPLETION'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.onInk,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onInkFaint,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.onInkBorder,
    );
  }
}

class _DayHistoryCard extends StatelessWidget {
  const _DayHistoryCard({
    required this.dateId,
    required this.tasks,
    required this.historyMap,
    required this.dailyLog,
    required this.initiallyExpanded,
  });

  final String dateId;
  final List<TaskModel> tasks;
  final Map<String, RoutineHistoryEntry> historyMap;
  final DailyLogModel? dailyLog;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateId);
    final entries = [
      for (final task in tasks) historyMap['$dateId:${task.id}'],
    ].whereType<RoutineHistoryEntry>().toList();
    final done = entries
        .where((entry) => entry.status == RoutineStatus.done)
        .length;
    final missed = entries.length - done;
    final pending = tasks.length - entries.length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
    final color = _progressColor(progress);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: _DateBadge(date: date, color: color),
          title: Text(
            _weekdayLabel(date),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AppStatusChip(label: '$done done', color: AppColors.success),
                if (missed > 0)
                  AppStatusChip(label: '$missed missed', color: AppColors.coral),
                if (pending > 0)
                  AppStatusChip(label: '$pending untracked', color: AppColors.mutedText),
              ],
            ),
          ),
          children: [
            _DayBrief(
              done: done,
              missed: missed,
              pending: pending,
              total: tasks.length,
              progress: progress,
              color: color,
            ),
            if (dailyLog != null) ...[
              const SizedBox(height: 12),
              _DailyLogFacts(log: dailyLog!),
            ],
            const SizedBox(height: 14),
            for (var index = 0; index < tasks.length; index++) ...[
              _HistoryRoutineRow(
                task: tasks[index],
                entry: historyMap['$dateId:${tasks[index].id}'],
              ),
              if (index != tasks.length - 1)
                const Divider(height: 20, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }

  Color _progressColor(double progress) {
    if (progress >= 0.75) return AppColors.success;
    if (progress >= 0.4) return AppColors.warning;
    return AppColors.coral;
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }
}

class _DailyLogFacts extends StatelessWidget {
  const _DailyLogFacts({required this.log});

  final DailyLogModel log;

  @override
  Widget build(BuildContext context) {
    final mealCount = log.breakfast.length + log.lunch.length + log.dinner.length;
    final notes = <({IconData icon, String label, String value})>[
      if (log.workNotes.trim().isNotEmpty)
        (icon: Icons.work_outline_rounded, label: 'Work', value: log.workNotes),
      if (log.studyNotes.trim().isNotEmpty)
        (icon: Icons.school_outlined, label: 'Study', value: log.studyNotes),
      if (log.gamingNotes.trim().isNotEmpty)
        (icon: Icons.sports_esports_outlined, label: 'Gaming', value: log.gamingNotes),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _LoggedFact(
                  icon: Icons.local_fire_department_rounded,
                  value: '${log.totalCalories}',
                  label: 'kcal logged',
                  color: AppColors.coral,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.border),
              Expanded(
                child: _LoggedFact(
                  icon: Icons.restaurant_rounded,
                  value: '$mealCount',
                  label: mealCount == 1 ? 'food item' : 'food items',
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          for (final note in notes) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(note.icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: AppColors.bodyText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '${note.label}: ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: note.value),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoggedFact extends StatelessWidget {
  const _LoggedFact({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date, required this.color});

  final DateTime date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return Container(
      width: 54,
      height: 62,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            months[date.month - 1],
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            '${date.day}',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 23,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBrief extends StatelessWidget {
  const _DayBrief({
    required this.done,
    required this.missed,
    required this.pending,
    required this.total,
    required this.progress,
    required this.color,
  });

  final int done;
  final int missed;
  final int pending;
  final int total;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _brief(),
            style: const TextStyle(
              color: AppColors.bodyText,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  String _brief() {
    if (total == 0) return 'No routines were scheduled for this day.';
    if (done == total) return 'A fully completed day: all $total routines were done.';
    return '$done of $total routines were completed, with $missed missed and '
        '$pending left untracked.';
  }
}

class _HistoryRoutineRow extends StatelessWidget {
  const _HistoryRoutineRow({required this.task, required this.entry});

  final TaskModel task;
  final RoutineHistoryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final status = entry?.status;
    final color = switch (status) {
      RoutineStatus.done => AppColors.success,
      RoutineStatus.missed => AppColors.coral,
      null => AppColors.mutedText,
    };
    final icon = switch (status) {
      RoutineStatus.done => Icons.check_rounded,
      RoutineStatus.missed => Icons.close_rounded,
      null => Icons.remove_rounded,
    };
    final statusLabel = switch (status) {
      RoutineStatus.done => 'DONE',
      RoutineStatus.missed => 'MISSED',
      null => 'NO UPDATE',
    };
    final recordedTitle = entry?.taskTitle.trim();
    final title = recordedTitle == null || recordedTitle.isEmpty
        ? task.title
        : recordedTitle;
    final hasTime = task.startTime.isNotEmpty && task.endTime.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              if (hasTime)
                Text(
                  '${task.startTime} – ${task.endTime}',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                )
              else
                const Text(
                  'Archived routine',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                ),
              if (entry?.remark.isNotEmpty ?? false) ...[
                const SizedBox(height: 6),
                Text(
                  entry!.remark,
                  style: const TextStyle(
                    color: AppColors.bodyText,
                    fontSize: 12,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          statusLabel,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

