# Implementation plan

> Original 26 October research/proposal. Implementation was subsequently authorized as 0.87.4. See [current decisions](IMPLEMENTATION_0874.md) and [executed evidence and remaining limits](DELIVERY_0874.md); planned rows below are not all passed.

**Planning only. All implementation packages below are pending.** The current request authorizes research and documentation. It does not start these coding steps, change the installed plugin, or resume unrelated roadmap items.

## Delivery objective

An artist can open a difficult original source, select complete mesh pieces, assign Bend/Follow/Fixed, correct an inferred root or attachment, inspect automatic preview feedback and commit a reusable definition. The normal Prepare button remains sufficient for ordinary plants. The original source geometry and unrelated layers remain intact.

Use Max 2027 only for development and qualification. Preserve the current 0.87.3.2 package/receipts and original scenes. A future version decision is recorded in the [technical design](03_TECHNICAL_DESIGN.md#10-saved-formats-and-release-boundary); do not bump any version during this documentation task.

## E0 — Prove the popup and picking boundary

**Dependencies:** none beyond an owned development profile and exact source/native identities.

- Confirm matching Qt 6.8.3 development headers/libs against the installed Autodesk runtime; keep headless tests independent of Qt.
- Build a small native floating window that draws a copied source mesh, orbits, picks a face/piece, overlays selection and releases its buffers.
- Demonstrate repeated open/close, minimize, multiple DPI scales, source deletion, scene reset and host exit. Test interaction with Max's main window and keyboard focus.
- Prototype visible-only rectangle/brush picking on overlapping thin leaves; check GPU readback/CPU BVH costs.
- Use the fern and grass snapshots. No production scene edits or installed-profile changes.

**Exit:** a working owned Max 2027 witness plus measured memory/input behavior. If the dedicated viewer fails, document the cause and revised native-viewport alternative before building further UI. Runtime DLL presence or a compiled empty dialog alone does not pass E0.

## E1 — Establish native authoring data and invariants

**Dependencies:** frozen data choices from the technical design; E0 establishes the UI transport boundary.

Suggested new native units: `CyrusVegetationLab/experiments/stem-live/preparation_authoring.hpp/.cpp` for host-free records, hashing, validation and compilation inputs. Names are proposed; avoid an independent duplicate core.

- Factor geometry/component inspection out of `analyzeTopology` so it works before successful inference.
- Define categorical piece overrides, root hints, guide keys, parents and attachment locations.
- Preserve existing automatic output when no overrides exist.
- Resolve intent before the ordered-tube/blade/topology inference routes finalize their guides; every route must honor authored constraints.
- Validate supported piece topology, root patches, guide order, complete vertex assignment, fixed handling and rest reproduction.
- Add meaningful native cases for a drooping leaf, decorative base, parent/flower attachment, invalid cycle and changed indexing.

**Exit:** native tests prove complete geometry preservation, exact rest reconstruction and deterministic canonical intent. A role cannot be ignored by an automatic fallback route.

## E2 — Build selection and role editing

**Dependencies:** E0, E1.

Suggested new Max-only units under `AminScatter/src/`: `interactions_editor.cpp`, `interactions_editor_view.cpp`, with an explicit session header under `include/`. Extend the existing host target; keep the numeric model free of Qt/SDK types.

- Source-only view, click/rectangle/selection brush, add/subtract, isolate and material-ID assistance.
- Contextual Behavior choice: Automatic/Bend/Follow stem/Keep fixed; selected count and role colors.
- Simple guide/root overlay, no hover tooltips, no full permanent rig tree.
- Local selection/role Undo/Redo; Reset selected and a secondary Reset all edits.
- Latest-only numeric preview job with one running request, generation checks, cancellation and retained complete preview.

**Exit:** whole-piece semantics are obvious, occluded leaves do not change accidentally, and browsing/selection counters show no preparation or scatter work. Open the editor successfully after a failed automatic preparation.

## E3 — Add the useful guide repairs and private test

**Dependencies:** E2.

- Set root end and display the extracted root patch; Flip direction with dependent rebinding.
- Move supported existing interior guide points while preserving rest geometry.
- Connect to stem / Make root with cycle/distance validation.
- Follow stem parent picking with visible attachment and exact rigid-detail motion.
- Editor-only test sphere, radius and gap; actual `fitSource`/visible-mesh checks, roots kept visible, restoration on moving away.
- Precise unresolved-part messages. Unsupported welded branching pieces stay visible and cannot claim Ready.

**Exit:** fern and flower workflows pass with correct source roots, shape-preserving details, no scene node creation and no collider-free deformation. Testing cannot report success by hiding failed pieces.

## E4 — Integrate persistence, ownership and atomic commit

**Dependencies:** E1–E3.

- Add **Edit preparation…** to the authoritative `interactions-ui.ms` template; regenerate via the existing UI generator. Do not patch only the generated script.
- Extend `interactions-authoring.ms` and `interactions_host.cpp` with bounded open/summary/commit commands and the new guarded definition envelope.
- Preserve overrides through Prepare and automatic settings refresh. Preserve layer-level ownership of existing settings.
- Add authored hash/revisions to the shared rig key and invalidate only affected source/contact data.
- Stage compiled source, current-placement contact results and output resources before one host-thread commit; retain previous state on failure.
- Add local draft vs Max scene Undo separation, source-slot/layer lifetime checks, migration guards, `.max` roundtrip and supported copy/merge handling.
- Keep the existing recipe-contact guards. Do not silently export a recipe that omits authored preparation.

**Exit:** Manual pending edits survive, old/new definitions cannot mix, two layers using one source stay independent, cancellation/failed commit loses neither the draft nor the previous scene result. Save/reopen preserves authored intent and exact source association.

## E5 — Qualify geometry, UI and performance

**Dependencies:** E4.

Execute the [validation matrix](05_VALIDATION_MATRIX.md), including actual generated button handlers and physical Windows gestures in an owned Max 2027 profile. Begin with one fern and one flower; then repeat with many instances sharing those sources and a large garden copy.

Record cold capture, component discovery, inference/binding, viewport upload, picking, contact fit and commit separately. Capture failed attempts and fixes. Enforce full mesh/correspondence correctness before claiming a faster result. Test the important unchanged automatic grass workflow too.

**Exit:** all required first-delivery rows pass with exact identities, failures remain recoverable, and remaining limitations are explicit. Do not treat direct native calls or displayed version captions as UI/loaded-build evidence.

## E6 — Prepare a coherent artist delivery

**Dependencies:** E5 and user authorization to implement/deliver that version.

- Update the maintained artist workflow, engineering decision record, version domains and source/package guards together.
- Build a runnable Max 2027 MZP from the exact qualified native/script pair; verify archive integrity, payload hashes and host/version checks.
- Save an owned fern/flower trial scene and brief testing instructions. Preserve original supplied scenes.
- Record any renderer, scale, topology or DPI limitations that remain outside qualification.
- Provide **Scripting > Run Script**, then restart instructions. Do not install into the artist profile or restart their Max session automatically.

EXE creation, older-host builds, Git push and website publishing need their own current authorization. The proposed editor does not require a second standalone product or a new library system.

## File impact map

| Existing area | Planned change |
| --- | --- |
| `CyrusVegetationLab/experiments/stem-live/analysis.hpp`, `analysis.cpp`, `topology_analysis.cpp`, `connectivity.hpp` | Reusable component inspection and constrained guide/parent inference. |
| `stem_core.hpp/.cpp` | Validated authored mappings, root/frame rebuilding and fixed-part edge cases; preserve the existing decoder. |
| `AminScatter/include/interactions_source.h`, `src/interactions_source.cpp` | Authoring-aware source compilation, key mapping, persistence and exact contact correspondence. |
| `include/interactions_host.h`, `src/interactions_host.cpp` | Captured source/session identity, host-safe lifecycle and commit bridge. |
| `src/interactions_engine.cpp`, `interactions_preview.cpp`, `interactions_render.cpp` | Audit affected invalidation/publication and channel preservation; change only where the new source revision needs it. |
| `tools/ui/templates/interactions-ui.ms`, `interactions-authoring.ms`, `unified-core.ms` | Editor entry, commit/Undo, settings preservation, saved schema/copy guards. |
| `tools/ui/approved-layout-rows.cjs`, layout tests and generated outputs | Add the button and declared controls without reintroducing overflow or tooltips. |
| `AminScatter/CMakeLists.txt`, matched packaging metadata | Max-only viewer linkage, native authoring tests and exact new capability guards. |
| `AminScatter/tests/`, future owned `tools/procedural_lab/` campaign | Native invariants, host lifecycle, physical input and reproducible measurements. |

These are implementation targets, not permission to rewrite neighboring systems. In particular, preserve unrelated Library, Arrange, MCP, Physics and Botany work in the current dirty tree.

## Deliberately later

Partial-face painted regions; splitting welded branches virtually; continuous stiffness/weight maps; new freehand guide networks; multi-guide skinning; reusable prepared-library packages; arbitrary rigged/proxy sources; opacity-aware selection; wind and stateful simulation. Each needs its own correctness contract. Do not add them just because the new editor could eventually host them.
