import 'dart:io';

import 'package:griddle/griddle.dart';

/// A sample application that fills the entire terminal with coordinates.
void main() {
  final display = Display.fromAnsiTerminal(
    stdout,
    width: () => stdout.terminalColumns,
    height: () => stdout.terminalLines,
  );
  final screen = Screen.display(display);

  for (var y = 0; y < screen.height; y++) {
    screen.set(0, y, Cell('${y % 10}'));
  }
  for (var x = 0; x < screen.width; x++) {
    screen.set(x, 0, Cell('${x % 10}'));
  }

  screen.update();
  display.close();
}
