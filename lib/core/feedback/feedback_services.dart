import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AudioService {
  void tick();
  void success();
}

abstract class HapticService {
  void tick();
  void success();
}

class SystemAudioService implements AudioService {
  const SystemAudioService();
  @override
  void tick() => unawaited(SystemSound.play(SystemSoundType.click));
  @override
  void success() => unawaited(SystemSound.play(SystemSoundType.click));
}

class SystemHapticService implements HapticService {
  const SystemHapticService();
  @override
  void tick() => unawaited(HapticFeedback.selectionClick());
  @override
  void success() => unawaited(HapticFeedback.lightImpact());
}

final audioServiceProvider = Provider<AudioService>(
  (ref) => const SystemAudioService(),
);
final hapticServiceProvider = Provider<HapticService>(
  (ref) => const SystemHapticService(),
);
