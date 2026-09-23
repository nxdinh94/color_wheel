import 'dart:math' as math;

class PaletteConfig {
  const PaletteConfig({
    required this.baseHue,
    required this.hueRange,
    required this.innerLightness,
    required this.outerLightness,
    required this.innerSaturation,
    required this.outerSaturation,
  });
  final double baseHue;
  final double hueRange;
  final double innerLightness;
  final double outerLightness;
  final double innerSaturation;
  final double outerSaturation;
}

class LevelConfig {
  const LevelConfig({
    required this.number,
    required this.ringCount,
    required this.sectorCount,
    required this.palette,
    required this.shuffleOffsets,
  });
  final int number;
  final int ringCount;
  final int sectorCount;
  final PaletteConfig palette;
  final List<int> shuffleOffsets;
}

class RingState {
  const RingState({
    required this.index,
    required this.currentOffset,
    this.solutionOffset = 0,
  });
  final int index;
  final int currentOffset;
  final int solutionOffset;

  RingState copyWith({int? currentOffset}) => RingState(
    index: index,
    currentOffset: currentOffset ?? this.currentOffset,
    solutionOffset: solutionOffset,
  );

  bool isSolved(int sectorCount) =>
      normalizeSector(currentOffset, sectorCount) ==
      normalizeSector(solutionOffset, sectorCount);
}

class PuzzleState {
  const PuzzleState({
    required this.level,
    required this.rings,
    this.moveCount = 0,
  });
  final LevelConfig level;
  final List<RingState> rings;
  final int moveCount;

  bool get isCompleted =>
      rings.every((ring) => ring.isSolved(level.sectorCount));

  PuzzleState withMove(int ringIndex, int offset) {
    final next = List<RingState>.of(rings);
    next[ringIndex] = next[ringIndex].copyWith(currentOffset: offset);
    return PuzzleState(
      level: level,
      rings: List.unmodifiable(next),
      moveCount: moveCount + 1,
    );
  }

  factory PuzzleState.initial(LevelConfig level) => PuzzleState(
    level: level,
    rings: List.unmodifiable([
      for (var i = 0; i < level.ringCount; i++)
        RingState(index: i, currentOffset: level.shuffleOffsets[i]),
    ]),
  );
}

int normalizeSector(int value, int count) => ((value % count) + count) % count;

double normalizeDegrees(double degrees) => ((degrees % 360) + 360) % 360;

double shortestAngularDelta(double current, double previous) =>
    math.atan2(math.sin(current - previous), math.cos(current - previous));

int nearestSector(double rotation, int sectorCount) =>
    (rotation / (2 * math.pi / sectorCount)).round();

int? ringAtRadius(
  double radius,
  double outerRadius,
  int ringCount, {
  double centerFraction = 0.16,
}) {
  if (radius < outerRadius * centerFraction || radius > outerRadius) {
    return null;
  }
  final width = outerRadius * (1 - centerFraction) / ringCount;
  return ((radius - outerRadius * centerFraction) / width).floor().clamp(
    0,
    ringCount - 1,
  );
}
