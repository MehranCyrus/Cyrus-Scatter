# CyrusScatter 0.87.5.2 — contact work audit and performance

This patch reduces redundant exact contact work and reuses identical stem/leaf
frame calculations. Existing collider shapes, preparation settings and visible
triangle validation remain. The complete 0.87.5.1 Library/Scene preset work is
preserved. [Audit and measured limits](AUDIT.md), [implementation plan](PLAN.md),
[artist guide](ARTIST_GUIDE.md), [exact qualification](QUALIFICATION_08752.json).

## Install

[Max 2027 MZP](../../../dist/CyrusScatter-0.87.5.2-20261027/CyrusScatter-0.87.5.2-Max2027.mzp).
Use **Scripting > Run Script**, then **restart Max**. Install the complete matched
package. No reanalysis is required solely for this update; derived source caches
rebuild when loaded. An owned saved test copy is recorded in the qualification.
The installer was exercised only in a disposable profile, not the artist's setup.

## Result and evidence

- Controlled alternating 1,000-plant numeric replay: **100.31 → 78.76 ms** median,
  **21.48% lower**, with identical pose digests and quality warnings.
- Final Max 2027 native Edit callbacks: **37.38 ms / 200 plants**, **111.84 ms /
  1,000 plants**. Timings are CPU command costs, not presented FPS.
- Warm passive actions reuse preparation, placements, contacts and buffers.
  Physical dragging produces three successors with zero geometry uploads.
- **61/61 native executables pass**, with **625 frozen source files** verified.
  Generated-source and focused catalog checks pass. Natural grass, fern and
  authored fixed-base complete mesh checks, Bake, hiding, Undo/Redo, failure
  retention/recovery, Manual pending edits, save/reopen and Scene preset merge
  pass on the exact installed pair. Hardware HLSL math check: 2,412,954 corners,
  zero visibility mismatches.

The deep stress case still exceeds the existing stem-edge strain limit, despite
clearing the collider and preserving root anchors. It remains an explicit quality
limitation, with an absolute-error diagnostic in the audit. This patch does not
claim all remaining code/work is necessary or every plant is physically correct.

## Identity and scope

Scatter/managed **0.87.5.2**; native Interactions **12**; saved schema **63**;
portable recipe **9**; native Scene preset metadata **1**; Edit/storage **3**.
Independent products retain their versions. **Max 2027 only**.

MZP SHA-256:
`4130029213d015297a4df6fcd15b3662b0152925e77a0ce4a118e4a0450d4f2d`.
Script SHA-256:
`3ffd2262ad3b29becbb8b2f2117590fb19e30b122ecafaccb515bb262e92cbf8`.
AminScatter.dlx SHA-256:
`c2b8a71735b92afe2d85c1f58051c9f4ad94782e5ae093042dc317d8f2ff52b6`.

Evidence root: `build/interactions08752-20261027-01/`. Final producer:
`native-final/`; package/installer: `payload-final/`, `installer-final/`; loaded
host: `host-final/`; numeric parity: `final-natural/`, `paired-final/`; hardware
delivery: `gpu-final/`. Development attempts and previous deliveries retain their
own identities. Repository knowledge retrieval was stale (40/64 enrolled parents
fresh at startup); current source was inspected directly. No corpus refresh,
older-host build, EXE, Git push or website publication is included.
