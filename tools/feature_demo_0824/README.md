# Editable feature demonstration, 15 October 2026

User-requested Max 2027 scene containing one flat plane, one procedural mountain
and simple Pyramid models. The scene uses the already qualified **0.82.4** pair;
it does not change product code/version, install anything or resume Phase 6.
Keep the artist's normal session and existing scene files separate.

Final owned host: `build/mcp-qualification/foundation-roadmap-feature-demo0824-20261015-01`.
Source/native input: `build/mesh-mask-0824-20261015-01/script-03`. Launch via
`tools/eleven_phases/launch.py` with a fresh `foundation-roadmap-feature-demo0824-*`
name and `--year 2027`. Submit these files through `tools/eleven_phases/request.py`.

- `build_scene.ms`: entirely scripted scene creation and initial publication.
- `verify_scene.py`: 53 behavioral checks; all temporary parameter experiments
  restore the authored result. Frozen publication fingerprints include full
  matrices, source, identities, anchors, Band ownership and protection fields.
- `finalize_scene.py`, `save_clean.ms`: presentation/camera corrections and
  saved-view reopen verification. The earlier finalizer's DIB images are excluded.
- `render_preview.ms`: creates temporary joined geometry from accepted rows,
  renders four Scanline previews, and never saves those meshes into the demo.
- `verify_delivery_scene.py`: reopens the frozen editable scene, checks full
  publication equality, Manual mode, saved camera, six real source pyramids,
  absence of temporary meshes and zero external asset references.
- `inspect.py`, `capture.ms`, `capture_staged.*`, `finish_presentation.ms`:
  diagnostics. Hidden viewport grabs returned stale or black images despite
  successful camera binding; they are not final preview or renderer evidence.

Fixtures require the redirected owned host and keep correlated failure receipts.
Early producer corrections covered MAXScript reserved names, explicit object-local
mesh coordinates/negative Gaussian exponents, `viewport.activeViewport`, label
bounds, and layer enumeration. These do not indicate changes to the plugin.
Data Channel's Vertex Output class ID uses positive `2882382387L` in MAXScript.

The read-only knowledge generation remained stale; current source and contracts
F01/F02/F04/F09-F11 were inspected directly. No knowledge refresh was performed.
Relevant public API reference: [Autodesk viewport DIB documentation](https://help.autodesk.com/cloudhelp/2024/JPN/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Viewports/GUID-8AA71F9E-F4F0-4437-A44E-9683619E89DE.html).

The delivery copies the `.max`, four rendered previews, [artist instructions](START%20HERE.md)
and scene-verification receipt into a fresh ignored `Test Scene` subfolder, with
per-file hashes and a ZIP. Ignored scenes/binaries are not backed up by Git.
No Computer Use, normal-profile input, installer execution or Git push is part
of this task.
