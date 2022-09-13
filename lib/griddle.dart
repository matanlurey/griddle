/// Griddle is a _canvas-like_ drawing API based on a 2D grid of cells.
///
/// Griddle has only three concepts to master:
/// 1. [Cell]s, which a single character codes and, optionally, colors.
/// 2. [Buffer]s, which are painting contexts made up of a 2D grid of [Cell]s.
/// 3. [Screen]s, which write a [Buffer] to an updateable (external) display.
///
/// [Screen] can be _optionally_ combined with a [Display] for simplicty:
/// ```dart
/// // NOT required, just an example to get running with a few lines of code.
/// import 'dart:io' show stdout;
///
/// void main() {
///   final screen = Screen.display(
///     Display.fromAnsiTerminal(
///       stdout,
///       width: () => stdout.terminalColumns,
///       height: () => stdout.terminalLines,
///     )
///   );
///
///   // Use your screen!
/// }
/// ```
///
/// Or, for testing and continuous integration-like environments:
/// ```dart
/// void main() {
///   final buffer = StringBuffer();
///
///   final screen = Screen.display(
///     Display.fromStringBuffer(
///       buffer,
///       /* Optionally set width: ... and height: ..., defaults to 80x25 */
///     ),
///   );
///
///   // Use your screen!
/// }
/// ```
///
/// We expect higher-level APIs to built on top of Griddle in the future!
library griddle;

import 'package:meta/meta.dart';
import 'package:neoansi/neoansi.dart';

export 'package:neoansi/neoansi.dart' show Color;

part 'src/buffer.dart';
part 'src/cell.dart';
part 'src/screen.dart';
part 'src/display.dart';
