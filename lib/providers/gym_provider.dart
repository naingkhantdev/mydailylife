import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_technique_model.dart';
import '../services/firestore_service.dart';
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
      state = _sorted(saved);
    } catch (_) {
      // The built-in plan remains available while Firestore is unavailable.
    }
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

const _gymDayTemplates = [
  _GymDayTemplate(1, 'Push 1', 'Chest, Shoulders, Triceps'),
  _GymDayTemplate(2, 'Pull 1', 'Back, Rear Delts, Biceps'),
  _GymDayTemplate(3, 'Legs 1 & Core', 'Quads, Calves, Abs'),
  _GymDayTemplate(4, 'Push 2', 'Chest, Shoulders, Triceps'),
  _GymDayTemplate(5, 'Pull 2', 'Back, Biceps'),
  _GymDayTemplate(6, 'Legs 2 & Core', 'Hamstrings, Glutes, Abs'),
  _GymDayTemplate(7, 'Rest & Recovery', 'Mobility, walking, sleep'),
];

const _defaultGymTechniqueEntries = <(int, String)>[
  (1, 'Bench press'),
  (1, 'Incline dumbbell press'),
  (1, 'Shoulder press'),
  (1, 'Lateral raises'),
  (1, 'Triceps pushdowns'),
  (2, 'Pull-ups or lat pulldown'),
  (2, 'Barbell rows'),
  (2, 'Seated cable rows'),
  (2, 'Face pulls'),
  (2, 'Biceps curls'),
  (3, 'Squats'),
  (3, 'Leg press'),
  (3, 'Leg extensions'),
  (3, 'Standing calf raises'),
  (3, 'Plank'),
  (4, 'Incline bench press'),
  (4, 'Machine chest press'),
  (4, 'Arnold press'),
  (4, 'Cable fly'),
  (4, 'Overhead triceps extension'),
  (5, 'Deadlift or rack pull'),
  (5, 'Chest-supported row'),
  (5, 'Single-arm pulldown'),
  (5, 'Hammer curls'),
  (5, 'Preacher curls'),
  (6, 'Romanian deadlift'),
  (6, 'Hip thrust'),
  (6, 'Hamstring curls'),
  (6, 'Walking lunges'),
  (6, 'Hanging knee raises'),
  (7, 'Light walk'),
  (7, 'Stretching'),
  (7, 'Meal prep'),
];

final defaultGymTechniques = <GymTechniqueModel>[
  for (var index = 0; index < _defaultGymTechniqueEntries.length; index++)
    GymTechniqueModel(
      id: 'gym-${_defaultGymTechniqueEntries[index].$1}-$index',
      weekday: _defaultGymTechniqueEntries[index].$1,
      name: _defaultGymTechniqueEntries[index].$2,
    ),
];
