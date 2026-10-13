import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/task_model.dart';
import '../providers/routine_provider.dart';
import '../theme/app_palette.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/menu_row.dart';
import '../widgets/section_heading.dart';

class RoutineManagerScreen extends ConsumerWidget {
  const RoutineManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(routineProvider);
    final strings = context.strings;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.routines),
      appBar: AppBar(title: Text(strings.manageRoutines)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.addTask),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SectionHeading(
            eyebrow: strings.yourScheduleEyebrow,
            title: strings.keepDayRealistic,
          ),
          const SizedBox(height: 7),
          Text(
            strings.routinesIntro,
            style: TextStyle(color: context.palette.mutedText, height: 1.45),
          ),
          const SizedBox(height: 22),
          if (tasks.isEmpty)
            EmptyState(
              icon: Icons.event_note_outlined,
              title: strings.noTasksYet,
              message: strings.noTasksYetHint,
              iconColor: context.palette.primary,
              iconBackground: context.palette.blueSoft,
              actionLabel: strings.addFirstTask,
              onAction: () => _openEditor(context),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.palette.border),
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
                      Divider(
                        height: 1,
                        indent: 70,
                        color: context.palette.divider,
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
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteTaskTitle),
        content: Text(strings.deleteTaskBody(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.palette.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
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
                color: context.palette.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryIcon(task.category),
                color: context.palette.primary,
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
                    style: TextStyle(
                      color: context.palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${task.startTime} – ${task.endTime}',
                    style: TextStyle(
                      color: context.palette.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    daySummary(context.strings, task.recurringDays),
                    style: TextStyle(
                      color: context.palette.bodyText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: context.strings.taskOptions,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: MenuRow(
                    icon: Icons.edit_outlined,
                    label: context.strings.edit,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: MenuRow(
                    icon: Icons.delete_outline_rounded,
                    label: context.strings.delete,
                    color: context.palette.danger,
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
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? strings.editTask : strings.newTask),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: strings.taskName,
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.enterTaskName
                  : null,
            ),
            const SizedBox(height: 18),
            _FieldLabel(strings.timeLabel),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: strings.starts,
                    value: formatTime(_startTime),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeField(
                    label: strings.ends,
                    value: formatTime(_endTime),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FieldLabel(strings.repeatsOn),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(
                      strings.weekdayShort(day),
                      style: TextStyle(
                        color: _days.contains(day)
                            ? context.palette.onPrimary
                            : context.palette.bodyText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
              Text(
                strings.selectOneDay,
                style: TextStyle(color: context.palette.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            _FieldLabel(strings.categoryEyebrow),
            const SizedBox(height: 8),
            DropdownButtonFormField<RoutineCategory>(
              value: _category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in RoutineCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(strings.category(category)),
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
                child: Text(
                  isEditing ? strings.saveChanges : strings.addToRoutine,
                ),
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
      style: TextStyle(
        color: context.palette.mutedText,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
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

String daySummary(AppStrings strings, List<int> days) {
  if (days.length == 7) return strings.everyDay;
  if (days.length == 5 &&
      const {1, 2, 3, 4, 5}.every(days.contains)) {
    return strings.weekdaysOnly;
  }
  final sorted = [...days]..sort();
  return sorted.map(strings.weekdayShort).join(strings.listSeparator);
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
