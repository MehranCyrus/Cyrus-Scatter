# Scatter 0.86.8.7 repair and high-poly viewport delivery

23 October 2026. **Implemented and qualified for Max 2027 within the scope
below.** The final frozen producers, matched production/fault host runs and
exact installer packages passed. The [qualification receipt](QUALIFICATION_08687.json)
records 106 Max assertions and the package identities. Candidate04 and
earlier receipts remain evidence for their own bytes; the final receipt
does not silently inherit their test results.

## Scope and preservation

The user selected 0.86.8.7 and authorized implementation, delegated work,
testing and packaging after a Git backup. The approved
[R01–R07 repair plan](REVIEW_REMEDIATION_PLAN_20261023.md), its
[validation requirements](REVIEW_REMEDIATION_VALIDATION_20261023.md) and the
[high-poly Mesh plan](../viewport-memory/HIGH_POLY_MESH_PLAN_20261023.md)
define this delivery. A requirement or planned matrix row is not, by itself,
a passed test.

The scoped backup was committed and pushed as
`4185f29ca6c12bb115211be2f027977a80748ca8` on `codex/workflow-0.75`, with the
remote ref independently compared. Unrelated Arrange/Physics work, website
prototypes, private assets, scenes, SDKs and ignored installers were excluded
from that checkpoint. Local evidence below is ignored build output, not part
of the Git backup.

Original Paint is unchanged. Schema 59, recipe 8, registration identities,
ordered layers, source clearance, stable placement identity and pending
Manual edits remain the contracts. The memory preference is an installation
preference, not a new placement or recipe parameter. Analyzer's standalone
installer remains independently versioned at 0.14.2; its analysis algorithm
is outside this repair. New SDK and host qualification is for **Max 2027
only**. No artist profile is installed into, no artist session is restarted,
and no website publication is claimed.

## R01–R07 repairs

| Item | Repair and resulting behavior | Evidence and qualification boundary |
| --- | --- | --- |
| R01 — Boundary Relax image crash | Boundary traversal now uses the common `SurfaceDensity` sampling path. Native images take precedence over legacy arrays, and the supported coordinate, filter, curve and wrap behavior is shared. Positive sampled density is checked along the moved path. The original image case no longer dereferences an empty array. | The original white 2×2 image witness crashed the prior native implementation with `0xC0000005`; repaired image and array witnesses pass ASan. Exact ordered-output comparison covers unaffected cases. Correct rejection of a path through zero density is an intentional correction. This is not a rewrite of original Paint or a new randomness channel. |
| R02 — Analyzer MZP preservation | The standalone MZP delegates installation to the verified C# ownership transaction rather than replacing an arbitrary startup wrapper. Custom or unowned bytes cause an actionable refusal and remain intact. | Exact final-package owned Max checks passed custom-wrapper refusal, recognized migration/repeat/restart, analysis and stale-helper rejection. |
| R03 — interrupted backup recovery | Both installer paths use create-only, same-volume unique temporary backups, bounded snapshots, flushed writes, byte verification and atomic final publication without overwriting a different canonical backup. Legacy truncated backup artifacts are preserved while the new verified namespace permits a valid retry. | Transaction tests cover interruption, recovery, contention and conflicting bytes. The final03 EXE passed all 47 entry-point/handler assertions; archive and provenance checks passed. Process-kill testing is not proof of every power-loss or storage-failure ordering. |
| R04 — unsafe mesh access | The SDK adapter checks counts and storage before allocation or dereference, checks each face index before reading a vertex, and rejects non-finite positions/transforms. Source inspection and the re-evaluated mesh used by appearance preparation have corresponding guards. RAII retains converted-object cleanup on failure. | Production-body native malformed-storage/index cases and source inspection exercise the ordering. A deliberately malformed SDK `TriObject` has not been injected into a live Max scene; the plan's GEO-H01 host witness is not claimed as passed. |
| R05 — projected movement cost | A call-owned spatial index over copied/frozen eligible geometry replaces repeated exhaustive projection scans. Exact distance ties still choose the first eligible face. Existing Relax hint behavior, ordered results and random channels are preserved. Small or unused projections avoid the index. | Matched native parity and timing evidence is detailed below. A shared work allowance spans receivers, and live scratch is charged and released. Native timings do not establish viewport FPS or every dense-receiver host case in the broader plan. |
| R06 — build and package provenance | Frozen inputs now include selected licensing/trust inputs, shared managed producers, installer sources, configuration, selected SDK/toolchain and actual compiler dependencies. Missing or changed selected inputs prevent a complete receipt. Generated inputs are recorded at their proper generation boundary. Consumers validate the producer chain. | Clean SDK builds, negative input/tamper cases and package guards passed. After the Scatter MZP SHA/MVID guard changed a selected input, fresh producers and final host/package runs passed with the new identities. |
| R07 — ambiguous result JSON | Duplicate keys are rejected at every object depth before status or identity is trusted, including identical values and escaped-equivalent names. Existing bounded parsing, identity, terminal and exact assertion-ID requirements remain. | The focused duplicate-key suite passed 26 tests, included in the final 260-test Python suite. Final host acceptance uses strict request-bound parsing; historical receipts retain their original interpretation and limitations. |

