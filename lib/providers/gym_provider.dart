import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gym_day_model.dart';
import '../models/gym_technique_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'sync_status_provider.dart';

final gymTechniqueProvider =
    StateNotifierProvider<GymTechniqueController, List<GymTechniqueModel>>(
  (ref) => GymTechniqueController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
    syncStatus: ref.watch(syncStatusProvider.notifier),
  ),
);

final gymDayPlanProvider =
    StateNotifierProvider<GymDayPlanController, List<GymDayModel>>(
  (ref) => GymDayPlanController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
    syncStatus: ref.watch(syncStatusProvider.notifier),
  ),
);

final gymPlanProvider = Provider<List<GymDay>>((ref) {
  final days = ref.watch(gymDayPlanProvider);
  final techniques = ref.watch(gymTechniqueProvider);
  return [
    for (final day in days)
      GymDay(
        weekday: day.weekday,
        title: day.title,
        focus: day.focus,
        isRestDay: day.isRestDay,
        exercises: [
          for (final technique in techniques)
            if (technique.weekday == day.weekday) technique.name,
        ],
      ),
  ];
});

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String weekdayName(int weekday) => _weekdayNames[weekday - 1];

/// Weekday label for the technique manager, e.g. `Monday · Leg day`. The title
/// comes from the user's own plan, so it changes as soon as the day is renamed.
String gymDayLabel(int weekday, List<GymDayModel> days) {
  final title = gymDayFor(weekday, days).title.trim();
  if (title.isEmpty) return weekdayName(weekday);
  return '${weekdayName(weekday)} · $title';
}

/// Falls back to the built-in split so a half-written plan never throws.
GymDayModel gymDayFor(int weekday, List<GymDayModel> days) {
  for (final day in days) {
    if (day.weekday == weekday) return day;
  }
  return defaultGymDays[weekday - 1];
}

final todayGymProvider = Provider<GymDay>((ref) {
  final plan = ref.watch(gymPlanProvider);
  final weekday = DateTime.now().weekday;
  return plan.firstWhere((day) => day.weekday == weekday);
});

