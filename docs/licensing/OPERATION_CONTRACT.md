# L0 operation contract and native ownership coverage

**Updated 2026-10-05 — provisional contract; ordinary product enforcement remains off.** Complements the [October 2 static audit](CODEBASE_AUDIT.md) and [roadmap](ROADMAP.md). The October 4 table below is retained as the pre-ownership evidence baseline. Its 69 declarations are historical inventory, not current security coverage.

## October 5 implementation delta

The [native foundation](NATIVE_FOUNDATION_2026-10-05.md) replaces the amount/seed wrapper experiment with a private native owner. `authored_revision.inc:58` admits a single-use permit, validates prospective output, and consumes it at line 65 before committing. Its evaluation method accepts only the native owner. It neither accepts new recipe arguments nor trusts a saved/render flag. Save/Undo/clone preserve the native recipe; scene-file authenticity and full clone/migration policy are not established.

`cyrus_edit.cpp:62`, `:81`, `:85`, `:88`, `:119` and `:127` gate the actual reset/delete/transform/clone and direct command paths before mutation. The actual SDK Move path is exercised under expiry. `brush_host.cpp:221`, `:252`, `:347`, `:367`, `:369`, `:402` and `:409` gate stroke admission/commit, settings, history, direct dabs, fill and delete. Brush imports the same AminScatter runtime. Actual Painter end-callback expiry, cancellation, retained history, display, Undo/Redo, reopen and renewal pass private Max tests. Public settings/fill/delete commands are denied without changing prior state.

Full layer/source/container settings and advanced/procedural raw inputs remain outside the owner. Brush filtering can still consume raw caller rows/density. Analyzer dependencies, native SDK whole-object cloning, PFlow/bake preparation, legacy migration and malformed scene provenance remain unqualified. These are reasons to keep the experiment out of ordinary builds, not exceptions silently granted to paying customers. The closed MCP schemas remain unchanged and do not confer licensing authority.

The common local client uses verified immutable state, real installation-key binding and authenticated activation time in the real-context fixture. It has no fake-clock primitive there. No production endpoint, seat ledger or authenticated account flow is implied. B07/B08 remain open; the bounded evidence and next acceptance packet are in the foundation report.

## Policy vocabulary

The [C++ prototype](../../CyrusLicensing/include/cyrus/licensing/policy.h) distinguishes inspection, scene preservation, recovery, existing-work rendering, Scatter authoring and Analyzer authoring. Distribution, CS Edit and Brush share Scatter authoring rights; they do not need a purchased entitlement for every algorithm. The decision uses independent authority, build, device, capacity and time facts. This is an internal prototype API; its integers are not an approved signed format or stable ABI.

Rendering requires evidence that inputs represent approved existing work. Neither a public `render=true` flag nor `Authority::Verified` written by a script supplies evidence. The lab passes synthetic evidence only to prove the policy branch; it has not implemented that proof.

## October 4 entry-family baseline

