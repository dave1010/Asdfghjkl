# Asdfghjkl

Tiny swift app yhat lets the user use the keyboard to move and click the mouse.

## 0\. UX / Behaviour spec

*   **Trigger:** double-tap `Cmd` anywhere in macOS.
*   **Mode:** while the overlay is visible:
    *   the keyboard is used to “navigate” the grid.
    *   `Esc` cancels.
    *   character keys refine the target.
    *   `Space` clicks in the current target.
*   **Grid:**
    *   4 rows × 10 columns (40 tiles).
    *   Layout roughly matches a QWERTY-ish mental model, but doesn’t have to be perfect.
*   **Refinement:**
    *   Start with full screen(s) area.
    *   Each key press slices into that area using the 4×10 grid.
    *   After N keypresses, you’ve got a tiny region; `Space` clicks centre of that region.
*   **Zoom:**
    *   A small floating zoom window that shows a magnified preview of the current region (like a loupe).
*   **Multi-display:**
    *   Overlay appears on _all_ displays.
    *   Each keypress refines the region _within the currently selected display_.
    *   You can support “jump display” later (e.g. pressing a function key, or separate mode).

* * *

## 1\. High-level architecture

Single Xcode macOS app target, with three main concerns:

1.  **Input layer**
    
    *   Global CGEvent tap.
    *   Double-tap Cmd detection.
    *   Routing key events into the “overlay controller”.
2.  **Overlay layer**
    
    *   A controller that:
        *   owns N overlay windows (1 per screen),
        *   owns the grid state (`currentRect` per screen? or pick one active screen),
        *   receives high-level commands: `start`, `cancel`, `refineWithKey`, `click`.
3.  **Action layer**
    
    *   Mouse cursor movement + click.
    *   Zoom window that listens to the current target rect and redraws.

You can keep most of this sane with a few structs and a very small state machine.

* * *

## 2\. Input layer – double-tap Cmd

### 2.1 Event tap setup

*   Use `CGEvent.tapCreate` with `kCGHIDEventTap` (or `sessionEventTap`), listening for:
    *   `.flagsChanged`
    *   `.keyDown`
*   Install the tap on launch; on failure, bail with an error.

Key constraints:

*   You’ll need **Input Monitoring** and possibly **Accessibility** permissions.
*   Keep the event tap handler fast and simple.

### 2.2 Double-tap state machine

You want to distinguish:

*   Cmd used as a modifier (`Cmd+C`)
*   Single tap Cmd (ignored)
*   Double-tap Cmd (our activation gesture)

State you’ll track:

*   `cmdDown` (Bool)
*   `cmdLastTapTime: CFAbsoluteTime?`
*   `cmdUsedAsModifierSinceDown` (Bool)

Algorithm:

1.  On `.flagsChanged` where Command goes **down**:
    
    *   `cmdDown = true`
    *   `cmdUsedAsModifierSinceDown = false`
2.  On `.keyDown` while `cmdDown` is true:
    
    *   `cmdUsedAsModifierSinceDown = true`
3.  On `.flagsChanged` where Command goes **up**:
    
    *   If `cmdUsedAsModifierSinceDown == false`:
        *   This was a “tap” (no other keys pressed).
        *   Compare time now with `cmdLastTapTime`.
        *   If `cmdLastTapTime` exists and `now - last < 0.35` → treat as double-tap.
        *   Update `cmdLastTapTime = now`.
    *   Else:
        *   This was used as modifier; clear `cmdLastTapTime` or leave it, depending on taste.
4.  When double-tap detected:
    
    *   Dispatch to main thread: `OverlayController.shared.toggle()` or `.start()`.

You can keep all of this in a tiny `CommandTapRecognizer` class that emits `onDoubleTap` callbacks.

* * *

## 3\. Overlay layer – windows, grid, and state

### 3.1 Multi-screen windows

macOS doesn’t give you a magical “span window across all screens”, but:

*   You can enumerate `NSScreen.screens`.
*   For each, create a borderless window filling that screen’s `frame`.

Basic window config:

