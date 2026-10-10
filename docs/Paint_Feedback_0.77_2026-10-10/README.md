# Paint feedback 0.77 — 10 October 2026

Baseline: `7ef0e8c264dca5648bbebd7c73a52f8b3031ba54`, branch `codex/workflow-0.75`. Scatter **0.77 / package 0.77.0**, schema **54**, calculation model **CyrusUnified1**. Analyzer remains **0.14** and MCP remains **0.73.0 / closed plan 0.73**. This batch changes paint evaluation and feedback, not receiver sampling or saved stroke semantics.

## Implementation checklist

- [x] Keep receiver-bound strokes as saved intent, including ordered paint/erase, intra-gesture maximum influence and max-union across Paint Areas.
- [x] Cache feedback values and conservative adaptive coverage nodes across committed strokes.
- [x] Keep a fixed pre-gesture coverage value and maximum influence for the active gesture. A verified unchanged derived-dab prefix permits processing only the extension; altered old dabs/settings take the recomputation path.
- [x] Preserve conservative footprint refinement. A small island wholly inside a large triangle must remain visible even if its corners are unpainted.
- [x] Separate approximate floating-point feedback composition from authoritative plant membership. Candidate threshold decisions use conservative residual bounds and finish the original backward evaluation when uncertain.
- [x] Avoid copying the complete document to evaluate a pending stroke.
- [x] Store only the appended stroke in a new gesture's Undo record. Bulk history edits still use their existing whole-document snapshots.
- [x] Publish completed feedback arrays together. Failed evaluation must not mark the revision complete or replace the previous visible result.
- [x] Bound feedback storage and release its caches when the paint session ends.
- [x] Request feedback ticks at 33 ms instead of 150 ms; avoid rebuilding the saved-history list during an unfinished gesture. This is an event-loop interval, not a latency guarantee.
- [x] Bump authoritative/generated UI, native/package metadata and product help catalog together.

## Research decisions

