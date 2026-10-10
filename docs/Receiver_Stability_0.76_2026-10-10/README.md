# Receiver stability — research and implementation qualification

Baseline: `02f9326` on `codex/workflow-0.75`, Scatter 0.76 / package 0.76.0 / schema 54. Research accessed 10 October 2026. Receiver-local sampling is implemented and the bounded qualification below passes. This report distinguishes vendor documentation, earlier measured behavior and our design decisions; it is not release certification.

## Official research

| Source | Documented concept | Application to Cyrus |
| --- | --- | --- |
| [SideFX Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html) | Primitive seed attributes avoid dependence on primitive numbering. Rest geometry plus primitive number/coordinates and Attribute Interpolate supports deformation with unchanged topology. Texture-space correspondence is a separate strategy. Relax introduces neighborhood dependencies; output order and stable IDs are separate concepts. | Use persistent receiver seeds, separate IDs from retry order, and state geometry/Relax limits explicitly. We are implementing receiver membership stability, not arbitrary topology correspondence or a rest-pose animation mode. |
| [SideFX Attribute Interpolate](https://www.sidefx.com/docs/houdini/nodes/sop/attribinterpolate.html) | Attributes can be reconstructed using primitive coordinates or source element numbers and weights. | Keep face-and-barycentric anchors for Brush. A barycentric anchor is not a UV texture map and does not make a face index persistent after remeshing. |
| [Autodesk Mesh API](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_mesh.html) | `BaryCoords` and the extended `IntersectRay` describe locations relative to triangle vertices. The API distinguishes geometric face normals from corner/interpolated render normals. | The current calculation uses geometric normals. Smooth-normal orientation is a separate feature, not necessary for receiver stability. Host snapshots remain on the Max thread. |
| [Forest Surface rollout](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces) | XY placement projects along the Forest object's local Z; UV mode follows surface mapping. XY positions normally seed item randomness; stacked randomization changes that behavior. The manual describes a shared terrain-characteristic table with manual/Auto update. | Forest's projected workflow explains some stable terrain behavior but is not a general replacement for surface sampling on spheres. Documented caching does not establish the exact invalidation or upload algorithm. |
| [Chaos Scattering rollout](https://docs.chaos.com/display/VMAX/Scattering%2BRollout), [Chaos getting started](https://support.chaos.com/hc/en-us/articles/4953372632209-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Getting-Started) | Temporal consistency scatters at a rest frame and follows deformation. Collision avoidance has different applicability outside that rest frame. Normal alignment controls orientation. | Temporal consistency and receiver-addition stability are distinct contracts. Preserving every plant while also re-solving arbitrary new collisions is not an unconditional guarantee. |

The current Chaos documentation site returned an empty client-rendered page to the text reader. The indexed official Scattering rollout and official support page were readable. No private implementation or vendor cache-hit claim is inferred from these pages. Existing [measured Forest/Chaos research](../Vendor_Surface_Paint_Research_2026-10-09/README.md) found substantial Chaos reshuffling on receiver addition and stable Forest flat painted coverage in its qualified fixture. Those measurements remain historical evidence, not new tests of current vendor versions.

## Chosen design

1. Keep the saved append-only node/UUID receiver history. Names and current list positions are not identities. A replacement node with the same name receives a new identity.
2. Generate on each receiver independently. Its persistent UUID salts separate position, model, rotation and scale random channels. Area-weighted triangles and uniform triangle sampling remain the geometric basis.
3. Encode the saved receiver slot and local candidate ordinal in the numeric candidate ID. The owning layer supplies the namespace. Maintain a separate bounded schedule for candidate-budget/accepted-target retries. Rejected candidates never compact identities.
4. Density rounds each receiver's expected count independently below the cap. Fixed Total uses area-weighted largest-remainder quotas with saved-slot tie breaking. At the existing 100,000 cap Density also needs quota redistribution. Decreased quotas remove local suffixes; unchanged surviving candidates keep their base transforms.
5. Prepare/cache receiver-local rows. Combine them with current face offsets for Brush coverage, then apply the existing ordered acceptance and publication. Projection and candidate Relax operate on the candidate's own receiver. Shared spacing and cleanup still evaluate their relationships.
6. Edit/radius binding receipts compare common generation settings and previously bound receiver geometry. Add/remove/reorder is allowed; missing receivers retain their receipt. Actual geometry changes remain a guarded generation change. Protected candidate requirements are admitted per receiver, including zero-quota suffixes.
7. Preserve bounded admission and atomic publication. Stable output is tested separately from cache reuse and viewport buffer reuse.

### What the calculation uses

The persistent receiver UUID seeds its random stream. A plant ID combines the saved receiver slot and that receiver's candidate ordinal; neither the object's name nor its current list position is used as identity. Triangle sampling is weighted by triangle area. For triangle vertices A, B and C, barycentric coordinates locate a point as `(1-u-v)A + uB + vC`; the face's geometric normal controls surface orientation. Face indices and barycentric coordinates are geometric anchors, not the persistent plant ID. Separate random channels select position, model, rotation and scale, so unrelated channel settings do not consume a shared random sequence.

### Limits and transition

The new sampler changes the first rebuild of scenes authored with the earlier combined sampler. This is not a bit-for-bit migration of earlier placements. Existing authored paint remains receiver-bound, but new candidates sample that paint. Earlier combined-sampler Edit identities and radius bindings must fail explicitly instead of silently attaching edits to different plants; authored edits are retained until the artist explicitly resets or restores the old matching build. Original scene files are never overwritten by qualification.

Adding a receiver must not move unchanged base candidates. Fixed Total/caps can reduce their number. Relax can move survivors when its own receiver quota or neighborhood changes. Shared collisions, cleanup, masks and protected edits can change acceptance. Geometry/topology edits are outside the unchanged-receiver promise. Face indices are not claimed to survive remeshing. Geometry hashing/area inspection may still touch unchanged meshes during Update; cached candidate reuse is not a claim of zero host geometry access or incremental GPU upload.

## Acceptance and evidence

- [x] Native 20→21 Density full transform/model/triangle/identity equality, Fixed Total survivor equality, reorder/remove, quotas/caps, retry scheduling and bounds.
- [x] Max 20→21 Density, Fixed Total, reorder/rename/remove/restore, cold recomputation and save/reopen.
- [x] Plane/sphere Paint Areas, fractional coverage, union and inactive target restoration.
- [x] Edit clones, protected suffixes, per-instance radii, missing receivers, bound-geometry guard and failed-successor retention. Arbitrary topology correspondence is not claimed.
- [x] Include/Exclude, source assignment, movement projection, Relax, cleanup and collision relationships in the focused and existing scripted fixtures.
- [x] Manual pending, Live relevant receiver changes, unchanged inspection/navigation and preparation/publication/upload counters.
- [x] Generated source checks, Python/native regressions, matched private Max payload identities.
- [x] Maintained architecture/artist/backlog documentation and final delivery report.

### Measured results

| Test | Final result |
| --- | --- |
| Density, 20 equal-area receivers → 21 | 10,000 → 10,500 plants; all original 10,000 stable IDs, full matrices and source models identical |
| Fixed Total, same receivers | 10,000 total; 9,524 unchanged original survivors and 476 plants on the new receiver |
| Receiver cache on append | One receiver prepared; twenty previous candidate caches reused |
| Seven warm synchronous appends | 97, 97, 96, 100, 287, 96, 97 ms; median **97 ms** |
| Receiver-specific Max checks | **51 assertions**, including cold recompute, save/reopen, Edit clones, protected zero-quota candidates, radius guards, same-name replacement, fractional curved/flat paint, Live scheduling and retained navigation counters |
| Native Release/Max 2027 SDK build | **15 native test executables passed**; receiver test contains **30,101 assertions** |
| Generated source / Python | Generated integration passes; **141 tests passed**; three package-version checks repeated successfully after installer help was updated |
| Wider Max regressions | Regions/views/reopen, retained Proxy, Update, Analyzer freshness, core acceptance, Manual/spacing, containers, Relax, Analyzer assignment, Edit persistence, exact output, texture invalidation and failure retention passed |
| Playback | **942 assertions passed**, including Scatter/Analyzer scheduling and retained display reuse |
| Corona geometry smoke | 100 cones, 320×240, one pass; publication/epoch preserved and Sphere Proxy helper remains nonrenderable; 1,599.6 ms render |

The append measurement includes scene API work, geometry hashing, candidate preparation, acceptance and publication. It is a warm small-mesh fixture, not a large-asset benchmark, presented FPS or an old/new speedup comparison. The 287 ms tail is retained in the data. Counts/caches and output equality are asserted independently. [RESULTS.json](RESULTS.json), [receiver checks](evidence/receiver-checks.txt), [timings](evidence/receiver-performance.txt), [full host campaign](evidence/campaign.json), [playback](evidence/result.txt), [native tests](evidence/native-tests.log) and [Python receipt](evidence/python-tests.xml) contain the recorded evidence.

### Failures found while developing the change

Earlier failures are retained as receipts, not counted as final passes. Initial lazy default-curve initialization changed the common key after baseline preparation; moving initialization before key capture fixed redundant old-receiver work. A spline fingerprint initially inspected Analyzer helpers as splines; limiting it to actual Spline Bands inputs fixed that failure. Final Relax controls are now explicit generation-key dependencies. Invalid/empty radius bindings and non-positive receiver area fail explicitly.

Fixture corrections included an illegal source weight of 2 (valid range 0–1), a Manual geometry test that read a cached snapshot instead of issuing Update, and MAXScript forward-global declarations when loading the new fixture before the older region fixture. The final paint and guard checks were rerun successfully against unchanged final product payloads. The report does not treat fixture errors as product defects.

### Reproduce and inspect

Use an owned disposable Max 2027 profile, never an artist session. The final native output is `build/receiver076/release-max2027`; its [SDK receipt](evidence/scatter-sdk-receipt.json) pins source and native hashes. The final private profile is `build/mcp-qualification/receiver076-release`; [launch.json](evidence/launch.json) pins the copied/loaded payload. The owned PID was verified and stopped after tests. Original courtyard SHA-256 remains `e0f32e1cd041c5e71ad5dc58877ddd493ce0eef7927ba0bc5fff96df3b0c9e32`.

The authoritative added fixture is [Max_Receiver_Stability_076.ms](../../tools/procedural_lab/Max_Receiver_Stability_076.ms); native allocation/identity witnesses are in [receiver_tests.cpp](../../AminScatter/tests/receiver_tests.cpp). The [saved launch script](scripts/launch-release.py), [focused driver](scripts/release-final-run.py), [extended driver](scripts/release-extended.py), [remaining guard/paint driver](scripts/final-extra.py), [regression driver](scripts/release-final-regression.py), [playback payload](scripts/playback.ms), [render payload](scripts/render_check.ms) and [package script](scripts/package.py) record the commands used. These are local campaign recipes with recorded build/profile paths: copy them to a new ignored run, select fresh output/profile paths, and verify matching source/native hashes before repeating. The launcher rejects an existing profile. Keep host mutations serialized. The regression driver adapts only historical fixture profile guards and the old 0.75 caption assertion to 0.76; feature assertions remain intact.

Run the generated check, MCP/tool pytest and native builder using the [agent workflow](../AGENT_WORKFLOW.md). The recorded native build uses Max 2027 SDK, MSVC 14.38.33130, Windows SDK 10.0.19041.0 and Release x64. Test transport is private MAXScript file dispatch; no public MCP authoring scope was enlarged.

### Delivery and remaining gates

Matching archives are [Scatter 0.76.0](../../dist/Receiver_Stability_0.76_2026-10-10/Max2027/CyrusScatter-0.76.0-Max2027.mzp) and [Analyzer 0.14](../../dist/Receiver_Stability_0.76_2026-10-10/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp). [PACKAGE.json](PACKAGE.json) records their hashes and confirms the runtime-tested script/native bytes are in the archives. Analyzer is unchanged. These local ignored archives are not included in a source Git push. Installer execution was not qualified and nothing was installed into the artist profile.

Read the **Limits and transition** section before upgrading an existing composition. B02 is closed only within this unchanged-receiver contract. The [current backlog](../BACKLOG.md) retains cold viewport realization, physical input/Brush latency, aggregate memory, the earlier intermittent display observation, geometry stress, Max 2026 runtime and broader artist/release acceptance. There is no new topology-preserving remesh feature, rest-pose animation policy, smooth-normal feature or incremental GPU-upload claim.

No computer use, normal-profile installation or vendor binary modification is part of this campaign. Website, `Landing Page Design/` and original scenes are excluded.
