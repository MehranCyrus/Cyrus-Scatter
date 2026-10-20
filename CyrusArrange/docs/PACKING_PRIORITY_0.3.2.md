# Required props and geometry packing — 0.3.2 development

Status: implemented for ordinary surfaces and qualified in the focused cases
below. This is a development checkpoint, not a release or a complete packing
optimizer. The full [acceptance ledger](GEOMETRY_WORKFLOW_0.3.2.md) remains active.
Original 0.3.1 packages and earlier receipts are preserved.

## Artist behavior

The normal workflow remains receiver, props, Copies and Generate. The native
solver gives larger selected objects room before optional smaller clutter and
distributes search among usable spaces. Furniture labels do not restrict props.

An optional **Min copies** field sits beside the selected source in **Props**
inside Modify. Zero means no required minimum. Positive entries appear in source
labels, for example `Book [min 8]`. This is a minimum within the arrangement's
total Copies, not extra copies added to that total. Protected copies count once
toward both totals. Pending minimums, scale, quantity, seed and other visible
settings commit with Generate. There is no Apply button or new settings window.
Reusable-group creation preserves pending per-source values when Max rebuilds
the Modify context. Removing a registered source removes its policy atomically.

A required object which cannot pass the physical checks leaves its reserved
copy unfilled; the solver does not hide it by substituting smaller clutter.
Impossible authored totals fail before publication, retaining the last complete
settings, seed and output. Optional fit scaling still tries preferred size first
and accepts only a physically checked uniform reduction within permitted limits.

At this checkpoint, minimums with explicit book-row composition are rejected.
Path minimums are being integrated: a nonzero policy currently rejects path
Generate with an explanation; clearing the minimum draft to zero allows ordinary
path generation in the same transaction. These are explicit remaining boundaries,
not claims that the full required-copy feature is finished.

The subsequent [path-minimum extension](PATH_MINIMUMS_0.3.2.md) removes the
temporary path restriction. It has its own fresh source map and qualification;
the historical checkpoint below does not certify that later implementation.

## Native ownership and algorithm

C++ owns `AssetMinimum`, validation, required deficits, source demand, packing,
physics, saved policies and publication. MAXScript owns a bounded presentation
draft and calls one native Generate command. It does not compute placements.

The surface solver validates unique known source IDs, at most 256 positive
policies and at most 10,000 aggregate required copies. It accounts for preserved
output before assigning new work. Required deficits precede optional demand;
within each class, nominal volume, footprint and height determine descending
size order, with stable identity tie-breaking. Optional demand uses existing
weights, then packs larger objects before smaller ones. Required counts are
explicitly reserved rather than depending on a source winning a weighted draw.
Registered source weights retain their existing positive-value admission rule.

Space search balances used envelope area and bounded attempted work against
usable area, with seeded ties. Initial proposals use the projected source
rectangle to avoid wasting samples where its envelope plainly exceeds a space.
Later proposals can use edges of accepted envelopes. Neither proposal shortcut
accepts a placement: every final pose still passes sampled region membership,
full footprint support, edge margin, overhead/static geometry and output spacing
queries. Ordinary stacking and authored clustering remain supported.

The original/preferred-size pass searches all usable spaces before descending
fit probes and refinement. Failed required slots remain reserved. Counts and
candidate/query budgets bound work. This is a seeded heuristic, with legitimate
underfill, rather than a proof that no better packing exists. Existing complete
source envelopes remain conservative for irregular models; mesh/compound
refinement is still required by the full objective.

Fill without minimums retains independent per-region seeded behavior. Each
region uses the same priority solver, with other accepted regions supplied as
explicit obstacles. Delegated validation, candidates, geometry work and bounded
scratch are charged to the outer admission budget. Quantity is a global target.

## Storage and API

Scene schema **7** appends a bounded minimum-count footer after schema6's optional
path layout: one `u64` count followed by `(u64 asset ID, u64 copies)` pairs. The
empty footer is eight bytes; at most 256 rows require 4,112 bytes. The decoder
accepts schemas3–7, supplies no invented policies for older files, and validates
the whole state before publishing it or advancing identity high-water marks.
Library2, registry1, native class IDs and the seven Document reference slots are
unchanged. Original saved files are not rewritten by reading them.

- `caPropMinimums owner` reads positive `#(assetID, minimumCopies)` rows without
  capturing geometry or solving.
- `caGeneratePlacementMinimums owner values10 minimumRows freshSeed` stages
  policies and all placement drafts in one output transaction.