class GymDayPlanController extends StateNotifier<List<GymDayModel>> {
  GymDayPlanController({
    required FirestoreService firestoreService,
    required String userId,
    required SyncStatusController syncStatus,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _syncStatus = syncStatus,
        super(defaultGymDays) {
    _loadDays();
  }

  final FirestoreService _firestoreService;
  final String _userId;
  final SyncStatusController _syncStatus;
  bool _hasLocalChanges = false;

  Future<void> updateDay(GymDayModel day) async {
    _hasLocalChanges = true;
    state = [
      for (final current in state)
        if (current.weekday == day.weekday) day else current,
    ];
    await _syncStatus.track(
      key: 'gym_day:${day.weekday}',
      write: () => _firestoreService.saveGymDay(userId: _userId, day: day),
    );
  }

  /// Trades the name, focus line and rest flag between two weekdays.
  ///
  /// The weekday numbers themselves never move, because they are the document
  /// ids: what travels is everything the user typed. Pair this with
  /// `GymTechniqueController.swapWeekdays` so the exercises follow the name.
  Future<void> swapDays(int weekdayA, int weekdayB) async {
    if (weekdayA == weekdayB) return;
    final dayA = gymDayFor(weekdayA, state);
    final dayB = gymDayFor(weekdayB, state);
    final movedToA = GymDayModel(
      weekday: weekdayA,
      title: dayB.title,
      focus: dayB.focus,
      isRestDay: dayB.isRestDay,
    );
    final movedToB = GymDayModel(
      weekday: weekdayB,
      title: dayA.title,
      focus: dayA.focus,
      isRestDay: dayA.isRestDay,
    );

    _hasLocalChanges = true;
    state = [
      for (final current in state)
        if (current.weekday == weekdayA)
          movedToA
        else if (current.weekday == weekdayB)
          movedToB
        else
          current,
    ];
    await _syncStatus.track(
      key: 'gym_day:$weekdayA-$weekdayB',
      write: () => _firestoreService.saveGymDays(
        userId: _userId,
        days: [movedToA, movedToB],
      ),
    );
  }

  Future<void> _loadDays() async {
    try {
      final saved = await _firestoreService.getGymDays(userId: _userId);
      if (!mounted || _hasLocalChanges) return;
      if (saved.isEmpty) {
        // A fresh account, or one created before the plan became editable,
        // starts from the built-in split, which is already the current state.
        await _firestoreService.saveGymDays(
          userId: _userId,
          days: defaultGymDays,
        );
        return;
      }
      state = _withEveryWeekday(saved);
    } catch (_) {
      // The built-in split stays available while Firestore is unavailable.
    }
  }

  /// The plan must always render seven days, so a weekday missing from the
  /// saved data falls back to its built-in entry instead of disappearing.
  static List<GymDayModel> _withEveryWeekday(List<GymDayModel> days) {
    final savedByWeekday = {for (final day in days) day.weekday: day};
    return [
      for (final fallback in defaultGymDays)
        savedByWeekday[fallback.weekday] ?? fallback,
    ];
  }
}

class GymTechniqueController extends StateNotifier<List<GymTechniqueModel>> {
  GymTechniqueController({
    required FirestoreService firestoreService,
    required String userId,
    required SyncStatusController syncStatus,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _syncStatus = syncStatus,
        super(_sorted(defaultGymTechniques)) {
    _loadTechniques();
  }

  final FirestoreService _firestoreService;
  final String _userId;
  final SyncStatusController _syncStatus;
  bool _hasLocalChanges = false;

  Future<void> addTechnique(GymTechniqueModel technique) async {
    _hasLocalChanges = true;
    state = _sorted([...state, technique]);
    await _syncStatus.track(
      key: 'gym_technique:${technique.id}',
      write: () => _firestoreService.saveGymTechnique(
        userId: _userId,
        technique: technique,
      ),
    );
  }

  Future<void> updateTechnique(GymTechniqueModel technique) async {
    _hasLocalChanges = true;
    state = _sorted([
      for (final current in state)
        if (current.id == technique.id) technique else current,
    ]);
    await _syncStatus.track(
      key: 'gym_technique:${technique.id}',
      write: () => _firestoreService.saveGymTechnique(
        userId: _userId,
        technique: technique,
      ),
    );
  }

  /// Moves one exercise to another weekday, keeping its id so the cue, steps
  /// and image saved against it come along.
  Future<void> moveTechnique(GymTechniqueModel technique, int weekday) async {
    if (technique.weekday == weekday) return;
    await updateTechnique(technique.copyWith(weekday: weekday));
  }

  /// True when [weekday] already holds an exercise of this name, ignoring
  /// [ignoreId]. A move would otherwise silently stack two `Squats` on one day.
  bool hasNameOnWeekday(String name, int weekday, {String? ignoreId}) {
    final target = name.trim().toLowerCase();
    return state.any(
      (technique) =>
          technique.id != ignoreId &&
          technique.weekday == weekday &&
          technique.name.toLowerCase() == target,
    );
  }

  /// Adds a day type's starter exercises to [weekday] and returns how many
  /// landed. Anything the day already holds by that name is skipped, so
  /// re-picking a preset tops the day up rather than duplicating it.
  ///
  /// Ids are minted fresh rather than reused from the built-in library: the
  /// same exercise can legitimately sit on two days, and a shared id would
  /// make the two entries the same Firestore document.
  Future<int> addPresetExercises(GymDayPreset preset, int weekday) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final additions = <GymTechniqueModel>[];
    for (final name in preset.exercises) {
      if (hasNameOnWeekday(name, weekday)) continue;
      additions.add(
        GymTechniqueModel(
          id: 'gym-$stamp-${additions.length}',
          weekday: weekday,
          name: name,
        ),
      );
    }
    if (additions.isEmpty) return 0;

    _hasLocalChanges = true;
    state = _sorted([...state, ...additions]);
    await _syncStatus.track(
      key: 'gym_techniques:additions',
      write: () => _firestoreService.saveGymTechniques(
        userId: _userId,
        techniques: additions,
      ),
    );
    return additions.length;
  }

  /// Sends every exercise on [weekdayA] to [weekdayB] and back again, so a
  /// whole training day changes place in one action.
  Future<void> swapWeekdays(int weekdayA, int weekdayB) async {
    if (weekdayA == weekdayB) return;
    final moved = [
      for (final technique in state)
        if (technique.weekday == weekdayA)
          technique.copyWith(weekday: weekdayB)
        else if (technique.weekday == weekdayB)
          technique.copyWith(weekday: weekdayA),
    ];
    if (moved.isEmpty) return;

    _hasLocalChanges = true;
    final movedById = {for (final technique in moved) technique.id: technique};
    state = _sorted([
      for (final technique in state) movedById[technique.id] ?? technique,
    ]);
    await _syncStatus.track(
      key: 'gym_techniques:swap',
      write: () => _firestoreService.saveGymTechniques(
        userId: _userId,
        techniques: moved,
      ),
    );
  }

  Future<void> deleteTechnique(String techniqueId) async {
    _hasLocalChanges = true;
    state = [
      for (final technique in state)
        if (technique.id != techniqueId) technique,
    ];
    await _syncStatus.track(
      key: 'gym_technique:$techniqueId',
      write: () => _firestoreService.deleteGymTechnique(
        userId: _userId,
        techniqueId: techniqueId,
      ),
    );
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
      // Saved data wins from here on: the day an exercise sits on, its name and
      // its removal are all the user's to change, so nothing is forced back to
      // the built-in plan on the next launch.
      state = _sorted(saved);
    } catch (_) {
      // The built-in plan remains available while Firestore is unavailable.
    }
  }

  /// Adds every built-in exercise the plan does not already hold and returns
  /// how many were added.
  ///
  /// Only the seeding of a brand new account is automatic, so this is how an
  /// existing plan picks up exercises added to the library later. Nothing
  /// already saved is touched, and an exercise that matches a built-in by day
  /// and name is left alone even when its id differs, so a hand-added `Squats`
  /// does not end up sitting next to the built-in one.
  Future<int> addMissingDefaults() async {
    final existingIds = {for (final technique in state) technique.id};
    final existingKeys = {
      for (final technique in state) _dayNameKey(technique),
    };
    final missing = [
      for (final technique in defaultGymTechniques)
        if (!existingIds.contains(technique.id) &&
            !existingKeys.contains(_dayNameKey(technique)))
          technique,
    ];
    if (missing.isEmpty) return 0;

    _hasLocalChanges = true;
    state = _sorted([...state, ...missing]);
    await _syncStatus.track(
      key: 'gym_techniques:missing',
      write: () => _firestoreService.saveGymTechniques(
        userId: _userId,
        techniques: missing,
      ),
    );
    return missing.length;
  }

  static String _dayNameKey(GymTechniqueModel technique) {
    return '${technique.weekday}:${technique.name.toLowerCase()}';
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
    this.isRestDay = false,
  });

  final int weekday;
  final String title;
  final String focus;
  final List<String> exercises;
  final bool isRestDay;
}

/// A one-tap day type for the day editor.
///
/// Typing `Leg day` plus a focus line every time a split is rearranged is the
/// slow part of moving a training day, so these fill both fields at once. They
/// only prefill the form; the wording stays editable before it is saved.
class GymDayPreset {
  const GymDayPreset({
    required this.label,
    required this.title,
    required this.focus,
    this.exercises = const [],
    this.isRestDay = false,
  });

