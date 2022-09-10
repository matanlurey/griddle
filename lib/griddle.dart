import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:neoansi/neoansi.dart';
import 'package:neocolor/neocolor.dart';

export 'package:neocolor/neocolor.dart' show Color;

/// A screen is the root building block in `griddle`, a 2D _grid_ of cells.
///
/// Screens are _stateful_, and provide a higher-level API to:
/// - Read and write characters and color effects to individual cells.
/// - Synchronize the state of the (internal) screen with an external terminal.
///
/// There are two provided ways to create a screen:
/// - [Screen], which creates a disconnected in-memory virtual screen.
/// - [Screen.terminal], which creates a screen that interfaces with a terminal.
///
/// However, [Screen] exists as an abstraction: _extend_ and create your own!
///
/// **NOTE**: In the future, the screen API will also support _input_ (events).
@sealed
abstract class Screen {
  /// Visible in order to allow `extends Screen`.
  ///
  /// ```dart
  /// import 'package:griddle/griddle.dart';
  ///
  /// class MyScreen extends Screen {
  ///   MyScreen() : super.base();
  ///
  ///   // Finish implementing Screen API
  /// }
  /// ```
  Screen._baseNotYetReadyAsPublicApi(int width, int height)
      : _cells = List.generate(
          height,
          (_) => List.filled(width, Cell()),
        );

  /// Creates a disconnected in-memory screen of initial [width] and [height].
  ///
  /// Virtual screens are internally used for _buffering_, and are also suitable
  /// for _testing_, as well as maintaining a platform independent stateful view
  /// that will later be synchronized to a platform-specific view.
  factory Screen(int width, int height) {
    RangeError.checkNotNegative(width);
    RangeError.checkNotNegative(height);
    throw UnimplementedError();
  }

  /// Creates a screen that interfaces with an external [terminal].
  ///
  /// The simplest possible "real" terminal is [Terminal.usingStdio]:
  /// ```dart
  /// void main() {
  ///   final screen = Screen.terminal(Terminal.usingStdio());
  ///
  ///   // Use the 'screen' attached to stdin and stdout.
  /// }
  /// ```
  ///
  /// The width and height of the screen are determined by the terminal.
  factory Screen.terminal(Terminal terminal) = _TerminalScreen;

  /// Buffered cells for the screen.
  final List<List<Cell>> _cells;

  /// Clears all cells back to the default (empty) state.
  void clear() {
    for (var i = 0; i < height; i++) {
      _cells[i] = List.filled(width, Cell());
    }
  }

  /// Sets characters representing [text] to a particular location.
  void print(
    String text,
    int x,
    int y, {
    Color? foreground,
    Color? background,
  }) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      for (var n = 0; n < l.length; n++) {
        if (x + n >= width || y + i >= height) {
          continue;
        }
        setCell(
          x + n,
          y + i,
          Cell(l[n]).withColor(foreground: foreground, background: background),
        );
      }
    }
  }

  /// Returns the cell at the provided [x] and [y] coordinates.
  @nonVirtual
  @useResult
  Cell getCell(int x, int y) => _cells[y][x];

  /// Sets the cell at the provided [x] and [y] coordinates to [cell].
  @nonVirtual
  void setCell(int x, int y, Cell cell) {
    _cells[y][x] = cell;
  }

  /// Updates the cell at the provided [x] and [y] coordinates with [update].
  @nonVirtual
  void updateCell(int x, int y, Cell Function(Cell) update) {
    setCell(x, y, update(getCell(x, y)));
  }

  /// Override to provide a way to update cells.
  void update();

  /// Width of the screen.
  @nonVirtual
  int get width => _cells[0].length;

  /// Height of the screen.
  @nonVirtual
  int get height => _cells.length;

  /// A stream that fires every frame the screen could be updated.
  ///
  /// The event value provided ([Duration]) is the time elapsed since the last
  /// frame was emitted.
  @nonVirtual
  Stream<Duration> get onFrame {
    final stopwatch = Stopwatch()..start();
    return Stream.periodic(const Duration(milliseconds: 1000 ~/ 30), (_) {
      final time = stopwatch.elapsed;
      stopwatch.reset();
      return time;
    });
  }
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

/// A two-dimensional cell, sometimes called a "pixel", within a screen.
///
/// A cell is a simple immutable value-type that is a combination of a:
/// - [character], which defaults to a space (`' '`).
/// - [foregroundColor]
/// - [backgroundColor]
@immutable
@sealed
class Cell {
  static const _$codeSpace = 0x20;

  /// Character code to be rendered in this cell.
  final int character;

  /// If provided, the 24-bit RGB color  used for styling the [character].
  final Color? foregroundColor;

  /// If provided, the 24-bit RGB color used for styling the background.
  final Color? backgroundColor;

