# Scatter Physics research

**For the standalone workflow, start with the
[Physics Lab documentation set](DOCUMENTATION.md): artist guidance, technical
architecture, diagnostics/recovery, validation and research decisions.** It
consolidates the evidence below and records subsequent positive artist feedback
without changing the scope of historical receipts.

The current [0.2.1 repair](COLLIDER_COOK_021.md) corrects small baked static
colliders and small-object contact precision, with the exact artist-log reproduction.
It preserves the completion workflow and standalone scope below.

The [0.2.0 workflow](ARTIST_GUIDE_020.md) makes Finish/Freeze bake independent
Editable Poly colliders, isolates future collision quality and fixes checkbox-only
activation and unassigned-material colours. See [technical evidence](BAKE_WORKFLOW_020.md)
for final qualification and limits. Earlier versioned reports remain historical.

The [0.1.9 repair follow-up](STABILITY_UI_019.md) corrects small-piece cooking,
quality popup sizing, model removal/ordering and creation sizing. Use the
[0.1.9 testing guide](TEST_SCENE_019.md) for its installer and scenes. Qualification
is scoped by its linked final evidence; earlier receipts keep their original scope.

The [0.1.8 collision-quality delivery](COLLISION_QUALITY_018.md) added per-model
compound quality, checked source activation and the rolling-hull correction.
Its [mountain testing guide](TEST_SCENE_018.md) and scene remain historical.
The preceding receipts below keep their historical qualification scope.

The [0.1.7 mountain-brush and collision-display investigation](MOUNTAIN_BRUSH_017.md)
records the tall-pyramid stall, actual mountain/teapot/hard-shape tests and the
new Show collision shapes option and selectable viewport icon. It remains a
separate Max 2027 lab delivery.

The [0.1.6 collision-proxy correction](COLLISION_BINDINGS_016.md) investigates the
recorded sphere/plane incident, prevents mistaken proxy assignments and records
fresh standalone tests. Its installer is a separate Max 2027 lab delivery.

The [0.1.5 surface-grip update](SURFACE_GRIP_015.md) adds Stickiness (%), records
Houdini-informed design decisions, terrain and slope tests, current crash recovery,
and the separately packaged Max 2027 lab delivery.

16 October 2026. The original investigation was research and proposed design only. Its receipts do not include a Scatter implementation, version change, SDK build, installation, Max launch, commit or push. Follow-on standalone work has a separate execution ledger below.

**Follow-on work:** the user subsequently authorized an independent Max 2027 test
node, with no integration into Scatter and no Computer Use. See
[standalone implementation and evidence](IMPLEMENTATION.md) and the
[Physics Lab guide](../../CyrusPhysicsLab/README.md). The research receipts below
retain their original scope; they are not qualification of that later build.
The subsequent [0.1.1 brush/UI correction](BRUSH_UI_011.md) records the reported
failure, corrected collision handling, responsive controls and fresh validation.
The [0.1.2 automatic-proxy correction](AUTO_PROXY_012.md) addresses normal detailed
sources such as Sphere32 while retaining the full rendered model.
The test-only [0.1.2 outside-surface brush checks](OUTSIDE_BRUSH_012.md) cover
leaving/re-entering the receiver, release/cancel outside, edge footprint rejection,
held-stroke limits and empty-gesture Undo. They change no feature code.
The [0.1.3 crash diagnostics and lifecycle correction](CRASH_DIAGNOSTICS_013.md)
records the reproduced native null read, flushed brush/memory logs, external
dump capture, abrupt-exit durability and the qualified standalone diagnostic MZP.

The [17 October continuous-brush follow-up](CONTINUOUS_BRUSH_RESEARCH_20261017.md)
uses the [artist recording](ARTIST_LOG_013_20261017.md), current lab source and
fresh SideFX/Jolt/Max documentation to recommend one live world across gestures,
with explicit Finish, lost-body handling, Undo and recovery. It supersedes the
one-world-per-gesture proposal for that standalone experiment only; it includes
unexecuted acceptance gates and makes no implementation or integration change.

