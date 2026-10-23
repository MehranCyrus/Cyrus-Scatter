# One million real library leaves — viewport investigation

21 October 2026. **Measurements on the shipped 0.86.8.2 build in Max 2027;
no product code, installer or version change.**

## Finding

There is further viewport optimization opportunity. In this fixture the expensive
full-detail case is dominated by GPU geometry processing. Orbiting does **not**
regenerate the million placements, repeat acceptance, prepare new source geometry,
upload transforms or rebake textures. The existing retained resources are doing
useful work.

The three sources contribute **171,909,804 triangles** when all one million
placements are submitted. Full-detail GPU work is approximately **51 ms per
present**, compared with **2.7 ms** for the default navigation subset. Close-up
views continue submitting the broad source groups. Spatially smaller render items
and distance-dependent source detail are the strongest next candidates; their
benefits and implementation costs still need a prototype and comparison.

## Identity and scene

- Git `3d387550cacf37fe1aeae7a01455f7644d9cf08b`, branch
  `codex/workflow-0.75`; pre-existing Physics Lab, website and knowledge work
  was present and was not part of the test.
- All **479 qualified build source hashes**, the generated script and all
  staged native modules match the existing Max 2027 receipt at
  `build/clearance-relax-08682-20261021/max2027/receipt.json`.
- Script SHA-256:
  `c56cee163dbd0a0fffb700c390d0142d0e8ea8df4d8b0e34f31eef98f8180ac5`.
  Runtime fingerprint:
  `0e133e4d2f87c3948940ae5837520ffca51cccb7b1bbcfe1217baec5a9977937`.
- Private Max 2027 PID **25740**, redirected profile under
  `build/mcp-qualification/million-leaves-08682-20261021-01-2027/`.
  The pre-existing artist PID 32088 received no commands. The connector was
  unavailable; the repository's private launcher/transport was used.
- Ryzen 5 5600X, 6 cores / 12 logical processors; approximately 96 GiB RAM;
  RTX 3090, **24,576 MiB** GPU memory. GPU identity is from `nvidia-smi`, not
  the truncated Windows `AdapterRAM` field. Viewport **1094 × 750** pixels.
- Installed shared content **0.86.7** was reused in place. Imports use the actual
  catalog and `CyrusModelMerge`, retaining the prepared Corona materials/maps.
  Original library model hashes match after testing.

| Library source | Source triangles | Accepted copies | Full-detail triangles |
| --- | ---: | ---: | ---: |
| A006 — Leaf 06, Broadleaf, Bright Green | 114 | 333,279 | 37,993,806 |
| A007 — Leaf 07, Curled Leaf, Dry Brown | 400 | 333,122 | 133,248,800 |
| A012 — Sycamore Leaf 04, Mottled Autumn | 2 | 333,599 | 667,198 |
| Total | 516 unique source triangles | **1,000,000** | **171,909,804** |

One layer scatters onto a 100 m × 100 m plane, in centimetres, with equal source
weights. Spacing, cleanup and both Relax modes are disabled so exactly one million
candidates are accepted. Sources and receiver are hidden from ordinary viewport
drawing. The native scattered preview remains visible. Automatic final rendering
is disabled for this viewport test.

The saved scene is:

`build/mcp-qualification/million-leaves-08682-20261021-01-2027/Million Real Library Leaves - 0.86.8.2.max`

It contains procedural settings and three real source models, rather than one
million separate Max nodes. It was saved with the normal 500,000 navigation /
2,000,000 idle triangle limits, Textured mesh and all three weights restored.
Reopening in the private host reconstructs **1,000,000** placements with the same
complete native publication fingerprint and no preview error. Open/evaluate/display
took 13.41 seconds in that witness; this includes scene loading and reconstruction,
not just calculation. The first million-placement solve took 2.93 seconds.

## Method and recorded scope

Evidence root: `build/million-leaves-08682-20261021-01/`.
Host outputs: `build/mcp-qualification/million-leaves-08682-20261021-01-2027/`.

**52 cases / 3,990 scripted orbit steps** cover hidden preview, Point Cloud,
Proxy, colored Mesh and Textured mesh; default, intermediate and unlimited
budgets; wide and close cameras; selected and unselected controller; 100,000 and
1,000,000 accepted placements; and source isolation by weights.

