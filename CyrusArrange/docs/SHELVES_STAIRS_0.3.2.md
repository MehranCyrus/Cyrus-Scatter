# Detailed books and arbitrary stair props — 0.3.2 development

This campaign extends the compact Modify/path checkpoint with actual prepared
book meshes in multiple compartments and different prop types on stair treads.
The focused campaign below passed. This is development evidence, not release
qualification. The complete fourteen-item goal remains active.

The subsequent [priority packing checkpoint](PACKING_PRIORITY_0.3.2.md) changes
the production solver and adds required copies. Its fresh 26-check Max run and
independent verification place all 100 books across four levels and 48 props
across all six treads, including required books/bins. The measurements and
receipts below retain their original, earlier source scope.

## Inputs and preservation

The source is the prepared `Books_01_Book_002` in the user's organized Corona
library, with immutable model/metadata/map identities from
`tests/max/real_world_models_data.ms`. The original file and all declared book
maps are checked before use. A disposable copied model is merged into an owned
millimetre scene; other members of that working collection are discarded there.
The library and original download remain untouched.

One working book is rotated upright, without resizing, for the shelves. A second
copy retains its flat orientation for the stairs. Each has 1,361 actual source
vertices and 2,672 evaluated triangles; source polygon counts are a different
representation. Source vertices, topology, smoothing, authored UV1 coordinates,
mapping faces and material binding are checked against generated outputs. Source
transforms and meshes are checked again after all generation.

The cabinet, stairs, fruit and bin are newly modeled geometry, not downloaded
assets. The eight-part cabinet includes three interior shelf levels, an upper
board, full side/back walls and a divider. No furniture type or prop eligibility
rule decides placement. An upper board remains a physically valid receiving
surface; it is not silently excluded by a semantic cabinet rule.

## What the test measures

`tests/max/arrange_shelves_stairs_tests.ms` requests 100 uniformly scaled upright
books, using 80–110% random scale, a 5mm edge margin and 2mm gap. It verifies real
output contact, complete geometry/appearance preservation, multiple interior
levels, seed repeatability, protected output, Undo and schema6 save/reopen. The
six-tread case requests 48 copies drawn from the actual flat book and modeled
fruit/bin, with 8mm edge margin and 10mm gap. It measures actual world meshes and
exports them for independent verification. Generation time is recorded separately
from host startup, mesh export and test computation.

`tools/verify_shelves_stairs.py` imports no plugin geometry or sampler. It first
proves that each exported receiver is a closed, consistently outward-oriented,
eight-corner/twelve-triangle rectangular solid with complete exterior planes.
Only then are its bounds used as an exact solid oracle. It checks every output
vertex against source geometry under the reported pose and final scale, exact
face/material-ID/smoothing records, actual base height, full footprint support
and edge margins, solid avoidance and all pair envelope gaps. UV coordinates
and material-root reference checks remain explicit Max-host evidence.

The verifier also mutates actual valid exported data: lift a source-consistent
output, move it off support, duplicate another output's geometry/pose with a
different stable ID, and remove a receiver face. These must fail for support,
overlap or solid-proof reasons. A complete independent acceptance run requires
a successful exact-pair host receipt and the verifier's frozen source hash.

## Initial evidence and correction

Frozen `build/native-032-shelves01` passed both SDK modules and fifteen native
suites. `build/host-032-shelves01` stopped after 12 passes at the protection
assertion, so it is not a passed campaign. Its first generation nevertheless
published all 100 detailed books in **107ms**, with 4,730 candidate probes.
The retained actual-mesh export independently passed: **34/35/30/1** books on
the four boards, maximum vertex correspondence error **0.000547mm**, minimum
pair envelope gap **2.09579mm**, complete support and no cabinet penetration.
The upper board's one book is a valid geometry-based placement.

The initial assertion compared the pre-Protect native double scale against the
subsequently protected pose. `caSetLocked` intentionally captures the current
actual Max node transform, including user edits and Max's float scale. The
correct preservation witness is the accepted pose after this explicit command,
then exact comparison across regeneration. The failure is retained; this test
correction does not loosen support, source preservation, collision or quantity
requirements. Fresh result/seed/delta diagnostics and failed-scene retention
were also added. A new frozen campaign must pass before claiming the complete
shelf/stair workflow.

The prototype independent proof and its four rejected negative controls are in
`build/shelves-analysis02/diagnostic.json`; that diagnostic is not a complete
host campaign or release qualification. Final current evidence will be appended
after both cases and lifecycle checks pass on one frozen source pair.

## Passed current campaign

`build/native-032-shelves03` compiled both Max2027 SDK modules and passed all
**15 native suites**. `build/host-032-shelves02` passed **22 actual Max checks**,
exited normally with code0, and passed the five native-pair/profile guards.
The corrected protection witness showed zero position, yaw or scale difference
after fresh generation, preserved the protected flag, and retained 100 outputs.
One Undo restored the complete accepted prior arrangement.

The frozen independent verifier then passed both actual-mesh exports and all
four negative controls. Its first premature invocation correctly refused the
still-pending host receipt; acceptance was run only after normal host exit.

| Case | Actual copies | Supports used | Timed Generate | Maximum vertex error | Minimum pair envelope gap |
| --- | ---: | --- | ---: | ---: | ---: |
| Upright prepared books | 100 | 34 / 35 / 30 / 1 across four boards | 118ms | 0.000547mm | 2.09579mm, required 2mm |
| Mixed stair props | 48 | 25 / 17 / 6 across three treads | 75ms | 0.001389mm | 11.08221mm, required 10mm |

The stair outputs contain **43 fruit, 4 detailed flat books and 1 bin**. All are
physically valid, with the complete footprints supported, requested edge margins
and no solid penetration or pair collision. These counts also expose a useful
next improvement: random acceptance currently favors smaller props and fills
earlier support regions. The remaining priority/packing work should reserve
large/required props before filling around them, with deliberate distribution
across usable spaces. This is a placement-quality task, not a failed collision
check. Existing source weights do not promise equal accepted counts.

The timings cover the native Generate call after scene preparation, including
its calculation/publication. They exclude Max startup, model loading, test mesh
export, independent verification and rendering; they are not FPS or broad
hardware benchmarks. The original Max file, metadata and all declared maps
remained byte-identical. The 2,793,472-byte private test scene also saved and
reopened with both complete logical arrangements intact.

The **151-file current source map** and all receipt/artifact digests are indexed
in `build/shelves-032-progress01/progress.json`. Compared with the earlier
path/Modify checkpoint, the only source changes are the new fixture and verifier;
production C++, UI, installer and third-party source hashes are unchanged.

| Evidence | SHA256 |
| --- | --- |
| Native build receipt | `9f68b0077562c44dbdb0f69b34085270011f863e22fb588ada8ea604a8a2bc89` |
| Actual Max host receipt | `e92b0e6a6055c8e76a28ce628830f0ac915d15294df68f50eab4c2d1110e92d2` |
| Independent geometry report | `d2ea091f6f2ed707f8e310dbf42c2f1458068e2a0a0e76b52cf44103f9846d3d` |

No artist installation, restart, computer use or final-package claim is implied.
The private scene requires a matching development pair and is not an installer
or artist-ready replacement for the preserved 0.3.1 example. Broader imported
receiver cases, real curved roads, units/performance coverage, irregular-fit
refinement, priority logic, diagnostics/highlights, inline overrides and final
installer acceptance remain open in the full ledger.
