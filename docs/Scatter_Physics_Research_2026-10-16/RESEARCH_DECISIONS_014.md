# Physics Lab research and design decisions

**Consolidated rationale · standalone 0.1.4 · 17 October 2026**  
[Documentation home](DOCUMENTATION.md) · [Technical guide](TECHNICAL_GUIDE_014.md)

## The problem being solved

Conventional scatter placement distributes transforms according to surfaces,
spacing and authored masks. A physics brush also needs temporal state: new
objects can fall, collide, move older objects and settle into a composition.
The original request was to brush assets such as leaves onto a street and obtain
more convincing contact through rigid-body simulation.

The implemented model is **authored emission → collision proxies → bounded
simulation → retained result**. A continuous session lets the artist add several
gestures while earlier bodies move. Explicit Finish/Freeze separates ongoing
simulation from acceptance of the composition.

The earliest proposal settled one gesture before accepting the next. That
proposal was superseded after source investigation and the 0.1.3 artist recording
showed the interaction cost of waiting for a whole batch, including falling
objects outside finite support. The original documents remain historical;
the [continuous follow-up](CONTINUOUS_BRUSH_RESEARCH_20261017.md) and 0.1.4
implementation describe the successor.

## Research coverage and evidence types

| Source family | What was actually examined | What it supports |
| --- | --- | --- |
| Cyrus code/contracts | Existing brush, ownership, persistence, display and host boundaries | Reuse opportunities and integration constraints |
| Jolt / PhysX / Bullet source | Pinned public source and API behavior through GitHub research | Candidate capabilities and adapter design; source alone does not rank performance |
| Houdini documentation | Stroke, painting, packed RBD emission, proxies, identity, caching and Vellum | Workflow concepts and distinctions; no local Houdini runtime qualification |
| tyFlow | Official operator documentation plus selected native RTTI/callback/import inspection | Related Max Painter and Undo integration; no full solver/scheduler reconstruction |
| Local experiments | Native solver comparisons and isolated Max 2027 fixtures | Recorded behavior for specific builds/inputs only |
| Artist recording / feedback | Supplied 0.1.3 recording and later positive 0.1.4 response | Actual recorded rejection sequence and subjective response; neither is a universal benchmark |

The original [source register](SOURCES.md), [engine research](ENGINES.md),
[Houdini study](HOUDINI.md), [tyFlow study](TYFLOW.md) and their evidence files
retain primary links and inspected revision identities. This document synthesizes
that work; external references were not re-fetched during documentation assembly.

## Jolt versus PhysX

The standalone implementation pins Jolt to
`1b2e77e3c6c09709e5edc79dc208459b8ff32051` and PhysX to
`b97365c6ddb32fda8469bc788ec18024862b0368`. Jolt CPU is the installed lab solver.
PhysX CPU is compiled into offline comparison tools, not the Max modules. Bullet
was part of source research and is not a third measured lab implementation.

The final original comparison cohort passed **80/80** numerical runs: two engines,
four scenarios, 1/100 bodies and five repeats. Inputs shared metre geometry,
births, the 1/120-second clock, four substeps and recorded physical settings.
Internal algorithms and contact tuning were still engine-specific.

| Historical 100-body fixture | Jolt median solve | PhysX median solve |
| --- | ---: | ---: |
| Flat | 30.54 ms | 26.37 ms |
| Pile | 1,567.77 ms | 165.59 ms |
| Curb | 32.32 ms | 26.80 ms |
| Fast drop | 33.82 ms | 38.94 ms |

