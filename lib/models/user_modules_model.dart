/// Which feature areas a user opted into — at signup, or later in Settings.
///
/// Defaults to every module on, so an account that has never written a
/// `modules` field (every account that existed before this setting did) keeps
/// seeing the full app exactly as it always has.
class UserModulesModel {
  const UserModulesModel({
    this.dietEnabled = true,
    this.timeEnabled = true,
    this.gymEnabled = true,
  });

  static const allEnabled = UserModulesModel();

  final bool dietEnabled;
  final bool timeEnabled;
  final bool gymEnabled;

  bool get hasAnyEnabled => dietEnabled || timeEnabled || gymEnabled;

  UserModulesModel copyWith({
    bool? dietEnabled,
    bool? timeEnabled,
    bool? gymEnabled,
  }) {
    return UserModulesModel(
      dietEnabled: dietEnabled ?? this.dietEnabled,
      timeEnabled: timeEnabled ?? this.timeEnabled,
      gymEnabled: gymEnabled ?? this.gymEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diet_enabled': dietEnabled,
      'time_enabled': timeEnabled,
      'gym_enabled': gymEnabled,
    };
  }

  factory UserModulesModel.fromMap(Map<String, dynamic> map) {
    return UserModulesModel(
      dietEnabled: map['diet_enabled'] as bool? ?? true,
      timeEnabled: map['time_enabled'] as bool? ?? true,
      gymEnabled: map['gym_enabled'] as bool? ?? true,
    );
  }
}
