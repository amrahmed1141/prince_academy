import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semi-circle progress gauge with a green fill and thumb, matching the
/// admin “Members today attendance” card.
class SemiCircularGauge extends StatelessWidget {
  const SemiCircularGauge({
    super.key,
    required this.progress,
    required this.child,
    this.trackColor = const Color(0xFFE8E0D8),
  });

  /// 0–1 fill along the arc.
  final double progress;
  final Widget child;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth,
          constraints.maxHeight * 1.85,
        );
        return Center(
          child: SizedBox(
            width: side,
            height: side * 0.58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: SemiCircularGaugePainter(
                      progress: progress,
                      trackColor: trackColor,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.35),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Semi-circle gauge — fill uses the same green gradient as member session cards.
class SemiCircularGaugePainter extends CustomPainter {
  SemiCircularGaugePainter({
    required this.progress,
    required this.trackColor,
  });

  final double progress;
  final Color trackColor;

  static const _fillColors = [
    Color(0xFFB7E27A),
    Color(0xFF8FD15B),
    Color(0xFF66BE47),
    Color(0xFF3E9F34),
  ];
  static const _fillStops = [0.0, 0.35, 0.68, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final inset = stroke / 2 + 2;
    final diameter = size.width - inset * 2;
    final radius = diameter / 2;
    final center = Offset(size.width / 2, size.height - inset);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..addArc(rect, math.pi, math.pi), trackPaint);

    final t = progress.clamp(0.0, 1.0);
    if (t > 0) {
      final fillPaint = Paint()
        ..shader = const SweepGradient(
          startAngle: math.pi,
          endAngle: math.pi * 2,
          colors: _fillColors,
          stops: _fillStops,
          transform: GradientRotation(0),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(Path()..addArc(rect, math.pi, math.pi * t), fillPaint);
    }

    final angle = math.pi + (math.pi * t);
    final thumb = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(
      thumb,
      stroke * 0.42,
      Paint()..color = const Color(0xFF3E9F34),
    );
  }

  @override
  bool shouldRepaint(covariant SemiCircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor;
  }
}
