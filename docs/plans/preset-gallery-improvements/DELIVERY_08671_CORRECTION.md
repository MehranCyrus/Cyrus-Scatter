# Corrected 0.86.7.1 — visible lists, library feedback and automatic installation

20 October 2026. User-authorized correction within **0.86.7.1**.
Schema 58, CyrusUnified1 and the four native modules remain unchanged.
The [first 0.86.7.1 delivery](DELIVERY_08671.md) retains its original
artifacts, hashes, measurements and known acceptance limits.

## Artist-visible corrections

- Layers and Models lists remain visible after cached refreshes, adding a
  layer, editing sources, Undo, owner changes and panel remounting.
- Adding a library model displays a persistent banner naming the model and
  destination layer. Manual mode explains that Update scatter is still needed;
  Live mode identifies its automatic update behavior. Scene merge has its own
  confirmation. Failed imports show visible failure feedback.
- The EXE presents three Max version cards and **Install / Update**,
  **Uninstall**, and **Close**. Profiles, host binaries and library locations
  are detected automatically. Technical information is behind **Details**.
  Analyze, Apply, the INI picker and ordinary content-path selectors are removed.
- Running selected Max versions produce an actionable close-and-retry message.
  The installer neither closes nor restarts Max. The MZP works inside its
  matching host and instructs the user to restart afterwards.

## Cause and ownership

`tools/ui/colored-lists.cjs` keeps native backing lists hidden while managed
lists display colored rows. The layout cache called synchronization without a
new geometry layout; synchronization copied the backing list's deliberately
hidden state into the visible list. Item counts remained correct underneath.

The original package reproduced this in an owned Max 2027 profile: one layer
and one source were visible after full layout, then both became hidden after
cached layout and five warm binds. Earlier tests checked item/model state and
layout rectangles but missed this visibility transition.

The correction retains each managed list's intended visibility, updating that
intent only after a complete layout pass. Item, color and selection updates
still run on cached binds. Conditional lists retain their layout-controlled
visibility. This is view state scoped to the control lifetime; it does not
change placement ownership, scene data, Undo or publication. Host UI and scene
access remain on the host thread.

`LibraryPanel` owns the notification label; MAXScript reports progress and only
announces success after the actual merge returns successfully. Import failure
keeps the existing rollback behavior.

## Installation and content

Use the corrected EXE in:

`dist/CyrusScatter-0.86.7.1-corrected-20261020/`

Close selected Max versions, select their cards, and click **Install/Update**.
For the MZP use **Scripting > Run Script**, choose the file for the running
Max year, click **Install/Update**, then restart Max.

Automatic discovery checks the shared registration, recognized previous runtime
bindings, companion Content, bounded sibling CyrusScatter delivery folders and
known installed profiles. It does not crawl drives. Host discovery checks the
Autodesk registry and standard installation path. Ambiguous/noninitialized
profiles receive guidance to initialize Max or use its matching MZP.

First adoption verifies the content before publishing its registration.
Subsequent updates reuse registered content. Models, textures and previews are
kept in their current folder; no new content version or second copy is created.
Standard Max 2024/2026/2027 profiles share one library registration. Native and
managed plugin payloads remain host-specific.

An actual **read-only** probe of the artist's installed Max 2027 profile found
the existing `Library-0.86.6.2` through its old runtime binding. The plan calls
for **5,479,166 plugin bytes and zero library bytes**, plus the existing 16 MiB
working allowance. Nothing was installed into the artist's profiles.

This workstation's three-host-compatible content remains at
`dist/CyrusScatter-0.86.7-20261020/Content`. Fresh recipients need that supplied
Content folder beside the EXE. Existing recipients can reuse their registered
library. The MZP resolves existing shared/legacy content; use the EXE plus Content
for fresh automatic content setup. Keep adopted folders available. Installers
do not download models. Uninstall removes selected registration while preserving
shared content, other hosts and old paths referenced by saved scenes.

## Executed evidence

Evidence: `build/repair-08671-20261020/final-receipt.json` pins 20 receipts and
all four artifact hashes. Fixtures are under `tools/repair_08671/`.

