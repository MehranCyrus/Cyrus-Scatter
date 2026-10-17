# Scatter Physics research

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
