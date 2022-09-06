import 'dart:async';
import 'dart:math' as math;

// TODO: Remove this package and replace with pkg/neocolor.
import 'package:color/color.dart';
import 'package:griddle/griddle.dart';

/// A sample application, similar to the one provided in [termpixels][].
///
/// [termpixels]: https://github.com/loganzartman/termpixels
void main(List<String> args) {
  final debug = args.length == 1 && args.first == 'debug';

  final screen = Screen.terminal(Terminal.usingAnsiStdio());
  const string = 'Hello World, from Griddle!';

  Timer.periodic(const Duration(milliseconds: 100), (_) {
    if (!debug) {
      screen.clear();
    }

    for (var i = 0; i < string.length; i++) {
      final t = DateTime.now().millisecondsSinceEpoch;
      final f = i / string.length;
      final x = screen.width ~/ 2 - string.length ~/ 2;
      final o = math.sin(t * 3 + f * 5) * 2;
      final y = (screen.height / 2 + o).round();
      final c = Ansi8BitColors.values[_hslTo256(f + t, 1, 0.5)];

      if (debug) {
        print('${string[i]}: ($x, $y) = ${c.name} from h=${f + t}');
      }

      screen.setCell(x + i, y, Cell(string[i]).withColor8(foreground: c));
    }

    if (!debug) {
      screen.update();
    }
  });
}

/// Returns the cooresponding 6x6x6 RGB cube color (i.e. 8-bit color palette).
///
/// This function ignores graycales and assumes color for simplicity.
int _rgbTo256(num r, num g, num b) {
  final r8 = r * 8 ~/ 256;
  final g8 = g * 8 ~/ 256;
  final b8 = b * 4 ~/ 256;
  return 16 + (r8 << 5) | (g8 << 2) | b8;
}

int _hslTo256(double h, double s, double l) {
  final rgb = HslColor(h, s * HslColor.sMax, l * HslColor.lMax).toRgbColor();
  return _rgbTo256(rgb.r, rgb.g, rgb.b);
}
