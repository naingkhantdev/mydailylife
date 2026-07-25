// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineHistoryEntry _$RoutineHistoryEntryFromJson(Map<String, dynamic> json) =>
    RoutineHistoryEntry(
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String,
      date: DateTime.parse(json['date'] as String),
      status: $enumDecodeNullable(_$RoutineStatusEnumMap, json['status'],
              unknownValue: RoutineStatus.missed) ??
          RoutineStatus.missed,
      remark: json['remark'] as String? ?? '',
    );

Map<String, dynamic> _$RoutineHistoryEntryToJson(
        RoutineHistoryEntry instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_title': instance.taskTitle,
      'date': instance.date.toIso8601String(),
      'status': _$RoutineStatusEnumMap[instance.status]!,
      'remark': instance.remark,
    };

const _$RoutineStatusEnumMap = {
  RoutineStatus.done: 'done',
  RoutineStatus.missed: 'missed',
};
