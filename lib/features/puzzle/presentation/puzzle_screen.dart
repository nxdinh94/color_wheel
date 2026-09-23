import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/feedback_services.dart';
import '../../../core/persistence/progress_repository.dart';
import '../../settings/settings_screen.dart';
import '../domain/puzzle_models.dart';
import '../logic/level_generator.dart';
import '../logic/palette_generator.dart';
import 'widgets/color_wheel.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  final _generator = const LevelGenerator();
  final _palette = const HslColorPaletteGenerator();
  late LevelConfig _sourceLevel;
  late LevelConfig _visibleLevel;
  late PuzzleState _puzzle;
  late List<List<Color>> _colors;
  int _wheelRevision = 0;
  int _completionToken = 0;
  int _debugSeed = LevelGenerator.defaultSeed;
  bool _celebrating = false;
  bool _isComplete = false;
  bool _pulse = false;
  bool _debugPanel = false;

  @override
  void initState() {
    super.initState();
    final number = ref.read(appProgressProvider).currentLevel;
    _load(_generator.generate(number));
  }

  void _load(LevelConfig level) {
    _sourceLevel = level;
    _visibleLevel = level;
    _puzzle = PuzzleState.initial(level);
    _colors = _palette.generate(level);
    _wheelRevision++;
    _celebrating = false;
    _isComplete = false;
    _pulse = false;
    _completionToken++;
  }

  void _feedbackTick() {
    final settings = ref.read(appProgressProvider);
    if (settings.soundEnabled) ref.read(audioServiceProvider).tick();
    if (settings.hapticsEnabled) ref.read(hapticServiceProvider).tick();
  }

  void _feedbackSuccess() {
    final settings = ref.read(appProgressProvider);
    if (settings.soundEnabled) ref.read(audioServiceProvider).success();
    if (settings.hapticsEnabled) ref.read(hapticServiceProvider).success();
  }

  void _onMove(int ring, int offset) {
    if (_celebrating) return;
    setState(() => _puzzle = _puzzle.withMove(ring, offset));
    _feedbackTick();
    if (_puzzle.isCompleted) _complete();
  }

  Future<void> _complete() async {
    if (_isComplete) return;
    final token = ++_completionToken;
    setState(() {
      _celebrating = true;
      _isComplete = true;
      _pulse = true;
    });
    _feedbackSuccess();
    if (_sourceLevel.number > 0) {
      await ref
          .read(appProgressProvider.notifier)
          .completeLevel(_sourceLevel.number);
    }
    if (!mounted || token != _completionToken) return;
    await Future<void>.delayed(const Duration(milliseconds: 340));
    if (!mounted || token != _completionToken) return;
    setState(() => _pulse = false);
    await Future<void>.delayed(const Duration(milliseconds: 410));
    if (!mounted || token != _completionToken) return;
    setState(() => _celebrating = false);
  }

  void _nextLevel() {
    if (!_isComplete) return;
    final next = _sourceLevel.number == 0
        ? ref.read(appProgressProvider).currentLevel
        : _sourceLevel.number + 1;
    setState(() => _load(_generator.generate(next)));
  }

  void _restart() {
    setState(() => _load(_sourceLevel));
  }

  void _regenerate() {
    _debugSeed++;
    setState(
      () => _load(
        _sourceLevel.number == 0
            ? _generator.firstPlayable(seed: _debugSeed)
            : _generator.generate(_sourceLevel.number, seed: _debugSeed),
      ),
    );
  }

  void _testWheel() {
    setState(() => _load(_generator.firstPlayable(seed: _debugSeed)));
  }

  void _instantSolve() {
    if (_celebrating) return;
    final solved = LevelConfig(
      number: _sourceLevel.number,
      ringCount: _sourceLevel.ringCount,
      sectorCount: _sourceLevel.sectorCount,
      palette: _sourceLevel.palette,
      shuffleOffsets: List.filled(_sourceLevel.ringCount, 0),
    );
    setState(() {
      _visibleLevel = solved;
      _puzzle = PuzzleState.initial(solved);
      _wheelRevision++;
    });
    _complete();
  }

  @override
  Widget build(BuildContext context) {
    final number = _sourceLevel.number;
    final alignedRings = _puzzle.rings
        .where((ring) => ring.isSolved(_puzzle.level.sectorCount))
        .length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  Text(
                    number == 0 ? 'TEST WHEEL' : 'LEVEL $number',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Color(0xFF77736D),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const aspectRatio = 1.24;
                    final width = math.min(
                      constraints.maxWidth - 4,
                      (constraints.maxHeight - 12) * aspectRatio,
                    );
                    final height = width / aspectRatio;
                    return Center(
                      child: AnimatedScale(
                        scale: _pulse ? 1.025 : 1,
                        duration: const Duration(milliseconds: 340),
                        curve: Curves.easeInOut,
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: ColorWheel(
                            key: ValueKey(_wheelRevision),
                            level: _visibleLevel,
                            colors: _colors,
                            onMove: _onMove,
                            showDebug: kDebugMode && _debugPanel,
                            enabled: !_isComplete,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              AnimatedOpacity(
                opacity: _isComplete ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Text(
                  'Level complete',
                  style: TextStyle(
                    color: Color(0xFF68645F),
                    fontSize: 15,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'MOVES  ${_puzzle.moveCount}',
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: Color(0xFF77736D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: alignedRings == _puzzle.rings.length
                      ? const Color(0xFFE5EDE2)
                      : const Color(0xFFEFEDE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'RINGS ALIGNED  $alignedRings / ${_puzzle.rings.length}',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: alignedRings == _puzzle.rings.length
                        ? const Color(0xFF4D654A)
                        : const Color(0xFF77736D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isComplete)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _celebrating ? null : _nextLevel,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3030),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Next level',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Restart'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF65615C),
                  ),
                ),
              if (kDebugMode)
                ExpansionTile(
                  title: const Text('Debug', style: TextStyle(fontSize: 12)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  onExpansionChanged: (value) =>
                      setState(() => _debugPanel = value),
                  children: [
                    Text(
                      'Offsets: ${_puzzle.rings.map((r) => r.currentOffset).join(', ')}  '
                      'Target: ${_puzzle.rings.map((r) => r.solutionOffset).join(', ')}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _instantSolve,
                          child: const Text('Instant Solve'),
                        ),
                        TextButton(
                          onPressed: _regenerate,
                          child: const Text('Regenerate'),
                        ),
                        TextButton(
                          onPressed: _testWheel,
                          child: const Text('4×12 Test'),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
