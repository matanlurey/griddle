import 'dart:io' show stdout;
import 'dart:math' show Random;

import 'package:griddle/griddle.dart';
import 'package:neoargs/neoargs.dart';

/// Runs a simulation of "Conway's Game of Life".
///
/// See: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life.
///
/// To provide a seed:
/// ```sh
/// dart example/game_of_life.dart --seed 1234567890
/// ```
///
/// To visually debug with a 10x slower framerate:
/// ```sh
/// dart example/game_of_life.dart --debug
/// ```
void main(List<String> argv) {
  final args = StringArgs.parse(argv);

  final debug = args.getOption('debug').wasPresent;
  final seed = args.getOption('seed').optionalOnce() ?? '';

  _GameOfLife(
    Screen.output(
      RawScreen.fromAnsiTerminal(
        stdout,
        width: () => stdout.terminalColumns,
        height: () => stdout.terminalLines,
      ),
    ),
    random: Random(int.tryParse(seed)),
    debugShowNeighborCount: debug,
    framesPerSecond: debug ? 1 : 10,
  ).run();
}

class _GameOfLife {
  static const _black = Color(0xFF000000);
  static const _red = Color(0xFFFF0000);
  static const _green = Color(0xFF00FF00);
  static const _blue = Color(0xFF0000FF);

  static final _empty = _life.clearCharacter();

  static final _life = Cell('\u2588').withColor(
    background: _black,
    foreground: _blue,
  );

  final Screen _screen;

  /// Whether to indicate why cells are growing or living visually.
  final bool _debugShowNeighborCount;

  /// How many frames to render per second.
  final int _framesPerSecond;

  /// A value of `true` indicates a cell, and `false` is empty.
  final List<bool> _living;

  /// Temporary state used before updating [_living].
  final List<bool> _growing;

  _GameOfLife(
    this._screen, {
    required int framesPerSecond,
    required Random random,
    bool debugShowNeighborCount = false,
  })  : _living = List.generate(_screen.length, (_) => random.nextBool()),
        _growing = List.filled(_screen.length, false),
        _debugShowNeighborCount = debugShowNeighborCount,
        _framesPerSecond = framesPerSecond;

  int get _rows => _screen.height;

  int get _columns => _screen.width;

  void run() async {
    final frames = Duration(milliseconds: 1000 ~/ _framesPerSecond);

    // ignore: no_leading_underscores_for_local_identifiers
    await for (final _ in Stream<void>.periodic(frames)) {
      _drawState();
      _updateState();
    }
  }

  /// Given the provided [x], [y], returns how many neighbors are living.
  ///
  /// ```
  /// 012
  /// 3█4
  /// 567
  /// ```
  int _liveNeighborsOf(int x, int y) {
    const neighbors = [
      // TOP LEFT
      [-1, -1],

      // TOP CENTER
      [00, -1],

      // TOP RIGHT
      [01, -1],

      // CENTER LEFT
      [-1, 00],

      // CENTER RIGHT
      [01, 00],

      // BOTTOM LEFT
      [-1, 01],

      // BOTTOM CENTER
      [00, 01],

      // BOTTOM RIGHT
      [01, 01],
    ];

    var sum = 0;
    for (final offset in neighbors) {
      final offsetX = offset[0];
      final checkX = x + offsetX;
      if (checkX < 0 || checkX >= _columns) {
        continue;
      }

      final offsetY = offset[1];
      final checkY = y + offsetY;
      if (checkY < 0 || checkY >= _rows) {
        continue;
      }

      sum += _living[checkY * _columns + checkX] ? 1 : 0;
    }
    return sum;
  }

  /// Updates the state of the cells with the following rules:
  ///
  /// 1. Any live cell with fewer than two neighbors dies (underpopulation).
  /// 2. Any live cell with 2-3 neighbors lives on to the next generation.
  /// 3. Any live cell with more than three neighbors dies (overpopulaton).
  /// 4. Any dead cell with exactly three neighbors is born (reproduction).
  void _updateState() {
    for (var y = 0; y < _rows; y++) {
      for (var x = 0; x < _columns; x++) {
        final n = _liveNeighborsOf(x, y);
        final i = y * _columns + x;

        var live = _living[i];
        if (n == 3) {
          live = true;
        } else if (n != 2) {
          live = false;
        }
        _growing[i] = live;
      }
    }
    _living.setAll(0, _growing);
  }

  /// Syncs the cell state to the screen.
  void _drawState() {
    _screen.update();

    for (var y = 0; y < _rows; y++) {
      for (var x = 0; x < _columns; x++) {
        final i = y * _columns + x;

        final Cell cell;

        if (_debugShowNeighborCount) {
          final n = _liveNeighborsOf(x, y).toRadixString(16).toUpperCase();
          cell = Cell(n).withColor(foreground: _living[i] ? _green : _red);
        } else {
          cell = _living[i] ? _life : _empty;
        }

        _screen.set(x, y, cell);
      }
    }
  }
}
