# Design

This doc: an overview of the design and plans around developing `griddle`.

<!--
  Fun Emoji I will use in this doc:

  ⚪ Draft                          Still figuring out exactly what to do.
  🔵 Done                           Completed (at least for now).
  🟢 In-progress and on-track       On-track to be completed.
  🟡 Planned or off-track           Planned, or in slow (but steady) progress.
  🔴 Blocked                        Planned, but progress cannot be made yet.
-->

## Layers

> 🔵 &nbsp;&nbsp;**Done**: Additional APIs could be added though.

There are 3 "layers" necessary to build a terminal-based UI framework:

1. A low-level API for manipulating a terminal:

   We use a combination of `dart:io`, `dart:ffi`, and [`neoansi`][neoansi].

2. A higher-level, _canvas-like_ drawing API built upon the lower-level API.

   This package, `griddle`.

3. A framework-level, _declarative_ API for creating complex UIs simply.

   **Out of scope** of this package, to be built on top of `griddle`.

   Some examples of what this might look like:

   - [`brick`, a Haskell terminal user interface toolkit][brick]
   - [`bubbletea`, a fun, functional, and stateful way to build terminal apps][bubbletea]
   - [`gruid`, grid-based applications in Go][gruid]

[brick]: https://github.com/jtdaugherty/brick
[bubbletea]: https://github.com/charmbracelet/bubbletea
[gruid]: https://github.com/anaseto/gruid
[neoansi]: https://pub.dev/packages/neoansi

## Compatibility

> 🔵 &nbsp;&nbsp;**Done**: No platform specific libraries are imported.

It should be possible to support all major platforms, including:

1. Desktops on all major platforms (Windows, MacOS, Linux)
2. Web (compiled to JavaScript)
3. Mobile (using [Flutter](https://flutter.dev))

In fact, it might even be possible to directly support something like Discord.
However, everything but _desktop_ would require creating or using a terminal
_emulator_, which is additional work. Therefore, priority will be put on
_desktop_ work using native (built-in) terminals.
