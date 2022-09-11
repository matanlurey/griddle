part of '../griddle.dart';

/// Stores a 2D buffer of cells.
///
/// A buffer maintains a two-dimensional buffer of [Cell] instances, and
/// provides methods of manipulating them programatically, such as [fill] and
/// [print], as well as direct "pixel" access using [get] and [set].
class Buffer {
  var _cells = const <Cell>[];
  var _width = 0;
  var _height = 0;

  /// Creates a new buffer of the specified width and height.
  Buffer(this._width, this._height) {
    resize(_width, _height);
  }

  /// Resizes the buffer to given [width] and [height].
  ///
  /// Any existing cells are retained, new ones are filled with [Cell.blank].
  @nonVirtual
  void resize(int width, int height) {
    RangeError.checkNotNegative(width);
    RangeError.checkNotNegative(height);

    final previous = _cells;
    final newLength = width * height;
    final newCells = List.filled(newLength, Cell.blank);

    final copyUntil = math.min(previous.length, newLength);

    for (var i = 0; i < copyUntil; i++) {
      newCells[i] = previous[i];
    }

    _width = width;
    _height = height;
    _cells = newCells;
  }

  /// Width of the buffer.
  @nonVirtual
  int get width => _width;

  /// Height of the buffer.
  @nonVirtual
  int get height => _height;

  /// Returns whetyher [x] and [y] are considered within bounds of the buffer.
  @nonVirtual
  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  /// Converts [x] and [y] to an index within [_cells].
  ///
  /// If either [x] or [y] are out of bounds an error is thrown.
  int _toIndexChecked(int x, int y) {
    RangeError.checkValueInInterval(x, 0, width, 'x');
    RangeError.checkValueInInterval(y, 0, height, 'y');
    return x * height + y;
  }

  /// Returns the cell located at ([x], [y]).
  @nonVirtual
  Cell get(int x, int y) => _cells[_toIndexChecked(x, y)];

  /// Sets the cell located at ([x], [y]) to [value].
  @nonVirtual
  void set(int x, int y, Cell value) => _cells[_toIndexChecked(x, y)] = value;

  /// Fills a rectangular region of the screen with the given attributes.
  ///
  /// If an attribute value is not specified (or set to `null`), then that
  /// attribute is left unchanged when filling cells.
  ///
  /// Any part of the rectangle that lies outside of the buffer is ignored.
  @nonVirtual
  void fill(
    int x,
    int y,
    int width,
    int height, {
    int? character,
    Color? foregorund,
    Color? background,
  }) {
    for (var i = x; i < x + width; i++) {
      for (var j = y; j < y + height; j++) {
        if (!inBounds(x, y)) {
          continue;
        }
        var cell = get(x, y).withColor(
          foreground: foregorund,
          background: background,
        );
        if (character != null) {
          cell = cell.withCharacter(character);
        }
        set(x, y, cell);
      }
    }
  }

  /// Fills the entire screen buffer with the attributes of the given [cell].
  @nonVirtual
  void clear([Cell cell = Cell.blank]) {
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        set(i, j, cell);
      }
    }
  }

  /// Sets character representing [text] to a particular location.
  ///
  /// Characters that would fall out of bounds of the buffer are ignored.
  @nonVirtual
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
        set(
          x + n,
          y + i,
          Cell(l[n]).withColor(foreground: foreground, background: background),
        );
      }
    }
  }
}
