# Asdfghjkl

> **The Mouse is Dead. Use _Asdfghjkl_ instead.**

Named after the [Deadmau5 song Asdfghjkl](https://www.youtube.com/watch?v=1aP910O2774)

## What does it do?

1. Double tap Cmd to see a grid on your screen.
2. Tap a corresponding key to move the mouse to that area.
3. Tap again (and again) to drill down.
4. Tap `Space` at any point to click the mouse.

You can also:

- Tap `Backspace` to zoom back out to the previous level
- Tap `Esc` to cancel and hide the overlay

## Why?

Mice are slow and a long way away from the keyboard.

## Inspiration

- [mouseless](https://mouseless.click/)
- [mousemaster](https://github.com/petoncle/mousemaster)
- [warpd](https://github.com/rvaiya/warpd)
- [scoot](https://github.com/mjrusso/scoot)
- [shortcat](https://shortcat.app/)
- [superkey](https://superkey.app/)
- [homerow](https://www.homerow.app/)
- [httpsvimac](https://github.com/nchudleigh/vimac)

## How does it work?

Read [ARCHITECTURE.md](ARCHITECTURE.md) for a deeper look at the current components and runtime flow.

### Multiple displays

On multi-display setups, the 4×10 grid is divided horizontally across all overlay windows so
the first keypress selects a screen by column range (e.g. `Q…T` on screen 1, `Y…P` on screen
2). Refinements after the first key keep using the per-screen slice, keeping labels and hit
testing aligned with the display that owns the tapped keys.

### Permissions

The macOS app installs the global CGEvent tap on launch (requires Input Monitoring and
Accessibility permissions) and rebuilds overlay windows whenever displays change, keeping a
window on every attached screen. Quit the app to tear down the tap cleanly.

On first launch, macOS may block the event tap unless the app is allowed under **System Settings > Privacy & Security > Input Monitoring** and **Accessibility**. The app now surfaces a dialog when the tap cannot be created so you can grant the permissions and restart.

## Development

`Asdfghjkl` is built with Swift 6.2 and targets macOS 14+.

You can build and run `Asdfghjkl` with the provided `Makefile`:

```sh
make build   # swift build + direct swiftc compile for quick iteration
make test    # runs the GridLayout and overlay state tests
make run     # runs the executable from .build/debug
```

### Continuous integration

GitHub Actions keep the package healthy and provide a downloadable binary:

* `Test` runs on pushes to `main` and all pull requests, setting up Swift 6.2 on macOS and executing `swift test --parallel`.
* `macOS Binary` is a manually triggered workflow that builds the `Asdfghjkl` release product on macOS, captures the release bin path with `swift build --configuration release --show-bin-path`, lists the contents of that directory for debugging, and uploads the resulting executable as an artifact.
