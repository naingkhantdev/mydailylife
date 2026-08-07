import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Icon-in-circle + title + message pattern shared by every screen's
/// "nothing here yet" state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.iconBackground,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String message;

  /// An empty state that only reports emptiness is a dead end. Pass these to
  /// offer the one action that fills it — both are needed for the button to
  /// render.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// Null means "use the theme's default empty-state accent". These cannot
  /// default to a constant in the constructor any more: the fallback now has
  /// to be read from the active theme, which is only available once `build`
  /// has a `BuildContext`.
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: iconBackground ?? palette.violetSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? palette.violet, size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.mutedText, height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
