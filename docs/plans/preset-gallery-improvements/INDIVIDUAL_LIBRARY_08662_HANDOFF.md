# Individual plant library: thumbnail stall and textured viewport handoff

Updated 20 October 2026, Asia/Tehran. Product: Cyrus Scatter **0.86.6.2**, Max
**2027**. This report records delivered work, subsequent artist feedback, source
findings and the next requested corrections. It is a review/implementation
handoff, not evidence that either open item is fixed.

## 1. Outcome and current status

| Item | Current status | Evidence limit |
| --- | --- | --- |
| Individual plant library and installation | Delivered; artist confirms installation and model/material/texture loading work | One distinct model was exercised by the prior owned-host campaign; artist additionally demonstrated a leaf scatter and Corona render |
| B33: thumbnails remain at Loading until clicked | **Open defect** | Artist reproduction and source inspection; exact scheduling/redraw cause has not been isolated |
| B34: textured Mesh viewport with leaf opacity | **Requested feature, absent from current implementation** | Native source confirms identification-only shading; no texture implementation or prototype was made |
| Earlier MZP Content-folder error | Artist resolved by selecting the parent Content folder | Folder-selection UX remains strict; accepting Content/Library automatically was discussed but never implemented |

The last two investigations made **no plugin-code changes**, built no successor
and launched no Max session. This handoff updates documentation only. Existing
0.86.6.2 package hashes and historical qualification retain their original scope.
The artist's successful render confirms the displayed material path works; it
does not qualify all 96 models or textured viewport behavior.

## 2. What was completed before these findings

The user replaced the original procedural demonstrations and the eight mixed
planting pilots with individual assets from the first plant catalog. They want
to create their own mixed planting designs. No replacement mixed presets were
requested.

The original **104 cards represent 96 unique individual entries**. Eight cards
are collections, composites or alternate-renderer duplicates of models already
listed separately. All 104 remain accounted for through eight source-alias rows;
models were not discarded merely to reduce the count.

| Category | Individuals |
| --- | ---: |
| Trees | 24 |
| Shrubs | 7 |
| Flowers | 6 |
| Groundcover | 5 |
| Grasses | 3 |
| Leaves | 49 |
| Ground Details | 2 |
| Total | 96 |

Preparation produced one static independent Editable Mesh per entry, retaining
natural size, materials and mappings. Trunk/foliage components were kept as one
plant. Three former Corona proxies were converted with their full geometry:
736,931, 563,380 and 832,240 triangles. Seven initial preparation failures were
repaired: corrected ACEScg textures shared basenames across sources, and grouped
tree cleanup needed to detach geometry before deleting parent helpers. The other
89 successful assets were retained. Existing corrected tree source frames were
reused. Originals were preserved and existing Corona renders were reused.

The new default browser is **Plant models > All models**, with seven flat
categories. An explicit model content type loads prepared native MAX files;
individuals are not disguised as scatter recipes. **Merge model** creates a
visible scene model. **Add to selected layer** registers one hidden source with
the existing planting settings, without inventing a layer or scatter design.
Personal recipes remain separate. Max's automatic naming initially changed
Broadleaf Tree 02 to Broadleaf Tree 001; the delivered script now preserves the
exact name and only appends a suffix for actual duplicates.

Old active library files were moved reversibly to
`build/individual-model-library-20261020/retired-library-0866/` after automatic
approval review rejected a bulk deletion command without a detailed reason.
They are excluded from the new active browser and installer. Historical releases
remain preserved. Some historical fixture tools still need an explicit archive
path if used again.

The installer distribution is an EXE/MZP plus a companion **Content** folder.
Its 1,204 content files total **5,850,789,633 bytes**: 96 MAX scenes, 96 JPEGs,
1,011 shared map/resource files and one catalog. The largest MAX is approximately
1.398 GB. The installer pins the manifest and streams size/hash-verified files
into a versioned release before registration, with finite bounds of 2 GiB/file,
16 GiB total and 4,096 listed files. It does not embed the multi-gigabyte library
inside the EXE or read entire model files into managed byte arrays.

## 3. Exact baseline and where to inspect it

Repository: `F:/Cursor/_Cyrus_Apps/CyrusScatter`. Branch:
`codex/workflow-0.75`. Last committed/pushed backup:
`3ec1cbc2b725912e39c2625ceecb648970054050`. **The new individual-library source and
these documentation updates are still working-tree changes.** A checkout of
that commit or GitHub alone is insufficient to inspect the current successor.
Preserve pre-existing changes and unrelated work.

Canonical local distribution:
`dist/CyrusScatter-0.86.6.2-20261020/`.

