# Browser playback review: the three supplied videos

Reviewed 18 October 2026, Asia/Tehran. This is a post-release research addendum to Cyrus Arrange 0.2.0.

The videos **do play in the in-app browser**. The user's request to try computer use supplied authorization for this later browser session. The [earlier research note](UX_REFERENCE_VIDEOS_2026-10-18.md) accurately records the failed extraction attempt, but its access limitation does not apply to this browser route. That historical note and the qualified release archives remain unchanged.

## What was actually reviewed

Each video was reviewed visually across its timeline using normal playback, periodic screenshots and pauses/replays for inspection. This is sampled visual observation, not a recording or inspection of every frame. All three players reported captions unavailable; audio was muted and was **not analyzed**. No transcript or downloaded video was used. Observed wording and code below come from visible frames, not inferred narration.

| Reference | Player duration | Visual coverage and endpoint handling |
| --- | ---: | --- |
| [Scatter Tools trailer](https://www.youtube.com/watch?v=mcC36HDNeN0) | 1:16 | Played from the opening through the final furniture example and automatic next-video transition. Key sections were paused; the last section was replayed. A later End-key check confirms 1:16/1:16, independently of the playback observations. |
| [Auto-Populate Furniture tutorial](https://www.youtube.com/watch?v=08dhjSh0XMU) | 5:49 | Played from 0:00 through the closing card at 5:48, with observations throughout. The remaining one-second end position was checked using End. |
| [MAXScript randomization lesson](https://www.youtube.com/watch?v=l3nYoA7olM0) | 2:43 | Played from 0:00 through the finished player at 2:43, with observations throughout. |

The durations total **9:48**. Retained evidence contains 56 observations and 29 selected screenshot files; these counts include replays and one excluded automatic transition. [The annotated ledger](../../build/ux-video-playback-01/observations.json) preserves actual URLs, times and raw accessibility output; [the original ledger](../../build/ux-video-playback-01/observations.raw.json) is retained separately. Capture labels were assigned before observation and are not timestamp authority. One label says `v1-end` after autoplay had already opened another video; it is explicitly excluded. Frames immediately after seeking can be stale until the image settles, so the settled replay is used instead. Screenshots are the browser's original JPEG bytes with corrected `.jpg` extensions.

## Trailer: distinguish the tools

- Around 0:04–0:16, cars exchange existing positions and orientation, including complete groups.
- At 0:24–0:33, toys demonstrate position swapping and target-rotation inheritance.
- At 0:42, a separate transform rollout exposes translation, Z rotation, scale and an anchor choice.
- At 0:51, props occupy spline/vertex locations; at 1:01, props occupy designated pivots.
- At 1:08–1:09, Auto-Populate Furniture distributes mixed decorations among open shelves.

The practical lesson is to give each operation a clear purpose. Furniture styling should remain Cyrus Arrange's main activity; a generic object shuffle or transform tool has different input and fit expectations.

## Furniture tutorial: the artist interaction

| Observed time | Visible action/result | Lesson for Cyrus |
| --- | --- | --- |
| 0:35–0:58 | Select three plants, choose furniture mode, pick a table, scatter. Two plants are on the table while another remains at its original location. | Keep first use short and report what fitted. |
| 1:11 | Explicit scale limits of 50–60% accompany three plants fitting the small table. | Scale reduction is an authored choice; preserve real dimensions by default. |
| 1:25–2:04 | Restore/reuse the selection and choose a table with several raised support surfaces. | A furniture target can contain several usable support levels. |
| 2:16–2:40 | A two-level circular trolley receives plants above and below; scale limits show 50–75%. | Validate each support and its overhead clearance. |
| 2:52–3:50 | Nineteen selected mixed props, including preassembled book/decor groups, are repeatedly distributed across the desk and side shelves. Some remain on the floor. | Bulk intake and grouped assets reduce artist preparation; fit can underfill. |
| 4:16–4:43 | Repeated scatter redistributes accessories into the open shelf compartments and onto its top. | Repeated clicks should explore variations with the same chosen target and props. |
| 4:55–5:43 | A subset is used on another table, then a separate transform rollout changes yaw and scale. At 5:26 the visible limits include Z rotation −180° to 180°, scale 50–100%, and a base anchor. | Keep variation controllable; validate the final transformed pose. |

These are viewport observations, not measurements of vendor collision correctness or speed. The tutorial does not demonstrate category-based semantic recognition or a retained reusable asset library. Its source implementation was examined separately in the [local source research](SPLINE_DYNAMICS_LOCAL_RESEARCH_2026-10-18.md).

![Reference open-shelf demonstration at approximately 4:16, SplineDynamics.com](../../build/ux-video-playback-01/v2-pass-20.jpg)

## MAXScript lesson: three separate kinds of variation

At 0:44, the visible snippet varies horizontal position by ±3 scene units and yaw by ±20°. It processes selected nodes without a parent, which avoids applying that loop separately to both a root group and its children. The same sampled horizontal offset is used for both X and Y; those axes are correlated in this example. Around 1:01–1:14, the same operation is applied to chairs.

At 1:29–1:43, independent RGB values change the objects' wire colors. This concerns viewport identification/display, not an assignment of new rendered materials.

At 1:56–2:27, materials are collected from the selected objects, randomly assigned, and removed from the remaining draw list. This permutes the existing material entries without replacement; repeated references can still occur when the original selection shares materials. The video does not show furniture-fit validation or a complete seed/persistence contract for these snippets.

For Cyrus, small variation should respect units, root/group ownership, contact, clearance and collision. Material variation should be an explicit optional operation with compatible materials; it should preserve the default source appearance and avoid unexpectedly changing shared source materials.

## Current implementation versus proposed follow-up

The [qualified 0.2.0 workflow](../SIMPLE_WORKFLOW.md) already provides one main Generate action, a fresh seed by default, Keep seed, automatic existing-arrangement discovery, retained source geometry/appearance, grouped assets and detailed controls under Advanced. Its C++ placement checks the pose with the selected yaw/scale before publication. The videos add direct visual evidence for the interaction, rather than changing what was runtime-tested for that release.

The clearest next improvement is **bulk prop intake**: select several original models/groups, add them together, and review the resulting entries in one compact list. The current quick UI adds one model/group at a time. A second useful improvement is an explicit **Subtle variation** choice for bounded yaw/offsets, integrated with the native fit checks. Neither proposed feature is claimed to be implemented here. Preserve duplicate-source checks, group identity, explicit category/book metadata, repeatable seeds and one-step Undo when implementing them.

Only research evidence and this new note were added in this session. No Max scene, runtime source, native binary, installed artist plugin or qualified archive was changed. The previous qualification's no-computer-use statement concerns its own testing; this later user-authorized browser review used computer use.
