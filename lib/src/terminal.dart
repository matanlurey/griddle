part of '../griddle.dart';

/// A terminal is an optional external "backend" API for use with a screen.
abstract class Terminal {
  /// Visible in order to allow `extends Terminal`.
  ///
  /// ```dart
  /// import 'package:griddle/griddle.dart';
  ///
  /// class MyTerminal extends Terminal {
  ///   MyTerminal() : super.base();
  ///
  ///   // Finish implementing Terminal API
  /// }
  /// ```
  ///
  /// Simpler implementations may benefit from using [AnsiTerminal].
  const Terminal.base();

  /// Creates a terminal that uses ANSI codes with [stdin] and [stdout].
  factory Terminal.usingAnsiStdio({io.Stdin? stdin, io.Stdout? stdout}) {
    return _StdioAnsiTerminal(stdin ?? io.stdin, stdout ?? io.stdout);
  }

  /// Returns the width of the terminal window in characters.
  int get width;

  /// Returns the height of the terminal window in characters.
  int get height;

  /// Flushes the output buffer, if any.
  void flush();

  /// Clears the entire output screen.
  void clearScreen();

  /// Hides the cursor.
  void hideCursor();

  /// Shows the cursor.
  void showCursor();

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

class _TerminalScreen extends Screen {
  final Terminal _terminal;

  _TerminalScreen(this._terminal)
      : super._baseNotYetReadyAsPublicApi(
          _terminal.width,
          _terminal.height,
        ) {
    _terminal.hideCursor();
  }

  @override
  void update() {
    // This is far from optimal, but gives us a reasonable starting point.
    _terminal.clearScreen();

    for (var i = 0; i < height; i++) {
      for (var j = 0; j < width; j++) {
        final cell = _cells[i][j];
        _writeAnsiColorSequences(cell);
        _terminal.writeByte(cell.character);
      }

      _terminal.writeByte(0xa);
    }

    _terminal.flush();
  }

  void _writeAnsiColorSequences(Cell cell) {
    var wroteSequence = false;

    final foreground = cell.foregroundColor;
    if (foreground != null) {
      _terminal.setForegroundColor(foreground);
      wroteSequence = true;
    }

    final background = cell.backgroundColor;
    if (background != null) {
      _terminal.setBackgroundColor(background);
      wroteSequence = true;
    }

    if (!wroteSequence) {
      _terminal.resetStyles();
    }
  }
}
