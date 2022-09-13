import 'dart:io' show stdout;
import 'dart:math' as math;

import 'package:griddle/griddle.dart';

/// A sample application, similar to the one provided in [termpixels][].
///
/// [termpixels]: https://github.com/loganzartman/termpixels
void main() {
  run(
    Screen.display(
      Display.fromAnsiTerminal(
        stdout,
        width: () => stdout.terminalColumns,
        height: () => stdout.terminalLines,
      ),
    ),
  );
}

void run(Screen screen) {
  const string = 'Hello World, from Griddle for Dart!';
  final frames = Stopwatch()..start();
  Stream<void>.periodic(const Duration(milliseconds: 1000 ~/ 30)).listen((_) {
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
      ..print('${frames.elapsedMilliseconds}ms', 0, screen.height ~/ 2 - 2)
      ..update();

    frames.reset();
  });
}
