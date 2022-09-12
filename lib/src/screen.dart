part of '../griddle.dart';

/// A screen is the root building block in `griddle`, a 2D _grid_ of cells.
///
/// Screens are _stateful_, and provide a higher-level API to:
/// - Read and write characters and color effects to individual cells.
/// - Synchronize the state of the (internal) screen with an external surface.
///
/// There is only one provided way to create a screen:
/// - [Screen.terminal], which creates a screen that interfaces with a terminal.
///
/// However, [Screen] exists as an abstraction: _extend_ and create your own!
///
/// **NOTE**: In the future, the screen API will also support _input_ (events).
@sealed
abstract class Screen extends Buffer {
  final int _framesPerSecond;

  /// Creates a disconnected in-memory screen of initial [width] and [height].
  Screen(
    super.width,
    super.height, {
    int framesPerSecond = 30,
  }) : _framesPerSecond = RangeError.checkNotNegative(
          framesPerSecond,
          'framesPerSecond',
        );

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
  factory Screen.terminal(
    Terminal terminal, {
    int framesPerSecond,
  }) = _TerminalScreen;

  /// Given the current state of the buffer, updates an external surface.
  void update();

  /// A stream that fires every frame the screen could be updated.
  ///
  /// The event value provided ([Duration]) is the time elapsed since the last
  /// frame was emitted.
  @nonVirtual
  Stream<Duration> get onFrame {
    final stopwatch = Stopwatch()..start();
    final duration = Duration(milliseconds: 1000 ~/ _framesPerSecond);
    return Stream.periodic(duration, (_) {
      final time = stopwatch.elapsed;
      stopwatch.reset();
      return time;
    });
  }
}
