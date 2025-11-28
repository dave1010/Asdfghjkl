# Asdfghjkl

Use the keyboard instead of the mouse.

Named after the Deadmau5' song Asdfghjkl, as the mouse is dead and you use a Qwerty keyboard instead.

**Double tap Cmd to see an overlay on your screen. Tap a corresponding key to select that area, then tap again (and again) to drill down. Tap space to move the mouse and click.**

The package now ships a SwiftUI/AppKit macOS app lifecycle that installs a global CGEvent tap
to capture double-Cmd activation and routes key presses into the `InputManager`. Borderless
overlay windows span each connected `NSScreen` to visualise the grid refinement and
highlight the current target, and a floating zoom window follows
`ZoomController.observedRect`. Key presses are consumed while the overlay is active: letters
refine the grid, `Space` clicks, and `Esc` cancels.

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
* `macOS Binary` is a manually triggered workflow that builds the `Asdfghjkl` release product on macOS, records `swift build --configuration release --product Asdfghjkl --show-bin-path` in the environment, lists the contents of the reported bin directory for debugging, and uploads the resulting executable as an artifact.
