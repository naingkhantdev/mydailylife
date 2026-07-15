import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';
import '../services/firestore_service.dart';
import 'firestore_provider.dart';

final dailyLogProvider =
    StateNotifierProvider<DailyLogController, DailyLogModel>((ref) {
  return DailyLogController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final dailyLogHistoryProvider = FutureProvider<List<DailyLogModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getDailyLogs(
        userId: ref.watch(currentUserIdProvider),
      );
});

class DailyLogController extends StateNotifier<DailyLogModel> {
  DailyLogController({
    required FirestoreService firestoreService,
    required String userId,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        super(DailyLogModel(date: DateTime.now())) {
    _loadToday();
  }

  final FirestoreService _firestoreService;
  final String _userId;
  bool _hasLocalChanges = false;
  bool _saveInProgress = false;
  bool _saveQueued = false;

  void addMealItem(MealSlot slot, MealItem item) {
    switch (slot) {
      case MealSlot.breakfast:
        state = state.copyWith(breakfast: [...state.breakfast, item]);
      case MealSlot.lunch:
        state = state.copyWith(lunch: [...state.lunch, item]);
      case MealSlot.dinner:
        state = state.copyWith(dinner: [...state.dinner, item]);
    }
    _didChange();
  }

  void removeMealItem(MealSlot slot, int index) {
    List<MealItem> removeAt(List<MealItem> items) {
      return [
        for (var i = 0; i < items.length; i++)
          if (i != index) items[i],
      ];
    }

    switch (slot) {
      case MealSlot.breakfast:
        state = state.copyWith(breakfast: removeAt(state.breakfast));
      case MealSlot.lunch:
        state = state.copyWith(lunch: removeAt(state.lunch));
      case MealSlot.dinner:
        state = state.copyWith(dinner: removeAt(state.dinner));
    }
    _didChange();
  }

  void updateNotes({
    String? workNotes,
    String? studyNotes,
    String? gamingNotes,
  }) {
    state = state.copyWith(
      workNotes: workNotes,
      studyNotes: studyNotes,
      gamingNotes: gamingNotes,
    );
    _didChange();
  }

  void replace(DailyLogModel log) {
    state = log;
    _didChange();
  }

  void _didChange() {
    _hasLocalChanges = true;
    _queueSave();
  }

  Future<void> _loadToday() async {
    try {
      final log = await _firestoreService.getDailyLog(
        userId: _userId,
        date: state.date,
      );
      if (!mounted || _hasLocalChanges || log == null) {
        return;
      }
      state = log;
    } catch (_) {
      // Keep the local day available when Firestore cannot be reached.
    }
  }

  Future<void> _queueSave() async {
    if (_saveInProgress) {
      _saveQueued = true;
      return;
    }

    _saveInProgress = true;
    do {
      _saveQueued = false;
      final logToSave = state;
      try {
        await _firestoreService.saveDailyLog(
          userId: _userId,
          log: logToSave,
        );
      } catch (_) {
        // Optimistic local edits remain available for the current session.
      }
    } while (mounted && _saveQueued);
    _saveInProgress = false;
  }
}
