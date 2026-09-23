import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hue_wheel/features/puzzle/domain/puzzle_models.dart';
import 'package:hue_wheel/features/puzzle/logic/level_generator.dart';
import 'package:hue_wheel/features/puzzle/logic/palette_generator.dart';

void main() {
  test('normalizes angles and sectors', () {
    expect(normalizeDegrees(-10), 350);
    expect(normalizeDegrees(370), 10);
    expect(normalizeSector(-1, 8), 7);
    expect(normalizeSector(8, 8), 0);
    expect(normalizeSector(9, 8), 1);
  });

  test('unwraps a drag across both angle boundaries', () {
    expect(shortestAngularDelta(0.01, 2 * math.pi - 0.01), closeTo(0.02, 1e-9));
    expect(
      shortestAngularDelta(-math.pi + 0.01, math.pi - 0.01),
      closeTo(0.02, 1e-9),
    );
    expect(
      shortestAngularDelta(math.pi - 0.01, -math.pi + 0.01),
      closeTo(-0.02, 1e-9),
    );
  });

  test('snaps to nearest sector including circular equivalents', () {
    final step = 2 * math.pi / 8;
    expect(nearestSector(step * 1.49, 8), 1);
    expect(nearestSector(step * 1.51, 8), 2);
    expect(normalizeSector(nearestSector(2 * math.pi, 8), 8), 0);
    expect(normalizeSector(nearestSector(-step, 8), 8), 7);
  });

  test('hit tests center, rings, boundaries, and outside', () {
    expect(ringAtRadius(10, 100, 4), isNull);
    expect(ringAtRadius(16, 100, 4), 0);
    expect(ringAtRadius(37, 100, 4), 1);
    expect(ringAtRadius(58, 100, 4), 2);
    expect(ringAtRadius(79, 100, 4), 3);
    expect(ringAtRadius(101, 100, 4), isNull);
  });

  test('completion is logical and normalized', () {
    final level = const LevelGenerator().generate(1);
    var puzzle = PuzzleState.initial(level);
    expect(puzzle.isCompleted, false);
    puzzle = puzzle.withMove(0, level.sectorCount);
    puzzle = puzzle.withMove(1, -level.sectorCount);
    expect(puzzle.isCompleted, true);
    expect(puzzle.moveCount, 2);
  });

  test('generation is deterministic, shuffled, and ordered across ranges', () {
    const generator = LevelGenerator();
    for (final number in [1, 5, 6, 15, 16, 30, 31, 50, 51, 80, 81, 200]) {
      final a = generator.generate(number);
      final b = generator.generate(number);
      expect(a.ringCount, b.ringCount);
      expect(a.sectorCount, b.sectorCount);
      expect(a.palette.baseHue, b.palette.baseHue);
      expect(a.shuffleOffsets, b.shuffleOffsets);
      expect(a.shuffleOffsets.every((offset) => offset != 0), true);
      expect(a.shuffleOffsets.toSet().length, greaterThan(1));
      expect(PuzzleState.initial(a).isCompleted, false);
      final colors = const HslColorPaletteGenerator().generate(a);
      expect(colors.length, a.ringCount);
      expect(
        colors.every((ring) => ring.toSet().length == a.sectorCount),
        true,
      );
    }
    final playable = generator.firstPlayable();
    expect((playable.ringCount, playable.sectorCount), (4, 12));
    expect(generator.generate(1).ringCount, 2);
    expect(generator.generate(2).ringCount, 3);
    expect(generator.generate(3).ringCount, 4);
    expect(generator.generate(4).ringCount, 5);
    expect(generator.generate(5).ringCount, 6);
    expect(generator.generate(6).ringCount, 7);
    expect(generator.generate(7).ringCount, 8);
    expect(generator.generate(80).ringCount, 8);
  });

  test('validator rejects solved, uniform, and indistinct levels', () {
    final level = const LevelGenerator().generate(31);
    const validator = LevelValidator();
    expect(validator.isValid(level), true);
    expect(
      validator.isValid(
        LevelConfig(
          number: level.number,
          ringCount: level.ringCount,
          sectorCount: level.sectorCount,
          palette: level.palette,
          shuffleOffsets: List.filled(level.ringCount, 0),
        ),
      ),
      false,
    );
    expect(
      validator.isValid(
        LevelConfig(
          number: level.number,
          ringCount: level.ringCount,
          sectorCount: level.sectorCount,
          palette: level.palette,
          shuffleOffsets: List.filled(level.ringCount, 1),
        ),
      ),
      false,
    );
    expect(
      validator.isValid(
        LevelConfig(
          number: level.number,
          ringCount: level.ringCount,
          sectorCount: 24,
          palette: level.palette,
          shuffleOffsets: level.shuffleOffsets,
        ),
      ),
      false,
    );
  });
}
