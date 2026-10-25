# 04 Collision and solvers

**Status: inspected dependency behavior, supplied diagnostics, engineering hypotheses and a comparison plan.** The [R12 source review](references/R12-source-review.json), [R13 review](references/R13-evidence-review.json) and [R14 review](references/R14-evidence-review.json) distinguish code checks, reported native runs and analytic fixtures. No production solver has been selected or independently executed here.

## Neighborhoods and geometry roles

Keep render source, driver geometry, receiver and obstacle proxy distinct. A receiver anchors a plant; it is not automatically an obstacle. Rooted mode uses one-way interaction initially: the fixed stone affects the grass, and the stone receives no reaction motion. Plant-to-plant contact is a separate opt-in scope.

Build a bounded spatial broad phase over accepted plant reach and obstacle geometry. Query potential contacts before narrow-phase tests. Use the union of old/new obstacle influence and previous dependencies during updates. An obstacle moving away matters as much as one moving into contact. A single nearest object or nearest surface sample cannot establish the complete constraint set.

## Contact fidelity

The collision representation must match the intended behavior. A convex hull can remove concavities; a terrain hull can bridge a valley; a conservative capsule can block a ribbon that could physically turn edge-on through a gap. Show proxies and their effective margins.

For a thin blade, test whole segments/capsules or an explicitly represented ribbon. Endpoint tests can miss a segment crossing a stone. Finite surface samples can miss crossings between samples. A component fully inside a closed obstacle can require inside/outside classification even when no triangle pair intersects.

After decoding, validate the visible mesh against every relevant obstacle. Guide clearance does not prove mesh-edge or triangle clearance. Smoothing, shell thickness, interpolation and rendering subdivision can introduce new contact. The validation envelope must match the geometry actually delivered.

For signed distance fields, record voxel size, band coverage, sign validity and approximation error. Open meshes, thin surfaces and intersecting obstacles need a declared policy. A narrow polygon gap can disappear in a coarse field. Surface normals alone do not supply robust inside/outside semantics for arbitrary meshes.

## Clearance accounting

Define terms once: visible half-width or proxy radius, requested clearance, obstacle padding, discretization error and numerical acceptance tolerance. Avoid counting the same width twice. For a straight parallel channel, if effective radius already includes visible half-width plus clearance, a necessary centerline-channel width is approximately twice that radius; it is not that value plus the blade width again.

That lower bound is not a general feasibility proof. Curvature, base attachment, admissible strain and full three-dimensional routes matter. Opposing contacts must remain separate constraints; averaging their normals can cancel the information needed to escape penetration.

## Rest state, initial state and loading history

| State | Meaning | Why it matters |
| --- | --- | --- |
| Rest shape | Authored preferred shape and material target | Must remain independent of a temporary collision-free initialization |
| Initial geometry | Starting iterate or simulation pose | May need contact recovery or explicit preparation |
| Completed fit | Accepted geometry for the declared inputs | Does not automatically redefine the rest shape |
| Simulation history | Motion, velocities and solver state over time | Can change the settled result and restart requirements |

The original use case includes an already intersecting source beside an already fixed stone. Keep that test. Moving the stone in gradually from a clear position is a useful comparison but solves a different loading history.

A deterministic internal continuation or relaxation scheme may be a legitimate fitting algorithm. Record its start and continuation policy without animating the artist's scene or implying a unique physical equilibrium. With a separate straight-rest target, a clear bent initial guide has a restoring load. Rebuilding rest constraints from that bent guide can erase the load entirely.

## Numerical candidates

| Candidate | Useful first comparison | Main unresolved issue |
| --- | --- | --- |
| Geometric contact projection plus shape/length regularization | Small static fit with explicit limits | Deep overlap recovery, multi-contact convergence and shape quality |
| Rod or position/constraint relaxation | Rooted bend and optional material frame | Discretization, stiffness/work dependence, collision fidelity and initialization |
| Jolt CPU soft-body/rod route | Mechanics/control comparator using an existing dependency | Checked bare-rod environmental contact samples vertices, leaving segment and root-policy gaps |
| Ribbon/surface solver | Frame-aware contact for wide or twisting blades | Greater state/contact cost and source preparation |
| Full rigid body | Pebbles and rigid leaves | Cannot provide vegetation bending or leaf folding |

Jolt's CPU Cosserat-rod addition and its later experimental GPU hair path are distinct capabilities. A GPU-path restriction is not a general rejection of CPU rods, and a CPU rod feature is not proof of full continuous capsule collision suitable for this product. Inspect the pinned implementation and run the same contact fixtures before choosing it. [Jolt 5.4.0](https://github.com/jrouwe/JoltPhysics/releases/tag/v5.4.0), [Jolt 5.6.0](https://github.com/jrouwe/JoltPhysics/releases/tag/v5.6.0).