| Artifact | SHA-256 |
| --- | --- |
| CyrusScatter-0.86.6.2-Setup.exe | `8f2fb27697dfaa90851fa7229f3d836b8506cfb52db5e8211e10fc7aecbe8cdc` |
| CyrusScatter-0.86.6.2-Max2027.mzp | `f3e6768dfd9318ff2c272ad209587f20e81cf089441f4760fe5ea685d35a2e14` |
| Content/content-manifest.json | `d8d8f69e4f0ade1d22487c4aa4db0f97686979d23dc6febeeddb6eb53c811eb0` |
| CyrusScatter.ms | `3a5db6ace320e9a6dfd6ca24ef04845c1717c390e512b75119e3bc8238a88de6` |
| CyrusGallery.dll | `878f2690f998ccfbcefd1a0e237d956b7c9da41cc4b2055d03e176d33d7e5f75` |
| model-catalog.json | `e3146c4a1511927f3ee542ffbee776af44377a93c0e9b066385375766f543540` |

Read-only inspection after the artist's installation found the script, gallery
and catalog at
`C:/Users/Mehran/AppData/Local/CyrusScatter/2027/r/801cdef80783/`, with hashes
matching the table. This confirms installed file identity, **not** the identity
of every module currently loaded into the running artist process. No attachment
to or mutation of that process was performed.

The native calculation/display binaries were retained unchanged from the prior
matched implementation. `RUNTIME-IDENTITY.json` in the distribution records all
four native hashes. Schema remains 58; recipe format remains 7. The earlier
qualified 0.86.6 baseline and its evidence remain separately identified.

The knowledge service was queried for this handoff. Its selected index records
older HEAD `ce062502ecda3af57b25e8821c9e5a7744d3501d`, sources were not fully
verified, and the exact gallery path search returned no results. Current findings
therefore come from direct working-tree source inspection. No index refresh was
performed or claimed.

## 4. B33: automatic thumbnail loading stalls

### Artist reproduction and established facts

1. Install 0.86.6.2 with its complete Content folder and open Cyrus Library.
2. Use Plant models > All models. The artist's screenshot uses Large tiles in a
   wide window, scrolled beyond the first entries.
3. Some previews display while many visible tiles remain at **Loading**.
4. The status bar already says `Ready: 96 individual models; 96 matching.`
5. Clicking a Loading tile causes its image to appear. The user reports this as
   repeatable behavior after an initial set has loaded.

The 96 compressed JPEGs total **3,365,158 bytes** (about 3.4 MB); average size is
35,054 bytes and largest 82,594 bytes. Browsing does **not** open their MAX scenes,
merge geometry or render the previews. A heavy model import is not the operation
being observed here. Clicking makes the asset's preview usable, so blanket
missing-image explanations do not fit the reported symptom.

It remains unknown whether each affected image was decoded before the click or
the click starts its decode. No wall-clock delay, worker/queue trace or live
counter capture was obtained from the artist session. **Do not state that an
exact queue bug, timer bug, disk issue or cache limit has been proven.**

### Current source path

Primary source: [LibraryGallery.cs](../../../AminScatter/ui/LibraryGallery.cs).
Line numbers below describe the inspected working tree and may move.

| Symbol / approximate line | Current behavior |
| --- | --- |
| `IndividualModelCatalog.Load`, 80 | Synchronously parses the catalog, validates paths and scene file sizes, and hashes all 96 preview files. It does not hash scene contents here |
| `ContentPath` / `NoLinks`, 53 / 47 | Checks each relative path and ancestor chain; repeated filesystem metadata work can affect opening time |
| `VerifyScene`, 130 | Hashes the selected MAX only during explicit model loading |
| `BeginPage`, 392 | Increments a generation; old pending jobs retain their slots until drained |
| `BoundsFor` / `VisibleItem`, 415 / 420 | Computes tile bounds using columns, DPI/user scale and AutoScrollPosition; automatic requests depend on visibility |
| `Schedule`, 480 | Requests the selected tile first, then visible tiles; permits two outstanding jobs |
| `Request`, 488 | Adds a pending key/job slot and runs Decode through Task.Run |
| `Decode`, 505 | Reads and hashes the JPEG, checks dimensions, decodes and resizes to a maximum 256 pixels |
| `Drain`, 558 | A 40 ms WinForms timer drains completed results, frees slots, caches images, invalidates and schedules more |
| `SelectedIndex`, 370 | Clicking a new selection calls Invalidate and Schedule; selected requests bypass the visibility filter |
| `OnPaint`, 455 | Draws a cached image or Loading/Unavailable placeholder; it does not itself guarantee a new request |

