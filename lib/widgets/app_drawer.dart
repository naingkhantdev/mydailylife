import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/user_modules_provider.dart';
import '../theme/app_palette.dart';

class AppRoutes {
  const AppRoutes._();

  static const home = '/home';
  static const dashboard = '/dashboard';
  static const diet = '/diet';
  static const workLog = '/work-log';
  static const nightSplit = '/night-split';
  static const gym = '/gym';
  static const gymTechniques = '/gym-techniques';
  static const gymHistory = '/gym-history';
  static const history = '/history';
  static const routines = '/routines';
  static const settings = '/settings';
  static const login = '/login';
  static const moduleSetup = '/module-setup';
}

/// The drawer's floating glass card.
///
/// This is the one surface that floats over live page content rather than
/// over the ambient backdrop, so it gets a real blur: translucent glass with
/// no blur would leave the page's text legible through the menu.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(28);
    // The blur samples the page *after* the drawer's black scrim, so the
    // light-mode glass is thickened or it turns a dull grey.
    final fill = palette.isDark
        ? palette.surface
        : palette.surfaceElevated.withOpacity(0.82);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: Border.all(color: palette.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayId = user?.email ?? user?.displayName ?? 'Signed out';
    final modules = ref.watch(userModulesProvider);

    return Drawer(
      width: 312,
      elevation: 0,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: _GlassPanel(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 10, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [context.palette.primary, context.palette.violet],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: context.palette.shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sync_rounded,
                        // onPrimary, not white: in dark mode this gradient
                        // starts at bright cyan and white on cyan is 1.5:1.
                        color: context.palette.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RoutineSync',
                            style: TextStyle(
                              color: context.palette.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayId,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.palette.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: context.palette.mutedText,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.palette.divider),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                  children: [
                    _DrawerItem(
                      icon: Icons.today_rounded,
                      title: 'Today',
                      route: AppRoutes.home,
                      currentRoute: currentRoute,
                    ),
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      route: AppRoutes.dashboard,
                      currentRoute: currentRoute,
                    ),
                    if (modules.gymEnabled) ...[
                      _DrawerItem(
                        icon: Icons.fitness_center_rounded,
                        title: 'Gym plan',
                        route: AppRoutes.gym,
                        currentRoute: currentRoute,
                      ),
                      _DrawerItem(
                        icon: Icons.edit_note_rounded,
                        title: 'Gym techniques',
                        route: AppRoutes.gymTechniques,
                        currentRoute: currentRoute,
                      ),
                      _DrawerItem(
                        icon: Icons.history_rounded,
                        title: 'Gym history',
                        route: AppRoutes.gymHistory,
                        currentRoute: currentRoute,
                      ),
                    ],
                    if (modules.dietEnabled)
                      _DrawerItem(
                        icon: Icons.restaurant_rounded,
                        title: 'Diet & calories',
                        route: AppRoutes.diet,
                        currentRoute: currentRoute,
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.palette.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: _DrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  route: AppRoutes.settings,
                  currentRoute: currentRoute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
  });

  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final isSelected = route == currentRoute;
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigate(context, isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            // A neutral frosted wash rather than a brand-coloured fill, so
            // the selection reads as quiet glass. [ink] inverts between
            // themes, so the same expression is a soft grey in light mode
            // and a soft white in dark.
            decoration: BoxDecoration(
              color: isSelected
                  ? palette.ink.withOpacity(palette.isDark ? 0.08 : 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? palette.border : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.primary.withOpacity(0.12)
                        : palette.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? palette.primary : palette.bodyText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isSelected ? 1 : 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, bool isSelected) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (isSelected) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) {
        navigator.pushReplacementNamed(route);
      }
    });
  }
}