Installer helper admission checks both the helper file SHA and the identity
of an already loaded assembly, including its MVID. A matching filename or
assembly caption alone does not establish that Max is invoking the packaged
helper. Final Analyzer I02 and Scatter I04 both passed stale-helper refusal
before profile changes, using their exact final03 packages.

## Projected movement parity and measured cost

The matched harness in
[parity-and-asan02](../../../build/native-remediation-08687-20261023/parity-and-asan02/result.json)
compared the checkpoint implementation with the repair under the same Max
2027 toolchain. All **50 full-scatter cases** produced byte-identical ordered
output: 2,763,112 bytes, SHA-256
`663409e0f24a75c5378cc98ce8981dd905177c67d0d11e74a9d1c40e6c848659`.
The original image and array crash witnesses both completed with ASan exit 0.

Matched three-run medians below include index construction and native
generation for 2,000 placements; they are not presented-frame measurements.

| Receiver triangles | Previous median | Repaired median | Speed ratio |
| ---: | ---: | ---: | ---: |
| 1,000 | 21.7624 ms | 1.8852 ms | 11.54× |
| 4,000 | 96.9484 ms | 2.9069 ms | 33.35× |
| 16,000 | 413.4380 ms | 8.9038 ms | 46.43× |

The separate
[calibration02 run](../../../build/native-remediation-08687-20261023/calibration02/result.json)
observed zero index builds for 1, 8 and 32 faces, and one build at 33 faces.
At 262,144 faces and 2,000 placements, projected generation took 160.674 ms,
used 5,247,000 bytes of index scratch and performed 16,024 exact triangle
tests after the build. At 16,000 faces and one million placements, it took
2,571.48 ms with 330,264 scratch bytes. These are finite calibration cases,
not a promise for arbitrary topology or placement counts.

One synchronous successor shares a 200,000,000-unit work allowance and a
256 MiB live-scratch allowance across receiver calls. Build comparisons,
query nodes and exact triangle checks consume the work budget, including
work on subsequently rejected candidates. The multiple-receiver exhaustion
case rejected at the shared work limit and ended with zero live scratch;
starting another receiver cannot reset that allowance.

## Viewport memory preference and admission policy

**Viewport & render > Viewport memory…** offers Automatic or Custom
**256–65,536 MiB**, with current native policy and usage readings. The value
is stored under the Max profile's PlugCFG directory in
`CyrusScatterViewport.ini` and applied process-wide across Scatter
controllers. It is not saved into scenes, layers, recipes or Undo records.

Changing the preference affects future resource admission. It does not solve
placements, evict current resources, clear history or automatically retry a
failed successor. Lowering the ceiling below retained usage can therefore
leave the current complete display visible while rejecting new allocations.
**Refresh display** explicitly retries from published placements and keeps
pending Manual placement edits pending. An artist's triangle/instance draw
limit may still intentionally select boxes; tests distinguish that choice
from resource-admission failure.

| Policy component | Current finite rule |
| --- | --- |
| Automatic Mesh total | With OS telemetry available, the smaller of one eighth of physical RAM and 8 GiB. |
| Custom Mesh total | The requested MiB ceiling, subject to the independent CPU and device checks below. It cannot override checked arithmetic, work bounds or OS headroom. |
| Device allowance | The smaller of the selected total and 2 GiB. This is an application fallback allowance, **not measured installed or available VRAM**. No adapter-zero assumption is used. |
| CPU admission | The smaller of available physical memory minus `max(512 MiB, total physical / 16)` and available commit minus 512 MiB. Missing OS telemetry rejects a CPU successor with a controlled diagnostic. |
| Concurrent pending CPU | Display and metadata reservations share a pending ledger. Memory not yet materialized is deducted once; committed memory is already reflected in the next OS sample. |
| Metadata inspection | A separate finite 32,000,000 inspected-face work bound and CPU conversion-estimate allowance of 4,096,000,000 bytes. The Custom display ceiling does not gate placement metadata or Auto Radius. |

