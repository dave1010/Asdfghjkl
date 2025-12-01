# Asdfghjkl Architecture

## Overview
Asdfghjkl is a macOS utility that replaces mouse navigation with a keyboard-driven overlay. A global event tap detects a double-tap of the Command key to toggle the overlay, keys refine a 4×10 grid that maps to the screen while warping the cursor to the refined centre, and pressing Space clicks without needing to move again. The package is split into a reusable core library and a macOS app target that hosts SwiftUI/AppKit windows for the overlay and zoom preview.

## Package layout
The Swift package exposes a platform-neutral `AsdfghjklCore` library alongside the `Asdfghjkl` executable target. Core contains the state machine, grid math, input handling, and mouse action abstractions, while the executable hosts the SwiftUI/AppKit presentation that subscribes to core state and renders overlay windows on every screen. Tests target the core library directly to keep UI concerns separate.

## Core layer
- **Grid navigation**: `GridLayout` maps keyboard characters onto a 4×10 grid and returns the subdivided rectangle for each key, enabling iterative refinement of the target region. `GridRect` provides geometric utilities including `center` for the midpoint, while `GridPartitioner` splits the columns across multiple displays so the first keypress selects the correct screen before drilling into that display.
- **Overlay state and control**: `OverlayController` owns the overlay lifecycle. It starts the overlay with the active screen bounds, refines the current rectangle on key presses, and deactivates after a click or cancel. The controller maintains a history stack of previous states, allowing backspace to restore the previous level. The controller extracts clear helper methods: `selectScreenIfNeeded`, `refineGrid`, `applyRefinement`, and `zoomOut` make the key handling flow explicit. `OverlayState` holds the active flag, root bounds, refined rectangle, and derived target point so downstream consumers can react without duplicating business logic.
- **Input processing**: `InputManager` installs the CGEvent tap on macOS, routes modifier changes through `CommandTapRecognizer` to detect the double-Cmd gesture, and forwards key presses to the overlay controller. It also consumes Escape to cancel and Space to trigger the click, mirroring the keyboard-driven workflow even in non-AppKit builds (where it logs a stub message instead of creating the tap).
- **Pointer actions**: `MouseActionPerforming` abstracts cursor motion and clicking. The default `SystemMouseActionPerformer` can warp the cursor independently of clicks and post click events at the current target, while tests can inject stubs to assert coordinates without real side effects.

## macOS app layer
- **App bootstrap**: `AppDelegate` wires the pieces together: it instantiates the grid layout, overlay controller, and visual model; builds overlay windows per `NSScreen` with per-display grid slices; and starts the input manager. It rebuilds windows when screens change so overlays and partitions stay in sync. Window visibility is managed through `updateWindowVisibility`, which shows/hides overlay windows based on state.
- **Overlay windows**: `OverlayWindowController` hosts an `OverlayGridView` inside a borderless `NSWindow` at the `.screenSaver` level. The SwiftUI view draws the translucent grid and highlights the current target rectangle for each display while ignoring mouse events. Each window receives its own `GridSlice` so labels and hit testing only cover the columns assigned to that screen.
- **State bridging for SwiftUI**: `OverlayVisualModel` mirrors core overlay state as an `ObservableObject`, letting SwiftUI views animate visibility and highlights as the controller emits updates. The app listens to `OverlayController.stateDidChange` and hops to the main actor with Swift concurrency tasks so UI updates stay in sync with the event tap callbacks while satisfying AppKit's main-thread isolation.

## Event flow
1. App launch initializes the controllers, windows, and screen observer, then starts the input manager.
2. Double-tapping Command toggles the overlay and shows the overlay windows.
3. Each key press refines the grid rectangle via the core layout; the first key maps to a display when multiple screens are present, after which refinements stay within that slice, move the cursor to the refined centre, and update the highlight. The current state is pushed to history before each refinement.
4. Backspace pops the previous state from history, restoring the rectangle and cursor position to the previous level.
5. Arrow keys move the selected tile by half its width (left/right) or height (up/down), keeping its size unchanged while updating cursor position. Movement is blocked before a selection is made and constrained to stay within screen bounds.
6. Space posts a click at the refined target without warping again, after which the overlay hides; Escape cancels instead.
