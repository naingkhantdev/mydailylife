/// One exercise inside a day's workout: the target the user set, and which of
/// those sets they have ticked off.
class GymExerciseSession {
  const GymExerciseSession({
    required this.targetSets,
    required this.targetReps,
    required this.completedSets,
    this.weightKg = 0,
  });

  factory GymExerciseSession.empty({
    int targetSets = defaultTargetSets,
    int targetReps = defaultTargetReps,
  }) {
    return GymExerciseSession(
      targetSets: targetSets,
      targetReps: targetReps,
      completedSets: const {},
    );
  }

  static const defaultTargetSets = 3;
  static const defaultTargetReps = 10;

  final int targetSets;
  final int targetReps;
  final Set<int> completedSets;

  /// Working weight for the day, in kilograms. Zero means not recorded — a
  /// bodyweight exercise and an unrecorded one look the same, which is the
  /// honest reading until the user types a number.
  final double weightKg;

  bool get isComplete => completedSets.length >= targetSets;

  bool get hasWeight => weightKg > 0;

  /// Nothing here is worth storing: the user has neither ticked a set nor
  /// changed the target. Pruning these keeps an untick from resurrecting the
  /// exercise on the next load.
  bool get isPristine {
    return completedSets.isEmpty &&
        targetSets == defaultTargetSets &&
        targetReps == defaultTargetReps &&
        weightKg == 0;
  }

  GymExerciseSession copyWith({
    int? targetSets,
    int? targetReps,
    Set<int>? completedSets,
    double? weightKg,
  }) {
    return GymExerciseSession(
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      completedSets: completedSets ?? this.completedSets,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, dynamic> toMap(String exercise) {
    final sets = completedSets.toList()..sort();
    return {
      'name': exercise,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'completed_sets': sets,
      'weight_kg': weightKg,
    };
  }

  factory GymExerciseSession.fromMap(Map<String, dynamic> map) {
    final targetSets =
        (map['target_sets'] as num?)?.toInt() ?? defaultTargetSets;
    final stored = map['completed_sets'] as List<dynamic>? ?? const [];
    final completedSets = <int>{};
    for (final entry in stored) {
      if (entry is! num) {
        continue;
      }
      // A target lowered on a later day would otherwise leave set 4 ticked on
      // a three-set exercise, which no toggle can reach.
      final setNumber = entry.toInt();
      if (setNumber >= 1 && setNumber <= targetSets) {
        completedSets.add(setNumber);
      }
    }

    return GymExerciseSession(
      targetSets: targetSets,
      targetReps: (map['target_reps'] as num?)?.toInt() ?? defaultTargetReps,
      completedSets: completedSets,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A single training day, keyed by date so past days stay readable as history.
///
/// Exercises are stored as an array rather than a map because their names are
/// user-authored and would otherwise become Firestore field names.
class GymSessionLog {
  const GymSessionLog({
    required this.date,
    this.exercises = const {},
  });

  final DateTime date;
  final Map<String, GymExerciseSession> exercises;

  static String dateIdFor(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get documentId => dateIdFor(date);

  GymExerciseSession sessionFor(String exercise) {
    return exercises[exercise] ?? GymExerciseSession.empty();
  }

  /// The same day with every untouched exercise removed, which is what gets
  /// written. An empty result means the document should be deleted instead.
  GymSessionLog get pruned {
    return GymSessionLog(
      date: date,
      exercises: {
        for (final entry in exercises.entries)
          if (!entry.value.isPristine) entry.key: entry.value,
      },
    );
  }

  bool get isEmpty => exercises.isEmpty;

  /// Kilograms actually moved across the day: weight x reps x completed sets,
  /// summed over every exercise. Counts what was ticked, not what was planned,
  /// so unticking a set takes its load back off the total.
  int get totalVolumeKg {
    var total = 0.0;
    for (final session in exercises.values) {
      total +=
          session.weightKg * session.targetReps * session.completedSets.length;
    }
    return total.round();
  }

  /// Exercises that carry a recorded weight, heaviest first.
  List<MapEntry<String, GymExerciseSession>> get loadedExercises {
    final entries = exercises.entries
        .where((entry) => entry.value.hasWeight)
        .toList()
      ..sort((a, b) => b.value.weightKg.compareTo(a.value.weightKg));
    return entries;
  }

  GymSessionLog withExercise(String exercise, GymExerciseSession session) {
    return GymSessionLog(
      date: date,
      exercises: {...exercises, exercise: session},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': documentId,
      'exercises': [
        for (final entry in exercises.entries) entry.value.toMap(entry.key),
      ],
      // Derived, and stored anyway — the same call `DailyLogModel` makes with
      // `total_calories`. It keeps the day's headline number readable straight
      // out of the document instead of rebuilding it from the set lists.
      'total_volume_kg': totalVolumeKg,
    };
  }

  factory GymSessionLog.fromMap(DateTime date, Map<String, dynamic> map) {
    final exercises = <String, GymExerciseSession>{};
    for (final item in (map['exercises'] as List<dynamic>? ?? [])) {
      if (item is! Map) {
        continue;
      }
      final entry = Map<String, dynamic>.from(item);
      final name = entry['name'] as String? ?? '';
      if (name.isEmpty) {
        continue;
      }
      exercises[name] = GymExerciseSession.fromMap(entry);
    }
    return GymSessionLog(date: date, exercises: exercises);
  }
}
