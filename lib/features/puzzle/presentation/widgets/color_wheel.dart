import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/puzzle_models.dart';
import 'wheel_painter.dart';

class ColorWheel extends StatefulWidget {
  const ColorWheel({
    super.key,
    required this.level,
    required this.colors,
    required this.onMove,
    this.showDebug = false,
    this.enabled = true,
  });
  final LevelConfig level;
  final List<List<Color>> colors;
  final void Function(int ring, int offset) onMove;
  final bool showDebug;
  final bool enabled;

  @override
  State<ColorWheel> createState() => ColorWheelState();
}

class ColorWheelState extends State<ColorWheel>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<int> _paintVersion = ValueNotifier(0);
  late final AnimationController _snap;
  late List<double> _rotations;
  int? _pointer;
  int? _ring;
  int? _snappingRing;
  double? _previousAngle;
  double _startRotation = 0;
  double _snapFrom = 0;
  double _snapTo = 0;
  int? _pendingOffset;
  double? pointerAngle;

  int? get selectedRing => _ring;
  List<double> get rotations => List.unmodifiable(_rotations);

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..addListener(_animateSnap);
    final step = 2 * math.pi / widget.level.sectorCount;
    _rotations = [
      for (final offset in widget.level.shuffleOffsets) offset * step,
    ];
  }

  @override
  void dispose() {
    _snap.dispose();
    _paintVersion.dispose();
    super.dispose();
  }

  void _animateSnap() {
    final ring = _snappingRing;
    if (ring == null) return;
    _rotations[ring] =
        _snapFrom +
        (_snapTo - _snapFrom) * Curves.easeOutCubic.transform(_snap.value);
    _paintVersion.value++;
  }

  void _startSnap(int ring, double target, {int? commitOffset}) {
    _snappingRing = ring;
    _snapFrom = _rotations[ring];
    _snapTo = target;
    _pendingOffset = commitOffset;
    _snap.forward(from: 0).whenComplete(() {
      if (!mounted || _snappingRing != ring) return;
      _rotations[ring] = target;
      _snappingRing = null;
      _paintVersion.value++;
      final offset = _pendingOffset;
      _pendingOffset = null;
      if (offset != null) widget.onMove(ring, offset);
      setState(() {});
    });
  }

  double _angle(Offset point, Size size) {
    final geometry = WheelPainter.arcGeometry(size);
    return math.atan2(
      point.dy - geometry.center.dy,
      point.dx - geometry.center.dx,
    );
  }

  void _onDown(PointerDownEvent event, Size size) {
    if (!widget.enabled || _pointer != null || _snappingRing != null) return;
    final geometry = WheelPainter.arcGeometry(size);
    final center = geometry.center;
    final delta = event.localPosition - center;
    final radius = delta.distance;
    final angle = _angle(event.localPosition, size);
    if (angle < geometry.startAngle || angle > geometry.endAngle) return;
    final ring = ringAtRadius(
      radius,
      geometry.outerRadius,
      widget.level.ringCount,
      centerFraction: WheelPainter.arcInnerFraction,
    );
    if (ring == null || ring == 0 || ring == widget.level.ringCount - 1) {
      return;
    }
    _pointer = event.pointer;
    _ring = ring;
    _previousAngle = angle;
    pointerAngle = _previousAngle;
    _startRotation = _rotations[ring];
    setState(() {});
  }

  void _onMove(PointerMoveEvent event, Size size) {
    if (event.pointer != _pointer || _ring == null) return;
    final current = _angle(event.localPosition, size);
    final nextRotation =
        _rotations[_ring!] + shortestAngularDelta(current, _previousAngle!);
    _rotations[_ring!] = nextRotation % (2 * math.pi);
    if (_rotations[_ring!] < 0) _rotations[_ring!] += 2 * math.pi;
    _previousAngle = current;
    pointerAngle = current;
    _paintVersion.value++;
    if (widget.showDebug) setState(() {});
  }

  void _onUp(PointerEvent event, {required bool cancelled}) {
    if (event.pointer != _pointer || _ring == null) return;
    final ring = _ring!;
    _pointer = null;
    _ring = null;
    _previousAngle = null;
    pointerAngle = null;
    if (cancelled) {
      _startSnap(ring, _startRotation);
    } else {
      final targetSector = nearestSector(
        _rotations[ring],
        widget.level.sectorCount,
      );
      final startSector = normalizeSector(
        nearestSector(_startRotation, widget.level.sectorCount),
        widget.level.sectorCount,
      );
      final targetOffset = normalizeSector(
        targetSector,
        widget.level.sectorCount,
      );
      _startSnap(
        ring,
        targetSector * 2 * math.pi / widget.level.sectorCount,
        commitOffset: targetOffset == startSector ? null : targetOffset,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return SizedBox(
          width: size.width,
          height: size.height,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _onDown(event, size),
            onPointerMove: (event) => _onMove(event, size),
            onPointerUp: (event) => _onUp(event, cancelled: false),
            onPointerCancel: (event) => _onUp(event, cancelled: true),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: size,
                    painter: WheelPainter(
                      colors: widget.colors,
                      rotations: _rotations,
                      repaint: _paintVersion,
                      showBoundaries: widget.showDebug,
                      arcDisplay: true,
                    ),
                  ),
                ),
                if (widget.showDebug)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xDDFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          'ring: ${_ring ?? '-'}  angle: ${pointerAngle?.toStringAsFixed(2) ?? '-'}\n'
                          'offsets: ${_rotations.map((a) => normalizeSector(nearestSector(a, widget.level.sectorCount), widget.level.sectorCount)).join(', ')}  '
                          'target: ${List.filled(widget.level.ringCount, 0).join(', ')}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
