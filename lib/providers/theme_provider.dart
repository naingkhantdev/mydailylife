import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'app_theme_mode';

/// Resolved in `main()` before `runApp` and injected via a `ProviderScope`
/// override.
///
/// Reading preferences up front rather than asynchronously inside the widget
/// tree is what stops the splash screen flashing the wrong appearance for a
/// frame before the saved choice loads.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(preferences: ref.watch(sharedPreferencesProvider));
});

/// Owns the light/dark/system choice and mirrors it to local storage.
///
/// Writes are fire-and-forget: the UI switches theme immediately off the new
/// state, and a failed disk write only costs the preference on next launch —
/// it should never block or undo the visual change the user just asked for.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController({required SharedPreferences preferences})
      : _preferences = preferences,
        super(_restore(preferences));

  final SharedPreferences _preferences;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    try {
      await _preferences.setString(_themeModeKey, mode.name);
    } catch (_) {
      // Preference is lost on next launch; the current session is unaffected.
    }
  }

  /// Cycles system -> light -> dark -> system, matching the drawer toggle.
  Future<void> cycleThemeMode() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    return setThemeMode(next);
  }

  static ThemeMode _restore(SharedPreferences preferences) {
    final saved = preferences.getString(_themeModeKey);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
