# Cyrus Scatter 0.41 — Boundary orientation

In each layer, open **Diversity / Colors → Analyze Surface**. Choose **Border** or **Street Side**, then enable **Face outward**. Each channel has independent settings, disabled by default for existing scenes.

Under **Source Object**, select a source row and choose its **Forward axis**: +Y, −Y, +X or −X. This is the local axis of the model which should face out of the planting surface. Point placeholders retain this setting when replaced with a model. Multiple selected rows can be assigned together.

**Corner radius** is measured in scene units around a boundary vertex. Within this distance the outward direction blends between the neighboring edge normals. Exactly at a corner it is their normalized bisector, for both convex and concave corners. Radius zero uses individual edge directions, while an exact corner still uses the bisector. Street Side uses the actual adjacent boundary edges, including an adjacent edge not marked as Street Side. Hole boundaries face into the hole.

Facing overrides procedural XYZ random rotation for affected Border/Street Side placements. The object's local Z follows the analyzed boundary plane, with its upward normal chosen consistently. This setting does not change positions, source IDs, point counts or scale. It runs after collision and final relax, before CS Edit; manual edits therefore remain last. Centerline, Points and ordinary Line Pattern do not use this setting.

Install the MZP, then restart 3ds Max 2026. The running session cannot swap the native binary. Version 0.41 uses a separate bin41 directory; back up scenes before saving them with a newer plugin version.

Validation: native tests cover four forward axes, 90°/45° corners, concave corners, hole and reversed winding, Street Side masks, tilted planes, Z offsets and float transport at exact edges. The provided Surface_analayzer_2.max was tested in a separate Max process: 4,709 boundary orientations updated without changing the three layer counts (2,688 / 3,273 / 1,436). Save/load, CS Edit composition, Point replacement and 7,397 PFlow transforms passed. No new Corona IR render benchmark was performed for this update.
