# Instance selection — 0.87.6.4

Hover a displayed scattered mesh: a simple box identifies that one instance.
Click it without a modifier key to select its layer and enter **Cyrus Scatter
Edit > Instances** with that instance selected. Use Max's Move, Rotate or Scale.
The Edit modifier remains separate; it is added automatically when needed.

To change the scatter's settings, select its **SC icon** or select **Cyrus
Scatter** in the modifier stack. To work with multiple setups, use Ctrl selection
or the scene selection tools; the existing shared controls remain available.

Picking uses the geometry actually displayed, including viewport draw limits.
Hidden or undisplayed instances cannot be clicked. The hover box is a visual cue;
the initial pick still checks the visible mesh, so gaps between leaves remain
pickable as gaps. Point Cloud/Centers keep their existing selection behavior.

Selecting an instance does not apply pending Manual settings. Use **Update
scatter** for those changes. The existing Live/Manual editing rules remain.

## Installation

Save your work and close the Max versions selected for installation. Run
`CyrusScatter-0.87.6.4-Setup.exe`, choose Max 2024, 2026 and/or 2027, and install.
Each host has its own native payload.

Alternatively, use **Scripting > Run Script** with the MZP for your Max version,
then restart Max. Install the complete package; it contains a matching script
and native modules. Existing Library content is reused.

Max 2027 has the focused runtime checks in [the delivery](DELIVERY.md).
Max 2024 and 2026 are SDK-built and package-verified, without host execution.
