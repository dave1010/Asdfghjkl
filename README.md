# Asdfghjkl

Use the keyboard instead of the mouse. Inspired by Deadmau5.

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
