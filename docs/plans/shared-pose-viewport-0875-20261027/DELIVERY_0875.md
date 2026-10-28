# CyrusScatter 0.87.5 — Max 2027 integration delivery

The standalone shared-geometry/compact-pose approach is integrated into the real
Scatter Mesh and Textured mesh paths. Existing CPU contact fitting and authored
preparation drive actual source polygons through public Nitrous graphics buffers.
Original source geometry, UV/opacity data and base instance streams remain shared;
movement updates nearby poses and a sparse transform table. No new artist GPU panel
or CUDA installation is required.

## Install and try

- MZP: `dist/CyrusScatter-0.87.5-20261027/CyrusScatter-0.87.5-Max2027.mzp`.
- Run **Scripting > Run Script**, select the MZP, then **restart Max**.
- Test scenes: `dist/CyrusScatter-0.87.5-20261027/TestScenes/` contains Grass,
  Fern and Authored interaction copies. Begin with Grass. Select the **Collider -
  sphere** layer's instance in **Cyrus Scatter Edit** and move it through the plant.
- [Artist guide](ARTIST_GUIDE_0875.md), [implementation](IMPLEMENTATION_0875.md),
  [plan and acceptance](PLAN.md), [machine-readable qualification](QUALIFICATION_0875.json).

These copies retain hidden models from the original test fixture and are larger
than an isolated plant asset. Original `Test Scene/` files were preserved. Saved
preview buffers rebuild on opening; source preparation is already stored.

Package SHA-256:
`97dcb3cb43dd40a6a7d1827087273e29eac23e554f36386c8f096bcc5f066dd8`.
Native interaction capability **12**, saved schema **63**, managed assembly
**0.87.5.0**. Recipe **9**, native Edit/storage **3**, prepared envelope **2** and
intent **1** preserve the preceding 0.87.4.4 work. Independently versioned products
are unchanged. This package is qualified only for **Max 2027**.

## What changed

The native packer records fixed/anchored corners, stem bindings, rigid followers,
basal smoothing and whole-triangle hiding. Shared graphics programs bind each
generation's immutable buffers at Draw time, so a failed successor can keep the
previous accepted result. Unchanged source types reuse their pose state while
another type changes. Completely hidden plants use a disabled-instance record,
including box previews; box-only realization uses a small binding buffer.

Source and pose reservations outlive retained graphics generations without holding
Max node watches. Node indices stay exactly representable and coordinates must be
finite floats. Source face addresses use shader uints. Existing memory/work limits
and viewport quotas remain explicit. The UI version, native guard, preparation
caption, Library and Gallery guards agree; three-part release labels normalize to
four-part managed assembly identities.

Preparation heuristics and the contact solver were deliberately preserved. The
large fern's initial 1 mm stem setting produced review errors; the existing 5 mm
minimum / 15 cm connection settings prepared it successfully. This is not a claim
that arbitrary imported plants now produce perfect automatic skeletons.

## Executed checks

The final package was installed into an owned disposable profile and loaded through
its automatic startup path. Native/script/module hashes, host guard and Gallery
identity were checked. The build verifies **622 source files** and passes **61/61
native tests**. Generated UI checks, focused capability-catalog tests and whitespace
checks pass. No artist profile was installed or restarted.

| Real source | Guides | Source triangles at 100% | Contact/geometry result |
| --- | ---: | ---: | --- |
| Grass Wild QMH | 451 | 27,501 | Natural contact and complete visible-mesh audit pass |
| Brainea Insignis fern | 3,087 | 593,787 | Natural contact and complete visible-mesh audit pass |
| Authored Neottopteris with fixed base | 46 | 183,030 | 4,710 fixed pieces retained; contact and Bake count match |

The production HLSL deformation math was compiled and read back on hardware with
the final native reference build. **2,412,954 corners** match canonical CPU geometry;
maximum source-space discrepancy is **1.3328e-7 m (0.00013328 mm)** and visibility
mismatches are **zero**. That is a numeric math check on an independent D3D11 device;
the real Max presentation checks are separate evidence.

