# Owner A return — Cyrus Vegetation Core Handoff v1

## Delivered result

This return supplies a working C++20 implementation of `make_jolt_world` and all `CollisionWorld` public methods. It uses the pinned public Jolt primitive-query APIs and separately labelled double-precision analytic refinement. The final Release build and a separate Debug AddressSanitizer/UndefinedBehaviorSanitizer run each passed all **15 `collision_` CTests**. This is the collision service for the prepared-ribbon static-fit handoff, not a complete fitter, dynamics world, host plugin or research-only stand-in.

**Role:** A — collision. **Edition:** `CyrusScatter_Vegetation_Core_Handoff_v1`.

**Actual frozen C++ header SHA-256:**

```text
f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f
```

Implementation additions are confined to `docs/research/vegetation-core-handoff/starter/collision/`. An executed baseline audit found all 80 original ZIP files byte-identical, all 79 originals outside that module unchanged, zero additions outside the module in the working packet, and all four frozen hashes/byte counts correct. The two files at this return ZIP's root are the checklist-required report and manifest. No shared declarations, fixtures, other module, root CMake, repository physics implementation or historical harness was edited.

## Integration and dependencies

- Exported target: **`cyrus_vegetation_collision`**, publicly linked to **`cyrus_prototype_contract`**.
- Entry point: `cyrus::vegetation::prototype_v1::make_jolt_world`.
- Returned service: `generation()`, `backend()`, `classify_point(...)`, `query_capsule(...)`.
- Engine commit: **`1b2e77e3c6c09709e5edc79dc208459b8ff32051`**.
- Archive: `https://codeload.github.com/jrouwe/JoltPhysics/tar.gz/1b2e77e3c6c09709e5edc79dc208459b8ff32051`.
- Required archive SHA-256: **`6bb6d626b7b70096cd07f1b25c0c223df035ab6386885f07f77baa88ae7d3998`**; observed size 19,399,443 bytes.
- Offline option: **`CYRUS_COLLISION_JOLT_SOURCE_ROOT`**. Both offline and fetched routes verify all 613 source/build/license inventory files byte-for-byte. Configure-time download additionally enforces `URL_HASH`. The offline route was executed; network fetching through CMake was not executed.
- MIT notice: `collision/cmake/Jolt-LICENSE.txt`. No full engine source or compiled binary is included.

Configure the unchanged handoff **starter** directory. Its existing root CMake discovers this module. A local coordinator can use:

```sh
cmake -S docs/research/vegetation-core-handoff/starter -B build/collision \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCYRUS_COLLISION_JOLT_SOURCE_ROOT=/path/to/exact/jolt/source
cmake --build build/collision --config Release \
  --target cyrus_collision_tests --parallel 2
ctest --test-dir build/collision -C Release -R '^collision_' --output-on-failure
```

These are portable templates. Exact executed argument arrays, absolute working directories, exit codes and logs are preserved in `collision/evidence/`: `configure-release`, `build-release-final`, `ctest-release-final`, `configure-sanitizers`, `build-sanitizers`, `ctest-sanitizers`, `ctest-asan-ubsan-no-lsan` and `dependency-admission`, each with JSON and log receipts. `base-integrity.json` records the separately executed original/frozen-file comparison. No pass is inferred from a command template.

### Actual observed environment/options

Linux `6.18.55`, x86-64, glibc 2.39; GCC/Ubuntu **13.3.0**; CMake **4.1.0**; Unix Makefiles. The adapter/tests compile in GNU C++20 mode; the unchanged dependency uses its C++17 mode. Source uses the portable frozen C++20 interface.

The new Jolt profile has double world positions, assertions, cross-platform deterministic mode, exceptions and RTTI enabled. Actual native configuration reported **SSE2**, 16-bit object layers, assertions, C++ RTTI and exceptions. SSE4/AVX/AVX2/AVX512/FMA/F16C/LZCNT/TZCNT, all compute backends, object streaming, profiler, debug renderer and IPO are disabled. Actual x86 compile options include `-msse2 -mfpmath=sse -pthread`, with `-fno-fast-math -ffp-contract=off` on the engine and adapter. Release uses `-O3 -DNDEBUG` while Jolt assertions remain explicitly enabled. The separate Debug build adds `-fsanitize=address,undefined -fno-omit-frame-pointer`.

See `build-options-release.txt`, `build-options-sanitizers.txt`, the selected exact compile commands, `environment.json`, and the runtime identity line in the test log. This is a new profile and execution receipt; R13's historical AVX profile and R14's historical single-world-precision profile are not reused as qualification.

## Behavior implemented

