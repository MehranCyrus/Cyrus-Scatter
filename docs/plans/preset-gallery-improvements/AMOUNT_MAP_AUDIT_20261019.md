# Amount map investigation — 19 October 2026

Status: current investigation and candidate correction, not a new delivery or a
replacement for the immutable 0.86.2 qualification. Scope: Amount map/image
clearing, pattern/channel switching and receiver-aware procedural maps. The
broader library portability audit remains pending.

## Baseline and reproduction

Source baseline: `ce062502ecda3af57b25e8821c9e5a7744d3501d` on
`codex/workflow-0.75`, with existing installer/documentation and untracked work
preserved. Owned Max 2027 profile:
`build/mcp-qualification/density0862-map-audit-20261019-01/`. Its `launch.json`
records matched script/native hashes and `loaded.tsv` records loaded module
paths. The native pair came from the qualified `pair03` receipt. No artist
session, installed package or other product's host was changed.

`audit-baseline.txt` records 19 cases with 1,000 requested placements, a two-face
plane, generated Amount picker/check/spinner handlers and the same authored
setters used by dropdown handlers. This is scripted host evidence, not physical
mouse interaction qualification.

- All three installed patterns evaluate. Checker using receiver UV1 produces 521
  placements. Constant UV7 produces 1,000; returning to UV1 restores the exact
  publication fingerprint.
- Numeric channel 2 R/G, white channel 3 and black channel 0 produce the
  corresponding combined density. Missing channel 8 fails with prior output
  retained; disabling it restores the exact Checker result.
- Clear sets `densityMap=undefined` but leaves `distributionMode=3`. Update
  fails with `Choose a density texture map` and retains the old result.
- Vertex Color reading channel 3, white at every receiver vertex, produces a
  varying field (approximately 0.0206–0.9072) and 476 placements instead of 1,000.
  Color Correction followed by two Output maps preserves that wrong result.
  The current `renderMap` tile bake has no receiver binding.
- `force-map-context.txt` explicitly invalidates and rebakes each map. Changing
  receiver channel 3 from entirely white to entirely black still produces the
  same 476 placements and fingerprint. Changing Checker's own map channel from
  1 to constant channel 7 likewise leaves its 521-placement fingerprint unchanged.
  Increasing bake counters establish that this is not just reuse of a stale tile.

## Clear correction contract

Explicit picker Clear removes the map and disables image density in one Undo
record, clearing pattern/provenance metadata. It preserves the independent mesh
mask and other authored settings. Merely disabling image density retains the
assigned map for re-enabling.

Owner: captured Amount layer. Dependencies: existing image-change path invalidates
the affected layer and field preview. Manual keeps its publication until Update;
Live uses the existing scheduler. Clear publishes the remaining enabled rules;
actual invalid dependencies retain the preceding complete publication. Undo/Redo
restores map reference and enable state together. No new per-placement storage,
peak-memory growth or history copies. Contracts: F01, F04, F05, F08 and F11.

The correction is in the authoritative `unified-core.ms` template and generated
script. The native implementation is unchanged. Candidate script SHA-256:
`9b0910141e763b9153abdf2f8a6b58c43ec542cd4a9d47882c198637e2b90320`.
`build/amount-map-audit-20261019-01/pair/receipt.json` verifies every native source
and binary against the previous immutable native build and pins this script-only
pair. `candidate-stage.json` and `candidate-fingerprint.txt` prove the script
loaded in the owned host. This remains an undelivered source candidate; no version
bump, installer replacement or artist installation was performed.

## Candidate verification

The maintained driver is `tools/density_map_audit/run.py`; the Max fixture is
`tools/density_map_audit/regression.ms`. The isolated host's `regression-*.txt`
records Manual pending behavior and explicit Update, Clear Undo/Redo, exact
combined image/mesh restoration, all three patterns and their Clear metadata,
channels 0/2/3/7, missing channel 8 and recovery, explicit UV1/UV7, disable versus
Clear, Live callback publication, visible combined-mask refresh, quiet idle and
scene save/reopen. The actual Clear handler is exercised. Dropdown tests invoke
their authored setter, and this is not physical picker/menu qualification.

Generated integration and approved-layout checks pass. No native rebuild or
repeated unrelated SDK tests are claimed for the script-only correction. The
pending receiver-aware graph feature is intentionally not counted as passing.

The final focused campaign passes **42 assertions** across 19 distinct phase
logs on **Max 2027, 29.1.0.11426**. A separate nested-map Live check starts with
black Checker -> Color Correction -> Output -> Output and changes the deepest
Checker to white: placements update from 0 to 1,000 and bakes from 1 to 2 without
explicit Update. Thus that tested nested-change path works; it does not repair
receiver-dependent sampling. `build/amount-map-audit-20261019-01/result.json`
pins the tested source, driver and evidence file hashes.

## Receiver-aware map support remains open

Vertex Color and multi-channel graphs require native evaluation with the selected
receiver's face/barycentric location, evaluated channels, positions, normals,
transforms and time. Validate map-tree requirements explicitly; a successful
standalone tile render does not establish support. Host SDK evaluation stays on
the host thread, and placement/preview must share scalar meaning and invalidation.
Keep projected patterns distinct from a map graph's own coordinates. Never
silently flatten receiver-bound data into a purportedly portable map-only tile.

Autodesk's Max 2027 [Texmap](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_texmap.html)
and [ShadeContext](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_shade_context.html)
interfaces describe contextual map evaluation; the host witnesses above establish
the current Cyrus failure independently.

Exit evidence: multiple receivers/channels, nested edits/animation, channel
deletion/recovery, Manual/Live, preview agreement, bounded work, Undo/Redo and
save/reopen. This audit does not qualify general renderer maps or the full library
edge-case matrix.
