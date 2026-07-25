// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_technique_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymTechniqueModel _$GymTechniqueModelFromJson(Map<String, dynamic> json) =>
    GymTechniqueModel(
      id: json['id'] as String,
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      cue: json['cue'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );

Map<String, dynamic> _$GymTechniqueModelToJson(GymTechniqueModel instance) =>
    <String, dynamic>{
      'weekday': instance.weekday,
      'name': instance.name,
      'cue': instance.cue,
      'instructions': instance.instructions,
      'image_url': instance.imageUrl,
    };
