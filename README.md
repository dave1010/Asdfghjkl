# Asdfghjkl

Use the keyboard instead of the mouse.

Named after the Deadmau5' song Asdfghjkl, as the mouse is dead and you use a Qwerty keyboard instead.

**Double tap Cmd to see an overlay on your screen. Tap a corresponding key to select that area, then tap again (and again) to drill down. Tap space to move the mouse and click.**

The package now ships a SwiftUI/AppKit macOS app lifecycle that installs a global CGEvent tap
to capture double-Cmd activation and routes key presses into the `InputManager`. Borderless
overlay windows span each connected `NSScreen` to visualise the grid refinement and
highlight the current target. A floating zoom window now captures a live snapshot of the
active region (when Screen Recording permission is granted) so you can see exactly where a
click will land as you refine the grid. The zoom window follows the target region so it
stays close to your focus point without drifting off-screen. Key presses are consumed while the overlay is
active: letters refine the grid, `Space` clicks, and `Esc` cancels.

Read [ARCHITECTURE.md](ARCHITECTURE.md) for a deeper look at the current components and runtime flow.

The macOS app installs the global CGEvent tap on launch (requires Input Monitoring and
Accessibility permissions) and rebuilds overlay windows whenever displays change, keeping a
window on every attached screen. Quit the app to tear down the tap cleanly.

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
