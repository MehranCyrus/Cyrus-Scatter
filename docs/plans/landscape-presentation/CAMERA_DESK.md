# Camera desk enhancement — 16 October 2026

The artist authorized adjustable timeline height, investigation of sluggish Orbit navigation, output composition aspects/safe guides, and playing the animation while observing its camera from Orbit. This private delivery is **studio/player 0.3.0** because it adds substantial artist-facing controls. Project schema stays **3**; Max camera exporter stays independently versioned **0.1.1**. Native Scatter and the existing website are separate.

## Artist workflow

- Drag the grip above Timeline to show more layers. Up/Down changes height by 20 pixels, Shift by 50; Home/End selects the bounds. Double-click restores 258 pixels. Collapse/expand retains the chosen height, and the preference survives reload. Desktop height is bounded to retain at least a 220-pixel canvas where the window allows it.
- **Frame** chooses free viewport, FHD 16:9, Vertical 9:16, Square 1:1, Classic 4:3 or Cinema 2.39:1. Toggle 90% action-safe and 80% title-safe guides in the same menu. The output border and renderer share one fitted rectangle. Presets describe aspect, not guaranteed pixel resolution.
- Capture stores the composition aspect in the existing full camera-pose key. Workspace format/guide/height changes alone do not change the project or history. Saved Playback follows its authored frame; an imported Max animation retains its recorded aspect and source bytes.
- Stay in **Orbit** or **Plan** while playing, reversing, restarting or scrubbing. The observer view stays under your control; the scene shows a moving camera body/frustum, its path and key-position markers. Ordinary pose keys remain editable; Max endpoints and their continuous source clip remain protected. Choose **Playback** explicitly to look through the saved camera. Pause before Capture or Save.
- Portrait letterboxing also applies to camera-handle picking and transform controls. Guides do not intercept viewport input. Plan and compiled preview hide the editor guide overlay.

## Implementation and performance

Orbit-only renders no longer run a full UI update on every frame; statistics refresh at most four times per second. The timeline skips unchanged time/project/transport writes, retains its rows and avoids rebuilding them for height-only changes. Safe-frame geometry changes only with its frame/mode/actual size. Camera helper transforms update without rebuilding their geometries. Tiny editor guides initialize on opening Orbit, including guides outside the current view, so rotating them into view does not create new buffers. Landscape frustum culling and model/material detail remain intact.

Layer fades still update their shader uniforms. The renderer traverses scene visibility/shadow flags only when those flags change; project publication, membership and context restoration invalidate that cache. Playback transport and the observer camera are independent. Original sampled movement, FOV, timestamps and clip duration are unchanged.

The final controlled comparison used frozen 0.2.0 and built 0.3.0, the same original BAILEY archive, 1440×900 at DPR 1, Chromium 145 and the local RTX 3090. It sent 90 identical Orbit input steps. Resolution was fixed at scale 1 in the owned profiler only, and initial buffers/program work completed before measuring. Production adaptive quality was unchanged.

| Metric | 0.2.0 | 0.3.0 |
| --- | ---: | ---: |
| Timeline DOM mutation records | 637 | 0 |
| UI updates during input sequence | 91 | 14 |
| UI update CPU p95 | 0.5 ms | 0.2 ms |
| Draw including UI median CPU | 9.4 ms | 9.8 ms |
| Draw including UI p95 CPU | 13.5 ms | 13.9 ms |
| New build scene rebuilds / geometry uploads after warm-up | — | 2→2 / 1191→1191 |

The avoidable timeline work and first-rotation helper uploads are removed. **This bounded run does not establish a net BAILEY render-speed improvement**: total draw CPU cost remains similar, dominated by rendering the building. These are submission/input diagnostics, not presented FPS, sustained thermal results or mainstream-device certification. Earlier exploratory profiles are retained with their original names; one software-rendering run was stopped when it contended with browser tests and is not qualification. [Final baseline](../../../presentation-studio/exports/camera-desk-20261016/orbit-final-before.json), [final result](../../../presentation-studio/exports/camera-desk-20261016/orbit-final-after.json) and [reproduction script](../../../presentation-studio/exports/camera-desk-20261016/profile-orbit.mjs) retain the measured conditions.

## Verification and review

- TypeScript and production studio/player build pass. Existing large-bundle advisories remain.
- **62 unit/integration checks pass.** The broad browser run passes **65/65**. After the final portrait-pointer/helper initialization refinements, the affected camera-desk and recovery run passes **14/14**, including one new picking case: **66 distinct browser cases** across these runs. Unchanged broad cases were not rerun after those bounded navigation changes.
- Resizing, persistence, keyboard controls, collapse/reset, narrow layout, guide ratios, capture/reopen/export aspect, Orbit/Plan transport, reverse/reset, camera/path markers, live observer navigation, imported timing, resource retention, idle, portrait picking, stale/failed publication and context recovery are covered. The broad run also exercises existing asset, layer, plan, photo, Max import and public-player controls.
- Independent frontend design evaluation: **PASS** for desktop 1440/1280 and narrow 840 layouts. Only one model provider was available, so evaluation used an independent same-provider agent.
- All **4,321 original BAILEY Max samples** match position, quaternion, FOV and aspect exactly through portable/public round trips. Original resources are byte-identical. Public output passes bounded ZIP/CRC, schema/version, resource hashes, camera binding and exact built-shell checks. Nested HTTP playback, random/reverse seeks and layer boundaries pass; warmed public uploads stay 975→975 and scene rebuilds 1→1, with no errors/external requests.

[Verification summary](../../../presentation-studio/exports/camera-desk-20261016/verification-summary.json), [source hashes](../../../presentation-studio/exports/camera-desk-20261016/qualified-source.json), [full sample parity](../../../presentation-studio/exports/camera-desk-20261016/bailey-full-parity.json), [standalone workflow](../../../presentation-studio/exports/camera-desk-20261016/standalone-workflow.json) and browser JSON are in [the run folder](../../../presentation-studio/exports/camera-desk-20261016/).

The user's existing studio tab is left on original **BAILEY · Architecture in motion**, paused in Orbit, with Focus enabled, FHD safe guides and a 298-pixel timeline. Wheel zoom and actual Orbit playback were reviewed there. [Studio proof](../../../presentation-studio/exports/camera-desk-20261016/studio-final-bailey.png) shows the camera/frustum animating while Orbit stays active; [final visible state](../../../presentation-studio/exports/camera-desk-20261016/user-studio-state.json) records the paused handoff. Workspace actions did not edit the original project.

[Editable QA copy](../../../presentation-studio/exports/camera-desk-20261016/BAILEY-timeline.cyrus-presentation.zip) and [public QA ZIP](../../../presentation-studio/exports/camera-desk-20261016/BAILEY-timeline-website.zip) deliberately hide pavement at 12s and show it at 16s to test layer timing; they preserve the camera and are separate from the user's original BAILEY delivery. Original v2 editable/public archives, GLB and camera hashes match their preserved receipts. An early provisional test wrote to old timeline-proof paths: the 0.2 editable archive was reconstructed and verified against its exact recorded SHA-256; its public ZIP was unchanged. The overwritten screenshot is retained as a provisional 0.3 diagnostic, and the old timeline record now links an untouched 0.2 review screenshot. All final outputs use this fresh run folder.

Repository HEAD remains `9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c` on `codex/workflow-0.75`; this private app remains untracked and is identified by its source hashes. This task did not change native code, open/restart Max, modify the existing website, commit, publish or deploy. Concurrent unrelated work was preserved. Further scene draw-call reduction or a different display-quality policy would require a separately measured renderer/asset change; no model detail was silently reduced here.
