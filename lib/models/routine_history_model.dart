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
}

enum RoutineStatus {
  done,
  missed,
}
