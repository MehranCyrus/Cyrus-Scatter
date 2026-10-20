# 0.86.8 — source clearance and layer priority

20 October 2026. **Qualified for scoped Max 2027 user testing.** The user authorized
implementation, UI refinement, packaging and a scoped Git backup. The final
[source/package/loaded-pair seal](../../../build/source-clearance-0868-20261020/final/final-receipt.json)
passes. This report records the exercised scope and remaining limits.

## Behavior

Models and Points now have a **Radius and clearance** section. Own copies, other
models in the layer, and other layers each inherit independently. An explicit
scope replaces that scope's default; it does not erase other relationships.
Selected target layers use UUIDs. Deleted targets remain inactive, and Undo
restores the relationship. The same geometry in two source rows has independent
authored policies.

Native C++ evaluates the effective constraints. Equivalent explicit/default
rules retain the inherited schedule, including cleanup. Conflicts use protected
edits, preferred sources, layer order and stable candidate order. Count admits
candidates before preference, so distant preferred candidates cannot take extra
slots. Accepted placements alone reserve space; cleanup and bounded replay
release removed blockers.

The spacing dropdown now says **Edit default rule**, with **Other layer** as the
peer label. The reported Between layers exception was reproduced with the
previous generated callback. Explicit loops replace the nested `collect`
expression that failed while resolving its captured `scope` local. Separate
baseline/fixed profiles establish the causal correction; final tests use the
actual dropdown commit notification.

Mixed selections display **Mixed** and only the edited field changes.
Factor/gap/metric controls stay in **Clearance distance**. The main panel scales
its height, including the scene-upgrade button, at larger UI scale.

## Persistence and architecture

Version is **0.86.8**, saved schema **59**, calculation contract **CyrusUnified2**,
complete recipe **8**, procedural publication bridge **4**. Native placement
remains **2**. Analyzer, MCP and library content keep independent versions.

Schema 58 requires **Upgrade scene to 0.86.8**, an Undoable action preserving
authored identities/settings. Save an upgraded copy. The previous runtime refuses
schema 59 and recipe 8 rather than evaluating after dropping new policies.
Supported earlier recipes receive inherited policies on import; files and
previews are not rewritten.

Authored sparse records and bounded UI orchestration remain MAXScript. Source
mapping validation, effective rules, spatial queries, conflict resolution,
cleanup and replay are C++. Workers/host-thread ownership are unchanged.
Limits remain ten populations, one million candidates, sixteen retry rounds and
fifty million neighbor visits. Policy metadata allows 512 active source rows per
population. Native memory admission uses a conservative
384-byte per-candidate allowance for solver coexistence (previously 256).

The first delivery conservatively settles setup acceptance after a changed input
key. Policy edits reuse candidate preparation, and unchanged browsing/animation
keys skip calculation. Compiled components and independent acceptance outputs are
not separately cached. This is a correctness delivery; no broad speedup is claimed.
Existing numeric presets retain their layer-owned categories.

## Evidence

The campaign is under `build/source-clearance-0868-20261020/`. Pre-existing source
changes were frozen in `baseline.json` before implementation.

| Evidence | Scope |
| --- | --- |
| Native suite | 49 tests; existing generation, radius, Paint, recipe, package, Edit, memory and ownership checks plus new clearance tests |
| Independent oracle | 240 randomized small scenes; mixed scopes, metrics, radii, preferences and protected placements |
| Native stress | 100,000 sparse candidates; deterministic output and bounded neighbor visits; recorded time is not a general benchmark |
| Python/generation | 176 tests, generated-source/inventory checks and approved layout checks |
| Max integration | Actual scope notifications, independent multi-source edits, mixed presentation, Undo/Redo, exact inherited/explicit fingerprints, candidate reuse and source/Point replacement |
| Lifecycle | Save/reopen; target rename/delete/Undo; failed-successor retention; Manual/Live; unrelated animation; explicit schema-58 upgrade and old-reader refusal |
| Real content | A027 Corona leaf plus filler spheres on a plane, sphere and box; clearance distances, material Color Correction, XY/3D roundtrip, Bake transforms/materials and Undo |
| Installer | Exact Max 2027 payload, existing library reuse, optional missing-ZIP failure, checked real-ZIP reuse and zero-byte repeat update in disposable paths |

