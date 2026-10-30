# Interaction review repairs — 0.87.6.3

User-authorized Max 2027 correction and performance pass, 29 October 2026.
Deliver the matched script/native MZP for artist testing. No EXE, older-host
build, installation, Git push or website work is part of this pass.

## Behavior and ownership

Preserve the 0.87.5.6 artistic Bend/Trim response and the 0.87.6.2 selection
workflow. F04–F10 apply: Manual pending placements remain pending, numeric work
uses immutable data, publication is atomic, host access stays on the Max thread,
and physical hide distances retain their units. No scene or recipe schema change
is planned. The user selected patch 0.87.6.3 for these repairs.

Inactive neighbor preferences remain authored, but only a reacting, prepared
source participates. Old/new edited bounds determine affected plants. Temporary
indexes contain at most the admitted edited rows; no per-changed-row map copies.
Hiding candidate selection is independent of the chosen deformation algorithm.

Fixed components share a visibility policy across point and mesh output. Render
bounds include fixed geometry plus the conservative guide deformation envelope.

Individual transform feedback should pin the immutable placement base and store
only sorted changed records. Selection flattens to that same base; no overlay
chains. Transform changes invalidate preparation receipts, preserve stable IDs,
source/receiver correspondence and old views, and receive distinct view tokens.
Payload metrics include overlays and simultaneous old/new generations. Undo
continues to own authored Edit history; this transient feedback is not serialized.

Viewport pose admission must cover the geometry actually eligible for idle and
navigation display. Draw-limit edits must not apply pending Manual placement
changes or require full source recapture. Count/reserve packed poses after the
admitted subset is known, retain offscreen solver state for restoration/render,
and preserve the last complete display if allocation or preparation fails.
The exact integration will follow the current display planner, not a second
independent quota system. Peak payload includes old/new pose buffers and scratch;
reported payload is not a process-RSS or VRAM guarantee.

## Completed scope and acceptance

See [delivery](DELIVERY.md) and [qualification](QUALIFICATION.json) for the exact
executed cases and evidence. Checked items below are scoped to those cases;
the broader design requirements above are not claims of exhaustive testing.

- [x] R1: consistent effective-neighbor policy; React/Off/Collider transitions,
  retained edits, disabled rows, distinct sources and ordinary recovery.
- [x] R2: Hide margin and Hide underneath with all response modes; overhead,
  distance boundary, transforms and restoration.
- [x] R3: borrow overrides and index edited reactors; deterministic parity and
  allocation/work comparison against the retained review probe.
- [x] R5/R6: fixed-component point/mesh parity and render-bound containment.
- [x] R7: sparse placement feedback with selection/compaction, stable identities,
  immutable predecessors, bounded memory and invalid-input checks.
- [x] R4: draw-aware pose admission, idle/navigation budget changes, retained cache
  invalidation and posed picking. Resource-failure injection remains unqualified.
- [x] Native regression suite and focused allocation/geometry probes.
- [x] Owned Max 2027 exact-payload checks: role transitions, hiding, budget changes,
  Edit/collider movement, Manual pending edits, Live held-input presentation,
  Undo/Redo/reload, navigation counters and representative foliage selection.
  Native visibility/parity checks do not establish a visual matrix of every mode.
- [x] Review the final diff, update maintained documentation with measured scope,
  and verify the matching Max 2027 MZP hashes and guards.

Static scaling concerns beyond the reproduced defects remain measured candidates,
not permission for a solver rewrite, GPU compute subsystem or broader feature work.
CPU timings, upload counters and actually presented updates are separate evidence.
