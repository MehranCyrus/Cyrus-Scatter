# Physics Lab 0.1.8 — collision quality and model palette

18 October 2026. Standalone Lab only; Max 2027. Qualified for the scoped artist
testing below, with the stated fit, Freeze and physical-input limitations.
The 0.1.7 mountain report remains the preceding qualified delivery.

## Research and selected design

SideFX's [Convex Decomposition SOP](https://www.sidefx.com/docs/houdini/nodes/sop/convexdecomposition.html)
splits a mesh into approximate convex segments. Lower Max Concavity improves fit
by creating more segments; open surfaces need particular care, and reducing hull
vertices helps simulation cost. [RBD Packed Object](https://www.sidefx.com/docs/houdini/nodes/dop/rbdpackedobject.html)
uses a separate convex hull per connected piece within a compound rigid body.
These document a workflow, not Houdini's private implementation or a guarantee of parity.

Jolt's [compound shape documentation](https://jrouwe.github.io/JoltPhysics/class_static_compound_shape.html)
supports the Lab's existing collection of convex child shapes. Its name refers to
unchanging child topology; the resulting rigid body can move. A single convex hull
cannot retain a teapot handle opening regardless of vertex count. Full dynamic
triangle meshes are unsuitable here because the terrain is also a triangle mesh.

[V-HACD](https://github.com/kmammou/v-hacd) 4.1, pinned at
`f900e42361491f525262d4825e758845e4969897`, offers bounded voxel decomposition,
hull count/vertex budgets and shrink wrapping in a small BSD-3-Clause source.
It is archived and recommends [CoACD](https://github.com/SarahWeiii/CoACD).
CoACD's collision-aware error metric is attractive, but its full preprocessing
adds OpenVDB/Boost/zlib; the lightweight build omits that repair stage. This Lab
evaluates the pinned V-HACD backend with explicit limits and measured hole/fit
witnesses, rather than representing it as current upstream development. Revisit
CoACD before production integration. Neither quality setting is exact geometry.

## Ownership, bounds and failure contract before implementation

- Each persistent model slot owns enablement and quality settings. Disabling a
  model changes future births, retains existing bodies/material indices/settings,
  and never removes/reorders source slots. All disabled is allowed as an authored
  palette but Start rejects it. Pending sessions lock these edits.
- Fast preserves the existing one-hull path. Balanced/Detailed prepare compound
  hulls from copied numeric meshes; per-model piece cap is 1–16 and volume error
  0.1–10 percent. Volume error is a voxel/hull volume measure, not Houdini's distance
  concavity and not a millimetre fit guarantee. Thin/open leaves retain Fast;
  unsupported detailed inputs fail explicitly, with previous output retained.
- Capture/host publication stay on Max's thread. Decomposition owns numeric input,
  runs on a joined native worker, and never calls the Max SDK. Explicit preparation
  can wait; no decomposition during redraw, panel browsing or pointer sampling.
- Cache per model includes render geometry, policy and thickness; reuse requires
  identical captured geometry. Shape edits require explicit Rebuild/Clear before
  extending a completed result. Enablement alone does not invalidate old bodies.
- Bound voxel resolution/depth, input/output geometry, hulls and vertices. A
  cooperative timeout rejects slow preparation. It is not a hard process deadline
  or a guarantee against allocator failure in upstream code. Measure memory/time.
- Native authored option changes participate in Max Undo. Save/reopen and cloning
  retain them. Numeric cook caches are transient; result/recovery inputs retain
  the actual accepted hulls. Failed preparation cannot replace the published result.
- Shared geometry admission remains 200k source vertices/faces, live/output/history
  bounds and diagnostics remain unchanged. The source cache retains one prepared
  copy per slot; account for cache + prior result + tentative input, not just hulls.

## Acceptance planned

1. Native concave-hole collision witness: Fast blocks an empty opening; compound
   preserves it. Repeatability, convex/simple shapes, invalid inputs and bounds.
2. Actual copied mountain: original pyramid, Sphere32 and teapot, Fast/Balanced/
   Detailed and mixed checked palette; continuous strokes while moving, outside
   hits/reentry, Undo/Redo, Pause/Resume, Finish/Freeze and no interior loss.
3. Actual checked-list and quality handlers, narrow layouts at 100/150%, disabled
   palette/locked pending edits, saved settings, clone, source/material slot stability.
4. Save artist test scene with mountain and all three models/Lab setups. Reopen in
   a fresh exact-pair host; verify bindings/options/result and run another stroke.
5. Exact-pair MZP hash/integrity/license payload and isolated installed restart.
   Preserve original scene/profile and original diagnostics. No Computer Use.

Independent version 0.1.8 is the Lab delivery selected for the new per-model
collision/palette controls and rolling-hull correction. Main Scatter remains
0.86.0; registration identities and the Lab's wrapper schema 2 remain unchanged.
Authored model policies are appended native Document data; numeric hulls remain
in the existing input format. The plan sections above preserve the decisions
recorded before implementation.

## Implemented controls and ownership

The Models dropdown is replaced by a scrollable checked list. Checks control
future emission; the highlighted row targets collision settings. All, None and
Solo participate in native Max Undo. Disabling a model preserves its source slot,
material index, previous bodies and settings. Pending work locks these edits.
All unchecked is an allowed authored palette, but both UI and native Start reject it.

| Per-model option | Fast | Balanced | Detailed |
| --- | --- | --- | --- |
| Representation | One hull | Compound | Compound |
| Target voxels | None | 100,000 | 400,000 |
| Preset maximum pieces | 1 | 8 | 16 |
| Vertices per piece | Existing bounded path | 64 | 128 |
| Decomposition depth | None | 6 | 7 |

Max pieces is editable from 1–16; Volume error (%) from 0.1–10. Lower volume error
is a decomposition target, not a world-distance accuracy guarantee. Render mesh,
UVs, smoothing, source transforms/pivots and material correspondence are retained.
A face-plane convexity proof, bounded to four million point/plane tests, keeps
already convex solids at one hull. Exhausting the proof budget falls back to
decomposition rather than guessing that the object is convex.

Pick proxy remains the existing single-convex artist override. Automatic quality
is retained but inactive until Use auto. Neither a manual convex proxy nor adding
vertices to one hull can retain a concave opening. Nearly flat cards reject
compound mode; use Fast or a suitable volumetric custom proxy. Preparation creates
no scene nodes and modifies no source mesh.

The native Document owns up to 64 model policies and a transient source cache.
Cache equality includes captured geometry, UVs/smoothing, quality, piece count,
volume error and thickness. Enablement is excluded from the cook key. Total cache
render geometry is capped at 200k vertices/faces. Published, pending and Undo states
may retain additional copies: this cache limit is not a whole-process RAM bound.
Each source remains limited to 16 hulls, each with at most 256 points. Existing
body/contact/output/persistence limits remain, and more pieces can reach them earlier.

Capture/publication use Max's thread. V-HACD consumes numeric copies on a joined
native worker. After 25 seconds cancellation is requested and the worker is joined
before release. This is cooperative cancellation, not a hard deadline or an
allocator-failure guarantee. Explicit Start/Rebuild can wait. Redraw, panel browsing
and pointer sampling do not decompose geometry. The unchanged-source test measures
decomposition reuse; Jolt world/shape initialization is a separate cost.

Policies persist and clone with the native Document and participate in Max Undo.
Derived cook caches are transient. Completed and pending inputs retain their actual
hulls. Pending Resume still requires the exact solver fingerprint; cached Freeze
remains available without replay. Shape edits require explicit Rebuild/Clear before
extending a completed result. Enablement alone can change the next session.

The host API uses one-based model slots. `cplSourceOptions` returns enabled,
quality (0–2), maximum pieces, volume-error percent, last cached hull count and
the Document cook counter. `cplSetSourceOptions` changes that model's authored
quality; `cplSetEnabledSources` takes exactly one Boolean per source. Both native
edits own their Max Undo record and reject pending sessions. The public UI passes
only these bounded authored values; it does not transport collision vertices.

## Failures caught and corrected

1. Raycast filling failed the closed torus hole witness. Closed topology now uses
   flood fill; open input uses raycast fill. Both presets preserve the tested closed
   torus opening. This does not qualify arbitrary open surfaces.
2. The first host candidate split even the convex pyramid and sphere. The bounded
   convexity proof now preserves a single hull for them.
3. The matrix caught a MAXScript bad-free-thunk error in Solo's event-local
   comprehension. A bounded function now builds the mask without that capture.
4. Short preview/Freeze checks passed, but the longer replay lost large spheres
   inside the mountain. All 20,000 receiver triangles face upwards; no recorded
   departure preceded those losses. This was interior tunnelling, not ordinary edge
   rolling or evidence of a MAXScript heap failure.

Controlled variants are retained under
`build/physics-quality-018-20261018-01/sphere-experiments-01/`. Internal-edge removal,
default contact-cache settings and an 0.008 speculative-distance factor still lost
spheres. Larger speculative distances stopped those losses but increased teapot
penetration to about 18.9 mm in that experiment, so those variants were rejected.
Bounded convex rounding removed these reproductions without changing the world's
speculative-distance rule. The final rule also preserves thin hull cooking.

[Jolt's convex-hull settings](https://jrouwe.github.io/JoltPhysics/class_convex_hull_shape_settings.html)
describe shrinking the hull before applying its radius, so the outer envelope is
not inflated. The pinned source was inspected too. The final helper first cooks
with the old settings and reads twice the COM-centred inner radius. Inner diameters
at most `max(0.01 m, 4 × thickness)` retain the old cook. Other hulls use at most
10 mm radius and 1 mm approximation error in source space, bounded by inner
diameter and Jolt's constraints. Instance scale multiplies these values. This
criterion handles a tilted thin card better than an axis-aligned thickness test.

Physics and diagnostic preparation share this helper. Wires show cooked convex
outlines; the small rounded edge fillets are not tessellated. The captured failed
sphere schedule is now a native regression in
`CyrusPhysicsLab/tests/fixtures/rolling-sphere-mountain.json`, advancing 4,000 steps
after the final birth. The evidence supports a correction to the Lab's former
near-zero rounding configuration, not a claim of an upstream Jolt defect.

## Measured fit and remaining accuracy limits

The actual sources are the original 10.462-m tall pyramid, Sphere32 with 0.6-m
radius and a Max teapot with radius 1.2 m / eight segments. They contain 6, 482 and
2,082 source vertices. The receiver is the original 250 × 250-m / 20,000-triangle
mountain, captured in metres.

A fixed 40³ grid in each render bounding box measures the union of convex
outlines. This is sampled occupied volume, not an exact physical-volume or
percentage-accuracy measurement.

| Model | Fast pieces / occupied cells | Balanced | Detailed |
| --- | ---: | ---: | ---: |
| Pyramid | 1 / 21,360 | 1 / 21,360 | 1 / 21,360 |
| Sphere32 | 1 / 34,824 | 1 / 34,824 | 1 / 34,824 |
| Teapot | 1 / 41,120 | 8 / 21,992 | 16 / 15,482 |

Detailed occupies about **62.35% less sampled volume** than Fast for this teapot.
All render vertices pass the 0.5%-of-diagonal plane-envelope check; that check is
not a closest-surface distance metric. Convex models retain the previous outline.
Rounding introduces its separately bounded source-space approximation.

**The test teapot's handle opening remains filled at the 16-piece cap.** The
local point `(-1.3, 0, 1.0) m` lies about 192 mm from rendered triangles. Three
outward render ray probes have zero/zero/two crossings, yet all proxy modes contain
that point. Volume error 0.1% and flood/surface-only fill at the same budget did
not clear it. Evidence is retained under `teapot-hole/` and `fill-experiments/`.
The exterior is much tighter; complete concave-hole fidelity is still a separate
acceptance item. Higher piece counts or another backend need their own format,
resource and collision qualification. A single custom convex proxy cannot solve it.

## Qualification and interpretation

Six CTest suites cover core, continuous sessions, grip/terrain, collision bindings,
mountain/display and the new quality/hole/rolling regressions. Repeated per-step
or per-vertex assertions are measurements, not independent scenarios.

The Max matrix drives rollout handlers and the private numeric SDK Painter probe
on the copied mountain. It covers all nine model/quality combinations, continuous
strokes while bodies move, outside misses/re-entry, live Undo/Redo, pending edit
locks, warm decomposition reuse, completed result Undo/Redo, mixed activation,
All/None/Solo, option Undo and cloning. Nine single-model runs retain 90 accepted
bodies; the mixed result includes all three source slots. The probe sends no OS input.

All three Detailed cases attempted Finish, reached its finite 30-second /
3,600-step bound and explicitly used Freeze. Fast/Balanced were deliberately
Frozen sooner. These are frozen comparisons, not settled-result claims. Zero
grip can permit continued rolling; universal settling and zero penetration are
not acceptance claims of this delivery.

Fresh-process tests reopen the scene, verify flags/quality, compare cached preview
vertices across pending save/reopen, Resume, Undo/Redo, explicitly Rebuild changed
quality and reject flat-card preparation without replacing published rows. The
isolated installer stages the MZP, restarts Max and exercises the ready scene
through staged startup. The checked list's real managed child HWND is measured
separately from its empty static host. Bounds/font/overlap checks cover all seven
rollouts at 100% and 150%. Presented pixels, physical input, renderer diversity
and presented FPS remain outside these scripted tests.

Long native replays also cover both palette results, advancing 4,000 steps after
the final accepted birth. They record departures, whole-body tunnels and vertical/
local-normal vertex depths, with published and replay measurements kept separate.
For multi-session palette inputs this is Rebuild-style resimulation: formerly
frozen bodies become dynamic again. It is a robustness check, not byte-for-byte
parity with the original multi-session world. Host tests separately verify
continuation against completed frozen blockers.
An additional collector check incorrectly treated every immediate Frozen pose
as settled and failed: the early Balanced teapot snapshot measures **11.96 mm**
local-normal vertex depth (12.30 mm vertical), versus **5.70 mm** at the long-replay
endpoint. The measurement is preserved as a limitation. Freeze intentionally copies
moving poses; this delivery does not certify a 10-mm bound for arbitrary immediate
Freeze snapshots. The separate long-endpoint gate is 10 mm normal depth, and all
11 final endpoints pass it with a maximum of 5.70 mm. No solver parameter was
changed to conceal this snapshot result.
Exact receipts and final values are in [machine evidence](COLLISION_QUALITY_018_EVIDENCE.json).
Failed profiles, source/binaries and logs remain under `build/`; none are relabeled
as delivery passes. An owned PDB rewrite/link failure was repaired by preserving
that PDB and relinking. This was a build failure, not an artist-session crash.

## Artist handoff

Use [the testing guide](TEST_SCENE_018.md). Mountain-Test.max contains an empty,
selected `PhysicsLab_Brush_Ready`, the actual mountain and all three models enabled
in Detailed mode. Its icon radius is two metres and it sits above
the mountain for easy selection. Mountain-Results.max retains frozen comparisons.
Sources and other Labs are hidden in Scene Explorer. Native solid-colour materials
avoid external renderer dependencies for brushing.

The original artist scene was copied, not overwritten. The normal profile/session
and crash recording remain intact. Exit receipts verify normal exit and no captured
native exceptions in these runs, not that arbitrary crashes are impossible. Existing
recorder/watcher support remains, with new cook/policy events. This task contains
no artist installation, restart, Scatter integration, preset work, commit or push.

## Final receipts and delivery identity

Branch `codex/workflow-0.75`, HEAD
`e3e81a6d204063efd9b77771ad9b0268ad2ea578`, with pre-existing dirty/untracked work
preserved. The snapshot, build receipt, loaded pair and package identify this local
delivery; HEAD alone does not include the uncommitted Lab source.

| Evidence | Final result / location under repository root |
| --- | --- |
| Native | Six suites pass; `build/physics-quality-018-20261018-01/native-01/` |
| Full Max 2027 matrix | 281 checks; `build/physics-lab-quality-018-mountain-06/` |
| Fresh scene/pending/rebuild/failure retention | 6,477 assertions, mostly repeated vertex comparisons; `build/physics-lab-quality-018-reopen-02/` |
| 150% native and managed-list layout | Pass; `build/physics-lab-quality-018-list150-02/` |
| Installed startup and ready scene | 57 continuous checks plus 19 ready-scene checks; `build/physics-lab-quality-018-installed-02/` |
| Long replay | 11 inputs, zero departures/whole-body tunnels; `build/physics-quality-018-20261018-01/replay-04/` |
| Endpoint normal depth | Maximum 5.70 mm; published Frozen maximum 11.96 mm, kept as a separate limit |
| Source snapshot | `build/physics-quality-018-20261018-01/final-source-018.zip` |

All final direct runtime and installed restart receipts exit with code 0, zero
exception notifications and empty exception files. The initial installer-only
setup creates no Lab recorder; its setup completion is checked separately.
The fresh-scene fixture predates the last label/tooltip shortening only; the
collector verifies that exact difference. Full matrix/layout and installed
startup use the final short-label script. No other script difference is accepted.

Installer:
`dist/CyrusPhysicsLab-0.1.8-20261018-03/CyrusPhysicsLab-0.1.8-Max2027.mzp`

| Artifact | SHA-256 |
| --- | --- |
| MZP | `2c2dd289b62f633a6ed5d240ebb3271d766967d5f1365dd44b23c0ea51a36f12` |
| Native DLX | `91cbdba43a218a9e2028291298425a161eff96863ea363d6978d04a05151d026` |
| Storage DLH | `e9f3244f67b0822b71f87c9dd57cc9d5709a4977185f556d26c009c665aca6eb` |
| Crash Watch | `ccd8b799dd462d159b85e0541993a3c26ed864dcb4ffd7b679e4596265084474` |
| Ready Test scene | `0dba50cff610df279394dc36eefaca1f599656ea93d59e308087975771bc2a0b` |
| Frozen Results scene | `5ce096dadea987738fdb3c327f824eb64463fc4c9b57829fbfa545bb98f0d275` |
| Original artist scene, unchanged | `99ee36fd84f34995ca565aa27ad6292a5b83b46a24ea7cfbe92a7ab87315b28e` |

The archive passes CRC and every payload hash, includes the V-HACD BSD license,
guards Max 2027 and excludes private SDK/fault modules. Earlier `-01` and `-02`
MZP candidates are superseded; use `-03`. The machine collector is reproducible:

```powershell
python docs/Scatter_Physics_Research_2026-10-16/quality-fixtures/collect_evidence.py
```

Next acceptance is artist mouse/tablet testing in the supplied ready scene and
review of the remaining open-hole and immediate-Freeze overlap limits. Broader
shape/scale mixes, extreme dense contact workloads and another decomposition
backend need separate qualification before any main-plugin integration.
