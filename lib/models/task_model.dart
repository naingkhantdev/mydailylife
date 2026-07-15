class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.recurringDays,
    required this.category,
  });

  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final List<int> recurringDays;
  final RoutineCategory category;

  bool runsOn(DateTime date) => recurringDays.contains(date.weekday);

  TaskModel copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    List<int>? recurringDays,
    RoutineCategory? category,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurringDays: recurringDays ?? this.recurringDays,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'recurringDays': recurringDays,
      'category': category.name,
    };
  }

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      title: map['title'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      recurringDays: List<int>.from(map['recurringDays'] as List? ?? const []),
      category: RoutineCategory.values.firstWhere(
        (category) => category.name == map['category'],
        orElse: () => RoutineCategory.routine,
      ),
    );
  }
}

enum RoutineCategory {
  meal,
  work,
  rest,
  gym,
  study,
  gaming,
  routine,
}
