# Independent review — Cyrus Scatter 0.7

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

5 October 2026. This records the **pre-fix** local implementation, not release qualification. The user subsequently authorized fixes, source containers and licensing work. Read [the current outcome](CURRENT_OUTCOME.md), [implementation evidence](IMPLEMENTATION_RESULTS.md) and [remaining roadmap](IMPLEMENTATION_ROADMAP.md) for that continuation; these original findings and receipts are retained.

## Scope and provenance

HEAD is `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`, branch `codex/planting-groups`. Initial scope: 48 tracked modifications and 187 untracked files. All 207 handoff source fingerprints match. [Inventory](evidence/initial-inventory.json) includes individual SHA-256 values, status and existing package payloads. Existing MZPs contain an older script/native pair and were not used to qualify current source.

Fresh SDK 2026 and 2027 builds both passed 13 native suites; MCP pytest passed 64 tests. The generated script check passed, with SHA-256 `dee0f3f85e912dbe15cda10eb62b3d098f431f6c547d7cf6acf71c64a0d583ca`. This check does not prove MAXScript compilation. The same script loaded in a fresh private Max 2027 process with the independently built DLLs; [loaded-module identities](evidence/loaded-modules.json) distinguish that process from the artist session. Max 2026 runtime remains untested.

No artist scene/profile was modified. Runtime diagnostics use disposable scenes under the ignored `build/mcp-qualification/procedural07-ui-independent-20261005` folder. Private connection credentials are not review artifacts.

## Findings, ordered by severity

### P1 — render transport can retain the previous procedural publication

`AminScatter/tools/ui/templates/pflow.ms:19`, `:104`; `AminScatter/tools/ui/procedural-policy.cjs:33`. Policy 3 moved the Manual revision to the controller, but the PFlow key still watches the global revision. It also omits controller-owned procedural pair rules. A 100-instance transport stayed at 100 after an explicit Update published 150; preRender did not rebuild it. A Live inter-layer rule similarly changed accepted rows without changing the render key. See `independent-render-transport.json` and `independent-render-probe.json` in evidence.

Smallest fix: include the published controller epoch and relevant Live recipe changes, then verify actual PFlow data after Manual Update and Live scoped-rule edits. Avoid regenerating placements merely to poll a signature.

### P1 — exact output evaluates pending Manual edits

`AminScatter/tools/ui/templates/planting-model.ms:147`. Cached rows are consumed only during temporary `groupDisplayOnly`; normal exact consumers call evaluation. Changing amount from 150 to 175 and reading exact placements, without Update, published 175 and advanced the epoch. This violates the stated Manual contract even when the viewport was still showing the completed result. Source-list/index coherence also needs coverage when consuming an older publication.

Smallest fix: give exact consumers an explicit published-snapshot path in Manual, including its source mapping. A cold scene needs a documented initial reconstruction rule. Keep legacy policy behavior separately testable.

### P1 — edits inside an existing density map are absent from cache dependencies

`AminScatter/tools/ui/templates/brush-integration.ms:36`; `procedural-evaluation.ms:26`, `:108`. The key records the map reference, not changes within it. With the same Checker map changed from black to white, 500 candidates remained at zero after event-loop return, Live redraw and exact evaluation. Explicit Update produced 500. The prepared-cache hit bypasses the otherwise uncached texture sampling. See `independent-dependency-probe.json`.

Smallest fix: track texture/reference change notifications and invalidate the affected preparation. Reinstall nonpersistent watchers after load/Undo. Test submaps and replacement as well as direct color changes; navigation must not resample textures.

### P1 — disabled saved radius bindings can stop all layers after reopen

`AminScatter/tools/ui/templates/procedural-evaluation.ms:135`; `procedural-model.ms:175`. A disabled leaf skips preparation but still validates radii against an empty transient binding. Save a setup with an overridden instance radius, disable that layer, and reopen: the enabled second layer fails too. The test retained its override and produced counts `[0,20]` before save, but after reopen threw the binding guard and published no epoch. See `independent-disabled-radius.json`.

Smallest fix: skip binding/radius work for nonparticipating empty inputs, preserve saved overrides, and retain the guard when the owner is reenabled. Test layer and child-set disabling, zero quota, reopen and Undo.

### P1 — cleanup is outside the procedural work limit

`AminScatter/src/procedural.cpp:119`; `AminScatter/src/final.inc:9`. Cleanup visits all nearby pairs without charging the solver's 50-million neighbor-work limit. Dense coincident populations took 13.8, 54.6, 197.4 and 745.9 ms at 2k, 4k, 8k and 16k respectively, despite setting the plan limit to one and reporting zero neighbor visits. This is approximately quadratic synchronous host work; replay can repeat it. See `cleanup-probe.csv` and the diagnostic fixture retained under `build/review-07-20261005`.

Smallest fix: charge cleanup visits to a shared bounded work budget and fail before publication when exhausted. This is not evidence that GPU compute is needed. A more efficient connected-components algorithm requires separate equivalence/performance evidence.

## Requirement coverage

