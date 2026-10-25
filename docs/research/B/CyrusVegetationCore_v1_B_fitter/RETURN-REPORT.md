# Owner B return report

**Role:** B — rooted static fitter.  
**Edition:** `CyrusScatter_Vegetation_Core_Handoff_v1`.  
**Starting actual frozen header SHA-256:** `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`.  
**Owned path:** `docs/research/vegetation-core-handoff/starter/fitter/`.

## Delivered implementation

The complete source implements `fit_rooted_guide` as bounded alternating projected
feasibility search with rest/bend regularization. It uses the frozen contract and
C++20 standard library only. `cyrus_vegetation_fitter` links
`cyrus_prototype_contract`. No owner A/C code, Jolt, Max SDK, plugin, host or
renderer is required. No frozen or unrelated source file was edited.

PositionOnly and ClampFrame are implemented and independently tested. SoftFrame
returns Unsupported. PositionOnly fixes the root point while allowing the first
span to rotate; ClampFrame fixes the first two nodes and root quaternion. The
quaternion-geodesic root-angle residual is measured independently from root
position. `root_angle_weight` is validated but unused by those two hard policies.

Every call starts from immutable rest, retains node/span ordering and lengths,
and privately stages all work. Whole-span capsules use conservative full-offset
envelopes; qualified witnesses and complete contacts are repeatedly refreshed.
Actual immovable local contact gradients give explicit diagnostics. Length and
rest/bend projections compete under a capped proposal; final complete collision
and geometry checks determine acceptance. There is no timestep, settling loop,
global-optimality proof or global-infeasibility claim.

`ConvergedCandidate` is a guide result only. C's independent canonical evaluation
and visible-mesh validation are still mandatory before coordinator publication.

## Actual builds and execution

Compiler: **GCC 13.3.0**, Ubuntu compiler package
`13.3.0-6ubuntu2~24.04`; Linux x86_64. Build system: **CMake 3.31.6**.
Exact paths, compiler output, flags, environment overrides, commands and exit
codes are retained under the module's evidence directory and in the manifest.

- Release configure/build exit 0; **19/19 CTest groups passed**, CTest exit 0.
- Debug ASan+UBSan configure/build exit 0. The first test run, with leak detection
  enabled, returned CTest exit 8 and 19 runtime failures: LeakSanitizer reported
  fatal process-inspection errors, including unavailable `/proc/.../task` and
  its ptrace limitation. This failed log is preserved.
- The same sanitized code with `ASAN_OPTIONS=detect_leaks=0:halt_on_error=1` and
  `UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1` passed **19/19 groups**,
  CTest exit 0, with no ASan/UBSan error reported. **Leak checking is unqualified.**
- All 79 original files outside B's directory match the supplied ZIP byte
  for byte. All four frozen hashes match the actual input. Compiled-source hashes
  in both retained execution summaries match the packaged source.

The suite comprises 18 fitter groups plus one analytic-oracle group, with multiple
subcases. Designated feasible tests require actual ConvergedCandidate and verify
root, original lengths, complete segment clearance, frames, identities, reported
residuals and input/options immutability. Rejection-only harnesses are not used as
proof of feasible fitting. The supplied 45-degree pose is a separate analytic
existence control and is never supplied to the solver as its answer.

Portable build/test commands, from the handoff root:

```sh
cmake -S docs/research/vegetation-core-handoff/starter \
  -B docs/research/vegetation-core-handoff/starter/fitter/build-release \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build docs/research/vegetation-core-handoff/starter/fitter/build-release --parallel 4
ctest --test-dir docs/research/vegetation-core-handoff/starter/fitter/build-release -R '^fitter_' --output-on-failure
```

The module also contains `tools/run_checks.py` to produce execution receipts and
`tools/verify_return.py` to verify this ZIP's complete inventory and frozen base.

## Observed numerical results

All rows below are newly executed C++ Release results, not historical report
claims or authored expected answers. The independent analytic span oracle agrees
with reported penetration within the test's comparison tolerance. Root tolerance
is 1e-8 m, penetration tolerance 1e-5 m, and relative length tolerance 0.001 in
these fixtures. Row counts include root admission and all refreshed/final queries.

