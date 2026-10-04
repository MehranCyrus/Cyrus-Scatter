# 08 — Validation plan and measurable acceptance

These are future implementation tests. Only source/documentation checks were performed while writing this package. Do not present this matrix as a passed campaign.

## Numerical contract tests

Use an independent exhaustive reference solver on small data and compare **accepted IDs**, classifications and conflicts with the accelerated implementation. Comparing counts alone can miss changed winners and identity corruption.

| ID | Fixture | Required result |
| --- | --- | --- |
| C01 | Same set, different sets, different layers | Exactly one applicable scope per pair; no double gap |
| C02 | Radii 0.20/0.30, multiplier 1, gap 0.10 | Distances below 0.60 reject; equality accepts |
| C03 | Multiplier zero with nonzero gap | Gap remains enforced |
| C04 | Independent self/sibling/layer values | Changing one scope leaves unrelated thresholds unchanged |
| C05 | Coincident, zero-radius and zero-gap inputs | Defined boundary semantics, finite work, no division by zero |
| C06 | Unequal radii, giant tree plus tiny grass | No broad-phase misses; collect cell/neighbor work, compare oracle |
| C07 | XY versus XYZ; stacked floors and thin shell | Documented metric behavior, no accidental geodesic claim |
| C08 | Negative/NaN/infinite values and extreme coordinates | Clear bounded validation failure before unsafe indexing |
| C09 | Protected-protected and protected-ordinary conflicts | Protected instances survive with diagnostics; ordinary rules remain valid |
| C10 | Externally rejected candidate next to another candidate | Rejected candidate never blocks the other |
| C11 | Ordinary scale, nonuniform scale, mirroring, shear | Radius follows the declared transform policy; no silent under-bound |
| C12 | Randomized small sets with multiple rules | Exhaustive/accelerated IDs and classifications match |

Extend [the existing group-spacing tests](../../AminScatter/tests/group_spacing_tests.cpp). Run the serial reference and eligible thread-count variants with the same inputs. Test insertion/order ties independently of hash-map iteration.

## Procedural integration fixtures

| ID | Scenario | Acceptance |
| --- | --- | --- |
| P01 | One layer with red, blue, yellow and grass sets | Sources/coverage stay independent; inherited versus overridden controls affect intended owners |
| P02 | Reorder sets and layers | Visible order equals ordinary precedence; IDs survive; one Undo restores the result |
| P03 | Equal weights and budget 500 | 167/167/166 before filtering; no unexplained final-count promise |
| P04 | Erase, disable and viewport-hide | Erase/disable release the appropriate occupancy; hiding changes display only |
| P05 | Coverage overlap without plant overlap; separated masks with near-boundary plants | Coverage policy and spacing policy remain independent |
| P06 | Early flower removed by union cleanup after blocking grass | Later layers see no ghost blocker; repair mode retries the grass candidate within its budget |
| P07 | Cleanup and refill repeatedly remove isolated candidates | Bounded stop, deterministic result, diagnostic; no infinite replay |
| P08 | Impossible accepted target, empty mask, zero set weight | Fast bounded completion/underfill with accurate reason |
| P09 | Raise target/attempt budget | Stable stream prefix under the declared version; no unexplained rebinding |
| P10 | Protected count greater than target | Preserve authored instances and report excess |
| P11 | Background between plants versus outside coverage | Gap case fills inside painted foreground holes; coverage-complement case reserves those areas |
| P12 | New higher-priority candidates during refill | Recheck affected lower output; final ordinary pair distances are valid |
| P13 | Point-only/empty source rows and source replacement | Slot/render counts and source policies are explicit; no lost ownership |
| P14 | Curved static receiver, sphere seam/pole and transformed receiver | Brush and instance anchors refer to the correct indexed surface snapshot |
| P15 | Topology/seed/distribution change with edits | Supported correspondence is preserved; unsupported bindings are reported, never assigned by compacted index |
| P16 | Include/exclude and density maps with final movement | Ordinary accepted positions satisfy the new policy's declared eligibility checks |

For refill, distinguish final validity from target attainment. Validate no forbidden ordinary overlap even when an attempt or repair limit is reached. Record unconsumed candidates and temporary cleanup suppression so underfill is explainable.

## Cache mutation and lifecycle tests

