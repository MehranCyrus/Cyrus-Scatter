# Stacked timeline implementation — 2026-10-16

Scope authorized by the artist: implement a timeline with camera keys and presentation layer tracks, inspired by After Effects, retaining viewport composition and original Max animation. This work is confined to `presentation-studio/`; native Scatter and `website/` are separate.

## Version decision

Studio/player **0.2.0** is a substantial private feature delivery with an explicit timing and persistence contract. Timed edits use project schema **3**. Existing schema 1/2 projects remain readable and derive their exact old holds, Bezier travel, reveal, and imported clip timing without rewriting on read. The first timeline edit publishes schema 3. Max camera exporter **0.1.1** and camera JSON format **1** remain unchanged. Old BAILEY v2 archives and their 0.1.2 qualification remain historical evidence; new runs qualify only the current source.

## Contract

- A camera diamond owns a complete pose (position, quaternion, lens, framing), an absolute time, and outgoing interpolation. Expanded camera properties display linked full-pose keys. Independent channel curves are outside this delivery.
- New Capture saves at the playhead, on the timeline frame grid. An editable key at that frame is updated. Compose at playhead opens the evaluated frame for navigation; Save targets its pinned edit owner. Typed seek times accept exact decimal seconds; frame snapping applies to ruler/key dragging.
- Camera timing is canonical in the ordered timeline keys. Existing holds and Bezier controls are retained during conversion; segment duration is derived from adjacent key times minus the source hold. Legacy interpolation preserves the old path; Linear/Ease use straight spatial interpolation with quaternion SLERP; Hold steps at the next key.
- Max clips retain their original immutable bytes, source seconds, poses and lens samples. Their bars and endpoint keys are protected; camera edits cannot split, move or retime them. Layer tracks remain editable over imported motion.
- Each presentation layer has its own step-visibility keys. Before its first key, its initial visibility applies. Inclusion and opening reveal gates still apply; a permitted viewer toggle overrides authored visibility for that session, and reset restores the authored schedule.
- Drag previews are local to the timeline; pointer release commits once, Escape cancels. Multi-key offsets stay relative. Invalid overlap/out-of-bounds edits fail atomically. Copy/paste is project-local; history, autosave, portable archive, compiled preview and public player share the same authored state.
- Seeking, timing edits and visibility playback reuse scene geometry and GPU buffers. They do not reload GLBs or publish a new render scene.

## Verification

Implemented and qualified locally as **0.2.0**. Repository HEAD remained `9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c`; this untracked private app is identified by [qualified source hashes](../../../presentation-studio/exports/timeline-20261016/qualified-source.json), including tests, package metadata and the exact embedded player shell.

| Check | Result |
| --- | --- |
| TypeScript and production player/studio build | Pass; existing large-bundle advisory remains |
| Unit contracts | 43 passed |
| Integration / portable / public contracts | 17 passed |
| Broad browser regression | 54/58 passed initially; four obsolete selectors/card-reordering expectations were updated |
| Final affected browser run | 30/30 passed, including all four updated cases, precise decimal seeking and a new hold-boundary case |
| Distinct passing browser cases across both runs | 59; unchanged cases were not rerun after the decimal-input fix |
| Independent design review | PASS at 1440/1280 desktop and narrow browser widths; only one model provider was available |
| BAILEY sample parity | All 4,321 source sample times matched position, quaternion, FOV and aspect exactly after portable reopen and public compilation |
| Export verification | ZIP limits/CRC, hashes, camera binding, schema, public paths and exact built player shell passed |

The final browser run exercised real key dragging, Escape cancellation, multi-selection offsets, undo, copy/paste/delete, interpolation, ruler seeking, zoom/collapse, viewport navigation/capture/save, layer visibility boundaries, autosave, hold extension/overlap rejection, public override/reset, and existing asset/plan/photo/recovery flows. A manual walkthrough found that HTML frame-step validation could silently reject `8.731` while leaving the displayed input changed. Numeric seeking now accepts arbitrary decimal seconds; tests assert the actual controller time after every numeric seek. The user studio also visibly reached `8.731` through its controls.

The final BAILEY website was loaded from its own nested HTTP path. Forward/reverse/random camera seeks and show/hide boundaries matched the studio evaluator. Static uploads stayed **975 → 975** and scene rebuilds **1 → 1** after warm-up; no browser errors or external requests were observed. These are resource-reuse checks, not a new physical-device or sustained-FPS qualification. The earlier 0.1.2 performance receipt remains historical.

Evidence is in [the run folder](../../../presentation-studio/exports/timeline-20261016/): [test summary](../../../presentation-studio/exports/timeline-20261016/verification-summary.json), [full camera/resource parity](../../../presentation-studio/exports/timeline-20261016/bailey-full-parity.json), [standalone browser workflow](../../../presentation-studio/exports/timeline-20261016/standalone-workflow.json), broad/final browser JSON, export verification, source backup, and screenshots. Reproduce with `npm run test:unit`, `npm run test:integration`, `npm run build` and `npm run test:browser`; the heavy BAILEY case requires its owned local v2 editable archive. The retained parity utility in the run folder also verifies the exact built player shell against the export.

## Review files and preservation

- The user studio at `http://127.0.0.1:5190/` is open on the original **BAILEY · Architecture in motion**. Only selection/playhead were changed for that walkthrough.
- [BAILEY timeline editable QA project](../../../presentation-studio/exports/timeline-20261016/BAILEY-timeline.cyrus-presentation.zip): schema 3, camera unchanged; pavement hides at 12 seconds and reappears at 16 as a visibility test.
- [BAILEY timeline QA website](../../../presentation-studio/exports/timeline-20261016/BAILEY-timeline-website.zip): player 0.2.0; SHA-256 `4e596b0ca9d0919e2349cee628ca5b72fe1c5b35ed5a418fea4eb44a2dde88b7`.
- [Current user studio](../../../presentation-studio/exports/timeline-20261016/studio-final-bailey.png), [desktop review](../../../presentation-studio/exports/timeline-20261016/review-desktop.png), [standalone player](../../../presentation-studio/exports/timeline-20261016/BAILEY-timeline-standalone.png), and [narrow browser review](../../../presentation-studio/exports/timeline-20261016/review-narrow.png).

Original BAILEY v2 editable SHA-256 remains `1b42296d4ef745ca6e312c722235761d891fa6ddc45c0cb29014e55a659b9ec5`; original website ZIP remains `7162847fae6b424a9feb99b20c75526cfddd9e92ac85cc176519b6ac66484a70`. The new editable QA archive retains every original resource byte and sampled camera hash. No native Scatter source, Max scene/session, installer or existing website was changed by this task. Nothing was committed, published or deployed.

Independent property curves, animated opacity, clip trimming/retiming, explicit baked editable copies and camera cuts remain outside this first timeline delivery. Imported Max motion is protected: extend duration and add ordinary keys outside its bar, or explicitly remove the imported animation to author a different path. Studio editing remains desktop oriented; narrow browser review does not qualify physical mobile devices.
