# I04 / P07 direction and normal blending — implementation contract

Baseline: delivered 0.82.6.1, implementation `f030fb3`, checkpoint `6c0a73b`. The active goal authorizes this work. Planned substantial delivery: **0.83.0**. This document is an implementation contract, not a qualification claim.

## Behavior and composition

Layer-owned orientation modes: existing Random orientation, World direction, and Look at target. The existing Align to normal checkbox remains; a 0–100% normal blend controls the preferred up direction from world +Z to the evaluated geometric face normal. Blend uses a spherical arc, with a deterministic world +X semicircle for the exactly opposed normal. Disabled alignment uses world +Z. Slope filtering continues to use the geometric surface normal independently.

Random mode preserves the established reference-axis convention, random rotations and scales. Explicit direction modes point canonical +Y at the full 3D world vector or from the final candidate position toward the target pivot; preferred up controls roll and is orthogonalized against forward. A target directly above/below a plant is therefore a valid 3D heading, not a planar projection. Parallel forward/up uses a deterministic alternate up; a coincident target uses the Random-mode reference frame. A zero fixed direction or missing selected target rejects the successor and preserves the previous complete result.

Models declare local +Z up; the existing per-source forward choices +Y, -Y, +X, -X apply to explicit direction modes. Random local XYZ rotations act in model coordinates, then the source-forward correction, then the chosen world frame. Source offsets retain their existing meaning. Analyzer boundary facing remains authoritative in Random mode; explicit direction modes override boundary facing, without changing Analyzer candidate positions. CS Edit follows procedural orientation; final transforms and source bounds/radii are computed before acceptance.

## Reuse and dependency boundary

Separate cached canonical random transforms from orientation. Candidate generation runs with a world reference frame; a bounded copied normal snapshot supplies evaluated face normals for the later orientation stage. Direction/blend/target changes must not regenerate candidates, change source choices, resample randomness or rebuild that normal snapshot. Orient after final candidate movement/Relax and Paint scale, before source offsets and CS Edit. This deliberately repairs orientation at the final face when Relax crosses a face: the old implementation could retain the pre-Relax normal.

Use native immutable per-receiver normal snapshots, bounded to ten million faces in total (matching the existing surface-filter bound), owned by the script cache and containing no Max nodes. The canonical sampler returns its copied normals alongside rows from the mesh it already read; avoid an extra geometry extraction. Reuse each snapshot with its receiver candidate cache. Applying orientation touches copied rows/normals only, with slot/face-range validation. Keep publication atomic and intermediate arrays separate from the last complete result. Measure this extra retained normal memory and cold preparation cost explicitly.

Target transforms (and their ancestors) are orientation dependencies only when Look at target is active. Query target transform validity without evaluating target geometry. Split orientation-controller time validity from candidate time validity, so animated heading/blend does not invalidate the candidate cache. Manual keeps its publication; Live responds to relevant orientation animation, while unrelated time changes and panel browsing remain passive. Disabled target references do not schedule work.

## Persistence and UI

Add fields to layer copying, closed recipe/settings contracts, input/prepared keys, dependency handling and supported inspection help. Scene schema remains 58: a separate appended parameter block adds neutral defaults without changing existing parameter IDs, Paint codec or row layout. Existing schema-58 scene reopen is a required host gate. New recipes and settings presets use format/capability 2. The still-current delivered format 1 has a narrow read conversion: require its exact original field set, add only Random/100%/+Y/no-target defaults, then validate the complete format-2 record. Never modify files while reading. This preserves recently delivered user/bundled recipes; it does not restore retired scene schemas or other historical formats. Native orientation capability is independently versioned at 1.

Complete recipes preserve the target as an explicit external node role. Numeric Transform presets preserve the destination target reference; applying Look at target without a valid destination target is rejected before mutation. Format-1 qualification receipts remain frozen. New saves use format 2, including after reading an old example. New orientation defaults must be explained in the artist guide.

Keep controls in the lazy Transforms panel: mode, direction XYZ or target picker/clear/status, Align to normal and blend. Explain +Z up, source Forward axis, and roll in tooltips. Validate at captured owners across picker/rebind callbacks. Bounds, wrapping and enabled states must pass at 100% and 150% Max UI scale.

## Acceptance and delivery sequence

1. Pure native frame/normal/math oracle: tilted, vertical, opposed and degenerate faces; blend endpoints/midpoint; full 3D target; zero/coincident cases; all four source axes; nonuniform/zero scale; finite orthogonal frame and handedness. Compare complete default matrices to the old sampler with alignment enabled where movement does not cross faces. Verify final Auto Radius changes and downstream spacing.
2. Integrate the copied normal snapshot and split preparation/cache keys. Count candidates, snapshot builds, preparation, acceptance and uploads. Direction-only edits must reuse candidate and normal data; target motion may affect final radii/accepted counts but not unrelated randomness.
3. Implement scoped validity/dependency handling and native capability guards; test static and animated target, parent motion, target deletion, inactive target and unrelated animation in Manual/Live. Failed updates retain previous complete rows/radii.
4. Add UI, persisted field inventories, complete recipes and settings presets; test actual handlers, owner switching, copy, one-Undo import, Undo/Redo, unit changes and save/reopen. Retain unsupported-controller complete-save explanations.
5. Run generated/Python/native checks; launch only a matched disposable Max 2027 pair. Use simple analytical fixtures plus a heavy multi-layer terrain and relevant Paint/Bands/Analyzer combinations. Compare full matrices/IDs/radii and avoided-work counters, not only counts.
6. Update examples/thumbnails affected by current-only data changes; verify every supported authored field. Package exact qualified MZP, update artist/site docs, commit/push and record the checkpoint. No artist installation. I05 follows.

Knowledge retrieval for `alignNormal` returned stale evidence; current source is authoritative. Source inspection found orientation in `scatter.cpp` before Relax, source transforms in `cspImpl_placements`, Analyzer facing/CS Edit in `procPrepare`, final bound/radius calculation downstream, and broad settings time validity in `input_validity.cpp`. These are the seams requiring explicit tests.
