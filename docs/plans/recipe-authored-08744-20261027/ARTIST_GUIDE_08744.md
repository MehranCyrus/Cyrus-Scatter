# Edited planting recipes — 0.87.4.4

Use **Library > Save Recipe**, select the layers to reuse, and leave **Include models, materials, terrain and paths** enabled for a portable preset. Cyrus Edit moves, rotations, scales, copies and deletions are included. Prepared source guides, their authored preparation and layer contact/hiding settings are included, along with referenced separate collider geometry.

Load the preset normally on your selected terrain. Edited recipes use their saved variation so edits remain attached to their original candidates. Imported owners, source identities and clone identities are independent of the original setup. The imported result calculates before the load succeeds, as one Undo operation. Geometry that no longer has a matching candidate remains saved as inactive edit history.

The usual static material/asset and receiving-terrain restrictions still apply. Keyed objects and parented/grouped source meshes need an explicitly prepared independent static derivative; this delivery does not serialize animation or arbitrary hierarchies. A settings-only recipe requires matching scene asset bindings. Recipe files keep their existing finite size limit and report an explicit error if the authored data is too large. Per-instance radius overrides, arbitrary effects, animation, XRefs and unsupported shaders are not newly supported.

Prepared interactions support one Cyrus Edit modifier per setup. A multi-modifier edited recipe without interactions can load into a new setup; combining modifier stacks into an existing setup is rejected. If the destination modifier has a different enabled state, load into a new setup. These checks preserve the existing setup rather than silently changing its modifier behavior.

The installer contains distinct Max 2024, 2026 and 2027 payloads. Runtime tests for this delivery use **Max 2027 only**; older hosts are build/package checked. Close the selected Max versions, run the EXE, choose the versions to update, and reopen Max. Alternatively run the matching MZP through **Scripting > Run Script**, then restart Max. Keep saved scene copies for your own tests.
