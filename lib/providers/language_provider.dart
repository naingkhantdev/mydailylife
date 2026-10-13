import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_provider.dart';

const _languageKey = 'app_language';

enum AppLanguage { english, myanmar }

final languageProvider =
    StateNotifierProvider<LanguageController, AppLanguage>((ref) {
  return LanguageController(preferences: ref.watch(sharedPreferencesProvider));
});

/// Owns the English/Myanmar choice and mirrors it to local storage.
///
/// Same shape as `ThemeModeController`: the UI switches immediately off the
/// new state and a failed disk write only loses the choice on next launch.
class LanguageController extends StateNotifier<AppLanguage> {
  LanguageController({required SharedPreferences preferences})
      : _preferences = preferences,
        super(_restore(preferences));

  final SharedPreferences _preferences;

  Future<void> setLanguage(AppLanguage language) async {
    if (language == state) return;
    state = language;
    try {
      await _preferences.setString(_languageKey, language.name);
    } catch (_) {
      // Preference is lost on next launch; the current session is unaffected.
    }
  }

  static AppLanguage _restore(SharedPreferences preferences) {
    return preferences.getString(_languageKey) == AppLanguage.myanmar.name
        ? AppLanguage.myanmar
        : AppLanguage.english;
  }
}
