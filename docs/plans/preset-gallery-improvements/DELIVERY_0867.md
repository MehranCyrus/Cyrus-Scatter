# Cyrus Scatter 0.86.7 — library, textured Mesh and source controls

20 October 2026. User-selected version, schema 58 / CyrusUnified1. Matched
Max 2024, 2026 and 2027 SDK/native/managed payloads; independent Analyzer,
licensing and MCP versions are unchanged. This is scoped user-test qualification,
not publication readiness or certification of arbitrary shaders/scenes.

## Delivery

Folder: `dist/CyrusScatter-0.86.7-20261020/`.

- `CyrusScatter-0.86.7-Setup.exe`: one unsigned Windows installer with all three
  exact MZPs embedded. Keep its adjacent **Content** folder when sharing.
- `CyrusScatter-0.86.7-Max2024.mzp`, `-Max2026.mzp`, `-Max2027.mzp`:
  **Scripting > Run Script** in the matching Max, choose the supplied content
  folder when prompted, save work and restart Max.
- `SHA256SUMS.txt`, `CONTENT-REPORT.json`, `QUALIFICATION.json` and `INSTALL.txt`
  identify the actual delivery and its evidence.

No artist installation, session restart, source-model overwrite, Git commit/push,
or website build/publication was performed. The working tree includes previous
uncommitted work beyond `3ec1cbc2b725912e39c2625ceecb648970054050`; Git alone
does not back up ignored models, installers or test receipts.

## Changes

**B33 thumbnails:** WinForms wheel scrolling can move the view without invoking
the existing OnScroll scheduling path. OnMouseWheel now schedules newly visible
tiles after the base scroll. The actual-control regression reproduces the stall
with that override removed, and passes with it present. Two bounded image workers,
generation cancellation, cache admission and UI-thread publication remain.

**B34 appearance:** choose **Mesh > Appearance > Materials / Textures**.
Native host-thread preparation copies source UVs and bakes bounded color/opacity
tiles. The retained GPU path keeps existing geometry/instance buffers and uploads
changed appearance data separately. Existing identification enum values are
preserved; source render materials are not rewritten.

Direct weak watches on the bounded material reference graph cover nested maps
and UV generators whose edits did not reliably reach the source-node watcher.
Color-management changes invalidate appearance. Corona map strengths respect
the parameter's SDK dimension: a UI percentage is not necessarily its stored
float. The real leaf test exposed this distinction.

**Models & Points:** **+** below the list adds a model; the top Add Point/Add
Model row and Add currently selected scene objects action are removed.
**Add Point** is beside **Make point**. **Pick object** replaces a selected
Point or model while preserving its row ID, label, weight, scale, radius,
offset and assignments. Duplicate sources and receiver picks are rejected.
The original scene object is retained.

**Library import:** dependency errors identify an unavailable material/map.
MAX headers can mention unused editor or studio plug-ins, so the bounded actual
merged shader graph is checked. A failed operation explicitly removes only its
captured imported nodes and restores selection; a host hold alone did not
remove those nodes in the tested older host. This does not claim that native
MAX file merging preserves arbitrary prior Undo history.

## Qualification

Primary receipts: `build/viewport-0867-20261020/`; final cold host receipts:
`build/mcp-qualification/viewport0867-test6-{2024,2026,2027}/`.
`QUALIFICATION.json` compares each loaded script/native/gallery identity with
the final MZP, records per-test results and preserves the original package hashes.

| Check | Evidence and boundary |
| --- | --- |
| Native build/tests | Distinct SDK builds for three hosts; Max 2027 native CTest: 48/48 |
| Generated/control integration | 320 current semantic controls; all 245 historical register entries accounted for, including explicitly retired Add selected; layout test passes |
| Python checks | 175 MCP/tool tests pass after updating the intentionally changed control-count expectation |
| Hosted gallery, all three Max years | 96-model catalog, wheel after idle without selection, warm revisit, resize, search/category replacement and disposal during queued work |
| Native Mesh, all three Max years | Nonsequential Multi/Sub IDs 3/8, color UV1 + opacity UV2, missing-UV retained result/recovery, UV edits, representation/appearance switching and scene reopen |
| Static/pending state | Material edits preserve placement epoch and geometry uploads; warm navigation uploads no unchanged buffers; pending Manual amount remains pending |
| Actual generated source controls, all three Max years | Add Point, Point→model, model→model, Make point, preserved source identity/settings, Undo/Redo and invalid-pick rejection |
| Real model, Max 2027 | A027 Bent Leaf imported through the product library command with original Corona/Forest graph, bitmap texture and opacity. Color Correction wrapping the graph, property edits, diffuse clearing, Undo, opacity off/on, animation and warm navigation pass |
| Content compatibility | All 96 saved single-mesh files readable as Max 2024 format in Max 2024/2026; absent material dependencies roll back; supported Standard fixture imports despite unrelated OpenPBR/Arnold file-header dependencies |
| Installer | 19 inert transaction/reuse/rollback checks; real EXE embedded-package extraction and install/repair in three owned destinations; physical file IDs prove shared model bytes. Exact MZP installer core is checked inside the three Max runtimes |

