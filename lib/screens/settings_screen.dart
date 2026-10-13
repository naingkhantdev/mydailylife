import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/sync_status_provider.dart';
import '../providers/user_modules_provider.dart';
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
    final strings = context.strings;
    final user = ref.watch(currentUserProvider);
    final displayId = user?.email ?? user?.displayName ?? strings.signedOut;
    final sync = ref.watch(syncStatusProvider);
    final modules = ref.watch(userModulesProvider);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.settings),
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionHeading(
            eyebrow: strings.languageEyebrow,
            title: strings.appLanguage,
          ),
          const SizedBox(height: 14),
          const LanguageSelector(),
          const SizedBox(height: 26),
          SectionHeading(
            eyebrow: strings.appearanceEyebrow,
            title: strings.theme,
          ),
          const SizedBox(height: 6),
          Text(
            strings.themeHint,
            style: TextStyle(color: context.palette.mutedText, height: 1.4),
          ),
          const SizedBox(height: 14),
          const ThemeModeSelector(),
          const SizedBox(height: 26),
          SectionHeading(
            eyebrow: strings.remindersEyebrow,
            title: strings.routineAlerts,
          ),
          const SizedBox(height: 12),
          const _ReminderSwitch(),
          const SizedBox(height: 26),
          SectionHeading(
            eyebrow: strings.featuresEyebrow,
            title: strings.manageFeatures,
          ),
          const SizedBox(height: 6),
          Text(
            strings.manageFeaturesHint,
            style: TextStyle(color: context.palette.mutedText, height: 1.4),
          ),
          const SizedBox(height: 12),
          _ModuleSwitch(
            icon: Icons.restaurant_rounded,
            title: strings.moduleDiet,
            subtitle: strings.moduleDietHint,
            value: modules.dietEnabled,
            onChanged: (value) => ref.read(userModulesProvider.notifier)
                .setModules(modules.copyWith(dietEnabled: value)),
          ),
          _ModuleSwitch(
            icon: Icons.schedule_rounded,
            title: strings.moduleTime,
            subtitle: strings.moduleTimeHint,
            value: modules.timeEnabled,
            onChanged: (value) => ref.read(userModulesProvider.notifier)
                .setModules(modules.copyWith(timeEnabled: value)),
          ),
          _ModuleSwitch(
            icon: Icons.fitness_center_rounded,
            title: strings.moduleGym,
            subtitle: strings.moduleGymHint,
            value: modules.gymEnabled,
            onChanged: (value) => ref.read(userModulesProvider.notifier)
                .setModules(modules.copyWith(gymEnabled: value)),
          ),
          if (modules.timeEnabled) ...[
            const SizedBox(height: 26),
            SectionHeading(
              eyebrow: strings.moreScreensEyebrow,
              title: strings.logsAndPlanning,
            ),
            const SizedBox(height: 12),
            _SettingsLink(
              icon: Icons.work_outline_rounded,
              title: strings.workLog,
              subtitle: strings.workLogHint,
              route: AppRoutes.workLog,
            ),
            _SettingsLink(
              icon: Icons.nightlight_round,
              title: strings.eveningSplit,
              subtitle: strings.eveningSplitHint,
              route: AppRoutes.nightSplit,
            ),
            _SettingsLink(
              icon: Icons.history_rounded,
              title: strings.history,
              subtitle: strings.historyHint,
              route: AppRoutes.history,
            ),
            _SettingsLink(
              icon: Icons.edit_calendar_rounded,
              title: strings.routines,
              subtitle: strings.routinesHint,
              route: AppRoutes.routines,
            ),
          ],
          const SizedBox(height: 26),
          SectionHeading(
            eyebrow: strings.accountEyebrow,
            title: strings.yourData,
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
                            ? strings.unsavedChanges(sync.unsaved)
                            : sync.isSaving
                                ? strings.saving
                                : strings.allSaved,
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
              label: Text(strings.retryNow),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(strings.signOut),
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
    final strings = context.strings;

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
                  strings.remindRoutineStart,
                  style: TextStyle(
                    color: context.palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(strings, settings, isSupported, count),
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

  String _subtitle(
    AppStrings strings,
    ReminderSettings settings,
    bool isSupported,
    int count,
  ) {
    if (!isSupported) {
      return strings.remindersUnavailable;
    }
    if (settings.permissionDenied) {
      return strings.remindersBlocked;
    }
    if (settings.isBusy) {
      return strings.updating;
    }
    if (!settings.isEnabled) {
      return strings.remindersOffHint;
    }
    return strings.remindersScheduled(count);
  }
}

/// One feature toggle. Unlike the onboarding screen's checkboxes, this saves
/// on every flip rather than behind a "Continue" button — there is no set-up
/// flow left to finish here, just a preference to change.
class _ModuleSwitch extends StatelessWidget {
  const _ModuleSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: context.palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.palette.primary),
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
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
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
