import 'dart:math' as math;

import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  const WheelPainter({
    required this.colors,
    required this.rotations,
    required Listenable repaint,
    this.separatorWidth = 0.65,
    this.showBoundaries = false,
    this.ringDisplay = false,
  }) : super(repaint: repaint);

  final List<List<Color>> colors;
  final List<double> rotations;
  final double separatorWidth;
  final bool showBoundaries;
  final bool ringDisplay;
  static const double centerFraction = 0.16;
  static const double ringInnerFraction = 0.18;
  static const double ringGap = 0.1;

  static WheelGeometry circleGeometry(Size size) {
    final outerRadius = size.shortestSide / 2 - 2;
    final center = Offset(size.width / 2, size.height / 2);
    return WheelGeometry(
      center: center,
      outerRadius: outerRadius,
      innerRadius: outerRadius * ringInnerFraction,
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (ringDisplay) {
      _paintRings(canvas, size);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    final count = colors.length;
    final width =
        (radius * (1 - centerFraction) - ringGap * (count - 1)) / count;
    final sectorAngle = 2 * math.pi / colors.first.length;
    final fill = Paint()..isAntiAlias = true;
    final separator = Paint()
      ..isAntiAlias = true
      ..color = const Color(0x66F8F6F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = separatorWidth;
    final startColor = _startColor;

    for (var ring = 0; ring < count; ring++) {
      final inner = radius * centerFraction + ring * (width + ringGap);
      final outer = inner + width;
      final outerRect = Rect.fromCircle(center: center, radius: outer);
      final innerRect = Rect.fromCircle(center: center, radius: inner);
      for (var sector = 0; sector < colors[ring].length; sector++) {
        final start = -math.pi / 2 + rotations[ring] + sector * sectorAngle;
        final end = start + sectorAngle + 0.0005;
        final path = Path()
          ..moveTo(
            center.dx + math.cos(start) * outer,
            center.dy + math.sin(start) * outer,
          )
          ..arcTo(outerRect, start, end - start, false)
          ..arcTo(innerRect, end, start - end, false)
          ..close();
        canvas.drawPath(path, fill..color = colors[ring][sector]);
        if (separatorWidth > 0 || showBoundaries) {
          final from =
              center + Offset(math.cos(start) * inner, math.sin(start) * inner);
          final to =
              center + Offset(math.cos(start) * outer, math.sin(start) * outer);
          canvas.drawLine(from, to, separator);
        }
      }
      if (separatorWidth > 0 || showBoundaries) {
        canvas.drawCircle(center, outer, separator);
      }
    }
    canvas.drawCircle(
      center,
      radius * centerFraction * 0.78,
      Paint()..color = startColor,
    );
  }

  void _paintRings(Canvas canvas, Size size) {
    final geometry = circleGeometry(size);
    final ringCount = colors.length;
    final step =
        (geometry.outerRadius -
            geometry.innerRadius -
            ringGap * (ringCount - 1)) /
        ringCount;

    for (var ring = 0; ring < ringCount; ring++) {
      final trackRadius =
          geometry.innerRadius + ring * (step + ringGap) + step / 2;
      final rect = Rect.fromCircle(
        center: geometry.center,
        radius: trackRadius,
      );
      final segmentPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = step
        ..strokeCap = StrokeCap.butt;
      final sectorAngle = 2 * math.pi / colors[ring].length;
      final turns = rotations[ring] / sectorAngle;
      final completedTurns = (turns + 1e-9).floor();
      final incomingFraction = (turns - completedTurns).clamp(0.0, 1.0);
      final incomingSector =
          (colors[ring].length - completedTurns - 1) % colors[ring].length;
      final outgoingSector =
          (colors[ring].length - completedTurns) % colors[ring].length;
      final span = geometry.endAngle - geometry.startAngle;
      final boundaryAngle = geometry.startAngle + span * incomingFraction;

      // A complete sector turn replaces the visible color. While dragging,
      // reveal the next sector from the edge it physically enters through.
      canvas.drawArc(
        rect,
        geometry.startAngle,
        span,
        false,
        segmentPaint..color = colors[ring][outgoingSector],
      );
      if (incomingFraction > 0) {
        canvas.drawArc(
          rect,
          geometry.startAngle,
          span * incomingFraction,
          false,
          segmentPaint..color = colors[ring][incomingSector],
        );
      }

      if (incomingFraction > 0.005 && incomingFraction < 0.995) {
        final inner = trackRadius - step / 2;
        final outer = trackRadius + step / 2;
        final direction = Offset(
          math.cos(boundaryAngle),
          math.sin(boundaryAngle),
        );
        canvas.drawLine(
          geometry.center + direction * inner,
          geometry.center + direction * outer,
          Paint()
            ..isAntiAlias = true
            ..color = const Color(0xBBFFFFFF)
            ..strokeWidth = 1.5,
        );
      }
    }

    if (showBoundaries) {
      final boundaryPaint = Paint()
        ..isAntiAlias = true
        ..color = const Color(0x66F8F6F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = separatorWidth;
      for (var layer = 1; layer < ringCount; layer++) {
        final radius =
            geometry.innerRadius + layer * (step + ringGap) - ringGap / 2;
        canvas.drawArc(
          Rect.fromCircle(center: geometry.center, radius: radius),
          geometry.startAngle,
          geometry.endAngle - geometry.startAngle,
          false,
          boundaryPaint,
        );
      }
    }
    final hubRadius = geometry.innerRadius * 0.58;
    canvas.drawCircle(geometry.center, hubRadius, Paint()..color = _startColor);
  }

  Color get _startColor {
    if (colors.isNotEmpty && colors.first.isNotEmpty) {
      return colors.first.first;
    }
    return const Color(0xFFF7F5F0);
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.rotations != rotations ||
      oldDelegate.separatorWidth != separatorWidth ||
      oldDelegate.showBoundaries != showBoundaries ||
      oldDelegate.ringDisplay != ringDisplay;
}

class WheelGeometry {
  const WheelGeometry({
    required this.center,
    required this.outerRadius,
    required this.innerRadius,
    required this.startAngle,
    required this.endAngle,
  });

  final Offset center;
  final double outerRadius;
  final double innerRadius;
  final double startAngle;
  final double endAngle;
}
