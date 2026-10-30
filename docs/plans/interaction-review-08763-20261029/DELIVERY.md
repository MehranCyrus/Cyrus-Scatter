# 0.87.6.3 — interaction review repairs

29 October 2026. Max 2027 testing delivery. The user requested fixes and focused
testing before a later all-host installer. No EXE, older-host build, artist
installation, Git push or website update was performed in this pass.

## Install and try

Use [CyrusScatter-0.87.6.3-Max2027.mzp](../../../dist/CyrusScatter-0.87.6.3-20261029/CyrusScatter-0.87.6.3-Max2027.mzp)
with **Scripting > Run Script**, then restart Max. This installs the matching
script and native modules; copying only the `.ms` file is insufficient.

Existing prepared models and artist controls remain. Try a copy of your scene:

1. Move a collider with Cyrus Edit and try an ordinary closed scene collider.
2. Change React/Off/Collider roles with neighboring-tree interaction retained.
3. Compare Inside solid/Under collider and Hide margin across Bend and Trim.
4. Change viewport triangle limits, then restore them. Pending Manual placement
   changes should still wait for Update.
5. Check mixed fixed/deforming sources and Undo/Redo an individual instance move.

The [selection/shared controls guide](../viewport-selection-08762-20261029/ARTIST_GUIDE.md)
and [Bend/Trim controls](../drag-response-08756-20261028/ARTIST_GUIDE.md) still apply.

## Changes against the review

| Finding | Repair | Evidence |
| --- | --- | --- |
| R1: inactive neighbor flag could throw or dereference a missing rig | One effective-neighbor predicate requires React, the authored option and prepared geometry in every participation path. Inactive preferences remain authored. | Native Off/Collider/React, disabled/restored edits and distinct sources; corresponding Max role transitions. The former isolated collider-only crash exits successfully. |
| R2: artistic modes missed overhead/margin hiding candidates | Candidate reach includes enabled hiding independently of the response mode. | Scene and scattered collider native cases, all four response modes, move-away restoration; eight Max hiding combinations. |
| R3: repeated override-map copying and scans | Borrow old/new maps; build edited-reactor bounds once per evaluation and query that index. Overhead footprints use horizontal splitting. | Actual-engine allocation probe and deterministic/restoration cases. |
| R4: pose packing ignored display quotas | Share the existing controller draw planner with pose admission. Pack poses for the union of idle/navigation mesh prefixes; retain transforms/hiding for box fallback. Limit changes invalidate the preview cache without applying Manual placement edits. | Native quota/permutation cases; Max 500-reactor fixture with five budget changes and unchanged placement/contact generation. |
| R5: Point Cloud removed fixed parts | Point and face visibility use the same fixed-aware predicate. | Eight fixed point samples and 12 fixed triangles remain visible with roots covered; CPU/compact parity checks. |
| R6: render bounds missed distant fixed geometry | Union complete source bounds with the conservative guide deformation envelope before transforming packet bounds. | All emitted fixture vertices are contained, including fixed geometry extending to 5.035 metres. |
| R7: one Edit transform copied the whole layer (additional review observation) | Immutable sparse transform overlay preserves the base and stable identities. Selection flattens to that base, overlays do not chain, and changed transforms invalidate preparation receipts. | Native identity/selection/compaction/invalid-input cases, allocation probe and Max Edit/save/reload/Undo checks. |

The artistic Bend/Trim fitting algorithm is unchanged. No new solver, GPU compute
backend, saved parameter or UI workflow was introduced. Scene schema **65**,
recipe **9**, Edit capability/storage **4/3**, source transform/Undo **2/2** and
viewport selection **1** remain. Native Interactions **16** guards the new pair.

## Measured results

All **62 native CTest suites passed**, including the added review cases.
Generated-source checks passed; the exact extracted package was loaded in an
owned Max 2027 profile. [Qualification](QUALIFICATION.json) records hashes and
the retained evidence files.

| Focused native probe | Before recheck | 0.87.6.3 |
| --- | ---: | ---: |
| 1,024 edited neighbors: total evaluation | 519.851 ms | 3.2384 ms |
| Same evaluation: allocation calls | 2,118,614 | 39,856 |
| Same evaluation: cumulative requested bytes | 285,908,326 | 1,358,775 |
| One changed record in a million-row placement view: new tracked row bytes | 96,000,000 | 208 |
| Same view operation | 42.1902 ms | 0.0239 ms |

These are single-run instrumented native probes, not Max frame times, process
peak-memory measurements or a million-instance realtime claim. The neighbor
fixture has zero contact queries and isolates unnecessary bookkeeping. The
original external review's approximately 429 ms run and this task's approximately
520 ms baseline recheck have different timings; allocation counts agree.

The native parameter matrix covers **648 cases / 6,480 faces**, deterministic
restoration and CPU/compact-pose parity (maximum coordinate error
**3.26901e-9 metres**). The review's 13,087-pose/2^24-word example remains an
arithmetic boundary illustration, not a newly executed extreme Max stress scene.

Max 2027 checks cover:

- React/Off/Collider transitions, retained edits and hiding restoration.
- Five preview-budget changes on 500 reacting placements, including unlimited;
  a pending Manual amount of 777 remains pending and 500 stays published.
- Shared-controller controls, owner redirection and geometric selection.
- The delivered Terraces garden: six controllers, 18,229 placements, 77 picking
  rays, plus 24 navigation submissions with unchanged placement epochs and
  retained stream counters.
- Independent CPU-baked posed-foliage ray reference: 138 hits, maximum error
  0.04834 centimetres (about 0.4834 mm) in this garden's centimetre system units.
  This measures screen-ray/picking agreement, not deformation-clearance accuracy.
- Twelve held-input Cyrus Edit stone updates and twelve ordinary closed-proxy
  moves. Both advance viewport presentation while held; sources, preparation,
  layouts and collider cooking remain unchanged within each movement series.
  Median native fits were 16.43 / 20.56 ms; CPU submit times were 63.24 / 66.43 ms.
  These are regression observations, not a matched before/after speedup or FPS.
- Six subsequent orbit updates produce no contact evaluations. Final requested
  and presented tickets catch up after release.
- Saved fixture reload and individual-instance Undo/Redo across separate events.

## Review limits and retained failures

The open visible hero rock cannot itself be a solid scene collider; the test uses
its existing closed proxy. Early driver attempts used the open mesh, omitted the
proxy's source-relative transform, or forced a source-freshness check ahead of
the production scene-transform callback. Those attempts are retained in the
owned build folder. The final replay uses production callback order and checks
both computation and presented tickets. They did not require product changes.

Earlier persistence drivers inspected the first layer instead of the selected
reactor, selected before reload publication completed, or included setup in the
transport Undo hold. The final separate-event fixture owns only its Edit command.

Physical mouse-to-screen latency, GPU FPS, full Corona/V-Ray output, device loss,
out-of-memory injection, long-session soak and arbitrary model topology were not
qualified. The render-bound repair is proven numerically; it is not an external
renderer certification. Point/fixed visibility is checked by native predicates
and compact parity, not a full screenshot matrix for every display mode.

The review's broader opportunities—retained pose-container bookkeeping, packet
reuse, dense high-poly picking acceleration and exact process/VRAM peaks—remain
measured candidates for later work. This patch does not claim the entire update
is proportional only to nearby plants. The environment-only CPU posed-batch
display path is unchanged and does not gain the compact GPU admission policy.

Maintained navigation and delivered facts are updated. Indexed knowledge and the
website retain their previous publication states. Other products and existing
working-tree changes are preserved.
