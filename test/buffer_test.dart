// ignore_for_file: cascade_invocations, prefer_const_constructors

import 'package:griddle/griddle.dart';
import 'package:test/test.dart';

void main() {
  group('Buffer', () {
    test('should create a 1x1 buffer', () {
      final buffer = Buffer(1, 1);

      expect(buffer.length, 1);
    });

    test('should create a 2x2 buffer', () {
      final buffer = Buffer(2, 2);

      expect(buffer.length, 4);
    });

    test('should create a 3x4 buffer', () {
      final buffer = Buffer(3, 4);

      expect(buffer.length, 12);
    });

    test('should map (x, y) as expected', () {
      // 00 01 02
      // 03 04 05
      // 06 07 08
      // 09 10 11

      const width = 3;
      const height = 4;
      final buffer = WritableBuffer(width, height);

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          buffer.set(x, y, Cell(i.toRadixString(16)));
        }
      }

      expect(
        buffer.toDebugString(),
        '012\n'
        '345\n'
        '678\n'
        '9ab\n',
      );
    });

    group('fromCells', () {
      test('should fail with an empty collection', () {
        expect(() => Buffer.fromCells([], width: 1), throwsArgumentError);
      });

      test('should fail with a width < 1', () {
        expect(() => Buffer.fromCells([Cell()], width: 0), throwsArgumentError);
      });

      test('should fail if collection is not subdividable by width', () {
        expect(
          () => Buffer.fromCells([Cell(), Cell()], width: 3),
          throwsArgumentError,
        );
      });

      test('should create a 2x2 buffer from the underlying cells', () {
        final cells = [Cell(), Cell(), Cell(), Cell()];
        final buffer = Buffer.fromCells(cells, width: 2);

        // Should have been copied and clearing has no impact.
        cells.clear();
        expect(
          buffer.toDebugString(),
          '  \n'
          '  \n',
        );
      });
    });

    group('fromMatrix', () {
      test('should fail with an empty matrix', () {
        expect(() => Buffer.fromMatrix([]), throwsArgumentError);
      });

      test('should fail with inconsistent nested lists', () {
        expect(
          () => Buffer.fromMatrix([
            [Cell(), Cell()],
            [Cell()]
          ]),
          throwsArgumentError,
        );
      });

      test('should create a 2x2 buffer from the underlying cells', () {
        final cells = [
          [Cell(), Cell()],
          [Cell(), Cell()]
        ];
        final buffer = Buffer.fromMatrix(cells);

        // Should have been copied and clearing has no impact.
        cells.clear();
        expect(
          buffer.toDebugString(),
          '  \n'
          '  \n',
        );
      });
    });

    group('resize', () {
      late WritableBuffer buffer;
      final x = Cell('X');

      // X X X
      // X X X
      // X X X
      setUp(() {
        buffer = WritableBuffer(3, 3, initialCell: x);
      });

      test('should have no effect if neither width or height changes', () {
        buffer.resize();

        expect(buffer.width, 3);
        expect(buffer.height, 3);
        expect(buffer.length, 9);
        expect(buffer.toList(), everyElement(x));
      });

      test('should prohibit shrinking width or height below 1', () {
        expect(() => buffer.resize(width: 0), throwsArgumentError);
        expect(() => buffer.resize(height: 0), throwsArgumentError);
      });

      test('should delete right-most cells if the width shrinks', () {
        buffer.resize(width: 2);

        expect(buffer.width, 2);
        expect(buffer.height, 3);
        expect(buffer.length, 6);
        expect(buffer.toList(), everyElement(x));
      });

      test('should delete bottom-most cells if the height shrinks', () {
        buffer.resize(height: 2);

        expect(buffer.width, 3);
        expect(buffer.height, 2);
        expect(buffer.length, 6);
        expect(buffer.toList(), everyElement(x));
      });

      test('should add right-most blank cells if the width expands', () {
        buffer.resize(width: 4);

        expect(buffer.width, 4);
        expect(buffer.height, 3);
        expect(buffer.length, 12);

        expect(buffer.toList().where((c) => c == x), hasLength(9));
        expect([
          for (int i = 0; i < 3; i++) buffer.get(3, i)
        ], [
          // (3, 0)
          Cell.blank,
          // (3, 1)
          Cell.blank,
          // (3, 2)
          Cell.blank,
        ]);
      });

      test('should add bottom-most blank cells if the height expands', () {
        buffer.resize(height: 4);

        expect(buffer.width, 3);
        expect(buffer.height, 4);
        expect(buffer.length, 12);

        expect(buffer.toList().where((c) => c == x), hasLength(9));
        expect([
          for (int i = 0; i < 3; i++) buffer.get(i, 3)
        ], [
          // (0, 3)
          Cell.blank,
          // (1, 3)
          Cell.blank,
          // (2, 3)
          Cell.blank,
        ]);
      });
    });

    test('should return whether a given coordinate pair is inBounds', () {
      final buffer = Buffer(1, 1);

      expect(buffer.inBounds(-1, 0), isFalse);
      expect(buffer.inBounds(0, -1), isFalse);
      expect(buffer.inBounds(0, 0), isTrue);
      expect(buffer.inBounds(1, 0), isFalse);
      expect(buffer.inBounds(0, 1), isFalse);
    });

    test('should fail getting cells outside of bounds', () {
      final buffer = Buffer(2, 2);

      expect(() => buffer.get(-1, 0), throwsRangeError);
      expect(() => buffer.get(0, -1), throwsRangeError);
      expect(() => buffer.get(2, 0), throwsRangeError);
      expect(() => buffer.get(0, 2), throwsRangeError);
    });

    test('should get cells by a coordinate pair', () {
      final buffer = Buffer.fromMatrix([
        [Cell('X'), Cell.blank],
      ]);

      expect(buffer.get(0, 0), Cell('X'));
      expect(buffer.get(1, 0), Cell.blank);
    });

    test('should fail at getting cells by index outside of bounds', () {
      final buffer = Buffer.fromMatrix([
        [Cell('X'), Cell.blank],
      ]);

      expect(() => buffer[-1], throwsRangeError);
      expect(() => buffer[2], throwsRangeError);
    });

    test('should get cells by index', () {
      final buffer = Buffer.fromMatrix([
        [Cell('X'), Cell.blank],
      ]);

      expect(buffer[0], Cell('X'));
      expect(buffer[1], Cell.blank);
    });

    test('should fail setting cells outside of bounds', () {
      // [i=0 | 0, 0] [i=1 | 1, 0]
      // [i=2 | 0, 1] [i=3 | 1, 1]
      final buffer = WritableBuffer(2, 2);

      expect(() => buffer.set(-1, 0, Cell('X')), throwsRangeError);
      expect(() => buffer.set(0, -1, Cell('X')), throwsRangeError);
      expect(() => buffer.set(2, 0, Cell('X')), throwsRangeError);
      expect(() => buffer.set(0, 2, Cell('X')), throwsRangeError);

      // Validate we didn't somehow set a cell to 'X'.
      expect(buffer.toList(), everyElement(Cell.blank));
    });

    test('should set cells by coordinate pair', () {
      final buffer = WritableBuffer(2, 1)..set(0, 0, Cell('X'));

      expect(buffer.toList(), [Cell('X'), Cell.blank]);
    });

    test('should fail at setting cells by index outside of bounds', () {
      final buffer = WritableBuffer(2, 1);

      expect(() => buffer[-1] = Cell('X'), throwsRangeError);
      expect(() => buffer[2] = Cell('X'), throwsRangeError);

      // Validate we didn't somehow set a cell to 'X'.
      expect(buffer.toList(), everyElement(Cell.blank));
    });

    test('should set cells by index', () {
      final buffer = WritableBuffer(2, 1)..[0] = Cell('X');

      expect(buffer.toList(), [Cell('X'), Cell.blank]);
    });

    test('should fill a rectanglular region with a color', () {
      final blue = Color.fromRGB(0x00, 0x00, 0xFF);
      final buffer = WritableBuffer(3, 3);

      buffer.fill(
        x: 1,
        y: 1,
        width: 2,
        height: 2,
        background: blue,
      );

      expect(
        buffer.toMatrix().map((r) => r.map((c) => c.backgroundColor)),
        [
          [null, null, null],
          [null, blue, blue],
          [null, blue, blue],
        ],
      );
    });

    test('should fill a rectanglular region with a character', () {
      final charX = 'X'.codeUnitAt(0);
      final buffer = WritableBuffer(3, 3);

      buffer.fill(
        x: 1,
        y: 1,
        width: 2,
        height: 2,
        character: charX,
      );

      expect(
        buffer.toDebugString(),
        '   \n'
        ' XX\n'
        ' XX\n',
      );
    });

    test('should clear the entire buffer', () {
      final buffer = WritableBuffer(2, 1, initialCell: Cell('X'));

      buffer.clear();

      expect(buffer.toList(), everyElement(Cell.blank));
    });

    test('should print text entirely within the bounds of the buffer', () {
      final buffer = WritableBuffer(3, 3);

      buffer.print('Hi!', 0, 1);

      expect(
        buffer.toDebugString(),
        '   \n'
        'Hi!\n'
        '   \n',
      );
    });

    test('should ignore text outside of the bounds of the buffer', () {
      final buffer = WritableBuffer(3, 3);

      buffer.print('Hello', 0, 1);

      expect(
        buffer.toDebugString(),
        '   \n'
        'Hel\n'
        '   \n',
      );
    });
  });
}
