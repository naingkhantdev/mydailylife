import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../providers/routine_provider.dart';
import '../theme/app_colors.dart';

class RoutineManagerScreen extends ConsumerWidget {
  const RoutineManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(routineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage routines')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const Text(
            'YOUR SCHEDULE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Keep the day realistic',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          const Text(
            'Your original tasks are preserved. Edit their time, days, title, '
            'or category—or add a routine that fits your life.',
            style: TextStyle(color: AppColors.mutedText, height: 1.45),
          ),
          const SizedBox(height: 22),
          if (tasks.isEmpty)
            const _EmptyTasks()
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < tasks.length; index++) ...[
                    _TaskRow(
                      task: tasks[index],
                      onEdit: () => _openEditor(context, task: tasks[index]),
                      onDelete: () => _confirmDelete(
                        context,
                        ref,
                        tasks[index],
                      ),
                    ),
                    if (index != tasks.length - 1)
                      const Divider(
                        height: 1,
                        indent: 70,
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

  void _openEditor(BuildContext context, {TaskModel? task}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskEditorScreen(task: task)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text(
          '“${task.title}” will be removed from your future schedule. '
          'Past history remains available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(routineProvider.notifier).deleteTask(task.id);
    }
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryIcon(task.category),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${task.startTime} – ${task.endTime}',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    daySummary(task.recurringDays),
                    style: const TextStyle(
                      color: AppColors.bodyText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Task options',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.task});

  final TaskModel? task;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Set<int> _days;
  late RoutineCategory _category;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _startTime = parseTime(task?.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = parseTime(task?.endTime) ?? const TimeOfDay(hour: 10, minute: 0);
    _days = {...?task?.recurringDays};
    if (_days.isEmpty) _days = {1, 2, 3, 4, 5};
    _category = task?.category ?? RoutineCategory.routine;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit task' : 'New task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task name',
                prefixIcon: Icon(Icons.edit_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a task name'
                  : null,
            ),
            const SizedBox(height: 18),
            const _FieldLabel('TIME'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Starts',
                    value: formatTime(_startTime),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeField(
                    label: 'Ends',
                    value: formatTime(_endTime),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _FieldLabel('REPEATS ON'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(shortDay(day)),
                    selected: _days.contains(day),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _days.add(day);
                        } else {
                          _days.remove(day);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (_days.isEmpty) ...[
              const SizedBox(height: 7),
              const Text(
                'Select at least one day.',
                style: TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            const _FieldLabel('CATEGORY'),
            const SizedBox(height: 8),
            DropdownButtonFormField<RoutineCategory>(
              value: _category,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in RoutineCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(categoryLabel(category)),
                  ),
              ],
              onChanged: (category) {
                if (category != null) setState(() => _category = category);
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(isEditing ? 'Save changes' : 'Add to routine'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (value == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _days.isEmpty) {
      setState(() {});
      return;
    }
    final existing = widget.task;
    final task = TaskModel(
      id: existing?.id ?? 'task-${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      startTime: formatTime(_startTime),
      endTime: formatTime(_endTime),
      recurringDays: _days.toList()..sort(),
      category: _category,
    );
    if (existing == null) {
      ref.read(routineProvider.notifier).addTask(task);
    } else {
      ref.read(routineProvider.notifier).updateTask(task);
    }
    Navigator.of(context).pop();
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.event_note_outlined, size: 42, color: AppColors.mutedText),
          SizedBox(height: 12),
          Text('No tasks yet. Add the first part of your day.'),
        ],
      ),
    );
  }
}

IconData categoryIcon(RoutineCategory category) {
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

String categoryLabel(RoutineCategory category) {
  return switch (category) {
    RoutineCategory.meal => 'Meal',
    RoutineCategory.work => 'Work',
    RoutineCategory.rest => 'Rest',
    RoutineCategory.gym => 'Gym',
    RoutineCategory.study => 'Study',
    RoutineCategory.gaming => 'Gaming',
    RoutineCategory.routine => 'Routine',
  };
}

String daySummary(List<int> days) {
  if (days.length == 7) return 'Every day';
  if (days.length == 5 &&
      const {1, 2, 3, 4, 5}.every(days.contains)) {
    return 'Weekdays';
  }
  final sorted = [...days]..sort();
  return sorted.map(shortDay).join(', ');
}

String shortDay(int day) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[day - 1];
}

TimeOfDay? parseTime(String? label) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(label ?? '');
  if (match == null) return null;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)!;
  if (hour == 12) hour = 0;
  if (period == 'PM') hour += 12;
  return TimeOfDay(hour: hour, minute: minute);
}

String formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '${hour.toString().padLeft(2, '0')}:$minute $period';
}
