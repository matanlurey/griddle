import 'dart:async';
import 'dart:math' as math;

import 'package:griddle/griddle.dart';

/// A sample application, similar to the one provided in [termpixels][].
///
/// [termpixels]: https://github.com/loganzartman/termpixels
void main() {
  final screen = Screen.terminal(Terminal.usingAnsiStdio());
  const string = 'Hello World, from Griddle!';

  Timer.periodic(const Duration(milliseconds: 20), (_) {
    screen.clear();

    for (var i = 0; i < string.length; i++) {
      final t = DateTime.now().millisecondsSinceEpoch;
      final f = i / string.length;
      final x = screen.width ~/ 2 - string.length ~/ 2;
      final o = math.sin(t * 3 + f * 5) * 2;
      final y = (screen.height / 2 + o).round();
      final c = Ansi8BitColors.values[_hslTo256(f + t, 1, 0.5)];
      // print('$i = $c (#${_hslTo256(f + t, 1, 0.5)}) from ${f + t}, 1, 0.5');
      screen.setCell(x + i, y, Cell(string[i]).withColor8(foreground: c));
    }

    screen.update();
  });
}

/// Converts the RGB color component [c] to the nearest xterm color cube index.
double _nearestCubeIndex(double c) {
  return ((c < 75 ? c + 28 : c) - 32) / 40;
}

/// Returns the cooresponding 6x6x6 RGB cube color (i.e. 8-bit color palette).
///
/// This function ignores graycales and assumes color for simplicity.
double _rgbTo256(double r, double g, double b) {
  final rIndex = _nearestCubeIndex(r);
  final gIndex = _nearestCubeIndex(g);
  final bIndex = _nearestCubeIndex(b);
  return 16 + (36 * rIndex) + (6 * gIndex) + bIndex;
}

/// Converts
int _hslTo256(double h, double s, double l) {
  final a = s * math.min(l, 1 - l);

  double f(int n) {
    final k = n + (h / 30) % 12;
    return l - a * math.max(math.min(math.min(k - 3, 9 - k), 1), -1);
  }

  return _rgbTo256(f(0), f(8), f(4)).round();
}