The user then authorized [0.1.4 continuous-brush implementation](CONTINUOUS_BRUSH_014.md)
in the standalone lab. That separate ledger records CB1–CB6 implementation,
current test evidence, package identity and remaining artist acceptance. The
research and earlier release receipts above retain their original status.

## Conclusion

An integrated physics placement tool is technically credible. Build it around **authored emission -> simplified collision bodies -> bounded settling -> persisted instance transforms**. Reuse Cyrus's interaction and output foundations while keeping simulated placements separate from surface-generated candidates. Choose an embedded physics engine after a controlled comparison; the earlier preference for Jolt is a prototype hypothesis, not a measured winner.

Offer two related workflows:

- **Physics Brush:** drag to emit individual assets, settle the gesture and retain its result. This addresses leaves, small stones and street debris.
- **Physics Area:** use existing Paint coverage as an emitter mask, generate a bounded population, then explicitly settle it. This adds a procedural alternative without making ordinary Paint simulate anything.

The existing layer's spacing rules cannot substitute for physical contact. Nor can physically settled rows be fed blindly through normal projection, orientation, spacing and cleanup stages: these can change or remove supporting bodies after the solve.

## Read the investigation

| Document | Contents |
| --- | --- |
| [PHASED_PLAN.md](PHASED_PLAN.md) | Original gated plan, starting with Jolt/PhysX comparisons and Max 2027 brush tests; follow-on execution is tracked separately |
| [CONTINUOUS_BRUSH_RESEARCH_20261017.md](CONTINUOUS_BRUSH_RESEARCH_20261017.md) | Follow-up Houdini research, continuous live-session architecture, boundary/Undo/recovery policies and proposed CB1–CB6 acceptance gates |
| [CONTINUOUS_BRUSH_RESEARCH_20261017_EVIDENCE.json](CONTINUOUS_BRUSH_RESEARCH_20261017_EVIDENCE.json) | Research source identities, primary references, knowledge freshness and preservation checks |
| [IMPLEMENTATION.md](IMPLEMENTATION.md) | Follow-on standalone node, execution receipts and remaining acceptance |
| [IMPLEMENTATION_EVIDENCE.json](IMPLEMENTATION_EVIDENCE.json) | Exact independent build/package identities and scripted-test receipts |
| [BRUSH_UI_011.md](BRUSH_UI_011.md) | 0.1.1 brush failure reproduction, UI corrections and validation limits |
| [BRUSH_UI_011_EVIDENCE.json](BRUSH_UI_011_EVIDENCE.json) | Exact corrected pair, package, native-layout and isolated-installer receipts |
| [AUTO_PROXY_012.md](AUTO_PROXY_012.md) | Sphere32 rejection, automatic convex proxies, custom override/reset and acceptance |
| [AUTO_PROXY_012_EVIDENCE.json](AUTO_PROXY_012_EVIDENCE.json) | Exact 0.1.2 pair, preserved render geometry, package and host receipts |
| [CYRUS_SOURCE.md](CYRUS_SOURCE.md) | Current source map, reusable components, lifecycle and integration gaps |
| [TYFLOW.md](TYFLOW.md) | Official workflow, fresh Ghidra results, address map and limits |
| [HOUDINI.md](HOUDINI.md) | Procedural node recipe, identity, proxies, emission and caching lessons |
| [ENGINES.md](ENGINES.md) | Pinned GitHub source observations and Jolt/PhysX/Bullet comparison |
| [PROPOSED_DESIGN.md](PROPOSED_DESIGN.md) | Artist workflow, ownership, persistence, scheduling and decisions |
| [VALIDATION.md](VALIDATION.md) | Unexecuted experiments, acceptance criteria and research gaps |
| [SOURCES.md](SOURCES.md) | Primary references, inspected revisions and continuation instructions |
| [EVIDENCE.json](EVIDENCE.json) | Source hashes, native identity, selected-function ledger and preservation checks |
| [KNOWLEDGE_STATUS.json](KNOWLEDGE_STATUS.json) | Stale knowledge index observation; direct inspection used instead |

