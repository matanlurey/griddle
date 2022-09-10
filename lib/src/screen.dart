part of '../griddle.dart';

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