The world deep-copies every admitted obstacle, including stable ID, geometry revision, pose revision, center and rigid orientation. Immutable native shape references and copied poses remain alive for the entire world generation. Entries/results are ordered by caller obstacle ID. Caller edits after construction cannot affect a live world.

Every complete point query classifies every obstacle against the solid enlarged by the requested Euclidean exclusion radius. Every complete capsule query examines the entire directed segment against every obstacle. The native path actually calls `Shape::CollidePoint` and `CollisionDispatch::sCollideShapeVsShape`; the raw-engine observation test requires dispatches and native hits.

Analytic primitive refinement establishes solid containment and a **qualified material coordinate**. The capsule result selects one deepest centerline-SDF witness per relevant obstacle. It is a documented reduction, not a full manifold or rigid-capsule minimum translation depth. Returned contacts reconstruct `a + u*(b-a)`, belong to the obstacle surface, have a unit outward normal, and satisfy the frozen signed-gap formula with geometric radius and clearance subtracted once. A raw engine miss never establishes outside/clear, and raw contact points are never assigned an invented `u`.

Capsule local +Y is explicitly aligned to the span; the contract material tangent is +Z. Primitive COM is checked as zero. The obstacle center is subtracted in double before float native transforms are formed. Boxes have zero convex radius. Native shape order and the negative penetration-axis normal are checked separately from final double witnesses.

Incomplete, ambiguous, invalid, unsupported, cancelled and over-budget operations return non-Ok status, `complete=false`, and discard staged outputs. A fixed raw collector cannot silently truncate. Root exclusion is supplied by point classification; root anchoring, orientation stiffness, solver response and final mesh acceptance remain Owner B/C work.

The standalone Jolt owner keeps one mutex-protected runtime lease count. Shape resources die before the last lease unregisters types and releases the factory/default material. Two worlds survive either destruction order. Per-world queries serialize and do not mutate shape/pose generations. Foreign Jolt ownership is rejected; this does not qualify cross-DLL sharing inside Max.

## Observed verification

| Execution | Observed result | Meaning |
| --- | --- | --- |
| Fresh Release configure/build | Exit 0 | Exact source verification and real native compilation succeeded. |
| Final Release CTest | **15/15 passed**, exit 0 | Final implementation passed the delivered black-box controls. |
| Separate Debug ASan/UBSan build | Exit 0 | Engine, adapter and tests compiled with both sanitizers. |
| First sanitizer CTest, default leak checking | **Exit 8; 15 process failures** | LeakSanitizer could not read `/proc/<pid>/task`; this environment cannot supply a valid leak result. The failure log is retained. |
| ASan/UBSan CTest with leak checking disabled | **15/15 passed**, exit 0 | `detect_leaks=0`, `halt_on_error=1`; no address/undefined-behavior diagnostic appeared. This is not leak validation. |
| Archive and source admission | Exit 0 | Actual archive hash matched; all 613 relevant files matched. |
| Deliberately wrong temporary source hash | Native verifier exit 1, expected | Real admission function rejected the mismatch; no engine source was altered. |
| Original/frozen packet audit | Exit 0 | 80 originals unchanged; 4/4 frozen records verified; ownership boundary preserved. |

The 15 cases are `identity_empty`, `point_sphere`, `point_box`, `capsule_sphere`, `capsule_box`, `capsule_axes`, `two_obstacles`, `invalid_inputs`, `limits`, `cancellation`, `snapshot`, `lifetime`, `scale_profile`, `repeatability` and `native_observations`. They are authored Owner A tests. The fixture catalog informed their scope; this is not execution of the complete joint A/B/C fixture catalog.

**Independent analytic controls:** metre-scale exact controls use a `2e-10` absolute comparison allowance, with explicit smaller/larger allowances for tiny and translated cases. The box diagnostic evaluated 200 deterministic varied boxes/spans against 501 independently computed point-SDF samples per span. It found 139 sampled contacts and returned 139 contacts. Maximum returned-gap excess over the sampled minimum was `4.8572257327350599e-16 m`; maximum witness/SDF reconstruction difference was `9.0205620750793969e-16 m`. Sampling can falsify a missed contact; positive samples alone do not prove continuous clearance. These are observed fixture residuals, not a universal accuracy bound.

**Separate raw-Jolt observations:** four shallow-contact controls expected `0.07 m` penetration and used a declared `3e-4 m` float-engine allowance. Sphere X/Z spans reported `0.070000283420085907 m`; rotated-box local Y/Z spans reported `0.070000000298023224 m` and `0.070000030100345612 m`. The largest raw depth difference from this expected value was about `2.8342e-7 m`. Raw normal/depth consistency error was at most `6.5135133897609165e-8 m` in those controls. These values do not replace the analytic witness tests or certify arbitrary raw GJK/EPA accuracy.

