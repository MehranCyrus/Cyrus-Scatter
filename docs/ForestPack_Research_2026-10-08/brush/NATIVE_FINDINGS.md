# Native brush findings

All addresses are RVAs in the hash-pinned core module. Add preferred base `0x180000000` for analysis VAs. Research labels are observations, not original source names. Detailed private listings/ledgers stay under the run identified in [EVIDENCE.json](EVIDENCE.json).

## Callback ownership and the Max Painter boundary

MSVC RTTI identifies `TForestDlgProcArea`, with an `IPainterCanvasInterface_V5` subobject at offset **88 / 0x58** and vtable RVA **0x22b2d0**. The callback owner is the area dialog procedure; the investigation's initial assumption that it belonged directly to `TForest` was corrected by decoding the class hierarchy.

Fresh MSVC 14.38.33130 / Max 2027 SDK probes compiled the layouts of Painter Canvas V5, Painter Interface V5/V7 and RestoreObj. They establish these canvas slots:

| Slot | Callback | RVA |
|---:|---|---|
| 0 | StartStroke | `0x8da40` |
| 1 | PaintStroke | `0x8db50` |
| 2 | EndStroke | `0x8e150` |
| 3 | EndStroke with arrays | `0x8e0e0` |
| 4 | CancelStroke | `0x8e1c0` |
| 5 | SystemEndPaintSession | `0x8e1e0` |
| 6 | PainterDisplay | `0x178a0`, shared trivial implementation |

Session setup `0x8e320` gathers receiving nodes and evaluated `ObjectState` records, loads the current contour paths and calls SDK-identified `InitializeNodesByObjState`, `InitializeCallback` and `StartPaintSession`. It also checks receiver configuration and handles an existing session. An XY-surface warning is present; the exact receiver-eligibility virtual method was not reconstructed.

Dialog initialization `0x8cd70` acquires a Max Painter interface. The actual primary dialog callback `0x8be40` retrieves its parameter-block owner at initialization, handles paint/erase/options and conversion commands, updates the size control, and ends painting during control destruction. SDK slot 67 (`0x218`) is `GetMaxSize`; slot 68 (`0x220`) is `SetMaxSize`. The options button calls `BringUpOptions`. This ties brush input and its settings to the host Painter rather than an independently invented input framework. Complete global preference restoration was not traced.

## Footprint, coordinate system and geometry editing

`PaintStroke` at `0x8db50` transforms the hit through a Forest-owned matrix and uses an axis selector to choose a two-dimensional plane. A size value is multiplied by 0.5; a minimum-work gate compares the result with 0.1 times Painter Max Size. This is the observed arithmetic, not a calibrated tablet-pressure threshold.

Circle helper `0x19c980` builds **24 vertices**, with an angular step of approximately **0.2617994 radians / 15 degrees**. It retains a size-dependent circle template and translates it to the current hit. The 24 count and angle constant were checked in the binary. Coordinates are converted to integer pairs using the system-unit scale; session setup calls `GetSystemUnitScale(3)`, whose SDK definition is millimeters. Float-to-integer conversion uses compiler rounding machinery; its exact tie behavior and numerical range were not qualified.

RTTI identifies `clipper::Clipper` with its relevant vtable at `0x242ef0`. The paint path initializes the clipping object, supplies existing paths and the circle, and invokes the wrapper at `0x198a20`. That wrapper dispatches through the observed Clipper implementation at `0x198cc0` and extracts resulting contours. Addition/subtraction matches the documented artist behavior. The private engine's operation codes and modifier-key mapping are not certified by borrowing an enum from a different Clipper release. The precise incorporated library version/modifications remain unknown.

Cleanup at `0x19d660` iteratively considers intermediate vertex deviation from endpoint segments, retains necessary points and compacts each contour. Its thresholds are derived from the current brush size; extra retention logic protects points around the active brush region. This is a contour-simplification algorithm, not evidence of stored grayscale pixels or editable history for each dab. Its approximation error and topology preservation need tests.

## Publication and stored shape

Contour publication `0x8d8d0` reinitializes a `PolyShape` inside the selected `LinearShape`, emits a `PolyLine` for each valid contour, marks it closed and invalidates geometry cache. Its OpenMP fill helper at `0x1ec530` converts integer paths back to three-dimensional polyline vertices. Projection branches place coordinates in YZ, XZ or XY; an XY receiver path additionally invokes internal surface-projection logic. Parallel vertex filling does not prove that the complete scatter solve is parallel or free of host-thread constraints.

Reverse path loader `0x19dd40` reads closed polylines from that shape into integer paths. The registration builder contains `arpaintlist` with type value `0x812`, corresponding to SDK `TYPE_REFTARG_TAB`. Area-record read/write helpers (`0x7eed0`, `0x7fbd0`) handle the shape-bearing record and other area properties. This establishes a referenced shape representation. Actual scene serialization, clone ownership and save/reopen survival were not exercised.

Paint-to-spline `0x8d4d0` creates a scene `SplineShape`, transforms it into the scene frame, creates/names its node and updates the area record. Spline-to-paint `0x8d250` evaluates a shape, constructs a `LinearShape`, transforms its `PolyShape` into Forest-local coordinates and updates the record. These paths explain how area painting and ordinary spline editing interoperate; approximation during curved-spline conversion remains unmeasured.

## Undo and cancellation

StartStroke calls Max `theHold.Begin`, creates `AreaPaintRestore` and copies the current contour paths into it. Both end callbacks accept the hold; CancelStroke cancels it. The array end callback does **not** visibly replay the supplied hit arrays in its selected body, so this pass does not certify “Update on Mouse Up” behavior.

The RestoreObj vtable at `0x22b8e0` and fresh SDK witness identify Restore `0x8e770` and Redo `0x8e960`. Restore can capture an after-state, then reinstall before-state contours; Redo installs the after-state. Both check the active paint area identity, rebuild the shape and request update/redraw work. They use session-global state, which makes changing selection/closing panels/Undo after ending a session important runtime cases. No failure is claimed from those globals alone.

## Limits and corrected labels

- Selection `area_load_contours` requested `0x8d700`, but Ghidra resolved it inside `0x8d4d0`; it was a duplicate paint-to-spline selection, not a recovered loader. The independently located loader is `0x19dd40`.
- Selection `area_dialog_dispatch` at `0x87bf0` is a max-value-plus-one area helper, not the dialog callback. The actual callback was found through its primary vtable at `0x8be40`.
- `area_restore_redo` duplicates the earlier RestoreObj slot-3 selection.
- A second Painter subclass belongs to `TFIvyDlgProcGrowth`. Its existence does not establish that Ivy painting or effect-parameter painting uses this area-contour pipeline.
- No fully recovered scatter scheduling, sampling, surface identity migration or complete mask-query implementation is claimed. Some decompiler signatures remain unresolved; claims were bounded by RTTI, SDK layouts, assembly and explicit imported shape/hold calls.
