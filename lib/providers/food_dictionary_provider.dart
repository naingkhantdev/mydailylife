import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'sync_status_provider.dart';

final foodDictionaryProvider =
    StateNotifierProvider<FoodDictionaryController, List<MealItem>>((ref) {
  return FoodDictionaryController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
    syncStatus: ref.watch(syncStatusProvider.notifier),
  );
});

/// The list of foods offered when logging a meal.
///
/// Saved per account: a food you add, rename or delete used to live only in
/// memory, so the starter list came back on every restart. Logged meals were
/// never affected — each `MealItem` copies its name and calories into the
/// daily log — but the customised list itself is worth keeping.
class FoodDictionaryController extends StateNotifier<List<MealItem>> {
  FoodDictionaryController({
    required FirestoreService firestoreService,
    required String userId,
    required SyncStatusController syncStatus,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _syncStatus = syncStatus,
        super(starterFoods) {
    _load();
  }

  /// Offered until the account saves its own list. Deleting one of these and
  /// restarting must not bring it back, which is why the saved list replaces
  /// this wholesale rather than merging with it.
  static const starterFoods = <MealItem>[
    MealItem(name: 'Boiled egg', calories: 78),
    MealItem(name: 'Rice', calories: 205),
    MealItem(name: 'White rice', calories: 205),
    MealItem(name: 'Fried rice', calories: 333),
    MealItem(name: 'Chicken breast', calories: 165),
    MealItem(name: 'Chicken thigh', calories: 209),
    MealItem(name: 'Fried chicken', calories: 320),
    MealItem(name: 'Banana', calories: 105),
    MealItem(name: 'Oatmeal', calories: 150),
    MealItem(name: 'Milk', calories: 122),
    MealItem(name: 'Apple', calories: 95),
    MealItem(name: 'Protein shake', calories: 180),
    MealItem(name: 'Tuna', calories: 132),
    MealItem(name: 'Peanut butter', calories: 190),
    MealItem(name: 'Bread slice', calories: 80),
    MealItem(name: 'Noodles', calories: 220),
    MealItem(name: 'Instant noodles', calories: 380),
    MealItem(name: 'Potato', calories: 161),
    MealItem(name: 'Sweet potato', calories: 112),
    MealItem(name: 'Avocado', calories: 240),
    MealItem(name: 'Yogurt', calories: 150),
    MealItem(name: 'Cheese slice', calories: 113),
    MealItem(name: 'Beef', calories: 250),
    MealItem(name: 'Pork', calories: 242),
    MealItem(name: 'Salmon', calories: 208),
    MealItem(name: 'Shrimp', calories: 99),
    MealItem(name: 'Vegetables', calories: 80),
    MealItem(name: 'Salad', calories: 120),
    MealItem(name: 'Coffee', calories: 5),
    MealItem(name: 'Tea', calories: 2),
    MealItem(name: 'Orange juice', calories: 112),
  ];

  final FirestoreService _firestoreService;
  final String _userId;
  final SyncStatusController _syncStatus;
  bool _hasLocalChanges = false;
  bool _saveInProgress = false;
  bool _saveQueued = false;

  void remember(MealItem item) {
    final exists = state.any(
      (food) => food.name.toLowerCase() == item.name.toLowerCase(),
    );
    if (exists) {
      return;
    }

    state = [...state, item];
    _didChange();
  }

  void upsert(MealItem item, {String? previousName}) {
    final targetName = previousName ?? item.name;
    final next = [
      for (final food in state)
        if (food.name.toLowerCase() == targetName.toLowerCase()) item else food,
    ];
    final alreadyExists = next.any(
      (food) => food.name.toLowerCase() == item.name.toLowerCase(),
    );

    state = alreadyExists ? next : [...next, item];
    _didChange();
  }

  void delete(String name) {
    state = [
      for (final food in state)
        if (food.name.toLowerCase() != name.toLowerCase()) food,
    ];
    _didChange();
  }

  void _didChange() {
    _hasLocalChanges = true;
    _queueSave();
  }

  Future<void> _load() async {
    try {
      final saved = await _firestoreService.getFoodDictionary(
        userId: _userId,
      );
      // A null means nothing was ever saved, so the starter list stands. An
      // empty list is a real answer and replaces it.
      if (!mounted || _hasLocalChanges || saved == null) {
        return;
      }
      state = saved;
    } catch (_) {
      // The starter list stays usable when Firestore cannot be reached.
    }
  }

  /// Collapses overlapping writes, so two quick edits cannot land out of order
  /// and leave the older list stored.
  Future<void> _queueSave() async {
    if (_saveInProgress) {
      _saveQueued = true;
      return;
    }

    _saveInProgress = true;
    do {
      _saveQueued = false;
      final foodsToSave = state;
      await _syncStatus.track(
        key: 'food_dictionary',
        write: () => _firestoreService.saveFoodDictionary(
          userId: _userId,
          foods: foodsToSave,
        ),
      );
    } while (mounted && _saveQueued);
    _saveInProgress = false;
  }
}