Decoded cache limit is 64 MiB. All 96 previews at the maximum 256×256×4 bytes
would occupy about 24 MiB before overhead. A simple fixed cache-cap explanation
is therefore not established by the source or observed count. The two-job limit
is a throttle, not an intended limit on how many images can eventually display.

[recipes.ms](../../../AminScatter/tools/ui/templates/recipes.ms) `showPage`
(approximately 984) sends all 96 descriptors through BeginPage/AddItem/EndPage;
pages hold up to 128 entries. `refresh` (approximately 1034) reloads the managed
catalog. The individual-model branch disables the old recipe scan timer.
Its Ready status reports catalog count, **not completion of image decoding**.
Closing/disposal drops the gallery's in-memory image cache, so reopening can
repeat reads and decodes.

### Diagnosis to complete, then fix

The click behavior supports an automatic scheduling/presentation problem. Review
these hypotheses rather than choosing one without a witness:

- Visible-item bounds or scroll/resize/DPI notifications omit tiles the artist
  can actually see; selected requests still reach them.
- Max's hosted message loop stops or delays completion draining/timer ticks;
  another interaction wakes presentation.
- Generation changes, pending keys or job-slot accounting leave work stranded
  after a page/category/search/resize transition.
- Initial synchronous catalog/filesystem work causes a separate opening delay;
  this does not by itself explain every click-dependent tile.

Use the existing JobsStarted, ImagesDecoded, PendingJobs, DecodedBytes and
ItemCount counters. Add temporary bounded diagnostic snapshots only if needed:
visible IDs/bounds, scroll offset/client size, current generation, pending and
completed counts, timer state and elapsed times before/after a click. Keep Max
hosted behavior in the reproduction; a standalone WinForms success alone does
not resolve an artist-host message-loop issue.

Fix the observed causal boundary. Retain generation cancellation, closed-control
cleanup and bounded memory. Prefer a reliable bounded visible/near-visible queue
and completion notification over requiring selection, repeated whole-page scans,
permanent forced repaint loops or opening MAX files to obtain thumbnails. Cache
validated immutable descriptors/decoded previews where justified. Show truthful
image-loading progress separately from catalog readiness. Do not simply increase
worker count or remove integrity checks and call the defect resolved.

Acceptance: visible previews finish automatically without clicks; scrolling and
resizing continue the queue; category/search changes cannot publish stale images;
closing during work is safe; warm revisits reuse admitted cache. Browsing must
create no scene objects and perform no scatter solve, render or model merge.
Use a focused actual Max 2027 window/scroll witness, not 96 model imports.

## 5. B34: original material textures and cutout opacity in Mesh preview

### Artist observation and current limitation

The artist imported a Sycamore leaf, scattered it and showed a successful Corona
15 render with yellow leaves and transparent cutout silhouettes. In the viewport
the same cards appear as green rectangles. The screenshot shows:

- Display mode: Mesh; Color by: Model; Show preview enabled.
- Navigating budget: 500,000 triangles; idle budget: 2,000,000.
- Max viewport display: Standard / Wireframe.

These rectangles are consistent with real rectangular leaf-card geometry being
drawn without its opacity texture. They should be distinguished from the genuine
bounding-box fallback used when mesh budgets/resources cannot admit full geometry.
Increasing a triangle budget does not implement alpha cutouts. Changing Max to
Shaded helps ordinary scene objects but cannot supply a texture path missing
from Scatter's custom display shader. The successful render is evidence that
the demonstrated model's material maps are present; reconverting the plant is
not the identified viewport requirement.

### Source-confirmed display path

| Source | Finding |
| --- | --- |
| [unified-core.ms](../../../AminScatter/tools/ui/templates/unified-core.ms), approximately 4355–4359 | Display modes are Point Cloud, Proxy, Mesh and Plant centres. Color by contains only Model, Layer and Bands |
| Same template, `flow_previewUI.bind`, approximately 4415 | The view binds the root controller; new display-setting ownership should follow the actual existing root/layer contract |
| [point_preview.h](../../../AminScatter/include/point_preview.h), `PreviewGeometry`, approximately 61 | Retains triangle positions, instance matrices, color and Band ownership; it has no source UV/material/opacity payload |
| [geometry_preview.inc](../../../AminScatter/src/geometry_preview.inc), `cyrusBuildGeometryPreview` | Copies source triangle positions and instance transforms, or builds proxy/fallback geometry; it does not copy material UVs/textures |
| [mesh_display.inc](../../../AminScatter/src/mesh_display.inc), `meshShader`, approximately 5–39 | Custom HLSL computes shaded identification color and outputs it with alpha 1. No image sampler, material UV lookup or alpha cutout exists |
| [source_geometry.inc](../../../AminScatter/src/source_geometry.inc), approximately 1–3 | Geometry fingerprint deliberately excludes palette/material changes; avoid making every material edit invalidate the placement/geometry pipeline |

