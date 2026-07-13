class MealItem {
  const MealItem({
    required this.name,
    required this.calories,
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'quantity': quantity,
    };
  }

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      name: map['name'] as String? ?? '',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

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

  Map<String, dynamic> toMap() {
    return {
      'work_notes': workNotes,
      'study_notes': studyNotes,
      'gaming_notes': gamingNotes,
      'breakfast': breakfast.map((item) => item.toMap()).toList(),
      'lunch': lunch.map((item) => item.toMap()).toList(),
      'dinner': dinner.map((item) => item.toMap()).toList(),
      'total_calories': totalCalories,
    };
  }

  factory DailyLogModel.fromMap(DateTime date, Map<String, dynamic> map) {
    List<MealItem> readMeal(String key) {
      return (map[key] as List? ?? const [])
          .whereType<Map>()
          .map((item) => MealItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return DailyLogModel(
      date: date,
      workNotes: map['work_notes'] as String? ?? '',
      studyNotes: map['study_notes'] as String? ?? '',
      gamingNotes: map['gaming_notes'] as String? ?? '',
      breakfast: readMeal('breakfast'),
      lunch: readMeal('lunch'),
      dinner: readMeal('dinner'),
    );
  }
}

enum MealSlot {
  breakfast,
  lunch,
  dinner,
}