## What R12 resolves at the Jolt pin

The local Lab build pins commit `1b2e77e3c6c09709e5edc79dc208459b8ff32051`; its Core header says 5.6.1. Eleven decision-critical local files match the public files at that commit after line-ending normalization. This is a source check, not a built/loaded-module identity check or an audit of the complete dependency. The exact commit and build flags matter more than a release nickname.

R13's wider source ledger matches 48 local file hashes, while the pinned CMake project string remains 5.6.0. Preserve both observations rather than substituting a nearby tag. Reported build flags and binary/loaded identity still need their own execution evidence.

In the checked bare CPU rod environmental path, shapes receive vertex positions and inverse masses and keep one selected collision plane per vertex. That interface supplies no rod segment or varying blade-width envelope. A segment can cross a stone while both sampled endpoints remain outside. Adding samples can reduce this error but does not prove continuous whole-segment contact. This finding is limited to that path: the engine also has soft-body face handling in its rigid-body CCD path, so it must not be generalized to every Jolt soft-body subsystem. [Vertex iterator](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/CollideSoftBodyVertexIterator.h), [rigid-body CCD implementation](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/PhysicsSystem.cpp).

Root construction also needs a controlled test. The normal rod-property calculation uses the minimum endpoint inverse mass for a rod, and its angular corrections use that rod inverse mass. A zero-inverse-mass root can therefore suppress adjacent rod rotation corrections and behave more like a clamp than an intended hinge. Contact projection also skips fixed vertices; it cannot repair a protected root already inside a stone. Compare position-only, soft angular and hard angular attachment explicitly rather than inferring them from one mass flag. [Rod properties](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/SoftBody/SoftBodySharedSettings.cpp), [rod constraints and projection](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/SoftBody/SoftBodyMotionProperties.cpp).

## Updated method recommendation

R13 supplies a reproducible diagnostic seed rather than a completed contact adapter. Its reported runs use Linux/GCC, double world positions, a single-threaded job system and no compute backends. Archive integrity, stored results and local source matches were checked here; the engine executions were not repeated.

| Reported diagnostic | Recorded observation | Consequence and limit |
| --- | --- | --- |
| Segment crossing and stock rod | Endpoints clear; capsule hit; ten rod updates leave the crossing with about 0.000000674 m endpoint drift | Confirms the sampled-contact gap in that setup; a hard-clamped single segment is not a feasible routing benchmark |
| Closed cube and interior points | Contained capsule has no surface hits; center occupancy false, off-axis interior true; deep soft vertex lacks a plane | Surface contact is not containment; shared-edge ray degeneracy needs an explicit ambiguity policy |
| Visible width and two walls | Center capsule clear, offset edge hits; diameter 0.10 capsule contacts both walls at gap 0.08 and neither at 0.12 | Coverage and local gap detection only; no full ribbon fit or two-stone correction executed |
| Equivalent tiny crossings | One hit at scale 1; zero at 0.001 and 0.00001, including proportionally reduced collision tolerance | Qualify numerical scale/normalization against an independent analytic control; the rejecting branch was not diagnosed |
| Far-origin query and arithmetic | Hits at origins 0 and 1,000,000 with matching base offset; float arithmetic loses a 0.001 delta | Subtract a nearby origin before reducing precision; one successful query does not qualify all host transforms |
| Rigid hull settling | Sleeps after 66 updates with zero error bits; final query penetration about 4.289 mm under a 1 mm slop setting | Sleep and slop are not final visible-clearance certificates; this residual is one query/build observation |

The [exact stored JSON](sources/evidence/cyrus_jolt_probe_results.json) retains every value. None of these rows is a production performance result or an independent repetition by this library.

R14 uses another recorded configuration: single world precision, SSE2 baseline, assertions, GCC 13.3 and CMake 4.1 with single-threaded jobs and compute disabled. Keep it separate from R13's double-world-position/AVX profile. Its [native JSON](sources/evidence/R14/harness_results.json) contains seven records across five families:

| R14 records | Reported observation | Consequence and limit |
| --- | --- | --- |
| H01, H02, H02b crossing | Capsule hit with clear endpoints; three-point rod still crosses after 60 updates at both 5 and 50 soft iterations; no contact observations | Reinforces the missing witness. The first span is clamped; these are detection controls, not feasible-routing comparisons |
| H03 containment | Contained capsule hits solid Box but not closed Mesh under either backface mode; cube-center parity sees two equal-fraction hits, off-axis one | Backfaces do not create remote surface contact. Raw no-hit does not itself identify an ambiguous solid query |
| H04 inside mesh | Free rod stays deeply inside with no contact observations | Requires separate solid classification/recovery or an explicit invalid-start result |
| H04b inside sphere | Three contacting vertices initially; free rod leaves the sphere and reaches about 11.273 m/s after 60 updates | Dynamic ejection is not a rooted static-fit success or evidence of acceptable settling |
| H05 protected root | Root remains near x=0.2 inside the unit sphere while update error bits stay zero | Feasibility and geometry acceptance remain application responsibilities |

R14's separate [analytic results](sources/evidence/R14/analytic_results.json) contain nine fixtures and fifteen reported Boolean checks. Its tiny-asset, large-origin, gap, corner and width expectations are mathematical controls, not additional native solver passes. R13's native tiny-query and far-origin results retain their original scope. Neither study measures throughput or supplies a completed contact fitter.

| Track or method | Proposed role | Decision still needed |
| --- | --- | --- |
| Jolt rigid bodies | Separate rigid-stone/debris settling track; fixed mesh/heightfield obstacles and suitable convex/compound moving proxies | Residual overlap, admitted capacity, lifecycle and transform publication |
| Focused static fitter | Leading hypothesis for prepared rooted vegetation; preserve rest/root constraints and test whole segments/envelopes | Recovery, multi-contact, visible quality and complete update cost |
| Jolt shape queries | Candidate contact backend for that fitter, compared with a direct triangle BVH | Contact completeness, mesh/solid policy, cooking, memory and warm-query cost |
| Stock CPU rods | Small mechanics/control comparator; document or address contact/root limitations | Whether adaptation is cheaper and more reliable than the focused fitter |
| Experimental GPU hair | Separate future investigation only if measured needs justify it | Integration, representation, contacts and output support; no current adoption |

Query reuse does not supply the fitter, root policy, rest constraints, convergence checks or renderer output. A custom collision listener alone cannot add rod-segment geometry absent from the checked iterator. Compare both contact backends using identical fixtures and acceptance criteria. [Shape-query interface](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/NarrowPhaseQuery.h).

