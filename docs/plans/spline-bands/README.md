# Spline bands implementation plan

Status: research and implementation proposal complete, with source/design review corrections incorporated. Prepared 12 October 2026. Implementation and empirical qualification have not started. English is the working language for this workstream.

The user authorized research and planning documents. This package does not authorize product implementation, installation, scene changes, commits, or publication. It is a scoped implementation proposal; the maintained project backlog remains authoritative for unrelated work.

## Objective

Make spline bands understandable and reliable: compact path/band controls, explicit source assignments, identifiable bands, rounded or sharp corners, independently overlapping ranges with density curves and viewport feedback, and automatic source radii. Preserve deterministic placements, independent collision scopes, responsive retained previews, and Manual/Live update contracts.

## Reading order

1. [Research and evidence](RESEARCH.md): current code, vendor references, existing native research, and evidence limits.
2. [Proposed behavior and design](DESIGN.md): ownership, geometry, density, UI, viewport, and radius contracts.
3. [Implementation sequence](IMPLEMENTATION.md): bounded milestones, affected files, dependencies, and completion gates.
4. [Validation and performance](VALIDATION.md): reproducible cases, independent oracles, host qualification, and performance gates.
5. [Research baseline](baseline.json): source identity and evidence checks for this planning pass.

## Required outcomes

- Empty consecutive bands retain their authored intervals.
- Consecutive mode remains available; independent ranges allow a dense Sphere band at 0–10 cm and a sparse Box band at 0–40 cm to contribute together.
- Density controls total occupancy as well as source mixture; refill must not cancel the fade.
- Band colors and field previews explain the actual calculation, including pending versus published state.
- Browsing, orbiting, selection, and display-only edits do not solve placements or upload unchanged sibling geometry.
- Every proposed feature has explicit persistence, failure-retention, numerical, and host acceptance checks.

## Decisions to implement

- Keep Consecutive ranges and Rounded corners as defaults for existing setups. Add Independent ranges and bounded Sharp joins as explicit choices.
- Select density occupancy, then a contributing Band, then a model. The inner/outer mix is controllable without creating a separate population for each Band.
- Use Candidate budget for overlapping/nontrivial density; reject Accepted target in those configurations so refill cannot erase the fade.
- Preserve Band identity throughout generation, Edit, spacing, preview and output. Colors and membership labels use that identity rather than guessing from source or position.
- Compute Auto Radius as conservative pivot-centered XY and 3D bounds from the final instance transform. Choose the metric per spacing rule and retain Manual control.
- Separate published plants/radii from pending authoring changes. Preview labels, geometry revisions and bounded display resources must agree with that distinction.

All twelve requirement groups, including compact controls, assignment clarity, source-row membership, density curves, colors, Auto Radius and the empty-interval correction, are mapped to milestones and tests in [IMPLEMENTATION.md](IMPLEMENTATION.md).

## Review and evidence

Three Astra reviewers covered native correctness, viewport/radius behavior, and design consistency. The primary agent checked critical source paths and reconciled the findings. The final written-plan review reported no further blocking contradictions after the documented corrections; that is a review result, not proof of product behavior.

Corrections include empty-band interval preservation, global Consecutive precedence, overlap saturation, cumulative Sharp-field error, owner/protection transport, copied-layer RNG identity, mixed XY/3D radii, Manual source-geometry revisions and CPU-versus-GPU failure guarantees. Initial Luna recommendations were not accepted as the design authority. Rejected claims are listed in [RESEARCH.md](RESEARCH.md).

The closing scope check found all 23 captured source/evidence file hashes unchanged and the tracked diff identical to the research baseline. Pre-existing status outside this planning folder was unchanged. Local Markdown links and JSON were checked. No product tests, builds, installations, scene edits or fresh vendor decompilation were performed.

## First engineering gate

Start with **P0**: complete the row-transport inventory, prove Sharp-field accuracy within finite limits, pin density oracles and units/source-bounds handling, and measure baseline costs. The production features follow only after those choices pass their gates.

The remaining empirical gates are Sharp accuracy/cost, metadata round trips, current-schema-55 initialization, retained display/upload behavior, Auto Radius source capabilities and physical Max 2026/2027 qualification. The plan does not claim flawless implementation, exact mesh collision, continuous no-gap-crossing during automatic movement, or untested proxy/device-loss support.