| Executed fixture | Iterations | Queries | Root error m | Relative length error | Max penetration m | Root angle rad | Accounted bytes |
|---|---:|---:|---:|---:|---:|---:|---:|
| Catalog F02 sphere / PositionOnly | 14 | 233 | 0 | 1.27495321e-06 | 0 | 0.518786613 | 44000 |
| Whole segment crosses sphere | 12 | 26 | 0 | 0 | 5.30142579e-08 | 0.529381935 | 13648 |
| Admitted width envelope | 4 | 10 | 0 | 0 | 5.06304477e-06 | 0.161451707 | 13648 |
| Two simultaneous spheres | 9 | 172 | 0 | 6.29657446e-05 | 0 | 0.0835641054 | 48456 |
| Two rotated boxes | 16 | 298 | 0 | 8.09281426e-05 | 4.48700848e-06 | 0.336755691 | 48456 |
| Rotated / translated / scaled | 14 | 233 | 0 | 1.27495321e-06 | 0 | 0.518786613 | 44000 |
| Different seven-node geometry | 7 | 91 | 0 | 2.08346848e-05 | 0 | 0.246747177 | 35328 |
| ClampFrame feasible fixture | 9 | 153 | 0 | 1.5347331e-06 | 0 | 0 | 44000 |


All candidate rows have zero unresolved contacts beyond tolerance. The sphere
fixture's measured rest objective is 0.000775336985677;
ClampFrame's is 0.000784552506645.
Clear empty/nonempty and curved-rest cases return exact supplied coordinates;
the default clear guide uses 0 iterations and 9 queries. The nonzero-roll frame
fixture independently preserves each authored 0.08-radian increment. Repeated
calls reproduce the same result, and moving the obstacle away restores exact rest.

The synthetic tiny-mobility row (`u=1e-200`) reaches WorkLimit after two iterations,
not RootConflict; it is a numerical regression, not a physical feasible scene.
True root-inside and zero-mobility local conflicts remain explicit RootConflict.
Unknown collision metrics before any complete audit are infinity/max-value
sentinels in C++ and null in the JSON evidence.

## Coverage

| Requirement | Status | Evidence / limit |
|---|---|---|
| Frozen C++20 entry point / exported target / isolated ownership | Implemented | Only fitter/ plus root handback metadata; frozen hashes verified |
| Array/numeric/frame/ID/revision/budget admission | Implemented | Malformed data and tight-memory ordering tests pass; external prepared-mesh revision comparison belongs to C/coordinator |
| PositionOnly root | Implemented | Exact planted point; first span and frame may turn; actual root-angle residual reported |
| ClampFrame root | Implemented | Exact first two nodes and root quaternion; independently tested feasible and conflicting controls |
| SoftFrame root | Unsupported | Explicit Unsupported; no substitution or finite-compliance claim |
| Whole-span capsule contact and simultaneous obstacles | Implemented | All returned qualified rows retained/refreshed; independent sphere/OBB positive controls |
| Conservative width-envelope admission | Implemented | radius >= full bound-offset norm; no oriented-ribbon edge optimization |
| Rest-shape/bend/length coupling | Implemented | Normalized rest gradient, endpoint contact projections, alternating length sweeps and full final audit |
| Zero gradient / tiny coefficient handling | Implemented | Actual zero gives local RootConflict; u=1e-200 numerical row remains diagnostic WorkLimit |
| Unit tangent frames / signs / incremental roll | Implemented | Positive deformed roll test and q/-q equivalence; chart limits explicit |
| Hidden full turns / antipodal chart | Unsupported | No winding inference or arbitrary transport axis |
| Bounded work/proposals and cancellation | Implemented | Iteration/query/node/contact limits; numerical-loop checkpoints; backend cancellation remains its responsibility |
| B-controlled memory bounds and visible payload accounting | Implemented | Checked reservations and counting allocator; metric is payload accounting plus declared allowance |
| Strict total cap across opaque backend allocations | Partial | Owning v1 query returns cannot be preempted; CONTRACT_CHANGE_REQUEST.md records needed extension |
| Complete final checks and honest residuals | Implemented | Only audited installed pose can be candidate; unknown metrics are explicit sentinels |
| Rest reset, input immutability and generation matching | Implemented | Repeated calls, changed obstacle and stale generations tested |
| Independent visible-mesh validation / A+B+C integration | Not executed | C and A are not dependencies or available implementations here |
| Release and ASan/UBSan execution | Implemented | 19/19 in each successful profile; leak detection disabled in successful sanitizer profile |
| LeakSanitizer qualification | Partial | Attempt failed with process-inspection fatal errors; failure retained, no leak pass claimed |
| Windows/MSVC, Max 2027, renderer, Bake/export | Not executed | Reserved for coordinator host/delivery qualification |
| Production scale/origin and performance qualification | Not executed | Synthetic local fixtures only; CTest timing is not benchmark evidence |


