# 01 Findings and recommendation

**Status: research synthesis and proposed scope.** Source families: R01-R04 engineering studies, R08/R11 preparation studies, R09/R10 practical workflows and R12-R14 solver-reuse research. The final supplied study is included; all fourteen original files are preserved. See the [source register](sources/README.md) and [corrections](09-EVIDENCE-AND-OPEN-QUESTIONS.md).

## Feasibility

The original idea is technically plausible: keep grass planted beside a stone and bend the nearby vegetation into a more natural arrangement. A useful first product is a static geometric result obtained through a bounded fitting operation. The artist can press Update while an internal numerical method performs several steps. Continuous timeline simulation is not a prerequisite for that interaction.

Houdini documents both a static curve collision operation and a Vellum mode that rolls inputs forward internally for each evaluated frame. These establish relevant building blocks, not a proven Cyrus implementation or a guarantee for arbitrary plant meshes. [Guide Collide With VDB](https://www.sidefx.com/docs/houdini/nodes/sop/guidecollidevdb.html), [Vellum Solver](https://www.sidefx.com/docs/houdini/nodes/sop/vellumsolver.html).

The hardest uncertainties are source preparation, reliable initial-intersection recovery, and delivery of differently bent geometry through Max's viewport/render/Bake paths. A convincing guide-only demonstration would leave all three partially unanswered.

R11 strengthens the representation evidence with two supplied public meshes, synthetic counterexamples and reported arithmetic checks. Independent topology recounts agree with its public-asset counts. This supports conservative preparation and explicit identity mapping; it does not establish automatic blade recognition, successful contact fitting or production asset coverage.

R13 adds a preserved C++ reproduction package and reported Linux headless diagnostics. It demonstrates, within that recorded build, a stock rod crossing an obstacle, ambiguous mesh occupancy, tiny-scale query misses and residual penetration after a rigid body sleeps. We inspected its harness/results and matched 48 cited file hashes to the local pinned dependency; we did not repeat the engine runs. This is stronger evidence for the identified gaps, not a complete fitted-grass or Max result. See the [evidence review](references/R13-evidence-review.json).

R14 adds a different CPU build profile, seven reported native records and nine analytic fixtures with fifteen stored checks. Its three-point rod still crosses a sphere at both 5 and 50 soft iterations; its free interior rod can be ejected with continuing velocity rather than settle into an acceptable shape. It narrows the public callback boundary and strengthens immutable query-generation ownership. The [R14 review](references/R14-evidence-review.json) preserves these findings without treating them as our reproduced runs or as a completed fitter.

## Separate the requested behaviors

| Behavior | What changes | Recommended scope |
| --- | --- | --- |
| Rooted vegetation fit | Shape changes; accepted root placement stays fixed | First bounded research prototype |
| Rigid settle | Object translation and rotation change; source shape stays fixed | Separate existing Physics Lab context and future integration decision |
| Deformable leaf drape | Unrooted surface bends, folds and moves | Later surface-solver investigation |
| Plant-to-plant interaction | Contact couples several deformable plants | Later opt-in feature with a separate cost budget |

A leaf modeled as one rigid body cannot fold over a curb. A single clump guide can provide a broad push but cannot promise individual blade contact on opposite sides of a stone. A solver choice should follow the intended representation and visible result.

## First product hypothesis

Use one prepared grass source with explicit roots, ordered guides, base frames and a verified guide-to-mesh binding. Begin with a small set of fixed solid primitive/convex/compound obstacles, plus explicitly declared terrain surfaces where qualified. Arbitrary mesh-solid containment needs a separate gate. Fit only affected accepted placements after ordinary placement acceptance has completed. Keep untouched placements on the existing shared-source path and attach optional deformation state to affected identities.

A focused deterministic fitter with explicit whole-segment/envelope contact is the leading hypothesis. Compare a direct triangle BVH with Jolt shape queries as its contact backend, and retain a small rod/constraint mechanics comparator. R12 and our pinned-source checks identify sampled-vertex contact and root-mass coupling in the stock CPU rod path; existing rigid-body integration does not remove those gaps. Select the method from contact quality, failure behavior, total update cost and output fidelity, not dependency reuse alone.

R13 favors selective Jolt query reuse, conditional on a qualified geometry adapter. Keep the BVH comparison: its reported tiny-scale and containment failures mean query availability alone is insufficient. Compare a fitter and rods against the same final validator, including the contact adapter each actually needs. The reported one-segment hard-clamped rod is a detection diagnostic; it cannot fairly rank feasible routing quality or speed.

The final decision remains a narrow experiment, not a production solver adoption: test a short prepared guide with enough root freedom and length for a known feasible route around one stone. Implement the missing contact response, then test visible width and two obstacles. Pair every intended rejection with a feasible control that must succeed; an implementation that rejects every plant does not meet the requested feature. Keep the authored viewport/render/Bake feasibility experiment early.

Start with artist-facing controls for obstacle selection, clearance, flexibility, root attachment and Update. Add complexity when the fixtures demonstrate a need. No arbitrary-asset automation, full ecosystem simulation, GPU requirement or universal renderer claim is justified by the present evidence.

## What “closest objects” should mean

Use proximity to find a bounded neighborhood, then test the actual geometry. The nearest object origin or nearest root is insufficient: a long blade can touch a farther stone, and two stones can constrain the same blade simultaneously. Candidate search must account for plant reach, obstacle bounds and the permitted deformation envelope.

The solver needs all relevant contacts in that neighborhood. Choosing only the closest stone or averaging opposing normals can produce an apparently smooth shape that still penetrates another obstacle.

## Research confidence

| Conclusion | Confidence and limitation |
| --- | --- |
| Prepared rooted grass can be represented by constrained guides or ribbons | Strong technical basis; actual source-library suitability is unmeasured |
| A static artist workflow can contain internal relaxation | Documented vendor precedent; Cyrus scheduling and costs remain unimplemented |
| Position, tangent and cross-section orientation need distinct treatment | Geometric requirement; UI defaults and material calibration remain proposed |
| Differently bent instances may require distinct visible geometry | Geometric consequence; exact allocation and reuse depend on the output design |
| A local fit can preserve accepted placements | Proposed feature invariant; upstream placement changes still follow existing contracts |
| Research estimates predict production performance | Unsupported; arithmetic scenarios are useful for budgeting only |

## Decision boundary

Proceed to a later, explicitly authorized end-to-end prototype if the user chooses implementation. First demonstrate one bent blade beside one fixed stone, with matching Max 2027 viewport, selected final renderer and Bake output. In parallel, audit a small representative asset set. Expand to clumps, two obstacles and scale only after those gates pass.

A tiny native segment-crossing/root probe can run alongside the authored output experiment. This reconciles R12's early solver falsification with the existing early output gate: both uncertainties should be tested before building a substantial solver. The [decision experiments](checklists/SOLVER-DECISION-EXPERIMENTS.md) remain proposed work.

The current request authorizes this research library. It does not start that prototype or alter the active improvement-program ledger.