The first `matrix01` run inherited Wireframe and is explicitly preliminary.
`shaded01`, `matrix02`, `matrix03` and `matrix04` explicitly set
`smoothhighlights` (Default Shading). Earlier batches update an owned camera
node; `matrix04` computes the same kind of orbit directly as view matrices,
without changing a scene node. Normal `redrawViews` and `completeRedraw` were
both tested. Results are kept by case and are not pooled as interchangeable
trials. Raw samples, not just medians, are retained.

Each timed loop records native counters before and after. A bounded diagnostic
session independently records zero calls to extraction, generation, masks,
radii, spacing, preview preparation, upload, publication and map baking during
its navigation window. All 52 cases preserve epoch, prepared/receiver builds,
accepted count, geometry/transform/owner upload counters and material bake count.

Signed Intel **PresentMon 2.6.0** records DXGI events for the owned PID only.
QPC-aligned phase windows select the dominant swap chain. Whole-host CPU/private
memory and periodic whole-device NVIDIA counters are separate records. Each
trace session was stopped by its unique owned session name and exited cleanly.

## Representative shaded results

The table below uses the final `matrix04` driver. Each row retains exactly one
million accepted placements. The source-only rows are diagnostic weight changes
in the disposable scene; the library files are not edited.

| Case | Submitted triangles per pass | Orbit step median / p95 | GPU busy per present, median |
| --- | ---: | ---: | ---: |
| Preview hidden | 0 | 32.00 / 66.15 ms | 4.11 ms |
| Three leaves, default Textured mesh navigation | 500,000 | 32.40 / 74.09 ms | 2.70 ms |
| Three leaves, full million, unlimited triangles | 171,909,804 | 110.16 / 134.09 ms | 50.89 ms |
| A007 only, full million | 400,000,000 | 250.25 / 257.53 ms | 116.76 ms |
| A006 only, full million | 114,000,000 | 77.94 / 89.84 ms | 35.22 ms |
| A012 only, full million | 2,000,000 | 31.96 / 65.75 ms | 2.48 ms |

The hidden baseline is already approximately 32 ms per scripted step. Lower
detail caps do not automatically improve this host/compositor/message-processing
floor. Do not subtract independently sampled medians as an exact plugin cost.
Default selected/unselected medians differed (46.23 / 32.04 ms), but similar
variation exists among unselected repeats; this does not establish a selection
regression.

The close-camera full-detail shaded witness (`matrix03`) took 109.25 ms per
step and 45.88 ms median GPU busy, versus 110.73 ms / 49.72 ms for its wide
repeat. Both retain all 171.9 million submitted triangles despite the much
smaller visible part of the field. Colored Mesh was similarly expensive at full
detail (110.05 ms close-camera step). Colored Mesh also retains supported opacity;
this is not an opacity-disabled shader comparison.

**Accepted count is not drawn count.** The default 500,000 navigation triangle
budget apportions approximately 85,400 instances in this fixture: 1,461 A006,
416 A007 and 83,523 A012. These per-source counts are derived from the inspected
`viewportQuotas` algorithm and verified to reproduce the native triangle plan;
the telemetry directly reports triangles, not those instance counts. The idle
2,000,000-triangle plan draws approximately 341,034 instances. A request for a
million point-preview samples admitted only 587,202 in the point-budget witness;
resource bounds remain separate from the Amount setting.

Sampled whole-host private memory peaked at **5.92 GiB**, including Max, plug-ins,
materials and allocator history. The final pre-reopen native mesh resource
reservation was 448,126,880 bytes (427.4 MiB), including conservative CPU/SDK/GPU
allowances. Neither metric is exclusive live VRAM. Whole-device GPU memory samples
peaked at 8,387 MiB and include other applications.

## Source interpretation and next work

1. **Retain existing instancing and cached source/material resources.**
   `AminScatter/src/mesh_display.inc:185` builds one instance stream per group;
   `:271` issues `DrawInstanced`. There is no CPU loop copying every source
   triangle for every placement. Navigation counters confirm reuse. Instancing
   reduces duplicated storage and submission work, but the GPU still processes
   the submitted triangles for every instance.