These are **historical exploratory solve times**, not 0.1.4 brush latency or
presented FPS. The retained gate checked completion, floor penetration below
0.5 mm and body-pair penetration below 1 mm. The curb case did not include an
exhaustive curb-penetration oracle. Runs shared the workstation, and the full
original E01–E10 matrix was not completed. Earlier failed/time-limited cohorts
remain in the record rather than contributing to a successful speed ranking.
[Original comparison and limitations](IMPLEMENTATION.md#engine-comparison-and-provisional-decision).

**Decision:** keep Jolt as the provisional lab engine because the thin-body
configuration and independent Max adapter had been exercised end to end.
PhysX was substantially faster in the recorded pile; Jolt was not selected on a
claim of universal speed superiority. A production engine decision still needs
matched curved-leaf, general-support and dense-scene quality/cost evidence.

## Lessons from Houdini

The study separates the user gesture, the emitted rigid piece, its collision
representation and its retained output. These ideas informed the lab's own
implementation; no claim is made that it recreates a Houdini node network.

| Studied concept | Lesson applied in the lab | Boundary |
| --- | --- | --- |
| Stroke versus Attribute Paint | A path that emits births is different from a density/mask field | Physics Brush and Physics Area remain separate inlets |
| Packed RBD identity | Keep stable per-body correspondence as populations change | Lab IDs are persistent high-water identities rather than transient row numbers |
| Render geometry versus simulation proxies | Solve bounded geometry while retaining render detail | Current dynamic proxies are convex, without general concave decomposition |
| RBD emission and active/sleeping state | New pieces can join a continuing world | The lab's live world spans gestures; completed sessions become fixed blockers |
| Solver substeps and caching | Distinguish simulation time, work cost, cached output and resumable state | Fixed-step worker and explicit scene/recovery/result contracts |
| Deleting unsupported simulated pieces | Bound work from bodies that fall away | The lab's whole-bounds lower-plane rule is its own policy |
| Vellum deformable motion | Flutter/bending is a different problem from rigid placement | Cloth, wind and deformable leaves remain out of scope |

Original vendor links and proposed network details are in
[HOUDINI.md](HOUDINI.md) and the
[continuous-brush research](CONTINUOUS_BRUSH_RESEARCH_20261017.md).
The Houdini workflow was researched, not executed or benchmarked locally.

## Lessons from tyFlow and Max Painter

The documented tyFlow study covered Birth Paint and physics-related operator
concepts. Selected native evidence confirmed a Painter canvas base and an Undo
integration path in the inspected Max 2027 binary. Several stroke/session
callbacks and cleanup helpers were inspected. Detailed evidence remains pinned
to that binary hash and the original analysis ledger.

The sampled PaintStroke callback returned success immediately; the actual
emission/evaluation path was not fully reconstructed. PainterDisplay analysis
had a decoding gap/type warning, and solver threading, exact birth storage,
collider-cache keys and the complete held-gesture scheduler remained unresolved.
It would be inaccurate to say the team recovered or copied tyFlow's physics engine.

**Decision:** reuse the supported Max Painter interaction family, explicitly own
temporary and completed state, connect Undo deliberately, and validate lifecycle
through real SDK callbacks in isolated hosts. These are locally implemented
contracts, not assumptions that tyFlow's internals match ours.
[Full native scope and open questions](TYFLOW.md).

## Maintained decision register

| Decision | Reason | Implemented result / remaining tradeoff |
| --- | --- | --- |
| Keep the experiment standalone | Validate behavior without changing main Scatter ownership or output | Separate object/modules/installer; integration remains a later task |
| Native C++ owns numeric work and lifetimes | Avoid placement-sized script transport; make thread/state ownership explicit | MAXScript remains the compact control layer; language alone is not proof of speed or safety |
| One world per live session | New strokes must interact while older bodies move | More complex history, recovery and lifetime management |
| Dedicated worker, copied inputs | Keep Max API access on its host thread while simulation advances independently | Capture/publication and individual expensive steps still have costs |
| Explicit Finish and Freeze | Separate settled acceptance from accepting current poses | Finish can time out; Freeze records an unsettled result |
| Completed output becomes fixed support | Avoid surprise motion in accepted work | Later sessions cannot wake old bodies without explicit Rebuild |
| Whole-world stroke Undo | New bodies can change older bodies | History/checkpoint memory needs separate admission |
| Native checkpoint in memory; canonical recipe on disk | Fast local Undo with controlled persistence | Resume needs the matching solver and valid inputs |
| Clip every footprint candidate and break misses | Prevent unsupported births and bridges across gaps | Already-emitted bodies may still leave the surface |
| Remove whole bodies below all support | Prevent indefinitely falling bodies from blocking completion | Falling births remain in authored history; no unlimited stream loophole |
| Automatic convex proxies with custom override | Ordinary render models should work without manual simplification | Convex envelopes can overestimate curved/concave geometry |
| Bounded queues, work, geometry and history | Limit resource growth and retain a usable previous result | Counts/settings can be rejected before the UI maximum |
| Durable logs plus recovery files | Retain causal data and accepted work around host failure | Final events/dumps cannot be guaranteed under every failure mode |
| Birth catalog for recovery | Repeated full histories created measurable overhead | Recorded recovery size and scripted latency improved; limits remain |

## What remains a proposal

The research contains a larger vision than the installed lab. Main-plugin Paint
coverage, ordered-layer integration, retained instancing, richer material support,
animation/seek semantics, deforming colliders, wind/cloth, local re-settling and
larger production populations require separate design and validation. Their
presence in a research diagram does not mean they are shipped.

A future merge should first establish artist workflow/contact acceptance, then
define the exact main-plugin setting owner, dependencies, identity, Undo, memory,
display and persistence contract. Simulated poses must not be silently projected,
relaxed or cleaned up by ordinary scatter stages in ways that destroy support.
Any engine/capacity decision should compare quality and latency for the same
representative scene before selecting an implementation.

## Research chronology

| Record | Purpose and status |
| --- | --- |
| [Original investigation](README.md), [phased plan](PHASED_PLAN.md) | Research and proposed gates; not qualification of later builds |
| [Standalone implementation](IMPLEMENTATION.md) | First native lab and bounded engine comparison |
| [0.1.1 brush/UI correction](BRUSH_UI_011.md) | Corrected interaction/layout and scoped host checks |
| [0.1.2 automatic proxies](AUTO_PROXY_012.md) | Detailed-sphere workflow and render-geometry preservation |
| [0.1.2 outside checks](OUTSIDE_BRUSH_012.md) | Test-only observation of the older boundary behavior |
| [0.1.3 diagnostics](CRASH_DIAGNOSTICS_013.md) | Controlled native-null reproduction, lifecycle correction and durable capture |
| [Artist recording](ARTIST_LOG_013_20261017.md) | Settling rejections and finite-support observations; no fatal error in that recording |
| [Continuous research](CONTINUOUS_BRUSH_RESEARCH_20261017.md) | Successor architecture and CB1–CB6 plan |
| [0.1.4 delivery](CONTINUOUS_BRUSH_014.md) | Implemented continuous session and current retained qualification |
| [Current validation report](VALIDATION_REPORT_014.md) | Consolidated evidence plus later positive artist feedback |

Read historical records for cause and evidence, and the current artist/technical
guides for the delivered workflow. This preserves the learning without presenting
retired behavior as current instruction.
