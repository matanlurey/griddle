part of '../griddle.dart';

/// Stores a mutable 2D buffer of cells.
///
/// A buffer maintains a two-dimensional buffer of [Cell] instances, and
/// provides methods of manipulating them programatically, such as [fill] and
/// [print], as well as direct "pixel" access using [get] and [set].
///
/// Virtual buffers are also suitable for _testing_, as well as maintaining a
/// platform independent stateful view that will later be synchronized to a
/// platform-specific view.
///
/// It is considered invalid to extend, implement, or mix-in this class.
@sealed
class Buffer {
  var _cells = const <Cell>[];
  var _width = 0;
  var _height = 0;

  /// Creates a new buffer by **copying** a predefined collections of [cells].
  ///
  /// Cells are considered to be filled from top-left to bottom-right.
  ///
  /// For example, a [width] of 2 would infer a height of 3 with 6 elements:
  /// ```txt
  /// (0, 0) (1, 0)
  /// (0, 1) (1, 1)
  /// (0, 2) (1, 2)
  /// ```
  ///
  /// **NOTE**: [width] must be able to evenly subdivide the length of [cells].
  factory Buffer.fromCells(
    Iterable<Cell> cells, {
    required int width,
  }) {
    if (cells.isEmpty) {
      throw ArgumentError.value(cells, 'cells', 'Must be non-empty');
    }
    if (width < 1) {
      throw ArgumentError.value(width, 'width', 'width must be >= 1');
    }
    final list = List.of(cells, growable: false);
    final divisions = list.length / width;
    final height = divisions.floor();
    if (divisions == height) {
      return Buffer._(list, width, height);
    } else {
      throw ArgumentError.value(
        width,
        'width',
        '${list.length} cells cannot be subdivided by $width ($divisions)',
      );
    }
  }

  /// Creates a new buffer by **copying** a nested list (2D matrix) of [cells].
  ///
  /// **NOTE**: The [List.length] of every nested list must be the same.
  factory Buffer.fromMatrix(List<List<Cell>> cells) {
    if (cells.isEmpty) {
      throw ArgumentError.value(cells, 'cells', 'Must be non-empty');
    }
    final height = cells.length;
    final width = cells.first.length;
    for (var i = 0; i < height; i++) {
      final row = cells[i];
      if (row.length != width) {
        throw ArgumentError.value(
          row.length,
          'row[$i].length',
          'Must be the same as row[0].length, which is $width',
        );
      }
    }
    return Buffer._(
      List.of(cells.expand((e) => e), growable: false),
      width,
      height,
    );
  }

  /// Creates a new buffer of the specified [width] and [height].
  ///
  /// Initial cells are filled in by [initialCell], dafaulting to [Cell.blank].
  Buffer(
    int width,
    int height, {
    Cell initialCell = Cell.blank,
  }) {
    resize(
      width: width,
      height: height,
      expand: initialCell,
    );
    // It should be impossible for the following to ever be hit, we only add
    // the message to make iterating on the buffer class internally easier or
    // if we create internal subtypes in the future.
    //
    // coverage:ignore-start
    assert(
      _cells.isNotEmpty,
      'Cells should represent a non-empty grid: $_cells',
    );
    // coverage:ignore-end
  }

  /// Creates a buffer assuming appropriate checks were already peformed.
  Buffer._(this._cells, this._width, this._height) {
    assert(() {
      _checkWidthAndHeight(width, height);
      return true;
    }(), 'Sanity check that this constructor is used properly');
  }

  void _checkWidthAndHeight(int width, int height) {
    if (width < 1) {
      throw ArgumentError.value(width, 'width', 'width must be >= 1');
    }
    if (height < 1) {
      throw ArgumentError.value(height, 'height', 'height must be >= 1');
    }
  }

  /// Resizes the buffer to given [width] and/or [height].
  ///
  /// Any omitted parameter defaults to the current [width] or [height].
  ///
  /// Any existing cells are retained, new ones are filled with [Cell.blank]
  /// unless [expand] is provided with another instance.
  ///
  /// See [clear] and [fill] for other ways to set cells in bulk.
  void resize({
    int? width,
    int? height,
    Cell expand = Cell.blank,
  }) {
    final oldWidth = this.width;
    final oldHeight = this.height;

    width ??= oldWidth;
    height ??= oldHeight;
    _checkWidthAndHeight(width, height);

    if (width == oldWidth && height == oldHeight) {
      return;
    }

    // Create new cells, or cells to be soon replaced with existing cells.
    final newCells = List.filled(width * height, expand);

    // Move cells from the previous cells to the new cells.
    for (var y = 0; y < oldHeight; y++) {
      for (var x = 0; x < oldWidth; x++) {
        if (y >= height || x >= width) {
          continue;
        }
        newCells[y * width + x] = _cells[y * oldWidth + x];
      }
    }

    _width = width;
    _height = height;
    _cells = newCells;
  }

