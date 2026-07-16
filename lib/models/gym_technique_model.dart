class GymTechniqueModel {
  const GymTechniqueModel({
    required this.id,
    required this.weekday,
    required this.name,
    this.cue = '',
    this.instructions = '',
    this.imageUrl = '',
  });

  final String id;
  final int weekday;
  final String name;
  final String cue;
  final String instructions;
  final String imageUrl;

  bool get hasCustomGuide {
    return cue.isNotEmpty || instructions.isNotEmpty || imageUrl.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'weekday': weekday,
      'name': name,
      'cue': cue,
      'instructions': instructions,
      'image_url': imageUrl,
    };
  }

  factory GymTechniqueModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return GymTechniqueModel(
      id: id,
      weekday: (map['weekday'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? '',
      cue: map['cue'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
    );
  }
}
