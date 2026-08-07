import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_technique_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

final gymTechniqueProvider =
    StateNotifierProvider<GymTechniqueController, List<GymTechniqueModel>>(
  (ref) => GymTechniqueController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  ),
);

final gymPlanProvider = Provider<List<GymDay>>((ref) {
  final techniques = ref.watch(gymTechniqueProvider);
  return [
    for (final template in _gymDayTemplates)
      GymDay(
        weekday: template.weekday,
        title: template.title,
        focus: template.focus,
        exercises: [
          for (final technique in techniques)
            if (technique.weekday == template.weekday) technique.name,
        ],
      ),
  ];
});

/// Weekday label for the technique manager, e.g. `Monday · Shoulders & Arms 1`.
String gymDayLabel(int weekday) {
  const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final template = _gymDayTemplates.firstWhere(
    (template) => template.weekday == weekday,
  );
  return '${weekdayNames[weekday - 1]} · ${template.title}';
}

final todayGymProvider = Provider<GymDay>((ref) {
  final plan = ref.watch(gymPlanProvider);
  final weekday = DateTime.now().weekday;
  return plan.firstWhere((day) => day.weekday == weekday);
});

class GymTechniqueController extends StateNotifier<List<GymTechniqueModel>> {
  GymTechniqueController({
    required FirestoreService firestoreService,
    required String userId,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        super(_sorted(defaultGymTechniques)) {
    _loadTechniques();
  }

  final FirestoreService _firestoreService;
  final String _userId;
  bool _hasLocalChanges = false;

  Future<void> addTechnique(GymTechniqueModel technique) async {
    _hasLocalChanges = true;
    state = _sorted([...state, technique]);
    try {
      await _firestoreService.saveGymTechnique(
        userId: _userId,
        technique: technique,
      );
    } catch (_) {
      // Keep the optimistic technique available while offline.
    }
  }

  Future<void> updateTechnique(GymTechniqueModel technique) async {
    _hasLocalChanges = true;
    state = _sorted([
      for (final current in state)
        if (current.id == technique.id) technique else current,
    ]);
    try {
      await _firestoreService.saveGymTechnique(
        userId: _userId,
        technique: technique,
      );
    } catch (_) {
      // Keep the optimistic edit available while offline.
    }
  }

  Future<void> deleteTechnique(String techniqueId) async {
    _hasLocalChanges = true;
    state = [
      for (final technique in state)
        if (technique.id != techniqueId) technique,
    ];
    try {
      await _firestoreService.deleteGymTechnique(
        userId: _userId,
        techniqueId: techniqueId,
      );
    } catch (_) {
      // Keep the optimistic deletion for the current session.
    }
  }

  Future<void> _loadTechniques() async {
    try {
      final saved = await _firestoreService.getGymTechniques(userId: _userId);
      if (!mounted || _hasLocalChanges) return;
      if (saved.isEmpty) {
        await _firestoreService.saveGymTechniques(
          userId: _userId,
          techniques: defaultGymTechniques,
        );
        return;
      }
      final migrated = _withMissingDefaults(
        _withCurrentDefaultSchedule(_withoutRetiredDefaults(saved)),
      );
      state = _sorted(migrated);
      if (!_hasSameTechniques(saved, migrated)) {
        await _firestoreService.saveGymTechniques(
          userId: _userId,
          techniques: migrated,
        );
        await _deleteRetiredDefaults(saved);
      }
    } catch (_) {
      // The built-in plan remains available while Firestore is unavailable.
    }
  }

  static List<GymTechniqueModel> _withoutRetiredDefaults(
    List<GymTechniqueModel> techniques,
  ) {
    return [
      for (final technique in techniques)
        if (!_retiredDefaultTechniqueIds.contains(technique.id)) technique,
    ];
  }

  Future<void> _deleteRetiredDefaults(
    List<GymTechniqueModel> saved,
  ) async {
    for (final technique in saved) {
      if (!_retiredDefaultTechniqueIds.contains(technique.id)) continue;
      try {
        await _firestoreService.deleteGymTechnique(
          userId: _userId,
          techniqueId: technique.id,
        );
      } catch (_) {
        // The next launch retries the cleanup.
      }
    }
  }

  static List<GymTechniqueModel> _withCurrentDefaultSchedule(
    List<GymTechniqueModel> techniques,
  ) {
    final defaultsById = {
      for (final technique in defaultGymTechniques) technique.id: technique,
    };
    return [
      for (final technique in techniques)
        _withCurrentDefaultTechnique(technique, defaultsById),
    ];
  }

  static GymTechniqueModel _withCurrentDefaultTechnique(
    GymTechniqueModel technique,
    Map<String, GymTechniqueModel> defaultsById,
  ) {
    final defaultTechnique = defaultsById[technique.id];
    if (defaultTechnique == null) return technique;

    return GymTechniqueModel(
      id: technique.id,
      weekday: defaultTechnique.weekday,
      name: defaultTechnique.name,
      cue: technique.cue,
      instructions: technique.instructions,
      imageUrl: technique.imageUrl,
    );
  }

  static List<GymTechniqueModel> _withMissingDefaults(
    List<GymTechniqueModel> techniques,
  ) {
    final existingKeys = {
      for (final technique in techniques)
        '${technique.weekday}:${technique.name.toLowerCase()}',
    };
    final missingDefaults = [
      for (final defaultTechnique in defaultGymTechniques)
        if (existingKeys.add(
          '${defaultTechnique.weekday}:${defaultTechnique.name.toLowerCase()}',
        ))
          defaultTechnique,
    ];
    return [...techniques, ...missingDefaults];
  }

  static bool _hasSameTechniques(
    List<GymTechniqueModel> current,
    List<GymTechniqueModel> next,
  ) {
    if (current.length != next.length) return false;

    for (var index = 0; index < current.length; index++) {
      final currentTechnique = current[index];
      final nextTechnique = next[index];
      if (currentTechnique.id != nextTechnique.id ||
          currentTechnique.weekday != nextTechnique.weekday ||
          currentTechnique.name != nextTechnique.name ||
          currentTechnique.cue != nextTechnique.cue ||
          currentTechnique.instructions != nextTechnique.instructions ||
          currentTechnique.imageUrl != nextTechnique.imageUrl) {
        return false;
      }
    }
    return true;
  }

  static List<GymTechniqueModel> _sorted(
    List<GymTechniqueModel> techniques,
  ) {
    final sorted = [...techniques];
    sorted.sort((a, b) {
      final dayComparison = a.weekday.compareTo(b.weekday);
      if (dayComparison != 0) return dayComparison;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }
}

class GymDay {
  const GymDay({
    required this.weekday,
    required this.title,
    required this.focus,
    required this.exercises,
  });

  final int weekday;
  final String title;
  final String focus;
  final List<String> exercises;
}

class _GymDayTemplate {
  const _GymDayTemplate(this.weekday, this.title, this.focus);

  final int weekday;
  final String title;
  final String focus;
}

/// Upper-body only rotation while the leg pain settles: chest, then shoulders
/// and arms, then back, run twice a week around a single rest day.
const _gymDayTemplates = [
  _GymDayTemplate(1, 'Shoulders & Arms 1', 'Delts, biceps, triceps'),
  _GymDayTemplate(2, 'Back 1', 'Lats, mid-back, core'),
  _GymDayTemplate(3, 'Chest 1', 'Flat and incline chest'),
  _GymDayTemplate(4, 'Shoulders & Arms 2', 'Delts, biceps, triceps'),
  _GymDayTemplate(5, 'Back 2', 'Lats, upper back, core'),
  _GymDayTemplate(6, 'Rest & Recovery', 'Mobility, walking, sleep'),
  _GymDayTemplate(7, 'Chest 2', 'Upper chest and pecs'),
];

/// Ids are stable across plan changes so saved cues, instructions and images
/// follow an exercise when it moves to another training day.
const _defaultGymTechniqueEntries = <(String, int, String)>[
  ('gym-2-7', 1, 'Shoulder press'),
  ('gym-2-8', 1, 'Lateral raises'),
  ('gym-3-13', 1, 'Face pulls'),
  ('gym-3-14', 1, 'Biceps curls'),
  ('gym-2-9', 1, 'Triceps pushdowns'),
  ('gym-3-10', 2, 'Pull-ups or lat pulldown'),
  ('gym-3-11', 2, 'Barbell rows'),
  ('gym-3-12', 2, 'Seated cable rows'),
  ('gym-1-4', 2, 'Plank'),
  ('gym-2-5', 3, 'Bench press'),
  ('gym-2-6', 3, 'Incline dumbbell press'),
  ('gym-4-18', 3, 'Cable fly'),
  ('gym-chest-dumbbell-pullover', 3, 'Dumbbell pullover'),
  ('gym-4-17', 4, 'Arnold press'),
  ('gym-shoulders-cable-lateral-raise', 4, 'Cable lateral raise'),
  ('gym-4-19', 4, 'Overhead triceps extension'),
  ('gym-5-23', 4, 'Hammer curls'),
  ('gym-5-24', 4, 'Preacher curls'),
  ('gym-5-21', 5, 'Chest-supported row'),
  ('gym-5-22', 5, 'Single-arm pulldown'),
  ('gym-back-straight-arm-pulldown', 5, 'Straight-arm pulldown'),
  ('gym-back-shrugs', 5, 'Dumbbell shrugs'),
  ('gym-6-29', 5, 'Hanging knee raises'),
  ('gym-7-30', 6, 'Light walk'),
  ('gym-7-31', 6, 'Stretching'),
  ('gym-7-32', 6, 'Meal prep'),
  ('gym-4-15', 7, 'Incline bench press'),
  ('gym-4-16', 7, 'Machine chest press'),
  ('gym-chest-pec-deck', 7, 'Pec deck fly'),
  ('gym-chest-dips', 7, 'Chest dips'),
];

/// Leg-loading exercises pulled out of the plan. They are removed from saved
/// data too, otherwise they would linger on whichever day they were last on.
const _retiredDefaultTechniqueIds = <String>{
  'gym-1-0', // Squats
  'gym-1-1', // Leg press
  'gym-1-2', // Leg extensions
  'gym-1-3', // Standing calf raises
  'gym-5-20', // Deadlift or rack pull
  'gym-6-25', // Romanian deadlift
  'gym-6-26', // Hip thrust
  'gym-6-27', // Hamstring curls
  'gym-6-28', // Walking lunges
};

final defaultGymTechniques = <GymTechniqueModel>[
  for (final entry in _defaultGymTechniqueEntries)
    GymTechniqueModel(
      id: entry.$1,
      weekday: entry.$2,
      name: entry.$3,
    ),
];
