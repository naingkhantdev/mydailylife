import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_log_model.dart';
import '../models/gym_technique_model.dart';
import '../models/routine_history_model.dart';
import '../models/task_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore rejects an empty document id, and a widget can rebuild for a
  /// frame while signing out. Every call is a no-op in that window.
  static bool _isSignedOut(String userId) => userId.isEmpty;

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

  Future<List<DailyLogModel>> getDailyLogs({required String userId}) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot = await _dailyLogs(userId).get();
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

  Future<List<RoutineHistoryEntry>> getRoutineHistory({
    required String userId,
  }) async {
    if (_isSignedOut(userId)) return const [];
    final snapshot =
        await _routineHistory(userId).orderBy('date', descending: true).get();
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
