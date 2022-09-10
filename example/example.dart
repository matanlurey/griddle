import 'dart:async';
import 'dart:math' as math;

import 'package:griddle/griddle.dart';

/// A sample application, similar to the one provided in [termpixels][].
///
/// [termpixels]: https://github.com/loganzartman/termpixels
void main(List<String> args) {
  final debug = args.length == 1 && args.first == 'debug';

  final screen = Screen.terminal(Terminal.usingAnsiStdio());
  const string = 'Hello world, from termpixels!';

  Timer.periodic(const Duration(milliseconds: 1000 ~/ 5), (_) {
    late final Stopwatch elapsed;

    if (!debug) {
      screen.clear();
    } else {
      elapsed = Stopwatch()..start();
    }

    for (var i = 0; i < string.length; i++) {
      final t = DateTime.now().millisecondsSinceEpoch * 1000;
      final f = i / string.length;
      final x = screen.width ~/ 2 - string.length ~/ 2;
      final o = math.sin(t * 3 + f * 5) * 2;
      final y = (screen.height / 2 + o).round();
      final c = Color.fromHSL(f * 100 + t, 1, 0.5);

      if (debug) {
        print('${string[i]}: ($x, $y) = $c from h=${f * 100 + t} [f=$f, t=$t]');
      }

      screen.setCell(x + i, y, Cell(string[i]).withColor(foreground: c));
    }

    if (!debug) {
      screen.update();
    } else {
      print('Frame took ${elapsed.elapsedMilliseconds}ms');
    }
  });
}
