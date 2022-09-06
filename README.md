# griddle

Griddle _simplifies_ to concept of creating 2D games or UI applications within
a 2D-matrix, or _grid_, which in turn makes it a suitable cross-platform
graphics framework for lower fidelity games or apps.

<!-- ENABLE WHEN PUBLISHED
[![On pub.dev][pub_img]][pub_url]
[![Code coverage][cov_img]][cov_url]
[![Github action status][gha_img]][gha_url]
[![Dartdocs][doc_img]][doc_url]
-->

[![Style guide][sty_img]][sty_url]

<!-- ENABLE WHEN PUBLISHED
[pub_url]: https://pub.dartlang.org/packages/griddle
[pub_img]: https://img.shields.io/pub/v/griddle.svg
[gha_url]: https://github.com/neo-dart/griddle/actions
[gha_img]: https://github.com/neo-dart/griddle/workflows/Dart/badge.svg
[cov_url]: https://codecov.io/gh/neo-dart/griddle
[cov_img]: https://codecov.io/gh/neo-dart/griddle/branch/main/graph/badge.svg
[doc_url]: https://www.dartdocs.org/documentation/griddle/latest
[doc_img]: https://img.shields.io/badge/Documentation-griddle-blue.svg
-->

[sty_url]: https://pub.dev/packages/neodart
[sty_img]: https://img.shields.io/badge/style-neodart-9cf.svg

It is _inspired_ by:

- [`tcell`, a Go package that provides cell-based views for terminals][tcell]
- [`termbox`, a minimalistic API to write text-based UIs][termbox]
- [`termpixels`, the terminal as a character-cell matrix][termpixels]

[tcell]: https://github.com/gdamore/tcell
[termbox]: https://github.com/nsf/termbox-go
[termpixels]: https://github.com/loganzartman/termpixels

## Purpose

Creating simple 2D programs that run inside a terminal (or terminal emulator) is
complicated. The goal of `griddle` is to **abstract a terminal-like screen into
a 2D _grid_ of character cells**.

Like [`termpixels`][termpixels], this project makes the terminal more
accessible and more fun, but in Dart!

> **NOTE**: To learn more about the design of `griddle`, view [DESIGN.md][].

[design.md]: DESIGN.md

## Usage

TBD.

## Contributing

TBD.
