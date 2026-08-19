/// One weekday of the training plan. The title and focus line are stored per
/// user, so the split can move from `Chest 1` to `Leg day` without a code
/// change and without touching the exercises already saved on that day.
class GymDayModel {
  const GymDayModel({
    required this.weekday,
    this.title = '',
    this.focus = '',
    this.isRestDay = false,
  });

  /// Matches `DateTime.weekday`: 1 is Monday through 7 is Sunday. The plan
  /// always holds exactly one entry per weekday, so this doubles as the id.
  final int weekday;
  final String title;
  final String focus;

  /// Rest days keep their exercises (mobility, walking) but drop the set
  /// progress bar, which reads as an unfinished workout otherwise.
  final bool isRestDay;

  String get documentId => 'day-$weekday';

  GymDayModel copyWith({
    String? title,
    String? focus,
    bool? isRestDay,
  }) {
    return GymDayModel(
      weekday: weekday,
      title: title ?? this.title,
      focus: focus ?? this.focus,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekday': weekday,
      'title': title,
      'focus': focus,
      'is_rest_day': isRestDay,
    };
  }

  factory GymDayModel.fromMap(Map<String, dynamic> map) {
    return GymDayModel(
      weekday: (map['weekday'] as num?)?.toInt() ?? 1,
      title: map['title'] as String? ?? '',
      focus: map['focus'] as String? ?? '',
      isRestDay: map['is_rest_day'] as bool? ?? false,
    );
  }
}
