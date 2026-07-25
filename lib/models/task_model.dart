import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel {
  const TaskModel({
    required this.id,
    this.title = '',
    this.startTime = '',
    this.endTime = '',
    this.recurringDays = const [],
    this.category = RoutineCategory.routine,
  });

  @JsonKey(includeToJson: false)
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final List<int> recurringDays;
  @JsonKey(unknownEnumValue: RoutineCategory.routine)
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

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  Map<String, dynamic> toMap() => toJson();

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) =>
      TaskModel.fromJson({
        ...map,
        'id': id,
        'title': map['title'] as String? ?? '',
        'startTime': map['startTime'] as String? ?? '',
        'endTime': map['endTime'] as String? ?? '',
        'recurringDays': List<int>.from(
          map['recurringDays'] as List? ?? const [],
        ),
        'category': map['category'] as String? ?? RoutineCategory.routine.name,
      });
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
