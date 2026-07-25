// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      recurringDays: (json['recurringDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      category: $enumDecodeNullable(_$RoutineCategoryEnumMap, json['category'],
              unknownValue: RoutineCategory.routine) ??
          RoutineCategory.routine,
    );

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
      'title': instance.title,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'recurringDays': instance.recurringDays,
      'category': _$RoutineCategoryEnumMap[instance.category]!,
    };

const _$RoutineCategoryEnumMap = {
  RoutineCategory.meal: 'meal',
  RoutineCategory.work: 'work',
  RoutineCategory.rest: 'rest',
  RoutineCategory.gym: 'gym',
  RoutineCategory.study: 'study',
  RoutineCategory.gaming: 'gaming',
  RoutineCategory.routine: 'routine',
};
