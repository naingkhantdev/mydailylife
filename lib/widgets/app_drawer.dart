import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
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
  static const history = '/history';
  static const routines = '/routines';
  static const settings = '/settings';
  static const login = '/login';
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayId = user?.email ?? user?.displayName ?? 'Signed out';

    return Drawer(
      width: 312,
      elevation: 0,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.palette.border),
          boxShadow: [
            BoxShadow(
              color: context.palette.shadow,
              blurRadius: 28,
              offset: const Offset(8, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
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
              Divider(height: 1, color: context.palette.border),
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
                      icon: Icons.restaurant_rounded,
                      title: 'Diet & calories',
                      route: AppRoutes.diet,
                      currentRoute: currentRoute,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.palette.border),
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
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [context.palette.blueSoft, context.palette.surface],
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? context.palette.blue.withOpacity(0.35)
                    : Colors.transparent,
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
                        ? context.palette.primary
                        : context.palette.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    // onPrimary, not white: in dark mode the selected chip is
                    // bright cyan and white on cyan is unreadable.
                    color: isSelected
                        ? context.palette.onPrimary
                        : context.palette.bodyText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? context.palette.primary : context.palette.ink,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isSelected ? 1 : 0,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: context.palette.primary,
                    size: 13,
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
