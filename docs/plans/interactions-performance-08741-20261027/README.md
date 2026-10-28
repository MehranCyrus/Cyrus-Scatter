# Scatter 0.87.4.1 — interaction reliability and performance campaign

27 October 2026. The user asks for a sustained, evidence-led improve/test loop using at least 20 distinct reacting plant models, moving colliders, varied shapes and scales, viewport usability, and a qualified Max 2027 MZP. The user explicitly selected **0.87.4.1**. The scoped test delivery and its unresolved limitations are recorded in [the delivery report](DELIVERY_08741.md); this checklist is not a claim that every topology or scene is supported.

Baseline: [0.87.4 delivery](../source-preparation-editor-20261026/DELIVERY_0874.md), commit `d24b880816ab367874f417f79d1253aafa9a60f5`, Max 2027, Interactions 8 and schema 62. Earlier claims remain limited to their exact source and host identity. The research index is stale; inspect current sources and receipts directly. No artist profile/session is modified.

## Objective and test inventory

Use at least **20 distinct real source models** in owned Max 2027 scenes. For every model record actual source identity/category, geometry and units, settings, preparation result, at least one attempted nontrivial collider contact, removal/restoration, source/root/visible-mesh correctness and timings or an explicit reproducible failure. An attempted test and a passing result are different; do not count an empty broad-phase result as a contact. The initial reproducible inventory contains 23 individual library fixtures (six flowers, three grasses, five groundcovers, seven shrubs, two trees) and 10 sources in the supplied New Plants scene. Names, full source hashes and copies are in `build/interactions08741-20261027-01/fixture-manifest.json`.

Use multiple collider shapes, including the existing sphere and supplied Rock_10 geometry. A fixed root or fixed decoration inside a solid may be impossible to resolve: verify a clear failure and previous complete result, rather than claiming that every physical configuration is solvable. Covered roots and contact gap are separate artist choices; root hiding must not be used to make geometry tests pass.

The campaign compares equivalent asset/instance transforms, scene units, scatter counts, topology, collider path and quality settings between builds. Track cold source capture/preparation, warm source reuse, candidate count, local contact fit, publication, redraw/event time and memory separately. A synchronous command/redraw duration is **not** presented FPS. Include physical held-pointer interaction and ordinary viewport navigation where the owned host can measure them; label any missing presentation measurement. Establish per-case baseline before deciding measurable improvement targets; no universal FPS guarantee is presumed.

## Campaign checklist

- [x] Read current handoff, ownership contracts, version policy, worktree status and available research; preserve unrelated work.
- [x] Copy and hash the 23 library files, New Plants scene and Rock_10 collider into the owned build run.
- [x] Launch a source-matched 0.87.4 baseline in an owned Max 2027 profile and verify loaded paths/hashes.
- [x] Evaluate at least 20 distinct plants through actual preparation and collider/contact behavior, recording successes and failures individually in the baseline and final successor.
- [x] Exercise real Cyrus Edit collider movement, fixed-root/decoration conflicts, box/closed-mesh/stone proxies, gap and covered roots, varying scales/transforms and move-away restoration on recorded candidates. An actual Live drag still rebuilds placements on release; this remains an optimization opportunity.
- [x] Exercise multiple independent instances and multiple colliders, shared source preparation, large-scene/locality and normal navigation without unrelated placement work. Final-package navigation samples were too sparse to establish a dependable frame rate.
- [x] Inspect workflows and visible settings. The detected guide-quality warning now directs the artist to a complete-mesh check; the observed limited effect of the existing stiffness control is documented rather than silently removed.
- [x] Rank measured problems by frequency, impact and correctness; implement bounded, evidence-backed candidate improvements. Record unresolved failures and the additional Live placement rebuild.
- [x] Repeat native, host and physical tests on the matched successor, including 25 real models and representative scene fixtures. Record three model exceptions and an unresolved intermittent access violation instead of counting them as passes.
- [x] Exercise source invalidation, Manual/Live, Undo/Redo, save/reopen, previous-result retention, relevant settings changes and affected lifecycle paths on recorded candidates. These focused checks do not establish exhaustive coverage.
- [x] Bump candidate product/build/script/installer identifiers to 0.87.4.1 under the user’s explicit selection; keep independently versioned products and saved formats separate. The native capability advances to 9; scene schema remains 62.
- [x] Build an exact matched Max 2027 `.mzp`; verify archive, guards, loaded identities, native tests, 25 final model outcomes and representative actual interactive input.
- [x] Save an owned trial copy, report measured comparisons and explicit limitations, and update current artist/engineering documentation.

## Acceptance and instrumentation

The original source/scene and artist profile are never overwritten. Each measured plant requires a true affected/contacting pose or an explicit failure, not just candidate proximity; restored-away states must be checked. For visible full-mesh audit, record triangle count, minimum gap, penetration/crossing counts, root-anchor error and maximum edge deformation. Compare against the existing 25% edge-change quality limit and record if a diagnostic fails. Do not shrink arbitrary problem budgets or remove valid stems to improve the numbers.

Source mesh/rig preparation is shared per source and settings; instances own independent transforms and poses. F01/F03 govern layer/source identity, F04/F08 govern relevant invalidation and no unrelated solve/upload, F05–F07 govern bounded work and previous-result retention, F09–F11 govern geometry, units, scene persistence and Undo. Host API and publication remain on Max’s thread; workers use copied immutable numeric data. Record payload/memory reservations separately from process and GPU peaks.

Every iteration has a frozen producer receipt, source/package hashes, loaded paths, scenario manifest, per-case outcomes, failed attempts and timing data. A performance change is accepted only when an equivalent-work before/after demonstrates benefit and geometry/recovery checks remain valid. Navigation and direct native fit are reported separately. The user’s desired “very fast” outcome is evaluated against measured p50/p95/max, representative scene scale and practical interaction; unsolved or unsupported configurations remain explicit.
