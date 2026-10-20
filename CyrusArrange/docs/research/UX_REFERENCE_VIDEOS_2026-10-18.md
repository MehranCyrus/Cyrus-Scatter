# UX reference videos — evidence reviewed 18 October 2026

## Coverage and access limits

**The three requested videos were not watched.** No full media, audio, captions,
transcript or timestamped video frames were obtained. Each video's duration is
unverified. Direct extraction with the installed yt-dlp 2025.03.21 and an isolated
2026.8.19 wheel failed with HTTP 429 and then a sign-in/bot challenge. No cookies,
account credentials, browser automation, artist Max session or access-control
workaround was used. Requests stopped at that boundary.

Ordinary public YouTube oEmbed requests succeeded and identify all three titles
and the creator. Their public thumbnails and one official manual screenshot
were inspected; **these are not video frames or evidence of full viewing**.
The official website embeds the exact requested IDs. Raw metadata, HTML,
screenshots, tool/error logs, URLs and hashes are preserved under
`build/ux-video-research-01/`, with a separate evidence manifest.

| Requested video | Verified subject | Duration / actual video coverage |
| --- | --- | --- |
| [mcC36HDNeN0](https://www.youtube.com/watch?v=mcC36HDNeN0) | Scatter Tools for 3ds Max: Smart Object Distribution for Interior Design! | Unknown / 0 seconds; no transcript or timestamped frames |
| [08dhjSh0XMU](https://www.youtube.com/watch?v=08dhjSh0XMU) | Quickly Scatter Decorative Objects with 'Auto-Populate Furniture' | Unknown / 0 seconds; no transcript or timestamped frames |
| [l3nYoA7olM0](https://www.youtube.com/watch?v=l3nYoA7olM0) | Maxscript Bits & Tricks #5 — Randomize Objects, Colors & Materials in 3ds Max | Unknown / 0 seconds; no transcript or timestamped frames |

All three oEmbed responses name **SplineDynamics.com**. The first two are
Scatter Tools references; the third is a scripting lesson, not another furniture
placement tutorial. The creator's public Vimeo upload 794309905 has a reported
duration of 349 seconds and a matching furniture-tutorial topic. Its media was
also unavailable without login. That duration is **not assigned to the requested
YouTube video**, and matching topic/creator does not establish identical cuts.

## What the primary written sources establish

The [Scatter Tools product page](https://www.splinedynamics.com/randomixer-scatter-tools/)
embeds mcC36HDNeN0. Its workflow redistributes selected existing scene objects,
rather than cloning a reusable source library. It supports grouped sources and
distribution objects. This differs materially from Cyrus Arrange's retained
source assets and generated outputs; workflow ideas do not imply equivalent
ownership, algorithms or performance.

The [furniture tutorial page](https://www.splinedynamics.com/tutorials/scatter-tools/auto-populate-furniture/)
embeds 08dhjSh0XMU and describes placing small props on furniture. The page is a
topic description, not a transcript. It provides no verified interaction timing
or evidence that a given number of clicks completes the video workflow.

The [official manual](https://www.splinedynamics.com/randomixer-scatter-tools-manual/)
documents selection plus **Pick Distribution Object**, a scatter-method selector
and **Scatter Objects**. Auto-populate targets horizontal furniture surfaces and
calculates placement orientation/anchor automatically. The vendor documents
object/furniture collision avoidance and leaving unplaceable objects at their
original locations. Its **Restore** returns saved transforms; **Commit** changes
that baseline. Those meanings differ from Cyrus Arrange's staged Preview/Commit.
The inspected static screenshot is labeled v0.9 and groups secondary functions
in rollouts; it is not proof of the current binary's exact UI or a video frame.
No seed control is visible there, which does not establish the hidden random
implementation or repeat behavior.

The [randomization lesson](https://www.splinedynamics.com/blog/maxscript-bits-tricks/randomize-objects-colors-materials-in-3ds-max/)
embeds l3nYoA7olM0 and publishes three small actions: position/Z-rotation
variation, wirecolor changes and material permutation. Reading its position
example shows the same sampled offset used for X and Y. Its material example
draws from a shrinking list. These are source-code observations, not timestamped
video observations. The shown examples do not implement furniture support or
collision validation and should not replace Cyrus Arrange's native fit queries.

## Practical UX recommendations for Cyrus Arrange

These are design proposals grounded in the user's request and the documented
workflows above, **not claims about unseen video interactions**:

1. Lead with **Furniture → Props → Generate**. Show the chosen furniture,
   accessory count and one readable result status. Move support-polygon editing,
   numeric region IDs, detailed category masks and diagnostics into secondary
   sections; retain their native validation and saved ownership.
2. Make **Generate** try a new seed by default, as the user explicitly requests.
   Offer a clearly named fixed/repeat-seed option for reproducibility. Save the
   actual successful seed. A new seed can still produce the same visible layout
   when only one legal solution exists; never promise a distinct pose every time.
3. Keep seed changes atomic with the successor: failure retains the prior
   published result and authored seed. Keep native deterministic generation
   available; new-default UX does not require changing the solver's seeded API.
4. A Preview should stage one proposal. **Commit preview** should commit that
   proposal after validation, without drawing a second surprise seed. Generate
   or Preview may explicitly create a fresh proposal; passive refresh must not.
5. Preserve the distinction between **new source registration**, **rebind**,
   **lock** and **saved appearance**. Do not imitate a selected-object shuffler
   by moving artist source models or randomizing their materials unexpectedly.
6. Keep a direct visible action and brief feedback; avoid requiring several
   separate Apply steps for the normal first arrangement. Advanced editors may
   keep explicit Apply semantics, but their drafts must be clearly marked.

Future full-video review requires accessible media/captions or a creator-provided
download. No interaction timestamps, full duration, complete viewing claim,
benchmark or private vendor algorithm is inferred from metadata or thumbnails.