  /// Creates a cell that will render the provided [character] string.
  ///
  /// ```dart
  /// // Just a space
  /// Cell()
  ///
  /// // Any character
  /// Cell('X')
  /// ```
  ///
  /// If a string is not provided, defaults to a space (`' '`).
  ///
  /// To add styling, use in conjunction with [withColor], i.e.:
  /// ```
  /// Cell('X').withColor(background: Color.fromRGB(0xFF, 0x00, 0x00))
  /// ```
  factory Cell([String? character]) {
    if (character == null) {
      return const Cell._(_$codeSpace, null, null);
    }
    if (character.length != 1) {
      throw ArgumentError.value(
        character,
        'character',
        'Must be a string of exactly length 1, got ${character.length}',
      );
    }
    return Cell._(character.codeUnitAt(0), null, null);
  }

  /// Creates a cell that will render the provided [character] code.
  ///
  /// ```dart
  /// // Just as an example, prefer Cell('X') for this use
  /// Cell.ofCharacter('X'.codeUnitAt(0))
  ///
  /// // Strongly preferred (hex-code for 'X' in code units)
  /// Cell.ofCharacter(0x58)
  /// ```
  ///
  /// To add styling, use in conjunction with [withColor], i.e.:
  /// ```
  /// Cell.ofCharacter(0x58).withColor(background: Color.fromRGB(0xFF, 0x00, 0x00))
  /// ```
  Cell.ofCharacter(int character)
      : this._(
          RangeError.checkNotNegative(character, 'character'),
          null,
          null,
        );

  const Cell._(
    this.character,
    this.foregroundColor,
    this.backgroundColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is Cell &&
          character == other.character &&
          foregroundColor == other.foregroundColor &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode {
    return Object.hash(
      character,
      foregroundColor,
      backgroundColor,
    );
  }

  /// Returns the cell with 1-bit colors set.
  ///
  /// An implicit or explcit value of `null` defaults to the current color.
  @useResult
  Cell withColor({
    Color? foreground,
    Color? background,
  }) {
    return Cell._(
      character,
      foreground ?? foregroundColor,
      background ?? backgroundColor,
    );
  }

  /// Returns the cell with all colors cleared (reset to the default).
  @useResult
  Cell clearColors() => Cell._(character, null, null);

  @override
  String toString() {
    final foreground = foregroundColor;
    final background = backgroundColor;
    final character = String.fromCharCode(this.character);
    if (foreground == null && background == null) {
      return 'Cell <$character>';
    } else {
      return 'Cell <$character: f=$foreground b=$background>';
    }
  }
}

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

/// A mix-in that implements most of [Terminal] with ANSI escape sequences.
///
/// To implement an ANSI terminal, use:
/// ```dart///
/// class MyTerminal extends Terminal with AnsiTerminal {
///   MyTerminal() : super.base();
///
///   @override
///   StringSink get outSink => /* ... tip: Stdout implements StringkSink */
///
///   @override
///   int readByte() => /* ... */
///
///   @override
///   void write(Object object) => /* ... */
///
///   @override
///   int get width => /* ... */
///
///   @override
///   int get height => /* ... */
/// }
/// ```
///
/// ... and implement:
///
/// - [outSink]
/// - [readByte]
/// - [width]
/// - [height]
mixin AnsiTerminal on Terminal {
  /// Sink represneting output into the terminal, often [io.stdout].
  @protected
  StringSink get outSink;

  /// Synchronously reads a byte from stdin.
  ///
  /// This call will block until a byte is available.
  ///
  /// If at end of file, -1 is returned.
  @protected
  int readByte();

  /// Writes the character represented by [byte] to stdout.
  @override
  @protected
  void writeByte(int byte) => outSink.writeCharCode(byte);

  /// Hidden cached instance of [AnsiSink] used for most commands.
  late final AnsiSink _ansiSink = AnsiSink.from(outSink);

  @override
  void clearScreen() {
    _ansiSink.clearScreen();
  }

  @override
  void hideCursor() => _ansiSink.hideCursor();

  @override
  void showCursor() => _ansiSink.showCursor();

  @override
  void resetStyles() => _ansiSink.resetStyles();

  @override
  void setBackgroundColor(Color color) => _ansiSink.setBackgroundColor24(color);

  @override
  void setForegroundColor(Color color) => _ansiSink.setForegroundColor24(color);
}

/// A simple ANSI supported [Terminal] that uses [io.Stdin]/[io.Stdout].
class _StdioAnsiTerminal extends Terminal with AnsiTerminal {
  final io.Stdin _stdin;
  final io.Stdout _stdout;

  _StdioAnsiTerminal(this._stdin, this._stdout) : super.base();

  @override
  final StringBuffer outSink = StringBuffer();

  @override
  void flush() {
    _stdout.write(outSink);
    outSink.clear();
    _stdout.flush();
  }

  @override
  int readByte() => _stdin.readByteSync();

  @override
  int get width => _stdout.terminalColumns;

  @override
  int get height => _stdout.terminalLines;
}
