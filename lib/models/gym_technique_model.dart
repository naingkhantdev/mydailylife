import 'package:json_annotation/json_annotation.dart';

part 'gym_technique_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GymTechniqueModel {
  const GymTechniqueModel({
    required this.id,
    this.weekday = 1,
    this.name = '',
    this.cue = '',
    this.instructions = '',
    this.imageUrl = '',
  });

  @JsonKey(includeToJson: false)
  final String id;
  final int weekday;
  final String name;
  final String cue;
  final String instructions;
  final String imageUrl;

  bool get hasCustomGuide {
    return cue.isNotEmpty || instructions.isNotEmpty || imageUrl.isNotEmpty;
  }

  Map<String, dynamic> toJson() => _$GymTechniqueModelToJson(this);

  Map<String, dynamic> toMap() => toJson();

  factory GymTechniqueModel.fromJson(Map<String, dynamic> json) =>
      _$GymTechniqueModelFromJson(json);

  factory GymTechniqueModel.fromMap(String id, Map<String, dynamic> map) =>
      GymTechniqueModel.fromJson({
        ...map,
        'id': id,
        'weekday': (map['weekday'] as num?)?.toInt() ?? 1,
        'name': map['name'] as String? ?? '',
        'cue': map['cue'] as String? ?? '',
        'instructions': map['instructions'] as String? ?? '',
        'image_url': map['image_url'] as String? ?? '',
      });
}
