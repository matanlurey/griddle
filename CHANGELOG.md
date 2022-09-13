# CHANGELOG

## 0.3.0

In accordance with our [design](DESIGN.md), any features that are not
appropriate for a high-level _canvas-like_ API were removed from this package:

- `Screen(framesPerSecond: ...)` and `Screen.terminal(framesPerSecond: ...)`.
- `<Screen>.onFrame`:

  ```dart
  // Before
  final screen = Screen(framesPerSecond: 30);
  screen.onFrame.listen((_) { /* ... */ })

  // After
  final screen = Screen();
  final frames = Stopwatch()..start();
  Stream.periodic(Duration(milliseconds: 1000 ~/ 30)).listen((_) {
    final time = frames.elapsed;
    frames.reset();
    /* ... */
  });
  ```

- `Terminal.usingAnsiStdio({stdin: ...})`:

  ```dart
  // Before
  import 'package:griddle/griddle.dart';

  void main() {
    Screen.terminal(Terminal.usingAnsiStdio());
  }
  ```

  ```dart
  // After
  import 'dart:io';

  import 'package:griddle/griddle.dart';

  void main() {
    Screen.display(
      Display.fromAnsiTerminal(
        stdout,
        width: () => stdout.width,
        height: () => stdout.height,
      ),
    );
  }
  ```

These changes allow us to focus on just pushing pixels and output, versus
worrying about other elements of UI, such as the update loop or user input,
which are better suited to other packages, as well as keeping this package
completely platform agnostic.

**If this API remains relatively stable, it will (eventually) become `1.0.0`.**

## 0.2.0

New release with many bug fixes, changes, and [new examples](example/README.md)!

### Backwards Compatible

- Added `Buffer.fromCells` and `Buffer.fromMatrix` as helpful factory methods.
- Added `<Buffer>.length` as an alias for `<Buffer>.width * <Buffer>.height`.
- Added `<Buffer>[]` and `<Buffer>[]=` for indexed reads/writes into a buffer.
- Added `<Buffer>.toList()` which returns a copy of the underlying cells.
- Added `<Buffer>.toMatrix()` which returns a copy of cells as nested lists.
- Changed `Buffer(width, height)`, added an optional `initialCell` parameter:

  ```dart
  // Before.
  Buffer(3, 3);

  // Semantically identical.
  Buffer(3, 3, initialCell: Cell.blank);

  // Newly possible.
  Buffer(3, 3, initialCell: Cell('X'));
  ```

### Breaking Changes

- Terminal output always skips line `0` and starts on line `1` for readability.
- Fixed a bug where cells were stored as `y * height + x`, not `y * width + x`.
- Fixed a bug where `<Buffer>.clear()` just didn't work, period.
- Fixed a bug where `<Buffer>.resize()` created an invalid state.
- Changed `<Buffer>.resize()` to have named parameters, and added `expand`:

  ```dart
  // Before
  buffer.resize(3, 4);

  // Semantically identical.
  buffer.resize(width: 3, height: 4);

  // Newly possible: just change width OR heght.
  buffer.resize(width: 3);
  buffer.resize(height: 4);

  // Newly possible: specify what cell to fill when expanding the buffer.
  // (Defaults to Cell.blank)
  buffer.resize(width: 3, height: 4, expand: Cell('X'));
  ```

- Changed `<Buffer>.fill()` to have only named parameters:

  ```dart
  // Before
  buffer.fill(1, 1, 2, 2);

  // Semantically identical.
  buffer.fill(x: 1, y: 1, width: 2, height: 2);
  ```

## 0.1.0

- Initial (real) commit, with a simple API and animated text example.

## 0.0.0

- Initial release as a placeholder only.
