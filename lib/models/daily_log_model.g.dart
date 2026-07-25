// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealItem _$MealItemFromJson(Map<String, dynamic> json) => MealItem(
      name: json['name'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$MealItemToJson(MealItem instance) => <String, dynamic>{
      'name': instance.name,
      'calories': instance.calories,
      'quantity': instance.quantity,
    };

DailyLogModel _$DailyLogModelFromJson(Map<String, dynamic> json) =>
    DailyLogModel(
      date: DateTime.parse(json['date'] as String),
      workNotes: json['work_notes'] as String? ?? '',
      studyNotes: json['study_notes'] as String? ?? '',
      gamingNotes: json['gaming_notes'] as String? ?? '',
      breakfast: (json['breakfast'] as List<dynamic>?)
              ?.map((e) => MealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lunch: (json['lunch'] as List<dynamic>?)
              ?.map((e) => MealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dinner: (json['dinner'] as List<dynamic>?)
              ?.map((e) => MealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailyLogModelToJson(DailyLogModel instance) =>
    <String, dynamic>{
      'work_notes': instance.workNotes,
      'study_notes': instance.studyNotes,
      'gaming_notes': instance.gamingNotes,
      'breakfast': instance.breakfast,
      'lunch': instance.lunch,
      'dinner': instance.dinner,
    };
