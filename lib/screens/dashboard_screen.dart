import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/routine_history_model.dart';
import '../models/task_model.dart';
import '../providers/diet_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';
import '../providers/history_provider.dart';
import '../providers/routine_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMap = ref.watch(historyProvider);
    final tasks = ref.watch(routineProvider);
    final log = ref.watch(dailyLogProvider);
    final todayGym = ref.watch(todayGymProvider);
    ref.watch(gymSessionProvider);
    final gymSessionController = ref.read(gymSessionProvider.notifier);
    final completedGymSets =
        gymSessionController.completedSetCount(todayGym.exercises);
    final targetGymSets =
        gymSessionController.targetSetCount(todayGym.exercises);
    final weight = ref.watch(currentWeightLbProvider);
    final today = DateTime.now();
    final todayId = _dateId(today);
    final todayTasks = tasks.where((task) => task.runsOn(today)).toList();
    final todayEntries = [
      for (final task in todayTasks) historyMap['$todayId:${task.id}'],
    ].whereType<RoutineHistoryEntry>().toList();
    final doneCount = todayEntries
        .where((entry) => entry.status == RoutineStatus.done)
        .length;
    final missedCount = todayEntries
        .where((entry) => entry.status == RoutineStatus.missed)
        .length;
    final overallEntries = historyMap.values.toList();
    final overallDoneCount = overallEntries
        .where((entry) => entry.status == RoutineStatus.done)
        .length;
    final overallMissedCount = overallEntries.length - overallDoneCount;
    final trackedDayCount = overallEntries
        .map((entry) => entry.dateId)
        .toSet()
        .length;
    final dateIds = {
      todayId,
      for (final entry in historyMap.values) entry.dateId,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TopSummary(
            weight: weight,
            calories: log.totalCalories,
            done: doneCount,
            missed: missedCount,
            total: todayTasks.length,
            gymProgress: '$completedGymSets/$targetGymSets',
            onEditWeight: () => _showWeightDialog(context, ref, weight),
          ),
          const SizedBox(height: 20),
          _OverallHistorySummary(
            trackedDays: trackedDayCount,
            done: overallDoneCount,
            missed: overallMissedCount,
          ),
          const SizedBox(height: 20),
          Text(
            'Daily routine by date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          for (final dateId in dateIds) ...[
            _RoutineDateSection(
              dateId: dateId,
              tasks: tasksForDate(tasks, dateId),
              historyMap: historyMap,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  List<TaskModel> tasksForDate(List<TaskModel> tasks, String dateId) {
    final date = DateTime.parse(dateId);
    return tasks.where((task) => task.runsOn(date)).toList();
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
    var enteredWeight = currentWeight.toStringAsFixed(0);

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Current weight'),
          content: TextFormField(
            initialValue: enteredWeight,
            autofocus: true,
            keyboardType: TextInputType.number,
            onChanged: (value) => enteredWeight = value,
            decoration: const InputDecoration(
              labelText: 'Weight in lb',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  double.tryParse(enteredWeight.trim()),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (value != null && value > 0) {
      ref.read(currentWeightLbProvider.notifier).state = value;
    }
  }
}

class _OverallHistorySummary extends StatelessWidget {
  const _OverallHistorySummary({
    required this.trackedDays,
    required this.done,
    required this.missed,
  });

  final int trackedDays;
  final int done;
  final int missed;

  @override
  Widget build(BuildContext context) {
    final total = done + missed;
    final completionRate = total == 0 ? 0 : (done * 100 / total).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall routine history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryValue(
                    label: 'Tracked days',
                    value: '$trackedDays',
                  ),
                ),
                Expanded(
                  child: _SummaryValue(label: 'Done', value: '$done'),
                ),
                Expanded(
                  child: _SummaryValue(label: 'Missed', value: '$missed'),
                ),
                Expanded(
                  child: _SummaryValue(
                    label: 'Completion',
                    value: '$completionRate%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  const _TopSummary({
    required this.weight,
    required this.calories,
    required this.done,
    required this.missed,
    required this.total,
    required this.gymProgress,
    required this.onEditWeight,
  });

  final double weight;
  final int calories;
  final int done;
  final int missed;
  final int total;
  final String gymProgress;
  final VoidCallback onEditWeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryValue(
                    label: 'Weight',
                    value: '${weight.toStringAsFixed(1)} lb',
                  ),
                ),
                IconButton(
                  tooltip: 'Edit weight',
                  onPressed: onEditWeight,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SummaryValue(label: 'Done', value: '$done/$total'),
                ),
                Expanded(
                  child: _SummaryValue(label: 'Missed', value: '$missed'),
                ),
                Expanded(
                  child: _SummaryValue(label: 'Calories', value: '$calories'),
                ),
                Expanded(
                  child: _SummaryValue(label: 'Gym sets', value: gymProgress),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _RoutineDateSection extends StatelessWidget {
  const _RoutineDateSection({
    required this.dateId,
    required this.tasks,
    required this.historyMap,
  });

  final String dateId;
  final List<TaskModel> tasks;
  final Map<String, RoutineHistoryEntry> historyMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prettyDate(dateId),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final task in tasks) _RoutineStatusRow(
              task: task,
              entry: historyMap['$dateId:${task.id}'],
            ),
          ],
        ),
      ),
    );
  }

  String _prettyDate(String dateId) {
    final date = DateTime.parse(dateId);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _RoutineStatusRow extends StatelessWidget {
  const _RoutineStatusRow({
    required this.task,
    required this.entry,
  });

  final TaskModel task;
  final RoutineHistoryEntry? entry;

  @override
  Widget build(BuildContext context) {
    final status = entry?.status;
    final statusText = switch (status) {
      RoutineStatus.done => 'Done',
      RoutineStatus.missed => 'Missed',
      null => 'Pending',
    };
    final icon = switch (status) {
      RoutineStatus.done => Icons.check_circle_outline,
      RoutineStatus.missed => Icons.cancel_outlined,
      null => Icons.radio_button_unchecked,
    };
    final color = switch (status) {
      RoutineStatus.done => const Color(0xFF166534),
      RoutineStatus.missed => const Color(0xFF991B1B),
      null => const Color(0xFF9CA3AF),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title),
                Text(
                  '${task.startTime} - ${task.endTime}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                if (entry?.remark.isNotEmpty ?? false)
                  Text(
                    entry!.remark,
                    style: TextStyle(
                      color: entry!.status == RoutineStatus.missed
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF475569),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            statusText,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
