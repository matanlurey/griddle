part of '../griddle.dart';

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