*   `styleMask: [.borderless]`
*   `isOpaque = false`
*   `backgroundColor = .clear`
*   `level = .screenSaver` (or `.modalPanel`/`.statusBar` if you want slightly less intrusive)
*   `ignoresMouseEvents = true`
*   `collectionBehaviour`:
    *   `.canJoinAllSpaces`
    *   `.fullScreenAuxiliary` so it appears over full-screen apps.

Each window hosts a SwiftUI view that draws:

*   lightly tinted rectangles for the grid cells
*   the currently-selected tile highlighted
*   optionally the label (letter) in each tile.

You then have one “active display” (start with `NSScreen.main`) and simply ignore keyboard grid updates for other screens initially.

### 3.2 Single source of truth: OverlayState

Define a simple state struct:

```swift
struct OverlayState {
    var activeScreen: NSScreen
    var currentRect: CGRect          // in screen coordinates of activeScreen
    var depth: Int                   // number of refinements
    var isVisible: Bool
}
```

`OverlayController` owns this and broadcasts changes (ObservableObject or a simple NotificationCenter / delegate).

On activation:

*   `activeScreen = NSScreen.main ?? NSScreen.screens.first!`
*   `currentRect = activeScreen.frame`
*   `depth = 0`
*   `isVisible = true`

On cancel:

*   `isVisible = false`
*   hide all windows and zoom.

* * *

## 4\. Grid model – 4×10 layout

You want a mapping `Character → (row, col)` for a 4×10 grid.

A concrete layout, for example:

```swift
let gridRows: [[Character]] = [
    Array("1234567890"),   // row 0
    Array("QWERTYUIOP"),   // row 1
    Array("ASDFGHJKL;"),   // row 2
    Array("ZXCVBNM,./")    // row 3
]
```

You don’t need to use all keys; you can ignore ones you don’t like. The mapping function:

```swift
struct GridLayout {
    let rows: [[Character]] = gridRows

    func index(for char: Character) -> (row: Int, col: Int)? {
        let upper = Character(char.uppercased())
        for (r, row) in rows.enumerated() {
            if let c = row.firstIndex(of: upper) {
                return (r, c)
            }
        }
        return nil
    }

    var columnCount: Int { rows.map(\.count).max() ?? 10 }
    var rowCount: Int { rows.count }
}
```

### 4.1 Subdividing the current rect

Given a `currentRect` and a `(row, col)`:

```swift
func subdivide(rect: CGRect, row: Int, col: Int,
               rowCount: Int, colCount: Int) -> CGRect {
    let tileWidth  = rect.width / CGFloat(colCount)
    let tileHeight = rect.height / CGFloat(rowCount)

    let x = rect.minX + CGFloat(col) * tileWidth
    let y = rect.minY + CGFloat(row) * tileHeight
    // Or invert Y depending on your visual orientation.

    return CGRect(x: x, y: y, width: tileWidth, height: tileHeight)
}
```

On each character press:

1.  Look up `(row, col)`.
2.  Compute subdivided rect.
3.  Set `currentRect = that rect`.
4.  Notify overlay views + zoom.

* * *

## 5\. Zooming (loupe)

Simplest design:

*   Another small borderless window that:
    *   floats near the centre of the active screen, or near the mouse cursor.
    *   shows a magnified snapshot of `currentRect`.

Implementation options:

1.  **Snapshot + scale**:
    
    *   Use `CGWindowListCreateImage` with the union of on-screen windows, clipped to `currentRect`.
    *   Draw that image scaled up in the zoom window’s content view, perhaps with a border.
2.  **NSView live scaling**:
    
    *   Harder; you don’t want to mirror the whole desktop manually.
    *   Snapshot-per-update is probably fine for a personal tool; you only update when keys are pressed.

Sequence:

*   When overlay is activated: create zoom window, show initial snapshot of the full active screen centre.
*   On each refinement: re-snapshot, and update the zoom image.
*   When done/cancelled: hide zoom.

You can absolutely skip this for v0 if you want to reduce surface area.

* * *

