# 0.86.8.2 — clearance fields and visible Relax controls

Delivered for continued user testing with matched Max 2024/2026/2027 packages.
Baseline:
`81e7a40a290cb7a3826739494302b7812644939f` / 0.86.8.1.

## Corrections

The expanded source **Clearance distance** fields were created with a literal
180-pixel width and no explicit native edit-field width. In an owned Max 2027
baseline, the edit field extended left of its page and covered the captions.
The shared generator now normalizes literal widths and gives every composed
spinner an explicit bounded edit width. Existing fields, handlers and identities
are retained.

**Point Relax** and **Boundary Relax** are now directly visible in **Spacing &
cleanup**, above Advanced. Enabling each reveals its own settings. Both remain
layer-owned; source radius and clearance remain source-owned. The shared
**Relax distance** stays editable when either mode is enabled. Previously,
Boundary Relax used this value while its UI disabled it unless Point Relax was
also enabled. Its tooltip explains the two uses: desired candidate separation
for Point Relax, neighbor search radius for Boundary Relax.

No native calculation change was required by the reproduced witnesses. Native
Point Relax and bounded Boundary Relax precede source-clearance filtering.
Showing/hiding controls does not alter settings or evaluate placements.
Advanced retains selected-instance radius overrides and accepted cleanup.

## Identity and compatibility

Patch 0.86.8.2 corrects existing controls and preserves schema 59, recipe 8,
publication bridge 4, native placement 2 and content revision 0.86.7. It retains
the user's explicitly requested Max 2024/2026/2027 compatibility. Analyzer,
MCP and Licensing keep independent versions. The engineering scope is recorded
in [the correction plan](CORRECTION_08682.md).

Product sources: authoritative layout generator/rows, unified template, generated
script/metadata and version identities. Reproducible owned-host and packaging
drivers are under `tools/clearance_relax_08682/`. Ignored evidence is under
`build/clearance-relax-08682-20261021/` and the matching
`build/mcp-qualification/clearance-relax-08682-*/` profiles.

## Final acceptance

- **49 native tests per SDK build**, including existing Point Relax, final
  movement, source-clearance and procedural suites; **176 Python tests**.
- Generated script/layout checks pass. The release receipt verifies 479 source
  hashes per build plus authoritative generator and qualification-driver hashes.
- Owned Max **2024, 2026 and 2027** sessions pass: actual Relax checkbox handlers,
  direct visibility with Advanced off, Boundary-only distance availability,
  candidate-count preservation, reduced close-pair energy, receiver projection,
  deterministic recalculation, disable/restore, bounded final movement,
  post-Relax within-layer and cross-layer pair distances, independent layer
  settings, Undo/Redo, save/reopen and Manual/Live publication. Binding and
  expanding Advanced do not rebuild candidate data or publications.
- Max 2027 mouse/keyboard input changes source factor to 1.5, gap to 3 cm, metric
  to XY and layer Relax distance to 30 cm. Model readback and an exhaustive
  accepted-pair witness confirm the resulting 39 cm rule for pairs involving
  that source. This is a bounded fixture, not a universal collision guarantee.
- Actual narrow Modify-panel fields (187 logical page width) and a separate
  generated-page host sized to 320 pixels have non-overlapping field/caption
  bounds. The narrow UI was visually inspected at 100% UI scale; other DPI
  settings were not interactively qualified. The wider probe resizes the actual
  child HWND because the `#cmdPanel` rollout declaration otherwise retains its
  default width. It does not claim a wider artist Modify-panel preference test.
- MZP CRCs, every manifest payload hash, version/host guards, loaded script/native/
  Gallery hashes and all three EXE-embedded MZPs match. The 2024/2026 sessions
  load copies from freshly installed disposable runtimes; 2027 loads the matched
  build and its installed copy is byte-verified. Installer tests cover absent
  optional content, checked missing ZIP failure, existing shared-library reuse,
  exact version installation and repeat updates with zero new content bytes.
- All three artist profile templates retain their launch-time hashes. Only owned
  test processes were closed after qualification.

Machine-readable receipt:
`build/clearance-relax-08682-20261021/final-receipt.json`.
Host logs are named `bounds.txt`, `calculations.txt`, `lifecycle.txt`, plus
Max 2027 `numeric.txt` and `wide.txt`. The inspected screenshot is
`build/clearance-relax-08682-20261021/max2027-clearance-relax.jpg`.

The initial calculation fixture incorrectly required a reduction below 200
candidates with radius 5 despite Point Relax already separating them. This was
a test assumption, not a reproduced solver failure. A radius-12 witness tests
actual conflicts and checks every accepted pair against the summed-radius rule.
Early generator checks also caught a stale generated feature-catalog version;
regeneration corrected the metadata before final qualification. Initial
concurrent build receipts were rejected after restoring repository LF line
endings; all three frozen builds and tests were then rerun successfully. A
caption-bound fixture was corrected to allow a label above its field, and the
wide-host fixture was corrected to resize the real child window. These early
driver failures are not promoted to product failures or final acceptance.

## Packages and installation

Final output: `dist/CyrusScatter-0.86.8.2-20261021/`.

- `CyrusScatter-0.86.8.2-Setup.exe`: matched 2024/2026/2027 payloads.
- `CyrusScatter-0.86.8.2-Max2024.mzp`, `Max2026.mzp`, `Max2027.mzp`.
- `CyrusScatter-Content-0.86.7.zip`: unchanged content, linked to the existing
  archive allocation on this workstation rather than duplicated.

Close the Max versions being updated, run the EXE, select their cards and click
Install/Update. Existing content can be reused with the plant-library option
unchecked. For a fresh content installation, keep the ZIP beside the EXE and
check **Install / update plant library**. Alternatively, use **Scripting > Run
Script** with the MZP matching the host year, then restart that Max version.

No artist profile installation or session restart is part of qualification.
The installer remains unsigned. Private content, scenes and binary packages are
ignored artifacts and are not included in the Git backup.

## Limits

Focused UI, procedural Relax and pivot-clearance checks do not establish exact
mesh collision, rigid-body physics, universal scene acceptance or performance
improvements. Boundary Relax is bounded neighborhood smoothing, not a new physics
solver. The previous real-leaf/material performance and renderer coverage retain
their original [0.86.8.1 scope](DELIVERY_08681.md); this patch does not requalify
every renderer or the entire library. Tests use owned profiles and scenes.
