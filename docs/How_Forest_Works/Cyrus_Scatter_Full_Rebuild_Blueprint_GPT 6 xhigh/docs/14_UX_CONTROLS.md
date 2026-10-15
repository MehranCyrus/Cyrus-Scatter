# 14 — UX design, control hierarchy, modes and artist-readable behavior

## 1. Product principle

**Artist should control composition without understanding the implementation graph.** We can use ForestPack's concepts as behavioral references while creating a distinctive Cyrus Scatter interface and terminology. A UI checkbox is a front end to a typed command with clearly defined dependencies and states.

## 2. Recommended UI information architecture

```text
Cyrus Scatter (one selected scatter)
  Overview           thumbnail / accepted count / build state / scene warnings
  Sources            models, groups, weights, Color IDs, collision footprints, LOD
  Distribution       Image | Path | Reference | Particle/External
  Receivers          surface list, XY/UV, slope/altitude, refresh
  Regions            ordered Include/Exclude Area stack, linked areas
  Paint              brush tools, region selection, coverage/falloff overlay
  Variation          source diversity, clusters, random transforms, maps
  Spacing            collision, boundary/footprint, cross-scatter suppression
  Edit Instances     select/pin/replace/move/remove/rebind
  Procedural Rules   Effects and field graphs
  Appearance         tint, color correction, animation, materials
  Camera & LOD       culling, distance, levels, billboard facing
  Preview & Render   viewport representations, limits, per-renderer capabilities
  Diagnostics        counts, timings, cache, rejected candidates, dependencies
  Presets & Tools    library, exports/bake, version migration, update controls
```

This is a proposed alternative to reproducing ForestPack rollouts one by one; it organizes by user tasks and shared system boundaries.

## 3. Context-aware controls

- `Distribution = Path`: show path list, spacing/vertices, sequence, follow path; hide Image map pixel controls unless explicitly used as a modulation field.
- `Surface = UV`: enable UV channel/island controls and mark unsupported projection/falloff combinations.
- `Area = Paint`: enable brush, erase, preview falloff, convert to spline; warn if no receiver.
- `Diversity = Clusters`: show size/roughness/edge/noise only when at least two eligible sources.
- `Camera-dependent preview`: warn that camera movement may force regeneration.
- `Renderer = unsupported`: show precise fallback, not a misleading enabled setting.
- `Boundary = Edge`: display rendering support requirements, whether viewport can preview, and material dependency.

Disabled controls should explain **why** in a tooltip. Preserve user-defined but temporarily unsupported settings for future reactivation; don't erase them when changing modes.

## 4. Area List editing

Each row includes icon/type, user name, Include/Exclude badge, enabled state, source/receiver icon, falloff indicator, linked-source indicator and warning marker. Drag/reorder with Undo. Display a small live diagram of **bottom-to-top processing**. An overlay can color every accepted candidate by originating Include area and show which Exclude removed it.

For overlaps, warn "two Include regions overlap; duplicate instances may occur" rather than silently deduplicating under compatibility settings.

## 5. Painting UI

Brush size in system/world units, optional screen-size toggle explicitly distinguished; add/erase; tablet pressure for radius/strength; falloff overlay; target receiver; coverage layer selector; brush-edge preview; masked coverage preview. Hotkeys must be configurable and tested against Max's actual current shortcuts.

Distinguish **painted coverage**, **effective density**, and **visible accepted plants** with separate overlay colors. The user can inspect rejected-candidate causes (e.g. coverage exists but collisions suppress plants).

## 6. Source list and variation feedback

Sources should have thumbnails, names, probabilities, enable/empty state, source color, geometry size, collision radius and group policy. Sum and normalized probabilities displayed side-by-side. Give an intentional empty-slot button and a separate mute-from-selection action.

For Color ID mode show legend from map colors to selected source. For clusters show a top-down source-class preview and clarify how Size, Roughness, Mixing and Noise influence patches. Use source labels/IDs, not material colors alone.

## 7. Parameter semantics visible to artists

Every control has unit, default, valid range, type, data domain, dependencies and behavior when toggled. Example:

| Control | Tooltip concept | UI treatment |
|---|---|---|
| Density | Changes candidate acceptance, not always accepted count | Show candidate and accepted counts |
| Collision radius | Controls spacing envelope, may reduce population | Show footprint gizmo and rejects |
| Height-only scale falloff | Shrinks vertical plant dimension, not footprint | Before/after preview |
| Map-as-value | Samples exact transform value | Value gradient preview |
| Map-as-probability | Changes magnitude of randomness | Variance overlay preview |
| Randomize Stacked | Different variation per vertically stacked region | Receiver-ID preview |
| Link to Surface | Attach manual items to receiver | Surface binding badge |
| Preview max items | Display sampling only | Displayed vs final counts |

## 8. Build/update status

Expose statuses: `Up to date`, `Evaluating`, `Preview stale`, `Manual update required`, `Missing source`, `Renderer capability fallback`, `Partially built`, `Error`. Never show the old buffer as if it were a freshly accepted output after a failed job. Progressive updates are fine if labeled draft.

## 9. Diagnostics panel

```text
Scatter: Garden_Grass
Generator candidates:             1,480,000
Area-rejected:                      220,000
Source-empty:                        40,000
Collision-rejected:                 160,000
Accepted:                         1,060,000
Viewport shown:                     120,000
Cache reuse: 92% tiles (example)
Rebuild: Surface 0ms | Fields 12ms | Gen 52ms | Collision 71ms | Upload 8ms
```

Numbers above are **illustrative**, not measurements. Add source histogram, overlap warnings, dirty-tile view, stalled build reason, memory budget and one-click "Compare full rebuild" for developer mode.

## 10. Preset UX

Make scope explicit before saving/loading:

- **Settings:** numeric/curve settings, no scene references.
- **Recipe:** source references/asset descriptors and scatter behavior.
- **Scene Setup:** recipe plus references to actual scene nodes, possibly requiring relink.

Preset loads should preview what will be replaced and create one Undo transaction. Missing assets must remain visibly unresolved, not silently replaced.

## 11. UI performance

Update totals and thumbnails on relevant changes, not every timer tick. Virtualize very large source/region lists. Never synchronously invoke a full scatter regeneration directly from every spinner drag; use throttled draft updates and authoritative commit on release. Keep original Max user interactions (selection, hotkeys, navigation, other plugins) intact.

## 12. Interaction acceptance tests

- Artist can learn basic grass scattering without visiting engineering diagnostics.
- Artist can explain why more density didn't create more plants using reported collision statistics.
- Reordering Areas shows expected result and is undoable.
- Paint cursor remains responsive during heavy builds and can cancel safely.
- Changing distribution modes retains inactive settings without cross-mode corruption.
- User understands when a control affects final render vs viewport only.
- All disabled/warning states cite a specific constraint or source, not generic "not available".
- Every editable control supports consistent copy/paste, reset and Undo if appropriate.
