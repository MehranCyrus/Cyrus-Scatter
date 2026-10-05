# Current outcome — 5 October 2026

The authorized UI/correctness and visual source-container implementation is complete within the documented 0.7 contract and has passed fresh private Max 2027 regression. Licensing has advanced to a tested native/local foundation; it is **not a complete commercial licensing system and is not enabled in the ordinary build**. Product metadata remains 0.7.0, serialization is 53, and existing scene class IDs are preserved.

Read [implementation evidence](IMPLEMENTATION_RESULTS.md), [the source evaluation trace](EVALUATION_TRACE.md), [source-container behavior](SOURCE_CONTAINERS.md), [licensing results and limits](../licensing/NATIVE_FOUNDATION_2026-10-05.md), then [the remaining implementation roadmap](IMPLEMENTATION_ROADMAP.md). The original [independent review](README.md) retains pre-fix findings and reproductions rather than rewriting history.

The subsequent user-authorized [Git backup checkpoint](BACKUP_CHECKPOINT.md) preserves this implementation, tests, documents, curated evidence and preview-launcher source. It does not implement the newly proposed floating layer editor or turn this development checkpoint into a release.

## Completed fixes and feature

The five independently reproduced P1 problems were fixed: stale PFlow publication, premature Manual exact evaluation, in-place density-map invalidation, disabled saved radius bindings, and unbounded cleanup work. The P2 native scrolling defect was fixed. Real pointer testing verified one/two/three-column width changes, nested scrolling and automatic spacing entry in Manual/Live. Whole layers flow between native pages; their inner sections stay together. The UI code remains native; no custom web layout was introduced.

Source containers are ordinary Rectangle splines with global/layer/paint-set ownership. Their local XY bounds test source pivots, ignoring height. Moving a registered source out parks it; reentry retains source-row settings and identity. Settings belong to each owner that uses the model. Manual retains the published result until Update; Live responds to scene-event batches. New enrollment follows the existing saved-Edit binding guard. This is a source-model organizer; receiving surfaces and Brush still determine where plants grow.

The current default parks the source's candidates without reallocating its weight; this was the stated assumption while the optional preference remained unanswered. Other candidate identities/transforms stay stable. Collision winners and bounded accepted-target replenishment may legitimately change when blockers disappear. Multiple rectangles and transformed/parented/mirrored rectangles are covered. Rounded/modified arbitrary shapes are rejected. Limits are 32 rectangles and 1,024 registered source rows per pool, with ten total populations in the existing layer system.

## Handoff requirement reconciliation

| Handoff requirement | Current result and evidence boundary |
| --- | --- |
| Procedural top-to-bottom order | Native solver and Max core fixtures preserve stable owner/candidate ordinals, allocation identity and deterministic prefix replay. Protected authored plants are an explicit exception to ordinary winner order. |
| Layer ownership | Layer defaults and global scheduling/receivers/display remain separate. UI copy/reorder/reentry/binding tests pass. No second independent settings model was added. |
| Paint sets | Enabled weights share a layer budget; sources and coverage remain distinct. Ten total populations is still the limit. |
| Three collision scopes | Self, sibling-set and layer rules remain independent, including explicit disabled overrides. Native oracle tests cover the solver; runtime fixtures cover binding and publication. |
| Adjustable radius | Source footprints, conservative transform scaling and saved per-instance overrides remain. Disabled/zero-input bindings no longer break unrelated layers. Radius remains a spacing approximation, not mesh collision. |
| Coverage / gap filling / replenishment | Separate support-field complement, spacing gap filling and bounded candidate-prefix replacement remain explicit. Shortfall is reported; it is not a packing proof. |
| Procedural Brush | Flat/curved static surface, history, save/reopen and Undo are tested. Topology changes retain the existing guard; geodesic/deforming-surface rebinding is not implemented. Direct Dab now propagates failed stroke callbacks. |
| Areas and transforms | Existing include/exclude, density and randomization paths remain; density-map/submap edits invalidate their affected preparation. Procedural Random/Clusters are supported; Line/Analyzer assignment, point Relax and unprojected Brush movement retain documented gates. |
| Authored edits | Stable edited/clone IDs, source/radius bindings and protected reservations remain. Source parking filters edited candidates without forgetting their stored edits. New source enrollment with saved edits is explicitly guarded. |
| Cache correctness | Navigation/UI reuse candidate/prepared/publication buffers. All layers stage before publication; failure retains the preceding complete epoch and source mapping. Cleanup shares the 50-million-neighbor budget with solve/retry work. |
| Manual / Live | Exact, PFlow and Bake consume the same completed Manual publication; explicit Update advances it. Live spacing and real delayed source events update without candidate rebuilding where the recipe is unchanged. |
| Viewport performance | Retained Mesh/Point code matches the original committed implementation. 20k/100k and fresh paired container/control runs show no navigation-triggered generation, Brush work or buffer rebuild/upload. Synchronous timings are not presented FPS; Proxy stalls and complex-asset limits remain. |
| Viewport visibility | Hidden owners retain final-output/collision participation; disabled owners stop participating. Existing core/binding fixtures cover the distinction. |
| Native UI | Native column widths, expansion, scrolling, automatic spacing and lifecycle tests pass in Max 2027. Max 2026 runtime, other DPI arrangements and broad accessibility coverage remain unqualified. |
| Statistics | Published epoch/count/shortfall remain separate from pending work. Cleanup work now counts toward the shared bound. Failed successor tests retain exact previous rows. |
| MCP | 66 offline tests pass. Policy 3 remains read-only; recipe inspection adds pool references without doing membership scans. Closed plan schemas 1/2 and their mutation guards are preserved. This is not full procedural layout import/export. |
| Future ML | No model, training pipeline, learned inference or automatic upload was added. Future recipe proposals can use explicit versioned interfaces; model behavior is not invented. |
| Compatibility/release | Matching SDK 2026/2027 builds pass 13 ordinary native suites each; fresh Max 2027 load and runtime campaign pass. Save/reopen/copy/Undo preserve the new fields. Old MZPs remain older artifacts; no new installer is presented as qualified. |
| Engineering simplicity | Pure numeric solver and retained display are preserved. No speculative GPU compute or general dependency framework was added. Generator rewrite coupling, broad explicit-Update invalidation, full candidate-pool memory peaks and projected movement triangle scans remain measured optimization candidates. |