## Evidence categories

**SOURCE** means current local Cyrus code or a named upstream source revision was inspected. **VENDOR DOC** means publicly documented behavior, without a new runtime witness. **NATIVE** means selected disassembly/RTTI/import evidence in a hash-pinned binary. **PROPOSAL** means our own design. **OPEN** means untested or unresolved. These categories do not imply one another.

The inspected tree is branch `codex/workflow-0.75`, HEAD `9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c`, with substantial pre-existing tracked/untracked work. README's qualified baseline is 0.85.0/schema 58; the working CMake/controller identify in-progress 0.85.1 and recipes format 5. This study qualifies neither delivery. See [source scope](CYRUS_SOURCE.md).

Final fingerprinting detected concurrent changes in the controller/template and recipe files. This research did not edit them. Relevant preparation/recipe sections were re-inspected; before/after hashes and the drift are retained rather than claiming a frozen whole-tree snapshot.

## Actual work and its limits

- Inspected authoritative native sources and generated-controller template, foundation contracts and current handoff.
- Used GitHub tools to fetch the installed Ghidra MCP release documentation and inspect pinned Jolt, PhysX and Bullet source. Studied official tyFlow, SideFX and Autodesk documentation.
- Verified installed/private tyFlow 2027 hashes, copied its Ghidra project and performed fresh selected analysis using the already installed Ghidra 12.1.4 / MCP 6.0.0 / Java 21 stack.
- Saved and closed the copied project, stopped only the verified owned backend process, and retained private analysis artifacts in the ignored run.

During the original research, no physical brush, simulation-quality or performance experiment was executed in Max, Houdini or a physics harness. Subsequent scripted Max and numerical results belong to IMPLEMENTATION.md. No vendor physics solver was fully reconstructed. Read [TYFLOW.md](TYFLOW.md) before treating decompilation completion as behavioral proof. A complete inventory of every plugin or algorithm is outside this bounded study.

The [phased plan](PHASED_PLAN.md) turns the engine-neutral matrix in [VALIDATION.md](VALIDATION.md) into sequenced experiments, decisions, implementation stages and delivery gates. Its first work package was Jolt/PhysX comparison plus Max 2027 brush tests. The user later authorized the independent test node; see IMPLEMENTATION.md for actual results and remaining gates. The historical plan does not authorize integration into Scatter or amend the existing improvement program.
# Standalone repair successor: 0.1.9 — qualified

Scope authorized 18 October: reproduce the artist's 0.1.8 convex-hull failures,
repair bounded numeric hull cooking, correct the quality popup, replace palette
All/None/Solo with Add (+), Remove (×), and Replace, and match Scatter's scene-unit
creation/drag icon behaviour. This is a patch successor to delivered Lab 0.1.8;
Scatter stays 0.86.0. Registration identities and numeric input format stay intact.

F05–F11 apply: native copied geometry owns cooking; invalid geometry retains the
previous result. Model removal unlinks future emission, preserves already placed
bodies/material slots, and is Undoable. Native source slots remain stable, with
removed used slots retained as numeric snapshots; unused slots can be reused.
The palette edits are bounded by 64 slots, and pending sessions reject edits.
Caches remain transient; removal Undo stores bounded binding references/policies,
not placement-sized copies. Saved native policies record palette membership.
No artist profile installation, Computer Use, presets, or Scatter integration.

Acceptance completed in the [0.1.9 report](STABILITY_UI_019.md) and [machine evidence](STABILITY_UI_019_EVIDENCE.json): recorded failing hulls in single/mixed palettes; all quality
modes; thin/offset/scaled geometry; continuous/outside strokes and Undo; palette
remove/re-add/save/reopen; popup geometry at narrow widths/DPI; creation sizing;
Max 2027 exact-pair qualification and runnable installer.
