# CHANGELOG

## 0.4.0

- Split `Buffer` into two interfaces: `Buffer` (immutable) and `WritableBuffer`.

  - If you were just using `Buffer` indirectly through `Screen`, no API changes.
  - If you were creating a `Buffer` and writing to it, use `WritableBuffer` now:

  ```diff
  - final buffer = Buffer(3, 3);
  + final buffer = WritableBuffer(3, 3);

  buffer.print('Hello', 0, 1);
  ```

- Added `<WritableBuffer>.fillFrom`, which is _spiritually_ a [`BITBLT`][]:

  ```dart
  // Pre-define a sprite-like object in an immutable buffer.
  final other = Buffer.fromMatrix([
    [Cell('┏'), Cell('┓')],
    [Cell('┃'), Cell('┃')],
    [Cell('┗'), Cell('┛')],
  ]);

  // Copy it into a writable buffer.
  final buffer = WritableBuffer(5, 5)..fillFrom(other, x: 2, y: 1);
  ```

[`bitblt`]: https://en.wikipedia.org/wiki/Bit_blit

## 0.3.1

Applied basic optimizations to ANSI escape code screens.

```dart
// Before
screen.print('GREEN', 0, 2, foreground: green, background: blue);
screen.update();
```

... produced:

```txt
\x1B[2J\n
\x1B[0m \x1B[0m \x1B[0m \x1B[0m \x1B[0m\n
\x1B[0mH\x1B[0mE\x1B[0mL\x1B[0mL\x1B[0mO\n
      \x1B[38;2;0;255;0m\x1B[48;2;0;0;255mG\x1B[38;2;0;255;0m\x1B[48;2;0;0;255mR\x1B[38;2;0;255;0m\x1B[48;2;0;0;255mE\x1B[38;2;0;255;0m\x1B[48;2;0;0;255mE\x1B[38;2;0;255;0m\x1B[48;2;0;0;255mN\n
```

... and after the optimizations:

```txt
\x1B[2J\n
      \n
\x1B[0m\x1B[38;2;0;255;0m\x1B[48;2;0;0;255mGREEN\n
```

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
