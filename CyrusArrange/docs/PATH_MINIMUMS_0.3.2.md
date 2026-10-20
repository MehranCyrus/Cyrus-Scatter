# Required copies along paths — 0.3.2 development

Status: current exact pair passed seventeen native suites and 170 actual Max
checks, including 88 mounted Modify checks. This remains development evidence.
The completed
surface packing checkpoint is [recorded separately](PACKING_PRIORITY_0.3.2.md).
This extension removes its temporary nonzero-path-minimum restriction. It does
not complete the full geometry redesign or qualify an installer.

## Behavior and ownership

The existing **Props → Min copies** control works for a bound path through the
same native typed policy as surface placement. There is no new rollout, popup
or separate Apply step. A minimum applies globally across the active one/two
lanes. For three copies in each lane, a minimum of four is valid within the
combined total of six. Registered source weights remain positive and govern
optional demand; a required count is reserved independently of the weighted draw.

Protected output is validated and counted before new demand. Its counts satisfy
source minimums once. Required deficits reserve available lane capacity before
weighted optional copies. Required sources are processed before optional ones;
each class uses descending volume/footprint/height and stable source-ID ties.
The native solver searches remaining slots at the preferred size before any
allowed uniform reduction. Every final pose retains full lane, collision, and
optional road-support/overhead validation after scale, heading and jitter.

Optional weighted choices are preferences. If they cannot fit, a later bounded
pass tries other selected sources in unreserved slots. It cannot consume copies
reserved for an impossible required source. A failed complete slot search ends
that source's fallback batch, with candidate/work caps still authoritative.

A required source that cannot fit keeps its reserved copy unfilled. Missing
minimums name the source and count in warnings. Requested/accepted/unfilled lane
totals remain explicit. With spacing mode, native arc length and center spacing
determine the actual available slots; minimums exceeding that result reject.
Overfull protected lanes cannot donate fictitious free slots to another lane.
Invalid input and work-budget exhaustion retain the previous complete document
and output through the existing publication transaction.

Clearing a Quantity path copies the combined active lane total into surface
Copies before removing the binding. It preserves minimum policies and current
output pending Generate. In spacing mode it uses the current output count,
bounded by output admission and at least the minimum sum; without outputs it
uses the saved Copies value. It does not capture or solve a curve when clearing.
Modify rebases mode/count to native values while restoring genuinely pending
gap, scale, seed and per-source edits. Undo restores the actual binding and previous
first/other lane quantities. No source mesh, material or class identity changes.

## Numeric implementation

`PathRequest` appends a borrowed synchronous `AssetMinimum` span. It carries no
Max references. `caGeneratePathMinimums` stages placement/path/minimum drafts
together, and existing Generate routes honor saved policies. Scene schema7
already stores these policies, so this extension adds no new scene format.

Native admission validates at most two lanes, 256 assets/policies and the
configured output cap, at most 10,000 copies. Bounded slot records retain lane,
slot and filled state; source demand uses stable-ID maps and source pointers.
Candidates, slot visits, comparisons, validation and query work charge the same
budget. No unbounded packing pass, retained geometry cache or MAXScript placement
loop is introduced. Failed candidates cannot consume a slot or publish an ID.

The surface kernel additionally normalizes each saved yaw modulo 360 before
trigonometry and relative-angle subtraction in edge-adjacent proposals. A finite
saved rotation such as `1e308` must produce the same finite proposals as its
normalized rotation. It keeps the original protected pose value intact.

## Verification scope

New native cases exercise twelve seeds, low-weight required sources, source-array
reordering, protected minima, combined and spacing totals, impossible reserved
copies, fit floors, full required totals, candidate limits, lane capacity and
independent straight-lane/pair envelope measurements. The existing curved-lane,
100-car budget, original-size preference and lifecycle tests also run. Surface
tests compare every bounded proposal for extreme versus normalized protected yaw.

