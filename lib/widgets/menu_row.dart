import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Icon + label row for `PopupMenuItem`s.
///
/// Bare text items give the user nothing to recognise at a glance, and leave a
/// destructive action looking identical to a safe one. Pass [color] to mark
/// the destructive entry.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? context.palette.bodyText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: resolved),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: resolved)),
      ],
    );
  }
}
