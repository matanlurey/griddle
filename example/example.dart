import 'dart:async';
import 'dart:math' as math;

import 'package:griddle/griddle.dart';

/// A sample application, similar to the one provided in [termpixels][].
///
/// [termpixels]: https://github.com/loganzartman/termpixels
void main() {
  final terminal = Terminal.usingAnsiStdio();

  try {
    run(Screen.terminal(terminal..hideCursor()));
  } finally {
    terminal
      ..resetStyles()
      ..showCursor();
  }
}

void run(Screen scren) {
  final screen = Screen.terminal(Terminal.usingAnsiStdio());
  const string = 'Hello World, from Griddle for Dart!';

  final timer = Stopwatch();
  var elapsedMs = 0;

  Timer.periodic(const Duration(milliseconds: 1000 ~/ 30), (_) {
    timer.start();
    screen.clear();

    for (var i = 0; i < string.length; i++) {
      final t = DateTime.now().millisecondsSinceEpoch / 1000;
      final f = i / string.length;
      final c = Color.fromHSL(f * 300 + t, 1, 0.5);
      final x = screen.width ~/ 2 - string.length ~/ 2;
      final o = math.sin(t * 3 + f * 5) * 2;
      final y = (screen.height / 2 + o).round();

      screen.setCell(x + i, y, Cell(string[i]).withColor(foreground: c));
    }

    final msText = '${elapsedMs}ms';
    final yMsPos = screen.height ~/ 2 - 2;
    for (var i = 0; i < msText.length; i++) {
      screen.setCell(i, yMsPos, Cell(msText[i]));
    }

    screen.update();
    elapsedMs = timer.elapsedMilliseconds;
    timer.reset();
  });
}
