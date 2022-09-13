part of '../griddle.dart';

/// A display is an optional external "backend" API for use with a screen.
///
/// While not necessarily backed by an actual terminal (or terminal emulator),
/// a [Display] has the minimal amount of APIs needed in order to draw pixels
/// to a _terminal-like_ backend.
abstract class Display {
  /// Visible in order to allow `extends Display`.
  ///
  /// ```dart
  /// import 'package:griddle/griddle.dart';
  ///
  /// class MyDisplay extends Display {
  ///   // Finish implementing Display API
  /// }
  /// ```
  ///
  /// @nodoc
  const Display();

  /// Creates a display that writes ANSI escape codes to a string buffer.
  ///
  /// This screen is suitable for easy usage using `dart:io` and `stdout`:
  /// ```dart
  /// import 'dart:io' as io;
  ///
  /// void main() {
  ///   final display = Display.fromAnsiTerminal(
  ///     io.stdout,
  ///     width: () => io.stdout.terminalColumns,
  ///     height: () => io.stdout.terminalLines,
  ///   );
  /// }
  /// ```
  ///
  /// For a display without ANSI escapes, see [Display.fromStringBuffer].
  factory Display.fromAnsiTerminal(
    StringSink output, {
    required int Function() width,
    required int Function() height,
  }) = _AnsiTerminalDisplay;

  /// Creates a minimal display that writes plain text to a string buffer.
  ///
  /// All colors and styling are ignored and [width] and [height] default to
  /// a conservative (and hopefully continuous integration friendly)
  /// `80x24` (unless otherwise provided.)
  factory Display.fromStringBuffer(
    StringBuffer output, {
    int width,
    int height,
  }) = _UnstyledTextDisplay;

  /// Returns the width of the output display in characters.
  ///
  /// Screens may (but are not required to) poll this getter to check if the
  /// size of the display has chand (and to resize internal output buffers as
  /// necessary).
  @experimental
  int get width;

  /// Returns the height of the output display in characters.
  ///
  /// Screens may (but are not required to) poll this getter to check if the
  /// size of the display has chand (and to resize internal output buffers as
  /// necessary).
  @experimental
  int get height;

  /// Flushes the output buffer, if any.
  void flush();

  /// Clears the entire output display.
  void clearScreen();

  /// Resets all output styling applied.
  void resetStyles();

  /// Writes the provided [byte] as a character to the terminal output.
  void writeByte(int byte);

  /// Sets subequent text's 24-bit RGB background color.
  ///
  /// **NOTE**: The 8-bit alpha channel ([Color.alpha]) is ignored.
  void setBackgroundColor(Color color);

  /// Sets subequent text's 24-bit RGB foreground color.
  ///
  /// **NOTE**: The 8-bit alpha channel ([Color.alpha]) is ignored.
  void setForegroundColor(Color color);
}

/// A raw screen that supports writing to a [StringBuffer].
///
/// No colors or advanced formatting are supported in this implementation.
class _UnstyledTextDisplay extends Display {
  final StringBuffer _output;

  /// Temporarily holds output until [flush] is used to move it to [_output].
  final _bufferedOutput = StringBuffer();

  _UnstyledTextDisplay(
    this._output, {
    this.width = 80,
    this.height = 24,
  });

  @override
  void clearScreen() => _output.clear();

  @override
  void flush() {
    _output.write(_bufferedOutput);
    _bufferedOutput.clear();
  }

  @override
  final int width;

  @override
  final int height;

  @override
  void resetStyles() {}

  @override
  void setBackgroundColor(Color color) {}

  @override
  void setForegroundColor(Color color) {}

  @override
  void writeByte(int byte) => _output.writeCharCode(byte);
}

/// A raw screen that supports writing to an ANSI-escape supported terminal.
class _AnsiTerminalDisplay extends Display {
  final StringSink _output;
  final int Function() _width;
  final int Function() _height;

  /// Temporarily holds output until [flush] is used to move it to [_output].
  final _bufferedOutput = StringBuffer();
  late final _ansiOut = AnsiWriter.from(_bufferedOutput);

  _AnsiTerminalDisplay(
    this._output, {
    required int Function() width,
    required int Function() height,
  })  : _width = width,
        _height = height;

  @override
  void clearScreen() => _ansiOut.clearScreen();

  @override
  void flush() {
    _output.write(_bufferedOutput);
    _bufferedOutput.clear();
  }

  @override
  void writeByte(int byte) => _ansiOut.writeCharCode(byte);

  @override
  int get width => _width();

  @override
  int get height => _height();

  @override
  void resetStyles() => _ansiOut.resetStyles();

  @override
  void setBackgroundColor(Color color) => _ansiOut.setBackgroundColor24(color);

  @override
  void setForegroundColor(Color color) => _ansiOut.setForegroundColor24(color);
}
