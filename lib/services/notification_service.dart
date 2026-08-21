import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';
import '../utils/clock_label.dart';

/// Weekly reminders for the routines the user already scheduled.
///
/// The whole app is built on a fixed clock — every task carries a start time —
/// but nothing told the user when one arrived, so the app only worked if they
/// remembered to open it. One repeating notification per routine per weekday
/// closes that loop.
///
/// Every method fails soft. A device that refuses notifications, a missing
/// timezone database, a plugin that did not register: none of it may stop the
/// rest of the app from running.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'routine_reminders';
  static const _channelName = 'Routine reminders';
  static const _channelDescription =
      'Tells you when a scheduled routine is due.';

  /// Notification ids have to fit in a 32-bit int, and they have to be stable
  /// so rescheduling replaces a reminder instead of adding another.
  static const _idModulus = 1 << 30;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  bool get isReady => _ready;

  /// Loads the timezone database and registers the plugin. Called once before
  /// `runApp`; scheduling is a no-op until it succeeds.
  Future<void> initialize() async {
    if (_ready) {
      return;
    }

    try {
      tz_data.initializeTimeZones();
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Asked for explicitly when the user turns reminders on, rather than
          // ambushing them with a permission prompt on first launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (error) {
      debugPrint('Notification setup failed: $error');
    }
  }

  /// Asks the platform for permission. Returns false when it is refused, which
  /// is what keeps the settings switch honest.
  Future<bool> requestPermission() async {
    if (!_ready) {
      return false;
    }

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
    }
    return false;
  }

  /// Replaces every scheduled reminder with one per routine per weekday.
  ///
  /// Cancelling first is what keeps a renamed, retimed or deleted routine from
  /// leaving a reminder behind.
  Future<void> scheduleRoutineReminders(List<TaskModel> tasks) async {
    if (!_ready) {
      return;
    }

    await cancelAll();

    try {
      for (final task in tasks) {
        final time = parseClockLabel(task.startTime);
        if (time == null || task.title.isEmpty) {
          continue;
        }

        for (final weekday in task.recurringDays) {
          if (weekday < DateTime.monday || weekday > DateTime.sunday) {
            continue;
          }
          await _plugin.zonedSchedule(
            _idFor(task.id, weekday),
            task.title,
            _bodyFor(task),
            _nextOccurrence(weekday, time),
            _details,
            // Inexact on purpose: a routine reminder does not need to fire to
            // the second, and exact alarms would mean asking for one of
            // Android's most restricted permissions.
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            // Required on this plugin version. Absolute time is what a fixed
            // daily schedule means: 07:00 stays 07:00 across a zone change.
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    } catch (error) {
      debugPrint('Scheduling reminders failed: $error');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) {
      return;
    }
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('Cancelling reminders failed: $error');
    }
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  String _bodyFor(TaskModel task) {
    if (task.endTime.isEmpty) {
      return 'Starts at ${task.startTime}.';
    }
    return '${task.startTime} – ${task.endTime}';
  }

  /// The next time [weekday] falls at [time], today included when it has not
  /// passed yet. `matchDateTimeComponents` repeats it weekly from there.
  tz.TZDateTime _nextOccurrence(int weekday, ClockTime time) {
    final now = tz.TZDateTime.now(tz.local);

    // Rebuilt per day rather than adding 24 hours, so the clock time survives
    // a daylight-saving change instead of drifting by an hour.
    for (var offset = 0; offset <= 7; offset++) {
      final candidate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + offset,
        time.hour,
        time.minute,
      );
      if (candidate.weekday == weekday && candidate.isAfter(now)) {
        return candidate;
      }
    }
    return now.add(const Duration(days: 7));
  }

  int _idFor(String taskId, int weekday) {
    return ('$taskId:$weekday').hashCode.abs() % _idModulus;
  }
}
