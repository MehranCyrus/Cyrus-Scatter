# Geometry-driven native core: 0.3.2 development

This describes implemented native changes, not a finished UI or qualified
release. See [the complete ledger](GEOMETRY_WORKFLOW_0.3.2.md) for remaining work.

## Eligibility and count

`arrange()` considers all registered source assets. Historical furniture masks,
category weights/caps and regional category masks no longer remove candidates.
Explicit per-source weights remain preferences. Excluded regions, physical
support, stable stack tops, permitted rotations, obstacles and protected output
remain authoritative. Geometry and metadata admission still rejects malformed
or over-budget inputs. Category records remain readable in released documents;
they do not impose a placement policy in the new solver.

`AmountMode::Quantity` requests a global total, including retained output. A
region cannot independently request another complete copy of that total. Later
regions may fill what an earlier region could not fit. Zero is a valid quantity.
No sources or no available support yields the original requested count with
unfilled slots. Protected excess is retained and reported, not deleted to meet
a smaller number. The current search visits regions in stable ID order; better
global mixed-size/required-object packing remains unfinished.

Fill retains an area-based estimate and finite placement search. It is not an
optimal packing algorithm. The new simple native command neutralizes old style,
clustering and empty-space multipliers so they cannot secretly alter its single
coverage target. The core remains capped by candidate, placement and work
admission. A hard computational-budget failure throws; the caller retains the
previous published result. Ordinary geometric underfill returns honest totals.

## Scale and physical checks

Default output scale is 1. Random scale samples the explicit global interval;
it does not mutate source nodes or mesh coordinates. Each candidate's final
uniform scale affects its contact footprint, collision volume and stack height.

Fit first searches all available regions at the original or randomly sampled
size. Only unfilled targets enter a second fit pass. This avoids shrinking an
object into an early compartment when a later compartment accepts it unchanged.
For a rejected fallback candidate, it tests up to sixteen descending scale samples down to the allowed
minimum. The first verified success brackets refinement with the preceding
failure. Up to twelve bisection probes refine that bracket. Successful staged
probes do not publish output; only the chosen verified candidate is added to
the current native solve. No scale below the minimum is accepted.

This is a bounded candidate-level search, not a proof of the globally largest
possible fit. Irregular geometry can have nonmonotone feasibility intervals.
The existing query checks actual receiver support/clearance and uses complete
conservative prop collision bounds. Exact irregular-prop collision refinement is
still required by item05 and has not been delivered by this first change.

## Native host transaction

`caPlacementSettings owner` returns ten values:

| Position | Value |
| --- | --- |
| 1 | Saved nonnegative Integer64 seed in the simple workflow |
| 2 | Amount mode: 1 Fill, 2 Quantity |
| 3 | Requested whole-number total |
| 4 | Fill density, 0..1 |
| 5 | Prop spacing in millimetres |
| 6 | Support-edge margin in millimetres |
| 7 | Random scale enabled |
| 8 | Fit scaling enabled |
| 9, 10 | Minimum and maximum uniform scale factors |

`caGeneratePlacement owner values freshSeed` reads bounded authored values and
stages a complete native successor through the existing Generate pipeline.
It applies settings and output together, including seed generation. It exposes
no furniture type or category input. The returned existing result tuple gives
requested, accepted, kept, candidates, unfilled and warnings. Script arrays do
not hold the numerical placement workload.

Scene schema5 appends the amount/scale settings after the prior composition
payload. Released schemas3/4 are read with neutral defaults for the new fields.
Original saved files are not rewritten during decode. Quantity and scale range
validation occurs before serialization/publication; truncated or malformed
decodes retain the caller's high-water state.

## Evidence and limits

The first accepted core snapshot is `build/native-032-space03`: thirteen native
executables passed, including 5,275 assertions in the new physical workflow
test. It independently checks 100 copies against literal support bounds and
pair separation, repeatable random scales, protected counts, cabinet overhead,
fit minimum, unchanged sources and the new scene codec.

`build/native-032-host01` and `host02` also compiled the actual Max2027 native
pair and passed thirteen native executables. Compilation is not host/UI proof.
The first owned Max fixture failed parsing at a top-level local declaration,
before any plugin assertions. That failed receipt remains unchanged. The
second run stopped in fixture setup because helper functions needed explicit
global declarations. A corrected exact-source host04 build then passed the
actual **19-check Max suite** with normal exit and all five identity/profile
guards: `build/host-032-geometry03/receipt.json`.

The core snapshot `build/native-032-space04` added global preferred-size
search and propagates the actual fitted parent pose into stack attempts. All
thirteen native executables pass, including 5,281 physical workflow checks.
The earlier 19-check host is evidence for its own frozen pair only.

The current `build/native-032-ui05` builds both modules and passes all thirteen
native executables, including automatic sampling. Its exact pair passed 52 real
Modify checks in `build/host-032-ui05`, covering inline Props/Scale, Generate
drafts, source preservation, bounds/nonoverlap, seeds, Undo/Redo, owner safety,
group-context restoration, macro creation and save/reopen. The separate current
100-copy/cabinet fixture passed all 19 checks in `build/host-032-geometry04`, with
normal exit and all five native/profile guards. The current source map matches
both hosts and the SDK build; `build/ui-032-progress03/progress.json` records it.

Full UI/options and picker acceptance, priorities, paths, lane queries,
diagnostic highlights and release/installer qualification remain open. No artist
profile has been installed or restarted by this development work. See the
[unified Modify documentation](UNIFIED_MODIFY_0.3.2.md) for current UI scope.
