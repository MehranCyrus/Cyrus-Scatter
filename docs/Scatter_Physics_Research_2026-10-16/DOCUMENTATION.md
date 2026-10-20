# Cyrus Physics Lab

**Current repair: [0.2.1 small baked colliders](COLLIDER_COOK_021.md).** Use its installer and the [0.2 workflow](ARTIST_GUIDE_020.md) for current testing. Physics Brush is the standalone Cyrus Physics Lab; it is not yet integrated into Cyrus Scatter and its package/version remain separate.

**Standalone workflow: [0.2.0 artist guide](ARTIST_GUIDE_020.md) and [bake/material/checkbox qualification](BAKE_WORKFLOW_020.md).**
Finish now bakes Editable Poly colliders; quality changes affect new strokes. The
0.1.9 repair and its test guide below are historical prerequisites, not current
completion instructions.

**Earlier follow-up: [0.1.9 hull/UI and model-lifecycle repair](STABILITY_UI_019.md).**
Use the [mountain testing guide](TEST_SCENE_019.md) for the ready scene,
quality presets, checked models, fit limits and installation. The
[0.1.7 investigation](MOUNTAIN_BRUSH_017.md) preserves the tall-pyramid stall,
contact-size handling, diagnostic wires and selectable-icon evidence. The
[0.1.6 correction](COLLISION_BINDINGS_016.md) preserves the sphere/plane incident,
proxy controls and that delivery's evidence. The [0.1.5 surface-grip delivery](SURFACE_GRIP_015.md)
introduced Stickiness (%). The guides below remain the versioned 0.1.4 foundation;
their receipts retain their original scope.

## Documentation · 0.1.4 · 3ds Max 2027

**Interactive rigid-body placement, from the first brush stroke to a recoverable composition.**

Physics Lab is an independent experimental geometry object. Draw on a receiving
surface to introduce rigid assets into a shared simulation, adjust the composition
through further strokes, then Finish or Freeze the result. Physics and its working
data are native C++; MAXScript provides the controls and bounded host commands.

This documentation describes the **0.1.4 standalone delivery**, issued on
17 October 2026. It consolidates the research, inspected implementation, retained
test receipts and subsequent artist feedback. It does not change the plugin or
authorize integration into CyrusScatter.

| Delivery at a glance | Current position |
| --- | --- |
| Host | 3ds Max 2027; Windows |
| Physics engine | Embedded Jolt CPU; PhysX is an offline comparison only |
| Interaction | Multiple brush gestures share one live world |
| Default / maximum body setting | 1,000 / 5,000, subject to other resource limits |
| Output | Retained poses displayed through a combined native mesh |
| Persistence | MAX scene, result JSON and separate live-session recovery |
| Validation | 3,174 existing native checks, 413 continuous checks, 57 installed-pair Max workflow checks |
| Artist feedback | Positive report of fast, responsive brushing; broader acceptance remains open |

## Choose a guide

| Document | Audience and purpose |
| --- | --- |
| [Artist guide](ARTIST_GUIDE_014.md) | Installation, first session, every main control, object limits, proxies, saving and practical workflows |
| [Technical guide](TECHNICAL_GUIDE_014.md) | Thread ownership, command flow, fixed steps, identity, Undo, publication, persistence, limits and source map |
| [Diagnostics and recovery](DIAGNOSTICS_GUIDE_014.md) | Symptoms, historical crash findings, log contents, recovery procedure and an actionable bug-report template |
| [Validation and delivery report](VALIDATION_REPORT_014.md) | Exact package, tested scenarios, performance measurements, user feedback and remaining acceptance |
| [Research and decisions](RESEARCH_DECISIONS_014.md) | Jolt versus PhysX, lessons from Houdini and tyFlow, design rationale, superseded proposals and future gates |

Read the artist guide before a first session. Read the technical guide together
with the validation report before changing implementation. For a failure, preserve
the recording folder and follow the diagnostics guide before rebuilding a scene.

## Historical 0.1.4 installer

[Historical CyrusPhysicsLab-0.1.4-Max2027.mzp](../../dist/CyrusPhysicsLab-0.1.4-20261017-03/CyrusPhysicsLab-0.1.4-Max2027.mzp). For current installation use the 0.2.1 repair linked above; retain this older package only with its original evidence/scenes.

Run through **Scripting > Run Script**, save work and restart Max 2027. Create the
object at **Geometry > Cyrus Labs > Cyrus Physics Lab**. The package identity and
verification details are in the [delivery report](VALIDATION_REPORT_014.md).

The earlier `-01` and `-02` package directories contain superseded internal
candidates. Keep the delivered installer with test scenes. Local `build/` and
`dist/` artifacts are ignored by Git and require their own backup.

## Concepts used throughout these guides

| Term | Meaning |
| --- | --- |
| Receiver | The mesh on which the brush can place births; it can also collide |
| Source / model | The render asset copied into the composition |
| Proxy | Simplified collision geometry associated with a source |
| Collider | Static geometry that constrains the simulated bodies |
| Birth | An authored body creation with an identity and simulation-step stamp |
| Gesture / stroke | One press–drag–release interaction |
| Session | The live world shared by several gestures until Finish, Freeze or Cancel |
| Pending | Work in the current session, before publication into the completed result |
| Completed / saved bodies | Bodies published by Finish or Freeze; “saved” here does not mean the MAX file has been written |
| Settled | The session passed its bounded quiet-motion criterion |
| Frozen | Current poses accepted explicitly, without requiring settlement |
| Recovery boundary | The last complete durable session record; it can precede the final input before a crash |

## Evidence and maintenance

The guides are an explanation of the recorded delivery. The
[implementation ledger](CONTINUOUS_BRUSH_014.md) and
[structured qualification](CONTINUOUS_BRUSH_014_EVIDENCE.json) remain the detailed
release witnesses. [Documentation provenance](DOCUMENTATION_EVIDENCE_014.json)
records inspected inputs, hashes and checks for this documentation pass.

Historical findings retain their original versions and limitations. Vendor
documentation, selected binary inspection, local code, executed tests and artist
observations answer different questions; none silently substitutes for another.
Primary-reference links remain in the original research documents. This pass did
not run a new vendor benchmark or refresh those external references.

When behavior changes, update the affected guides and record a fresh package and
test witness. Preserve old measurements. Update artist acceptance only for the
scenario actually observed. The knowledge index does not currently enroll the
lab source; direct source and recorded receipts underpin these guides.

[Research archive and chronology](README.md) · [Project guide](../../CyrusPhysicsLab/README.md)