## Final ordinary candidate

The [final worktree inventory](evidence/final-worktree.json) records HEAD, branch, tracked/untracked status and individual source/document hashes. It is an inventory, not a passing-test certificate; ignored SDKs, binaries and private scenes have separate run receipts. The original handoff inventory is retained alongside it. No commit was made to hide or collapse this local scope.

`build/qualification-07-20261005/final01/` contains the frozen ordinary build for both SDKs. Both native suites passed; 66 MCP tests passed. The first runtime attempt stopped at the private-UI profile-name guard before that fixture ran. It was a harness naming error, not an accepted UI pass.

`final02/` reuses those binaries after verifying all compiled-source hashes, and freezes the corrected fixture/launcher. Its fresh private profile passed core, binding, UI, adversarial review regressions, container acceptance/edge/output tests, real delayed Live events and 100k navigation. All four loaded native modules were verified against expected paths/hashes before the campaign. Development-authority primitives were absent. The generated script SHA-256 is `4f88237f486d49e067a6f3d65a28d46dea457de15cd4aa65c1ecd4501d11fd33`.

No production fixes are inferred from old MZPs or previous agent claims. At runtime qualification, no artist scene/profile installation, commit, push or external publication had been performed; the later source-only Git backup is recorded separately above. Private test scenes, DLLs and full logs remain in ignored workspaces; compact source/build/runtime receipts are retained beside this report.

The final licensing experiment separately passed real activation, offline expiry, cold reopen/render, Brush expiry during a gesture, shared renewal and automatic local refresh/checkpoint across two Max 2027 processes. Both hosts joined their maintenance worker on normal shutdown. This covers the native-owned amount/seed slice, actual CS Edit mutations and Brush history gates; it does not authorize enabling the still-incomplete product-wide boundary. Both SDK configurations passed the 1,120-assertion core campaign, and the final native integration candidate passed 22 groups per SDK. Failed intermediate attempts and the narrower test limits remain in the licensing report.

## Remaining priorities and acceptance

1. **Whole-product licensing is a release blocker before enabling enforcement.** Settle B07 dependency/migration/bake policy and B08 offline transfer accounting from the reproduced examples. Extend native ownership to all procedural layer/source/container authoring, preserving IDs and cold saved evaluation. Direct calls, setters, SDK callbacks, MCP and failure-before-cleanup must obey the same transaction.
2. **Complete customer authority and recovery.** The memory-only test issuer is not an account or seat service. Implement maintained authentication, transactional assignments/idempotent issuance, signer custody, recovery and audit under approved policy. Exercise last-seat races, tenant isolation, signer failure, replay, lost-machine and outstanding offline grants before a customer pilot.
3. **Qualify the supported product configurations.** Run Max 2026 UI/scene tests, more DPI/layout cases, representative third-party assets/renderers, cold render workers and mixed-module rejection. Then build matching installers, sign and qualify them in clean disposable profiles before artist installation/publication.
4. **Optimize only demonstrated limits.** Measure real large-scene registration and peak old/new publication memory, Proxy stalls and projected movement. Preserve output equivalence and zero navigation rebuild/upload; do not select GPU compute solely from synchronous redraw time.

These remaining items are explicit unfinished work, not implied capabilities or a 1.0 readiness claim.
