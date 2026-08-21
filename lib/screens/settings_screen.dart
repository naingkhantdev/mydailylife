import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/sync_status_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../widgets/app_drawer.dart';
import '../widgets/section_heading.dart';
import '../widgets/theme_mode_selector.dart';

/// Home for everything that is not part of the daily loop.
///
/// The drawer used to list all nine screens at once, which buried the four
/// that get opened every day. The occasional ones live here instead, together
/// with appearance and the account controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayId = user?.email ?? user?.displayName ?? 'Signed out';
    final sync = ref.watch(syncStatusProvider);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.settings),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionHeading(
            eyebrow: 'APPEARANCE',
            title: 'Theme',
          ),
          const SizedBox(height: 6),
          Text(
            'Auto follows your phone, so the app switches with it at night.',
            style: TextStyle(color: context.palette.mutedText, height: 1.4),
          ),
          const SizedBox(height: 14),
          const ThemeModeSelector(),
          const SizedBox(height: 26),
          const SectionHeading(
            eyebrow: 'REMINDERS',
            title: 'Routine alerts',
          ),
          const SizedBox(height: 12),
          const _ReminderSwitch(),
          const SizedBox(height: 26),
          const SectionHeading(
            eyebrow: 'MORE SCREENS',
            title: 'Logs & planning',
          ),
          const SizedBox(height: 12),
          const _SettingsLink(
            icon: Icons.work_outline_rounded,
            title: 'Work log',
            subtitle: 'What you got done today',
            route: AppRoutes.workLog,
          ),
          const _SettingsLink(
            icon: Icons.nightlight_round,
            title: 'Evening split',
            subtitle: 'Study and gaming notes',
            route: AppRoutes.nightSplit,
          ),
          const _SettingsLink(
            icon: Icons.history_rounded,
            title: 'History',
            subtitle: 'Past days, routines and meals',
            route: AppRoutes.history,
          ),
          const _SettingsLink(
            icon: Icons.edit_calendar_rounded,
            title: 'Routines',
            subtitle: 'Edit the recurring day plan',
            route: AppRoutes.routines,
          ),
          const SizedBox(height: 26),
          const SectionHeading(
            eyebrow: 'ACCOUNT',
            title: 'Your data',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: context.palette.border),
            ),
            child: Row(
              children: [
                Icon(
                  sync.hasUnsaved
                      ? Icons.cloud_off_rounded
                      : sync.isSaving
                          ? Icons.cloud_sync_rounded
                          : Icons.cloud_done_rounded,
                  color: sync.hasUnsaved
                      ? context.palette.warning
                      : context.palette.bodyText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayId,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // A status, not a slogan: this used to claim the data
                      // was saved whether or not any write had succeeded.
                      Text(
                        sync.hasUnsaved
                            ? '${sync.unsaved} change'
                                '${sync.unsaved == 1 ? '' : 's'} not saved yet'
                            : sync.isSaving
                                ? 'Saving…'
                                : 'All changes saved. Only you can see them.',
                        style: TextStyle(
                          color: sync.hasUnsaved
                              ? context.palette.warning
                              : context.palette.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (sync.hasUnsaved) ...[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: sync.isSaving
                  ? null
                  : ref.read(syncStatusProvider.notifier).retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry now'),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(authServiceProvider).signOut();
    if (!navigator.mounted) {
      return;
    }
    navigator.pushReplacementNamed(AppRoutes.login);
  }
}

/// Turns weekly routine reminders on, and says plainly when the platform
/// refuses them instead of leaving a switch that looks enabled but is not.
class _ReminderSwitch extends ConsumerWidget {
  const _ReminderSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderProvider);
    final controller = ref.read(reminderProvider.notifier);
    final isSupported = controller.isSupported;
    final count = controller.scheduledCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Icon(
            settings.isEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_outlined,
            size: 20,
            color: settings.isEnabled
                ? context.palette.primary
                : context.palette.mutedText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remind me when a routine starts',
                  style: TextStyle(
                    color: context.palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(settings, isSupported, count),
                  style: TextStyle(
                    color: settings.permissionDenied || !isSupported
                        ? context.palette.warning
                        : context.palette.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.isEnabled,
            onChanged: !isSupported || settings.isBusy
                ? null
                : (value) => controller.setEnabled(value),
          ),
        ],
      ),
    );
  }

  String _subtitle(ReminderSettings settings, bool isSupported, int count) {
    if (!isSupported) {
      return 'Not available on this device.';
    }
    if (settings.permissionDenied) {
      return 'Blocked in system settings — allow notifications first.';
    }
    if (settings.isBusy) {
      return 'Updating…';
    }
    if (!settings.isEnabled) {
      return 'Uses the start times already on your routines.';
    }
    return count == 1
        ? '1 weekly reminder scheduled.'
        : '$count weekly reminders scheduled.';
  }
}

/// One row into a screen that no longer earns a permanent drawer slot.
class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => Navigator.of(context).pushReplacementNamed(route),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: context.palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.palette.background,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: context.palette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.palette.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.palette.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
