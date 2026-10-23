# Scatter 0.86.9.2 — Modify-panel crash correction

23 October 2026. Focused Max 2027 acceptance passed for the exact packaged bytes.
**0.86.9.1 acceptance is withdrawn.** Its original [report](DELIVERY_08691.md)
and receipts remain historical. This correction supersedes its column-fit claim.

## What failed and what changed

The artist's installed 0.86.9.1 script/native hashes matched the distributed pair.
The artist dump and an owned reproduction both show a null read at
`Qt6Widgets!QBoxLayout::setGeometry+0x460` during native rollup layout.
The reported trigger includes widening Modify to approximately six columns and
selecting another Scatter controller. Initial scripted checks could return PASS
before later queued native layout crashed the host.

The 0.86.9.1 sizing integration was too invasive: it intercepted window placement,
forced nested dialog geometry during hook attachment, bound the root and took
over root resize. 0.86.9.2 restores the complete pre-0.86.9.1 native sizing path
in `rollout_scroll.cpp`, the root template and the lazy-page width expression.
Max owns column geometry and root auto layout again; scroll/focus hooks retain
their earlier child-only lifetime protocol. This is a bounded integration rollback,
not a claim that the dump identifies one uniquely proven faulty source line.

A diagnostic that disabled only the binding calls later failed in Qt focus code.
It also accidentally stripped the script BOM, so it is excluded from acceptance.
Historical 0.86.9 survived the focused comparison but is not current qualification.
All diagnostics and failure records remain under the evidence root below.

**Remaining cosmetic limit:** small Max-controlled column insets may remain.
Removing all native padding is deferred. No replacement width hook is introduced.

The procedural TextureMap thumbnail/cache, native empty Map targets and Edit live
matrix/post-commit axis-refresh changes remain. Full mesh presentation still commits
on release. Original Paint, clearance calculation, edits, Undo, schema 59, recipe 8,
native Edit 2 and independent Analyzer 0.14.2/content 0.86.7 are preserved.

## Focused evidence

Evidence root: `build/crash-08691-20261023-01/`.
The [qualification manifest](QUALIFICATION_08692.json) binds producer inputs,
request/results, loaded files, package manifests and hashes. The
[implementation contract](IMPLEMENTATION_08692.md) records scope and failure rules.

- Max 2027 native Scatter: **56/56 tests passed**. The unchanged exact-byte
  Analyzer producer retains its one native suite; its current host bridge passes.
- **37 focused Python tests passed**. Generation checks cover **333 controls**
  and **32 delimiter fixtures**. Documentation/catalog checks are separate below.
- Corrected owned host PID 38800: three single-column A/B cycles (six switches),
  ten wide-panel A/B cycles (20 switches), and two rapid batches of ten switches
  while lazy mounting can still be pending. Geometry confirms at least six native
  columns. Each mutation returns before independent driver idle/probe requests;
  checks include process survival, correct owner/empty queue and both complete
  publication fingerprints, IDs/radii and pending Manual values.
- Undo/Redo after browsing; two independent procedural-map owners; save/reopen;
  warm post-reopen switches; fresh empty owner after populated pages all pass.
  Cold reconstruction may advance epoch/build 0→1 while preserving authored
  count/seed/layer identity. The fixture freezes its warm baseline after settling.
- Retained functional checks: density preview/revision/cache/Clear/Undo/Manual
  (seven), prior 0.86.9 edited scene and radii (two), Analyzer bridge (one),
  native Edit Move/Undo/Redo/Cancel/edited-scene roundtrip (five).
- Physical Compact Editor Checker drop onto an initially empty native Map button,
  choosing Instance: assignment, preview and Manual preservation pass (two).
- Physical Scatter creation (one object per viewport click) followed by Modify:
  correct new owner and existing publications preserved (three).
- **No corrected-candidate crash observed.** Owned test host closed cleanly.
  This is focused regression evidence, not broad renderer/DPI/production/soak
  certification. Repeated checks and setup probes are not additional feature coverage.

The manifest selects 19 request witnesses / 41 assertions from the campaign;
that count includes sequencing/state checks and must not be read as 41 distinct
features. Fixture corrections and excluded diagnostics are explicitly recorded.

## Packages and installation

One [Windows EXE](../../../dist/CyrusScatter-0.86.9.2-20261023/CyrusScatter-0.86.9.2-Setup.exe)
contains distinct matched SDK builds for **Max 2024, 2026 and 2027**, including
**Surface Analyzer 0.14.2**. **Only Max 2027 was runtime-tested. Max 2024/2026 are
build-only and untested**; those hosts and their native tests were not launched.
The installer core is reused unchanged. This pass verifies source/build admission,
all six MZP CRCs/duplicates/member hashes/version-host guards, and matching loaded
2027 bytes; it does not claim a new interactive installer campaign.

EXE: 6,440,960 bytes; SHA-256
`d93c1dcd1353d0c1794aa2d5fae6706066c88b1df8a6a48b0a20fc22a3c9b50c`.
Save and close the selected Max versions, run **Install / Update**, then reopen.
No artist profile was installed or restarted by this work. Existing library content
is reused; the optional content ZIP remains separate.

Alternative: run the exact [Max 2027 Scatter MZP](../../../dist/CyrusScatter-0.86.9.2-20261023/CyrusScatter-0.86.9.2-Max2027.mzp)
and [Analyzer MZP](../../../dist/CyrusScatter-0.86.9.2-20261023/CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp)
through **Scripting > Run Script**, then restart Max. Separate MZPs are unnecessary
when using the combined EXE. [Installation details](../../Max_2027_Installation.md).

## Unchanged limits and workspace

Map targets accept TextureMaps rather than complete materials. Generic previews
are not receiver/camera/renderer-accurate; use Show mask. B37 clone-dependent full
Edit-stack Copy/radius remapping remains open. Generation/receiver guards stay
active. Save upgraded Edit scenes as new copies for older-reader safety.

Branch baseline: `codex/workflow-0.75`, HEAD
`dde07870d4c005cb27987c4c46f7f9065cb1e891` plus scoped uncommitted changes.
Unrelated Arrange/Physics/library/private-asset changes were preserved. No commit,
push, artist install, website build/publication or knowledge-index activation was
performed. Maintained guidance and knowledge routing reflect this correction;
the selected retrieval index remains stale and requires direct-source fallback.
