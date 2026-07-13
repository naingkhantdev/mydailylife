import 'package:flutter/material.dart';

import '../models/routine_history_model.dart';
import '../models/task_model.dart';

class TimelineCard extends StatelessWidget {
  const TimelineCard({
    super.key,
    required this.task,
    this.historyEntry,
    required this.onDone,
    required this.onMissed,
    required this.onClear,
  });

  final TaskModel task;
  final RoutineHistoryEntry? historyEntry;
  final VoidCallback onDone;
  final VoidCallback onMissed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final status = historyEntry?.status;
    final isDone = status == RoutineStatus.done;
    final isMissed = status == RoutineStatus.missed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _categoryIcon(task.category),
                  color: const Color(0xFF374151),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration:
                            isMissed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (historyEntry?.remark.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text(
                        historyEntry!.remark,
                        style: TextStyle(
                          color: isMissed
                              ? const Color(0xFFB42318)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: isDone ? null : onDone,
                icon: const Icon(Icons.check),
                label: const Text('Done + remark'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isMissed ? null : onMissed,
                icon: const Icon(Icons.close),
                label: const Text('Missed'),
              ),
              const Spacer(),
              if (status != null) ...[
                IconButton(
                  tooltip: 'Clear status',
                  onPressed: onClear,
                  icon: const Icon(Icons.undo),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.meal:
        return Icons.restaurant;
      case RoutineCategory.work:
        return Icons.work_outline;
      case RoutineCategory.rest:
        return Icons.airline_seat_recline_normal;
      case RoutineCategory.gym:
        return Icons.fitness_center;
      case RoutineCategory.study:
        return Icons.menu_book;
      case RoutineCategory.gaming:
        return Icons.sports_esports;
      case RoutineCategory.routine:
        return Icons.event_available;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RoutineStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const SizedBox.shrink();
    }

    final isDone = status == RoutineStatus.done;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDone ? 'Done' : 'Missed',
        style: TextStyle(
          color: isDone ? const Color(0xFF166534) : const Color(0xFF991B1B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
