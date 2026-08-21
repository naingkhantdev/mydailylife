import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_status_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';

/// App-wide notice that something did not save.
///
/// Wrapped around the navigator in `MaterialApp.builder`, so it covers every
/// screen without each one having to opt in. It stays silent while writes are
/// landing — a pill that flashes on every ticked set is noise — and only
/// appears when a write has actually failed, where it offers the retry.
///
/// Deliberately **not** a `ConsumerWidget`. This sits directly above the app's
/// navigator, which carries a `GlobalKey`: rebuilding it — or changing the
/// length of its children list — reparents the entire app subtree and trips
/// `InheritedElement.debugDeactivated`'s `_dependents.isEmpty` assertion. So
/// the layout here is fixed and const, and only the leaf watches the provider.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Expand, not the default loose fit: the navigator was getting tight
      // constraints before this widget wrapped it, and it should keep them.
      fit: StackFit.expand,
      children: [
        child,
        // Always present, always const, always the second slot. It renders
        // nothing at all until there is something to report.
        const Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: _UnsavedNotice(),
          ),
        ),
      ],
    );
  }
}

class _UnsavedNotice extends ConsumerWidget {
  const _UnsavedNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final count = status.unsaved;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final controller = ref.read(syncStatusProvider.notifier);

    return Material(
      color: palette.warningSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      elevation: 6,
      shadowColor: palette.shadow,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: palette.warning.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 19, color: palette.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1
                        ? '1 change is not saved'
                        : '$count changes are not saved',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    status.isSaving
                        ? 'Retrying…'
                        : 'They are still here — reconnect and retry.',
                    style: TextStyle(
                      color: palette.bodyText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: status.isSaving ? null : controller.retry,
              child: const Text('Retry'),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: controller.dismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: palette.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
