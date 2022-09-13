part of '../griddle.dart';

/// A screen is the root building block in `griddle`, a 2D _grid_ of cells.
///
/// Screens are _stateful_, and provide a higher-level API to:
/// - Read and write characters and color effects to individual cells.
/// - Synchronize the state of the screen buffer with an external display.
///
/// There is only one provided way to create a screen:
/// - [Screen.display], which creates a screen that uses a low-level [Display].
///
/// However, [Screen] exists as an abstraction: _extend_ and create your own!
@sealed
abstract class Screen implements Buffer {
  /// Creates a screen that interfaces with an external [screen].
  ///
  /// See [Display.fromAnsiTerminal] and [Display.fromStringBuffer].
  factory Screen.display(Display screen) = _Screen;

  /// Given the current state of the screen buffer, updates an external surface.
  ///
  /// How this implemented might vary, but a typical control may look like:
  /// ```dart
  /// @override
  /// void update() {
  ///   _clearScreen();
  ///   _forEachCellUpdateScreen();
  ///   _flushScreenBufferIfAny();
  /// }
  /// ```
  void update();
}

/// Simple implementation of [Screen] that delegates to a [Display].
class _Screen extends Buffer implements Screen {
  final Display _output;

  _Screen(this._output) : super(_output.width, _output.height);

  @override
  void update() {
    _output.clearScreen();

    for (var i = 0; i < height; i++) {
      _output.writeByte(0xa);
      for (var j = 0; j < width; j++) {
        final cell = get(j, i);
        _writeStyles(cell);
        _output.writeByte(cell.character);
      }
    }

    _output
      ..writeByte(0xa)
      ..flush();
  }

  void _writeStyles(Cell cell) {
    var styled = false;

    final foreground = cell.foregroundColor;
    if (foreground != null) {
      _output.setForegroundColor(foreground);
      styled = true;
    }

    final background = cell.backgroundColor;
    if (background != null) {
      _output.setBackgroundColor(background);
      styled = true;
    }

    if (!styled) {
      _output.resetStyles();
    }
  }
}