- `caGeneratePathMinimums owner values10 pathValues19 minimumRows freshSeed`
  provides the equivalent typed path entry; the current nonzero-path limitation
  above is checked explicitly.

Input rows permit zero to clear a policy. Unknown IDs, duplicate rows, fractions,
negative values, excessive totals and stale owner tickets reject before output.
The transient Modify custom attribute is version5. It keeps the same identity,
five sections and native owner binding. Its Min copies spinner edits a draft;
opening Props, changing selection and hydration never trigger analysis.

## Focused qualification, 18 October 2026

Frozen SDK pair: `build/native-032-packing-host02/receipt.json`. Both Max2027
modules and all **17 native suites** passed. New packing tests exercise 24 seeds,
required large objects, impossible reservations, complete support/nonoverlap,
balanced spaces, protection, repeatability and bounded uniform fit. Storage tests
cover schema7 roundtrip/corruption, schema6 migration and combined path totals.
The former geometry golden remains intact; a separate reviewed packing golden
records changed seeded layouts with the same six analytical target counts.

Owned normal Max2027 `build/host-032-packing-ui01/receipt.json` passed **83 mounted
Modify checks**. These include atomic minimum drafts, rejected excessive values,
preservation across group-context rebuilding, saved minimum hydration, Generate,
Undo/Redo, paths and absence of extra settings dialogs. Normal exit and all five
loaded-module, binary, private-INI and artist-profile guards passed.

Owned Max2027 Batch `build/host-032-packing-shelves01/receipt.json` passed **26
checks** on actual output geometry. It used one complete imported prepared book
(1,361 vertices, 2,672 triangles), with its authored UV/material, and modeled
receivers, fruit and bin. Original library scenes, metadata and maps stayed
byte-identical. Minimum policies, invalid-draft retention, protected poses,
repeatability, Undo and schema7 save/reopen passed.

| Measured generation case | Result | Distribution | Generate call |
| --- | --- | --- | --- |
| Detailed upright books | 100 / 100 | Shelf levels: 24, 23, 26, 27 | 59 ms, 1,048 candidates |
| Mixed stair props, books ≥8 and bins ≥4 | 48 / 48 | 15 books, 16 bins, 17 fruit; six treads: 8, 8, 6, 6, 12, 8 | 28 ms, 1,283 candidates |

Timings are single generation calls after scene preparation on this machine.
They exclude startup, model loading, export and rendering; they establish no
general latency/FPS guarantee. The preceding checkpoint measured 118/75 ms and
different distributions; those receipts remain historical rather than replaced.

`tools/verify_shelves_stairs.py` independently checked actual exported vertices,
complete footprint contact, exact box receiver solids, static/pair avoidance and
source topology. Minimum measured envelope gaps were **2.004974 mm** against a
2 mm requirement and **10.003906 mm** against 10 mm. Maximum source-to-output
world-vertex errors were **0.0005413 mm** and **0.0014100 mm**. All four shelf
levels, six treads and required source counts passed. Deliberately floating,
off-support, overlapping and broken-receiver exports were correctly rejected.
UV1/material-root identity was checked in Max, separately from this verifier.

Evidence: `build/host-032-packing-shelves01/independent-shelves-stairs.json`.
No artist installation, artist-session commands or computer use occurred.

## Research decisions and remaining work

SideFX's documented [Scatter and Align](https://www.sidefx.com/docs/houdini/nodes/sop/scatteralign.html)
separates count, density and spacing; [Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html)
also distinguishes independent density sampling from an imposed total. These
support keeping our Fill and Quantity semantics distinct; our reservation and
priority heuristic is our own implementation, not a reproduction of Houdini's.

Houdini's [instance attributes](https://www.sidefx.com/docs/houdini/copy/instanceattrs)
distinguish position, orientation, pivot and uniform scale, and
[RBD Configure](https://www.sidefx.com/docs/houdini/nodes/sop/rbdconfigure.html)
documents collision representations separately from visual geometry. We retain
the original source and store placement transforms separately. The latter
reference informs planned irregular collision refinement; this checkpoint has
not implemented that refinement. References checked 18 October 2026.

Continue path minima, irregular geometry refinement, useful per-object failure
feedback/highlights, inline independent overrides, real curved-road models,
units/performance/lifecycle coverage and the final exact installer campaign.
Passing this checkpoint does not complete the fourteen-item goal.
