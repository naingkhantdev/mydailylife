import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_log_model.dart';
import '../models/gym_day_model.dart';
import '../models/gym_session_model.dart';
import '../models/gym_technique_model.dart';
import '../models/routine_history_model.dart';
import '../models/task_model.dart';
import '../models/weight_entry_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore rejects an empty document id, and a widget can rebuild for a
  /// frame while signing out. Every call is a no-op in that window.
  static bool _isSignedOut(String userId) => userId.isEmpty;

  /// The dictionary lives in a single document inside the `foods` collection.
  static const _foodDictionaryId = 'dictionary';

  /// How far back the history reads reach.
  ///
  /// Every screen that shows the past renders a window of days, so pulling the
  /// whole collection only grew the cost of opening the app: a year of use is
  /// hundreds of documents fetched to draw a seven-day strip.
  static const historyWindowDays = 90;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _dailyLogs(String userId) {
    return _firestore.collection('users').doc(userId).collection('daily_logs');
  }

  CollectionReference<Map<String, dynamic>> _tasks(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>> _routineHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('routine_history');
  }

  CollectionReference<Map<String, dynamic>> _gymTechniques(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('gym_techniques');
  }

  CollectionReference<Map<String, dynamic>> _gymDays(String userId) {
    return _firestore.collection('users').doc(userId).collection('gym_days');
  }

  CollectionReference<Map<String, dynamic>> _weightLog(String userId) {
    return _firestore.collection('users').doc(userId).collection('weight_log');
  }

  CollectionReference<Map<String, dynamic>> _foods(String userId) {
    return _firestore.collection('users').doc(userId).collection('foods');
  }

  CollectionReference<Map<String, dynamic>> _gymSessions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('gym_sessions');
  }

  Future<void> saveDailyLog({
    required String userId,
    required DailyLogModel log,
  }) async {
    if (_isSignedOut(userId)) return;
    return _dailyLogs(userId).doc(log.documentId).set(log.toMap());
  }

  Future<DailyLogModel?> getDailyLog({
    required String userId,
    required DateTime date,
  }) async {
    if (_isSignedOut(userId)) return null;
    final id = DailyLogModel(date: date).documentId;
    final snapshot = await _dailyLogs(userId).doc(id).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return DailyLogModel.fromMap(date, data);
  }

  /// The most recent days, newest first. Document ids are `yyyy-MM-dd`, so
  /// ordering by id is ordering by date without needing a stored field.
  Future<List<DailyLogModel>> getDailyLogs({
    required String userId,
    int limit = historyWindowDays,
  }) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot = await _dailyLogs(userId)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((document) {
          final date = DateTime.tryParse(document.id);
          if (date == null) {
            return null;
          }
          return DailyLogModel.fromMap(date, document.data());
        })
        .whereType<DailyLogModel>()
        .toList();
  }

  /// Live view of one day's log, so a meal added on another device shows up
  /// here without a restart.
  Stream<DailyLogModel?> watchDailyLog({
    required String userId,
    required DateTime date,
  }) {
    if (_isSignedOut(userId)) return Stream<DailyLogModel?>.empty();
    final id = DailyLogModel(date: date).documentId;
    return _dailyLogs(userId).doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : DailyLogModel.fromMap(date, data);
    });
  }

  Future<void> saveTasks({
    required String userId,
    required List<TaskModel> tasks,
  }) async {
    if (_isSignedOut(userId)) return;
    final batch = _firestore.batch();
    for (final task in tasks) {
      batch.set(_tasks(userId).doc(task.id), task.toMap());
    }
    return batch.commit();
  }

  Future<List<TaskModel>> getTasks({required String userId}) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot = await _tasks(userId).get();
    return snapshot.docs
        .map((document) => TaskModel.fromMap(document.id, document.data()))
        .where((task) => task.title.isNotEmpty)
        .toList();
  }

  Future<void> saveTask({
    required String userId,
    required TaskModel task,
  }) async {
    if (_isSignedOut(userId)) return;
    return _tasks(userId).doc(task.id).set(task.toMap());
  }

  Future<void> deleteTask({
    required String userId,
    required String taskId,
  }) async {
    if (_isSignedOut(userId)) return;
    return _tasks(userId).doc(taskId).delete();
  }

  Future<void> saveGymTechniques({
    required String userId,
    required List<GymTechniqueModel> techniques,
  }) async {
    if (_isSignedOut(userId)) return;
    final batch = _firestore.batch();
    for (final technique in techniques) {
      batch.set(
        _gymTechniques(userId).doc(technique.id),
        technique.toMap(),
      );
    }
    return batch.commit();
  }

  Future<List<GymTechniqueModel>> getGymTechniques({
    required String userId,
  }) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot = await _gymTechniques(userId).get();
    return snapshot.docs
        .map(
          (document) => GymTechniqueModel.fromMap(
            document.id,
            document.data(),
          ),
        )
        .where((technique) => technique.name.isNotEmpty)
        .toList();
  }

  Future<void> saveGymTechnique({
    required String userId,
    required GymTechniqueModel technique,
  }) async {
    if (_isSignedOut(userId)) return;
    return _gymTechniques(userId).doc(technique.id).set(technique.toMap());
  }

  Future<void> deleteGymTechnique({
    required String userId,
    required String techniqueId,
  }) async {
    if (_isSignedOut(userId)) return;
    return _gymTechniques(userId).doc(techniqueId).delete();
  }

  Future<void> saveGymDays({
    required String userId,
    required List<GymDayModel> days,
  }) async {
    if (_isSignedOut(userId)) return;
    final batch = _firestore.batch();
    for (final day in days) {
      batch.set(_gymDays(userId).doc(day.documentId), day.toMap());
    }
    return batch.commit();
  }

  Future<List<GymDayModel>> getGymDays({
    required String userId,
  }) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot = await _gymDays(userId).get();
    return snapshot.docs
        .map((document) => GymDayModel.fromMap(document.data()))
        .where((day) => day.weekday >= 1 && day.weekday <= 7)
        .toList();
  }

  Future<void> saveGymDay({
    required String userId,
    required GymDayModel day,
  }) async {
    if (_isSignedOut(userId)) return;
    return _gymDays(userId).doc(day.documentId).set(day.toMap());
  }

  Future<List<GymSessionLog>> getGymSessions({
    required String userId,
    int limit = historyWindowDays,
  }) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot = await _gymSessions(userId)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((document) {
          final date = DateTime.tryParse(document.id);
          if (date == null) {
            return null;
          }
          return GymSessionLog.fromMap(date, document.data());
        })
        .whereType<GymSessionLog>()
        .toList();
  }

  /// Live view of one training day, so a set ticked on another device lands
  /// here while the workout is still open.
  Stream<GymSessionLog?> watchGymSession({
    required String userId,
    required DateTime date,
  }) {
    if (_isSignedOut(userId)) return Stream<GymSessionLog?>.empty();
    final id = GymSessionLog.dateIdFor(date);
    return _gymSessions(userId).doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : GymSessionLog.fromMap(date, data);
    });
  }

  Future<void> saveGymSession({
    required String userId,
    required GymSessionLog log,
  }) async {
    if (_isSignedOut(userId)) return;
    return _gymSessions(userId).doc(log.documentId).set(log.toMap());
  }

  Future<void> deleteGymSession({
    required String userId,
    required String dateId,
  }) async {
    if (_isSignedOut(userId)) return;
    return _gymSessions(userId).doc(dateId).delete();
  }

  /// The saved food dictionary, or `null` when the account has never saved
  /// one.
  ///
  /// The null is meaningful: an empty list means the user deleted every food
  /// and must stay empty, while "never saved" has to fall back to the built-in
  /// starter list.
  Future<List<MealItem>?> getFoodDictionary({required String userId}) async {
    if (_isSignedOut(userId)) return null;
    final snapshot = await _foods(userId).doc(_foodDictionaryId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return [
      for (final item in (data['items'] as List<dynamic>? ?? const []))
        if (item is Map) MealItem.fromMap(Map<String, dynamic>.from(item)),
    ];
  }

  /// Stores the dictionary as one document holding the whole list.
  ///
  /// Per-food documents would need an id for a value the user identifies by
  /// name, and every edit here rewrites the list anyway.
  Future<void> saveFoodDictionary({
    required String userId,
    required List<MealItem> foods,
  }) async {
    if (_isSignedOut(userId)) return;
    return _foods(userId).doc(_foodDictionaryId).set({
      'items': [for (final food in foods) food.toMap()],
    });
  }

  /// Entries inside the history window. `date` is stored as an ISO 8601
  /// string, which sorts and compares chronologically as text.
  Future<List<RoutineHistoryEntry>> getRoutineHistory({
    required String userId,
    int windowDays = historyWindowDays,
  }) async {
    if (_isSignedOut(userId)) return const [];
    final cutoff = DateTime.now().subtract(Duration(days: windowDays));
    final snapshot = await _routineHistory(userId)
        .where('date', isGreaterThanOrEqualTo: cutoff.toIso8601String())
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((document) => RoutineHistoryEntry.fromMap(document.data()))
        .where((entry) => entry.taskId.isNotEmpty)
        .toList();
  }

  Future<void> saveRoutineHistoryEntry({
    required String userId,
    required RoutineHistoryEntry entry,
  }) async {
    if (_isSignedOut(userId)) return;
    return _routineHistory(userId).doc(entry.key).set(entry.toMap());
  }

  Future<void> deleteRoutineHistoryEntry({
    required String userId,
    required String entryKey,
  }) async {
    if (_isSignedOut(userId)) return;
    return _routineHistory(userId).doc(entryKey).delete();
  }

  /// Body weight readings, newest first.
  Future<List<WeightEntryModel>> getWeightLog({
    required String userId,
    int limit = historyWindowDays,
  }) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot = await _weightLog(userId)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((document) {
          final date = DateTime.tryParse(document.id);
          if (date == null) {
            return null;
          }
          return WeightEntryModel.fromMap(date, document.data());
        })
        .whereType<WeightEntryModel>()
        .where((entry) => entry.weightLb > 0)
        .toList();
  }

  Future<void> saveWeightEntry({
    required String userId,
    required WeightEntryModel entry,
  }) async {
    if (_isSignedOut(userId)) return;
    return _weightLog(userId).doc(entry.documentId).set(entry.toMap());
  }

  /// Records the profile document for [userId]. Called on every sign-in.
  Future<void> prepareUserWorkspace({
    required String userId,
    String? email,
    String? displayName,
  }) async {
    if (_isSignedOut(userId)) return;

    await _firestore.collection('users').doc(userId).set({
      'email': email ?? '',
      'display_name': displayName ?? '',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
