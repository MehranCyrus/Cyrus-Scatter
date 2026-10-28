# Cyrus Scatter 0.87.5.4 — scene colliders and branch adaptation

**User-reported callback defect:** the delivered 0.87.5.4 script can raise `count in undefined` from an application callback. Its tests below missed that path. Use the [0.87.5.5 correction](CALLBACK_HOTFIX_08755.md); retain the original hashes and scoped measurements as historical evidence.

28 October 2026. Runtime qualification: Max 2027. Separate Max 2024 and 2026
payloads are included at the user's request, without launching either older host.

## Install

- [Combined EXE — Max 2024, 2026, 2027](../../../dist/CyrusScatter-0.87.5.4-20261028/CyrusScatter-0.87.5.4-Setup.exe)
- MZPs: [2024](../../../dist/CyrusScatter-0.87.5.4-20261028/CyrusScatter-0.87.5.4-Max2024.mzp), [2026](../../../dist/CyrusScatter-0.87.5.4-20261028/CyrusScatter-0.87.5.4-Max2026.mzp), [2027](../../../dist/CyrusScatter-0.87.5.4-20261028/CyrusScatter-0.87.5.4-Max2027.mzp).
- [Exact qualification and payload hashes](QUALIFICATION_08754.json), [checksums](../../../dist/CyrusScatter-0.87.5.4-20261028/CHECKSUMS.sha256).

Close the Max versions selected in the EXE before installation, then reopen Max.
For an MZP, use **Scripting > Run Script**, then restart Max. Keep the matching
script/native pair together. The EXE is unsigned. No artist installation or
artist-session restart was performed by this delivery.

The existing shared Library is retained; content remains 0.86.7. The EXE does not
embed a new model-library download. Native Scene presets remain Max 2027 only.
Independent Analyzer, Physics Lab, MCP and content product versions are unchanged.

## What changed

Ordinary walls, stones and other closed scene meshes can now be enrolled in
**Scene colliders**. They need no scatter layer, source row or Cyrus Edit
placement. Pick, Add selected, Remove and Select collider bind one controller-owned
reference list. Move/rotate/scale enrolled objects with normal Max tools.

Reacting layers can use **Bend branches**, **Prune branches** or **Bend then
prune**. These broader responses use prepared guide envelopes and bounded angle
proposals. Clearance, Bend strength, Prune penetration and Prune amount expose
the artistic tradeoffs. Pruning masks an entire prepared guide subtree and its
attached foliage per instance; moving the obstruction away restores it. CPU
mesh output, compact GPU poses and Bake consume the same visibility decision.
Structural trunks owning children remain protected and report blocked contacts.

**React to neighboring trees** is opt-in on both reacting layers. Stable layer
and instance identity decide which tree yields against immutable rest-branch
proxies. Repeating the same setup does not start feedback iterations. Ordinary
placement spacing still handles trunk locations.

Old scenes retain **Detailed contact** on migration; choose a broad response
explicitly when trying this workflow. The [artist guide](ARTIST_GUIDE_08754.md)
explains the controls and limitations.

## Reproduced defects and fixes

| Problem | Change |
| --- | --- |
| Manually stretching a wall triggered the plant transform restriction | Obstacle transforms have a separate boundary. Nonsingular nonuniform/mirrored linear transforms bake into a private collision copy; reacting plants retain their positive-uniform requirement. |
| Transform notifications repeatedly invalidated scene collider geometry | Ordinary collider geometry watches target the object, with node transform/object-offset checks separated. Translation reuses the numeric geometry. |
| A disabled/retired Cyrus Edit row could dereference unavailable feedback during contact restaging | Check current layer/instance admission before evaluating saved Edit feedback. Saved history remains intact. |
| Pending source geometry prevented changing an unrelated model/layer color | Recolor the complete retained publication without recapturing pending geometry or solving contacts. |
| Capped or tree-sized ordered circular stems were rejected during preparation | Admit validated end-ring caps and assess width relative to length; remove the old 3 cm inference ceiling. Arbitrary welded topology still needs review. |

This release does not add automatic analytic-sphere recognition or a convex-hull
simplifier. Closed collider meshes continue through the existing geometry query
path. Those earlier ideas must not be described as delivered here.

## Executed checks

