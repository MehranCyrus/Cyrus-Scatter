# Cyrus Arrange inspector API — 0.1.3, Max 2027

The inspector/export interface exposes nine visible MAXScript primitives. The
same `.dlx` also exposes the persistent setup and placement commands documented
in [the arrangement API](ARRANGEMENT_API.md). Call these APIs from Max's main
thread. The MAXScript UI owns controls and bounded summaries. Evaluated geometry,
region/cell storage, JSON serialization and overlay construction remain in C++.
No source node is modified by inspection. No script-sized geometry arrays cross
this API. Input names and handles in diagnostics are captured evidence, not live
references or executable expressions.

This describes 0.1.3; [the release ledger](RELEASE_VALIDATION_0.1.3.md) identifies
the exact build, host evidence and delivery status. Arrangement geometry reuse
is enabled by default, with current dependency and transaction checks.
That arrangement cache does not reuse or refresh this independent inspector
snapshot.

## Commands

- `caVersion()` returns `"0.1.3"` in the working source.
- `caSummary()` returns SUMMARY from the retained native snapshot without
  evaluating scene nodes or calculating geometry. It throws when no snapshot
  exists. The UI uses this passive read when reopening its panel.
- `caInspect nodeArray cellMM clearanceMM slopeDeg` stages a new native snapshot
  and returns SUMMARY below. All distances supplied to this command are physical
  millimetres regardless of Max's display units. Cell size must be finite in
  `[0.1,1000000]` mm; clearance in `[0,1000000000]` mm; slope in `[0,45]` degrees.
- `caRegion oneBasedIndex` returns REGION below for the retained snapshot.
- `caCreateOverlay()` returns one regular Editable Mesh node showing usable
  sampled cells. Cells are horizontal quads, inset by 3% of cell size per edge
  and raised by `min(0.5 mm, cellMM*0.01)` for visibility. The node is
  non-renderable and has the Boolean user property `CyrusArrangeGenerated=true`.
  It also records `CyrusArrangeVersion` and `CyrusArrangeFreshness` strings.
  Creation participates in an existing Undo hold, or creates its own single
  hold when called without one. The UI should wrap its replacement/deletion and
  this creation in one `undo on` transaction. Sources are not selected or changed.
- `caExport filename` returns `true` after native UTF-8 JSON export. A staged
  sibling temporary file is flushed/closed before Windows replacement of the
  target. Write/publish failures retain the cached snapshot and existing target.
  No directories are created. Export is a file action, outside scene Undo.
- `caClear()` releases the one cached native snapshot and returns `true`. It does
  not delete scene overlays and is not scene Undo. The UI deletes only its own
  generated overlay nodes when requested.
- `caDiagnostics()` returns DIAGNOSTICS below, including when no snapshot exists.
- `caModulePaths()` returns `#(actualMainDlxPath, actualStorageDlhPath)` for the
  loaded `CyrusArrange.dlx` and `CyrusArrangeStorage.dlh` modules. It throws if the
  companion module is not loaded or its path cannot be read. This passive
  diagnostic reports paths; qualification separately compares the actual file
  hashes with the candidate binaries.

## SUMMARY — 16 fields, one-based MAXScript indices

| Index | Value |
|---|---|
| 1 | Product version string |
| 2 | Captured geometry node count, after group expansion/deduplication |
| 3 | Input triangle count |
| 4 | Region count |
| 5 | Sampled cell count |
| 6 | Usable cell count |
| 7 | Total sampled area, mm² |
| 8 | Total usable area, mm² |
| 9 | Captured assembly minimum bounds, world-mm `point3` |
| 10 | Captured assembly maximum bounds, world-mm `point3` |
| 11 | Array of diagnostic/warning strings |
| 12 | Capture time, integer Max ticks |
| 13 | Translation origin, world-mm `point3` |
| 14 | Cell size, mm |
| 15 | Requested minimum clearance, mm |
| 16 | Maximum slope, degrees |

Fields 2–6 are native `Integer64` counts; REGION cell counts and numerical work
counters likewise retain their integer precision. MAXScript's literal `as string`
may append `L`. Format that suffix for display without narrowing the actual values
or converting IDs/counts through floating point.

## REGION — 9 fields

`#(id, boundsMinMM, boundsMaxMM, sampledAreaMM2, usableAreaMM2,
minimumClearanceMM, openAbove, cellCount, usableCellCount)`

Bounds are world-mm `point3` values. `minimumClearanceMM=-1` means infinity/no
overhead hit in the captured geometry; other values are nonnegative. Region IDs
are deterministic within this snapshot, not persistent face/topology identities.
Regions can contain blocked cells; usable area/count are reported separately.

## DIAGNOSTICS — 10 fields