`TEXCOORD` stream semantics in mesh_display.inc currently carry triangle-edge
vectors and instance-transform data. Their name does not mean source UV mapping
is already available. Color by Model means identification color assigned to the
source, not the model's albedo/material.

This is a missing native viewport capability, not an existing hidden checkbox.
No implementation, SDK feasibility prototype or performance measurement for
textured display has been performed in this conversation.

### Requested behavior and recommended implementation boundary

Provide an explicit one-click **Materials / Textures** viewport choice while
retaining Model/Layer/Bands identification and existing Point/Proxy/Mesh controls.
Choose the clearest UI placement after examining ownership; do not silently
renumber existing stored enums. The user primarily needs original base colors
and leaf transparency in normal shaded/textured navigation, not Corona-quality
lighting or a new material editor.

The native feature needs source UVs, correct face/material/submaterial binding,
base-color textures/colors and opacity/alpha. Cover the supplied Corona and
Multi/Sub material branches that actually contribute those properties. Preserve
UV seams, mapping channels, orientation and two-sided leaf visibility. Treat
image gamma/color-space and alpha independently so the corrected ACEScg maps
and other source maps do not become washed out or incorrectly transparent.
Define unsupported shader/map fallback visibly; do not claim arbitrary Corona
graph or full renderer fidelity from a base-color preview.

Use retained native instances. Inspect Max materials and copy host data on the
host thread, then use immutable prepared data through the supported Nitrous/SDK
resource lifecycle. Do not evaluate Max scene objects or renderer materials from
Draw or a generic worker. Decide alpha clipping/transparency, depth and two-sided
handling explicitly for leaves. Check appropriate Max 2027 SDK primary examples
before committing an implementation approach.

Declare ownership, texture/material/UV invalidation keys, CPU/GPU memory and
peak staging costs, eviction, device loss, failure recovery and Undo/persistence.
Keep placement data and retained geometry separate from material/texture state:
switching viewport appearance, navigating, or browsing the library must not
regenerate static placements or apply pending Manual settings. Relevant material
edits should refresh the material preview; unchanged buffers should remain
reusable. Retain the previous complete display on failed staging, with a clear
fallback/status. Keep existing triangle budgets, memory admission and shared
controller limits; zero does not waive resource admission.

There is also an existing 2,000,000-face source-inspection allowance in
`source_geometry.inc` / `geometry_preview.inc`. Some botanical assets exceed it.
Textured display does not automatically qualify those heavy sources or remove
that independent limit. Do not silently widen unrelated admission limits merely
to implement leaf textures; identify any required separate scope explicitly.

Relevant contracts: F04 Manual/Live and dependencies, F05 atomic publication,
F06 bounded work/resources, F07 host-thread/lifetime, F08 display reuse,
F10 units and F11 saved-state boundaries in the
[engineering foundation](../../ENGINEERING_FOUNDATION.md).

Focused acceptance: one representative alpha leaf visibly displays its original
color and cutout without rectangular fill; identification modes still work;
switching/repeated navigation retains placement identities and avoids unchanged
solve/upload work; supported material/UV edits refresh only relevant display
data; failure/cancellation retains prior presentation. Verify the supplied
Multi/Sub mapping with an appropriately small source if that path changes.
Keep actual model testing proportionate; do not repeat the 104-scene audit or
render campaign. Capture a viewport screenshot alongside the working Corona
reference. Existing renderer output/materials must remain unchanged.

## 6. Installer incident: resolved selection, unchanged UX

The first MZP error looked for
`.../Content/Library/content-manifest.json`. The manifest is actually at
`.../Content/content-manifest.json`. The selected directory was one level too
deep. The user selected **Content** and subsequently supplied the successful
installation screenshot. Read-only installed-file hashes match the delivery.

[install.ms](../../../AminScatter/installer/install.ms) uses a folder picker
because Max extracts the MZP into a temporary directory. `SetContentDirectory`
in [InstallEngine.cs](../../../AminScatter/setup/InstallEngine.cs) accepts the
provided root literally. The EXE resolves Content beside itself. The earlier
assistant statement that it would accept either directory was interrupted;
**no such fix was made**. An optional later usability correction can normalize
Content/Library to its verified parent or explicitly select the manifest, while
retaining version/hash/path checks. This is not a missing-model or failed-render
finding and need not delay diagnosis of B33/B34.

