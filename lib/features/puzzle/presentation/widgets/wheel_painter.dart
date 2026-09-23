import 'dart:math' as math;

import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  const WheelPainter({
    required this.colors,
    required this.rotations,
    required Listenable repaint,
    this.separatorWidth = 0.65,
    this.showBoundaries = false,
    this.arcDisplay = false,
  }) : super(repaint: repaint);

  final List<List<Color>> colors;
  final List<double> rotations;
  final double separatorWidth;
  final bool showBoundaries;
  final bool arcDisplay;
  static const double centerFraction = 0.16;
  static const double arcInnerFraction = 0.18;
  static const double arcHalfSpan = math.pi * 0.285;

  static WheelGeometry arcGeometry(Size size) {
    final verticalScale = size.width == 0
        ? 1.0
        : size.height / (size.width / 1.24);
    final outerRadius = size.width * 0.63;
    final center = Offset(
      size.width / 2,
      size.height - size.width * 0.125 * verticalScale,
    );
    return WheelGeometry(
      center: center,
      outerRadius: outerRadius,
      innerRadius: outerRadius * arcInnerFraction,
      startAngle: -math.pi / 2 - arcHalfSpan,
      endAngle: -math.pi / 2 + arcHalfSpan,
      verticalScale: verticalScale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (arcDisplay) {
      _paintArcs(canvas, size);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    final count = colors.length;
    final width = radius * (1 - centerFraction) / count;
    final sectorAngle = 2 * math.pi / colors.first.length;
    final fill = Paint()..isAntiAlias = true;
    final separator = Paint()
      ..isAntiAlias = true
      ..color = const Color(0x66F8F6F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = separatorWidth;

    for (var ring = 0; ring < count; ring++) {
      final inner = radius * centerFraction + ring * width;
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
      radius * centerFraction - 0.5,
      Paint()..color = const Color(0xFFF7F5F0),
    );
    canvas.drawCircle(
      center,
      radius * centerFraction - 7,
      Paint()
        ..color = const Color(0xFFD8D2C9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _paintArcs(Canvas canvas, Size size) {
    final geometry = arcGeometry(size);
    final ringCount = colors.length;
    final step = (geometry.outerRadius - geometry.innerRadius) / ringCount;
    canvas.save();
    canvas.translate(geometry.center.dx, geometry.center.dy);
    canvas.scale(1, geometry.verticalScale);
    canvas.translate(-geometry.center.dx, -geometry.center.dy);

    for (var ring = 0; ring < ringCount; ring++) {
      final trackRadius = geometry.innerRadius + (ring + 0.5) * step;
      final rect = Rect.fromCircle(
        center: geometry.center,
        radius: trackRadius,
      );
      final segmentPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = step
        ..strokeCap = StrokeCap.butt;
      final sectionSweep = geometry.endAngle - geometry.startAngle;
      final sectorAngle = 2 * math.pi / colors[ring].length;
      final displayRotation = rotations[ring] / sectorAngle * sectionSweep;

      for (var sector = 0; sector < colors[ring].length; sector++) {
        final baseStart =
            geometry.startAngle + displayRotation + sector * sectionSweep;
        for (var turn = -2; turn <= 2; turn++) {
          final start = baseStart + turn * colors[ring].length * sectionSweep;
          final end = start + sectionSweep;
          final visibleStart = math.max(start, geometry.startAngle);
          final visibleEnd = math.min(end, geometry.endAngle);
          if (visibleEnd <= visibleStart) continue;
          canvas.drawArc(
            rect,
            visibleStart,
            visibleEnd - visibleStart,
            false,
            segmentPaint..color = colors[ring][sector],
          );
        }
      }
    }

    if (showBoundaries) {
      final boundaryPaint = Paint()
        ..isAntiAlias = true
        ..color = const Color(0x66F8F6F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = separatorWidth;
      for (var layer = 1; layer < ringCount; layer++) {
        final radius = geometry.innerRadius + layer * step;
        canvas.drawArc(
          Rect.fromCircle(center: geometry.center, radius: radius),
          geometry.startAngle,
          geometry.endAngle - geometry.startAngle,
          false,
          boundaryPaint,
        );
      }
    }
    canvas.restore();

    final hubRadius = geometry.innerRadius * 0.72;
    canvas.drawCircle(
      geometry.center,
      hubRadius,
      Paint()..color = const Color(0xFFF7F5F0),
    );
    canvas.drawCircle(
      geometry.center,
      hubRadius - 6,
      Paint()
        ..color = const Color(0xFFD8D2C9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.rotations != rotations ||
      oldDelegate.separatorWidth != separatorWidth ||
      oldDelegate.showBoundaries != showBoundaries ||
      oldDelegate.arcDisplay != arcDisplay;
}

class WheelGeometry {
  const WheelGeometry({
    required this.center,
    required this.outerRadius,
    required this.innerRadius,
    required this.startAngle,
    required this.endAngle,
    required this.verticalScale,
  });

  final Offset center;
  final double outerRadius;
  final double innerRadius;
  final double startAngle;
  final double endAngle;
  final double verticalScale;
}
