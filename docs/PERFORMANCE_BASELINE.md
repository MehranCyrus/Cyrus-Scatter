# Interactive performance baseline

**0.87.6.7 Edit presentation follow-up:** [Pinned instances and held movement](plans/edit-preparation-08767-20261029/DELIVERY.md) replace release-only ordinary Mesh/Proxy movement with selected transform patches over retained geometry. Tested held samples present the new matrix without placement generation, source preparation or geometry uploads, including a copy of the 18,229-placement Terraces scene. Selected marker iteration and shared correspondence reduce repeated work. Callback timings are separated from actual presentation tickets; they are not GPU FPS, physical input latency or a claim of globally faster computation. Panel expansion/resize also preserves work counters. The artist-endorsed Bend/Trim reference remains 0.87.5.6.

The 0.87.6.7 preparation controls are opt-in per piece. They do not raise Automatic detail or alter the Bend/Trim baseline. On the supplied Violet, 16-point stem guides reduce the maximum source centreline approximation error from 7.68 to 0.80 mm; 62 explicitly selected leaves can have independent guides. Higher detail increases source preparation/pose work. This shape measurement is not a claim of faster contact solving or presented FPS.

**0.87.6.5 selection presentation follow-up:** [Mesh hover and persistent selected outlines](plans/instance-selection-08765-20261029/DELIVERY.md) retain the separate pick helper while replacing the box cue with cached, bounded visible mesh edges. Selected outlines hide during native transform gestures. Focused Max 2027 checks cover retained Manual inputs, unchanged placement/upload counters and no outline rebuilds during warm redraws, plus posed geometry and Undo/Redo. CPU redraw submission timings are not GPU FPS or physical input-to-present latency. The artistic Bend/Trim baseline remains unchanged.

**0.87.6.4 selection follow-up:** [Individual instance selection](plans/instance-selection-08764-20261029/DELIVERY.md) separates the pick helper from shared render items and replaces sampled-mesh hover with twelve box edges. Retained garden picking and navigation checks record unchanged placement/upload counters. No Bend/Trim algorithm change; this does not establish new input-to-present latency or GPU FPS.

**0.87.6.3 review follow-up:** [Review repairs](plans/interaction-review-08763-20261029/DELIVERY.md) remove repeated override-map copies and whole-placement feedback copies, and share draw quotas with compact pose packing. A focused native probe reduces a 1,024-edited-neighbor evaluation from about 520 to 3.24 ms and a one-row edit in a million-row immutable view from 96 MB copied to 208 tracked new bytes. These are scoped native probes, not Max viewport FPS or million-instance interaction qualification. Max 2027 checks separately cover draw-limit/Manual behavior, garden picking/navigation and held-input presentation. The original Bend/Trim algorithm and artist endorsement remain unchanged.

**0.87.6.1 measured follow-up:** [Terraces campaign](plans/terraces-performance-20261029/DELIVERY.md) implements the fixed/zero-Bend guide skip while preserving independent Trim/hiding and moving-parent inheritance. In its controlled real-tree replay, median native fit fell from 16.17 to 6.32 ms for fully fixed Bend and from 13.74 to 6.54 ms for zero Bend. Both have zero contact queries. The six experiments, panel reuse and 18,229-placement garden are scoped in [measurements](plans/terraces-performance-20261029/MEASUREMENTS.md). Scripted orbit had no contact work or buffer uploads; this is not physical input FPS. The original artist endorsement below is unchanged.

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

## Implemented follow-up and open work

[B41](BACKLOG.md#b41--further-interaction-performance-without-losing-the-baseline)
originally recorded 1,786 unnecessary queries in its fully fixed control case.
The 0.87.6.1 early skip closes that specific opportunity and adds a regression for
moving-parent inheritance below the fixed height. Trim and root hiding retain
their independent work. Finer spatial branch rejection and fewer transient
allocations remain investigations. The measured box proxy did not improve fit
time and was not adopted as a blanket policy. Ten thousand distant plants kept
the affected local set at nine but increased fit time; constant-time scaling is
not established. Preserve these distinctions when choosing the next experiment.

Revisit this baseline when the solver, guide hierarchy, query semantics, workload
scheduler, presentation lifecycle, source lineage, GPU bindings or quality mode
changes. Update this maintained decision and its evidence after a proven successor;
do not rewrite the 0.87.5.6 receipt or infer a new release from a documentation edit.