The Max path fixture adds actual mixed source nodes, global four/five-copy
policies over 3+3 lanes, independent output bounds and gap checks, repeatability,
invalid transaction retention, Undo/Redo, clear-path total preservation and
schema7 save/reopen. The mounted Modify fixture adds path minimum drafts,
Generate, inline readback and clear-path totals through real handlers.

The first native attempt `build/native-032-path-min-core01` built successfully,
then passed 16 of 17 suites. Its new path test incorrectly used a zero-weight
asset, rejected by existing source admission before the new assertions. The
fixture was corrected to a low positive weight; the original failed log is
preserved. The subsequent full SDK attempt is
`build/native-032-path-min-host01`, which passed both native modules and all
seventeen suites, including **8,150 path**, **5,174 surface packing** and **66
minimum persistence/admission checks**. The surface test's borrowed spans are
refreshed after changing their owning vector; no stale test span is relied on.
Owned Max2027 Batch `build/host-032-path-min-api01` passed **35 checks**, exited
normally and passed all five loaded-module, binary, private-INI and artist-profile
guards. This includes the actual mixed 3+3 lane output and every new path policy,
transaction, clear-path and save/reopen witness above. The corresponding mounted
Modify run was `build/host-032-path-min-ui01`; its failure and successor proof
are recorded below. No artist installation or computer use occurred.

That first mounted run failed after 83 passes at the new mode-switch witness.
Its path was in Center spacing mode: the inactive saved Copies value and minimum
sum produced four after clear although six outputs were visible. This was not
the Quantity case already proved by the native API run. The failed receipt is
preserved. The fix gives spacing clear explicit output-count semantics and
rebases the UI instead of treating an inactive count as an authored draft.
Additional tests cover spacing-clear Undo and preservation of unrelated pending
gap/minimum edits. Optional-source fallback has its own physical/native witnesses.
The successor frozen build `build/native-032-path-min-host02` passed both native
modules and all seventeen suites, including **8,199 path**, **5,174 packing** and
**66 minimum persistence/admission checks**. Its transient CA version is6, with
the same attribute identity and five sections. The actual Max successors are
`build/host-032-path-min-api02` and `build/host-032-path-min-ui02`; their passed
terminal receipts and matching regression campaign are recorded next.

## Current terminal qualification

Both successor hosts passed: **37 path API** checks and **88 mounted Modify**
checks, including the failed spacing-clear witness, pending gap/minimum drafts
and Undo. Matching current-pair **26 detailed shelf/stair** and **19 geometry/fit**
checks passed. All four hosts exited normally with all five exact-module, binary,
private-INI and artist-profile guards. The four receipts match the same current
154-file source map and both qualified native module hashes.

Independent verification of exported actual meshes passed with four correctly
rejected invalid controls. The same 100-book and 48-prop distributions and export
hashes from the surface packing checkpoint remain intact. Current generation
calls measured 102/55 ms after preparation, with the owned UI campaign running
concurrently. These are single observations, not a before/after performance or
FPS result. Current proof is
`build/path-minimums-032-progress01/progress.json`; its six receipt digests, cases,
native/source identities, measured gaps/errors and remaining scope are explicit.

No development installer was delivered, no artist profile was changed and no
computer use occurred. Earlier attempt receipts retain their failed or historical
scope. Full release acceptance remains open.

Explicit book-row composition with minimums remains unsupported. Irregular
source-envelope refinement, useful failure highlights, inline independent
overrides, complex real-world road/receiver models, broader units/performance
coverage and final package acceptance remain in the
[full ledger](GEOMETRY_WORKFLOW_0.3.2.md).

The subsequent [compound-collider checkpoint](COMPOUND_COLLIDERS_0.3.2.md) is the
current exact source pair:18 native suites and187 Max checks, including the same
37 path and88 Modify checks. It adds conservative occupied-source refinement to
surface/path pairs and static queries while retaining these count/mode contracts.