`#(loadedDllPath, version, hasSnapshot, sourceRows, timeTicks, work,
triangleCount, sampledCells, regionCount, originMM)`

Each source row is `#(capturedNodeHandle, capturedNodeName)`. With no snapshot,
sourceRows is empty and numerical fields/origin are zero. Loaded path comes from
the actual loaded DLL module rather than a configured installation directory.

## Coordinates, limits, failure and ownership

Input nodes are sorted by handle; selected groups expand recursively and repeated
members are deduplicated. Generated overlay nodes are skipped. Selecting a camera,
light, non-group helper, empty geometry or unconvertible object rejects the whole
successor with a useful error. The adapter accepts evaluated geometry convertible
to `TriObject`; renderer proxies that expose an approximate mesh cannot be
certified automatically. Use explicit analysis geometry for those assets.

Max geometry evaluation and mesh copying are synchronous on the main thread.
Temporary converted objects are released only when conversion returned a distinct
object. Capture explicitly queries `GetObjTMAfterWSM` before a fresh
`EvalWorldState` and before borrowing the evaluated object/mesh. This final
pipeline frame can be identity when a world-space modifier already produces
world-space geometry; context-dependent `GetObjectTM` is not a substitute.
Transform evaluation can invalidate borrowed pipeline data, which is why query
order matters. See the [Max 2027 INode reference](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_node.html).
Negative evaluated-frame parity reverses winding. World coordinates are calculated in double precision,
converted to millimetres and translated around the first captured vertex before
calling the core. Original reversed/invalid mesh normals are not repaired.
The explicit post-WSM source correction follows the native36 boundary failure;
native37's inspector regression and native39's independent WSM boundary suite
subsequently passed on their named pairs, as recorded in
[the host evidence](research/CACHE_HOST_VALIDATION_2026-10-18.md). Final native46
release acceptance remains separately tracked in the qualification ledger.

At an explicit zero-degree slope, an upward triangle may also satisfy numerical
flatness when its complete Z span is within the shared **0.002 mm** default
contact tolerance. Other slope checks and all sampling/clearance tests remain.
The separate default 0.5 mm sample-to-plane matching tolerance is not the exact
accessory contact bound. Inspection still reports sampled support rather than
full-footprint fit; the arrangement query checks its true support height band
and polygons separately. See [numerical support](NUMERICAL_SUPPORT.md).

The default core limits remain authoritative: 1,000,000 triangles, 1,000,000
sampled cells, 4,096 regions, 50,000,000 work operations. Adapter admission also
limits assemblies to 4,096 visited nodes and 3,000,000 input vertices. Overlay
construction separately rejects more than 250,000 usable cells before scene
mutation (at most 1,000,000 vertices/500,000 faces); increase cell size to reduce it.
Nonfinite coordinates/settings, invalid indices and singular transforms reject.
Core near-origin coordinates must remain within its 1,000,000,000 mm bound.
Overlay additionally rejects local or translation float quantization exceeding
`max(0.01 mm, cellMM*0.001)` instead of silently shifting coarse coordinates.

The previous complete snapshot remains until the successor and its small script
summary are complete. Failure retains that previous result. Capture geometry,
successor result and previous result can coexist; these caps are not exact whole
Max memory guarantees. `caClear` releases cached data; an overlay is separately
owned by Max's scene and Undo system.

The inspector retains a session-only **captured snapshot**, with no live
observers or automatic rebuild for that snapshot. The separate arrangement
system has native persistent setup ownership and dependency observation; these
do not refresh inspector data. Editing sources, time, units or opening
another scene does not recalculate the inspector snapshot; Inspect again or Clear. Cached source
handles/names are never dereferenced for export or overlay creation. Overlay
reconstructs physical captured coordinates using the current system-unit scale.
Regular mesh overlays can save/reopen without this plugin; cached analysis does
not persist and is not undoable.

JSON schema 1 exports `coordinate_space="world_mm"`, snapshot freshness,
captured units/time, settings, origin, bounds, counts, source rows, warnings and
regions/cells. World-mm positions have the translation origin added back.
Unbounded positive clearance is JSON `null` (not invalid `Infinity`/`NaN`). Names
and warning text are UTF-8 with JSON escaping for quotes, slashes and control
characters. MAXScript Point3 summaries/overlays use Max float precision; JSON
retains native doubles. Detection remains sampled support/clearance, not proof of
exact boundaries, access, cavities or accessory fit.

Host acceptance of a changed source pair requires its exact DLL/UI pair: group overlap and mirrors,
units/pivots, failure retention, UI handlers, overlay Undo/Redo, valid JSON with
escaped names, Clear release, overlay save/reopen and source preservation.
Historical passing receipts remain evidence for their original pairs only.
