import 'package:griddle/griddle.dart';
import 'package:test/test.dart';

void main() {
  const red = Color.fromRGB(0xFF, 0x00, 0x00);

  test('should create a blank cell', () {
    expect(Cell(), same(Cell.blank));
  });

  test('should create a cell from the first character', () {
    expect(Cell('X'), Cell.ofCharacter('X'.codeUnitAt(0)));
  });

  test('should refuse a string of length >1', () {
    expect(() => Cell('XY'), throwsArgumentError);
  });

  test('should refuse an invalid character code', () {
    expect(() => Cell.ofCharacter(-1), throwsRangeError);
  });

  test('should implement == and hashCode', () {
    final a = Cell('a');
    final b = Cell('b');

    expect(a, isNot(b));
    expect(a, equals(a));
    expect(a.hashCode, Cell('a').hashCode);
  });

  test('should create a new cell with foreground color set', () {
    final cell = Cell('X').withColor(foreground: red);

    expect(cell.character, 'X'.codeUnitAt(0));
    expect(cell.foregroundColor, red);
    expect(cell.backgroundColor, isNull);
  });

  test('should create a new cell with foreground color retained', () {
    final cell = Cell('X').withColor(foreground: red).withColor();

    expect(cell.character, 'X'.codeUnitAt(0));
    expect(cell.foregroundColor, red);
    expect(cell.backgroundColor, isNull);
  });

  test('should create a new cell with background color set', () {
    final cell = Cell('X').withColor(background: red);

    expect(cell.character, 'X'.codeUnitAt(0));
    expect(cell.foregroundColor, isNull);
    expect(cell.backgroundColor, red);
  });

  test('should create a new cell with background color retained', () {
    final cell = Cell('X').withColor(background: red).withColor();

    expect(cell.character, 'X'.codeUnitAt(0));
    expect(cell.foregroundColor, isNull);
    expect(cell.backgroundColor, red);
  });

  test('should create a new cell with colors cleared', () {
    final cell = Cell('X').withColor(background: red).clearColors();

    expect(cell.character, 'X'.codeUnitAt(0));
    expect(cell.foregroundColor, isNull);
    expect(cell.backgroundColor, isNull);
  });

  test('should create a new cell with character set', () {
    final cell = Cell('X').withCharacter('Y'.codeUnitAt(0));

    expect(cell.character, 'Y'.codeUnitAt(0));
    expect(cell.foregroundColor, isNull);
    expect(cell.backgroundColor, isNull);
  });

  test('should create a new cell with character cleared', () {
    final cell = Cell('X').clearCharacter();

    expect(cell, Cell.blank);
  });

  test('should describe the cell as a string', () {
    expect(Cell('X').toString(), 'Cell <X>');
  });

  test('should describe a cell with 1 color as a string', () {
    expect(
      Cell('X').withColor(foreground: red).toString(),
      'Cell <X f=0xFF0000 b=<NONE>>',
    );

    expect(
      Cell('X').withColor(background: red).toString(),
      'Cell <X f=<NONE> b=0xFF0000>',
    );
  });

  test('should describe a cell with 2 colors as a string', () {
    const blue = Color.fromRGB(0x00, 0x00, 0xFF);

    expect(
      Cell('X').withColor(foreground: red, background: blue).toString(),
      'Cell <X f=0xFF0000 b=0x0000FF>',
    );
  });
}