The final real-install campaign encountered one transient Windows access denial
while renaming a staged Max 2027 release. The old registration remained intact;
retry completed successfully. That failed attempt is not counted as a pass.

The older local hosts lack matching Corona/Forest dependencies. Their native
Standard/Multi/Sub tests and saved-file checks are passes; actual Corona model
appearance/rendering in those hosts is **not qualified**. Install the appropriate
renderer/map plug-ins for each host. No 2025 support is inferred.

Real leaf screenshots:
[original](../../../build/mcp-qualification/viewport0867-test6-2027/real-leaves-original.png),
[Color Correction](../../../build/mcp-qualification/viewport0867-test6-2027/real-leaves-corrected.png),
[edited correction](../../../build/mcp-qualification/viewport0867-test6-2027/real-leaves-edited.png),
[opacity off](../../../build/mcp-qualification/viewport0867-test6-2027/real-leaves-opacity-off.png),
[opacity restored](../../../build/mcp-qualification/viewport0867-test6-2027/real-leaves-opacity-restored.png).

## Content reuse and storage

The existing distribution's **Content** directory was moved from 0.86.6.2 to
0.86.7. The 96 prepared meshes were saved back through Max 2027 to Max 2024 file
format; no replacement geometry or previews were generated. Six files needed
removal of explicitly identified obsolete studio/legacy metadata. Live plant
materials remained intact. The save-back receipt records per-model hashes,
face/vertex counts and removed metadata.

All **1,107 image/preview files, 1,042,687,464 bytes**, remain byte-identical.
Only 96 MAX files and the catalog metadata changed. Total current content:
1,204 files / 5,851,207,027 bytes. Original catalog models, artist installation
and a pre-existing build content copy were preserved.

The installer stores verified content once per user in a short shared NTFS
store and links it into host/version directories. It reuses matching previous
installed assets, validates hashes, rejects modified blobs, repairs missing
links and preserves old releases needed by open Max sessions. New MAX save-back
bytes require new content; unchanged images do not. Old recovery releases are
not automatically garbage-collected. After evidence capture, 8,280
hash-verified temporary content links/blobs were removed from the owned test
installs. Small test runtimes and receipts remain; the shareable distribution
is intact. The broader recursive cleanup was blocked by automatic review, so
cleanup used explicit verified files instead.

## Supported preview boundary

Standard and Corona Legacy/Physical base color and cutout opacity, Multi/Sub
face IDs and common explicit UV channels are covered. Each color or opacity
branch requires one common source UV channel; the two branches may differ.
Map chains such as Bitmap/Checker/Color Correction are supported within that
boundary. Forest Color previews omit per-instance Forest variation.

Tiles are 256×256, at most 64 submaterials per source and 512 sources per call;
map traversal and weak dependencies are bounded. CPU snapshots, staging and GPU
admission count toward existing resource limits. Failure retains the prior
complete display; pending geometry requires Update before appearance can be
paired with it. The shader is two-sided with an alpha cutoff of 0.5, not a full
Corona/PBR/translucency or semi-transparent blend. World/object/vertex-dependent
map evaluation, different front/back shading, arbitrary third-party graphs and
renderer-perfect color are not qualified; unsupported branches report fallback.
Proxy/Point Cloud and reduced-box display retain their existing behavior.

The relevant contracts are F04 setting ownership/Manual state, F05 atomic
successors, F06 bounded resource ownership, F07 host-thread API access and
F08 dependency-specific invalidation. Appearance changes do not claim a broad
performance speedup. B21 panel latency and the separate Physics Lab remain
outside this release.
