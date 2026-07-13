import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_log_model.dart';
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
}
