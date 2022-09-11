# griddle

Griddle _simplifies_ to concept of creating 2D games or UI applications within
a 2D-matrix, or _grid_, which in turn makes it a suitable cross-platform
graphics framework for lower fidelity games or apps.

[![On pub.dev][pub_img]][pub_url]
[![Code coverage][cov_img]][cov_url]
[![Github action status][gha_img]][gha_url]
[![Dartdocs][doc_img]][doc_url]
[![Style guide][sty_img]][sty_url]

[pub_url]: https://pub.dartlang.org/packages/griddle
[pub_img]: https://img.shields.io/pub/v/griddle.svg
[gha_url]: https://github.com/neo-dart/griddle/actions
[gha_img]: https://github.com/neo-dart/griddle/workflows/Dart/badge.svg
[cov_url]: https://codecov.io/gh/neo-dart/griddle
[cov_img]: https://codecov.io/gh/neo-dart/griddle/branch/main/graph/badge.svg
[doc_url]: https://www.dartdocs.org/documentation/griddle/latest
[doc_img]: https://img.shields.io/badge/Documentation-griddle-blue.svg
[sty_url]: https://pub.dev/packages/neodart
[sty_img]: https://img.shields.io/badge/style-neodart-9cf.svg

It is _inspired_ by:

- [`tcell`, a Go package that provides cell-based views for terminals][tcell]
- [`termbox`, a minimalistic API to write text-based UIs][termbox]
- [`termpixels`, the terminal as a character-cell matrix][termpixels]

[tcell]: https://github.com/gdamore/tcell
[termbox]: https://github.com/nsf/termbox-go
[termpixels]: https://github.com/loganzartman/termpixels

## Purpose

Creating simple 2D programs that run inside a terminal (or terminal emulator) is
complicated. The goal of `griddle` is to **abstract a terminal-like screen into
a 2D _grid_ of character cells**.

Like [`termpixels`][termpixels], this project makes the terminal more
accessible and more fun, but in Dart!

> **NOTE**: To learn more about the design of `griddle`, view [DESIGN.md][].

[design.md]: DESIGN.md

## Usage

![Example app running](https://user-images.githubusercontent.com/168174/189504284-4e09879e-75bc-4916-afe0-998f1fa0e5ae.gif)

```dart
import 'dart:math' as math;

import 'package:griddle/griddle.dart';

void main() {
  final screen = Screen.terminal(Terminal.usingAnsiStdio());
  const string = 'Hello World, from Griddle for Dart!';

  screen.onFrame.listen((_) {
    screen.clear();

    for (var i = 0; i < string.length; i++) {
      final t = DateTime.now().millisecondsSinceEpoch / 1000;
      final f = i / string.length;
      final c = Color.fromHSL(f * 300 + t, 1, 0.5);
      final x = screen.width ~/ 2 - string.length ~/ 2;
      final o = math.sin(t * 3 + f * 5) * 2;
      final y = (screen.height / 2 + o).round();

      screen.print(string[i], x + i, y, foreground: c);
    }

    screen.update();
  });
}
```

(For the full example, see [example/example.dart](example/example.dart))

## Contributing

**This package welcomes [new issues][issues] and [pull requests][fork].**

[issues]: https://github.com/matanlurey/griddle/issues/new
[fork]: https://github.com/matanlurey/griddle/fork

Changes or requests that do not match the following criteria will be rejected:

1. Common decency as described by the [Contributor Covenant][code-of-conduct].
2. Making this library brittle/extensible by other libraries.
3. Adding platform-specific functionality.
4. A somewhat arbitrary bar of "complexity", everything should be _easy to use_.

[code-of-conduct]: https://www.contributor-covenant.org/version/1/4/code-of-conduct/

### Inspiration

Some inspiration/motivational sources elsewhere:

- [`brick`, a haskell TUI](https://github.com/jtdaugherty/brick)
- [`bubbletea`, a functional Go TUI](https://github.com/charmbracelet/bubbletea)
- [`gruid`, a modular Go TUI](https://github.com/anaseto/gruid)
