import '../domain/puzzle_models.dart';

class LevelGenerator {
  const LevelGenerator();
  static const int defaultSeed = 0x485545;

  LevelConfig generate(int levelNumber, {int seed = defaultSeed}) {
    final number = levelNumber < 1 ? 1 : levelNumber;
    final rings = (number + 2).clamp(3, 9);
    final sectors = switch (number) {
      <= 2 => 6,
      <= 4 => 8,
      <= 6 => 10,
      _ => 12,
    };
    final rng = _StableRandom(seed ^ (number * 0x9e3779b9));
    final palette = PaletteConfig(
      baseHue: rng.nextInt(360).toDouble(),
      hueRange: 0,
      innerLightness: number <= 15 ? 0.32 : 0.35,
      outerLightness: number <= 15 ? 0.68 : 0.65,
      innerSaturation: number <= 30 ? 0.64 : 0.58,
      outerSaturation: number <= 30 ? 0.98 : 0.94,
    );
    late List<int> offsets;
    do {
      offsets = [
        0,
        for (var ring = 1; ring < rings - 1; ring++)
          1 + rng.nextInt(sectors - 1),
        0,
      ];
    } while (offsets.length > 3 &&
        offsets.sublist(1, offsets.length - 1).toSet().length == 1);
    final level = LevelConfig(
      number: number,
      ringCount: rings,
      sectorCount: sectors,
      palette: palette,
      shuffleOffsets: List.unmodifiable(offsets),
    );
    if (!const LevelValidator().isValid(level)) {
      throw StateError('Generated an invalid level $number.');
    }
    return level;
  }

  LevelConfig firstPlayable({int seed = defaultSeed}) {
    final rng = _StableRandom(seed);
    late List<int> offsets;
    do {
      offsets = [0, 1 + rng.nextInt(11), 1 + rng.nextInt(11), 0];
    } while (offsets[1] == offsets[2]);
    final level = LevelConfig(
      number: 0,
      ringCount: 4,
      sectorCount: 12,
      palette: const PaletteConfig(
        baseHue: 0,
        hueRange: 0,
        innerLightness: 0.29,
        outerLightness: 0.66,
        innerSaturation: 0.66,
        outerSaturation: 0.98,
      ),
      shuffleOffsets: List.unmodifiable(offsets),
    );
    if (!const LevelValidator().isValid(level)) {
      throw StateError('Generated an invalid test level.');
    }
    return level;
  }
}

class LevelValidator {
  const LevelValidator();

  bool isValid(LevelConfig level) {
    if (level.ringCount < 3 ||
        level.sectorCount < 6 ||
        level.shuffleOffsets.length != level.ringCount) {
      return false;
    }
    if (level.shuffleOffsets.first != 0 || level.shuffleOffsets.last != 0) {
      return false;
    }
    final movableOffsets = level.shuffleOffsets.sublist(
      1,
      level.shuffleOffsets.length - 1,
    );
    if (movableOffsets.any(
          (offset) => offset <= 0 || offset >= level.sectorCount,
        ) ||
        (movableOffsets.length > 1 && movableOffsets.toSet().length == 1)) {
      return false;
    }
    final p = level.palette;
    if (!p.baseHue.isFinite ||
        p.hueRange < 0 ||
        p.hueRange > 360 ||
        360 / level.sectorCount < 30 ||
        p.innerSaturation < 0 ||
        p.innerSaturation > 1 ||
        p.outerSaturation < 0 ||
        p.outerSaturation > 1 ||
        p.innerLightness < 0 ||
        p.innerLightness > 1 ||
        p.outerLightness < 0 ||
        p.outerLightness > 1 ||
        p.outerLightness - p.innerLightness < 0.05 ||
        p.outerSaturation < p.innerSaturation) {
      return false;
    }
    return true;
  }
}

class _StableRandom {
  _StableRandom(int seed) : _state = seed & 0xffffffff {
    if (_state == 0) _state = 0x6d2b79f5;
  }
  int _state;
  int nextInt(int max) {
    _state ^= (_state << 13) & 0xffffffff;
    _state ^= _state >> 17;
    _state ^= (_state << 5) & 0xffffffff;
    _state &= 0xffffffff;
    return _state % max;
  }
}
