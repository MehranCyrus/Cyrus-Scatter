# Supplied Scatter Tools: source and workflow research

Research date: 2026-10-18. Primary target: the user's exact `SplineDynamics_Pack/Scatter Tools 1.02/ScatterTools_v1.02 Fixed.mzp`.

The supplied tool already implements furniture-aware geometric scattering. Its short artist workflow is useful to study. The inspected furniture routine finds broad horizontal supports and retries placements of existing selected props; it does not classify props as books, candles or plants. That distinction matters for Cyrus Arrange's category rules, generated book rows and saved reusable asset library.

## Evidence and boundaries

The original pack was read only. No vendor script, installer or macro was evaluated, installed or launched. No Max session, licensing state, artist scene or profile was changed. Static data decoding used the independently reviewed branches of the author's [3ds Max QuickBMS format script](https://aluigi.altervista.org/bms/3dsmax.bms). Decoded proprietary text stayed in memory: this report contains paraphrased findings and location metadata, not vendor implementation code. The data-only helper and its reviewed-source provenance are under `build/spline-pack-native-research-01/`.

The pack changed while the user relocated files. Earlier inventories describe earlier instants; directory names are not reliable version identifiers. A new read captured 27 MZP archives. Every selected archive was checked against its agreed identity before analysis and checked again afterward. This is a point-in-time inventory, not a claim that the containing tree is immutable. Full identities, archive member lists and source-location anchors are in [local evidence](../../build/spline-pack-research-01/evidence.json).

| Inspected input | Archive SHA-256 | Decoded ASCII SHA-256 / bytes |
| --- | --- | --- |
| Exact Scatter Tools 1.02 target | `b1c8139a0e8526b47ce1a7cc74f4b9f4c6ce32e78e0ee3b1f5227fb7239bd2b3` | `e4a63e56c002a1231dda8be223ced1f8a3d278221ff1bb7ccbcae43cb41b63a5` / 92,233 |
| Secondary RandoMixer 1.16, stored inside the folder named `RandoMixer 1.10` | `7b60e37b42095cba7928a0735d51a589c1cbd9deb6617e8a961f6ec5ab915eb3` | `7c9336e7156a4e471ee7d726dce2e19691c66862c424a4a463906976abd600c3` / 391,152 |
| Older RandoMixer 1.10, identity comparison only | `c7bc6174e086c7fd323cd432d5d25148e96a38af62192eef30d2776541c9739b` | `a1961fbf36105901f7292b36142a83f14a2b1236660a97d6bf8bb7ac9219e341` / 379,307 |

Scatter's encrypted member is `scripts/SplineDynamics/ScatterTools/ScatterTools.mse`, 92,234 bytes, SHA-256 `eb1da7ebad04322222cc2db0ce0a8ae441fe40e102aa8b84e29738b879927b59`. Its internal version value is 1.02; `mzp.run` contains a separate package version 1.0. The decoded stream has one minified line and quoted obfuscated identifiers immediately after `fn`. A whitespace-based function regex initially reported zero; a corrected declaration scan finds 117. Keyword counts alone were not used as algorithm evidence.

Coverage: the Scatter UI, hierarchy helpers, distribution preparation, normal filtering, grid construction, point sampling, collision/retry loop, transform baseline and cleanup path were traced. RandoMixer 1.16's corresponding support preparation, retry routine and quick furniture action were compared. This is static control-flow review, not complete analysis of unrelated rendering, licensing or collection features, and not a runtime compatibility, visual quality or performance test. The requested YouTube videos remain separate: [video evidence and its access limits](UX_REFERENCE_VIDEOS_2026-10-18.md).

## What the artist actually controls

The macro loads the MSE from the user's Scripts directory. The target archive contains script launchers, the encrypted script, icons and images; it contains no native placement DLL. The inspected placement logic itself is MAXScript calling Max's built-in geometry operations. This does not establish the implementation of every other Spline Dynamics product or imply that MAXScript and C++ have equal performance.

The normal sequence is: select existing props, pick the distribution model/group, choose a scatter method, then press the main scatter action. Five methods are present: whole surface, face direction, furniture, vertices/spline knots and pivots. Furniture mode supplies orientation/anchor behavior internally and disables irrelevant orientation/anchor controls. Generic modes expose direction, normal alignment, yaw range, uniform scale range and anchor choice. Defaults include zero additional yaw and 100% scale. The script initially opens Switch Places and Scatter Objects; the transform and information sections start collapsed. [S8, S9]

The UI remembers initial transforms for selected objects. Restore reapplies that baseline; the baseline-update routine records the current transforms. Repeated scattering restores that baseline first, rather than continually accumulating prior transforms. The implementation changes existing prop transforms; temporary clones are used to analyze distribution geometry and are removed afterward. It does not create a persistent semantic furniture setup or a saved library entry for each selected prop in this flow. [S3, S7, S8]

