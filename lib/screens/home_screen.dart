import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../models/daily_log_model.dart';
import '../providers/diet_provider.dart';
import '../providers/gym_provider.dart';
import '../providers/history_provider.dart';
import '../providers/routine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/calorie_summary.dart';
import '../widgets/quick_meal_entry_card.dart';
import '../widgets/timeline_card.dart';
import 'dashboard_screen.dart';
import 'diet_screen.dart';
import 'gym_plan_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedTaskId;

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(dailyLogProvider);
    ref.watch(historyProvider);
    final historyController = ref.read(historyProvider.notifier);
    final tasks = ref.watch(routineProvider);
    final todayGym = ref.watch(todayGymProvider);
    final todayTasks = tasks.where((task) => task.runsOn(DateTime.now())).toList();
    final selectedTask = _selectedTask(todayTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RoutineSync'),
      ),
      drawer: _AppDrawer(onOpen: (screen) => _open(context, screen)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Today',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_todayLabel(DateTime.now())}  |  ${todayGym.title}: ${todayGym.focus}',
            style: const TextStyle(color: AppColors.bodyText),
          ),
          const SizedBox(height: 16),
          CalorieSummary(totalCalories: log.totalCalories),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const Icon(Icons.swipe, size: 18, color: AppColors.mutedText),
            ],
          ),
          const SizedBox(height: 12),
          _ScheduleBreadcrumbBar(
            tasks: todayTasks,
            selectedTaskId: selectedTask?.id,
            onSelected: (task) => setState(() => _selectedTaskId = task.id),
          ),
          const SizedBox(height: 14),
          if (selectedTask != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Column(
                key: ValueKey(selectedTask.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${selectedTask.startTime} - ${selectedTask.endTime}',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TimelineCard(
                    task: selectedTask,
                    historyEntry:
                        historyController.entryForToday(selectedTask.id),
                    onDone: () =>
                        _markDone(context, historyController, selectedTask),
                    onMissed: () =>
                        _markMissed(context, historyController, selectedTask),
                    onClear: () => historyController.clearToday(selectedTask),
                  ),
                  if (_mealSlotFor(selectedTask) != null) ...[
                    const SizedBox(height: 8),
                    QuickMealEntryCard(slot: _mealSlotFor(selectedTask)!),
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

  TaskModel? _selectedTask(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return null;
    }

    if (_selectedTaskId != null) {
      for (final task in tasks) {
        if (task.id == _selectedTaskId) {
          return task;
        }
      }
    }

    return _currentTask(tasks, DateTime.now()) ?? tasks.first;
  }

  TaskModel? _currentTask(List<TaskModel> tasks, DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;

    for (final task in tasks) {
      final start = _minutesFromTimeLabel(task.startTime);
      final end = _minutesFromTimeLabel(task.endTime);
      if (start == null || end == null) {
        continue;
      }
      if (nowMinutes >= start && nowMinutes < end) {
        return task;
      }
    }

    TaskModel? latestPastTask;
    var latestPastStart = -1;
    for (final task in tasks) {
      final start = _minutesFromTimeLabel(task.startTime);
      if (start == null) {
        continue;
      }
      if (start <= nowMinutes && start > latestPastStart) {
        latestPastTask = task;
        latestPastStart = start;
      }
    }
    return latestPastTask;
  }

  int? _minutesFromTimeLabel(String label) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(label);
    if (match == null) {
      return null;
    }

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;

    if (period == 'AM' && hour == 12) {
      hour = 0;
    } else if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    return hour * 60 + minute;
  }

  MealSlot? _mealSlotFor(TaskModel task) {
    switch (task.id) {
      case 'breakfast':
        return MealSlot.breakfast;
      case 'lunch':
        return MealSlot.lunch;
      case 'dinner':
        return MealSlot.dinner;
      default:
        return null;
    }
  }

  String _todayLabel(DateTime date) {
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

  Future<void> _markMissed(
    BuildContext context,
    HistoryController controller,
    TaskModel task,
  ) async {
    var enteredRemark = '';
    final remark = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Why missed?'),
          content: TextField(
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => enteredRemark = value,
            decoration: const InputDecoration(
              labelText: 'Remark',
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
                Navigator.of(context).pop(enteredRemark.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (remark != null) {
      controller.markMissed(task, remark);
    }
  }

  Future<void> _markDone(
    BuildContext context,
    HistoryController controller,
    TaskModel task,
  ) async {
    var enteredRemark = '';
    final remark = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('What did you do?'),
          content: TextField(
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => enteredRemark = value,
            decoration: const InputDecoration(
              labelText: 'Remark',
              hintText: 'Example: finished API task, studied Riverpod, walked 20 minutes',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('Done only'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(enteredRemark.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (remark != null) {
      controller.markDone(task, remark: remark);
    }
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RoutineSync',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daily routine, food, gym',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      _ColorChip(color: AppColors.primary),
                      SizedBox(width: 8),
                      _ColorChip(color: AppColors.secondary),
                      SizedBox(width: 8),
                      _ColorChip(color: AppColors.tertiary),
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
              icon: Icons.restaurant,
              title: 'Diet',
              onTap: () => _openFromDrawer(context, const DietScreen()),
            ),
            _DrawerItem(
              icon: Icons.fitness_center,
              title: 'Gym',
              onTap: () => _openFromDrawer(context, const GymPlanScreen()),
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
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ScheduleBreadcrumbBar extends StatelessWidget {
  const _ScheduleBreadcrumbBar({
    required this.tasks,
    required this.selectedTaskId,
    required this.onSelected,
  });

  final List<TaskModel> tasks;
  final String? selectedTaskId;
  final ValueChanged<TaskModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.softMint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: tasks.length,
        separatorBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.secondary,
            ),
          );
        },
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isSelected = task.id == selectedTaskId;
          return Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onSelected(task),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  _shortTime(task.startTime),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    decoration: isSelected ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortTime(String time) {
    return time.replaceAll(' AM', '').replaceAll(' PM', '');
  }
}
