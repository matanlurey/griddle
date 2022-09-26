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
abstract class Screen implements WritableBuffer {
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
class _Screen extends _Buffer implements Screen {
  final Display _output;

  _Screen(this._output) : super(_output.width, _output.height);

  @override
  void update() {
    // If we more carefully tracked what was mutated since the last update,
    // we could technically avoid this step as well - however that would mean
    // the buffer would need to more complex.
    //
    // In practice, this optimization is likely not worth it, but YMMV.
    _output.clearScreen();
    const newLineChar = 0xa;

    // We assume that we start with no foreground or background colors.
    Color? foreground;
    Color? background;

    for (var i = 0; i < height; i++) {
      _output.writeByte(newLineChar);
      for (var j = 0; j < width; j++) {
        final cell = get(j, i);
        _writeStyles(
          cell,
          previousForeground: foreground,
          previousBackground: background,
        );
        foreground = cell.foregroundColor;
        background = cell.backgroundColor;
        _output.writeByte(cell.character);
      }
    }

    _output
      ..writeByte(newLineChar)
      ..flush();
  }

  void _writeStyles(
    Cell cell, {
    required Color? previousForeground,
    required Color? previousBackground,
  }) {
    var resetStyles = false;

    final foreground = cell.foregroundColor;
    if (foreground == null && previousForeground != null) {
      _output.resetStyles();
      resetStyles = true;
    }

    final background = cell.backgroundColor;
    if (!resetStyles && background == null && previousBackground != null) {
      _output.resetStyles();
    }

    if (foreground != null && foreground != previousForeground) {
      _output.setForegroundColor(foreground);
    }

    if (background != null && background != previousBackground) {
      _output.setBackgroundColor(background);
    }
  }
}
