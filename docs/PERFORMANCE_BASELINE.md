# Interactive performance baseline

**0.87.6 UI preservation:** the [UI/settings delivery](plans/ui-settings-0876-20261028/DELIVERY.md) repairs Point sources and control presentation. [67 protected native source hashes](plans/ui-settings-0876-20261028/evidence/protected-sources.json) remain unchanged from its pre-task snapshot; browsing retained publication counters. This is preservation evidence, not a new drag/orbit performance measurement. The original 0.87.5.6 baseline below remains authoritative.

**0.87.5.6, Max 2027, 28 October 2026** is the current artist-endorsed interaction
baseline. The user explicitly reported that Bend/Trim, movement and preview feel
good and asked us to preserve that performance. This is artist feedback on the
tested workflow, not a claim that every scene, renderer or input combination has
passed. [Exact delivery](plans/drag-response-08756-20261028/DELIVERY_08756.md),
[qualification](plans/drag-response-08756-20261028/QUALIFICATION_08756.json), and
[artist controls](plans/drag-response-08756-20261028/ARTIST_GUIDE.md) retain the
package identities, measured inputs and limitations.

## Product decision

Interactive archviz bending prioritizes responsive, predictable art direction.
A bounded approximation is appropriate when it gives the desired visible result.
Exact clearance, detailed mesh validation and more realistic simulation are
separate choices with separate costs. Do not silently put those costs back into
ordinary Bend/Trim or treat an approximate overlap as a reason to restart an
expensive search. The user values the current interaction feel over physical
realism. A future design can supersede this implementation after comparison.

## What made this version work

| Boundary | Current implementation and lesson |
| --- | --- |
| Contact calculation | Artistic Bend/Trim checks at most four coarse guide spans per relevant collider and applies one response. It avoids repeated angle searches and detailed visible-mesh refinement during movement. |
| Prepared data | Source-local guides, bounds/radii, geometry and GPU source bindings are reusable. Moving a collider changes nearby poses; it must not prepare every source or regenerate static planting. |
| CPU participation | Workload includes guide complexity, not only plant count. The qualified 12–13-candidate cases used four compute participants. Four is an observation, not a mandatory thread count for every machine or scene. |
| Presentation | A computed pose, a GPU-ready result and a displayed frame are different states. Ready results request the SDK display boundary while input is held. Each new ticket gets its own bounded presentation retries. |
| Change ownership | Ordinary collider transforms dirty contact pose work. They do not invalidate all placement/display records. Geometry/settings changes still need the appropriate complete successor. |
| Edit history | Candidate text IDs can recur under different source lineages. Filter inactive rows without a live input matrix both during movement and when replaying edits after response changes. Preserve authored history for Undo. |
| Recovery | Publish compatible results together; retain the last complete display when a successor fails. Responsiveness does not justify partial publication or losing artist edits. |

These mechanisms belong to the existing pipeline. Keep Max API access and
publication on the host thread; numerical workers consume owned copied data and
join before return. Current GPU drawing/deformation is not a CUDA/OpenCL contact
solver. Source ownership is mapped in [architecture](ARCHITECTURE.md); required
boundaries are [F04–F08](ENGINEERING_FOUNDATION.md#f04-manual-updates-and-relevant-live-dependencies).

## Measured evidence and its limits

The preserved `New Plants test 22.max` scene has **31 accepted reacting Broadleaf
Tree – Slender 03 instances**, around 13 nearby candidates and one moving stone.
Its mixed grass/fern layer was nonreacting during this campaign. Keep that scope
when quoting the result.

- Median CPU contact fit: **115.57 ms in 0.87.5.5 Detailed contact → 29.51 ms in
  0.87.5.6 artistic Bend**. Quality changes intentionally; this is not a
  same-physics speed comparison or a viewport FPS measurement.
- Standard scene and Cyrus Edit movement each produced 12 distinct presented
  tickets during 12 scripted held-input movement samples. The faster sequence
  produced 10; some intermediate results coalesced before display.
- All 72 final movement/orbit samples reported zero interaction errors/failed
  fits. Source preparation/capture, collider cooking and layout counters stayed
  unchanged during movement. Measured process-work counters stayed unchanged
  during orbit. Exact mesh refinement work was zero in the artistic modes.
- Trunk/base/fade settings changed after an Edit move without another preparation.
  Fixed base 100% produced no bent guides. Structural trunk recognition follows
  prepared hierarchy, not guaranteed botanical identification.

The scoped Max checks used MAXScript timers and a held-input predicate. They do
not establish physical mouse timing, general presented FPS, renderer fidelity,
all plant families, long-session memory behavior or million-instance realtime.
Native test suites and older hosts were not run for 0.87.5.6. Preserve earlier
receipts under their original labels rather than promoting them to this build.

## How to improve without losing the baseline

Use the exact qualified package as the comparison build. State the artist action,
scene/source identities, mode, preview density, collider geometry and relevant
settings. Separate cold preparation, warm contact fitting, pose/buffer work,
host redraw calls and actual presented tickets. Record slow spikes as well as
medians, and compare appearance and final state along the same movement path.

Before retaining a hot-path change, check its intended benefit and the relevant
unaffected behavior: ordinary scene collider and Cyrus Edit movement; held and
released updates; move-away/restoration and reversal; pure orbit with unchanged
work counters; trunk/base/fade; and Trim/hiding when affected. Preserve Manual
pending edits, shared source reuse, deterministic masks and atomic failure
recovery. Choose additional checks from the actual change; this is not an
instruction to rerun every historical suite for documentation work.

Keep an optimization only with measured benefit and acceptable visual/behavioral
results. More CPU threads, a new language or GPU compute alone is not a result.
Do not trade away the useful Bend/Trim behavior to obtain a smaller timing.

## Open work, not implemented improvements

[B41](BACKLOG.md#b41--further-interaction-performance-without-losing-the-baseline)
records a concrete opportunity: the fully fixed Bend-only control case still ran
1,786 contact queries in 23.863 ms while producing zero poses. An early skip must
respect any requested Trim or root-hiding work. Finer branch rejection, cheaper
appropriate collider queries, fewer transient allocations and measured buffer/
drawing costs are investigation targets, not delivered optimizations.

Revisit this baseline when the solver, guide hierarchy, query semantics, workload
scheduler, presentation lifecycle, source lineage, GPU bindings or quality mode
changes. Update this maintained decision and its evidence after a proven successor;
do not rewrite the 0.87.5.6 receipt or infer a new release from a documentation edit.