| Entry family | Proposed admission/continuity behavior | Evidence in this loop / remaining coverage |
| --- | --- | --- |
| Layer/source/amount/seed/paint parameter changes through UI | AuthorScatter before committing new authored state | Lab amount wrapper allows active, denies expired, preserves parameters. Actual parameter setters are still ungated. |
| Direct parameter assignment; `placements`, `cspImpl_placements` | Caller syntax must not determine permission. Saved evaluation and new authored input need distinct ownership. | Direct amount assignment plus `placements` produces new output under synthetic expiry. Implementation-method variants need separate runtime tests. |
| `aminScatterTransforms`, `aminScatterAdvanced`/`cyrusScatterAdvanced`, group/overlap/orientation/scale helpers | Compute only with an admissible native-owned input context, or document a weaker product-workflow boundary | Direct `aminScatterTransforms` generates 83 new rows; the public API currently cannot distinguish saved evaluation. Remaining compute primitives are inventoried, not individually tested. |
| `refreshPreview`, `cspImpl_refreshPreview` | Admit new authoring before clearing caches; preserve usable existing display on denial | Lab wrapper denial preserves the cache object and build count. Cold saved-state evaluation is a separate continuation path. Actual product methods are unchanged. |
| `CyrusPFBuild`, render callbacks | Existing-work render must rebuild transient render output without acquiring authoring capacity | 64-instance Scanline fixture checks actual PFlow population and saved-scene reconstruction. Denied bake and PFlow cleanup/exception rollback still need coverage. |
| `bakeInstances`, geometry export, manual PFlow conversion | Proposed authoring/export boundary; final B07 policy is open | Not executed by the licensing lab. Do not automatically classify output extraction as free rendering. |
| CS Edit commands and `Move`/`Rotate`/`Scale`/delete/clone/reset SDK callbacks | Admit new mutations before Undo capture or modification; preserve cancellation/restoration | Lab native move wrapper, Undo/Redo and saved edits exercised. Direct methods and SDK callbacks remain ungated; expiry mid-gesture not tested. |
| `cyrusEditStack`, publish/visibility/binding/identity recovery | Evaluation/bookkeeping is distinct from a new artist edit; needs approved state context | Saved edit identities survive fixture reopen and cold evaluation. Blanket denial here would threaten continuity. More legacy/topology cases remain. |
| Brush create/begin/dab/fill/stroke/delete/history changes | New document or stroke mutation needs AuthorScatter; same product right as ordinary placement | Fill wrapper tested. Direct native fill bypass observed. Painting gestures and history operations remain to cover. |
| Brush bind/rows/filter/mask refresh; stats/options/display | Classify evaluation, tool state and persisted authoring separately; do not gate by function name alone | Declaration inventory and representative source inspection only. No claim of complete Brush boundary coverage. |
| Brush stop/cancel; Undo/Redo/load/save | Permit cleanup and legitimate restoration even if current authoring authority ends | Brush Undo and CS Edit Undo/Redo tested. Malicious history/state injection and expiry during dragging remain unqualified. |
| Analyzer `runAnalysis` and native `cyrusAnalyzeSurface` | New explicit analysis needs AuthorAnalyzer; evaluation of saved dependent work needs separate continuity policy | Independent wrapper uses Analyzer right and preserves analysis-run count on denial. Dependent Scatter render after missing Analyzer caches not tested. |
| Retained publication/display, bounds, hit testing and preview diagnostics | Reuse prepared approved snapshots; no license I/O or signature work per point/frame | No production drawing changes. Licensing-specific viewport timing still unmeasured. |
| Python/MCP `MaxHost.generate` and direct pymxs setters | Same native contract as UI; remote/tool identity is not authority | Static path traced in `CyrusMCP/cyrus_mcp/max_host.py`; no live MCP mutation test in this loop. |
| Session CPU limits, rollout binding, recovery/status | Remain accessible as appropriate; classify optional setters separately | Inventory only. No reason to couple these to a purchased feature per helper. |

The full primitive inventory supplements this table; it does not cover all SDK callbacks, property setters, script functions or future entries. L0/E01 remains open until those entry paths are reviewed and the proposed owner can enforce the contract.

## Ownership reasoning and remaining expansion

A script wrapper is useful for user feedback and checking *before* destructive work, but can be skipped. The current native generators accept arbitrary nodes/settings. Adding a check to every calculation would also stop legitimate render regeneration. Adding a public `evaluation` flag would reopen the same bypass.

The bounded owner now demonstrates amount/seed and associated Edit/Brush mutation. Next cover the complete authored layer revision. Authoring commits require a verified operation context; preview/render evaluation must read the admitted revision. Exposed parameters must not become authority merely because a scene is loaded. Persisted schema/versioning, old scenes, Undo and scene portability need explicit treatment before extending this to the whole plugin. A native chunk alone does not authenticate maliciously edited scene data.

This remains a candidate design, not an adopted large rewrite. The amount/seed/Edit/Brush slice supplies concrete cost and continuity evidence. Compare full ownership against an explicitly weaker workflow lock before migrating all recipes. Do not build a full backend on an assumption that a script check protects native computation.

## B07: what “existing work” means

The fixture separates two facts: preserving authored parameters/edits, and freezing evaluated geometry. Changing a distribution surface moves evaluated placements; changing a source box's height can alter a render while placement fingerprints stay identical. A fingerprint of returned positions is therefore insufficient to enforce either a frozen scene or authorized provenance.

Recommendation for product discussion: preserve the authored Cyrus setup and support normal evaluation of its dependencies for rendering, with new Cyrus authoring locked. This is narrower and simpler than promising byte-identical geometry forever. It still requires a native owner for Cyrus's authored state and an explicit decision on externally changed dependencies. A frozen-output promise instead needs a qualified geometry/cache/provenance design, storage budget and missing-asset behavior. **Neither dependency policy has been silently selected.**

Full-term offline permission versus immediate device transfer remains the separate B08 decision. This experiment does not change that tradeoff or choose a shorter refresh window.
