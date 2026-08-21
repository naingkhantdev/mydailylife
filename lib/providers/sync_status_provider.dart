import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One place that knows whether the app's background writes are landing.
///
/// Every controller writes optimistically and swallows the failure so the UI
/// never stalls. That is the right behaviour, but on its own it makes a phone
/// with no signal — or an account whose security rules were never deployed
/// — look exactly like one that is saving fine. Routing each write through
/// [SyncStatusController.track] keeps that behaviour and makes the failure
/// visible and retryable.
final syncStatusProvider =
    StateNotifierProvider<SyncStatusController, SyncStatus>((ref) {
  return SyncStatusController();
});

typedef SaveOperation = Future<void> Function();

class SyncStatus {
  const SyncStatus({
    this.pending = 0,
    this.unsaved = 0,
    this.lastError,
  });

  /// Writes currently in flight.
  final int pending;

  /// Documents whose last write failed and are waiting for a retry.
  final int unsaved;

  final Object? lastError;

  bool get isSaving => pending > 0;
  bool get hasUnsaved => unsaved > 0;
}

class SyncStatusController extends StateNotifier<SyncStatus> {
  SyncStatusController() : super(const SyncStatus());

  /// Keyed by document, so a document that keeps failing collapses into one
  /// retry rather than a queue of stale attempts. Each operation re-reads its
  /// controller's current state, so a retry always sends the latest version.
  final Map<String, SaveOperation> _failed = {};
  int _pending = 0;
  Object? _lastError;

  /// Runs [write], reporting it as in-flight and remembering it if it fails.
  Future<void> track({
    required String key,
    required SaveOperation write,
  }) async {
    _pending++;
    _publish();
    try {
      await write();
      _failed.remove(key);
    } catch (error) {
      _failed[key] = write;
      _lastError = error;
    } finally {
      _pending--;
      _publish();
    }
  }

  /// Re-runs every failed write. Anything that fails again lands back in the
  /// pending set, so the banner stays until it genuinely succeeds.
  Future<void> retry() async {
    if (_failed.isEmpty) {
      return;
    }

    final pending = Map<String, SaveOperation>.from(_failed);
    _failed.clear();
    _lastError = null;
    _publish();

    for (final entry in pending.entries) {
      await track(key: entry.key, write: entry.value);
    }
  }

  /// Drops the failures without retrying — the user chose to move on.
  void dismiss() {
    _failed.clear();
    _lastError = null;
    _publish();
  }

  void _publish() {
    if (!mounted) {
      return;
    }
    state = SyncStatus(
      pending: _pending,
      unsaved: _failed.length,
      lastError: _lastError,
    );
  }
}