- Warm cache, then change one input from every row of [the invalidation matrix](05_CACHE_AND_VIEWPORT.md). Compare to a forced fresh evaluation and assert matching final output.
- Verify radius-only changes reuse candidate/coverage data; Brush edits reuse anchors; pure UI/display changes do not call placement generation.
- Verify disabled, empty, stale, failed and valid result states remain distinct.
- Test source/receiver deletion, Undo/Redo, layer/set copy/remove, rename, scene save/reopen/merge, time changes and external bitmap edits.
- Evict intermediate caches and reproduce the same final result. Measure temporary old/new-generation peak memory.
- Cancel or supersede a build during each expensive stage. Stale results must not replace the current generation.
- Inject preparation/solver/packet failures. Preserve the prior completed planting and report the failed owner/stage.
- Test scene closure and plugin UI teardown with pending work. No raw scene pointer may outlive its valid host context.
- Verify display/device recovery rebuilds appropriate resources without unexpectedly resampling planting.

## Viewport performance protocol

Use the same machine, Max/SDK binary, viewport dimensions, shading mode, camera path, source geometry, seed and accepted placement set when comparing drawing cost. Warm runs and first builds are separate tests. Capture loaded module paths/hashes; a successful build alone does not prove Max loaded it.

Test three comparisons separately:

1. **Old policy parity:** current baseline versus new build executing unchanged old policy.
2. **Evaluator overhead:** old/new architecture on equivalent normalized inputs, comparing accepted digests and update timings.
3. **New features:** independent scopes/refill on versus off, with candidate counts and resulting geometry reported so extra work is visible.

Proposed workloads: 1k, 20k, 100k and a controlled larger scene within configured caps; 1/3/many source assets; simple meshes and actual heavy vegetation; equal versus highly variable radii; sparse versus almost saturated coverage. Counts are experiment sizes, not promises that the current plugin accepts unlimited input.

Record:

- Build wall time and stage time; median and tail latency over repeated deterministic runs.
- Warm navigation median/p95/p99 frame time, displayed complexity and baseline scene-without-scatter timing.
- Candidate generation, coverage queries, source snapshots, packet builds and retained upload deltas.
- Draw/instance/sample counts, owned cache bytes, temporary peak bytes and observed process memory.
- Accepted count, rejection breakdown, fill shortfall and work limits.

Warm static orbit should add **zero placement generation, zero Brush evaluations and zero retained point/mesh uploads**. This is a direct architectural invariant. Proxy has a separate cached/batched path; assess its preparation and draw counters rather than requiring a retained-upload counter it does not use.

Choose a performance regression threshold after measuring baseline noise, and write it into the campaign configuration **before** reviewing candidate results. Do not turn one FPS screenshot into a universal performance claim. Frame time is easier to compare than subtracting FPS: 150 FPS is about 6.67 ms/frame, 80 FPS is 12.5 ms/frame, and 20 FPS is 50 ms/frame.

## Host, UI and output qualification

Pure numeric suites should compile/run for supported SDK toolchains. Runtime qualification must separately name Max versions actually exercised; Max 2027 evidence does not establish Max 2026 behavior. Test the install package and verify loaded binaries in a fresh isolated session.

Use disposable fixtures for Manual versus Live, rollouts/scrolling, set selection, Update, cancellation, artist overrides and Undo. Exercise renderer/Bake paths on the accepted output rather than display subsets. State which renderers were tested; do not generalize a Scanline fixture to all renderers.

For MCP, retain legacy schema tests and add new-policy parity, unsupported-field rejection, candidate/work limits, approval freshness, digest agreement, idempotency, transaction ownership, cancellation, Undo and actual export-count/transform validation.

## Suggested experiment sequence

| Experiment | Question | Decision from result |
| --- | --- | --- |
| E1: three-scope oracle | Does normalized rule classification preserve intended distances? | Approve P2 UI integration only after exact agreement |
| E2: cleanup-release fixture | Does bounded replay fill released holes without unstable work? | Select repair semantics/caps or simplify before rollout |
| E3: radius distribution sweep | Is the current uniform grid sufficient? | Add radius buckets only if neighbor visits dominate |
| E4: cache mutation matrix | Which stages really need rebuilding? | Replace broad invalidation only with verified narrow dependencies |
| E5: controlled navigation | Did the evaluator disturb display performance? | Preserve/revert display integration independently of solver features |
| E6: artist comparison | Can an artist explain counts, winner order and underfill? | Adjust labels/defaults before adding more advanced controls |

The final release report should attach source/build identities, raw results, failed cases and decisions. “Everything passed” without scope and artifacts is insufficient.