The former fixed 256 MiB appearance, 512 MiB owner, 1 GiB Mesh process and
separate two-million-face ceilings no longer independently reject the
measured tree case. Mesh admission coordinates actual retained CPU/system
and device resources, preparation costs and genuine old/new overlap. The
existing Point Cloud allowance remains a separate retained-renderer
contract; these Mesh readings are not a total-memory meter for Max.

Physical SDK buffers and textures carry shared lifetime leases. Reused
handles are charged once to the process even when multiple render items or
history owners refer to them. Per-owner logical footprints can include
shared resources, so summing owner footprints is not a physical-memory
measurement. Reservations transfer with their resources, vector capacities
are accounted where retained, and `RealizeToHWMemory(true)` system copies
remain charged. Conservative upload-copy allowance stays with the lease
where the SDK exposes no completion fence. Old bundles, history pins and
SDK-held handles continue to count until their final owners release them.

The renderer remains instanced. Float UV streams, material textures, cutout
behavior, geometry signatures and Auto Radius semantics are preserved;
there is no half-precision UV conversion or replacement renderer in this
delivery. The metadata tests demonstrate that low display headroom does
not block bounded CPU metadata work when CPU headroom is sufficient, and
that inadequate CPU headroom rejects it.

`cyrusViewportMemoryStats`, `cyrusSourceGeometryMemoryStats` and
`cyrusRetainedPresentationStats` expose separate read-only policy, resource
and presentation information. Usage is an owned-resource estimate, not
process private bytes or free VRAM. A remembered last failure can remain
after recovery; visible/requested tickets and current readiness determine
the current state.

Host conversion remains a boundary: an opaque third-party `ConvertToType`
may allocate internally before exact counts are available. The native code
makes a bounded CPU reservation estimate, uses available counts where
possible and validates the returned mesh, but does not control that host
allocator. Neither the 32-million-face work limit nor the conversion
estimate certifies every mesh below that count as displayable.

## Actual high-poly baseline and measured successors

The exact .6 script/native pair reproduced the user's failure in an owned
Max 2027 profile. Private library originals were read without alteration.

| Source | Vertices | Triangles | Channel 1 UV vertices | Channel 1 map faces |
| --- | ---: | ---: | ---: | ---: |
| A097 Maple — Green Foliage | 1,109,209 | 1,640,630 | 1,314,579 | 1,640,630 |
| A098 Norway Maple — Red Foliage | 172,649 | 215,272 | 189,668 | 215,272 |

Both sources are Editable Mesh objects with Multi/Sub materials. Two green
placements at scale 0.02, Count 2 and seed 446 reproduced
`Viewport material resources exceed the appearance allowance`. The saved
baseline's full ordered placement fingerprint is
`e18803f36b34c12e4e23085c3cddb8bc2a3fcef7fd7d48d072ba1e7a143d703e`.
Its sources, transforms and settings are the comparison witness in
[baseline-host01](../../../build/remediation-08687-20261023/baseline-host01).

The machine had approximately 95.9 GiB physical RAM, initially about
62.3 GiB free physical and 55 GiB available commit. These are observations,
not minimum requirements or promised capacity. The adapter was described as
an RTX 3090; available VRAM was not measured. The initial process sampler
missed the actual conversion interval, so no process-conversion peak is
claimed. The peaks below are the native ledger's owned-resource peaks.

Candidate04's matched
[host07 evidence](../../../build/remediation-08687-20261023/host07) records:

