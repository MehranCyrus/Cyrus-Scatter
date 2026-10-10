# Brush Start and Max 2026/2027 — 0.78.1

The artist-reported Start Brush failure was reproduced and corrected. This patch also fixes native control clipping in both supported Max years. Schema 55 and the vector payload are unchanged from 0.78.0.

## Cause and changes

The generated rollout declared `refreshBrushStatus` before the function it called, `status`. MAXScript resolved that forward reference as undefined. Start Brush successfully entered native Painter mode, then the first 33 ms session-timer callback tried to refresh the status, threw, and stopped painting. The user saw a button that appeared to do nothing.

The authoritative template now declares the callee first. The generated main, linked-container and floating views share that correction. The regression invokes the actual Start/Stop button handlers and lets real timer callbacks run; it does not stop at calling `cyrusBrushBegin` directly.

Native bounds inspection also found two Amount radio groups extending past a 162-pixel column, colour-picker captions outside the left edge, and an oversized colour swatch after shrinking the floating editor. The shared generator now measures radio-button widths and wraps narrow groups, gives colour pickers their own caption row, and resizes their actual native swatch windows.

## Delivery

| Host | Scatter | Paired Analyzer | Exact receipt |
| --- | --- | --- | --- |
| Max 2026 | [0.78.1 installer](../../dist/Brush_Start_0.78.1_2026-10-10/Max2026/CyrusScatter-0.78.1-Max2026.mzp) | [Analyzer 0.14](../../dist/Brush_Start_0.78.1_2026-10-10/Max2026/CyrusSurfaceAnalyzer-0.14-Max2026.mzp) | [2026 receipt](PACKAGE-2026.json) |
| Max 2027 | [0.78.1 installer](../../dist/Brush_Start_0.78.1_2026-10-10/Max2027/CyrusScatter-0.78.1-Max2027.mzp) | [Analyzer 0.14](../../dist/Brush_Start_0.78.1_2026-10-10/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp) | [2027 receipt](PACKAGE-2027.json) |

Use the installer for the matching Max year and restart Max. Do not load a loose script over an older native module. Installers remain local, ignored `dist/` artifacts; Git contains source and evidence. The normal artist profiles and their open scenes were not changed.

## Qualification

Final counts and exact identities are recorded in [EVIDENCE.json](EVIDENCE.json). The campaign runs in two owned, hidden Max processes with redirected profiles, copied scripts and verified native module paths. No computer use, mouse injection or artist-session mutation is used.

| Check | Max 2026 | Max 2027 |
| --- | ---: | ---: |
| Native Scatter suites | 15 passed | 15 passed |
| Button/callback and layout-no-rebuild assertions | 26 passed | 26 passed |
| Vector integration assertions | 376 passed | 429 passed |
| Passive inspection checks | 6 passed | 6 passed |
| Playback assertions | 835 passed | 835 passed |
| Layout contexts / native rectangles | 36 / 2,168 passed | 36 / 2,168 passed |
| Clipped or overlapping native controls | 0 | 0 |
| Paired Analyzer native core suite | 1 passed | 1 passed |

Shared Python regression: **143 passed**. Generated UI/catalog and generator unit checks pass. Vector assertion totals differ because some assertions inspect every surviving candidate in independently identified receiver fixtures; both hosts run the same scenarios. The final generated script SHA-256 is `bc58822b92b006350ee47d0435117f9e4a79476f23668998be58c0ed9ab27361`.

The test-only `CyrusPrivatePaintProbe.dlx` obtains the public SDK Painter canvas interface from the actual production document. It uses the actual Painter `TestHit` result and delivers `StartStroke`, `PaintStroke`, `EndStroke` and `CancelStroke`. It is not linked into or included in the product packages. This exercises production callback code without claiming physical event delivery or cursor feel.

The button fixture covers main and floating Start/Stop, status refresh, timed session survival, paint/erase, Undo/Redo, cancellation, two receiver-bound areas, Manual publication, Live publication, and receiver-cache reuse. Held/released input is deliberately controlled through the existing script provider in the private fixture, restored afterward. The test verifies that held input defers Live publication and release permits it.

The layout fixture inspects actual native HWND rectangles in 36 contexts per host: all 11 main sections in basic/advanced states; six floating-editor topics at 720×500, 920×650 and 1280×720; all four Layout modes and five Analyzer channels; three display modes with both colour styles; and both Amount modes with density-map settings. It checks clipping and cross-control overlap, excluding empty native caption windows.

The broader vector fixtures cover canonical region union/subtraction, large brushes, per-receiver ownership, feather curves, save/reopen, independent copies, invalid-target failure retention, passive inspection and candidate-cache reuse. Playback regression covers relevant/unrelated animation and retained Point/Proxy/Mesh behavior. The paired Analyzer retains 0.14 and receives its matching SDK build and native core test; full Analyzer renderer qualification is separate.

## Failures retained as evidence

- Delivered 0.78.0 was verified by both installed script and loaded DLL hashes. `start-fix-baseline-2027b/button-diagnostic.txt` reproduces active immediately after the button, undefined-call failure, and stopped after the first tick. The first baseline process exited before readiness; its failed startup receipt is retained.
- `fix-host2026-01` and `fix-host2027-01` confirmed the causal brush fix, then measured 15 clipping occurrences each across the layout contexts. These runs precede the responsive layout correction.
- An initial final-script button run reached Live with the desktop button state reported as held, correctly deferring publication. The fixture's unconditional publication expectation failed. The revised fixture explicitly tests both held and released states rather than overriding the product's deferral behavior. Product source was not changed to make that fixture pass.

Private run directories are under `build/vector-brush-078/`; historical receipts are preserved. Reproduction tools are documented [here](../../tools/vector_brush_078/README.md).

## Cleanup and remaining acceptance

The earlier integration removed production stroke-history storage/evaluation, old per-stroke controls, adaptive triangle tint, old payload decoding and model-owning paint-set conversion paths. Production authoring uses canonical vector regions. Historical reports and the four isolated prototypes remain outside the shipped package; they are comparison evidence, not runtime fallbacks. Existing internal registration identities remain intact.

Physical mouse/tablet strokes, cursor feel, DPI/font rendering, sustained heavy assets, renderer coverage, and installer/restart recovery still require their own acceptance. Native rectangle checks do not certify rendered glyphs or every display scale. Vector painting remains limited to single-valued local-XY terrain/planes; general curved-surface painting is not introduced by this patch.
