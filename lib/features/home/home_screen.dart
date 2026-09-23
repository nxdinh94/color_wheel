import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../puzzle/logic/level_generator.dart';
import '../puzzle/logic/palette_generator.dart';
import '../puzzle/presentation/puzzle_screen.dart';
import '../puzzle/presentation/widgets/wheel_painter.dart';
import '../settings/settings_screen.dart';
import '../../core/persistence/progress_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(appProgressProvider).currentLevel;
    final progressController = ref.read(appProgressProvider.notifier);
    final preview = const LevelGenerator().firstPlayable();
    final colors = const HslColorPaletteGenerator().generate(preview);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Settings',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
              const Spacer(),
              Text(
                'HUE WHEEL',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'A quiet puzzle of color and alignment',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 42),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth.clamp(0.0, 320.0);
                  return SizedBox(
                    width: size,
                    height: size / 1.06,
                    child: CustomPaint(
                      painter: WheelPainter(
                        colors: colors,
                        rotations: List.filled(preview.ringCount, 0),
                        repaint: const AlwaysStoppedAnimation(0),
                        arcDisplay: true,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'SELECT LEVEL',
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: Color(0xFF817B72),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1EEE8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: level,
                    items: [
                      for (var choice = 1; choice <= 80; choice++)
                        DropdownMenuItem(
                          value: choice,
                          child: Text(
                            'Level $choice · ${_ringCountFor(choice)} rings',
                          ),
                        ),
                      if (level > 80)
                        DropdownMenuItem(
                          value: level,
                          child: Text(
                            'Level $level · ${_ringCountFor(level)} rings',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        progressController.selectLevel(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PuzzleScreen(),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2F3030),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  int _ringCountFor(int level) => (level + 2).clamp(3, 9);
}
