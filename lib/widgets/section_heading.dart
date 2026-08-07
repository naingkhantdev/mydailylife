import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Eyebrow + title (+ optional trailing action) header used to
/// introduce a section of a screen. Shared so every screen's section
/// intros look and space themselves identically.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: context.palette.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
