# Experiments and acceptance plan

16 October 2026. **All experiment rows below are UNEXECUTED.** This investigation ran static source/native analysis and document verification only. No counts, latency or contact quality below are qualification claims.

## First decision: evaluate contact quality before product integration

Compare Jolt CPU and PhysX CPU in an owned disposable harness using identical numeric scene inputs, proxy shapes, emission records, fixed steps and physical tolerances. Record exact revisions/compiler/options. Do not choose by unrelated vendor demo FPS. Add Bullet only for a decision-critical gap.

| Experiment | Inputs | Acceptance evidence |
| --- | --- | --- |
| Flat leaf resting | Thickened outline and curved leaf, flat street | No fall-through; final visible height/normal and penetration measured relative to proxy tolerances |
| Thin/fast contact | Height/speed/step/CCD/thickness sweep | Tunnelling rate, maximum penetration and solve cost; report failed combinations |
| Street detail | Curb, pavement edge, bench legs, gutter, gaps | Correct collision against concavity/holes; compare simplified and detailed static colliders |
| Leaves overlapping | Multi-source piles, different scales/masses | Believable overlap, contact drift and energy decay; proxy inflation/float gap quantified |
| Slope and continuous motion | Several slopes/frictions plus optional directional force | Correct declared sliding behavior; maximum-step limit cannot falsely report settled |
| Spawn penetration | Obstacle under brush, dense births | Bounded retry/underfill; no explosive depenetration or unreported skipped bodies |
| Frame/units | Metres/centimetres, large origin, off-center pivot, mirror/nonuniform scale | Equivalent physical setup and source/output transform parity within declared tolerance |
| Capacity exhaustion | Bodies, pairs, contacts, hulls and memory constrained separately | Error detected; tentative solve rejected; previous complete result preserved |

Start with one-body analytic/resting cases before progressively larger populations. Suggested exploratory tiers are hundreds, thousands and then tens of thousands of simple bodies, stopping at the measured admission/latency boundary. These are test tiers, not advertised capacity targets.

Measure preparation/cooking, broadphase/contact/solver work, memory, settle duration and result transfer separately. Record source/proxy geometry counts and final penetration/quiet-state metrics alongside speed. A fast pile with omitted contacts is a failed result.

## Then validate Max 2027 interaction

Use Max **2027 only**, a matching source/native pair and a fresh owned profile/scene. Do not load an old schema fixture or mix the 0.85.0 package with the dirty 0.85.1 source. Any future installer/version delivery follows the repository's version/MZP policy; this research chooses no version.

| Scenario | Required witness |
| --- | --- |
| Real button and physical stroke | Start through actual UI; drag slowly/quickly, pause, cross off-surface space, resize and release; queued status callbacks remain valid |
| Emission/presentation independence | Replay identical saved births under different redraw rates and preview limits; compare IDs/source choices/full transforms in the declared repeatability scope |
| Gesture Undo/Redo | Existing Undo entries, completed stroke, cancel, erase and Redo; prior independent layer transforms remain exact |
| Low heap and large result | Preserve history under the reproduced B26-style headroom boundary or reject before mutation; native storage is not proof by itself |
| Failure before/after publication | Invalid proxy, dropped contacts, failed preview allocation, late commit failure and recovery; no mixed epochs or lost prior strokes |
| Owner lifecycle | Switch layer/panel, delete active owner/collider, close/reset/load scene and unload with work pending; no stale callback or late publish |
| Manual/Live isolation | Pending unrelated edits remain pending during Physics authoring; relevant input changes follow the declared policy |
| Idle/navigation | Committed result stays unchanged; solver/cooking/preparation/upload counters remain unchanged while browsing/orbiting or changing unrelated time |
| Save/copy/merge/recipe | Completed transform/ID fidelity, owner remapping, units, missing dependencies and damaged/oversize payloads |
| Output/render parity | Render/export consume the complete committed result and source frames; proxy preview cannot leak into render assets |

Measure event-to-feedback latency, frame-time distributions and worst cancel response. Distinguish presented frames from synchronous redraw timing. Compare display caps with the same total simulated bodies; reducing visible instances must not quietly reduce physical interaction. Account for old/new snapshots, Undo and drivers when measuring memory.

## Vendor reference experiments still needed

1. Build a disposable tyFlow Birth Paint + PhysX Shape + PhysX Collision reference. Compare continuous versus mouse-release updates, time-slider policies and preview-particle removal. Observe whether simulation advances during a held gesture and whether prior strokes replay.
2. Build the [proposed Houdini network](HOUDINI.md). Verify proxy/render correspondence, actual emission timing, one-time versus repeated births and cached settled output. Inspect the installed version before adapting current Houdini 22 docs.
3. If a private implementation question still blocks design, continue a bounded native trace from the anchors in [TYFLOW.md](TYFLOW.md). Recover the actual sampling entry/caller and unwind bounds before deeper solver analysis. No need to reconstruct the whole vendor engine.

## Decision gates

- **Gate A — visual feasibility:** believable leaf contact/overlap with bounded simple proxies.
- **Gate B — engine choice:** quality, preparation, resource failure and repeatability evidence favors one engine; document unresolved tradeoffs.
- **Gate C — host feasibility:** real Max brush/Undo/cancel and retained display meet an agreed responsiveness budget.
- **Gate D — data contract:** scene/recipe/identity/units and post-solve transform ownership are reviewed.
- **Gate E — implementation authorization:** choose a bounded delivery and version only after the preceding research decisions. Nothing here starts that implementation.

The most consequential open product choices are interaction with completed strokes, direct-spray versus area priority, source/proxy authoring UX and whether final results need full recipe replay. [PROPOSED_DESIGN.md](PROPOSED_DESIGN.md) supplies concrete defaults so these can be reviewed without a speculative framework.
