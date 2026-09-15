import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_modules_provider.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../widgets/app_drawer.dart';

/// Shown once, right after a brand-new account is created.
///
/// A first-time user otherwise lands on a drawer with nine screens before
/// they have used any of them. Picking what to track up front lets the rest
/// of the app hide what was left unchecked, so it starts simple around only
/// what the user actually asked for.
class ModuleSetupScreen extends ConsumerStatefulWidget {
  const ModuleSetupScreen({super.key});

  @override
  ConsumerState<ModuleSetupScreen> createState() => _ModuleSetupScreenState();
}

class _ModuleSetupScreenState extends ConsumerState<ModuleSetupScreen> {
  bool _diet = true;
  bool _time = true;
  bool _gym = true;
  bool _isSaving = false;

  bool get _hasAnySelected => _diet || _time || _gym;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 40,
                      color: palette.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'What do you want to track?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick what matters to you. You can change this anytime '
                      'in Settings, and the app stays simple around only what '
                      "you've turned on.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.bodyText, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _ModuleTile(
                      icon: Icons.restaurant_rounded,
                      title: 'Daily Food Management',
                      subtitle: 'Log meals and track calories.',
                      value: _diet,
                      onChanged: (value) => setState(() => _diet = value),
                    ),
                    const SizedBox(height: 10),
                    _ModuleTile(
                      icon: Icons.schedule_rounded,
                      title: 'Time Management',
                      subtitle: 'Plan your day and track routines.',
                      value: _time,
                      onChanged: (value) => setState(() => _time = value),
                    ),
                    const SizedBox(height: 10),
                    _ModuleTile(
                      icon: Icons.fitness_center_rounded,
                      title: 'Gym Management',
                      subtitle: 'Plan workouts and log gym sets.',
                      value: _gym,
                      onChanged: (value) => setState(() => _gym = value),
                    ),
                    if (!_hasAnySelected) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Keep at least one on — the app needs something to '
                        'show you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.danger,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed:
                          _isSaving || !_hasAnySelected ? null : _continue,
                      icon: _isSaving
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.onPrimary,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(_isSaving ? 'Setting up...' : 'Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _isSaving = true);

    await ref.read(userModulesProvider.notifier).setModules(
          UserModulesModel(
            dietEnabled: _diet,
            timeEnabled: _time,
            gymEnabled: _gym,
          ),
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
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
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: value
                  ? palette.primary.withOpacity(0.4)
                  : palette.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: value ? palette.blueSoft : palette.background,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  icon,
                  color: value ? palette.primary : palette.mutedText,
                  size: 20,
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
                        color: palette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: value,
                activeColor: palette.primary,
                onChanged: (checked) => onChanged(checked ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
