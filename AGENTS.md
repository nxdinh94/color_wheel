# Hue Wheel

A Flutter color wheel puzzle game with offline progress stored using
SharedPreferences and application state managed with Riverpod.

## Project layout

- `lib/features/puzzle/domain`: puzzle state and circular geometry helpers.
- `lib/features/puzzle/logic`: reproducible levels and color palettes.
- `lib/features/puzzle/presentation`: gestures, animation, and wheel rendering.
- `lib/core/persistence`: saved progress and sound/haptic preferences.
- `test`: puzzle logic and widget tests.

## Validation

Use a Flutter SDK compatible with the Dart constraint in `pubspec.yaml`.
Run `flutter pub get`, `flutter analyze`, and `flutter test` for code changes.
When changing gestures or painting, exercise the affected interaction on a
device or emulator as well. Report existing failures separately from regressions.

## Code Review Rules

- Flag rotations, hit testing, or snapping changes that move the stationary
  outer reference ring, jump across the angle boundary, or misclassify solved
  states. Normalize circular offsets before comparing them; deliberate changes
  to the puzzle design must update the corresponding behavior and tests.
- Flag level or palette changes that make a puzzle start solved, become
  unsolvable, or render its intended solution visually ambiguous. Preserve
  reproducibility for the same level and seed unless a versioned design change
  explicitly accounts for existing saved progress.
- Flag progress and preference changes that lose unlocked levels, reset saved
  settings, or allow an older asynchronous save to overwrite newer state.
  Preserve existing storage keys, or provide a migration when changing them.
