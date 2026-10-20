# 0.86.8.1 correction and viewport performance

20 October 2026. Implemented and qualified within the [0.86.8.1 delivery scope](DELIVERY_08681.md). Baseline is
`be5c8ec89c68df0473494581d57c19ff66917bd2`; the independent review remains
unchanged. Initial development used Max 2027; the user explicitly extended this
delivery to matched Max 2024 and 2026 builds and host tests. No artist installation,
session restart, content regeneration or website work is included.

## Acceptance

- Reproduce and fix F1 displaced blocker rejection, with two and sixteen rounds.
- Reproduce and fix F2 absent-source preference, including zero-weight host
  models, protected-only sources and eligible refill suffixes.
- Compile runtime rules from participating sources once per solve; measure empty
  and sparse high-source cases separately from placement work.
- Extend stateful native tests for admission, blocker release, cleanup, quotas,
  reason validity, limits and deterministic output.
- Profile the actual A006/A007 two-leaf, Count 200 radius workflow across Point,
  Proxy, Mesh and Textured mesh. Separate setter, solve/preparation, appearance,
  upload and redraw costs. Record cold and warm measurements, not presented FPS.
- Verify the third leaf's source geometry/opacity. Preserve supported opacity
  cutouts in colored Mesh while keeping source/layer identification colors.
- Exercise relevant and irrelevant changes: radius, priority, Count, material
  color/correction, opacity, UV, geometry, selection, display mode, animation,
  Manual/Live, Undo and save/reopen.
- Rebuild and verify the exact matching EXE/MZP. Reuse the existing content ZIP.

## Ownership and invalidation

Layer populations and source-row policies retain their schema and ownership.
Count admission still precedes preference. Protected rows retain precedence.
Previous occupancy may guide bounded refill but cannot remain authoritative
after its blocker disappears. Failure retains the previous complete publication.

Native rule compilation consumes copied metadata and eligible sample source
ordinals, including protected and authorized refill rows. Compilation is scoped
to the solve; no global unbounded policy cache or live scene pointers are added.
Source validation still covers authored metadata, including inactive entries.

Appearance owns immutable source UV/texture data independently of accepted
instance transforms. Source/material/UV/color-management changes invalidate
their relevant data. Radius/count/spacing changes must not rebake an unchanged
source material. Geometry correspondence and Manual pending-edit guards remain.
GPU resources are retained only while their immutable inputs match, with shared
ownership and existing memory admission. Host API access stays on the host
thread; Draw consumes prepared snapshots only. Undo invalidates via the same
dependency revisions; scene reset and source deletion release owned resources.

The change is a corrective patch, **0.86.8.1**, explicitly requested by the user.
No saved-scene or recipe fields changed. The delivery report records completed
checks, exact installer identities, measured performance and remaining limits.
The same-scene Textured mesh median changed from 921.322 ms to 186.688 ms
across five radius edits. Native metadata compilation for ten empty populations
of 512 authored sources took 1.5169 ms in the final run. These are scoped
measurements, not a general performance or renderer guarantee.
