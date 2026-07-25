import 'package:json_annotation/json_annotation.dart';

part 'routine_history_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RoutineHistoryEntry {
  const RoutineHistoryEntry({
    required this.taskId,
    required this.taskTitle,
    required this.date,
    this.status = RoutineStatus.missed,
    this.remark = '',
  });

  final String taskId;
  final String taskTitle;
  final DateTime date;
  @JsonKey(unknownEnumValue: RoutineStatus.missed)
  final RoutineStatus status;
  final String remark;

  String get dateId {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get key => '$dateId:$taskId';

  Map<String, dynamic> toJson() => _$RoutineHistoryEntryToJson(this);

  Map<String, dynamic> toMap() => toJson();

  factory RoutineHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$RoutineHistoryEntryFromJson(json);

  factory RoutineHistoryEntry.fromMap(Map<String, dynamic> map) =>
      RoutineHistoryEntry.fromJson({
        ...map,
        'task_id': map['task_id'] as String? ?? '',
        'task_title': map['task_title'] as String? ?? '',
        'date': DateTime.tryParse(map['date'] as String? ?? '')
                ?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'status': map['status'] as String? ?? RoutineStatus.missed.name,
        'remark': map['remark'] as String? ?? '',
      });
}

enum RoutineStatus {
  done,
  missed,
}
