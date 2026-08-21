import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A bare trend line — no axes, no labels, no grid.
///
/// It sits inside a stat tile next to the current figure, where the only
/// question is "which way is this going". Anything more would need the space
/// the figure is using.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.strokeWidth = 2,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    // One point is a dot, not a trend, and it reads as a stray mark. A stray
    // NaN would poison the whole path, so those go too.
    final points = values.where((value) => value.isFinite).toList();
    if (points.length < 2) {
      return const SizedBox.shrink();
    }

    // Size.infinite is clamped to whatever the parent allows, which is the
    // safe way to fill a box — SizedBox.expand asserts if either direction
    // ever arrives unbounded.
    return CustomPaint(
      size: Size.infinite,
      painter: _SparklinePainter(
        values: points,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    var lowest = values.first;
    var highest = values.first;
    for (final value in values) {
      if (value < lowest) lowest = value;
      if (value > highest) highest = value;
    }

    // A flat run has no range to scale against; draw it down the middle
    // instead of dividing by zero.
    final range = highest - lowest;
    final inset = strokeWidth / 2;
    final usableHeight = size.height - strokeWidth;
    final step = size.width / (values.length - 1);

    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final ratio = range == 0 ? 0.5 : (values[index] - lowest) / range;
      final x = step * index;
      final y = inset + (1 - ratio) * usableHeight;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        !listEquals(oldDelegate.values, values);
  }
}