## 6\. Action layer – clicking

When the user hits `Space`:

1.  Compute centre point:
    
    ```swift
    let target = CGPoint(x: currentRect.midX, y: currentRect.midY)
    ```
    
2.  Move cursor (optional, but feels more transparent):
    
    ```swift
    CGWarpMouseCursorPosition(target)
    ```
    
3.  Generate click:
    
    ```swift
    let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                       mouseCursorPosition: target, mouseButton: .left)
    let up   = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                       mouseCursorPosition: target, mouseButton: .left)
    down?.post(tap: .cghidEventTap)
    up?.post(tap: .cghidEventTap)
    ```
    
4.  Hide overlay + zoom, reset state.
    

You’ll need the app in **Accessibility** (for CGEvents) and/or **Input Monitoring** (for taps). Just prompt once and then rely on System Settings.

* * *

## 7\. Impl roadmap (realistic steps)

If you want a smooth path, I’d do this:

### Step 1 – Bare SwiftUI app with one overlay

*   Make a macOS app with a menu bar icon or a simple “Activate” button.
*   On click, show a borderless overlay window over `NSScreen.main`, with a translucent grey background.
*   Implement `Esc` to dismiss.

### Step 2 – 4×10 grid drawing + keyboard refinement

*   In the overlay view, draw the 4×10 grid for the full screen, highlight a tile based on `currentRect`.
*   Add `keyDown` handling:
    *   on letter/number: update `currentRect` using the grid model.
    *   re-render highlight.

No global hooks yet – just test behaviour when the app is active.

### Step 3 – Mouse click on Space

*   On `Space`, click centre of `currentRect`, hide overlay.
*   Manually give yourself Accessibility permission and verify it works in other apps when overlay is active.

### Step 4 – Event tap + double Cmd

*   Move keyboard handling into the CGEvent tap globally:
    *   when overlay is inactive: only pay attention to Cmd and double-tap detection.
    *   when overlay is active: intercept keydown events and _don’t_ pass them through to the system (you can return `nil` from the tap for those).
*   Wire double-tap Cmd → `OverlayController.start()`.

Now you’ve got the core “magic”: double-tap Cmd, type a few keys, Space to click.

### Step 5 – Multi-screen support

*   Create overlay window per screen.
*   For v1, you can:
    *   still only act on `activeScreen = NSScreen.main`, but show passive grid overlays on all.
    *   or choose screen based on current cursor location at activation time; use that as `activeScreen`.

### Step 6 – Zoom / loupe

*   Add a small zoom window that listens to `currentRect` and renders a magnified snapshot.
*   Tune performance and maybe cap refresh to “on keypress only”.

* * *

## 8\. Rough class layout

Something like:

*   `AppDelegate` / SwiftUI `App`:
    *   initialises `InputManager` and `OverlayController`.
*   `InputManager`:
    *   sets up CGEvent tap.
    *   owns `CommandTapRecognizer`.
    *   routes:
        *   double-tap Cmd → `overlayController.toggle()`
        *   when overlay active: key events → `overlayController.handleKey(char)`
*   `OverlayController`:
    *   owns `OverlayState`.
    *   owns overlay windows + zoom window.
    *   public methods:
        *   `start()`
        *   `cancel()`
        *   `handleKey(_ char: Character)`
*   `GridLayout`:
    *   mapping from char to `(row, col)` and subdivision.
*   `ZoomController`:
    *   optional; snapshot + display logic.

* * *

## 9\. A couple of design caveats

*   **Double-tap threshold:** too short and you’ll “miss” fast taps; too long and accidental double CMD taps will trigger. 250–350 ms is a decent starting range; make it configurable.
*   **Interference with normal Cmd usage:** you _must_ treat any `keyDown` while Cmd is held as “used as modifier” to avoid spurious triggers after `Cmd+C, Cmd+V` patterns.
*   **Spaces / Mission Control / full-screen apps:** using `.canJoinAllSpaces` and high window levels typically works fine, but you may see edge cases. For your personal use, they’re tolerable.

* * *
