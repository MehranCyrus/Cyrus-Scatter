# Clearance controls and Relax — 21 October 2026

Active correction to 0.86.8.1, requested after the artist observed clipped
Clearance distance fields and could not find Relax. Baseline is commit
81e7a40a290cb7a3826739494302b7812644939f. The independent review remains historical
evidence; it did not exercise these expanded controls at narrow widths.

## Scope and contracts

Use patch **0.86.8.2** for correction of existing UI and behavior, retaining
schema 59, recipe 8, publication 4 and content 0.86.7. Preserve the requested
Max 2024/2026/2027 distribution; develop and reproduce first in Max 2027.
F03/F04/F05/F08/F11 govern scope ownership, relevant updates, publication,
shared views and persistence. The knowledge index reports stale evidence;
current sources and original reports are inspected directly.

- Normalize native spinner field sizing in the generator, including controls
  with literal widths and no explicit fieldWidth. Verify actual HWND bounds,
  caption separation and readable values at narrow and wide panel widths.
- Expose Point Relax and Boundary Relax in the main Spacing & cleanup page,
  before Advanced instance overrides/cleanup. Show their settings when enabled.
- Preserve per-source clearance ownership and layer-owned Relax. UI visibility
  changes must not calculate or modify authored settings. Existing authored
  setters, Undo, Manual/Live invalidation and atomic native publication remain.
- Exercise actual generated handlers, owner switching, Undo/Redo and save/reopen.
  Check Relax moves eligible candidates and that subsequent own/cross-layer
  clearance meets pair distances. Investigate any failed calculation witness
  before modifying the native algorithm.

No new persistent fields or bulk caches are planned. Presentation state is
view-owned; bounded UI geometry work uses existing control lifetimes. Candidate
and publication memory/admission stay native-owned. Failures retain the previous
complete result. Original assets, artist profiles and unrelated work are preserved.

## Acceptance

1. Baseline host reproduces the reported field defect and documents Relax's
   current discovery path.
2. Expanded fields remain contained and non-overlapping across supported narrow
   and wide widths; values remain readable after rebinding and changing owners.
3. Relax is directly discoverable; enable/disable and numeric edits affect only
   the selected layer, with correct Manual/Live behavior.
4. Native and host witnesses cover Relax alone, clearance alone, combined rules,
   XY/3D distances, hierarchy, Undo/Redo and persistence.
5. Generated/layout checks and relevant suites pass. Matching installers are
   verified and tested in disposable profiles. Reuse unchanged shared content.

Completed within the [0.86.8.2 delivery scope](DELIVERY_08682.md). That report and
its machine-readable receipt own qualification and limitations; this plan alone
does not establish acceptance.
