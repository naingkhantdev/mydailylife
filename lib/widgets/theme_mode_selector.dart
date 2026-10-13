import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_palette.dart';

/// Three-way appearance switch: follow the OS, force light, or force dark.
///
/// "System" is kept as an explicit option rather than inferring it from a
/// boolean, because a plain on/off switch cannot express "track whatever the
/// phone does" — which is the mode most users actually want.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final strings = context.strings;
    final mode = ref.watch(themeModeProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          for (final option in [
            (ThemeMode.system, Icons.brightness_auto_rounded, strings.themeAuto),
            (ThemeMode.light, Icons.light_mode_rounded, strings.themeLight),
            (ThemeMode.dark, Icons.dark_mode_rounded, strings.themeDark),
          ])
            Expanded(
              child: _ThemeOption(
                icon: option.$2,
                label: option.$3,
                isSelected: mode == option.$1,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

/// English / Myanmar switch, styled as the same segmented control as the
/// theme picker. Each label is written in its own script, so someone who
/// cannot read the current language can still find their own.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final language = ref.watch(languageProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          for (final option in const [
            (AppLanguage.english, Icons.language_rounded, 'English'),
            (AppLanguage.myanmar, Icons.translate_rounded, 'မြန်မာ'),
          ])
            Expanded(
              child: _ThemeOption(
                icon: option.$2,
                label: option.$3,
                isSelected: language == option.$1,
                onTap: () => ref
                    .read(languageProvider.notifier)
                    .setLanguage(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? palette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? palette.onPrimary : palette.mutedText,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? palette.onPrimary : palette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