2. **Prototype spatially smaller native render groups.**
   `AminScatter/src/point_publication.inc:26` creates items per source group with
   that group's bounds; `AminScatter/src/point_display.cpp:427` gives those bounds
   to Nitrous. Existing item-level culling is real. Three source groups spanning
   the entire field provide coarse culling, however. Native spatial chunks could
   allow off-camera parts to be culled, with a measured draw-call/bounds/memory
   tradeoff. This is a source-supported opportunity, not a measured speedup.
3. **Prototype source detail based on projected size/distance.** A007 contributes
   approximately 77.5% of the mixed field's full-detail triangles. It remains
   expensive when visually tiny. Prepared lower-detail source geometry or a
   suitable far representation could preserve visible population better than
   simply dropping most instances. Preserve silhouette, UV/material mapping and
   leaf cutouts; qualify transitions. Do not destructively simplify the library.
4. **Keep explicit adaptive navigation limits and expose what is drawn.**
   `AminScatter/include/viewport_policy.h` already provides distinct idle and
   navigation budgets. Improve their artist feedback and investigate camera-aware
   admission while retaining deterministic stable subsets. The fixture's cheap
   two-triangle source consumes much of the remaining quota; a future policy
   should evaluate visual balance as well as throughput.
5. **Measure shader/vertex work after culling/detail prototypes.** Current streams
   expand source face corners and use no index buffer in this path. Revisit vertex
   processing only with exact attribute/UV/opacity preservation and a benchmark;
   this investigation does not prove an indexed representation will improve it.

The earlier ordinary-Update audit remains relevant to solve/preparation time.
Those improvements cannot remove the measured 171.9-million-triangle GPU cost
of this unchanged full-detail navigation case.

Any follow-up should retain the same frozen scene, compare cold/warm costs,
record native solves/preparation/uploads separately, test close and wide views,
and preserve complete placements/render output. Declare chunk ownership,
invalidation, peak retained memory, failure publication and Undo before coding.
Do not change the one-million acceptance limit as part of a viewport prototype.

## Evidence, limits and preservation

- `summary.json` / `summary.csv`: phase summaries and links to original cases.
- `*-presentmon.csv`: raw, PID-filtered DXGI events; `*-resources.jsonl`:
  sampled process/device observations; `*-receipt.json`: serialized case order.
- `source-identity.json`, `assets.json`, `machine-*`, `evidence-manifest.json`:
  loaded/staged/source inputs, machine facts and output SHA-256 values.
- Host `inspection.json`, `reopen.json`, per-case JSON and PNGs, plus
  `matrix02-1m-texture-default-diag-diagnostics.json`: count/identity/reuse witnesses.
- `driver.py`, `setup.ms`, `run_case.py`, `matrix.py`, `inspect.py`, `reopen.py`,
  `analyze.py`, `seal.py`: local test drivers. Build/profile/asset paths are explicit;
  they require this local owned fixture and are not public product APIs.

Orbit-step timing includes view changes, redraw and posted messages; shaded Max
often produces approximately two presents for one scripted step. Its reciprocal
is **not presented FPS**. PresentMon GPU work is whole-host frame work, not a
GPU hardware performance-counter attribution to one shader. Available display
intervals/latencies and missing rows are retained separately. This is one
workstation/viewport, under concurrent desktop activity, with no calibrated
mouse-to-photon, 4K, multi-monitor, renderer or other-host qualification.

One million did not exceed the existing candidate bound. This test does not
qualify larger populations or universal memory reliability. No extra layer,
spacing/Relax stress or long-session soak is claimed here.

All product source/native identities and original library model bytes match.
No installation or commands in the existing artist Max session were performed.
The normal Max INI **did change during the overlapping run**, so byte-for-byte
profile preservation is not claimed. `profile-observation.json` records both
hashes and the comparison with the redirected private INI; beyond redirected
directories, differing keys were render-output history and render-dialog position.
The writer/cause is undetermined while the artist session remained running. The
test did not restore or overwrite that current file. This limitation is retained
in the evidence seal rather than treating its initial equality failure as a pass.

The private Max session is left open with the saved, reopened, default-budget
three-leaf test scene for inspection. Reports/raw scenes remain local; there is
no new installer, version bump, commit, push or knowledge-index activation.
