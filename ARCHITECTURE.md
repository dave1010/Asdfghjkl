# Asdfghjkl Architecture

## Overview
Asdfghjkl is a macOS utility that replaces mouse navigation with a keyboard-driven overlay. A global event tap detects a double-tap of the Command key to toggle the overlay, keys refine a 4×10 grid that maps to the screen, and pressing Space moves the pointer to the refined cell and clicks. The package is split into a reusable core library and a macOS app target that hosts SwiftUI/AppKit windows for the overlay and zoom preview.

## Package layout
The Swift package exposes a platform-neutral `AsdfghjklCore` library alongside the `Asdfghjkl` executable target. Core contains the state machine, grid math, input handling, and mouse action abstractions, while the executable hosts the SwiftUI/AppKit presentation that subscribes to core state and renders overlay windows on every screen. Tests target the core library directly to keep UI concerns separate.

## Core layer
- **Grid navigation**: `GridLayout` maps keyboard characters onto a 4×10 grid and returns the subdivided rectangle for each key, enabling iterative refinement of the target region. The grid model also provides `GridRect` and `GridPoint` utilities for coordinate math, while `GridPartitioner` splits the columns across multiple displays so the first keypress selects the correct screen before drilling into that display.
- **Overlay state and control**: `OverlayController` owns the overlay lifecycle. It starts the overlay with the active screen bounds, refines the current rectangle on key presses, updates the zoom model, and deactivates after a click or cancel. `OverlayState` holds the active flag, root bounds, refined rectangle, and derived target point so downstream consumers can react without duplicating business logic.
- **Input processing**: `InputManager` installs the CGEvent tap on macOS, routes modifier changes through `CommandTapRecognizer` to detect the double-Cmd gesture, and forwards key presses to the overlay controller. It also consumes Escape to cancel and Space to trigger the click, mirroring the keyboard-driven workflow even in non-AppKit builds (where it logs a stub message instead of creating the tap).
- **Pointer actions**: `MouseActionPerforming` abstracts cursor motion and clicking. The default `SystemMouseActionPerformer` warps the cursor and posts click events, while tests can inject stubs to assert coordinates without real side effects.
- **Zoom model**: `ZoomController` tracks the currently refined rectangle and, on macOS, captures a snapshot image for that area through a `ZoomSnapshotProviding` strategy (defaulting to `CGWindowListCreateImage`). The observed rectangle and latest snapshot are published so UI components can update reactively.

## macOS app layer
- **App bootstrap**: `AppDelegate` wires the pieces together: it instantiates the grid layout, core controllers, and visual model; builds overlay windows per `NSScreen` with per-display grid slices; creates the zoom window; and starts the input manager. It rebuilds windows when screens change so overlays and partitions stay in sync.
- **Overlay windows**: `OverlayWindowController` hosts an `OverlayGridView` inside a borderless `NSWindow` at the `.screenSaver` level. The SwiftUI view draws the translucent grid and highlights the current target rectangle for each display while ignoring mouse events so it never blocks input. Each window receives its own `GridSlice` so labels and hit testing only cover the columns assigned to that screen.
- **Zoom window**: `ZoomWindowController` presents a floating window with `ZoomPreviewView`. It subscribes to the zoom controller’s published rectangle, repositions the window near the target while clamping to visible screen bounds, and shows the live snapshot or a loading placeholder when screen recording access is missing.
- **State bridging for SwiftUI**: `OverlayVisualModel` mirrors core overlay state as an `ObservableObject`, letting SwiftUI views animate visibility and highlights as the controller emits updates. The app listens to `OverlayController.stateDidChange` and applies changes on the main queue so UI updates stay in sync with the event tap callbacks.

## Event flow
1. App launch initializes the controllers, windows, and screen observer, then starts the input manager.
2. Double-tapping Command toggles the overlay and shows the overlay and zoom windows.
3. Each key press refines the grid rectangle via the core layout; the first key maps to a display when multiple screens are pre
sent, after which refinements stay within that slice and update the zoom snapshot and highlight.
4. Space triggers a cursor warp and click at the refined target, after which the overlay hides; Escape cancels instead.