- Generator/control integration and approved-layout assertions passed.
  Python regression suite: **175 passed**.
- Installer transaction suite: **46 checks passed**. Includes automatic
  discovery, missing content, registered reuse, old runtime fallback, three-host
  shared resolution, cancellation, publication failures, lock contention,
  modified-file preservation, long paths and synthetic low-space admission.
- The **actual EXE form** ran with `Application.Run` and illegal cross-thread
  control access checks enabled. Install and repeat Update were clicked;
  running-host rejection, retry, selection state and Uninstall operation passed
  against disposable profiles. All three resolved the original content folder.
  The running-host gate was injected for deterministic UI coverage; the probe
  did not close artist sessions or test a physical disk-full event.
- Actual hosted **Install** buttons passed in Max **2024, 2026 and 2027**.
- Lists, add-layer button, add/remove Point, Undo, owner switch, Advanced,
  remount and preserved Manual publication passed in all three hosts.
  The tests inspect native window visibility and managed item counts.
- All twelve sections, scoped Amount refresh, conditional Count/Density,
  retained counters, queued mount cancellation and saved preferences passed
  at configured **200% in Max 2024, 150% in Max 2026, 100% in Max 2027**.
  This is not physical multi-monitor DPI certification.
- Gallery wheel loading after idle, warm thumbnail reuse, search and disposal
  passed in all three hosts.
- Max 2027: the actual library load button imported **Sycamore Leaf 15 — Faded
  Gold**, retained its material, showed the success banner and kept lists visible.
  Live Amount changed from 9 to 12 placements; actual Live library addition and
  feedback passed. Manual and Live banners were checked separately.
- Max 2027 real A027 leaf regression passed Color Correction changes, diffuse
  clearing, opacity, Undo, animation and retained navigation without applying
  pending Manual edits.
- Max 2024/2026 lack the required Corona/map dependencies. Their real leaf
  imports were **rejected**, with visible error feedback, restored selection,
  no leaked nodes/sources and visible lists after remount. These are failure
  checks, not successful Corona rendering qualifications.
- Archive CRCs, every member hash, version/host guards, EXE embedded packages,
  current generated source, compiled managed source and actual loaded native/
  gallery identities were verified. No native rebuild was needed.

Initial fixture runs are retained: older-host leaf imports first failed as
expected for missing renderer dependencies; later fixtures explicitly checked
that failure contract. Immediate control reads after remount/rollback initially
ran before queued creation finished; the fixture now waits for that queue.
Neither observation is represented as successful older-host Corona support.

## Exact corrected artifacts

| Artifact | SHA-256 |
| --- | --- |
| CyrusScatter-0.86.7.1-Setup.exe | `4a4ffe641c87e4ffe5030c0f69a0fe4a5ffff09710d886a4e7526cfbc3c97948` |
| CyrusScatter-0.86.7.1-Max2024.mzp | `0c7ec4bd457fdcd6ce1c71fabca3aaae301f0b8c4a447069f5a3297488985dce` |
| CyrusScatter-0.86.7.1-Max2026.mzp | `6eb5ace680efff93427c64fb2bb575e497cc27bf687cbe5136eb54337d60ffff` |
| CyrusScatter-0.86.7.1-Max2027.mzp | `950bdc6bbb92493a73143b5e91a8640650608faeb034ced36b6036525014052f` |

Generated script file SHA-256:
`13dd36efe157bcd2a49c689715f9396e6e6ec8a2a9d7844e75df32ed6e10a20e`.
The embedded script-body fingerprint is separately
`520257aa263c2c9eb98706060b17901493f9f97fe769eecdf7137ae6a521d2b2`.
Content manifest remains
`010f43f09172c084ba15407227f9776e359b013e1f1a9583d31a2d4458e9a361`.

The EXE is unsigned. Native performance figures from the first delivery remain
historical; this correction does not claim new latency measurements. B21's cold
construction, fully lazy Advanced and sustained artist acceptance remain open.
No artist installation/restart, source-model changes, old-folder cleanup, Git
commit/push or website publication occurred.