Initial failures are retained separately. Product fixes include the lazy scope
callback, mixed-value binding, and the scaled main-panel height. Test-driver
corrections include Max's `CBN_SELENDOK` notification, generated control names,
and isolating warm cache checks from prior failed-successor/cold-display phases.
The first installed-host Bake check used a 1e-5 basis tolerance. A plain Max Point
assigned the same rotation reproduced the 5.89099e-5 error independently of the
plugin. The check now bounds basis error at 1e-4 and position error at 1e-5 cm;
material identity remains exact. Both final hosts pass. The diagnostic and failed
receipt are retained. No failed run is counted as acceptance.

Cold profile `update08671-test-clearance-final2-2027` ran at 150% scale;
`update08671-test-clearance-installed3-2027` loaded the actual installed bytes
at 100%. Actual dropdown/button notifications and bounds checks passed. Physical
Computer Use inspection confirmed the main-panel controls at both scales and
the source clearance/targets/priority controls at 100%. This is distinct from
physical tablet-brush or renderer validation.

- [49-test frozen native receipt](../../../build/source-clearance-0868-20261020/final/max2027-r2/receipt.json)
- [176-test Python log](../../../build/source-clearance-0868-20261020/final/python-tests.log)
- [Generated-source check](../../../build/source-clearance-0868-20261020/final/generated-r2/generated-check.json)
- [Final Max acceptance](../../../build/mcp-qualification/update08671-test-clearance-final2-2027/clearance-acceptance.txt), [lifecycle](../../../build/mcp-qualification/update08671-test-clearance-final2-2027/clearance-lifecycle.txt), [real leaf](../../../build/mcp-qualification/update08671-test-clearance-final2-2027/real-models.txt)
- [Installed-byte real-leaf test](../../../build/mcp-qualification/update08671-test-clearance-installed3-2027/real-models.txt) and [installer integration](../../../build/source-clearance-0868-20261020/final/installer-final-r2/result.txt)

Local build receipts are ignored by Git. A source checkout alone cannot verify
these executions; it contains the test drivers and this scoped record.

The broader [validation matrix](VALIDATION.md) is not a claim that every row has
been exercised. Physical tablet painting, all renderer combinations, million-row
host timing distributions and the remaining unrelated backlog are not certified
by this focused campaign.

## Packages and use

Final directory: `dist/CyrusScatter-0.86.8-20261020/`.

- `CyrusScatter-0.86.8-Setup.exe`
- `CyrusScatter-0.86.8-Max2027.mzp`
- `CyrusScatter-Content-0.86.7.zip`
- `SHA256SUMS.txt`

Close Max 2027 and use the EXE. Leave **Install / update plant library** unchecked
to keep existing content. For a content install, keep the ZIP beside the EXE and
check the option. Identical installed files are reused. The unchanged ZIP is a
hard link to the earlier archive on this workspace volume, without another
2.4 GB allocation. Content itself stays revision 0.86.7.

Alternatively run the MZP with **Scripting > Run Script**, then restart Max.
The artist performs installation; this campaign does not modify artist profiles
or restart artist sessions. The EXE is unsigned.

This delivery is qualified for **Max 2027 only**. The historical Max 2024/2026
packages retain their prior version and receipts. New clearance semantics are
not claimed on those hosts.

## Backup and artist acceptance

The authorized backup branch is `codex/workflow-0.75`. It includes the accumulated
Scatter code, installer/library work, this implementation and maintained docs.
Ignored models, scenes, content and installers are outside Git. Unrelated website,
CyrusArrange, design and licensing work is preserved outside this commit. Git
publication is recorded separately in the local final campaign directory.

The next artist check is to install the exact pair, open a copy of a schema-58
scene, use **Upgrade scene to 0.86.8**, and compare the familiar scene before
changing clearance. Then select the desired model, set its radius, choose the
independent scopes and use **Prefer this model** only when it should win
clearance conflicts. Normal priority retains layer/candidate ordering. Protected
edits are not silently deleted by preference.

## Exact final artifact identities

| Artifact | SHA-256 |
| --- | --- |
| `CyrusScatter-0.86.8-Setup.exe` | `94dcb4fd818a6ee25c10c8988802c8e45b468054513539bd07245601c7b5520c` |
| `CyrusScatter-0.86.8-Max2027.mzp` | `b81da84e92baaa5718db6ed6134a3e98f715a9d4cf845172e5739ff53480706e` |
| `CyrusScatter-Content-0.86.7.zip` | `db5a63e87f81abd78563ec80039fed066a6cb73f585779749ed23faf548f2c58` |

Generated script SHA-256: `add79c505533dd48136c02fcbaad2f48adec4cf4b9113c2f904625f9317fb3f2`.
Loaded body fingerprint: `b26098f455e70c093f75d43d74ec6b2d51385fcffbe8819004234dcd1e5c16ba`.
