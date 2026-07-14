class RoutineHistoryEntry {
  const RoutineHistoryEntry({
    required this.taskId,
    required this.taskTitle,
    required this.date,
    required this.status,
    this.remark = '',
  });

  final String taskId;
  final String taskTitle;
  final DateTime date;
  final RoutineStatus status;
  final String remark;

  String get dateId {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get key => '$dateId:$taskId';

  Map<String, dynamic> toMap() {
    return {
      'task_id': taskId,
      'task_title': taskTitle,
      'date': date.toIso8601String(),
      'status': status.name,
      'remark': remark,
    };
  }

  factory RoutineHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RoutineHistoryEntry(
      taskId: map['task_id'] as String? ?? '',
      taskTitle: map['task_title'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      status: RoutineStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => RoutineStatus.missed,
      ),
      remark: map['remark'] as String? ?? '',
    );
  }
}

enum RoutineStatus {
  done,
  missed,
}
