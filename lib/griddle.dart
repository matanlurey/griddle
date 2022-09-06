import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:neoansi/neoansi.dart';

export 'package:neoansi/neoansi.dart' show Ansi1BitColors, Ansi8BitColors;

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
        _terminal.resetStyles();
        _writeAnsiColorSequences(cell);
        _terminal.writeByte(cell.character);
      }

      _terminal.writeByte(0xa);
    }
  }

  void _writeAnsiColorSequences(Cell cell) {
    final foreground1BitColor = cell.foreground1BitColor;
    if (foreground1BitColor != null) {
      _terminal.setForegroundColor(foreground1BitColor);
    } else {
      final foreground8BitColor = cell.foreground8BitColor;
      if (foreground8BitColor != null) {
        _terminal.setForegroundColor8(foreground8BitColor);
      }
    }

    final background1BitColor = cell.background1BitColor;
    if (background1BitColor != null) {
      _terminal.setBackgroundColor(background1BitColor);
    } else {
      final background8BitColor = cell.background8BitColor;
      if (background8BitColor != null) {
        _terminal.setBackgroundColor8(background8BitColor);
      }
    }
  }
}

/// A two-dimensional cell, sometimes called a "pixel", within a screen.
///
/// A cell is a simple immutable value-type that is a combination of a:
/// - [character], which defaults to a space (`' '`).
/// - background color, either a [background1BitColor] or [background8BitColor].
/// - foreground color, either a [foreground1BitColor] or [foreground8BitColor].
@immutable
@sealed
class Cell {
  static const _$codeSpace = 0x20;

  /// Character code to be rendered in this cell.
  final int character;

  /// If provided, the 1-bit color used for styling the [character].
  ///
  /// If non-null, [foreground8BitColor] must be `null`.
  final Ansi1BitColors? foreground1BitColor;

  /// If provided, the 1-bit color used for styling the background.
  ///
  /// If non-null, [background8BitColor] must be `null`.
  final Ansi1BitColors? background1BitColor;

  /// If provided, the 8-bit color used for styling the [character].
  ///
  /// If non-null, [foreground1BitColor] must be `null`.
  final Ansi8BitColors? foreground8BitColor;

  /// If provided, the 8-bit color used for styling the background.
  ///
  /// If non-null, [background1BitColor] must be `null`.
  final Ansi8BitColors? background8BitColor;

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
  /// To add styling, use in conjunction with [withColor] or [withColor8], i.e.:
  /// ```
  /// Cell('X').withColor(background: Ansi1BitColors.red)
  /// ```
  factory Cell([String? character]) {
    if (character == null) {
      return const Cell._(_$codeSpace, null, null, null, null);
    }
    if (character.length != 1) {
      throw ArgumentError.value(
        character,
        'character',
        'Must be a string of exactly length 1, got ${character.length}',
      );
    }
    return Cell._(character.codeUnitAt(0), null, null, null, null);
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
  /// To add styling, use in conjunction with [withColor] or [withColor8], i.e.:
  /// ```
  /// Cell.ofCharacter(0x58).withColor(background: Ansi1BitColors.red)
  /// ```
  Cell.ofCharacter(int character)
      : this._(
          RangeError.checkNotNegative(character, 'character'),
          null,
          null,
          null,
          null,
        );

  const Cell._(
    this.character,
    this.foreground1BitColor,
    this.background1BitColor,
    this.foreground8BitColor,
    this.background8BitColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is Cell &&
          character == other.character &&
          foreground1BitColor == other.foreground1BitColor &&
          background1BitColor == other.background1BitColor &&
          foreground8BitColor == other.foreground8BitColor &&
          background8BitColor == other.background8BitColor;

  @override
  int get hashCode {
    return Object.hash(
      character,
      foreground1BitColor ?? background1BitColor,
      foreground8BitColor ?? background8BitColor,
    );
  }

  /// Returns the cell with 1-bit colors set.
  ///
  /// An implicit or explcit value of `null` defaults to the current color,
  /// assuming that 1-bit colors were previously used. Any set 8-bit colors are
  /// cleared by using this method.
  @useResult
  Cell withColor({
    Ansi1BitColors? foreground,
    Ansi1BitColors? background,
  }) {
    return Cell._(
      character,
      foreground ?? foreground1BitColor,
      background ?? background1BitColor,
      null,
      null,
    );
  }

  /// Returns the cell with 8-bit colors set.
  ///
  /// An implicit or explcit value of `null` defaults to the current color,
  /// assuming that 8-bit colors were previously used. Any set 1-bit colors are
  /// cleared by using this method.
  @useResult
  Cell withColor8({
    Ansi8BitColors? foreground,
    Ansi8BitColors? background,
  }) {
    return Cell._(
      character,
      null,
      null,
      foreground ?? foreground8BitColor,
      background ?? background8BitColor,
    );
  }

  /// Returns the cell with all colors cleared (reset to the default).
  @useResult
  Cell clearColors() => Cell._(character, null, null, null, null);

  @override
  String toString() {
    final foreground = foreground1BitColor ?? foreground8BitColor;
    final background = background1BitColor ?? background8BitColor;
    final character = String.fromCharCode(this.character);
    if (foreground == null && background == null) {
      return 'Cell <$character>';
    } else {
      return 'Cell <$character: f=${foreground?.name} b=${background?.name}>';
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

  /// Sets subequent text's 1-bit background color.
  void setBackgroundColor(Ansi1BitColors color, {bool bright = false});

  /// Sets subequent text's 8-bit background color.
  void setBackgroundColor8(Ansi8BitColors color);

  /// Sets subequent text's 1-bit foreground color.
  void setForegroundColor(Ansi1BitColors color, {bool bright = false});

  /// Sets subequent text's 8-bit foreground color.
  void setForegroundColor8(Ansi8BitColors color);
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
    // TODO: Determine if we need to split this into 3 methods.
    _ansiSink
      ..setCursorX(0)
      ..setCursorY(0)
      ..clearScreen();
  }

  @override
  void hideCursor() {
    // TODO: Use _ansiSink.hideCursor (https://github.com/neo-dart/neoansi/issues/2).
    _ansiSink.write('\u001b[?25l');
  }

  @override
  void showCursor() {
    // TODO: Use _ansiSink.showCursor (https://github.com/neo-dart/neoansi/issues/2).
    _ansiSink.write('\u001b[?25h');
  }

  @override
  void resetStyles() => _ansiSink.resetStyles();

  @override
  void setBackgroundColor(Ansi1BitColors color, {bool bright = false}) {
    _ansiSink.setBackgroundColor(color, bright: bright);
  }

  @override
  void setBackgroundColor8(Ansi8BitColors color) {
    _ansiSink.setBackgroundColor8(color);
  }

  @override
  void setForegroundColor(Ansi1BitColors color, {bool bright = false}) {
    _ansiSink.setForegroundColor(color, bright: bright);
  }

  @override
  void setForegroundColor8(Ansi8BitColors color) {
    _ansiSink.setForegroundColor8(color);
  }
}

/// A simple ANSI supported [Terminal] that uses [io.Stdin]/[io.Stdout].
class _StdioAnsiTerminal extends Terminal with AnsiTerminal {
  final io.Stdin _stdin;
  final io.Stdout _stdout;

  _StdioAnsiTerminal(this._stdin, this._stdout) : super.base();

  @override
  StringSink get outSink => _stdout;

  @override
  int readByte() => _stdin.readByteSync();

  @override
  int get width => _stdout.terminalColumns;

  @override
  int get height => _stdout.terminalLines;
}