## 7. Verification already performed and what it did not establish

Previous delivery checks covered source file/category/preview mappings, all
declared content identities, archive hashes, managed compilation and a small
isolated installer transaction including corrupt-content rejection. The owned
Max 2027 check used **one distinct model, A073 Broadleaf Tree 02**: 554,588
triangles; 490.636×493.997×607.883 cm; one registered source with persisted
defaults. The same model was repeated after the naming correction. Earlier
driver errors and the later successful receipt remain separate.

The final owned gallery witness displayed 96 descriptors and decoded **12
visible thumbnails**. It did not exercise a large scrolled window, wait for all
96 images, or establish automatic thumbnail progress after scrolling. Do not
reuse it as proof B33 is fixed. It also never tested textured Mesh display.

The artist now confirms model/textures work and provides a successful leaf
render; exact timing and source fingerprints for that scene were not recorded.
No exact thumbnail stall was reproduced by an owned host during these read-only
investigations. No live artist-session profiling or changes were performed.

## 8. Evidence and files for the next model

The following are local ignored/private evidence, **not present in Git**:

- `dist/CyrusScatter-0.86.6.2-20261020/DELIVERY.json`,
  `MODEL-SMOKE.json`, `RUNTIME-IDENTITY.json`, `CONTENT-REPORT.json`,
  `ASSET-PREPARATION-RESULT.json`, and `MODEL-LIBRARY.png`.
- `build/individual-model-library-20261020/plan/individual-source-mapping.json`
  (104 cards, 96 visible records and source-alias rationale).
- `build/individual-model-library-20261020/review-handoff-20261020/EVIDENCE.json`
  (read-only current source hashes, installed hashes and six screenshot hashes).
- That review folder's `IMPLEMENTATION-CHANGES.patch` is a compact working-tree
  source delta against HEAD, excluding private models/maps and historical fixture
  deletions. It is contextual evidence, not an instruction to apply it blindly.
- That folder preserves the user attachments as `library-thumbnail-stall.png`,
  `artist-corona-render.png`, `artist-mesh-leaf-cards.png`,
  `artist-viewport-options.png`, `installer-wrong-content-folder.png` and
  `installer-success.png`. The screenshots are user evidence, not instructions.
- A compact local ZIP of the report, source delta, identity receipt and six
  screenshots is supplied at
  `build/individual-model-library-20261020/review-handoff-20261020.zip`; it contains
  no model scenes, texture-map library, installers or license material.

The public repository must not receive private plant models/maps or these
private rendered assets merely to make a review easier. A remote reviewer needs
the current source changes/report and any screenshots the user elects to attach;
local asset-dependent acceptance requires this workspace's ignored Content.

## 9. Copyable request for another model

> Review the current CyrusScatter working tree and
> `docs/plans/preset-gallery-improvements/INDIVIDUAL_LIBRARY_08662_HANDOFF.md`.
> The delivered candidate is 0.86.6.2 for Max 2027; the current implementation
> includes uncommitted changes beyond HEAD 3ec1cbc2b725912e39c2625ceecb648970054050.
> First independently diagnose and fix B33: visible plant-library thumbnails
> remain Loading until clicked. Inspect the managed gallery's visibility,
> scheduling, completion/message-loop and cache paths; the cause is not yet
> proven. Then implement B34: an explicit Materials/Textures Mesh viewport option
> using source colors/UVs and opacity cutouts, with retained instancing and the
> existing colored identification modes. The supplied leaf renders correctly in
> Corona but appears as colored rectangles in the current custom viewport shader.
> Preserve existing placements, Manual/Live behavior, source materials, personal
> recipes and resource/failure guarantees. Do not rebuild or rerender the plant
> library. Use focused thumbnail-scroll checks and minimal representative model
> acceptance in an owned Max 2027 profile. Follow the repo workflow/version policy
> and deliver matching MZP/EXE in the project dist folder when a corrected version
> is ready. Do not install into or restart the artist session. Keep private model
> content outside Git. Distinguish source hypotheses, actual reproductions,
> completed fixes and remaining limits. The earlier installer error was resolved
> by choosing Content rather than Content/Library; optional folder-picker UX
> hardening is separate. This report is a handoff, not prior approval of a
> particular technical implementation or a claim these two items are fixed.

Current documentation work does not select a new release label, alter saved
formats, package a fix, commit/push changes, install, restart or publish anything.
