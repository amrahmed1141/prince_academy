import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';

/// Shared “Members today attendance” gauge used on the dashboard and detail page.
/// Wrap with [Hero] using [heroTag] for the open/close flight animation.
class TodayAttendanceKpiCard extends StatelessWidget {
  const TodayAttendanceKpiCard({
    super.key,
    required this.attended,
    required this.booked,
    this.fillHeight = true,
  });

  static const heroTag = 'today_attendance_kpi';

  final int attended;
  final int booked;

  /// When true, expands to fill a parent [Expanded]/dashboard PageView).
  /// When false, uses a compact fixed gauge height (detail page).
  final bool fillHeight;

  double get _progress {
    if (booked <= 0) return 0;
    return (attended / booked).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final gauge = LayoutBuilder(
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
                    painter: _SemiGaugePainter(
                      progress: _progress,
                      trackColor: const Color(0xFFE8E0D8),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.35),
                  child: _AttendanceStatus(
                    attended: attended,
                    booked: booked,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return AdminSectionCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Members today attendance',
            style: TextStyle(
              color: EColorConstants.authTextDarkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          if (fillHeight)
            Expanded(child: gauge)
          else
            SizedBox(height: 140, child: gauge),
        ],
      ),
    );
  }
}

class _AttendanceStatus extends StatelessWidget {
  const _AttendanceStatus({
    required this.attended,
    required this.booked,
  });

  final int attended;
  final int booked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontFamily: 'Poppins', height: 1.1),
            children: [
              TextSpan(
                text: '$attended',
                style: const TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: ' attendance',
                style: TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'from $booked members today',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: EColorConstants.authPlaceholderGray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

/// Semi-circle gauge — fill uses the same green gradient as member session cards.
class _SemiGaugePainter extends CustomPainter {
  _SemiGaugePainter({
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
  bool shouldRepaint(covariant _SemiGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor;
  }
}
