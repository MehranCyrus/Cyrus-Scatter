# 0.87.4 implementation record

27 October 2026. The user authorized the preparation editor, fern/grass Max 2027 tests and a matched MZP, explicitly selecting **0.87.4**. This supersedes the proposalâ€™s tentative 0.88.0 label. See the [delivery](DELIVERY_0874.md) for exact qualified bytes, executed checks and remaining acceptance.

## Ownership and native boundary

Foundation contracts F01 and F03â€“F11 apply. Authored intent belongs to the stable layer/source slot, guarded by the complete source fingerprint. Connected-piece indices are valid only within that fingerprint; they are not identities across remeshing. Existing minimum length, branch connection, stiffness, foliage fraction and budgets remain layer settings. No library asset or original source mesh is modified.

`preparation_authoring.hpp/.cpp` discovers deterministic complete pieces and validates sparse roles, root seeds, guide direction, 3â€“16 guide points and parent-piece references. Constraints are applied before topology inference. Automatic inference cannot silently replace a failed authored guide. Fixed pieces retain their faces/rest coordinates and bypass movable envelopes. Follow pieces retain rigid attachment. The global source ground remains stable when one lower piece is excluded, preventing unrelated crown guides from changing.

`preparation_editor.cpp` owns one modeless source viewer and session. Host capture and commit access Max objects only on its thread. A worker consumes copied numeric geometry/settings, checks cancellation and publishes only the current draft/pose generation. One job runs and one newest request waits; selection/browsing does not reanalyze. Close/reset/shutdown cancels and joins before freeing the session. Cancellation is cooperative; closing can wait for a bounded native fitter call to return. Cancellation is cooperative; closing can wait for a bounded native fitter call to return. Native source reservations, configurable admission limits, a bounded draft history and a viewer-buffer estimate constrain work; these are not a measured process-memory peak.

## Viewer decision

Qt runtime DLLs exist, but matching development headers/libraries are absent from the local toolchain. The delivered approach uses a native Win32 window and Direct3D 11 source viewer from the installed Windows SDK. It does not embed/reparent Nitrous or bundle another Qt runtime. GPU piece-ID/depth picking implements visible selection; projected complete triangles implement explicit through selection. Neutral two-sided role shading deliberately ignores texture opacity. Whole connected pieces are the selection unit; arbitrary welded face regions remain later work.

Physical testing found that an unregistered popup let Ctrl+Z reach Maxâ€™s scene Undo. The corrected viewer registers/unregisters its modeless window with Max, scopes accelerator suppression to its activation, and forwards draft shortcuts from buttons/frame to the viewer. Text-edit controls retain their own editing behavior. Keyboard qualification is recorded against the final package, not the earlier candidate.

## Persistence and publication

- Scatter version: **0.87.4**, per user selection.
- Native Interactions capability: **8**; scripts require the matching module.
- Scene class schema: **62**, preserving deliberate readers for preceding 59/60/61 scenes.
- Host prepared-definition envelope and authored compiled source: **format 2**. Unauthored format-1 definitions remain readable.
- Canonical authored intent: version **1**, sparse and fingerprint-bound.
- Analyzer, content, licensing, MCP and independent Lab product versions remain separate.

The generated UI adds **Edit preparationâ€¦** under Prepare model. Inspection can open before successful automatic inference. Draft edits update asynchronously; Use stages a complete definition and contacts against the last published placements. It recaptures source/settings and validates captured owner, slot and previous definition before one short Undo transaction. Ordinary arrays stage ParamBlock changes. A failed successor restores the previous definition/contact state and retains the draft. Unrelated pending Manual Count/placement edits are not consumed. Repeated Prepare and supported setting refresh pass the saved authored intent back to native compilation.

Cancel/window-close discards the draft. Popup Undo/Redo is distinct from Maxâ€™s scene history after Use. Save/reopen retains authored intent. Recipe/library contact export remains guarded; the editor does not make it a portable prepared-asset system.

## Changed areas and qualification scope

Authoritative changes are in `AminScatter/tools/ui/templates/`, the declared layout row, generated script/manifests, `AminScatter/src/interactions_host.cpp`, `interactions_source.cpp`, the new editor units, topology preparation and native authoring tests. `tools/build_inputs.py` explicitly enrolls the new authoring sources/headers in frozen builds. `tools/procedural_lab/interactions0874/` owns reproducible packaging and private-profile campaigns.

E0â€“E4 are implemented for the documented scope. E5 is **scoped fern/grass acceptance**, not completion of every original validation-matrix row. E6 is the exact matched Max 2027 MZP and scene copies. Broader garden scale, multiple DPI/driver configurations, arbitrary welded plants, production rendering and long-session memory remain explicit follow-up acceptance. A deeper grass contact exceeded the existing edge-strain quality threshold; it is retained as a known limitation, not counted as a passing contact.

No artist-profile installation/restart, older-host work, EXE, website publication or Git push is part of this request.
