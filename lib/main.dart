import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/reminder_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/gym_plan_screen.dart';
import 'screens/gym_technique_manager_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/night_split_screen.dart';
import 'screens/routine_manager_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/work_log_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_drawer.dart';
import 'widgets/sync_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Resolved before the first frame so the saved theme is already known when
  // the splash screen paints.
  final preferences = await SharedPreferences.getInstance();

  // Fails soft: a device that cannot schedule notifications still gets the
  // rest of the app, with the reminders switch reporting itself unavailable.
  final notifications = NotificationService();
  await notifications.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const MyApp(),
    ),
  );
}

Route<void>? _buildAppRoute(RouteSettings settings) {
  final Widget? page = switch (settings.name) {
    AppRoutes.home => const HomeScreen(),
    AppRoutes.dashboard => const DashboardScreen(),
    AppRoutes.diet => const DietScreen(),
    AppRoutes.workLog => const WorkLogScreen(),
    AppRoutes.nightSplit => const NightSplitScreen(),
    AppRoutes.gym => const GymPlanScreen(),
    AppRoutes.gymTechniques => const GymTechniqueManagerScreen(),
    AppRoutes.history => const HistoryScreen(),
    AppRoutes.routines => const RoutineManagerScreen(),
    AppRoutes.settings => const SettingsScreen(),
    AppRoutes.login => const LoginScreen(),
    _ => null,
  };

  if (page == null) {
    return null;
  }

  return PageRouteBuilder<void>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, animation, secondaryAnimation) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(opacity: curvedAnimation, child: child);
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'RoutineSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      onGenerateRoute: _buildAppRoute,
      // Wrapped around the navigator rather than added per screen, so a failed
      // write is visible wherever the user happens to be.
      builder: (context, child) => SyncBanner(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
