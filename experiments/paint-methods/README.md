# Paint Methods Lab

Planning baseline: 10 October 2026, Cyrus 0.77, `880ea89b654a389191c02e7a373807044ec713f1` on `codex/workflow-0.75`.

**Status: four standalone 0.1.0 prototypes built and initially tested.** [Results, failures and timings](results/0.1.0-2026-10-10/README.md) record 9,792 native assertions, 186 scripted Max checks and four isolated package smoke passes. This is partial qualification; no method has won. This lab is separate from Cyrus. Choose using correctness, measured responsiveness and the artist's experience.

## The four experiments

| Prototype | What it saves | Why test it | Main risk |
| --- | --- | --- | --- |
| [A — Vector Regions](methods/01-vector-regions/README.md) | Closed boundaries and holes | Directly editable planting borders; Forest-inspired terrain workflow | Complex polygon edits; ambiguous projection on folds/spheres |
| [B — Tiled Density Mask](methods/02-tiled-mask/README.md) | Current grayscale values in sparse projected tiles | Local updates and soft density without querying old strokes | Resolution, memory and projection limitations |
| [C — Surface Stroke Volumes](methods/03-surface-volumes/README.md) | Mesh-anchored swept brush segments and operation order | Analytic coverage; test the approach suggested by the inspected Chaos path | Overlapping history, boundary extraction and paint reaching nearby surfaces |
| [D — Baked Surface Field](methods/04-surface-field/README.md) | Current values in small per-face surface tiles | Curved surfaces without artist UVs or history replay | Seams, topology changes and resolution management |

These are four different authoritative data representations, not four settings of the current brush. A and B initially target terrain or a single-valued projection. C and D also attempt freeform meshes. A terrain winner need not be the freeform winner.

## Read next

- [Implementation plan](docs/IMPLEMENTATION_PLAN.md): scope, common behavior, milestones and delivery.
- [Trial instructions](docs/USAGE.md): launch a separate Max process and compare the four tools.
- [Feature status](results/0.1.0-2026-10-10/FEATURE_STATUS.md): implemented scope, control checks and remaining gates.
- [Test plan and acceptance gates](docs/TEST_PLAN.md): identical trials, measurements and decision process.
- [Research ledger](docs/RESEARCH.md): what sources establish, what remains unknown and local tool checks.
- [Planning inventory](evidence/planning-inventory.json): source hashes, installed vendor hashes and available tool files.

## Progress

- [x] Inspect current brush failure paths and prior qualification limits.
- [x] Review existing Forest/Chaos binary research and selected local exports.
- [x] Recheck installed vendor hashes and local analysis/build tool files.
- [x] Review relevant official documentation and public implementation candidates.
- [x] Define four independent methods and a common comparison contract.
- [x] Define correctness gates, performance experiments and staged implementation.
- [x] Build the minimal isolated host harness.
- [x] Implement one small working slice of each method.
- [x] Run initial comparison fixtures, publish measurements and package the four trials.
- [ ] Artist tries the trials; record actual interaction feedback.
- [ ] Select, revise or reject candidates on evidence.
- [ ] Propose Cyrus integration separately after selection.

The four extracted packages and ZIPs are under [`dist/0.1.0-final/`](dist/0.1.0-final/). Each `Try.cmd` starts a new Max 2027 process with a disposable profile. Native binaries and packages are ignored by Git; source and compact evidence are retained. No Cyrus source, version, installed plugin or artist scene is changed. No integration is preselected.

## Folder ownership

Each `methods/` folder owns its kernel and generated window. The small common adapter is compiled four times with distinct module/API identities. Shared code supplies input capture, copied mesh/BVH picking, gesture transactions, instrumentation and CPU preview; B/D also share a tile allocation utility with separate coordinate addressing. It does not reuse the Cyrus paint evaluator. Builds, packages, scenes and large raw captures go under ignored `build/`, `dist/`, `scenes/` and `results/raw/`. Small verified result summaries belong in `results/` alongside reproduction commands. No proprietary binary listings are copied into distributable code.
