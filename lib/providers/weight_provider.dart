import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weight_entry_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'sync_status_provider.dart';

/// Body weight readings, newest first.
///
/// This was a `StateProvider<double>` hardcoded to 190 lb: it sat on the
/// dashboard next to real figures and reset on every launch. Stored per day it
/// becomes the one number worth reading as a trend against the calorie log.
final weightProvider =
    StateNotifierProvider<WeightController, List<WeightEntryModel>>((ref) {
  return WeightController(
    firestoreService: ref.watch(firestoreServiceProvider),
    userId: ref.watch(currentUserIdProvider),
    syncStatus: ref.watch(syncStatusProvider.notifier),
  );
});

class WeightController extends StateNotifier<List<WeightEntryModel>> {
  WeightController({
    required FirestoreService firestoreService,
    required String userId,
    required SyncStatusController syncStatus,
  })  : _firestoreService = firestoreService,
        _userId = userId,
        _syncStatus = syncStatus,
        super(const []) {
    _load();
  }

  /// Shown until a first reading exists, so the tile has something to render.
  static const fallbackWeightLb = 190.0;

  final FirestoreService _firestoreService;
  final String _userId;
  final SyncStatusController _syncStatus;
  bool _hasLocalChanges = false;

  WeightEntryModel? get latest => state.isEmpty ? null : state.first;

  double get latestWeightLb => latest?.weightLb ?? fallbackWeightLb;

  bool get hasReading => state.isNotEmpty;

  /// Change since the oldest reading within [days], or `null` when there is
  /// nothing to compare against yet.
  double? changeOver(int days) {
    if (state.length < 2) {
      return null;
    }
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final withinWindow = state
        .where((entry) => !entry.date.isBefore(cutoff))
        .toList();
    // Fall back to the whole run when the window holds a single reading, so a
    // sparse log still shows a direction.
    final comparable = withinWindow.length >= 2 ? withinWindow : state;
    return comparable.first.weightLb - comparable.last.weightLb;
  }

  /// Readings inside [days], oldest first — the order a trend line is drawn.
  List<WeightEntryModel> trend(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final withinWindow = state
        .where((entry) => !entry.date.isBefore(cutoff))
        .toList()
        .reversed
        .toList();
    return withinWindow;
  }

  /// Records today's weight, replacing an earlier reading from the same day.
  void record(double weightLb) {
    if (weightLb <= 0) {
      return;
    }

    final entry = WeightEntryModel(date: DateTime.now(), weightLb: weightLb);
    _hasLocalChanges = true;
    state = [
      entry,
      for (final existing in state)
        if (existing.documentId != entry.documentId) existing,
    ]..sort((a, b) => b.documentId.compareTo(a.documentId));

    _syncStatus.track(
      key: 'weight:${entry.documentId}',
      write: () => _firestoreService.saveWeightEntry(
        userId: _userId,
        entry: entry,
      ),
    );
  }

  Future<void> _load() async {
    try {
      final entries = await _firestoreService.getWeightLog(userId: _userId);
      if (!mounted || _hasLocalChanges) {
        return;
      }
      state = entries;
    } catch (_) {
      // The tile falls back to its placeholder until the read succeeds.
    }
  }
}
