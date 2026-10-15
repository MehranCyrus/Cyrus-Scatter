# Behavioral reference test — TEMPLATE

**Test ID:** `FP-[SYSTEM]-[NNN]`

**Research question:**

**ForestPack version/build:**

**3ds Max version/build:**

**Renderer/version (if relevant):**

**Evidence:** official documentation URL; recorded UI observations; controlled measurements; unsupported/unknown.

## Minimal scene

- Units and coordinates:
- Receiver geometry and transform:
- Source geometry pivot/bounds/material:
- Generator distribution, map, seed:
- Area stack bottom-to-top:
- Selected mode and all enabled/disabled controls:
- Camera/time/viewport settings:

## Change sequence

| Step | Action | Expected observable | Actual ForestPack | Actual Cyrus |
|---:|---|---|---|---|
| 1 | Open/reset minimal scene | | | |
| 2 | Change exactly one parameter | | | |
| 3 | Undo/Redo, save/reopen | | | |

## Measurements

- Before/after accepted count:
- Generated / rejected candidate counts (if available):
- Instance IDs, position/rotation/scale distributions:
- Errors at boundary / UV seam / tile seam:
- Rendered appearance and missing geometry:
- Build time and peak memory (method stated):
- Output files, screenshots and SHA-256 hashes:

## Interpretation

- Directly established behavior:
- Likely but unproven mechanism:
- Outstanding alternatives:
- Confidence and compatible product versions:
- Decision for Cyrus:
- Regression test to add:
