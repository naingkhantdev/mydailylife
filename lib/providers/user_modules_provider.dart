import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_modules_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

export '../models/user_modules_model.dart' show UserModulesModel;

/// Which feature areas the signed-in user opted into. Starts at every module
/// on so the app never flashes a stripped-down drawer while Firestore is
/// still loading — it only narrows once a saved choice comes back.
final userModulesProvider =
    StateNotifierProvider<UserModulesController, UserModulesModel>((ref) {
  return UserModulesController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

class UserModulesController extends StateNotifier<UserModulesModel> {
  UserModulesController({
    required FirestoreService firestoreService,
    required String userId,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        super(UserModulesModel.allEnabled) {
    _load();
  }

  final FirestoreService _firestoreService;
  final String _userId;

  Future<void> _load() async {
    try {
      final loaded = await _firestoreService.getUserModules(userId: _userId);
      if (mounted && loaded != null) {
        state = loaded;
      }
    } catch (_) {
      // Stay on every module enabled rather than guessing from a failed read.
    }
  }

  /// Refuses to save every module off — the app would have nothing left to
  /// show and no way back in without going straight to Settings blind.
  Future<void> setModules(UserModulesModel modules) async {
    if (!modules.hasAnyEnabled) return;

    state = modules;
    try {
      await _firestoreService.saveUserModules(
        userId: _userId,
        modules: modules,
      );
    } catch (_) {
      // Applies locally regardless; the next successful write catches up.
    }
  }
}
