import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';

/// Shared container chrome for the app's dark "ink" hero cards
/// (Dashboard, Home's gym focus card, Gym plan header, History).
/// Keeps the background, radius, padding, and shadow in one place
/// instead of each screen re-declaring its own slightly different
/// BoxDecoration.
class DarkHeroCard extends StatelessWidget {
  const DarkHeroCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Material(
      color: context.palette.heroSurface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Small translucent pill badge used on dark hero surfaces
/// (Dashboard's date badge, the splash screen's intro badge).
class DarkHeroBadge extends StatelessWidget {
  const DarkHeroBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onInkSurface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.onInkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.onInkAccent, size: 14),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onInk,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
