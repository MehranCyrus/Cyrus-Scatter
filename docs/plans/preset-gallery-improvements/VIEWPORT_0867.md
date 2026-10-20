# 0.86.7 — active thumbnail, textured viewport and compatibility delivery

User-authorized 20 October 2026: fix B33, implement B34, use version 0.86.7,
and deliver matched installers for Max 2024, 2026 and 2027. Reuse the prepared
individual plant content, textures and thumbnails; do not rebuild the library.
This explicitly extends the normal Max 2027 development scope for this delivery.

Baseline: working tree beyond `3ec1cbc2b725912e39c2625ceecb648970054050`,
including the delivered 0.86.6.2 individual library. Preserve unrelated changes
and the artist's profiles and running session. Historical receipts keep their
original identities. No Git publication or artist installation is requested.

## Contract and implementation boundary

- B33: wheel scrolling must schedule newly visible thumbnails after the initial
  queue becomes idle. Preserve two concurrent file-only workers, generation
  cancellation, bounded cache, UI-thread publication and disposal. Test the
  actual managed control and hosted Max window, including scrollbars, wheel,
  resize, search/category changes and close during work.
- B34: add an explicit Materials / Textures choice without renumbering existing
  identification values. Root-owned display settings remain independent of
  placements and pending Manual settings (F04/F08). Source material/UV changes
  invalidate appearance independently of static placement buffers.
- Copy all Max scene/material data on the host thread. Drawing consumes retained,
  immutable native data and supported SDK graphics resources (F07). Keep geometry
  instanced; account for CPU/GPU images, UVs, staging overlap and Undo lifetime.
  Use finite texture dimensions/counts and existing resource admission (F06).
  Stage a complete successor before publishing; failure retains the previous
  complete display (F05). Source materials and renderer output remain unchanged.
- Initially qualify base color, source UV channels, material IDs, cutout opacity
  and two-sided leaves using the supplied Corona/standard/Multi-Sub paths.
  Document unsupported map/material fallbacks and do not imply renderer fidelity.
- Installer: matched SDK/native/managed payload per host, one reusable content
  distribution, verified paths/hashes, repair/rollback and preservation of
  personal recipes. Investigate the saved MAX format before declaring older-host
  compatibility. Reuse maps/previews; any necessary save-back must preserve plant
  geometry/materials rather than generate new assets.

## Acceptance and evidence

The implementation and focused qualification are recorded in
[DELIVERY_0867.md](DELIVERY_0867.md). Exact loaded/package identities and remaining
renderer limitations belong to that report. The qualification matrix covers
the alpha leaf, Multi/Sub mapping, material/UV edits, representation switching,
Manual pending edits, warm navigation reuse and failure recovery. Repeat the
relevant host and installer checks in all three explicitly requested Max years.
