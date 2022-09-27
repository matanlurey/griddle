// ignore_for_file: cascade_invocations

import 'package:griddle/griddle.dart';
import 'package:neoansi/neoansi.dart';
import 'package:test/test.dart';

void main() {
  const red = Color.fromRGB(0xFF, 0x00, 0x00);

  test('fromStringBuffer should provide a simple plain text "display"', () {
    final output = StringBuffer();

    // Create a display and set the color (which will be ignored).
    final display = Display.fromStringBuffer(output)
      ..setForegroundColor(red)
      ..setBackgroundColor(red)
      ..resetStyles();

    // Write every character to the "screen".
    'Hello World!'.codeUnits.forEach(display.writeByte);
    display.flush();

    // Reasonable terminal defaults.
    expect(display.width, 80);
    expect(display.height, 24);

    // Setting colors and resetting styles should have had no effect!
    expect(output.toString(), 'Hello World!');

    // Try "clearing" the screen and other non-effects.
    display.clearScreen();
    display.hideCursor();
    display.showCursor();
    expect(output.toString(), isEmpty);

    // Close
    display.close();
    expect(display.flush, throwsStateError);
  });

  group('fromAnsiTerminal provides a simple terminal "display" that', () {
    late StringBuffer output;
    late int width;
    late int height;

    late Display display;

    setUp(() {
      output = StringBuffer();
      width = 80;
      height = 24;

      display = Display.fromAnsiTerminal(
        output,
        width: () => width,
        height: () => height,
        hideCursor: false,
      );
    });

    test('hide/shows the cursor on start and close', () {
      display = Display.fromAnsiTerminal(
        output,
        width: () => width,
        height: () => height,
        hideCursor: true,
      );

      final capture = _SimpleAnsiListener();
      final reader = AnsiReader(capture);

      display.flush();
      reader.read('$output');
      expect(capture.wasHideCursor, isTrue);
      output.clear();

      display.close();
      reader.read('$output');
      expect(capture.wasShowCursor, isTrue);
    });

    test('should fail if closed', () {
      display.close();

      expect(display.flush, throwsStateError);
    });

    test('reports its height as height - 1', () {
      expect(
        display.height,
        23,
        reason: 'Avoids scrollback hiding the first line',
      );
    });

    test('should reflect latest width and height', () {
      width = 100;
      height = 40;

      expect(display.width, 100);
      expect(
        display.height,
        39,
        reason: 'Avoids scrollback hiding the first line',
      );
    });

    test('should write using ANSI escape codes', () {
      const blue = Color.fromRGB(0x00, 0x00, 0xFF);
      final capture = _SimpleAnsiListener();
      final reader = AnsiReader(capture);

      void resetCaptureState() {
        output.clear();
        capture.resetAssertions();
      }

      // Test A: Writing unstyled text is captured (without styles obviously).
      resetCaptureState();
      'Hello World!'.codeUnits.forEach(display.writeByte);
      display.flush();
      reader.read(output.toString());
      expect(output.toString(), 'Hello World!');
      expect(capture.wroteText, ['Hello World!']);
      expect(capture.backgroundColor24, isNull);
      expect(capture.foregroundColor24, isNull);
      expect(capture.wasClearScreen, isFalse);
      expect(capture.wasResetStyles, isFalse);

      // Test B: Only flushing outputs content to the "display".
      resetCaptureState();
      display.resetStyles();
      reader.read(output.toString());
      expect(output, isEmpty);
      expect(
        capture.wasResetStyles,
        isFalse,
        reason: 'Display not flushed',
      );

      // Test C: Reset styles is written upon flushing.
      resetCaptureState();
      display.flush();
      reader.read(output.toString());
      expect(output, isNotEmpty);
      expect(
        capture.wasResetStyles,
        isTrue,
        reason: 'Did not find escape in ${output.length} characters "$output"',
      );

      // Test D: Clear screen is written.
      resetCaptureState();
      display.clearScreen();
      display.flush();
      reader.read(output.toString());
      expect(capture.wasClearScreen, isTrue);

      // Test E: Colors are written.
      resetCaptureState();
      display.setBackgroundColor(red);
      display.setForegroundColor(blue);
      display.flush();
      reader.read(output.toString());
      expect(capture.backgroundColor24, red);
      expect(capture.foregroundColor24, blue);
    });
  });
}

class _SimpleAnsiListener extends AnsiListener {
  late bool wasClearScreen;
  late bool wasResetStyles;
  late Color? backgroundColor24;
  late Color? foregroundColor24;
  late List<String> wroteText;
  late bool wasHideCursor;
  late bool wasShowCursor;

  _SimpleAnsiListener() {
    resetAssertions();
  }

  void resetAssertions() {
    wasResetStyles = wasClearScreen = false;
    backgroundColor24 = foregroundColor24 = null;
    wroteText = [];
    wasHideCursor = wasShowCursor = false;
  }

  @override
  void write(String text) {
    wroteText.add(text);
  }

  @override
  void hideCursor() {
    wasHideCursor = true;
  }

  @override
  void showCursor() {
    wasShowCursor = true;
  }

  @override
  void clearScreen() {
    wasClearScreen = true;
  }

  @override
  void resetStyles() {
    wasResetStyles = true;
  }

  @override
  void setBackgroundColor24(Color color) {
    backgroundColor24 = color;
  }

  @override
  void setForegroundColor24(Color color) {
    foregroundColor24 = color;
  }
}
