import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log_model.dart';

final dailyLogProvider =
    StateNotifierProvider<DailyLogController, DailyLogModel>((ref) {
  return DailyLogController();
});

class DailyLogController extends StateNotifier<DailyLogModel> {
  DailyLogController() : super(DailyLogModel(date: DateTime.now()));

  void addMealItem(MealSlot slot, MealItem item) {
    switch (slot) {
      case MealSlot.breakfast:
        state = state.copyWith(breakfast: [...state.breakfast, item]);
      case MealSlot.lunch:
        state = state.copyWith(lunch: [...state.lunch, item]);
      case MealSlot.dinner:
        state = state.copyWith(dinner: [...state.dinner, item]);
    }
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
  }

  void replace(DailyLogModel log) {
    state = log;
  }
}