The supplied reports converged on separating saved intent from derived feedback. This implementation uses that principle without replacing curved surface painting with a UV bitmap or changing density semantics. Houdini's public Attribute Paint documentation distinguishes stroke geometry, an active-stroke stencil, baked geometry and cache updates. That supports the architectural separation, but does not establish SideFX's private scheduling or data structures. See the [official Attribute Paint reference](https://www.sidefx.com/docs/houdini/nodes/sop/attribpaint.html).

The existing [Forest/Chaos investigation](../Vendor_Surface_Paint_Research_2026-10-09/README.md) remains behavioral evidence. Vendor cache reuse, GPU brush computation and physical latency are not inferred from it. No vendor binaries were modified or copied into product code.

We chose a persistent version of Cyrus's existing conservative preview subdivision rather than a new texture/atlas format. This keeps the correctness comparison direct, supports curved receivers, and addresses measured repeated work. It still traverses the bounded preview tree; it is not a fully local dirty-tile or GPU paint system.

## Correctness and numerical contract

The native regression compares cached preview geometry with the stateless coverage builder, and feedback weights within `1e-12`. Feedback uses forward composition; last-bit differences from backward composition are allowed only there. All placement paths use authoritative threshold decisions.

When traversing history backwards, accumulated paint is a lower bound and accumulated paint plus remaining transmission is an upper bound. Membership can terminate only when the candidate threshold lies outside those bounds with a conservative roundoff guard. The guard is `64 * double_epsilon * (stroke_count + 1)`; it widens the uncertainty interval rather than accepting approximate coverage. Uncertain queries continue the same arithmetic and ordering as the original evaluator. Tests include exact thresholds and their neighboring representable values, multiple densities, mixed paint/erase, changed historical strokes and curved/occluded geometry.

Cache validity includes the receiver geometry fingerprint, base value, immutable stroke prefix, settings, sample capture frames and the previous revision in which a preview node was visited. Nodes becoming leaves again cannot borrow stale values. Pending dabs do not repeatedly apply strength to previously painted values. Cancellation, Undo/Redo, older edits and reopened scenes can require a cold feedback rebuild.

The cache holds at most **393,216 coverage nodes** (12 times the 32,768 preview triangle budget) and **100,000 feedback anchors per document**. Cache eviction affects work, not saved paint. Existing limits of 1,000,000 derived dabs and 8,000,000 face links still apply. These are count bounds, not a whole-scene byte or Undo budget.

## Evidence and reproduction

Exact results, matched source/native/script identities and remaining acceptance limits are recorded in [RESULTS.json](RESULTS.json), [PACKAGE.json](PACKAGE.json) and `evidence/`. Local disposable profiles and scenes remain under ignored `build/mcp-qualification/paint077*`; no artist profile or original scene was used.

### Measurements

Frozen 0.76 and final 0.77 ran the same owned Max 2027 fixture: a 200×200 plane with 4×4 segments, 1,000 mixed soft paint/erase gestures, active Coverage tint, then ten timed additional strokes. Both produced 832 tint triangles and the same sampled-row fingerprint `8025022206740621175`.

| CPU work | Frozen 0.76 median | Final 0.77 median |
| --- | ---: | ---: |
| Native feedback evaluation | 547.89 ms | **1.36 ms** |
| Scripted dab + feedback refresh | 548.48 ms | **1.41 ms** |

This is about **404× less feedback evaluation time in this deliberately overlapping-history workload**. It is not a general whole-scene speedup. See the raw [0.76](evidence/max-076-comparison.json) and [0.77](evidence/max-077-comparison.json) samples and their separate loaded-host manifests.

The continuous 0.77 fixture refreshed after every gesture: the last 30 of 1,000 committed strokes took a median **1.34 ms** in native evaluation. A subsequent unfinished drag measured **2.44 ms** for dab+refresh at 300 dabs. The first implementation in this batch still took **243.56 ms** there; that experiment exposed the repeated pending-stroke work and led to verified prefix/max-influence caching. The first sampled growing-footprint step at 30 dabs took **10.54 ms**; later sampled steps from 60–300 dabs had a **2.33 ms** median. New preview nodes can still be more expensive than warm nodes. These are not physical pointer or presented-frame measurements.

The [CPU benchmark](evidence/cpu-benchmark.csv) independently compares the stateless builder and cache: approximately 175–186 ms versus 0.38–0.43 ms for overlapping soft history near 1,000 strokes. At 2,048 same-center membership queries, the complete evaluator visited about 2.05 million dabs; conservative decisions visited 6,731 and returned identical booleans. Hard opaque paint already short-circuited and does not have a comparable membership speedup.

### Qualification checklist

| Result | Evidence |
| --- | --- |
| Passed: 16 native suites, including 687,313 new feedback/membership assertions | [Native tests](evidence/native-tests.txt), [source/build receipt](evidence/build.json) |
| Passed: 141 Python tests; generated UI/checks | `build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q` (12.40 s), `build/paint077/generated-final` |
| Passed: 11 active-feedback assertions, pending cancellation, repeated Undo/Redo, Manual publication and save/reopen | [Feedback checks](evidence/feedback-checks.json), [run](evidence/feedback-run.json) |
| Passed: 27 receiver assertions, including Density 20→21 preserving all 10,000 existing full transforms/models/IDs, and Fixed Total retaining 9,524 survivors | [Receiver checks](evidence/receiver-checks.txt) |
| Passed: exact preparation boundary, overflow retention, deletion recovery and Undo/Redo across overflow | [Overflow checks](evidence/overflow-checks.json) |
| Passed: curved plane/sphere painting, Paint Area union, removed-target preservation, UI owner binding, Manual/Live, source containers, spacing, Relax, Analyzer and Edit regression | [26-step host campaign](evidence/host-campaign.json) |
| Passed: 942 playback assertions | [Playback](evidence/playback.txt) |
| Passed: Corona 15 production-render smoke, 100 placements, preserved publication epoch | [Render](evidence/render-check.json) |
| Passed: both package manifests/hashes match runtime-tested payloads | [Package receipt](PACKAGE.json) |

An initial broader fixture stopped on its old `0.76` version assertion; the assertion was updated to require `0.77` and the final campaign passed. The baseline comparison launcher also needed an explicit global MAXScript function declaration before invoking a just-loaded fixture. These harness corrections did not remove behavioral assertions. The early long-drag measurement is retained as evidence of the implementation issue fixed during this batch.

### Local installers

- [Cyrus Scatter 0.77.0 for Max 2027](../../dist/Paint_Feedback_0.77_2026-10-10/Max2027/CyrusScatter-0.77.0-Max2027.mzp)
- [Matching Cyrus Surface Analyzer 0.14](../../dist/Paint_Feedback_0.77_2026-10-10/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp)

These ignored local packages contain the qualified payloads; installer execution itself was not repeated. Neither was installed into the artist profile. Follow the [installation guide](../Max_2027_Installation.md) and restart Max for a matching script/native set. Source-only Git does not include installers, private scenes or build binaries.

### Reproduce

1. Generate/check UI using the [agent workflow](../AGENT_WORKFLOW.md).
2. Run `python tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/<fresh-run>` and the Python suite.
3. Build [the CPU benchmark](../../tools/procedural_lab/brush_feedback_benchmark.cpp) against that Release library. It checks equivalent topology/weights and candidate membership while timing the stateless and cached paths on the same workload. This deliberate overlapping-history stress is not a whole-scene performance prediction.
4. Start an owned redirected Max 2027 host with the complete matching native/script set. Load `Max_Layer_Regions_074.ms`, then [Max_Brush_077.ms](../../tools/procedural_lab/Max_Brush_077.ms), and call `B77Feedback()`. It tests visible tint, 1,000 committed gestures, 300 pending dabs, passive redraw, Manual publication, cancellation, Undo/Redo and save/reopen.
5. [Max_Brush_077_Compare.ms](../../tools/procedural_lab/Max_Brush_077_Compare.ms) runs the same late-history workload against frozen 0.76 and 0.77 in separate owned hosts. Check both loaded payload manifests before comparing results.
6. Run the receiver, paint-area, preparation overflow/recovery, Manual/Live, source, Edit, layout/Analyzer, playback and Corona regression campaign. Historical fixture version assertions are explicitly adapted to 0.77 without removing behavioral checks.

## Remaining acceptance

- Physical mouse/tablet input-to-presented-feedback latency and sustained artist sessions remain unmeasured. Scripted host timing includes the stated calls, not operating-system input delivery or presented FPS.
- Very long active gestures still validate/resample and prepare their growing dab data; this change removes repeated feedback evaluation of the verified prefix, not all prefix preparation work.
- New preview nodes, older-history edits and cold reopen can replay history. Dense receivers, widespread painting, many Paint Areas and whole-scene/peak memory require larger stress tests.
- The tint draw path still submits GraphicsWindow triangles. No retained tint buffers or GPU brush compute were introduced.
- A 33 ms requested timer can be delayed by Max, scene evaluation, rendering or redraw. Live placement publication remains separate from active-gesture feedback; Manual plants wait for Update.
- Earlier combined-sampler scene/Edit migration limitations from 0.76 remain. 0.77 adds no new stroke serialization or receiver generation format.
- Max 2026 runtime, installer execution, physical UI interaction and release certification are not covered by this campaign.
