# Implementation sequence and acceptance gates

Status: proposed work. Only the investigation/fixture described in the results has run. The current instruction authorizes investigation and planning; it does not promote this entire roadmap to an implemented delivery.

## INT0 — Freeze the adapter contract

Write versioned native contracts for `PreparedSource`, placement binding, obstacle definitions/instances, root mask, pose state and complete interaction publication. Define SI/pivot frames, allowed transforms, ownership, source/cohort keys, invalidation, cancellation, serialization, Undo and resource accounting. Keep the A/B/C frozen v1 header unchanged; any new mesh-collider contract gets an explicit successor.

Exit: inspectable interfaces and fixtures cover source-object offsets, stable source correspondence, complete failure retention and changed-obstacle restoration. Select foundation F01–F11 acceptance, F12 when applicable. No new user-facing version is chosen until a coherent delivery scope is agreed and the version policy is applied.

## INT1 — Source preparation and capability registry

Extract the useful preparation logic from the single-object experiment behind a pivot-local shared source cache. Preserve explicit review and rejection of unresolved hierarchies. Reuse identical evaluated geometry/profile definitions across a root's layers and instances. Add a material-independent capability description: rigid obstacle, round-stem reactor, blade reactor, unsupported geometry.

Implement and qualify a **blade/ribbon preparation profile** for A069/A068, including flat blades with shared or duplicated vertices, blade direction, anchored bases and cross-section behavior. Do not force them through tube detection. Keep phlox blocked until its 54 unresolved connections are explained; add guide correction/import only with a defined authoring contract. Keep the tree static while a separate trunk/branch/leaf analysis is designed.

Exit: actual library sources reconstruct at rest, keep correct roots and survive transform/frame tests. Increasing 10 to 10,000 instances does not increase source analysis count. Changed geometry invalidates only its definition. Unsupported geometry remains normal Scatter with clear status. Caches survive accepted save/reopen/version checks or rebuild explicitly.

## INT2 — Directional relationships, spatial index and root cover

Add layer role/settings storage and a root-owned obstacle-to-reactor graph independent of classic spacing. Build a native index over stable published placement bindings and conservative reachable bounds. Refit obstacle pose bounds, query old and new regions, maintain reverse dependencies and stage a reversible covered-root mask. Start with admitted flat receiver and sphere/box/explicit proxy cover; extend only with tests.

Exit: moving a stone affects only its dependency region; far IDs/transforms remain unchanged; leaving plants restore correctly; several obstacles do not overwrite each other's result. Covered plants reappear with the same IDs. Manual mode and pending placement recipes remain intact. Report resource admission and incomplete query states.

## INT3 — Per-instance fitting and retained light preview

Adapt the independent fitter to consume shared rigs plus per-placement world transforms and complete relevant obstacle snapshots. Fit the affected guide subset while preserving parent/root constraints. Store compact poses, reuse rest geometry for unaffected copies and stage bounded CPU LOD meshes for changed instances. Keep all Max access/publication on the host thread.

Implement source/object-offset mapping tests before generalizing transform admission. Start with positive uniform scale; explicitly reject or defer nonuniform/mirrored/sheared transforms until they use correct metrics. Add clearance/refinement controls without conflating them with broad-phase range.

Exit: two instances of one source can bend differently without mutating each other or the source. Sphere motion, removing an obstacle, Undo and stale-job cancellation preserve complete results. Actual continuous held-mouse drags remain responsive. Full visible-mesh auditing catches foliage penetration and stem strain; a successful guide solve alone is insufficient.

## INT4 — Actual stone geometry and contact quality

Extend collision admission deliberately for the supplied rock meshes. Choose qualified convex decomposition/proxies or a triangle-mesh acceleration structure with explicit surface/solid semantics and tolerances. Test concavity, thin triangles, two-sided/open/nonmanifold input, deep containment and multiple simultaneous contacts. Proxy preparation is once per changed rock definition, not per copy/mouse event.

Refine contact on the delivered plant geometry so conservative guide envelopes do not leave an unexplained empty halo. Address stem cross-section/triangle strain before declaring natural close contact. The inspected 0.3.1 strong-bend strain remains a real quality gate.

Exit: zero admitted penetration beyond declared delivery tolerance, controlled clearance/error bounds, stable roots and acceptable stem/leaf deformation over a defined movement sweep. The flat-garden cover policy matches actual root occupation and has documented overhang limits. An enclosing sphere may remain a debug proxy, but cannot qualify mesh-rock conformance.

## INT5 — Renderer, Bake and full-quality pose delivery

Design the renderer inlet alongside INT3; implementation must complete before user delivery. Assess bounded exact posed-shape variants through the existing PFlow bridge versus a dedicated adapter. Measure how many unique shapes can be admitted before memory or build cost becomes unacceptable. Avoid materializing placement-sized script objects in a new hot interaction path.

Exit: viewport, full mesh, render and Bake agree on pose, world transform, normals, UVs, opacity, material IDs and root suppression. Define cold missing-source behavior and render/subframe evaluation. Qualify the intended installed renderer explicitly; the diagnostic Scanline attempt did not establish material fidelity. Motion blur/time-varying effects require additional scope.

## INT6 — Simple panel and release qualification

Bind the panel in [04](04_ARTIST_WORKFLOW.md) to the native authored model. Keep owner references valid across control rebuilds. Add truthful source/coverage/nearby/pose/budget status and clear failure messages. Run the garden matrix plus native correctness, generated-source checks, appropriate project tests and Max 2027 physical interaction/lifecycle/render tests on the exact matched pair.

Exit: all required rows of [06](06_VALIDATION_MATRIX.md) pass or are explicitly outside a narrowed delivery. Build and verify a runnable Max 2027 `.mzp` from that exact script/native pair, with payload hashes, guards and archive integrity. Deliver installer path and Scripting > Run Script instructions. Installation/restart remains the user's action unless explicitly requested. No production files, artist profiles or sessions were installed/restarted by this investigation.

## Follow-on scope

Wind, tree dynamics, branch breakage, plant-to-plant collision, rigid settling, GPU acceleration and cross-Scatter/scene-wide collider discovery need their own contracts and evidence. The shared rig/pose foundation makes them possible to investigate; it does not make them free or already implemented. Keep N/P/PG/I roadmap identifiers distinct from the local INT0–INT6 work labels above and from release numbers.

## Performance study before commitments

Use the same source/build/receiver setup at approximately 500, 2,500 and 10,000 placement tiers, plus a large mostly-far population. Measure cold analysis/rig realization separately from changed-collider query, fit, validation, mesh staging, publication and render costs. Record affected instances/guides, queries, cache hits, source analyses, avoided uploads, working/private/peak memory and retained history after repeated drags.

Suggested product targets for a bounded light preview are p95 input-to-visible update below 50 ms and release refinement below 300 ms. These are goals to test and revise, **not current guarantees**. Publish the admitted density, assets, active neighborhood, hardware and quality settings with every timing claim. The offline Python index timing cannot establish either target.
