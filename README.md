# Asdfghjkl

Use the keyboard instead of the mouse.

Named after the Deadmau5' song Asdfghjkl, as the mouse is dead and you use a Qwerty keyboard instead.

**Double tap Cmd to see an overlay on your screen. Tap a corresponding key to select that area. tap again (and again) to drill down. Tap soace to move the mouse and click.**

This repository currently contains a scaffolded macOS overlay app described in `PLAN.md`.
The Swift Package builds a headless skeleton of the input, overlay, and action layers so we
can iterate on the logic before attaching real AppKit windows and event taps.

## Building and testing

You can build and run the placeholder executable with the provided `Makefile`:

```sh
make build   # swift build + direct swiftc compile for quick iteration
make test    # runs the GridLayout and overlay state tests
make run     # runs the executable from .build/debug
```

To keep the binary alive for a quick state-machine demo, run with `ASDFGHJKL_DEMO=1`:

```sh
ASDFGHJKL_DEMO=1 .build/debug/Asdfghjkl
```

## Continuous integration

GitHub Actions keep the package healthy and provide a downloadable binary:

* `Test` runs on pushes to `main` and all pull requests, setting up Swift 6.2 on macOS and executing `swift test --parallel`.
* `macOS Binary` is a manually triggered workflow that builds a release binary on macOS and uploads `.build/apple/Products/Release/Asdfghjkl` as an artifact.
