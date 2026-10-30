# Try 0.87.6.1 and the Terraces garden

Use `dist/CyrusScatter-0.87.6.1-20261029/CyrusScatter-0.87.6.1-Setup.exe`.
Save your work, close the Max versions selected in the installer, then choose
**Install / Update**. The EXE includes Max 2024, 2026 and 2027 payloads. The scene
and runtime testing are Max 2027 only.

Alternatively run `CyrusScatter-0.87.6.1-Max2027.mzp` using **Scripting > Run
Script**, then restart Max. Install the complete package, not a loose script.
Keep the optional content-library checkbox off when your shared content is
already installed. Surface Analyzer remains a separate installation.

## Scene

Open `Terraces_Garden_0.87.6.1_Max2027.max` from the delivery's `Scenes` folder.
It references the existing local library maps and supplied boulder textures.
The scene is a Max 2027 file; it is not a tested older-host scene export.

Four named cameras show the estate, lake promenade, meadow/house and boulder
garden. Start with **GARDEN | 04 Boulder garden** for the closest planting view.
Five named Scatter controllers separate woodland, meadow, shrubs, lake details
and boulders. The original house, terraces and path remain.

To try interaction, select **GARDEN | Lakeside boulders**, open its **Cyrus Scatter
Edit** modifier and select an instance from the **Hero boulder** or other stone
layers. Move it through **Interactive grass at the boulders**. Its preparation is
already saved. Bend/Trim and root hiding are enabled; the three stone layers
share a closed proxy for the original open-bottom rock. The proxy is hidden and
nonrenderable. Leave the original source and proxy together in their saved setup.

## Display and controls

- **Point + Bands:** assign the new Point to a Band; the Models list caption
  updates without renaming or manually refreshing it.
- Panels retain their mounted controls when reopened. Changing a setting while
  a panel is closed still refreshes its values when reopened.
- **Fixed base 100%** or **Bend strength 0** avoids pointless bending queries.
  Trim and root hiding still do their own work when enabled.
- **Viewport & render** has separate navigating and idle triangle budgets.
  The landscape uses practical limits; some instances may appear as boxes or
  fewer meshes while navigating. These limits do not reduce accepted placement
  counts or the automatic final-render planting.
- The renderer uses the original library materials. Corona/Forest-dependent
  assets require their corresponding plug-ins. A textured viewport is an
  approximation of those materials.

The separate `Contact_Distant_10000_Stress.max` is a measurement fixture with
10,000 additional distant reacting trees. It is not the comfortable artist scene.
Do not use its load or memory behavior as a promise of full-detail realtime.

If a proxy removes too much vegetation around a complex shape, use a more
appropriate closed custom collider. A convex shape fills concavities; it should
not bridge doorways, root gaps or spaces you intend to preserve.
