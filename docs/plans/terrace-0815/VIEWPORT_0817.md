# Viewport mode switching and zero-limit point preparation

13–14 October 2026. User reports that Mesh often displays boxes and
Point Cloud keeps the preceding Proxy shape after all point/proxy limits are
set to zero. The user authorized investigating both and fixing the transition.

The development candidate is **0.81.7**, a patch to the delivered 0.81.6. It corrects
bounded preparation and transient cache reuse while preserving placement policy,
schema 58, Manual pending edits and the meaning of zero as no artist draw cap.
Resource admission remains independent. Native viewport capability advances to 2
for the matched point-capacity primitive; other product versions are unchanged.
No new installation or release qualification is implied by this investigation.
Relevant engineering contracts are F04 (Manual/relevant Live dependencies),
F05 (atomic publication), F06 (bounded resource admission), F07 (host-thread
publication) and F08 (retained viewport/UI reuse). Local knowledge retrieval was
stale for this working tree; cited evidence and implementation were inspected
directly without refreshing the index.

## Reproduced baseline

The exact delivered script/native pair ran in the owned Max 2027 profile
`build/mcp-qualification/foundation-viewport0816-box-audit-20261013-01`.
The original terrace scene was copied and its hash preserved. `audit.json`
records unchanged placement fingerprints/epoch throughout these observations:

- Fresh 2M idle / 500k navigating Mesh uses 9,591 box instances and some full
  meshes. Sources above their equal triangle share receive boxes.
- Zero/zero Mesh shows all 245,664 placements as boxes. The full-source stream
  needs about 1.65 GiB of conservative buffer/upload reservation before CPU
  snapshots, exceeding the fixed 512 MiB controller allowance. This allowance
  does not measure available VRAM. The current fallback replaces all groups.
- Repeated Proxy/Mesh switches increase tracked Mesh resources from 301 MiB
  through 554 and 806 MiB to allocation failure near the 1 GiB process limit.
  A diagnostic GC in the disposable host releases the retired snapshots;
  changing the draw limit then recovers. This is evidence of delayed cache
  disposal, not a recommendation to force global GC in normal use.

With both point limits zero, 0.81.6 attempts the complete placement-times-points
stream before admission. `points-zero.json` reproduces the same failure after
Box, Sphere and Pyramid: `Point preparation exceeds the 64 MiB allowance`.
Atomic failure retention preserves the previous complete representation, which
explains why choosing Points leaves the prior Proxy shape visible.

## Correction and acceptance

The correction keeps a bounded set of current-publication snapshots per layer so
ordinary mode/shape switches reuse the same CPU resources. It includes these
transient references in rollback and clears them on a new publication or scene
retirement. The six possible slots are Point Cloud, Centres, Mesh and the three
proxy shapes. These are CPU snapshots; only the active representation is bound
for retained drawing. The cache table is replaced atomically, not modified in
place while a rollback state references it.

Point Cloud prepares within a conservative controller resource capacity even
with zero draw caps, splits the sample across enabled layers and accepted rows,
and exposes `Point Cloud sampled to fit the preview memory allowance; draw limits
still apply.` The current ceiling is 587,202 prepared points before layer
rounding. It reserves 100 bytes per point for CPU capacity, retained/upload
copies and simultaneous preparation, with 8 MiB left for overhead within the
64 MiB owner allowance. Zero still means no artist draw cap. It does not remove
resource admission. This is a conservative allocation policy, not detected VRAM.

Required checks: actual dropdown callbacks, all zero point/proxy limits, repeated
Points/Proxy/Mesh transitions without resource growth, Manual pending placement
fingerprints, failure rollback, save/reopen, and matched Max 2026/2027 builds.
Mesh memory fallback remains separate from triangle caps; removing resource
guards is outside this patch. In particular, this patch does not promise full
geometry for zero/zero Mesh on the terrace. Finite limits can also legitimately
use boxes when one source exceeds its group triangle share.

## Source and build identity

Branch `codex/workflow-0.75`, base HEAD
`2b9ad12b24f9d91241db4567037f64db71fe9726`, with pre-existing working changes
preserved. The initial diff/status and directly edited source backups are in
`build/viewport-0817-20261014-01/baseline.json` and `baseline/`.

Frozen generated script SHA-256:
`da589005c8213ad954070a9e8ac837f45fc71f993e103da4304738ac24826bb8`.
Both `native-2026-02/receipt.json` and `native-2027-02/receipt.json` in that run
directory record the complete source/binary manifests and successful build and
28/28 native tests. Each private host checks loaded module paths against its
copied build and records `launch.json` and `loaded.tsv`. The normal installation
and packages remain 0.81.6; the candidate has not been packaged or installed.

The Python suite passes 161 tests. Generation checks pass with 252 controls;
approved UI layout checks pass. Generated script, native capability, catalog and
version assertions are aligned. These checks do not establish presented FPS.
`build/viewport-0817-20261014-01/verification.json` indexes 357 passing host
assertions with receipt hashes, plus the explicit Max 2026 terrace limitation.

## Host qualification

In each of `foundation-viewport0817-max2026-01` and
`foundation-viewport0817-max2027-01` under `build/mcp-qualification/`:

- `small.json`: 16 checks of independent limits, zero semantics, new-publication
  cache retirement, Manual pending edits, emergency fallback and persistence.
- `retained-results.json`: 17 retained-buffer checks.
- `publication-results.json`: 49 publication/failure/recovery checks.

Max 2026 `zero-points.json` additionally passes 10 checks with 1,000 placements
requesting ten million points. Both zero-cap phases draw 587,202 points, all
proxy-to-Point transitions succeed, Centres work, and placements stay identical.
The same ten checks pass in Max 2027 `foundation-viewport0817-max2027-03` after
the completed terrace campaign and scene reset.

Terrace qualification uses a copy of `Test Scene/Terraces_0815/Terraces_0815_Final.max`,
SHA-256 `54b006f2cd40183bcdb048d3ab040eaee066ad67728d5e3b76b381685ab65801`.
The fixture sends the actual native dropdown selection-confirmation event to
controls in its own process, then uses the normal spinner callbacks. MAXScript's
`selected` string property hides the event function ([Autodesk documentation](https://help.autodesk.com/cloudhelp/2017/ENU/MAXScript-Help/files/GUID-FAE5BB27-C3B2-46B4-B0BA-FF7CA80969A8.htm));
the corresponding Windows notification is [CBN_SELENDOK](https://learn.microsoft.com/en-us/windows/win32/controls/cbn-selendok).

`foundation-viewport0817-max2027-03/terrace.json` passes **173 checks / 33 captured
states**. Across four passes through Box, Sphere, Pyramid and finite Mesh,
returning to Points replaces all proxy/mesh draw plans. Both proxy limits zero
retain all 245,664 instances. Point Cloud prepares/draws 281,020 points under
the layer-share resource policy. The 245,664 placements and publication epoch
stay identical while a pending Manual amount edit remains unapplied. All active
GPU items are ready and every layer reports the requested mode without error.

The Mesh resource snapshot after each return to Points is exactly 313,159,888
bytes in all four passes. Active finite Mesh is exactly 365,492,096 bytes on
both the first and last pass. No diagnostic GC is called during switching. Its
1,998,120 idle / 499,346 navigating triangles and 9,591 fallback box instances
match the healthy baseline; memory admission does not force whole-controller
boxes after repeated switching. Save/reopen preserves zero point caps, display
mode and placement fingerprints. `points-zero.png` was inspected and shows the
cloud replacing proxies. The original terrace SHA-256 remains unchanged.

## Failed iterations and limits

The first native build attempts passed compilation/tests but correctly rejected
their receipts because generation/version text changed during the build. Only
the frozen `-02` builds are qualified. The first Python run exposed a stale
catalog version assertion, corrected before the 161-test pass.

The first Max 2027 process exited during terrace loading after the earlier
failure-injection campaign. No causal crash stack was captured. A fresh process
then reported a low-address VCRUNTIME write error at its first whole-scene redraw,
before any Scatter native prepare/upload. Retrying that redraw after explicitly
setting Smooth Highlights and `AdaptiveDegradeNeverDegradeGeometry=true`
succeeded. These viewport settings match the preceding 0.81.6 terrace fixture;
later cold-start runs use them explicitly. This is an observed host/viewport
uncertainty, not a proven cause or a claimed crash fix.

Two further fixture failures concerned invoking `.selected` and sending the
selection-change rather than selection-confirmation notification. Their receipts
are retained in `foundation-viewport0817-max2027-03`; they are not passing UI
witnesses. Product sources were not changed for these fixture corrections.

The first Max 2026 terrace attempt could not load the original Max 2027-format
scene. The retry used a verified disposable back-save made by Max 2027 with
`saveAsVersion:2026`; `compatibility-copy.json` records input/output hashes.
The test asserts load success before inspecting objects. The back-save is
`5d4ddd0d620fb95fd2c659c2e73a0ece79dc9be78274fcb5dc12bb5a25555ff3`.
That file loads, but source assets including `SOURCE | rose lavender` and
`SOURCE | copper lavender` become `Missing_GeomObject` in Max 2026. Consequently
initial publication correctly rejects unavailable source geometry; there is no
retained owner to measure. `foundation-viewport0817-max2026-02/source-conversion.json`
and `inspect-failed-points.json` record the missing classes and sampling failure.
The fixture now asserts initial-publication success before UI testing. **The
terrace is qualified here only in Max 2027.** Max 2026's synthetic policy, large
zero-limit point, retained and publication tests pass; a terrace test there
requires compatible source assets/plugins. No source geometry was replaced to
hide this limitation.

`build/viewport-0817-20261014-01/preservation.json` verifies both native receipts
still match all 104 recorded source inputs, both normal-profile INIs are
unchanged, all 13 installed payload/configuration files per Max year still match
the delivered 0.81.6 installation, and the original terrace hash is preserved.

Physical interaction, presented FPS, device loss, long sessions and other
machines remain acceptance work. Website import/content verification passes with
252 controls, 62 changelog versions and 57 reviewed sources. The initial website
check required the numeric version table cell to keep its established format;
the candidate qualifier is now in the meaning column. Website source/reference
synchronization does not build or publish the site. No commit or push is included
in this task. Owned test hosts were closed; normal installations remain 0.81.6.
