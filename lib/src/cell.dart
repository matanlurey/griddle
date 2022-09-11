part of '../griddle.dart';

/// A two-dimensional cell, sometimes called a "pixel", within a screen.
///
/// A cell is a simple immutable value-type that is a combination of a:
/// - [character], which defaults to a space (`' '`).
/// - [foregroundColor]
/// - [backgroundColor]
@immutable
@sealed
class Cell {
  /// A "blank" cell, i.e. with a space (`' '`) character.
  static const blank = Cell._(_$codeSpace, null, null);

  static const _$codeSpace = 0x20;

  /// Character code to be rendered in this cell.
  final int character;

  /// If provided, the 24-bit RGB color  used for styling the [character].
  final Color? foregroundColor;

  /// If provided, the 24-bit RGB color used for styling the background.
  final Color? backgroundColor;

  /// Creates a cell that will render the provided [character] string.
  ///
  /// ```dart
  /// // Just a space
  /// Cell()
  ///
  /// // Any character
  /// Cell('X')
  /// ```
  ///
  /// If a string is not provided, defaults to a space (`' '`).
  ///
  /// To add styling, use in conjunction with [withColor], i.e.:
  /// ```
  /// Cell('X').withColor(background: Color.fromRGB(0xFF, 0x00, 0x00))
  /// ```
  factory Cell([String? character]) {
    if (character == null) {
      return blank;
    }
    if (character.length != 1) {
      throw ArgumentError.value(
        character,
        'character',
        'Must be a string of exactly length 1, got ${character.length}',
      );
    }
    return Cell._(character.codeUnitAt(0), null, null);
  }

  /// Creates a cell that will render the provided [character] code.
  ///
  /// ```dart
  /// // Just as an example, prefer Cell('X') for this use
  /// Cell.ofCharacter('X'.codeUnitAt(0))
  ///
  /// // Strongly preferred (hex-code for 'X' in code units)
  /// Cell.ofCharacter(0x58)
  /// ```
  ///
  /// To add styling, use in conjunction with [withColor], i.e.:
  /// ```
  /// Cell.ofCharacter(0x58).withColor(background: Color.fromRGB(0xFF, 0x00, 0x00))
  /// ```
  Cell.ofCharacter(int character)
      : this._(
          RangeError.checkNotNegative(character, 'character'),
          null,
          null,
        );

  const Cell._(
    this.character,
    this.foregroundColor,
    this.backgroundColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is Cell &&
          character == other.character &&
          foregroundColor == other.foregroundColor &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode {
    return Object.hash(
      character,
      foregroundColor,
      backgroundColor,
    );
  }

  /// Returns the cell with colors set.
  ///
  /// An implicit or explcit value of `null` defaults to the current color.
  @useResult
  Cell withColor({
    Color? foreground,
    Color? background,
  }) {
    return Cell._(
      character,
      foreground ?? foregroundColor,
      background ?? backgroundColor,
    );
  }

  /// Returns the cell with a new [character] set.
  @useResult
  Cell withCharacter(int character) {
    return Cell._(character, foregroundColor, backgroundColor);
  }

  /// Returns the cell with the character cleared (reset to a space).
  @useResult
  Cell clearCharacter() {
    return Cell._(_$codeSpace, foregroundColor, backgroundColor);
  }

  /// Returns the cell with all colors cleared (reset to the default).
  @useResult
  Cell clearColors() => Cell._(character, null, null);

  @override
  String toString() {
    final foreground = foregroundColor;
    final background = backgroundColor;
    final character = String.fromCharCode(this.character);
    if (foreground == null && background == null) {
      return 'Cell <$character>';
    } else {
      return 'Cell <$character: f=$foreground b=$background>';
    }
  }
}
