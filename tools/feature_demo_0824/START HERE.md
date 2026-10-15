# Cyrus Scatter 0.82.4 feature demo

Open **CyrusScatter 0.82.4 Feature Demo.max** in **Max 2027** with the complete
**Cyrus Scatter 0.82.4** script/native pair installed. Adopt the file's system
units: **metres, scale 1**. This keeps the receiver-bound Paint data in its saved
units. The scene needs no external models, textures, Forest or Chaos plugins.

Select **CYRUS 0.82.4 | SELECT ME - five feature layers**. It opens with **Manual**
updates: choose a layer, change its controls, then press **Update scatter**.
You can switch to Live to experiment. Save your experiments under another name.

The flat plane on the left has three planting demonstrations. The mountain on
the right compares normal alignment. All pyramids remain procedural Scatter
placements, with six editable source pyramids parked below the plane. Spacing
is disabled in these examples so it does not obscure the density/size effects.

| Layer / color | What is active | Saved accepted count |
| --- | --- | --- |
| 01 Mesh density / orange | Plane channel 2, R/X, 0..1 input range, rising density response; uniform scale 0.8..1.2 | 583 |
| 02 Paint density + scale / cyan | One receiver-bound Paint Area; independent density and scale fades | 772 |
| 03 Bands density + scale / violet and pink | Two inside Consecutive Bands with opposite density and Custom scale curves | 1,107 |
| 04 Mountain, Normals ON / green | Curvature channel 3, slope/altitude limits, Include half and Exclude clearing; normal alignment on | 1,871 |
| 05 Mountain, Normals OFF / blue | The other mountain half uses the same kinds of masks and limits; pyramids remain world upright | 1,949 |

The saved scene contains **6,282 accepted placements**. Counts change when you
edit settings. Colors identify sources; they are separate from numeric mask
values. Max scene layers beginning **DEMO |** organize the objects; the five
planting layers above belong to the Scatter controller.

## 1. Mesh density and uniform scale

Select **01 Mesh density**, open **Amount > Mesh channel density**. The plane
stores a left-to-right ramp in channel **2/X**. The Density curve makes the left
side sparse and the right side dense.

- Turn **Use mesh channel mask** off, then Update: the Include rectangle fills
  more densely. Surviving plants keep their positions and size.
- Turn it back on and try **Invert mesh mask**: density favors the opposite side.
- Edit **Density curve**. A flat zero curve removes this layer; a flat 100% curve
  permits the full included population. Return to the saved rising curve or
  reopen the original demo to restore it.
- In **Transforms**, adjust the uniform scale range, initially **0.8..1.2**.
  This size variation is independent of the mesh density mask. This version's
  mesh channel feature controls density; it does not provide a scale map.
- **Preview mask** shows a bounded grayscale snapshot of this mask. Refresh it
  after edits. **Hide preview** clears the markers.

## 2. Paint density versus Paint size

Select **02 Paint density + scale**, open **Painting** and select the named cyan
Paint Area. Its strip was imported from a closed rectangle. The import is a
snapshot: moving that source rectangle alone does not repaint the area.

Saved values: **Area density 90%**, **Inside fade 1.2 m**, **Outside fade 0.6 m**,
both fades enabled, **Edge scale 0.2**, **Inner scale 1.4**. Separate curves shape
density and size. The outer transition extends beyond the painted border; Edge
scale describes its outer end with the saved curve.

- Disable **Fade density** and Update: more pyramids fill the transition while
  surviving pyramids retain their size.
- Re-enable it, disable **Fade scale** and Update: placement IDs/positions remain
  the same, while pyramids use unchanged source size.
- Restore both, edit each curve independently, and hover over the controls for
  their explanations. Edge scale must not exceed Inner scale.
- Use Paint/Erase or re-import a closed shape to alter coverage. The area shares
  this layer's models and population.

## 3. Spline Bands: two opposite profiles in one layer

Select **03 Bands density + scale**, open **Layout** and select the Path/Band.
The rectangle has two **inside** Consecutive Bands:

| Band | Distance inside the Path | Density from Start to End | Custom size from Start to End |
| --- | --- | --- | --- |
| Outer violet | 0..1.4 m | 100% down to 8% | 0.3 up to 1.6 times source size |
| Inner pink | 1.4..2.7 m | 10% up to 100% | 1.6 down to 0.3 times source size |

Curve X travels **across the strip**, from its Start to End, including inward
for these inside Bands. It does not travel around the Path.

- Make a density curve flat 100%: that Band becomes fuller, while its independent
  Custom scale profile remains active.
- Keep density unchanged and make a Custom scale curve flat 100%: its plants
  retain their positions/count and use unchanged source size.
- Compare **Scale profile > Follow Density** with **Custom**, then restore Custom.
- Resize or edit **PATH | 03 inside spline Bands** to see the live guide input.
  Band widths are world distances. Use Candidate budget, as saved, to retain
  the density fade.

## 4. Mountain: Curvature, slope, height and area limits

Select **04 Mountain | Normals ON** or **05 Mountain | Normals OFF**.

The mountain's **Data Channel** modifier has **Curvature -> Vertex Output** to
channel **3/X**. Scatter reads that channel through **Amount**. The actual values
span approximately **-1.328..1.186**; the saved input range 0..1 clamps outside
values before its Density curve. The modifier's rainbow display colors are
independent of the numeric values used for planting.

- Disable the mesh mask on layer 04 and Update: more eligible mountain positions
  fill. This test increased its count from 1,871 to 3,427.
- In **Transforms**, toggle **Align to normal**. Green pyramids tilt with actual
  receiver normals; blue pyramids remain world upright. Toggling alignment on
  the same layer preserves the tested positions and eligibility.
- In **Include / exclude areas > Surface eligibility**, the saved slope interval
  is **0..45 degrees**, with a **12 degree upper fade**. Density reduces between
  33 and 45 degrees; steeper faces are empty. Disable slope filtering to admit
  steeper positions. Layer 04 increased from 1,871 to 2,191 in that test.
- The altitude interval is **0..5.5 m** with a **1 m upper fade**. Lower the ceiling
  to **2 m**, with **0.5 m upper fade**, to see higher plants disappear clearly.
- Each mountain layer has its own Include rectangle. The red circular spline is
  a shared **Exclude** clearing, projected in XY. Its outline follows the terrain
  for visibility. Move/scale the spline and Update, or remove its assignment to
  allow plants into the clearing. Preserve the original guide when experimenting.

The two mountain layers have different halves and random streams. For a precise
before/after comparison, toggle a setting on one layer and restore it.

## Views and verification

The file reopens in **CAM 01 | Overview**. Use **C** or the viewport camera menu
to choose **CAM 02** (plane), **CAM 03** (mountain) or **CAM 04** (top plan).
Camera icons are hidden by category; all four camera objects remain available.
The **DEMO | Labels** scene layer contains viewport teaching labels.

**53 scripted Max 2027 checks passed**, including independent curve effects,
normal-axis comparisons against actual face normals, area/slope/height limits,
restoration of full transforms/IDs and current-schema save/reopen. The final
presentation file also passed a fresh rebuild/reopen comparison across all five
layers and has no external asset references.

The PNG previews are Scanline snapshots assembled temporarily from the exact
accepted transforms. Temporary preview meshes and lights are absent from the
editable `.max` file. Background viewport grabs proved unreliable in this host,
so they were excluded from delivery. Native renderer parity, sustained-session
performance and physical input qualification remain separate.

Creation, verification and previews used Max scripting APIs. **Computer Use was
not used.** Plugin code/version and the paused Phase 6 were not changed.