  /// Width of the buffer.
  int get width => _width;

  /// Height of the buffer.
  int get height => _height;

  /// Total number of cells in the buffer.
  ///
  /// Semantically identical to `buffer.width * buffer.height`.
  int get length => width * height;

  /// Returns whetyher [x] and [y] are considered within bounds of the buffer.
  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  /// Converts [x] and [y] to an index within [_cells].
  ///
  /// If either [x] or [y] are out of bounds an error is thrown.
  int _toIndexChecked(int x, int y) {
    RangeError.checkValueInInterval(x, 0, width - 1, 'x');
    RangeError.checkValueInInterval(y, 0, height - 1, 'y');
    return y * width + x;
  }

  /// Returns the cell located at ([x], [y]).
  Cell get(int x, int y) => _cells[_toIndexChecked(x, y)];

  /// Sets the cell located at ([x], [y]) to [value].
  void set(int x, int y, Cell value) {
    _cells[_toIndexChecked(x, y)] = value;
  }

  /// Returns the cell located at the specified [index].
  ///
  /// See [toList] for how to determine index given an `x`, `y`, or use [get].
  Cell operator [](int index) => _cells[index];

  /// Sets the cell located at the specified [index] to [cell].
  ///
  /// See [toList] for how to determine index given an `x`, `y`, or use [set].
  void operator []=(int index, Cell cell) {
    _cells[index] = cell;
  }

  /// Fills a rectangular region of the screen with the given attributes.
  ///
  /// If an attribute value is not specified (or set to `null`), then that
  /// attribute is left unchanged when filling cells.
  ///
  /// Any part of the rectangle that lies outside of the buffer is ignored.
  void fill({
    required int x,
    required int y,
    required int width,
    required int height,
    int? character,
    Color? foreground,
    Color? background,
  }) {
    RangeError.checkNotNegative(x, 'x');
    RangeError.checkNotNegative(y, 'y');
    RangeError.checkNotNegative(width, 'width');
    RangeError.checkNotNegative(height, 'height');
    for (var i = x; i < x + width; i++) {
      for (var j = y; j < y + height; j++) {
        if (!inBounds(i, j)) {
          continue;
        }
        var cell = get(i, j).withColor(
          foreground: foreground,
          background: background,
        );
        if (character != null) {
          cell = cell.withCharacter(character);
        }
        set(i, j, cell);
      }
    }
  }

  /// Fills the entire screen buffer with the attributes of the given [cell].
  void clear([Cell cell = Cell.blank]) {
    for (var i = 0; i < height; i++) {
      for (var j = 0; j < width; j++) {
        set(j, i, cell);
      }
    }
  }

  /// Sets character representing [text] to a particular location.
  ///
  /// Characters that would fall out of bounds of the buffer are ignored.
  void print(
    String text,
    int x,
    int y, {
    Color? foreground,
    Color? background,
  }) {
    if (text.isEmpty) {
      return;
    }
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      for (var n = 0; n < l.length; n++) {
        if (x + n < 0 || x + n >= width || y + i < 0 || y + i >= height) {
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

  /// Returns the buffer as a list of cells.
  ///
  /// This method can be considered the _opposite_ of [Buffer.fromCells].
  ///
  /// Cells are mapped where:
  /// ```
  /// final cells = buffer.toList();
  ///
  /// // Reads (x, y) from the list.
  /// final index = y * width + x;
  /// cells[index];
  /// ```
  List<Cell> toList() => List.of(_cells);

  /// Returns the buffer as a nested list (2D matrix) of cells.
  ///
  /// This method can be considered the _opposite_ of [Buffer.fromMatrix].
  List<List<Cell>> toMatrix() {
    return [
      for (var y = 0; y < height; y++)
        [for (var x = 0; x < width; x++) _cells[y * width + x]]
    ];
  }

  /// Returns a plain-text preview of the underlying buffer.
  ///
  /// For typical usage see [Screen.display] and [Display.fromStringBuffer].
  String toDebugString() {
    final buffer = StringBuffer();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer.writeCharCode(_cells[y * width + x].character);
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
