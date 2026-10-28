# Contact correctness and work audit — 0.87.5.2

The user authorizes a further measured performance pass and selects 0.87.5.2.
Start from the complete 0.87.5.1 Library delivery. Preserve its Scene preset
implementation, portable recipes, source identities and independent products.
Max 2027 is the sole development/qualification host.

## Scope and ownership

Audit the existing numeric contact pipeline and retained viewport. Establish
independent geometric controls, stage/query counts and reproducible movement
costs before claiming an optimization. F04–F11 apply. The CPU fitter remains
authoritative; the existing GPU path draws its accepted poses. No new physics
engine, GPU solver or artist settings are required.

Source geometry and topology are immutable, shared per prepared source. Cache
only facts derived from that geometry. A source/settings revision rebuilds those
facts; a collider move does not. Workers consume copied numeric data and join
before atomic publication. Failed successors preserve the prior result. Derived
caches are not serialized and add no Undo records or saved schema changes.
Account new source storage and temporary preparation/query storage explicitly.

## Implemented candidate and its proof obligation

Exact guide checks currently classify every posed vertex, then check every
triangle's distance to the closed collider. The triangle checks already cover
the vertex-to-surface distance. For each indexed connected component, one
outside point plus every triangle clearing the boundary proves the entire
component is outside. Keep a representative for each component and every unused
vertex; do not equate material labels or spatial proximity with connectivity.
Keep all triangle checks and explicit fixed-root checks. A disconnected enclosed
leaf, triangle-interior crossing and unused enclosed vertex are required controls.

Cache local triangle addresses and this connectivity in the immutable Source.
The additional retained payload is 12 bytes per triangle plus 4 bytes per
component and vector headers/capacity. Temporary preparation uses a 4-byte
source-vertex address map and a 4-byte per-guide union table. The existing exact
query admission charges two buffers of at most 50,000 double-precision Vec3
values per worker (2.4 MB); reuse those for posed and obstacle-local positions.
No per-frame connectivity, source-mesh reconstruction or Max calls enter workers.

Within each candidate, reuse consecutive stem-ring frame interpolation and
identical rigid-leaf attachment transforms. Cache only exactly equal span/u or
part IDs and reset at each candidate. Preserve arithmetic and source ordering.
This needs constant scratch and cannot reuse a frame from a preceding pose.

Process diagnostics count source capture, rig realization, collider cooking,
layout creation and actual evaluations/fits. Per-evaluation counters report
exact point/face tests and transformed vertices. Preserve the last real preview
build duration; report cache-hit time separately, instead of replacing a costly
build measurement with a subsequent cheap read. Counters are observational,
process-local, monotonic and absent from scene serialization.

## Acceptance

- [x] Record baseline identity, real-model replay and stage costs.
- [x] Verify contact predicates against independent analytic/brute-force controls.
- [x] Remove measured redundant work without omitting containment or face contact.
- [x] Compare identical old/new movement traces, poses, hiding and quality warnings.
- [x] Observe no preparation/placement/contact/upload work for warm idle, camera,
  selection and unrelated animation; preserve pending Manual edits.
- [x] Test relevant movement, restoration, invalid input retention, Undo and reload
  in an owned Max 2027 profile with the matched final package.
- [x] Smoke the preserved Library Scene preset workflow on that exact pair.
- [x] Build/hash-check the Max 2027 MZP and publish scoped evidence and limitations.

Earlier deep-overlap strain warnings and the exposed-root collider limitation
remain open until independently diagnosed and verified. Output equality alone is
not proof of botanical correctness; redraw duration is not presented FPS.