## Numerical and resource limits

The declared objective combines squared displacement from rest and squared
differences from rest second differences. The normalized gradient uses factor
0.2 and a 16-weight bend bound; each outer step has 20 alternating length sweeps
and at most 12 frame-chart halvings. These are numerical/artistic choices, not
material properties. Sampling is unchanged and index-based, so sampling density
or uneven spacing affects the regularizer. Acceptance is first feasible under
tolerances, not an energy minimum, monotonic convergence or guaranteed route.

Frames use unit tangent alignment, shortest transport and preserved incremental
rest roll. Ambiguous pi/antipodal charts and hidden full turns are Unsupported or
unresolved after bounded backtracking. No arbitrary transport axis or winding is
invented. The capsule envelope can reject gaps that a specially oriented ribbon
could fit; oriented ribbon-edge contact and self-collision are not implemented.

Memory values above are high-water **accounted payload bytes**, including private
requests, explicit output capacity, inspected query return capacity and a declared
8,192-byte diagnostic/local-state allowance plus context size. They are not
measured process/allocator/backend scratch peaks. Private requests are checked
before allocation. The frozen virtual calls return owning vectors and strings
after their backend allocation, so B cannot enforce a strict aggregate cap or
observe earlier opaque scratch. A returned excessive capacity gives WorkLimit;
its already-allocated observed payload may exceed the requested limit. Inspection
may stop at the first over-budget issue string, so that failed return's metric is
the observed accounting scope, not a complete opaque-process peak.

`CONTRACT_CHANGE_REQUEST.md` requests bounded caller-owned output plus a budgeted
backend scratch resource (or equivalent fully instrumented resource path).
No incompatible header change was made. Cancellation is checked in bounded B
loops; opaque backend latency/allocations remain its responsibility. Qualification
of surface witnesses, complete contact enumeration and stable generation also
depends on the supplied CollisionWorld's contract.

Tests cover synthetic local metre-scale geometry and one transformed/scaled
variant. They do not establish universal subnormal/large-coordinate robustness,
production asset coverage, runtime throughput, thread orchestration or Windows
behavior. No timing benchmark, renderer image or Max host pass is claimed.

## Evidence separation and handback integrity

Synthesis 01/03/04/05/07/08/09 and relevant R11–R14 reviews/originals informed the
design. `evidence/research_and_contract_review.md` and `numerical_review.md` are
source reviews. R11–R14 historical report-local runs remain historical. Authored
controls, current analytic checks, actual C++ executions and proposed next-version
resource experiments are labeled separately. A/C/Jolt/Max/renderer integration
and independent visible-mesh validation are Not executed here.

The ZIP contains the complete owned module, this report and `return-manifest.json`.
The manifest inventories exact byte counts and SHA-256 hashes for every returned
file except itself and records all starting frozen hashes. Build trees, binaries,
caches, SDK/vendor trees and unrelated packet files are excluded.

## Integration note

Merge only `docs/research/vegetation-core-handoff/starter/fitter/`, keep the frozen header/scaffold/catalog, and link
`cyrus_vegetation_fitter`. Supply a qualified immutable CollisionWorld and prepared
rest guide to `fit_rooted_guide`; retain stable identities and generation checks.
Pass only a current ConvergedCandidate to C for independent visible-mesh validation
before publication. SoftFrame stays Unsupported; resolve the recorded aggregate
memory-contract gap at the coordinator boundary. Every obstacle change refits
affected placements from immutable rest.
