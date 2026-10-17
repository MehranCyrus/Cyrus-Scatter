> Historical user objective, enrolled 15 October 2026. P06 grids and P07 orientation were subsequently implemented. Further roadmap implementation is currently paused. Read the [current phase table and scope](PROGRESS.md#original-phase-status) and [engineering foundation](../../ENGINEERING_FOUNDATION.md) before acting. The original objective below preserves past authorization; it does not authorize new implementation, Physics Lab integration, native migration or Git/install actions.

Implement and qualify the remaining Cyrus Scatter improvement program, starting with presets, then continuing through the documented roadmap. Deliver a usable preset library with thumbnails and a distributable Windows EXE installer.

Work autonomously through coding, testing, corrections, documentation, packaging and Git checkpoints. Do not stop after planning or wait for my manual testing between phases. I will perform final artist acceptance afterward.

REPOSITORY AND BASELINE

Repository:
F:\Cursor\_Cyrus_Apps\CyrusScatter

Start from the actual current checkout. The last reported delivery is Scatter 0.82.6, commit b23ed93, on codex/workflow-0.75. Verify these facts rather than assuming they remain current.

Read AGENTS.md, README.md, the current handoff, engineering contracts, version policy and:
- docs/plans/eleven-phase-roadmap/README.md
- docs/plans/eleven-phase-roadmap/TODO.md
- docs/plans/eleven-phase-roadmap/FOREST_IMPROVEMENTS.md
- docs/plans/panel-performance-0826/PROGRESS.md
- docs/plans/recipes-0825/PROGRESS.md
- docs/plans/recipes-0825/FORMAT.md
- docs/BACKLOG.md

Preserve unrelated changes, artist scenes, installed plugins, licensing work and the artist’s normal Max profile.

This goal explicitly resumes Phase 6 and authorizes the remaining roadmap implementation. It supersedes the earlier Phase 6 pause for this program.

FIRST DELIVERY: PRESETS AND THUMBNAILS

Start with I03 and the unfinished preset-browser work.

Extend the existing recipe system with:
- Search, tags/categories and clear library navigation.
- Optional stored thumbnails with responsive visible-page loading.
- Clear summaries of included layers, Paint, settings and required external assets.
- Useful explanations when unsupported authored data prevents Save Everything.
- Explicit Add Layers and New Setup workflows.
- Reliable refresh, cancellation and detection of changed library entries.

Preserve complete supported authored settings and Paint. Never silently discard unsupported data or transfer receiver-bound Paint onto incompatible terrain.

Browsing, searching and viewing thumbnails must not calculate scatter, evaluate terrain, import assets or load every Paint attachment.

Create an initial useful preset collection, then expand it as later features become available. Target at least eight distinct examples, such as:
- Meadow with multiple vegetation layers.
- Trees with understory.
- Slope/altitude-controlled mountain planting.
- Spline-band hedges or border planting.
- Rectangular orchard.
- Staggered or hexagonal planting.
- Avenue with repeating models and gaps.
- Formal garden or courtyard planting.

Use procedural demonstration assets or assets whose redistribution is permitted. Keep artist model substitution straightforward. Include compatible demonstration terrain/scenes where Paint or other bindings require them.

Thumbnails must accurately represent the saved preset. Prefer captures or renders of its actual Max result. Generate thumbnails explicitly and cache them; never regenerate them during idle browsing.

REMAINING IMPLEMENTATION

After the preset delivery, complete the remaining original P06–P11 scope and Forest-informed I04–I18 improvements in a dependency-aware sequence.

The scope includes:
- Direction controls and controlled normal blending.
- Explicit variation policies for copy/import.
- Rectangular, staggered and hexagonal layouts.
- Direct path spacing, sequences, gaps and reference placement.
- Scale/rotation maps and map-driven model assignment.
- Shared evaluated terrain snapshots where profiling justifies them.
- Finer reuse of candidates, filters, attributes and acceptance results.
- Adaptive viewport and resource-lifecycle improvements.
- True UV pattern placement and explicit surface projection.
- Supported authored Edit/per-instance-radius recipe transfer.
- A bounded typed effects stack.
- Asset packages and transactional library application.
- Source-animation sampling and geometry LOD.
- Explicit renderer adapters and separately qualified edge trimming.
- A bounded expression system after the typed effects foundation is proven.

Use the detailed plan to define each feature’s exact contract and dependencies. Break large items into independently testable deliveries.

Do not duplicate completed capabilities. For proposed performance optimizations, measure the bottleneck first. If evidence does not justify an optimization, document the decision and continue useful independent work.

Use Forest/Chaos research and official documentation to understand behavior and evaluate design choices. Distinguish documented behavior, observed evidence and inference. Implement Cyrus’s own solution; do not assume proprietary internals or copy unlicensed implementation material.

PERFORMANCE AND CORRECTNESS

Preserve:
- Ordered layers and explicit setting ownership.
- Receiver-bound Paint Areas and stable identities.
- Deterministic randomness with documented limits.
- Independent collision scopes.
- Correct final transforms/radii before acceptance.
- Manual pending edits and relevant Live updates.
- Bounded memory/work and atomic publication.
- The previous complete result when a successor fails.
- Host-thread access to Max APIs; workers use copied data.
- The responsiveness improvements delivered in 0.82.6.

Static idle, panel browsing, selection and unrelated animation must not cause unnecessary placement calculations or unchanged-buffer uploads.

Measure UI work, geometry extraction, map preparation, placement, filtering, spacing, publication, preview preparation and uploads separately. Compare complete placement data as well as counters; unchanged output alone does not prove cache reuse.

TESTING AND DELIVERY LOOP

Use 3ds Max 2027 only. Do not build for, launch or test Max 2026.

For each bounded delivery:
1. Inspect current source and record the baseline.
2. Define intended behavior, unaffected behavior and acceptance tests.
3. Implement in authoritative native sources/templates/generators.
4. Run appropriate native, generated and Python checks.
5. Test the matched script/native pair in an owned disposable Max 2027 profile.
6. Exercise actual UI handlers and relevant lifecycle/failure cases.
7. Measure performance in representative simple and heavy scenes.
8. Fix demonstrated failures and repeat affected checks.
9. Update documentation, roadmap/TODO, backlog and artist help.
10. Build and verify a runnable Max 2027 MZP.
11. Commit the coherent delivery, push it and verify the remote hash.
12. Continue to the next item.

Test Manual/Live behavior, Undo/Redo, save/reopen, owner switching, missing dependencies, failed successors, cache reuse and memory growth whenever affected.

Use automation/MAXScript/MCP where suitable. Use physical UI testing when needed and available. Keep untested physical-display, renderer or device behavior explicitly open. Never claim a visual or runtime pass from offline tests alone.

Do not install into or restart my normal Max session. Installer testing must use owned disposable environments and verified destinations.

VERSIONING

I authorize a new development-numbering approach for this program:
- First preset/browser delivery: 0.82.6.1.
- Subsequent substantial deliveries: 0.83.0, 0.84.0, and so on.
- Smaller follow-ups may use additional patch steps within the current series.

Update Release_Versioning.md and applicable agent guidance to explain this change. Ensure version parsing, build resources, guards, documentation and packaging support the selected format consistently.

Preserve historical qualification labels and hashes. Keep Analyzer, MCP and other independently versioned components separate. Reserve 1.0 for publication readiness.

FINAL EXE INSTALLER

Deliver a Windows EXE installer for the qualified Max 2027 product, alongside the MZP.

The EXE must:
- Identify supported Max installations and explain its destination.
- Install the exact qualified script/native pair.
- Include the distributable presets, thumbnails and required permitted demo content.
- Provide a writable user preset location separate from bundled examples.
- Preserve user-created presets during upgrades.
- Handle a running Max instance safely and give restart instructions.
- Support a defined upgrade and uninstall workflow.
- Preserve unrelated plugins and user content.
- Keep signing keys, license secrets, private test modules and artist assets out of the package.

Preserve the existing licensing contract and document the recipient activation workflow. Do not silently disable licensing to make distribution easier.

Test fresh installation, upgrade, preset discovery, thumbnail loading, sample use, repair/failure handling and uninstall in disposable environments. If code signing requires unavailable credentials, deliver the tested unsigned installer and clearly record that limitation.

TRACKING AND AUTONOMY

Maintain one current execution ledger with:
- Completed work and exact commit/package identities.
- Current task and next task.
- Actual test results and performance measurements.
- Failed experiments, unresolved defects and acceptance limits.
- Clear reproduction/resumption instructions.

Correct stale current-status/version references without rewriting historical evidence. Treat the stale knowledge-search index as separate maintenance; do not rely on it as current source evidence.

Do not ask routine implementation questions or stop for my manual phase acceptance. Make reasonable choices within the documented contracts. If a missing decision or external dependency blocks one item, record it precisely and continue independent authorized work.

Do not publish the website, distribute packages to other people or modify external accounts as a side effect.

COMPLETION

Complete the goal only when the agreed implemented features pass their applicable checks, the preset library and thumbnails work, the EXE and MZP are built and verified, documentation is current, and the authorized code is pushed.

Any unresolved feature, failed test or unavailable required acceptance must remain visibly incomplete. If a session or execution limit interrupts work, leave an accurate handoff so the next continuation resumes from the current task.

The final report must include:
- What was delivered.
- Preset inventory and use instructions.
- MZP and EXE paths and installation instructions.
- Git branch and commit.
- Measured performance and test evidence.
- Supported host/renderer scope.
- Remaining limitations and my final artist acceptance checklist.
