part of '../griddle.dart';

/// A screen is the root building block in `griddle`, a 2D _grid_ of cells.
///
/// Screens are _stateful_, and provide a higher-level API to:
/// - Read and write characters and color effects to individual cells.
/// - Synchronize the state of the (internal) screen with an external surface.
///
/// There is only one provided way to create a screen:
/// - [Screen.output], which creates a screen that uses a low-level [RawScreen].
///
/// However, [Screen] exists as an abstraction: _extend_ and create your own!
@sealed
abstract class Screen implements Buffer {
  /// Creates a screen that interfaces with an external [screen].
  ///
  /// See [RawScreen.fromAnsiTerminal] and [RawScreen.fromStringBuffer].
  factory Screen.output(RawScreen screen) = _Screen;

  /// Given the current state of the buffer, updates an external surface.
  void update();
}

/// Simple implementation of [Screen] that delegates to a [RawScreen].
class _Screen extends Buffer implements Screen {
  final RawScreen _output;

  _Screen(this._output) : super(_output.width, _output.height);

  @override
  void update() {
    _output.clearScreen();

    for (var i = 0; i < height; i++) {
      _output.writeByte(0xa);
      for (var j = 0; j < width; j++) {
        final cell = get(j, i);
        _writeAnsiColorSequences(cell);
        _output.writeByte(cell.character);
      }
    }

    _output
      ..writeByte(0xa)
      ..flush();
  }

  void _writeAnsiColorSequences(Cell cell) {
    var wroteSequence = false;

    final foreground = cell.foregroundColor;
    if (foreground != null) {
      _output.setForegroundColor(foreground);
      wroteSequence = true;
    }

    final background = cell.backgroundColor;
    if (background != null) {
      _output.setBackgroundColor(background);
      wroteSequence = true;
    }

    if (!wroteSequence) {
      _output.resetStyles();
    }
  }
}
