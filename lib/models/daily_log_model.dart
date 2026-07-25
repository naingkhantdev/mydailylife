import 'package:json_annotation/json_annotation.dart';

part 'daily_log_model.g.dart';

@JsonSerializable()
class MealItem {
  const MealItem({
    this.name = '',
    this.calories = 0,
    this.quantity = 1,
  });

  final String name;
  final int calories;
  final int quantity;

  int get totalCalories => calories * quantity;

  MealItem copyWith({
    String? name,
    int? calories,
    int? quantity,
  }) {
    return MealItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => _$MealItemToJson(this);

  Map<String, dynamic> toMap() => toJson();

  factory MealItem.fromJson(Map<String, dynamic> json) =>
      _$MealItemFromJson(json);

  factory MealItem.fromMap(Map<String, dynamic> map) => MealItem.fromJson(map);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DailyLogModel {
  const DailyLogModel({
    required this.date,
    this.workNotes = '',
    this.studyNotes = '',
    this.gamingNotes = '',
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
  });

  @JsonKey(includeToJson: false)
  final DateTime date;
  final String workNotes;
  final String studyNotes;
  final String gamingNotes;
  final List<MealItem> breakfast;
  final List<MealItem> lunch;
  final List<MealItem> dinner;

  int get totalCalories {
    return [
      ...breakfast,
      ...lunch,
      ...dinner,
    ].fold(0, (total, item) => total + item.totalCalories);
  }

  String get documentId {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DailyLogModel copyWith({
    String? workNotes,
    String? studyNotes,
    String? gamingNotes,
    List<MealItem>? breakfast,
    List<MealItem>? lunch,
    List<MealItem>? dinner,
  }) {
    return DailyLogModel(
      date: date,
      workNotes: workNotes ?? this.workNotes,
      studyNotes: studyNotes ?? this.studyNotes,
      gamingNotes: gamingNotes ?? this.gamingNotes,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
    );
  }

  Map<String, dynamic> toJson() => _$DailyLogModelToJson(this);

  Map<String, dynamic> toMap() => {
        ...toJson(),
        'total_calories': totalCalories,
      };

  factory DailyLogModel.fromJson(Map<String, dynamic> json) =>
      _$DailyLogModelFromJson(json);

  factory DailyLogModel.fromMap(DateTime date, Map<String, dynamic> map) =>
      DailyLogModel.fromJson({
        'date': date.toIso8601String(),
        'work_notes': map['work_notes'] as String? ?? '',
        'study_notes': map['study_notes'] as String? ?? '',
        'gaming_notes': map['gaming_notes'] as String? ?? '',
        'breakfast': _readMealJson(map['breakfast']),
        'lunch': _readMealJson(map['lunch']),
        'dinner': _readMealJson(map['dinner']),
      });
}

List<Map<String, dynamic>> _readMealJson(Object? value) {
  return (value as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

enum MealSlot {
  breakfast,
  lunch,
  dinner,
}