Follow-up pointer testing during implementation reproduced a **P2 nested scrolling defect** in `AminScatter/src/rollout_scroll.cpp`: three-column layout works, but scrolling inside the layer did not scroll its column, whereas the outer column edge did. All three layer binding counts were zero (`evidence/fix1-scroll-bindings.json`). The aggregate rollup HWND is not an ancestor of pages in every column. `IRollupPanel::GetRollupWindowHWND()` also returned null on this Max 2027 Qt host. The correction checks panel ownership and resolves the page's actual parent per gesture; pointer validation is recorded separately from the original review.

| Requirement | Independent assessment at this snapshot |
| --- | --- |
| Ordered evaluation and identities | Sound core: stable candidate ordinals, owner IDs, deterministic prefix replay, explicit ordinary winner order. Native exhaustive oracle compares all three collision scopes. Protected edited instances intentionally reserve space even against earlier ordinary candidates. |
| Layer ownership / paint sets | Shared layer budget and defaults are explicit; per-set sources and coverage remain distinct. UI event/lifecycle fixture passes copy, reordering, removal, inheritance and peer preservation. Ten **total** populations is a hard limit, not ten layers each with ten sets. |
| Collision scopes / radii | Independent self, sibling and layer rules; explicit disabled pair overrides; strict-distance test allows equality. Conservative transform bound handles shear/mirroring. Radius is a footprint approximation, not triangle intersection. Saved disabled bindings have the defect above. |
| Coverage / filling / replenishment | Coverage complement is evaluated once at support anchors. Between-plants requires a nonzero applicable spacing rule. Refill is bounded and shortfall is explicit. Relax and Line/Analyzer assignment are deliberately gated on policy 3. |
| Brush / areas / transforms | Existing flat/curved Brush and binding runtime acceptance passed independently. Movement/source lift follow the support-anchor contract. Density-map invalidation is broken. Geodesic painting and deforming-topology rebinding are not implemented promises. |
| Authored edits / persistence | Native Edit transaction supports rollback, stable clones and protected zero-quota edits. Runtime acceptance includes source/receiver replacement, failure, selection rollback and save/reopen. Disabled saved radii expose an uncovered case. |
| Atomic publication / caching | Core stages all layers/display before committing. New failure preserves the previous preview. Exact output and render invalidation have the defects above. Explicit Manual Update currently invalidates candidate/prepared work broadly, including for rule-only changes. |
| Manual / Live | Automatic spacing events pass scripted event tests. Exact output violates Manual scheduling. Actual pointer spinner-drag grouping and Live coalescing remain to qualify. |
| Viewport performance / visibility | Retained point/mesh implementations match the committed baseline. Hidden owners retain solve participation; disabled owners do not. Fresh navigation benchmarks are still required after fixes. Existing redraw timings are synchronous work, not presented FPS. Proxy stalls remain a known limitation. |
| Native UI | Current helper hides unused pages and initially orders active pages correctly in Max 2027; the intermediate test's failure does not reproduce on this pair. Lifecycle/event acceptance passes. Real width changes, one/two/three-column scrolling and focus are unverified: computer input attempts were stopped by concurrent-user-input detection. Whole layers flow as pages, not individual subsections. |
| Statistics | Distinct quota/accepted/shown/shortfall and published epoch exist. Work accounting omits cleanup. Last-publication versus pending/error semantics need regression coverage at every consumer. |
| MCP | 64 offline tests pass; policy 3 mutation guard precedes transactions. Closed schemas 1/2 remain unchanged. Policy 3 exposes recipe/diagnostics; do not imply a full policy-3 transform export or arbitrary UI mutation API without a demonstrated implementation. |
| ML | Future proposal only. No trained model, learned inference pipeline or automatic uploads were established. |
| Compatibility / delivery | Scene class IDs preserved, 0.7.0 metadata, serialization 52. Fresh SDK builds pass; private Max 2027 load passes. Old packages do not qualify current source; Max 2026 host remains unqualified. |
| Simplicity / bounds | Preserve pure native solver and retained display. Main risks are generator string-rewrite coupling, duplicated derived state, broad invalidation, full candidate-pool allocation and old/new publication memory peaks. Projected movement also scans receiver triangles per candidate. Optimize measured paths before adding a generalized graph or GPU framework. |

## Evidence quality and limits

Runtime core, binding and UI scripted acceptance passed, but the additional adversarial fixtures found failures those passes missed. Existing placement fingerprints compare position/source and do not fully prove rotation, scale, ID or source-binding equality. Future regression comparisons should include complete row transforms and identities. Test counts and source inventories are not correctness certificates.

Native UI ownership/category calls were checked against the [Autodesk rollup interface](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_i_rollup_window.html) and [panel members](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_rollup_panel-members.html). The returned command-panel rollup follows the [Interface contract](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_interface.html). These contracts support the implementation shape; they do not replace pointer-level host testing.

Licensing was originally preserved outside procedural review. The later implementation authorization includes it. Existing laboratory signature tests demonstrate the verifier, not a production native authoring boundary, customer service or offline-transfer policy. Its existing roadmap remains authoritative for those milestones.
