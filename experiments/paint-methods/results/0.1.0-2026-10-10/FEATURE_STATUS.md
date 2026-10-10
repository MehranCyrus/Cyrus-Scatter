# 0.1.0 feature and gate status

This matrix maps the [original test contract](../../docs/TEST_PLAN.md) to actual initial evidence. **PARTIAL means the row is not certified.** PASS applies only to a named tested slice. Unsupported domains are N/A; untested cases remain NOT RUN. The [report](README.md) contains identities, timings and failures.

## Contract coverage

| ID | Initial result | Evidence and remaining work |
| --- | --- | --- |
| I01 | PARTIAL | Native swept/miss-gap tests, three screen-ray callback dabs per method and Start/Stop passed. SDK radius value and callback inside/outside probes now pass all four. Four event rates, physical drags/re-entry and cross-unit calibration incomplete |
| I02 | PARTIAL | Window close/shutdown and deleted receiver suspension passed. Escape, selection change, repeated Start and exhaustive Painter preference restoration not qualified |
| H01 | PASS tested hard slice | Analytic disk oracle, erase hole, swept union/chronology and native exact state comparisons; A/B/C/D |
| H02 | PARTIAL | Twenty-four growing islands and complete >32,768-triangle preview retained prior sampled coverage. Exact artist letters/physical long drawing still open |
| H03 | PARTIAL | Overlap and growing traces at 1/10/100/1,000 gestures, ten CPU repetitions; 10k and physical feedback not run |
| H04 | PARTIAL | Growing area and second large region checked. Separate controlled path-length sweep remains open |
| H05 | NOT RUN | Thousands of islands, sawtooth borders and pathological narrow repeated cuts |
| H06 | PARTIAL | Independent variable-radius sweep oracle and large preview guard; extreme range/long physical gesture and allocation limits open |
| S01 | PARTIAL; A N/A interior opacity | B/C/D center strength and separate-gesture accumulation pass. Equivalent event-rate/soft erase sweeps not fully qualified |
| S02 | NOT IMPLEMENTED | Vector inner/outer fade, composed holes/exclusions and density semantics |
| G01 | PARTIAL | Two-triangle sub-face detail and reversed-diagonal seam regression pass. Dense equivalents/mixed-size seam error not qualified |
| G02 | FAIL freeform fold gate | A/B explicitly reject sphere/fold domain. C/D sphere paint/erase pass but connected-fold probe returns 1 on unintended sheet. Sloped wall/full backside campaign open |
| G03 | NOT RUN | Nonuniform/mirrored scale, large origin and unit sweep |
| G04 | PARTIAL / deferred follow | File load rejects changed geometry; runtime geometry/transform changes suspend. Deformation following and topology rebind not implemented |
| R01 | PARTIAL | 21 independent receiver documents and deleted target inactivity pass. Remove/restore identity, reorder and reuse-counter qualification open |
| R02 | PARTIAL | Explicit named receiver-bound regions exist. Include/Exclude composition, duplicate-instance identity semantics and candidate deduplication not implemented |
| U01 | PARTIAL | Dedicated gesture Undo/Redo, Cancel, Clear and exact external save/load pass. Max Ctrl+Z, embedded scene save/reopen, cloning and receiver link restoration not implemented |
| V01 | PARTIAL | Boundary/fill/sample generation and complete publication pass. Numeric outline error/toggle combinations/visual inspection not fully qualified |
| V02 | PARTIAL | Scripted redraw did not increase CPU preview-build count. No retained GPU upload or presented orbit/pan/zoom qualification |
| V03 | NOT IMPLEMENTED | Production Manual/Live scheduling and asynchronous successors; lab is synchronous |
| B01 | PARTIAL | Invalid hit and complete-preview refusal preserve paint. Active publication peak, allocation/worker failure and cancellation latency open; no workers in current lab |
| P01 | PARTIAL | Ten independent CPU repetitions plus one Max campaign. Five-cold/ten-warm host protocol, meaningful callback tails and physical presentation timing open |
| P02 | PARTIAL | Current/history logical accounting and exact file roundtrip. Actual allocation, peak/plateau and long clear cycles not qualified |
| A01 | NOT RUN | Artist physical trials and useful instanced plant samples; current display is diagnostic coverage only |

## Window control inventory

All four generated windows compile and open; each exposed `addReceiver`, `beginPainting` and `endPainting` binding was called in Max and each final extracted package passed its launcher smoke. **No physical button clicking was performed.** Most checks below exercise underlying native APIs; they do not certify the click/file-dialog path.

| Exposed control | Related tests | Evidence / limitation |
| --- | --- | --- |
| Pick receiver / new region | R01/R02/I01 | Rollout binding called, native create tested on plane/21 receivers; actual picking gesture not run |
| Active region list | R01/R02 | Independent region APIs tested; list-selection handler not physically exercised |
| Name | R02 | UI label edit implemented; renaming handler not exercised; name is transient and not part of `.plab` payload |
| Paint precision / pixel size | G01/H06/P01 | Native tests at 2 and benchmark at 5; fixed on creation; UI edit/range extremes not fully tested |
| Paint / Erase | H01/S01 | Hard/erase APIs all four; sphere C/D; UI setting transfer by start/stop binding |
| Radius | I01/H06/G03 | Native disk/variable-radius oracle, scripted callback ray hit and SDK setter/getter/footprint calibration pass; physical ring and cross-unit calibration incomplete |
| Strength / Soft edge | S01 | B/C/D native/host soft center tests; disabled for A. Full gradient/event-rate equivalence pending |
| Start painting / Stop | I01/I02 | Rollout functions and native Painter start/stop exercised in host and four final packages |
| Undo paint / Redo paint | U01 | Underlying API and exact native saved-state equivalence pass; dedicated history, no Max Ctrl+Z |
| Clear region | U01/P02 | Underlying API passes; long memory plateau not measured |
| Boundary | V01 | Underlying generation passes; A canonical border, B/C/D derived 50% contour; physical checkbox path not tested |
| Fill | V01/B01 | Underlying generation, large complete coverage and guard pass; visual appearance not qualified |
| Coverage samples | V01 | Underlying nonzero weighted sample generation passes; these are display cells, not stable generated plant IDs |
| Display step | V01/B01/P01 | Preview at several steps, 300k-cell refusal preserves paint; UI range extremes not exhausted |
| Refresh preview | V01/V02 | Underlying refresh and CPU cache counters exercised; GraphicsWindow drawing has no proven GPU retention |
| Save region / Load region | U01/G04 | Underlying external file APIs/roundtrip tested; actual file dialogs not automated. Export required before closing |
| Status timer / stats | P01/I02 | Window opens, status API returns counters; long idle/timer lifetime not separately stressed |
| Close window | I02/U01 | All four windows closed and final package processes shut down cleanly; close discards unexported data |

## Implementation gaps that matter before selection

- D lacks the planned surface-distance propagation. Its fold failure disqualifies a general freeform claim.
- C stores anchors but does not follow deforming geometry; receiver edits suspend it like the other trials.
- The shared preview rebuilds complete CPU geometry. Dirty chunks, retained Nitrous buffers and physical presented timing remain separate work.
- Paint-state/history accounting is logical and incomplete as a peak-memory bound. B/D use shared tiles; C copies history/index state. No method has passed long-session memory qualification.
- Full Include/Exclude composition, spline interchange, vector fade, stable candidate-cloud IDs, instanced plants, automatic receiver restoration and native scene persistence remain absent.

These gaps are explicit prototype scope, not reasons to keep the current Cyrus brush or choose a fast failing candidate.
