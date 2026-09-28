import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/puzzle_models.dart';

abstract class ColorPaletteGenerator {
  List<List<Color>> generate(LevelConfig level);
}

class HslColorPaletteGenerator implements ColorPaletteGenerator {
  const HslColorPaletteGenerator();

  @override
  List<List<Color>> generate(LevelConfig level) {
    final p = level.palette;
    final random = math.Random(_seedFor(level));
    final ringHues = List.generate(level.ringCount, (ring) {
      // Keep the outer ring as the stable reference. Movable rings get a
      // different, reproducible hue from the same family around baseHue.
      if (ring == level.ringCount - 1 || p.hueRange == 0) {
        return normalizeDegrees(p.baseHue);
      }
      final familyOffset = (random.nextDouble() - 0.5) * p.hueRange;
      return normalizeDegrees(p.baseHue + familyOffset);
    });

    return List.generate(level.ringCount, (ring) {
      final progress = level.ringCount <= 1
          ? 0.0
          : ring / (level.ringCount - 1);
      final saturation =
          p.innerSaturation +
          (p.outerSaturation - p.innerSaturation) * progress;
      final lightness =
          p.innerLightness + (p.outerLightness - p.innerLightness) * progress;
      return List.unmodifiable(
        List.generate(level.sectorCount, (sector) {
          // Keep each ring in one color family while retaining a visible
          // shade for each sector so rotating a ring remains observable.
          final shadeProgress = level.sectorCount <= 1
              ? 0.5
              : sector / (level.sectorCount - 1);
          final shadeOffset = (shadeProgress - 0.5) * 0.22;
          final shadedLightness = (lightness + shadeOffset).clamp(0.05, 0.95);
          return HSLColor.fromAHSL(
            1,
            ringHues[ring],
            saturation,
            shadedLightness,
          ).toColor();
        }),
      );
    });
  }

  int _seedFor(LevelConfig level) {
    var seed = level.number * 0x9e3779b9;
    seed ^= level.ringCount * 0x85ebca6b;
    seed ^= level.sectorCount * 0xc2b2ae35;
    seed ^= _pHueSeed(level.palette.baseHue);
    return seed & 0x7fffffff;
  }

  int _pHueSeed(double hue) => hue.round() * 0x27d4eb2d;
}
