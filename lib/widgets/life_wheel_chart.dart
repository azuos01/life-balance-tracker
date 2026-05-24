import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LifeWheelChart extends StatelessWidget {
  final List<double> scores; // 10 values 1-10
  final List<String> labels;
  final List<String> icons;
  final double size;
  final bool interactive;
  final void Function(int index)? onAreaTap;

  const LifeWheelChart({
    super.key,
    required this.scores,
    required this.labels,
    required this.icons,
    this.size = 300,
    this.interactive = false,
    this.onAreaTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onTapUp: interactive
            ? (details) => _handleTap(details.localPosition, size)
            : null,
        child: CustomPaint(
          painter: _LifeWheelPainter(
            scores: scores,
            labels: labels,
            icons: icons,
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset localPos, double s) {
    if (onAreaTap == null) return;
    final center = Offset(s / 2, s / 2);
    final n = scores.length;
    double minDist = double.infinity;
    int nearestIndex = -1;

    for (int i = 0; i < n; i++) {
      final angle = 2 * pi * i / n - pi / 2;
      final labelR = (s / 2) * 0.88;
      final lx = center.dx + labelR * cos(angle);
      final ly = center.dy + labelR * sin(angle);
      final dist = (localPos - Offset(lx, ly)).distance;
      if (dist < minDist) {
        minDist = dist;
        nearestIndex = i;
      }
    }
    if (minDist < 40 && nearestIndex != -1) {
      onAreaTap!(nearestIndex);
    }
  }
}

class _LifeWheelPainter extends CustomPainter {
  final List<double> scores;
  final List<String> labels;
  final List<String> icons;

  _LifeWheelPainter({
    required this.scores,
    required this.labels,
    required this.icons,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.68;
    final n = scores.length;

    // Grid rings
    final gridPaint = Paint()
      ..color = AppTheme.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int ring = 1; ring <= 10; ring++) {
      final r = radius * ring / 10;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = 2 * pi * i / n - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axes
    final axisPaint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = 0.8;
    for (int i = 0; i < n; i++) {
      final angle = 2 * pi * i / n - pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        axisPaint,
      );
    }

    // Filled polygon
    final fillPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = 2 * pi * i / n - pi / 2;
      final r = radius * (scores[i].clamp(1.0, 10.0)) / 10;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Data points
    final dotPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;
    for (int i = 0; i < n; i++) {
      final angle = 2 * pi * i / n - pi / 2;
      final r = radius * (scores[i].clamp(1.0, 10.0)) / 10;
      canvas.drawCircle(
        Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)),
        4,
        dotPaint,
      );
    }

    // Area colors for labels
    final colors = AppTheme.areaColors;

    // Labels
    for (int i = 0; i < n; i++) {
      final angle = 2 * pi * i / n - pi / 2;
      final labelR = radius * 1.22;
      final lx = center.dx + labelR * cos(angle);
      final ly = center.dy + labelR * sin(angle);

      final color = colors[i % colors.length];

      // Icon
      final textPainter = TextPainter(
        text: TextSpan(
          text: icons[i],
          style: const TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );

      // Score badge
      final scorePainter = TextPainter(
        text: TextSpan(
          text: scores[i].toStringAsFixed(1),
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scorePainter.paint(
        canvas,
        Offset(
          lx - scorePainter.width / 2,
          ly + textPainter.height / 2 + 1,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_LifeWheelPainter old) =>
      old.scores != scores || old.labels != labels;
}
