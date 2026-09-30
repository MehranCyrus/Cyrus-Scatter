# Stage 13 — Presentation asset production

## Goal

Produce a small, credible media kit from working scenes that explains what an artist can accomplish.

## Why this matters

A beautiful image attracts attention; a visible, repeatable revision demonstrates the product. You need both, with every shown feature and result tied to the actual build.

## What we currently know

- **VERIFIED IN SOURCE:** Scatter, boundary/edge controls, native CS Edit and Analyzer workflows are present.
- **REQUIRES MANUAL 3DS MAX TEST:** each scene's demonstrated workflow and final render on the declared build.
- **PROPOSED:** the seven scene briefs in [Stage 08](08_Demo_and_Benchmark_Scenes.md) are reusable QA/presentation inputs. They have not been created or qualified by this documentation task.
- **UNKNOWN:** finished branding, media rights, usable hero scene and measured comparative performance.

## My tasks

- [ ] Pick one lead workflow, one lead scene and the audience from Stage 05.
- [ ] Qualify that scene before recording.
- [ ] Create a shot list and capture the actual UI/workflow.
- [ ] Record build/settings/rights for each asset.
- [ ] Prepare captions, poster images and appropriate web exports.
- [ ] Review every proposed message against the claims matrix.

## Engineering / Codex tasks

- Stabilize the qualified demo build and supply reproduction scenes/settings.
- Explain count vs displayed population, edit invalidation and renderer limits accurately.
- Capture measurements through the approved benchmark protocol.
- Investigate recording-time failures before presenting the feature.
- Verify media still represents the released build after relevant changes.

## Boss / Product-owner decisions

Approve the lead message, branding, budget, rights and final public media. A new logo or complete showreel is not necessary to start recording a qualified workflow.

## Step-by-step procedure

1. Start with **one 20–30 second hero, three short workflow clips, six to ten screenshots and one quick-start recording**. Expand only when those are useful and accurate.
2. Use S01 plus one lead scene first; the full seven-scene kit may grow later.
3. Record a clean start state, the operation/settings, a revision and a result. Save the exact scene and settings.
4. Capture full-resolution masters and separate web copies; retain audio/captions and project files.
5. Check visual clarity at the intended website size and on a small screen.
6. Attach each claim to a tested feature/support row; have another person follow the shown workflow.
7. Approve and list the final assets with provenance. Recheck affected assets when the build changes.

### Production list — all items PROPOSED

| Asset | Product message | Scene / feature | Approximate length | UI visible? | Destination / proof |
|---|---|---|---|---|---|
| Hero animation | A controllable landscape revision produces a usable scene | S02 courtyard or S04 road; placement + boundary revision | 20–30 sec | Briefly for the actual revision | Homepage/showreel; tested workflow + actual render |
| Feature clip A | Adjust population and variation predictably | S01/S02; Count, source weights, random scale/rotation | 45–75 sec | Yes; labels legible | Feature page/docs/social excerpt; MT04–09 |
| Feature clip B | Place along a boundary/path with explicit controls | S04; Street Side or Edge Border, spacing/offsets | 45–75 sec | Yes | Feature page/tutorial; MT11–14/29; show which mode |
| Feature clip C | Preserve deliberate local instance changes | S06; CS Edit move/rotate/scale, save/reopen | 45–75 sec | Yes; Instances mode | Feature page/docs; MT19–27 including edited persistence |
| Analyzer feature clip | Turn an eligible planar surface into boundary/path/point data | S05; analysis and export | 45–75 sec | Yes; input/settings/output | Feature page/tutorial; MT28–30; explain supported input shape |
| Viewport recording | Inspect placement with controlled display budgets | S03/S07; Point Cloud, Proxy, Mesh | 15–30 sec | Yes; display mode/counts | Docs/performance section; MT17/34; visible count differs from final population |
| Before/after revision | Explain the user action and resulting arrangement | S02/S04; same camera/assets and one stated change | 10–15 sec | Briefly or separate inset | Homepage/use case; no hidden asset/count change |
| Small looping GIF | One readable action/result | Any qualified lead scene; one control only | 4–8 sec | Only if legible | Social/docs; provide still or non-looping equivalent |
| Overview screenshots | Show starting inputs and finished arrangement | S01/S02/S04; surface/source/placement | Still images | Mix UI and result | Homepage/docs; label viewport vs render |
| UI close-ups | Help a reader find the exact control | S01/S06/S05; relevant rollout/modifier only | Still images | Yes | Docs/FAQ/tutorial; actual current captions |
| Rendered scenes | Show visual output using declared assets/render setup | S02/S03/S04; two useful camera angles | Still images / optional short camera shot | No | Homepage/gallery; renderer/build/asset-rights record |
| Benchmark graphic | Show a measured operation under named conditions | S07; recompute/cache/display/render preparation | Still chart | Optional settings inset | Performance/docs; raw results + protocol; no invented improvement |
| Workflow diagram | Explain surface → rules → edits → preview/render | S01/S06 and Stage 01 | One small diagram | No | Docs/feature explanation; source-consistent, not a performance claim |
| Logo/icons | Provide recognizable product identity | Approved brand assets | Static / simple optional motion | No | Header/download/social; ownership and small-size readability |