| Case | Observed result | Resource or reuse evidence |
| --- | --- | --- |
| M04 — original tree failure | Exact .6 placement fingerprint retained; 3,281,260 full triangles, two instances, zero boxes, actual retained draw activity. | 895,976,810 live bytes: 598,302,714 CPU/system and 297,674,096 device. Owned peak 955,039,490 bytes; zero pending after completion. |
| M05 — source above two million faces | Constructed source has 2,400,000 actual faces and draws all of them. Idle/navigation retain full Mesh. Geometry modification changes its signature; numeric source/Auto Radius checks pass. | 604,807,141 live owned bytes. This is actual mesh topology, not a requested primitive segment count. |
| M06 — refusal and recovery | A 256 MiB custom limit rejects a successor while retaining the previous complete publication. Placement metadata and numeric Auto Radius remain independent of that display preference; recovery succeeds. | Diagnostics distinguish resource rejection from intentional artist draw caps and show pending reservations released. |
| M07 — aggregate sources and material refresh | Green, red and a distinct green source total 3,496,532 source triangles across three instances, all full Mesh. Material-only change commits a changed material key and a new complete visible ticket, preserving rows and epoch. | Geometry and transform upload deltas are both zero. Live bytes change from 1,912,313,551 to 1,925,650,567; peak 2,038,188,703. Scalar material replacement correctly performs no bitmap bake. |
| M08 — two owners and retained lifetime | Two controllers, old/new material generations, Manual Update, Undo/Redo, Live receiver dependencies, unrelated changes, save/reopen and delete/Undo pass seven assertions. Stable IDs and complete fingerprints survive the explicit file-unit round trip. | Owned peak 3,488,247,268 bytes includes real overlapping owners/history/SDK resources. After reopen, live bytes are 1,655,715,492: 1,064,561,604 CPU/system and 591,153,888 device, with zero pending. |

The larger lifecycle peak is intentional evidence of overlap, not an
estimate obtained by pretending the previous display is already freed.
Releasing history pins reduces usage; retained SDK handles and Undo pins
may keep old physical allocations alive after a controller changes.

The raw baseline was created by merging a library `source.max`, which does
not perform Gallery texture relinking. The bounded fixture now resolves
the same nine private texture paths through the catalog mapping used by
Gallery, clones material graphs in the disposable scene and records the
resolved paths and input hashes. Original library files, source materials
and baseline file bytes remain unchanged. Early black/stipple screenshots
were therefore not accepted as material/cutout parity. The final suite must
retain both the actual-tree path-resolution proof and the controlled pixel
oracle below.

## Complete presentation, reuse and float material baking

CPU publication alone is insufficient when Nitrous realizes buffers later.
The host now stages a complete render bundle and keeps the last ready
bundle until every successor item has realized. Workers consume copied
resources and do not read scene APIs. Realization checks all sibling items,
including items not currently visible through culling; host publication
then switches the complete generation at one boundary.

A late texture, UV or later-group buffer failure therefore retains the old
ready image and visible ticket. It does not partially draw the successor or
mark requested content as visible. Same-input explicit retry remains
eligible; idle redraw does not loop the failed preparation. Rapid
replacement keeps the latest candidate, hide/delete/reset gates stop
presentation, and resources remain charged for any surviving SDK/history
owners. Marker suppression uses the retained visible state rather than
assuming a failed requested generation has no display.

Material refresh can create a new snapshot wrapper without changing any
instance. Buffer reuse now checks the complete ordered matrix payload and
Band correspondence exactly, rather than requiring wrapper identity. When
several previous groups have identical geometry but different matrices,
selection prefers the compatible corresponding logical group, then an
exact ordered instance match among geometry-compatible groups. Geometry,
material and appearance compatibility checks remain in force. Tests of the
production helper cover identical, reordered, transformed and Band-changed cases,
including two same-geometry groups with different matrices. This preserves
the same physical instance-buffer lease when reuse is valid.

The controlled leaf test also found a separate CPU baking defect. The
filtered float `RenderBitmap` path produced biased black/white
values and did not preserve the tested UV/output controls. Zero-filling
the bitmap did not correct it. The narrow change uses the host
`Interface::RenderTexmap` path with the existing float tile and filtering
policy. SDK probes agreed with the raw `renderMap` oracle for scalar/color,
sRGB leaf and tiling/offset/invert cases.

Candidate04 M11 then passed the actual viewport pixel oracle: the raw
128×128 mask had 7,984 opaque pixels out of 16,384 (48.7305%); visible green
cutout coverage was 16,166 / 32,990 (49.0027%). The 256×256 native probe had
31,936 opaque pixels out of 65,536 (48.7305%). Red-to-green and cutout
successors kept geometry uploads at 1,512 bytes and transform uploads at
48 bytes, preserved placement fingerprint/epoch and left Manual Count 7
pending while one published placement remained displayed. See
[retained-regression-evidence.txt](../../../build/remediation-08687-20261023/host07/retained-regression-evidence.txt)
and its input/viewport PNGs. This qualifies those controlled material and
cutout paths, not all materials, proxies or renderers.