The public [product page](https://www.splinedynamics.com/randomixer-scatter-tools/) and [manual](https://www.splinedynamics.com/randomixer-scatter-tools-manual/) describe the same selection/picker/action model, redistribution of existing objects, furniture mode and restoration. The manual's public screenshot is an older v0.9 illustration; it is not evidence of the current supplied binary or video frames. In particular, vendor baseline Commit terminology must not be confused with Cyrus Arrange's staged Preview/Commit.

## Furniture placement, traced in order

The following locations are **zero-based half-open byte offsets in the exact ASCII stream above**, not source line numbers. The complete anchor map is in the evidence JSON.

| Evidence | Location in Scatter 1.02 | Observed behavior and limits |
| --- | --- | --- |
| S1 | 40,695–42,566 | Measures bounds; filters broad panels using relative dimensions; selects faces by angle to an axis. Furniture preparation calls the upward-direction filter with a 0.5-degree threshold. This is a geometric heuristic, not recognition of a TV console or a book. |
| S2 | 42,566–43,699 and 47,947–48,695 | Builds a horizontal segmented plane for each support. Grid spacing depends on the shorter support dimension and aspect ratio, using divisors 11, 9 or 7. Downward rays from four offsets test whether grid cells lie over the original support. Rejected cells and an open-edge border ring are removed. |
| S3 | 45,512–47,553 and 48,695–50,791 | Clones hierarchy geometry, converts temporary copies, separates connected planar components and creates support grids. The furniture call also retains side/bottom panels as collision objects. Intermediate materials are cleared only on these temporary analysis copies. |
| S4 | 50,791–51,583 | Chooses a random support face and a random triangle sample obtained from three face vertices. The collision helper loops over other props and temporary structural panels using `intersects`. |
| S5 | 52,146–53,345 | Sorts props by their horizontal bounding extent, chooses random candidate faces, seats the prop base on a support point and retries while collisions remain. Furniture dispatch supplies a 60-attempt limit per prop; the generic routine defaults to 50. Exhaustion restores that prop's saved transform. |
| S6 | 65,936–74,158 | The handler normalizes selection to topmost hierarchy roots, excludes the picked distribution root, randomizes selection order, restores transform baselines, builds temporary distribution geometry and runs the chosen placement routine. It deletes temporary geometry and restores the original selection. |
| S7 | 59,963–60,630 | Restore and baseline-recording routines operate on stored node/transform pairs. Invalid stored nodes are cleaned separately. |
| S8 | 65,936–74,158 | Furniture mode disables generic orientation/anchor controls. Uniform scale is applied before placement; optional Z rotation is applied afterward. |
| S9 | 81,872–82,358 | Creates a compact rollout floater; registers an Undo notification callback and removes the owned callback on close/recreation. |

The dimensional filter and inset grid intentionally simplify the surface problem. Small decorative geometry can be ignored as a furniture panel; thin/irregular surfaces may lose useful area to coarse discretization. Object clearance is not exposed as an explicitly measured empty-volume model in the traced routine. The collision list includes retained structural panels, so shelves can reject props that overlap the board above or a side panel.

Autodesk explicitly defines [`intersects`](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Node-MAXWrapper/Node-Common-Properties-Operators/Node-Common-Methods/GUID-C6CD8B3A-C5EF-4A83-8DB2-B5EDFEFDEEDD.html) as node bounding-box overlap. It is not a triangle intersection test. The same page specifies that `intersectRay` returns the nearest admissible surface hit and respects face normals. Therefore the support rays and collision calls have different roles; the presence of ray tests does not make all placement collision tests mesh-accurate.

No explicit RNG seeding call appears in the decoded Scatter source, and the traced action uses `random` repeatedly. Thus the supplied action is consistent with a fresh result on another click, but a user-visible reproducible seed contract was not established. No semantic asset class, allowed-furniture mask, trained model, scene graph inference or LLM call appears in the traced placement path. Those statements apply to this inspected path, not every feature in every release.

## Static concerns to learn from

Optional yaw is applied **after** the collision-accepted placement loop, and no subsequent collision/support recheck is visible before cleanup. Nonzero yaw can change a long object's occupied envelope. This is a concrete static concern for that optional setting, not a reproduced vendor defect; its default yaw range is zero. Cyrus Arrange should continue validating the final yaw, scale, footprint and enclosing collision box together before publication. Its current native candidate construction/query already follows that order; see `src/arrangement.cpp` and `src/placement_queries.cpp`.

The retry loop also restores a prop whenever its counter reaches the limit, including the final allowed attempt. A finite attempt budget is not proof that space is unavailable, and per-object fallback is not a transaction over the complete layout. Our UI should report underfill and retain the last accepted complete result on failure. There is no basis from this static review for speed, quality or robustness rankings between the two tools.

## Secondary version comparison

RandoMixer 1.16 uses closely corresponding structural filters, a 0.5-degree face filter, grid/ray preparation, random point sampling and the same bounding-box overlap primitive. Its quick furniture button dispatches a 50-attempt routine, moves selected existing props and deletes temporary analysis surfaces. Its generic fit routine sorts props by horizontal extent. These observations are bound to decoded offsets 127,533–132,446 and 374,467–375,297, not to its containing folder's misleading 1.10 name. This brief comparison does not establish equivalence of every Scatter Tools and RandoMixer feature.

## Practical decisions for Cyrus Arrange

1. Make the everyday path furniture selection → source prop selection/catalog → Generate. Supply a safe category default and useful status. Keep masks, source contact editing, region IDs and diagnostics in advanced editors.
2. Let Generate choose a new seed by default, as the user requested. Keep an explicit repeat/fixed-seed option, preserve the actual successful seed with the setup, and publish seed/settings/output atomically. Preview should stage one seed; Commit should accept that exact staged result.
3. Disable irrelevant controls instead of asking artists to configure an anchor and orientation for every routine furniture run. Keep explicit support/spine authoring available when the asset needs it.
4. Keep our reusable asset metadata, semantic eligibility rules, protected placements, whole book-row locks, scene persistence and final-fit validation. The short vendor workflow is useful UX evidence; its transient transform-redistribution model is not a replacement architecture for the user's larger goal.
5. Show placed/requested counts and actionable underfill reasons. A reroll should feel cheap and predictable, while failure leaves the prior accepted result reviewable.

These are independently written design recommendations. No vendor implementation, decoded source, helper algorithm or licensing material was added to Cyrus Arrange production code or delivery payloads by this research task.
