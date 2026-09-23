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
    final palette = List.generate(level.sectorCount, (sector) {
      final hue = normalizeDegrees(
        p.baseHue + p.hueRange * sector / level.sectorCount,
      );
      return HSLColor.fromAHSL(
        1,
        hue,
        (p.innerSaturation + p.outerSaturation) / 2,
        (p.innerLightness + p.outerLightness) / 2,
      ).toColor();
    });
    return List.generate(
      level.ringCount,
      (_) => List<Color>.unmodifiable(palette),
    );
  }
}
