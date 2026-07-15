import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../models/routine_history_model.dart';
import '../models/task_model.dart';
import '../providers/gym_provider.dart';
import '../providers/gym_session_provider.dart';
import '../providers/history_provider.dart';
import '../providers/routine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/quick_meal_entry_card.dart';
import 'dashboard_screen.dart';
import 'gym_plan_screen.dart';
import 'history_screen.dart';
import 'routine_manager_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMap = ref.watch(historyProvider);
    final historyController = ref.read(historyProvider.notifier);
    final tasks = ref.watch(routineProvider);
    final todayGym = ref.watch(todayGymProvider);
    ref.watch(gymSessionProvider);
    final gymController = ref.read(gymSessionProvider.notifier);
    final today = DateTime.now();
    final todayId = _dateId(today);
    final todayTasks = tasks.where((task) => task.runsOn(today)).toList();
    final entries = {
      for (final task in todayTasks)
        task.id: historyMap['$todayId:${task.id}'],
    };
    final doneCount = entries.values
        .where((entry) => entry?.status == RoutineStatus.done)
        .length;
    final completedSets = gymController.completedSetCount(todayGym.exercises);
    final targetSets = gymController.targetSetCount(todayGym.exercises);
    final currentTaskId = _currentTaskId(todayTasks, today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RoutineSync'),
        actions: [
          IconButton(
            tooltip: 'Manage routines',
            onPressed: () => _open(context, const RoutineManagerScreen()),
            icon: const Icon(Icons.edit_calendar_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _AppDrawer(onOpen: (screen) => _open(context, screen)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _TodayHeader(
            date: today,
            done: doneCount,
            total: todayTasks.length,
          ),
          const SizedBox(height: 14),
          _GymFocusCard(
            title: todayGym.title,
            focus: todayGym.focus,
            completedSets: completedSets,
            targetSets: targetSets,
            onOpen: () => _open(context, const GymPlanScreen()),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily routine',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: () => _open(context, const RoutineManagerScreen()),
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (todayTasks.isEmpty)
            const _EmptyToday()
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < todayTasks.length; index++) ...[
                    _RoutineRow(
                      task: todayTasks[index],
                      entry: entries[todayTasks[index].id],
                      isCurrent: todayTasks[index].id == currentTaskId,
                      onTap: () => _showTaskActions(
                        context,
                        historyController,
                        todayTasks[index],
                        entries[todayTasks[index].id],
                      ),
                    ),
                    if (index != todayTasks.length - 1)
                      const Divider(
                        height: 1,
                        indent: 82,
                        color: AppColors.border,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _showTaskActions(
    BuildContext context,
    HistoryController controller,
    TaskModel task,
    RoutineHistoryEntry? entry,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _TaskActionSheet(
        task: task,
        entry: entry,
        mealSlot: _mealSlotFor(task),
        onDone: () {
          Navigator.of(sheetContext).pop();
          _markDone(context, controller, task);
        },
        onMissed: () {
          Navigator.of(sheetContext).pop();
          _markMissed(context, controller, task);
        },
        onClear: () {
          controller.clearToday(task);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _markMissed(
    BuildContext context,
    HistoryController controller,
    TaskModel task,
  ) async {
    var enteredRemark = '';
    final remark = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as missed'),
        content: TextField(
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          onChanged: (value) => enteredRemark = value,
          decoration: const InputDecoration(
            labelText: 'What got in the way?',
            hintText: 'Optional note for your history',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(enteredRemark.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (remark != null) controller.markMissed(task, remark);
  }

  Future<void> _markDone(
    BuildContext context,
    HistoryController controller,
    TaskModel task,
  ) async {
    var enteredRemark = '';
    final remark = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete task'),
        content: TextField(
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          onChanged: (value) => enteredRemark = value,
          decoration: const InputDecoration(
            labelText: 'Short note',
            hintText: 'Optional: what did you accomplish?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Done only'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(enteredRemark.trim()),
            child: const Text('Save note'),
          ),
        ],
      ),
    );
    if (remark != null) controller.markDone(task, remark: remark);
  }

  MealSlot? _mealSlotFor(TaskModel task) {
    return switch (task.id) {
      'breakfast' => MealSlot.breakfast,
      'lunch' => MealSlot.lunch,
      'dinner' => MealSlot.dinner,
      _ => null,
    };
  }

  String? _currentTaskId(List<TaskModel> tasks, DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;
    for (final task in tasks) {
      final start = _minutes(task.startTime);
      final end = _minutes(task.endTime);
      if (start != null && end != null && nowMinutes >= start && nowMinutes < end) {
        return task.id;
      }
    }
    return null;
  }

  int? _minutes(String label) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(label);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour == 12) hour = 0;
    if (match.group(3) == 'PM') hour += 12;
    return hour * 60 + minute;
  }

  String _dateId(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({
    required this.date,
    required this.done,
    required this.total,
  });

  final DateTime date;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _weekday(date),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 3),
          Text(
            _date(date),
            style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$done of $total done',
                style: const TextStyle(
                  color: AppColors.bodyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime date) {
    const values = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return values[date.weekday - 1];
  }

  String _date(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _GymFocusCard extends StatelessWidget {
  const _GymFocusCard({
    required this.title,
    required this.focus,
    required this.completedSets,
    required this.targetSets,
    required this.onOpen,
  });

  final String title;
  final String focus;
  final int completedSets;
  final int targetSets;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TODAY\'S TRAINING',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      focus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$completedSets/$targetSets sets · View technique',
                      style: const TextStyle(
                        color: Color(0xFFA5B4FC),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.task,
    required this.entry,
    required this.isCurrent,
    required this.onTap,
  });

  final TaskModel task;
  final RoutineHistoryEntry? entry;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = entry?.status;
    final statusColor = switch (status) {
      RoutineStatus.done => AppColors.success,
      RoutineStatus.missed => AppColors.danger,
      null => AppColors.mutedText,
    };
    final statusIcon = switch (status) {
      RoutineStatus.done => Icons.check_circle_rounded,
      RoutineStatus.missed => Icons.cancel_rounded,
      null => Icons.radio_button_unchecked_rounded,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(
                _shortTime(task.startTime),
                style: TextStyle(
                  color: isCurrent ? AppColors.primary : AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withOpacity(0.09)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(task.category),
                size: 17,
                color: isCurrent ? AppColors.primary : AppColors.bodyText,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: status == RoutineStatus.missed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 7),
                        const Text(
                          'NOW',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Until ${task.endTime}',
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(statusIcon, color: statusColor, size: 21),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText, size: 19),
          ],
        ),
      ),
    );
  }

  String _shortTime(String value) {
    return value.replaceAll(':00', '').replaceAll(' ', '');
  }

  IconData _categoryIcon(RoutineCategory category) {
    return switch (category) {
      RoutineCategory.meal => Icons.restaurant_outlined,
      RoutineCategory.work => Icons.work_outline_rounded,
      RoutineCategory.rest => Icons.self_improvement_rounded,
      RoutineCategory.gym => Icons.fitness_center_rounded,
      RoutineCategory.study => Icons.menu_book_outlined,
      RoutineCategory.gaming => Icons.sports_esports_outlined,
      RoutineCategory.routine => Icons.event_available_outlined,
    };
  }
}

class _TaskActionSheet extends StatelessWidget {
  const _TaskActionSheet({
    required this.task,
    required this.entry,
    required this.mealSlot,
    required this.onDone,
    required this.onMissed,
    required this.onClear,
  });

  final TaskModel task;
  final RoutineHistoryEntry? entry;
  final MealSlot? mealSlot;
  final VoidCallback onDone;
  final VoidCallback onMissed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        2,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(task.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${task.startTime} – ${task.endTime}',
            style: const TextStyle(color: AppColors.mutedText),
          ),
          if (entry?.remark.isNotEmpty ?? false) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry!.remark,
                style: const TextStyle(color: AppColors.bodyText, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: entry?.status == RoutineStatus.done ? null : onDone,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: entry?.status == RoutineStatus.missed ? null : onMissed,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Missed'),
                ),
              ),
            ],
          ),
          if (entry != null)
            TextButton(onPressed: onClear, child: const Text('Clear status')),
          if (mealSlot != null) ...[
            const Divider(height: 30),
            QuickMealEntryCard(slot: mealSlot!),
          ],
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.free_breakfast_outlined, color: AppColors.mutedText),
          SizedBox(height: 10),
          Text('No routines scheduled today.'),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onOpen});

  final ValueChanged<Widget> onOpen;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.ink,
                    child: Icon(Icons.schedule_rounded, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RoutineSync',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Routine and training',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              onTap: () => _openFromDrawer(context, const DashboardScreen()),
            ),
            _DrawerItem(
              icon: Icons.fitness_center_rounded,
              title: 'Gym technique',
              onTap: () => _openFromDrawer(context, const GymPlanScreen()),
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              title: 'History',
              onTap: () => _openFromDrawer(context, const HistoryScreen()),
            ),
            _DrawerItem(
              icon: Icons.edit_calendar_outlined,
              title: 'Manage routines',
              onTap: () => _openFromDrawer(
                context,
                const RoutineManagerScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFromDrawer(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    onOpen(screen);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: AppColors.bodyText, size: 21),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }
}