The Analyzer clip may replace one of the first three clips if it becomes a lead workflow. Not every planned asset is a first-release requirement.

### Shot card

~~~text
Asset ID / filename:
Audience and one message:
Scene ID / saved starting state:
Feature IDs and manual test evidence:
Build hash / Max update / renderer build:
Exact count, seed, masks and preview budgets:
Shot sequence / action / expected visible result:
Actual result and known limitation:
Capture resolution / frame rate / UI scale:
Rights, credits and redistribution permission:
Claim IDs:
Master file / web export / poster / captions:
Reviewer / approval date:
~~~

### Recording and export guidance

- Capture real Max UI at a readable scale, commonly 1920×1080 or higher; keep a clean master. These are production suggestions, not product requirements.
- Use consistent cameras, units, lighting and seed for revision comparisons.
- Show whether an image is viewport shading or a render. Do not imply proxy preview reproduces material/renderer shading.
- Caption important settings; crop away license identifiers, personal paths and unrelated customer content.
- Export practical MP4/WebM copies as required by the eventual website; prefer video over a large GIF when appropriate.
- Keep videos understandable without sound; provide captions/transcript and a poster frame. Avoid compulsory autoplay/audio.
- Benchmark charts need operation name, sample method, build/hardware, axes/units, population vs displayed count and honest spread. An improvement claim needs a matched prior build/result.
- Use original assets or record specific rights. A library's use in a render does not automatically permit bundling its source objects in downloadable scenes.

### Asset register

| ID / file | Scene / claim IDs | Evidence | Rights/credits | Result | Approval / destination |
|---|---|---|---|---|---|
| HERO-01 / pending | S02 or S04 / pending | | | NOT TESTED | |
| CLIP-01..03 / pending | Qualified lead workflows | | | NOT TESTED | |
| SHOT-01..10 / pending | Relevant scene/control | | | NOT TESTED | |
| TUTORIAL-01 / pending | S01 first scatter | | | NOT TESTED | |
| BENCH-01 / pending | S07 / performance claim | | | NOT TESTED | Optional until measurements exist |

## Evidence to collect

Master videos/images, scene versions, shot cards, captions/posters, raw benchmark data, asset permissions, claims/support references and approvals. A convenient future location is build/commercialization-review/date/media; this task creates no media.

## Status table

| Item | Status | Notes |
|---|---|---|
| Lead scene qualified | NOT TESTED | Stage 08 |
| Starter shot list | PARTIAL | Proposed list supplied |
| Masters/captions/web exports | NOT TESTED | Actual capture required |
| Evidence/rights/claim review | NOT TESTED | Required before public use |
| Approved media kit | NOT TESTED | Owner review |

## Completion criteria

The realistic starter kit exists, every shown workflow has runtime evidence, every asset has rights/provenance, and public messages pass the claims review. Optional benchmark graphics and extra scenes may remain absent.

## Do not do yet

Do not manufacture performance charts, present simulated UI as the working plug-in, hide known output limits or redistribute commercial library assets without confirmed rights.

## Optional / later

Long showreel, multiple aspect ratios, localization, complete seven-scene gallery and a refreshed logo/icon system.

## Next stage

[Stage 14 — Landing page content plan](14_Landing_Page_Content_Plan.md).

