import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hue_wheel/app/app.dart';
import 'package:hue_wheel/core/persistence/progress_repository.dart';
import 'package:hue_wheel/features/puzzle/domain/puzzle_models.dart';
import 'package:hue_wheel/features/puzzle/logic/level_generator.dart';
import 'package:hue_wheel/features/puzzle/logic/palette_generator.dart';
import 'package:hue_wheel/features/puzzle/presentation/widgets/color_wheel.dart';

class _MemoryProgressRepository implements ProgressRepository {
  AppProgress value = const AppProgress();
  @override
  AppProgress read() => value;
  @override
  Future<void> write(AppProgress progress) async => value = progress;
}

void main() {
  testWidgets(
    'a grabbed ring follows without jumping and commits one sector move',
    (tester) async {
      final level = const LevelGenerator().generate(1);
      final colors = const HslColorPaletteGenerator().generate(level);
      final key = GlobalKey<ColorWheelState>();
      final moves = <(int, int)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 300,
                child: ColorWheel(
                  key: key,
                  level: level,
                  colors: colors,
                  onMove: (ring, offset) => moves.add((ring, offset)),
                ),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(ColorWheel));
      final start = center + const Offset(0, -65);
      final before = key.currentState!.rotations;
      final gesture = await tester.startGesture(start);
      expect(key.currentState!.rotations, before);
      await gesture.moveTo(center + const Offset(65, 0));
      await tester.pump();
      expect(
        key.currentState!.rotations[0] - before[0],
        closeTo(math.pi / 2, 0.001),
      );
      expect(key.currentState!.rotations[1], before[1]);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moves.length, 1);
      expect(moves.single.$1, 0);
      expect(moves.single.$2, normalizeSector(level.shuffleOffsets[0] + 2, 6));
    },
  );

  testWidgets('cancel restores rotation and does not count a move', (
    tester,
  ) async {
    final level = const LevelGenerator().generate(1);
    final key = GlobalKey<ColorWheelState>();
    var moves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 300,
              child: ColorWheel(
                key: key,
                level: level,
                colors: const HslColorPaletteGenerator().generate(level),
                onMove: (_, _) => moves++,
              ),
            ),
          ),
        ),
      ),
    );
    final center = tester.getCenter(find.byType(ColorWheel));
    final before = key.currentState!.rotations[0];
    final gesture = await tester.startGesture(center + const Offset(0, -65));
    await gesture.moveTo(center + const Offset(65, 0));
    await gesture.moveTo(center + const Offset(130, 0));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(key.currentState!.rotations[0], closeTo(before, 0.001));
    expect(moves, 0);
  });

  testWidgets('restart and completion advance saved progress', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryProgressRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        child: const HueWheelApp(),
      ),
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 1'), findsOneWidget);
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    expect(find.text('MOVES  0'), findsOneWidget);
    await tester.tap(find.text('Debug'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instant Solve'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('Level complete'), findsOneWidget);
    expect(find.text('RINGS ALIGNED  2 / 2'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
    expect(repository.value.currentLevel, 2);
    expect(repository.value.highestUnlockedLevel, 2);
    await tester.tap(find.text('Next level'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        child: const HueWheelApp(),
      ),
    );
    expect(find.text('Level 2 · 3 rings'), findsOneWidget);
  });

  testWidgets('level dropdown selects levels with progressively more rings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryProgressRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        child: const HueWheelApp(),
      ),
    );
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Level 3 · 4 rings').last);
    await tester.pumpAndSettle();
    expect(repository.value.currentLevel, 3);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 3'), findsOneWidget);
    final wheel = tester.widget<ColorWheel>(find.byType(ColorWheel));
    expect(wheel.level.ringCount, 4);
  });

  testWidgets('shows partial ring progress then finishes after the last ring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryProgressRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        child: const HueWheelApp(),
      ),
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final wheelFinder = find.byType(ColorWheel);
    final wheel = tester.widget<ColorWheel>(wheelFinder);
    final wheelSize = tester.getSize(wheelFinder);
    final center = tester.getCenter(wheelFinder);
    final outerRadius = wheelSize.shortestSide / 2 - 2;
    double radiusForRing(int ring) => ring == wheel.level.ringCount - 1
        ? outerRadius * 0.9
        : outerRadius * 0.38;

    Future<void> solveRing(int ring) async {
      final offset = wheel.level.shuffleOffsets[ring];
      final delta = -offset * 2 * math.pi / wheel.level.sectorCount;
      const maxStep = 0.2;
      final steps = (delta.abs() / maxStep).ceil();
      final radius = radiusForRing(ring);
      final gesture = await tester.startGesture(center + Offset(radius, 0));
      for (var step = 1; step <= steps; step++) {
        final angle = delta * step / steps;
        await gesture.moveTo(
          center + Offset(radius * math.cos(angle), radius * math.sin(angle)),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await solveRing(wheel.level.ringCount - 1);
    expect(find.text('RINGS ALIGNED  1 / 2'), findsOneWidget);
    expect(find.text('Next level'), findsNothing);

    await solveRing(0);
    expect(find.text('RINGS ALIGNED  2 / 2'), findsOneWidget);
    expect(find.text('Level complete'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
  });

  testWidgets('settings are persisted through the repository', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryProgressRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        child: const HueWheelApp(),
      ),
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haptics'));
    await tester.pumpAndSettle();
    expect(repository.value.soundEnabled, false);
    expect(repository.value.hapticsEnabled, false);
  });
}
