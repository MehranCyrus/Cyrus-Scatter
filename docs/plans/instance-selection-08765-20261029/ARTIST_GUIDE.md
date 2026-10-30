# Mesh hover and selection — 0.87.6.5

Hover a scattered mesh to see yellow edges on that one instance. Click it to
select its layer and enter **Cyrus Scatter Edit > Instances**. The selected
outline stays visible when the pointer leaves. Move, Rotate or Scale as usual:
the outline hides during the transform gesture and returns afterward.

The selection follows the displayed mesh, including bent and trimmed plants.
Dense assets use sampled edges to keep the cue light. A displayed box proxy
keeps a box outline. Large multi-selections retain the existing center markers
in addition to a bounded number of mesh outlines; all selected instances remain
editable. Point Cloud and Centers keep their existing selection behavior.

Select the **SC icon** or **Cyrus Scatter** in the modifier stack to change the
setup. The Edit modifier remains separate. Selection does not apply pending
Manual settings; use **Update scatter** for those changes.

## Install

Save work, close the Max versions selected for installation, and run
`CyrusScatter-0.87.6.5-Setup.exe`. Choose Max 2024, 2026 and/or 2027.

Alternatively, use **Scripting > Run Script** with the MZP for the corresponding
Max version, then restart Max. Install the complete package: the script and
native modules belong together. Existing Library content is reused.

Host qualification and exact package identities are recorded in [the delivery](DELIVERY.md).
