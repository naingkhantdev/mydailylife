import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_log_model.dart';
import '../models/routine_history_model.dart';
import '../models/task_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

  Future<void> saveDailyLog({
    required String userId,
    required DailyLogModel log,
  }) {
    return _dailyLogs(userId).doc(log.documentId).set(log.toMap());
  }

  Future<DailyLogModel?> getDailyLog({
    required String userId,
    required DateTime date,
  }) async {
    final id = DailyLogModel(date: date).documentId;
    final snapshot = await _dailyLogs(userId).doc(id).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return DailyLogModel.fromMap(date, data);
  }

  Future<void> saveTasks({
    required String userId,
    required List<TaskModel> tasks,
  }) async {
    final batch = _firestore.batch();
    for (final task in tasks) {
      batch.set(_tasks(userId).doc(task.id), task.toMap());
    }
    return batch.commit();
  }

  Future<List<RoutineHistoryEntry>> getRoutineHistory({
    required String userId,
  }) async {
    final snapshot = await _routineHistory(userId)
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
  }) {
    return _routineHistory(userId).doc(entry.key).set(entry.toMap());
  }

  Future<void> deleteRoutineHistoryEntry({
    required String userId,
    required String entryKey,
  }) {
    return _routineHistory(userId).doc(entryKey).delete();
  }
}