The separate `NEVER_SHIP` fault build passed **16 assertions** across F01,
F02 and F03 in
[fault03](../../../build/mcp-qualification/foundation-spline-remediation08687-fault03):
initial failure/retry and lifecycle, texture/UV failure with a prior image,
second-group realization failure without partial display, and failure plus
recovery on the actual 3.28-million-triangle tree display. The tree fault
retained the previous image/ticket/fingerprint and recovered without
geometry or transform re-upload. These are injected resource failures,
not a claim of recovery from genuine device loss. Fault primitives and
development markers must be absent from the production package; F00 and
archive guards repeat that check for the final payload.

## Qualification ledger and final identities

The later installer-helper guard changed selected producer inputs. Fresh
`scatter05`, `scatter-fault04` and `analyzer02` producers were built and
tested, followed by matched host and final03 package checks. All rows below
refer to that final input set; earlier candidates retain separate receipts.

| Gate | Final evidence | Result |
| --- | --- | --- |
| Generated source | `generated-final/generated-check.json`; generated script identity matches the final package. | 333 controls passed; this alone is not physical UI acceptance. |
| Production native | `scatter05/receipt.json`; clean Max 2027 SDK build, complete v2 input manifest. | 53/53 CTest passed. |
| Fault native | `scatter-fault04/receipt.json`; isolated `NEVER_SHIP` build. | 53/53 CTest passed; fault payload excluded from shipping archives. |
| Analyzer native | `analyzer02/receipt.json`; clean Max 2027 SDK build. | 1/1 CTest passed. |
| Python | `python-tests-final.txt`. | 260 passed in 64.02 seconds. |
| Production Max | `host08`; exact final production payload. | 17 scenarios / 71 assertions passed, including Gallery, real Mesh/materials, lifecycle, resource refusal and production fault-hook absence. |
| Fault Max | `foundation-spline-remediation08687-fault04`; bound run `64a68de686e74384b9412c00e2f29224`. | Three scenarios / 16 assertions passed. The corrected predecessor-ticket wait and earlier failure are explained below. |
| Installer Max | `installer-host02`, `installer-stale02`, `installer-scatter-stale01`; exact final03 archives. | Four scenarios / 19 assertions passed: 12 + 2 + 3 + 2. |
| Combined EXE | `build/r867e06/receipt.json`; actual final EXE Install/Update handler. | 47/47 assertions passed, separately from Max-host totals. |
| Transaction and backup suite | `build/r867i/8db68239/checks.log`; same frozen qualified installer core. | 283 assertions, ten process-kill/retry cases and seven real-archive migrations passed. |
| Final packages | `final-packages03-audit.json` and `final-dist03-audit.json`. | Archive integrity, selected host/version and helper guards, producer dependencies, exact EXE embedded resources, production fault-marker exclusion and all 31 distribution copies passed. |

The final Max total is **106 assertions**: 71 production, 16 fault and 19
installer. Native, Python, generated-control and EXE assertions are separate
counts. The [tracked qualification receipt](QUALIFICATION_08687.json) is an
exact copy of the local
[final aggregate](../../../build/remediation-08687-20261023/FINAL_QUALIFICATION.json),
SHA-256 `29268048880154536f63fa2b7463bd372d08564b55dd71a4a271f262023d2c21`.
It binds request IDs, fixture hashes, original host qualification identities,
results, producers and packages. Raw scenes, logs and binaries remain local
ignored artifacts; this compact receipt does not make them part of Git.

Final production payload SHA-256 identities:

| Payload | SHA-256 |
| --- | --- |
| `AminScatter.dlx` | `6351b7410eb157bd6706a5c2d439f571f96f1884f16a136fa5d21a0c40aff817` |
| `CyrusScatter.ms` | `4d1e117a1f7d89f03a72671f55f7fbeb02895c585da1cca03d57e59fd13218cb` |
| `CyrusSurfaceAnalyzer.dlx` | `ddf00daa18fbb186ed1275e8367a4d93714762d0429cab90486dc412316f04aa` |
| `CyrusSurfaceAnalyzer.ms` | `256ec6a25176417d2d45ec7f7ef1262ca3ffec1332f57965c77df7883a56ae69` |
| `CyrusInstaller.dll` | `6c25fbbd1166255a8fcc3b4108379d9c91f216c72a4cd0268273d4231fce5a0a` |
| `CyrusGallery.dll` | `61b85ff35de28d5b809845a950b8db4835012a78090adfed56a57575bd85155e` |

The distribution is
[dist/CyrusScatter-0.86.8.7-20261023](../../../dist/CyrusScatter-0.86.8.7-20261023).
Final artifact hashes are:

| Artifact | SHA-256 |
| --- | --- |
| `CyrusScatter-0.86.8.7-Setup.exe` | `e8082a9d3e71189851ceb81f90197e90376f146cf6a9d350f1962bc8cbf9942f` |
| `CyrusScatter-0.86.8.7-Max2027.mzp` | `a7a504ab0db219dc90c72c7f3804d5bca0710cff6550b9c3c24a8119b9f257ac` |
| `CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp` | `825da3d659520c91227fd21dd5844cf41b59add0728fa86f62dd0af175542aeb` |

Close Max, run the EXE, select Max 2027 and use **Install / Update**, then
reopen Max. The EXE includes Analyzer 0.14.2; existing content revision
0.86.7 is reused. Alternatively, use **Scripting > Run Script**, select the
matching MZP, then restart Max as instructed. Both MZPs reject an incompatible
already loaded installer helper before changing the profile. All owned test
sessions were closed; no artist profile or running artist session was changed.

## Failed candidates, fixture corrections and remaining limits

The retained logs explain why each successor was necessary. Candidate01
established the real-tree full Mesh improvement but exposed late-realization
retention and material-refresh transform reuse gaps. Candidate02 added the
complete presentation barrier. Candidate03 removed snapshot-wrapper
identity from exact instance reuse, but F02 still exposed selection of the
wrong previous same-geometry group. Candidate04 corrected that selection
and the float material bake; its targeted positive and injected-failure
successors passed. A passing later candidate does not erase these failed
records.

Several fixture failures also required correction rather than a product
workaround:

- The first dense primitive fixture hit Max's segment clamp. It was replaced
  with a mesh whose measured topology is actually 2,400,000 faces.
- Quiet scene loading without `useFileUnits:true` adopted the current reset
  units and rescaled the centimeter baseline by ten. The owned baseline and
  reopen fixtures now explicitly adopt file units and log units before
  save/reopen. Candidate04 M08 preserves exact coordinates and fingerprints.
  This does not change or newly qualify the product's unit-rescale contract.
- A scalar Standard material replacement has no Texmap to bake. M07 now
  requires the changed material key in committed display identity, a new
  complete visible revision, unchanged rows/epoch and unchanged streams;
  it does not incorrectly demand an increment in bitmap-bake count.
- Gallery can reuse its rollout definition object across open/close. The
  reopened-dialog oracle uses the fresh session UUID and valid owner
  binding, rather than definition-object inequality. M12's seven assertions
  passed on candidate04 and again on the final matched host08 payload.
- Directly merged tree materials needed the same catalog texture resolution
  as Gallery. Relinking the disposable test copies and auditing original
  files was separate from the native float-bake correction.
- The initial Python catalog test expected 332 controls; the authorized
  memory button made the generated total 333. That old failed run remains
  an intermediate result, not a passing full-suite receipt.
- Final fault04's first F02 wait rejected the already-failed ticket 2 before
  its explicit refresh published ticket 3. A
  [read-only observer](../../../build/mcp-qualification/foundation-spline-remediation08687-fault04/observe-f02-a9b64c94895a41fa97785c7b3d182b6d.txt)
  then found ticket 3 completely ready, unchanged geometry/transform uploads
  and pending Manual Count intact, without issuing refresh, publish, redraw
  or scene mutation. A failed native generation cannot become ready again;
  this was the predecessor being observed during deferred publication.
  The fixture now records the failed ticket before explicit refresh and
  tolerates only that predecessor within the existing 20-second deadline;
  any new failed ticket still rejects immediately. No product change was
  made. Rebound run `64a68de686e74384b9412c00e2f29224` passed F01/F02/F03,
  **16/16 assertions**, including the exact high-poly failure/recovery case.

Current evidence is bounded to the named Max 2027 profiles, controlled
materials, measured sources and resource failures. It does not establish
every roadmap validation row, malformed SDK-object host injection, genuine
device-loss recovery, all renderer/proxy combinations, all-control physical
UI/DPI behavior, sustained long-session reliability, or universal high-poly
capacity. Owned-resource accounting is not an allocator-wide cap over Max
or third-party conversion. Native projection speedups are not FPS claims.

The recorded scoped qualification is complete. Wider acceptance above stays
open and is not implied by this patch. The maintained source documentation
is updated, but the live knowledge index is still stale: the final full
source check found 31 of 48 enrolled sources fresh and 17 changed. No new
index was activated; a reviewed knowledge refresh remains separate work.
