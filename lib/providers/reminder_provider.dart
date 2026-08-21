import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../utils/clock_label.dart';
import 'routine_provider.dart';
import 'theme_provider.dart';

const _remindersEnabledKey = 'routine_reminders_enabled';

/// Set in `main()` after the service has initialised, the same way
/// [sharedPreferencesProvider] is.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in ProviderScope',
  );
});

/// Owns the reminders switch and keeps the scheduled notifications in step
/// with the routine list.
///
/// It watches [routineProvider] rather than being called from the editor, so
/// renaming a routine, moving its time or deleting it reschedules on its own.
final reminderProvider =
    StateNotifierProvider<ReminderController, ReminderSettings>((ref) {
  final controller = ReminderController(
    notifications: ref.watch(notificationServiceProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  );
  ref.listen<List<TaskModel>>(
    routineProvider,
    (_, tasks) => controller.syncSchedule(tasks),
    fireImmediately: true,
  );
  return controller;
});

class ReminderSettings {
  const ReminderSettings({
    this.isEnabled = false,
    this.isBusy = false,
    this.permissionDenied = false,
  });

  final bool isEnabled;
  final bool isBusy;

  /// The last attempt to enable reminders was refused by the platform. The
  /// switch stays off, and the UI can say why instead of silently failing.
  final bool permissionDenied;

  ReminderSettings copyWith({
    bool? isEnabled,
    bool? isBusy,
    bool? permissionDenied,
  }) {
    return ReminderSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      isBusy: isBusy ?? this.isBusy,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

class ReminderController extends StateNotifier<ReminderSettings> {
  ReminderController({
    required NotificationService notifications,
    required SharedPreferences preferences,
  })  : _notifications = notifications,
        _preferences = preferences,
        super(
          ReminderSettings(
            isEnabled: preferences.getBool(_remindersEnabledKey) ?? false,
          ),
        );

  final NotificationService _notifications;
  final SharedPreferences _preferences;
  List<TaskModel> _tasks = const [];

  bool get isSupported => _notifications.isReady;

  /// Turns reminders on or off, asking for permission the first time. A
  /// refusal leaves the switch off, because a switch that says "on" while the
  /// OS blocks every notification is worse than no switch.
  Future<void> setEnabled(bool enabled) async {
    if (state.isBusy) {
      return;
    }
    state = state.copyWith(isBusy: true, permissionDenied: false);

    if (!enabled) {
      await _notifications.cancelAll();
      await _persist(false);
      state = state.copyWith(isEnabled: false, isBusy: false);
      return;
    }

    final granted = await _notifications.requestPermission();
    if (!granted) {
      await _persist(false);
      state = state.copyWith(
        isEnabled: false,
        isBusy: false,
        permissionDenied: true,
      );
      return;
    }

    await _notifications.scheduleRoutineReminders(_tasks);
    await _persist(true);
    state = state.copyWith(isEnabled: true, isBusy: false);
  }

  /// Re-schedules against the current routine list, or does nothing while
  /// reminders are off.
  Future<void> syncSchedule(List<TaskModel> tasks) async {
    _tasks = tasks;
    if (!state.isEnabled) {
      return;
    }
    await _notifications.scheduleRoutineReminders(tasks);
  }

  /// How many reminders the current routine list would produce — one per
  /// routine per weekday it runs on.
  int get scheduledCount {
    var total = 0;
    for (final task in _tasks) {
      // Same test the service schedules by, so the count cannot claim a
      // reminder for a routine whose time is free text like "Anytime".
      if (task.title.isEmpty || parseClockLabel(task.startTime) == null) {
        continue;
      }
      total += task.recurringDays
          .where(
            (weekday) =>
                weekday >= DateTime.monday && weekday <= DateTime.sunday,
          )
          .length;
    }
    return total;
  }

  Future<void> _persist(bool enabled) async {
    try {
      await _preferences.setBool(_remindersEnabledKey, enabled);
    } catch (_) {
      // The choice is lost on next launch; this session still honours it.
    }
  }
}