No throughput or memory benchmark was run. Recorded command/CTest wall times are execution receipts only.

## Coverage and limits

| Requirement | Status | Evidence or restriction |
| --- | --- | --- |
| Frozen factory and all world methods | Implemented | Real pinned native adapter; all public controls execute. |
| Complete solid point/exclusion queries | Implemented | Sphere/OBB inside, boundary, outside and exclusion controls. |
| Whole-segment capsule contact | Implemented | Crossing endpoints, contained spans and all-obstacle controls. |
| Qualified u, surface/normal/gap | Implemented | Independent reconstruction and primitive support checks. |
| Immutable shape and pose generation / stable IDs | Implemented | Caller edits, destruction, input reorder and quaternion-sign controls. |
| Simultaneously alive worlds / teardown order | Implemented for standalone scope | Survivor queried after either world is released, plus reacquisition. |
| Query/contact limits and incomplete-not-clear | Implemented | Empty-looking over-budget and overflowing queries fail explicitly. |
| Nonfinite and scale admission | Implemented | Includes inactive fields, invalid rotations and precision-driven ambiguity. |
| Cancellation | Implemented cooperatively | Already-requested cancellation tested; native-call or mutex-wait preemption is not provided. |
| Memory accounting | Implemented payload/reservation policy; partial total accounting | Actual capacities and known payloads checked. Allocator/global/native overhead and measured peaks are not fully instrumented. |
| General mesh, open mesh, hull, SDF or transformed scale/shear | Unsupported | Only the declared primitive profile is admitted. |
| Forced OOM recovery | Partial / not fault-injected | Ordinary allocation failure handled where possible; pinned internal hash-table exception safety has a disclosed limit. |
| Max, renderer, Bake, DLL sharing | Not executed / outside A scope | No host SDK or host validation claimed. |
| Joint prepared-ribbon fit and independent mesh acceptance | Not executed by A | Coordinator must combine B/C and run the shared fixtures. |

Numeric admission is explicit: at most 4096 obstacles; caller minimum feature between `1e-6` and `1000 m`; active dimensions, capsule radius and span length between that minimum and `1000 m`; coordinate components within `±1e6 m`; exclusion/clearance at most `1000 m`; tolerance between `1e-10 m` and one quarter of the declared minimum feature. Coordinate-dependent double roundoff qualification can still return `Ambiguous` within those ranges. The allowance is an engineering estimate, not formal interval arithmetic.

`max_query_calls` counts native per-obstacle dispatches **within each public operation**, not lifetime world consumption. Owner B needs its own aggregate solve budget. Other shared node/iteration/render limits are checked nonzero but do not control Jolt's internal GJK/EPA iterations. Cancellation latency and parallel-query race stress were not measured.

The byte charge is known world/entry/primitive payload plus a 4096-byte metadata reservation, and result-vector capacity plus a 65536-byte operation reservation. These reservations are not measured peaks or proven maximum native stack sizes. Standard vector over-allocation is checked after allocation. Shared Jolt registration/default material, native internal allocations, allocator overhead, process/thread infrastructure and caller-retained results are outside exact instrumentation. Multiple worlds and retained results need coordinator-level aggregate accounting.

Worlds must release before Jolt's global C++ static teardown. Foreign mutation of engine globals, arbitrary static shutdown ordering and Max cross-DLL ABI safety are not supported. Runtime initialization OOM releases reachable resources and poisons further acquisition because the pinned hash-table growth path can lose old storage on allocation failure; a process restart is then required. Full internal leak reclamation is not claimed, and LeakSanitizer validation was blocked here.

## Change list and coordinator handoff

Added the module CMake target; exact-source verifier/hash inventory/MIT notice/build-profile guards; `collision_world.cpp`; private primitive refinement, runtime lifecycle and diagnostics helpers; the 15-case test executable; README; source audit; real command/build/test logs and integrity evidence. The original module `ASSIGNMENT.md` is returned unchanged. `return-manifest.json` lists every returned file with byte count and SHA-256, the four verified frozen records, environment, executions and unexecuted scope.

**No contract change is requested.** The shared header/root CMake and all fixtures remain frozen.

For the local coordinator: restore only `starter/collision/` at the original path, verify the manifest and frozen header, configure the starter against the exact Jolt source, and link `cyrus_vegetation_collision`. Keep one returned world for one immutable scene generation throughout a fit. Require Ok **and** complete before consuming a query, refresh contacts after finite B updates, and require C's independent whole-mesh acceptance. Build a successor world after a stone edit; retain the old world only for work still tied to its old generation. Combined B/C qualification and Max integration remain local-coordinator gates.
