# Drawing responsiveness — 0.78.2

The integrated vector brush was doing unnecessary panel layout work at drawing cadence, and border preparation depended on a script timer. This patch removes the repeated layout and prepares border feedback from the production Painter callbacks. Schema 55, vector geometry, saved contours, feather curves and candidate generation are unchanged.

## Measured cause and changes

The 0.78.1 control run measured each stage separately over a continuous 300-point path on a 200 × 200 plane with 2,048 faces and a Manual layer with 5,000 candidates. The painting panel was open. Panel refresh alone cost 24.79 ms median, compared with 0.29 ms for authoring the region. The generated status delegate rearranged the whole panel on every region revision, even though its text remained “Brush active”.

Status now reports whether its text changed. The generated main, container and floating views only recalculate their layout when that change requires it. Start/Stop/error transitions still update their status and row heights.

The old continuous SDK callback test authored 1,000 points but left zero cached border segments until the script timer ran. The isolated vector prototype refreshes from its Painter callback. Cyrus now does that too: it prepares feedback after an input-processing interval of at least 16 ms, requests redraw, and starts the next interval after that work finishes. EndStroke flushes the final border. No input samples are discarded, and the complete scene population is not recalculated during the gesture. The idle timer remains as a safety net, and skips a duplicate redraw when native feedback is already current.

This addresses a plausible source of fast-input delay: Windows gives [WM_TIMER lower priority than queued input](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-timer). The scripted test deliberately withholds message pumping; it demonstrates feedback freshness without timer delivery, not physical event latency. Native redraw requests made within one MAXScript invocation can be deferred by Max. Neither those requests nor the requested 16 ms interval prove 60 FPS.

## Max 2027 comparison

Same generated workload; times are synchronous CPU stages in milliseconds. These are one controlled run per build, not a statistical claim about all scenes.

| Stage | 0.78.1 median | 0.78.2 median | 0.78.1 p95 | 0.78.2 p95 |
| --- | ---: | ---: | ---: | ---: |
| Region authoring | 0.292 | 0.251 | 0.533 | 0.480 |
| Border preparation | 5.896 | 5.428 | 11.454 | 10.410 |
| Panel status/layout | 24.789 | 0.273 | 34.221 | 0.910 |
| Synchronous redraw | 8.946 | 7.301 | 12.462 | 10.246 |
| Combined update | 39.590 | 13.323 | 55.062 | 21.337 |

The combined update is about 2.97× faster in this fixture. Border calculation itself was not rewritten; its small timing variation is not attributed to an algorithm improvement. The 1,000-point SDK path produces intermediate cached borders while the stroke remains active, before EndStroke. The final flush is current, so a subsequent refresh does no preparation. Cancelled continuous erasing preserves the placement fingerprint. Manual population epochs and receiver candidate-build counts stay unchanged during authoring.

Max 2026's final 0.78.2 run measured 15.30 ms median / 23.28 ms p95 for the combined update, including 0.35 ms median for panel status. There is no 2026 baseline comparison in this campaign. The screen-space callback path can quantize differently between hosts; its contour-vertex counts are not an equal-geometry cross-year benchmark.

Raw measurements and exact identities are kept under `build/vector-brush-078/speed-baseline-2027` and the final `speed-host*` folders. Reproduce with [responsiveness.ms](../../tools/vector_brush_078/responsiveness.ms) and [summarize_drawing.py](../../tools/vector_brush_078/summarize_drawing.py); the [private-host instructions](../../tools/vector_brush_078/README.md) apply. The callback probe is test-only and is excluded from installers.

## Qualification and delivery

Use the matching installer and restart Max; do not combine a new script with old loaded modules.

| Host | Installer | Exact receipt |
| --- | --- | --- |
| Max 2026 | [Scatter 0.78.2](../../dist/Brush_Responsiveness_0.78.2_2026-10-10/Max2026/CyrusScatter-0.78.2-Max2026.mzp) | [2026 receipt](PACKAGE-2026.json) |
| Max 2027 | [Scatter 0.78.2](../../dist/Brush_Responsiveness_0.78.2_2026-10-10/Max2027/CyrusScatter-0.78.2-Max2027.mzp) | [2027 receipt](PACKAGE-2027.json) |

The package directories also contain the unchanged, paired Analyzer 0.14 installer. Its native core qualification is reused from the matching 0.78.1 campaign; no new Analyzer or renderer certification is claimed. Installers remain local ignored artifacts.

Both years pass 15 native suites, 7 drawing regressions, 26 button/callback assertions, 6 passive inspection checks, 835 playback assertions, and native layout validation over 36 contexts / 2,168 rectangles. The vector suite additionally covers feathering, save/reopen, receiver ownership, failure retention and cache reuse; exact per-candidate assertion totals are in the receipts. Shared Python tests: 143 passed. Generated UI/catalog and generator unit checks pass. [EVIDENCE.json](EVIDENCE.json) preserves the measured summaries, exact identities and result hashes.

No artist profile is installed or changed; no computer use or pointer injection is used. Physical fast strokes/tablets, very complex accumulated borders and sustained heavy scenes remain artist acceptance gates. The existing local-XY terrain restriction is unchanged.

## Investigation receipts

- The first 0.78.2 test incorrectly expected unchanged status immediately after Start, before the first active-status refresh. The fixture now performs the transition before checking that repeated status refresh is a no-op.
- An initial callback assertion expected synchronous overlay draw counts from a long MAXScript call. Max deferred those draws despite preparing the border. The private driver now leaves the stroke open so the test directly checks prepared borders before EndStroke, and does not label this a presented-frame measurement.
- Initial Max 2026 private starts stalled before loading the Cyrus modules or executing the bootstrap. Their folders are retained. Only verified owned processes were stopped; ordinary artist Max sessions were preserved.
- Autodesk's documented [`-silent` startup option](https://help.autodesk.com/cloudhelp/2026/ENU/3DSMax-Basics/files/GUID-BCB04DEC-7967-4091-B980-638CFDFE47EC.htm) allowed the isolated 2026 host to reach bootstrap. The launcher restores both Silent and Quiet modes before testing. An initial suite with Quiet still enabled is retained under `startup-quiet-pass`; the final responsiveness and full suite were repeated with both flags false. The blocking startup dialog's contents were not inspected.