R14 makes the hook distinction precise. The pinned engine has a public advanced rigid-body contact-generation callback, but rigid pair processing diverts soft bodies into their separate pipeline before invoking it. The soft-body listener adjusts pair settings and observes a const post-solve particle manifold; it exposes no endpoint/frame constraint-row insertion API. Budget a maintained internal extension if a CPU rod route requires that missing seam, or let a focused fitter own response through public queries. This finding does not mean every custom Jolt contact requires a fork. [Rigid callback](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/PhysicsSystem.h#L92-L108), [soft-body listener](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/SoftBody/SoftBodyContactListener.h).

## Query and update adapter details

Construct a segment capsule from midpoint, local Y-axis orientation, half the endpoint distance and a declared radius. Arbitrary axial stretching is not valid capsule scaling at this pin. Reject zero-length segments or use an explicit sphere fallback. Keep body-origin and center-of-mass transforms distinct. When the query is shape 1, the documented penetration axis moves shape 2 out, so a corresponding translation of the query uses the opposite normalized direction. A separation-shell query can return negative depth. Prove these conventions with a known primitive before distributing corrections to deformable endpoints. [Capsule](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/Shape/CapsuleShape.h), [query results](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/CollideShape.h).

A rod material frame uses local Z along the span; a query capsule uses local Y. Convert deliberately rather than reusing the same quaternion. A raw contact also supplies no semantic material fraction along the guide. Derive and validate that fraction from the capsule-side witness/axis or an independently qualified closest-feature calculation. An arbitrary obstacle-side projection during deep overlap is insufficient.

R14 proposes a local frozen-witness response. For a qualified fraction u, outward unit normal n, obstacle witness c, radius r and clearance h, let p=(1-u)x0+u*x1 and g=dot(n,p-c)-r-h. Its endpoint gradients are (1-u)n and u*n. With mobilities w0/w1, a hard projection uses denominator D=w0*(1-u)^2+w1*u^2 and multiplier -g/D when g is negative. Preserve a pinned endpoint with zero mobility; negative gap with D=0 is an immovable conflict. This is a local linearization to test, not a complete solver. Width offsets add frame/rotation gradients; every correction must refresh witnesses and revalidate roots, rest/length and all contacts.

Whole-segment coverage is spatial coverage at a pose. A translation cast of a rigid capsule does not cover arbitrary endpoint bending, rotation or ribbon deformation through time. Declare final-pose fitting separately from continuous motion/route preservation. Both need an independent final visible-shape validator.

R13 also clarifies contact refresh. In the checked CPU soft-body path, collision planes are selected before integration and reused across its soft substeps. Increasing soft-body iterations changes integration/constraint work without automatically refreshing those planes or adding segment geometry. World collision steps and manual CustomUpdate calls are different boundaries; avoid double stepping a body through both paths. Root inverse mass zero still needs canonical zero initial velocity to be stationary. Free/finite angular attachment remains a prototype, not a reported success. [Runtime/update contract](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/SoftBody/SoftBodyMotionProperties.h).

## Physical scale and solid/surface policy

Declare conversion from scene units to the engine's physical scale and choose a local numerical origin. Test equivalent scenes at different scene-unit settings and translated far from the world origin. Engine tolerances and default vertex radii are numerical defaults, not calibrated grass clearance presets. Record all effective values; do not silently retune global engine settings per blade.

The checked triangle helper has finite backward thickness. A closest triangle or its backface slab does not classify every point deeply inside an arbitrary closed solid. Keep a separate declared containment policy and distinguish closed solids from open/sided surfaces. A root-conflict preflight should preserve the plant and report the conflict. [Triangle helper](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/CollideSoftBodyVerticesVsTriangles.h).

Do not replace that policy with unqualified raw mesh parity. The checked fallback counts triangle hits along a positive-Y ray; the report's cube-center ray meets a shared face diagonal and returns an inconsistent inside result. Use independently checked solid classification with edge/vertex handling and an ambiguous outcome. A no-hit surface query cannot certify that an entire blade is outside. [Point classification implementation](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/Shape/Shape.cpp).

For static geometry queries, normalization into a qualified local metric is a candidate response to tiny-scale failures; it must pass mapped-back acceptance tests. Dynamic rescaling also affects gravity, velocities, mass/inertia, compliance and time. Numerical convex rounding, artist clearance, length-valued collision tolerance and dimensionless penetration tolerance remain different quantities. Reducing one tolerance is not a complete scale policy.

Shape names are not body-role rules. An immutable StaticCompound can form a moving body when its children are eligible. Triangle meshes have a documented dynamic/kinematic exception with supplied mass properties, but mesh-mesh and mesh-heightfield contact remain unsupported; use convex/compound moving debris as the first rigid profile. These engine possibilities do not extend Cyrus support automatically. [Mesh roles](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/Shape/MeshShape.h).

An SDF backend would add sign, sampling, error, cache and out-of-band policies. Under a true 1-Lipschitz distance function with bounded field error, samples including both endpoints with maximum straight-segment spacing h support a lower bound of minimum sampled distance minus h/2 minus field error. An arbitrary interpolated or narrow-band field does not inherit that guarantee. This is an analytical condition, not a supplied field implementation or benchmark.

## Convergence, failure and budgets

Track root error, frame error, length/strain change, visible-mesh penetration, residual motion if applicable and work consumed. “Reached frame 90” and “object sleeping” are insufficient acceptance criteria. Calibration must retain topology, mass mode and units so a refinement does not accidentally change the experiment.

Bound affected placements, guide samples, obstacle geometry, candidate pairs, contact storage, iterations, scratch and output geometry separately. Report limit exhaustion distinctly from setup failure or unresolved contact. Neither raising iterations nor reducing friction repairs missing collision geometry or contradictory constraints.

Use the same units, input geometry, decoder and acceptance metrics across comparator methods. Solver-specific coefficients need not have the same physical meaning. Performance comparisons must include preparation, neighborhood search, solve, decoding, output and publication rather than reporting only the integration loop.

Check engine update error bits as well as completion. At this pin, body-pair/contact/manifold capacity errors can mean contacts were ignored. An ordinary return from an update cannot by itself admit the result for publication. Record the exact error, keep the previous complete result and distinguish capacity failure from unresolved geometric contact. [Update errors](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/EPhysicsUpdateError.h).

The [eight solver decision experiments](checklists/SOLVER-DECISION-EXPERIMENTS.md) translate R12 into bounded future comparisons. Every experiment remains Pending.

Experimental compute hair can run without scalp data in an official source example; scalp authoring is optional. This does not remove its separate compute/material/output integration or its sampled environment-contact limitations. No compute-hair runtime was executed by R14 or this library. [No-scalp collision example](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Samples/Tests/Hair/HairCollisionTest.cpp).
