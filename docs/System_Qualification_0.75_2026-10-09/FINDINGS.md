# Findings and improvement priorities

## Verified strengths

- Failed generation retains the previous complete placements and source mapping. Invalid radii, cleanup work limits and stale Edit bindings have explicit guards.
- Paint Areas can target different receivers within one layer, combine coverage, survive save/reopen, and retain paint while the receiver is inactive. Model ownership stays at the layer.
- Independent spacing relationships use measured radius/gap clearance and ordered ownership. Source settings survive container parking and re-entry.
- A 100,000-instance navigation witness performs no placement regeneration, Brush work or unchanged-buffer uploads across its tested display modes.
- Main Layout controls, paired transforms and shared views have current native-bound and ownership assertions. Selection is checked separately from generation.

These statements refer to the bounded passing scenarios in EVIDENCE.json, not every possible scene.

## Open product priorities

| Priority | Finding | Evidence / next acceptance |
| --- | --- | --- |
| High | One retained-buffer assertion failed after a mixed UI/legacy sequence | Clean 835-assertion playback, 100k navigation and an isolated repeat pass. The failed sequence reached 601 assertions; added counter diagnostics. Root cause remains unproven. |
| High | Adding/reordering receivers can move existing placements | Earlier receiving-surface study reproduced 7,466/10,000 moved positions after adding surface 21. Current combined sampler is unchanged. Design stable receiver-local generation before promising incremental density. |
| High | 100k Proxy drawing is expensive despite stable caches | Current simple 32-face source witness: median synchronous camera/redraw about 2,227 ms. Optimize drawing only with equal shown geometry and separate upload/draw metrics. |
| High | Brush history and aggregate derived memory remain a scaling concern | Prepared-stroke reuse is implemented; canonical final-region storage, aggregate admission and end-to-end stroke latency remain unfinished. |
| Medium | First cold physical container Move/Undo history remains unisolated | Current scripted group/node movement can pass without reproducing that physical interaction. Preserve it as a separate acceptance gate. |
| Medium | Older multi-set conversion remains unfinished | Retained old sets are not new Paint Areas. Do not silently reinterpret ownership. |
| Medium | Some internal tooltips/catalog vocabulary and historical teaching diagrams still need terminology cleanup | Current guide and capability ownership take precedence; no remote Paint Area authoring is implied. |
| Medium | Complex curved boundaries, high DPI/tablet and long sessions remain underqualified | World-XY spline masks/bands are not surface-following brush regions. Test folded sheets, complex asset pivots, extreme radii, docking and sustained sessions. |

## Performance witness

Max 2027, 100,000 candidates/accepted instances, one 32-face cone, 843 × 741 viewport, 30 camera/redraw steps per display mode after warm-up. Point Cloud submits 500,000 points. Mesh admits all 100,000 simple instances. Whole-process working set was about 3.28 GB; this is not plugin-only memory or VRAM.

| Mode | Median synchronous camera + redraw |
| --- | ---: |
| Preview off | 46.75 ms |
| Point Cloud | 38.95 ms |
| Proxy | 2,227.49 ms |
| Mesh | 405.73 ms |
| Plant centres | 136.04 ms |

Initial explicit update was about 2,614.5 ms. Off/Point differences are noisy host timings, not evidence that drawing improves performance. These are **not presented FPS**, do not use heavy plant geometry, and cannot be compared directly to vendor tests. Raw samples and p95 summaries are retained in EVIDENCE.json.

## Failures encountered during the campaign

1. The first generated binding probe and an older container fixture used top-level local declarations with `fileIn`. Added an explicit scope; this was a test compilation problem.
2. Older container tests directly supplied plain Rectangles, which current container admission rejects. Changed their fixtures to Cyrus Source Container helpers and required a clean publication before checking exact/PFlow output. The old run correctly retained its previous result, which was insufficient for the test's expected two-source mapping.
3. The old Edit-binding test changed the setup-wide surface field. It now changes the actual layer receivers, preserving the intended stale-binding assertion.
4. The first mixed failure sequence reported a Live render-pair mismatch. The clean corrected campaign passed with published `[100, 0]`, bridge `[100]` and no preview errors. Three further fresh pair checks also passed. No product fix was made for this observation; repeat checks are retained rather than assigning an unproven root cause.
5. One combined UI campaign exceeded its 300-second total budget; another bundled all grips plus lifecycle exceeded its 180-second request budget after the three grip-mode reports passed. Remaining scenarios are split into bounded requests. These interrupted hosts are recorded as failed/incomplete and were stopped.
6. A post-UI playback run failed its unchanged retained-buffer assertion after 601 checks. The clean playback and isolated retained repeat passed. This is an unresolved observation, not a demonstrated algorithm correction.
7. The first real Corona save recovery remained pending at a six-second snapshot. A subsequent mixed run captured `interaction_held=true` during a pending IR edit. Analyzer also stopped at an empty initial boundary after its idle checks passed. Both products defer Live work while a mouse button is held; this is a plausible interference source, not a proven explanation for every failure. The final clean run passed 942 Scatter/Analyzer playback assertions and the complete actual Corona lifecycle. Save recovery was observed settled after about 4.36 seconds in that run. No interaction guard was bypassed. This closes the bounded clean lifecycle gate; it does not prove the cause of all earlier failures.
8. The renderer fixture referenced the retired standalone diagnostics rollout. Its export path now uses `statisticsUI.diagnosticsUI_saveReport`. Timeline-isolation tests disable node-event batches; the final ordinary idle/Live campaign explicitly restores them.

Do not erase these observations from the audit or infer a product defect solely from an obsolete fixture. Conversely, do not mark an untested artist gesture as passed because its scripted handler succeeded.