The final Max 2027 package's script/native identity is pinned in the qualification
JSON, including automatic installed startup in owned profiles. Its 62 native
suites pass; 577 Python checks and generator/catalog checks pass (375 semantic
controls). Max 2024's SDK/native checks had already completed before the user
waived older-host testing. Max 2026 was compiled without tests. Neither older
host was launched, and their runtime compatibility remains unverified.

Max 2027 checks cover nonuniform/mirrored walls, equivalent parameter-built
boxes, collider geometry edits, add/remove and response Undo/Redo, deleted-node
Undo, source-failure recoloring, real grass and fern preparation, generated
branch-tree preparation, neighbor response and restoration. A real mouse drag
published a new response while the button was held, with no new source capture,
preparation, collider cook, placement layout or placement generation. Actual
viewport zoom changed neither solves nor unchanged buffer-upload counters.

Public exact mesh construction and Bake both produced **18,291 faces** in the
pruned test. This is geometry consistency, not an external-renderer image test.
Native scene save/load and all three delivered trial copies reopen successfully.
A fresh material-free Scene preset preserves settings, preparations and placement
transforms while importing independent collider nodes and nonempty identities.
Portable recipe capture explicitly rejects unsupported new references/settings.

The renderer-dependent imported scene's Scene preset capture correctly rejected
unavailable shader dependencies in the private core-only host. Its materials
were preserved. The separate neutral fixture qualifies reference/settings
persistence, not the original material graph. Failed test attempts and corrected
test-oracle assumptions remain in the local campaign receipts.

## Measured scope

| Owned Max 2027 case | Observation |
| --- | --- |
| 1,000 imported grass instances, ten nonzero wall movements | 34–82 ms per synchronous update; median 61 ms. Last step: 227 affected candidates, 121 posed plants, 6,013 pruned guides, zero work-limited guides and zero detailed mesh refinement work. |
| 60 generated branch trees, neighbors enabled, external wall moved away | 37 posed trees, 8 pruned guides, 34 blocked structural/uncleared guides, zero work-limited guides; recorded solve 12.15 ms. Repeating the setup performed no new evaluation. |
| 12 imported Neottopteris fern instances | 6 affected, 3 posed, 49 accepted hinge fits, 641 pruned guides, zero work-limited guides; recorded solve 24.09 ms. |

These are CPU observations of the documented fixtures, not presented FPS or
million-instance guarantees. Broad envelopes can retain leaf-level intersections.
Blocked trunks/branches are visible diagnostics, not proof of full clearance.
The 60-tree fixture is generated geometry; automatic preparation of arbitrary
commercial tree junctions and full renderer/animation/soak acceptance remain open.

Max replaced typed zero scale with a very small nonzero evaluated axis in the
host probe. Genuine singular-transform rejection is established by the numeric
suite, not by treating that UI value as an exact zero matrix.

## Trial copies

- [1,000 grasses and an ordinary scaled wall](../../../Test%20Scene/Interaction%200.87.5.4/Scene_Collider_Grass_0.87.5.4.max)
- [Fern and an ordinary wall](../../../Test%20Scene/Interaction%200.87.5.4/Scene_Collider_Fern_0.87.5.4.max) — Mesh preview preserves its optional renderer materials.
- [Generated branching trees and a wall](../../../Test%20Scene/Interaction%200.87.5.4/Branch_Tree_Neighbors_0.87.5.4.max)

The tested Test22 snapshot is the preserved 60,690,432-byte copied input. The
artist path was separately saved at 09:48 during this task and is now a different
94,132,390-byte file; the qualification records both hashes and does not claim
they are identical. No trial was saved over that artist path. Artist INIs match
the owned final-host launch baselines.

## Maintained handoff

Scene schema **64**, Interactions **14** and source-command Undo **2** advance.
Source transform **2**, Edit capability/storage **4/3**, portable recipe **9** and
Scene preset metadata **1** remain. [The plan](PLAN.md) records ownership,
invalidation, memory/Undo and failure behavior. Source changes include the
authoritative templates/generators, native implementation and focused tests.

Current navigation, the artist guide, version policy, progress ledger and feature
catalog are updated. Knowledge-index activation, website publication, Git
commit/push and artist-profile installation were not performed.
