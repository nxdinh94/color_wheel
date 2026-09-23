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
          final hue = normalizeDegrees(
            p.baseHue + p.hueRange * sector / level.sectorCount,
          );
          // Keep the whole wheel monochromatic while retaining a visible
          // shade for each sector so rotating a ring remains observable.
          final shadeProgress = level.sectorCount <= 1
              ? 0.5
              : sector / (level.sectorCount - 1);
          final shadeOffset = (shadeProgress - 0.5) * 0.22;
          final shadedLightness = (lightness + shadeOffset).clamp(0.05, 0.95);
          return HSLColor.fromAHSL(
            1,
            hue,
            saturation,
            shadedLightness,
          ).toColor();
        }),
      );
    });
  }
}
