import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProgress {
  const AppProgress({
    this.currentLevel = 1,
    this.highestUnlockedLevel = 1,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  final int currentLevel;
  final int highestUnlockedLevel;
  final bool soundEnabled;
  final bool hapticsEnabled;

  AppProgress copyWith({
    int? currentLevel,
    int? highestUnlockedLevel,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) => AppProgress(
    currentLevel: currentLevel ?? this.currentLevel,
    highestUnlockedLevel: highestUnlockedLevel ?? this.highestUnlockedLevel,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
  );
}

abstract class ProgressRepository {
  AppProgress read();
  Future<void> write(AppProgress progress);
}

class SharedPreferencesProgressRepository implements ProgressRepository {
  SharedPreferencesProgressRepository(this.preferences);
  final SharedPreferences preferences;

  @override
  AppProgress read() => AppProgress(
    currentLevel: (preferences.getInt('currentLevel') ?? 1).clamp(1, 1000000),
    highestUnlockedLevel: (preferences.getInt('highestUnlockedLevel') ?? 1)
        .clamp(1, 1000000),
    soundEnabled: preferences.getBool('soundEnabled') ?? true,
    hapticsEnabled: preferences.getBool('hapticsEnabled') ?? true,
  );

  @override
  Future<void> write(AppProgress progress) async {
    await Future.wait([
      preferences.setInt('currentLevel', progress.currentLevel),
      preferences.setInt('highestUnlockedLevel', progress.highestUnlockedLevel),
      preferences.setBool('soundEnabled', progress.soundEnabled),
      preferences.setBool('hapticsEnabled', progress.hapticsEnabled),
    ]);
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  throw StateError('ProgressRepository must be provided at startup.');
});

class AppProgressController extends Notifier<AppProgress> {
  @override
  AppProgress build() => ref.read(progressRepositoryProvider).read();

  Future<void> _save(AppProgress next) async {
    state = next;
    await ref.read(progressRepositoryProvider).write(next);
  }

  Future<void> completeLevel(int level) async {
    if (state.currentLevel != level) return;
    final next = level + 1;
    await _save(
      state.copyWith(
        currentLevel: next,
        highestUnlockedLevel: next > state.highestUnlockedLevel
            ? next
            : state.highestUnlockedLevel,
      ),
    );
  }

  Future<void> selectLevel(int level) async {
    await _save(state.copyWith(currentLevel: level.clamp(1, 1000000)));
  }

  Future<void> setSound(bool enabled) =>
      _save(state.copyWith(soundEnabled: enabled));

  Future<void> setHaptics(bool enabled) =>
      _save(state.copyWith(hapticsEnabled: enabled));
}

final appProgressProvider =
    NotifierProvider<AppProgressController, AppProgress>(
      AppProgressController.new,
    );
