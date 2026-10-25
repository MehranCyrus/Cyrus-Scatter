# Vegetation Stem Lab 0.2.0 — Max 2027 test kit

An independent, asset-specific experiment for moving a sphere through the prepared Lavender 05 model. It does not alter CyrusScatter. The scene embeds its stem preparation and source mesh, so it remains editable after reopening with the matching native modules.

## Run the test

Save your current Max work first. Keep the extracted test-kit folder together. In **Max 2027 > Scripting > Run Script**, run **OpenTest.ms**. It verifies the native/script/scene files, loads the native class and opens **Lavender_Stem_Live_Max2027.max**. A scene requiring saved work will be left untouched.

Click **Select sphere to drag**, press **W** if needed, and move `CVS_Collider_Sphere` along X toward the lavender. The default viewport uses the lighter preview. Move the sphere away to restore the original shape. The controls can pause live interaction, show the full viewport mesh, or print a full-resolution contact audit. Rendering and mesh conversion use the full geometry.

The `.mzp` installs this same portable kit into a versioned folder under your user scripts directory. It does not replace CyrusScatter. After installation, run the installed `OpenTest.ms`; if a different Stem Lab binary is already loaded, save work and restart Max 2027 before opening the new kit. The accompanying portable folder also works without changing your plug-in directory settings.

## Preparation and limits

- Original plant: 577,792 vertices / 832,240 triangles. Preview: 62,568 vertices / 90,640 triangles.
- 1,290 centreline guides come from actual tube cross-sections. Parent attachments follow the source's authored tube order, including downward-growing twigs. Leaves, flowers and irregular small parts follow rigid attachment frames, preserving their local shape.
- 150 irregular stem pieces are attached rigidly rather than treated as independent flexible tubes. This is prepared for the supplied asset; it is not a general automatic vegetation-rigging tool.
- Static rooted contact fitting, with a bounded joint-rotation fallback for difficult child stems. It is not wind, inertia, stem-to-stem collision or a general cloth simulation.
- Only the supplied complete Sphere is a collider. Keep uniform positive scale and the saved system units. Source and output transforms are locked/retained; move the sphere.
- Preview is a reduced representation. Use **Validate full mesh** for contact/shape diagnostics. Plain botanical test materials and regenerated geometric normals are supplied; original Corona/texture/normal fidelity is not qualified.
- Difficult or unsupported inputs retain the previous accepted pose and report an error in the panel. That retained result can be stale relative to a newly moved collider.

The dated qualification report beside the kit records actual drag evidence, source/native identities, timing and remaining limits. Historical research and the original Vegetation Lab 0.1.0 remain separate.