  final String label;
  final String title;
  final String focus;

  /// A starter set for the day, offered when the preset is picked. Renaming a
  /// day to `Arm day` is only half the job while the day still holds the bench
  /// press, so the exercises can come along in the same step.
  ///
  /// These are names, not ids: the built-in guide in `gym_technique_card.dart`
  /// matches on the exercise name, so a seeded `Hammer curls` gets the same
  /// rich guide as the one already in the library.
  final List<String> exercises;

  final bool isRestDay;
}

const gymDayPresets = <GymDayPreset>[
  GymDayPreset(
    label: 'Chest',
    title: 'Chest day',
    focus: 'Chest, front delts, triceps',
    exercises: [
      'Bench press',
      'Incline bench press',
      'Dumbbell bench press',
      'Machine chest press',
      'Cable fly',
      'Pec deck fly',
      'Chest dips',
      'Dumbbell pullover',
    ],
  ),
  GymDayPreset(
    label: 'Back',
    title: 'Back day',
    focus: 'Lats, mid back, biceps',
    exercises: [
      'Pull-ups or lat pulldown',
      'Barbell rows',
      'Seated cable rows',
      'T-bar row',
      'One-arm dumbbell row',
      'Straight-arm pulldown',
      'Dumbbell shrugs',
    ],
  ),
  GymDayPreset(
    label: 'Legs',
    title: 'Leg day',
    focus: 'Quads, hamstrings, glutes, calves',
    exercises: [
      'Squats',
      'Leg press',
      'Leg extensions',
      'Romanian deadlift',
      'Hamstring curls',
      'Bulgarian split squat',
      'Walking lunges',
      'Standing calf raises',
    ],
  ),
  GymDayPreset(
    label: 'Shoulders',
    title: 'Shoulder day',
    focus: 'Front, side and rear delts, traps',
    exercises: [
      'Shoulder press',
      'Arnold press',
      'Lateral raises',
      'Cable lateral raise',
      'Front raises',
      'Rear delt fly',
      'Face pulls',
      'Dumbbell shrugs',
    ],
  ),
  GymDayPreset(
    label: 'Arms',
    title: 'Arm day',
    focus: 'Biceps, triceps, forearms',
    exercises: [
      'Biceps curls',
      'Hammer curls',
      'Preacher curls',
      'Incline dumbbell curls',
      'Cable curls',
      'Triceps pushdowns',
      'Skull crushers',
      'Overhead triceps extension',
      'Close-grip bench press',
    ],
  ),
  GymDayPreset(
    label: 'Push',
    title: 'Push day',
    focus: 'Chest, shoulders, triceps',
    exercises: [
      'Bench press',
      'Incline dumbbell press',
      'Shoulder press',
      'Lateral raises',
      'Cable fly',
      'Triceps pushdowns',
      'Overhead triceps extension',
    ],
  ),
  GymDayPreset(
    label: 'Pull',
    title: 'Pull day',
    focus: 'Back, rear delts, biceps',
    exercises: [
      'Pull-ups or lat pulldown',
      'Barbell rows',
      'Seated cable rows',
      'Face pulls',
      'Rear delt fly',
      'Biceps curls',
      'Hammer curls',
    ],
  ),
  GymDayPreset(
    label: 'Core',
    title: 'Core day',
    focus: 'Abs, obliques, lower back',
    exercises: [
      'Plank',
      'Hanging knee raises',
      'Cable crunches',
      'Russian twists',
      'Dead bug',
    ],
  ),
  GymDayPreset(
    label: 'Full body',
    title: 'Full body',
    focus: 'One big lift per movement pattern',
    exercises: [
      'Squats',
      'Bench press',
      'Barbell rows',
      'Shoulder press',
      'Romanian deadlift',
      'Plank',
    ],
  ),
  GymDayPreset(
    label: 'Cardio',
    title: 'Cardio & conditioning',
    focus: 'Intervals, incline walking, rower',
    exercises: [
      'Incline treadmill walk',
      'Rowing machine intervals',
      'Cycling intervals',
      'Stair climber',
    ],
  ),
  GymDayPreset(
    label: 'Rest',
    title: 'Rest & Recovery',
    focus: 'Mobility, walking, sleep',
    exercises: [
      'Light walk',
      'Stretching',
      'Foam rolling',
      'Hip and shoulder mobility flow',
    ],
    isRestDay: true,
  ),
];

/// What a fresh account starts with. Every title, focus line and rest-day flag
/// is stored per user from then on, so turning Wednesday into something else is
/// an edit inside the app rather than a code change.
const defaultGymDays = <GymDayModel>[
  GymDayModel(weekday: 1, title: 'Push 1', focus: 'Chest, shoulders, triceps'),
  GymDayModel(weekday: 2, title: 'Pull 1', focus: 'Back, rear delts, biceps'),
  GymDayModel(
    weekday: 3,
    title: 'Legs 1 & Core',
    focus: 'Quads, calves, abs',
  ),
  GymDayModel(weekday: 4, title: 'Push 2', focus: 'Chest, shoulders, triceps'),
  GymDayModel(weekday: 5, title: 'Pull 2', focus: 'Back, biceps'),
  GymDayModel(
    weekday: 6,
    title: 'Legs 2 & Core',
    focus: 'Hamstrings, glutes, abs',
  ),
  GymDayModel(
    weekday: 7,
    title: 'Rest & Recovery',
    focus: 'Mobility, walking, sleep',
    isRestDay: true,
  ),
];

/// The built-in exercise library, seeded into a new account and available to an
/// existing one through `addMissingDefaults`.
///
/// Ids are stable across plan changes so saved cues, instructions and images
/// follow an exercise when it moves to another training day. The ids read as
/// `gym-<old index>` for entries that predate the editable plan; keeping them
/// is what stops those saved guides from being orphaned.
///
/// Entries carry no cue or instructions on purpose: an empty cue lets the rich
/// built-in guide in `gym_technique_card.dart` answer for the exercise, while
/// filling one in would replace that guide with the generic custom template.
const _defaultGymTechniqueEntries = <(String, int, String)>[
  // Push 1 — chest, shoulders, triceps.
  ('gym-2-5', 1, 'Bench press'),
  ('gym-2-6', 1, 'Incline dumbbell press'),
  ('gym-push-db-bench-press', 1, 'Dumbbell bench press'),
  ('gym-2-7', 1, 'Shoulder press'),
  ('gym-2-8', 1, 'Lateral raises'),
  ('gym-4-18', 1, 'Cable fly'),
  ('gym-chest-dips', 1, 'Chest dips'),
  ('gym-2-9', 1, 'Triceps pushdowns'),
  ('gym-push-close-grip-bench', 1, 'Close-grip bench press'),
  ('gym-push-front-raise', 1, 'Front raises'),

  // Pull 1 — back, rear delts, biceps.
  ('gym-3-10', 2, 'Pull-ups or lat pulldown'),
  ('gym-3-11', 2, 'Barbell rows'),
  ('gym-3-12', 2, 'Seated cable rows'),
  ('gym-pull-t-bar-row', 2, 'T-bar row'),
  ('gym-back-straight-arm-pulldown', 2, 'Straight-arm pulldown'),
  ('gym-3-13', 2, 'Face pulls'),
  ('gym-pull-rear-delt-fly', 2, 'Rear delt fly'),
  ('gym-back-shrugs', 2, 'Dumbbell shrugs'),
  ('gym-3-14', 2, 'Biceps curls'),
  ('gym-pull-cable-curl', 2, 'Cable curls'),

  // Legs 1 & Core — quads, calves, abs.
  ('gym-1-0', 3, 'Squats'),
  ('gym-legs-front-squat', 3, 'Front squat'),
  ('gym-1-1', 3, 'Leg press'),
  ('gym-1-2', 3, 'Leg extensions'),
  ('gym-legs-bulgarian-split-squat', 3, 'Bulgarian split squat'),
  ('gym-6-28', 3, 'Walking lunges'),
  ('gym-1-3', 3, 'Standing calf raises'),
  ('gym-legs-seated-calf-raise', 3, 'Seated calf raises'),
  ('gym-1-4', 3, 'Plank'),
  ('gym-core-cable-crunch', 3, 'Cable crunches'),

  // Push 2 — chest, shoulders, triceps.
  ('gym-4-15', 4, 'Incline bench press'),
  ('gym-4-16', 4, 'Machine chest press'),
  ('gym-chest-pec-deck', 4, 'Pec deck fly'),
  ('gym-chest-dumbbell-pullover', 4, 'Dumbbell pullover'),
  ('gym-4-17', 4, 'Arnold press'),
  ('gym-push-machine-shoulder-press', 4, 'Machine shoulder press'),
  ('gym-shoulders-cable-lateral-raise', 4, 'Cable lateral raise'),
  ('gym-push-upright-row', 4, 'Upright row'),
  ('gym-4-19', 4, 'Overhead triceps extension'),
  ('gym-push-skull-crushers', 4, 'Skull crushers'),

  // Pull 2 — back, biceps.
  ('gym-5-20', 5, 'Deadlift or rack pull'),
  ('gym-5-21', 5, 'Chest-supported row'),
  ('gym-pull-one-arm-db-row', 5, 'One-arm dumbbell row'),
  ('gym-pull-wide-grip-pulldown', 5, 'Wide-grip lat pulldown'),
  ('gym-5-22', 5, 'Single-arm pulldown'),
  ('gym-pull-inverted-row', 5, 'Inverted row'),
  ('gym-5-23', 5, 'Hammer curls'),
  ('gym-5-24', 5, 'Preacher curls'),
  ('gym-pull-incline-db-curl', 5, 'Incline dumbbell curls'),
  ('gym-6-29', 5, 'Hanging knee raises'),

  // Legs 2 & Core — hamstrings, glutes, abs.
  ('gym-6-25', 6, 'Romanian deadlift'),
  ('gym-legs-single-leg-rdl', 6, 'Single-leg Romanian deadlift'),
  ('gym-6-27', 6, 'Hamstring curls'),
  ('gym-6-26', 6, 'Hip thrust'),
  ('gym-legs-glute-bridge', 6, 'Glute bridge'),
  ('gym-legs-good-morning', 6, 'Good mornings'),
  ('gym-legs-step-up', 6, 'Dumbbell step-ups'),
  ('gym-legs-calf-press', 6, 'Calf press on the leg press'),
  ('gym-core-russian-twist', 6, 'Russian twists'),
  ('gym-core-dead-bug', 6, 'Dead bug'),

  // Rest & Recovery.
  ('gym-7-30', 7, 'Light walk'),
  ('gym-7-31', 7, 'Stretching'),
  ('gym-rest-foam-rolling', 7, 'Foam rolling'),
  ('gym-rest-mobility-flow', 7, 'Hip and shoulder mobility flow'),
  ('gym-7-32', 7, 'Meal prep'),
];

final defaultGymTechniques = <GymTechniqueModel>[
  for (final entry in _defaultGymTechniqueEntries)
    GymTechniqueModel(
      id: entry.$1,
      weekday: entry.$2,
      name: entry.$3,
    ),
];
