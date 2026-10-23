# 0.86.9.1 — density controls and Edit feedback

Scope authorized 23 October 2026: procedural map thumbnails, an empty native
map drop target, first-column resizing, and the previously reproduced slow Edit
gesture feedback. Patch version selected by the user; schema 59, recipe 8,
Edit storage/capability 2 and independently versioned Analyzer 0.14.2 remain.

- **Density UI:** the layer owns the texture graph. The visible Map choice is
  a native mapbutton even when empty. Texture maps are valid inputs; an entire
  material has no unambiguous density channel. A transient, one-entry 72×72
  thumbnail per mounted Amount page uses map identity, dependency revision and
  validity interval. Bitmap previews borrow the source image. Procedural images
  are closed on replacement/close; failures clear the preview without changing
  the graph, pending Manual edits or committed placements. No scene persistence
  or Undo payload is added for thumbnails.
- **Panel geometry:** layout uses actual available HWND widths, and explicitly
  resizes the main rollout controls. Measured Max 2027 native bodies were 201
  units wide while their centered dialogs remained 162 units. Extend the
  existing owned page subclass to fit dialog content on native geometry
  messages, including nested bodies; detach on close/destruction. Preserve native rollout categories/order
  and lazy mounting. Presentation actions do not evaluate placements.
- **Edit:** native selected-handle feedback derives current authored deltas
  through the already proven committed local input/downstream suffix. During
  dragging, display, hit testing and gizmo centers use that same matrix.
  Move unlocks Max's axis-tripod display so the gizmo follows this center;
  rotation and scale retain their original locked gesture pivot. Full
  placements remain published on release. Preview state is transient, cleared
  by unrelated authoring, Cancel/Undo/Redo and full display staging/publication
  of that authored revision; re-presenting an older retained bundle cannot
  clear a newer gesture. CPU rollback also clears preview state.
  A coalesced, modifier-identified UI message refreshes Max's cached axes after
  renderer commit/rollback, outside the render callback. It emits selection-only
  invalidation, preserves authored revisions and is discarded with its panel.
  The preview owns no extra population-sized matrix array. Existing stale-feedback guards
  and atomic authored block updates remain. Original Paint is unchanged.
- **Evidence/delivery:** build distinct SDK payloads for Max 2024, 2026 and 2027.
  Run native and focused owned-host tests only for 2027. Older payloads are
  explicitly build-only, untested. Include Analyzer in one EXE and produce the
  exact Max 2027 MZP; do not install into or restart artist sessions.

Acceptance: map pick/drop/Clear and Undo, bounded thumbnail reuse/invalidation,
single/multiple-column fit without placement changes, live selected-handle
movement with matching release, Undo/Redo/Cancel and saved scene preservation.
Retain the density-generation binding guard and the documented copied Edit
stack limitation. Record any incomplete acceptance in the delivery report.