Final Max checks cover direct pointer dragging through Cyrus Edit, movement/rest
restoration, mixed source types, unchanged camera activity, F3 Mesh/Textured mesh,
simultaneous wire/shaded views, independent hiding and box quotas, invalid-setting
retention/recovery, Undo/Redo, save/reopen, pending Manual amount edits, and the
Layers > Recipes button displaying all **96** library models. Undo's observed
world-float rounding is recorded in metres against a 2 micrometre tolerance.
CPU Bake triangle counts match the independent complete visible-mesh audit. No
production-renderer frame or arbitrary material graph acceptance is claimed.

## Paired movement measurements

Same final build, sources, seed, settings and 14-step path per case; only an owned
process diagnostic selects the old CPU triangle producer. RTX 3090 / Ryzen 5600X.
All source triangles are enabled for the comparison. Data sizes are decimal MB.

| Plants | Producer | Median native Edit callback, ms | Median first redraw command, ms | Rebuilt geometry sent over trace | Pose data sent over trace |
| ---: | --- | ---: | ---: | ---: | ---: |
| 200 | Earlier CPU triangle delivery | 69.808 | 29.742 | 104.510 MB | 0 |
| 200 | Shared GPU pose delivery | 55.923 | 19.081 | **0** | **3.407 MB** |
| 1,000 | Earlier CPU triangle delivery | 188.109 | 47.058 | 376.308 MB | 0 |
| 1,000 | Shared GPU pose delivery | 160.278 | 17.237 | **0** | **11.244 MB** |

For the 1,000-plant trace, pose bytes are about **97% smaller** than the preceding
rebuilt geometry. Source binding uploads are zero during the warmed traces; only
the moved collider's small transform stream also changes. Edit callbacks include
CPU contact fitting and publication preparation. Redraw timings are main-thread
command durations, not isolated GPU time or presented FPS. The harness suppresses
scripted idle sync only during the bounded native trace, then resumes/checks it;
event/presentation waits are recorded separately. A physical held-pointer test also
passed on the final installed pair.

## Limits and follow-up

The worst dense/deep test is a stress case, **not visual-quality acceptance**. Both
producers report the same maxima of 8 and 48 warned guides for the 200/1,000 cases.
The largest reported stem-edge ratio change is approximately 4.71 versus the 0.25
quality threshold. This existing CPU mapping/fit limitation is retained and visible;
the GPU path does not repair it or hide warnings. Natural single-model checks above
pass their full audits. Further work should diagnose absolute edge displacement,
improve constrained basal deformation and profile exact contact queries before
expanding GPU solving.

CPU fitting still dominates the deepest 1,000-plant trace (roughly 150–160 ms median).
This delivery does not promise millions of simultaneously bending plants at realtime
FPS. Visible polygon count, first preparation/upload, full audits and material
capture also cost time. Palette/material changes can still invalidate more source
display data than necessary; camera-only activity does not. Cross-layer source GPU
deduplication, sparse per-guide packing, broader culling/LOD and GPU collision remain
future measured work. Other GPUs, older Max hosts and production renderer frames
are unqualified by this delivery. Exposed-root trunk fitting remains on hold.

One early development profile reported an access violation during a source switch
followed by an immediate scripted edit before presentation was settled. Subsequent
fresh-profile source switches, final-package workflows and direct pointer tests pass;
this is not evidence of a diagnosed universal crash fix. The failed development
receipt remains in the owned run for reproduction if it recurs.

Evidence root: `build/interactions0875-20261027-01/`. Final producer:
`native-final-pair/`; installer: `installer-final-pair/`; loaded host:
`host-final-pair/`; HLSL math audit: `gpu-final-pair/`; exact report:
`qualification-final.json`. Preliminary builds/packages are not this delivery's
identity. Repository knowledge retrieval was stale at startup; current original
sources were inspected, and this work does not claim a refreshed knowledge corpus.
