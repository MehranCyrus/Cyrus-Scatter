# Open questions requiring local implementation evidence

These questions should drive the first experiments and comparison review. They are not requests for the artist to research SDK details.

| Priority | Question | Evidence needed | Current status |
|---|---|---|---|
| 1 | Which stage dominates real drag-to-present latency? | Revision-correlated CPU/GPU/presentation trace on small and dense scenes | No new full pipeline trace in this research |
| 1 | Can `SetBufferParameter` feed our shader with updated pose pages? | Owned Max 2027 sample, exact types/flags, visual/numeric checks | Public declaration verified; runtime untested |
| 1 | Can current `posePoint` semantics be reproduced with acceptable GPU precision? | Rest/posed frame, root smoothing, fixed/rigid/branch parity | Synthetic nlerp probe is insufficient |
| 1 | How will bent bounds, picking and Wireframe share the pose revision? | Source design plus multi-viewport/hit-test fixture | Proposed, not implemented |
| 1 | Is shader deformation enough to remove the measured bottleneck? | Before/after end-to-end trace at equal quality | Unknown |
| 2 | Is compact pose readback cheap enough for a future GPU fitter? | K/G-sized transfer experiment and Max buffer upload | Full-vertex round trip was measured; compact path was not |
| 2 | Is `ID3D11GraphicsWindow` available on our active Nitrous path? | Owned read-only runtime adapter query | Public declaration exists; legacy header prerequisite unresolved locally |
| 2 | Is there a documented compute-resource import/consumption path for retained draw? | Public SDK sample/vendor guidance plus runtime test | Not found in reviewed retained buffer interfaces |
| 2 | Does retained pose-map copying dominate at large history sizes? | K held fixed, many retained poses, CPU allocation/copy timing | Source shows copy; cost unmeasured |
| 2 | What root infeasibility policy is best for the current art workflow? | Fixture with fixed root inside collider; explicit hide/failure behavior | No universal bending-only solution |
| 2 | Which collider approximation is acceptable for exposed roots? | Authored/compound proxy versus exact geometry comparison | One cylinder is insufficient for the illustrated root flare |
| 3 | Is GPU mesh BVH or SDF fitting worth its complexity? | Query distribution, field construction/amortization, thin-feature error | Proposed alternatives |
| 3 | How many guide levels/contact buckets are typical in our library? | Preparation statistics across representative source families | Existing models available, not surveyed anew here |
| 3 | What lag policy feels best during continuous drag? | Strict-latest versus bounded-lag experiment; final release exact | Requires concurrency prototype |
| 3 | Can smaller VRAM cards/hybrid laptops run the chosen path? | Exact driver/adapter/budget matrix | Only RTX 3090 executed |
| 3 | What is final renderer/Bake parity for shader-driven preview? | Matching authoritative revision and material/geometry audit | Must remain a separate gate |

## Questions for external researchers

When their reports arrive, request precise answers where they differ:

1. Which **public Max 2027 method and resource type** connects their GPU output to retained rendering? A generic CUDA/D3D sample is not that answer.
2. Are their performance numbers executed, quoted from a paper, analytical, or proposed? What N/K/G/Q/P/V/T, hardware, transfer and presentation windows were used?
3. Does their solver preserve fixed roots and all relevant guides, handle broad leaf surfaces, and report infeasible/incomplete states without hiding geometry?
4. What becomes dense per instance? Include simultaneous generations, staging, lookup tables, normals, collider fields and CPU memory.
5. Is their proposed XPBD/dynamic solver a semantic change from rest-based static fitting? How are time, warm starts, Undo and final-state reproducibility defined?
6. What are the exact upstream pins, licenses and runtime requirements? Are they citing a current development branch or a tested stable release?

Do not resolve these by majority vote among AIs. Preserve each original, normalize claims, and choose the smallest experiment that distinguishes competing explanations. The [comparison protocol](../../comparison/README.md) records unresolved claims and the required deciding test.
