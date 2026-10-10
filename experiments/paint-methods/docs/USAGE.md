# Trying the four standalone prototypes

These are **0.1.0 experiments for Max 2027**, separate from Cyrus. They are intended to compare interaction and representations, not replace the production brush yet. See [results](../results/README.md) for measured scope and known failures.

## Start a trial

Open a method's extracted package under [`dist/0.1.0-final/`](../dist/0.1.0-final/), then run `Try.cmd`. Python 3 and Max 2027 must be installed. This first launcher expects the existing English Max 2027 profile and local installation paths used on this workstation. It opens a **new Max process**, using a disposable profile and a sample plane. It loads that method's DLL and window; it does not install into the normal Max profile or reuse the artist's running process.

1. Click **Pick receiver / new region**, then select `PaintLab_Receiver`.
2. Choose Paint or Erase, set Radius, then press **Start painting** and drag over the plane.
3. Press **Stop** before changing brush settings. Right click ends the Painter session.
4. Try intersecting strokes, holes, separated islands and a much larger painted area. Earlier paint should remain.
5. Use the tool's **Undo paint / Redo paint** buttons. These are a dedicated experiment history; Max Ctrl+Z integration is not implemented.
6. Use **Save region** to export `.plab` data. Load into an identical receiver snapshot and the same precision. Saving the Max scene does **not** embed the lab region. Closing the tool discards regions that were not exported.

Each explicit receiver pick creates a named region. Later gestures edit the selected region. You can pick multiple receivers and switch with the list. There is no automatic new region for each gesture, and no source model/population ownership hidden inside it.

## Precision and display

**Paint precision / pixel size** is fixed when a region is created. A uses it for polygon quantization; B and D use it for stored field samples. C stores analytic sweeps, so this value does not limit its canonical query precision. Smaller values can cost more memory/work. Settings are in Max system units, with world-unit spinners for input.

**Display step** independently controls the shared mesh preview approximation. A displays its canonical contour; B/C/D currently extract a 50% weight contour on the display mesh. Points/fill show nonzero coverage, with color brightness indicating weight. A low-strength soft stroke can therefore be visible without producing a 50% contour. Display samples are a diagnostic visualization, not generated plants or a scatter density calculation.

The shared preview refuses to build more than 300,000 complete cells. Increase Display step if it refuses. It retains the previous complete display and paint rather than publishing a truncated portion. Display refusal is still a usability limit, not a successful performance result.

## What to compare

| Method | Useful trial | Known restriction |
| --- | --- | --- |
| A — Vector Regions | Hard borders, erase holes, many strokes inside an existing region | Projected workflow; arbitrary soft interior opacity and sphere painting unavailable |
| B — Tiled Density Mask | Soft density, large/fine brushes, expanding terrain regions | Projected workflow; storage resolution affects borders and memory |
| C — Surface Stroke Volumes | Curved receiver, long history, intersecting strokes | Euclidean volumes can reach nearby sheets; history/index costs grow |
| D — Baked Surface Field | Coarse mesh, triangle seams, curved receiver, soft painting | Current footprint is restricted Euclidean, not geodesic; connected folds can leak |

Receiver geometry/transforms changing suspends the region and preserves data. Automatic deformation, topology rebinding, receiver restoration, native Max scene storage, complete Include/Exclude composition, spline interchange and retained Nitrous uploads are later lab gates. The existing process keeps display geometry cached on the CPU; the current GraphicsWindow drawing path does not establish GPU buffer reuse or presented FPS.

## Useful feedback to record

Record method, receiver, scene units, paint precision, display step, radius, strength, approximate drawing size/history, and the action that felt wrong. Distinguish a missing border, missing fill and a wrong coverage query. The window shows state size, edit time and preview preparation time; these are not physical input-to-present latency.

Try the same drawing in all four. A method earns further work only if its supported workflow is accurate and comfortable. A poor result is useful evidence; we do not preserve a candidate simply because it has been implemented.
