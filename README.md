# Asdfghjkl

Use the keyboard instead of the mouse.

Named after the Deadmau5' song Asdfghjkl, as the mouse is dead and you use a Qwerty keyboard instead.

**Double tap Cmd to see an overlay on your screen. Tap a corresponding key to select that area, then tap again (and again) to drill down. Tap space to move the mouse and click.**

This repository currently contains a scaffolded macOS overlay app described in `PLAN.md`.
The Swift Package builds a headless skeleton of the input, overlay, and action layers so we
can iterate on the logic before attaching real AppKit windows and event taps. The overlay
controller can now drive an injected click handler and keep a zoom controller in sync with
the current target rectangle, making it easier to plug UI rendering into the existing state
The default action performer (`SystemMouseActionPerformer`) now issues real CGEvent cursor
warps and clicks on macOS so the scaffold is closer to end-to-end behaviour even before the
overlay windows exist.

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
* `macOS Binary` is a manually triggered workflow that builds the `Asdfghjkl` release product on macOS, captures the release bin path with `swift build --configuration release --show-bin-path`, lists the contents of that directory for debugging, and uploads the resulting executable as an artifact.
