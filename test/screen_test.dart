// ignore_for_file: cascade_invocations

import 'package:griddle/griddle.dart';
import 'package:test/test.dart';

void main() {
  test('Screen.display should update a display', () {
    const blue = Color.fromRGB(0x00, 0x00, 0xFF);
    const green = Color.fromRGB(0x00, 0xFF, 0x00);
    final output = StringBuffer();
    final screen = Screen.display(
      Display.fromAnsiTerminal(
        output,
        width: () => 5,
        height: () => 4,
        hideCursor: false,
      ),
    );

    // Print a message on the second line.
    screen.print('HELLO', 0, 1);
    screen.update();

    // Check readable message.
    expect(
      screen.toDebugString(),
      '     \n'
      'HELLO\n'
      '     \n',
    );

    // Check encoded details.
    expect(
      output.toString(),
      '\x1B[2J\n'
      '     \n'
      'HELLO\n'
      '     \n',
    );

    // Clear capture buffer.
    output.clear();

    // Print a styled message on the third line.
    screen.print('GREEN', 0, 2, foreground: green, background: blue);
    screen.update();

    // Check readable message.
    expect(
      screen.toDebugString(),
      '     \n'
      'HELLO\n'
      'GREEN\n',
    );

    // Check encoded details.
    expect(
      output.toString(),
      '\x1B[2J\n'
      '     \n'
      'HELLO\n'
      '\x1B[38;2;0;255;0m\x1B[48;2;0;0;255mGREEN\n',
    );
  });

  test('Screen.display should reset (foreground) styles when necessary', () {
    const blue = Color.fromRGB(0x00, 0x00, 0xFF);
    final output = StringBuffer();
    final screen = Screen.display(
      Display.fromAnsiTerminal(
        output,
        width: () => 5,
        height: () => 3,
        hideCursor: false,
      ),
    );

    // Print a message on the first and second lines.
    screen.print('HELLO', 0, 0, foreground: blue);
    screen.print('WORLD', 0, 1);
    screen.update();

    // Check encoded details.
    expect(
      output.toString(),
      '\x1B[2J\n'
      '\x1B[38;2;0;0;255mHELLO\n'
      '\x1B[0mWORLD\n',
    );
  });

  test('Screen.display should reset (background) styles when necessary', () {
    const blue = Color.fromRGB(0x00, 0x00, 0xFF);
    final output = StringBuffer();
    final screen = Screen.display(
      Display.fromAnsiTerminal(
        output,
        width: () => 5,
        height: () => 3,
        hideCursor: false,
      ),
    );

    // Print a message on the first and second lines.
    screen.print('HELLO', 0, 0, background: blue);
    screen.print('WORLD', 0, 1);
    screen.update();

    // Check encoded details.
    expect(
      output.toString(),
      '\x1B[2J\n'
      '\x1B[48;2;0;0;255mHELLO\n'
      '\x1B[0mWORLD\n',
    );
  });
}
