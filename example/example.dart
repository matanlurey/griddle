import 'dart:math' as math;

import 'package:griddle/griddle.dart';

/// A sample application, similar to the one provided in [termpixels][].
///
/// [termpixels]: https://github.com/loganzartman/termpixels
void main() {
  final terminal = Terminal.usingAnsiStdio();

  try {
    run(Screen.terminal(terminal));
  } finally {
    terminal
      ..resetStyles()
      ..showCursor();
  }
}

void run(Screen screen) {
  const string = 'Hello World, from Griddle for Dart!';
  screen.onFrame.listen((elapsed) {
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

    screen
      ..print('${elapsed.inMilliseconds}ms', 0, screen.height ~/ 2 - 2)
      ..update();
  });
}
