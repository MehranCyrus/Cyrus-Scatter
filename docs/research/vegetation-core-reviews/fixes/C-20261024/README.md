# Local correction variant of owner C

The [review](../../C-REVIEW-20261024.md) records four reproduced failures and the corrected Windows/ABC result. Original C source/archive and all frozen v1 files remain unchanged. This folder preserves the small correction and coordinator regression sources outside ignored build output. It is not a product version or a Max plugin delivery.

## Corrections

- Reject unknown root-mode enumerators before validation can Pass.
- Reject nonfinite obstacle dimensions, including inactive primitive fields, matching the shared contract and A's admission.
- Use true shortest-path slerp at finite small angles; normalized linear interpolation is reserved for the coincident-frame limit. Keep the independent reference sampler mathematically consistent.
- Admit the directed-tangent frame scratch payload before either evaluator or validator reserves it. A 64-node/3-vertex case previously requested 1,512 bytes under a 1,000-byte limit and returned success. Both entry points now return ResourceLimit before that request.

[CHANGES.json](CHANGES.json) binds exact before/after bytes and SHA-256 hashes of the three changed module files. [OWNER-C-FIXES.patch](OWNER-C-FIXES.patch) contains the source correction. A/B, public signatures, fixture catalog and root scaffold are unchanged.

## Reproduce in an owned directory

1. Start from the exact original handoff v1 starter/header and the three archived A/B/C returns. Verify the four frozen file hashes and each return manifest. Extract each owned module only into a **fresh** `build/<run>/abc-starter/`; include the unchanged starter CMake and `include/` header there.
2. Check the original C files against `CHANGES.json`. Apply `OWNER-C-FIXES.patch` to that copied module, stripping the documented repository prefix or using a patch workspace with that path. Never apply it blindly to unrelated/current source. Verify all corrected file hashes afterward.
3. Copy the three C++/CMake fixture files in `coordinator/` to `build/<run>/abc-source/`. Copy `run_local.py` and `box_distance_check.py` to the run root. The relative `abc-source/` and `abc-starter/` layout is deliberate.
4. From the repository root, run the local runner's `configure`, `build`, and `ctest` actions with distinct `--label` values. Supply `--source build/<run>/abc-source --binary build/<run>/abc-release --jolt` to configure; supply that binary path for build/ctest, with test pattern `^(collision_|fitter_|delivery_|pipeline_|review_)`.

The local runner uses the inspected Windows MSVC 14.38.33130 / SDK 10.0.19041.0 installation and exact local Jolt tree. It does not launch Max. Configure with another verified toolchain separately where needed; recorded Windows passes do not qualify that other build. Temporary OBJ-test files are scoped under the owned run's temporary directory.

`pipeline.cpp` links actual A/B/C modules. Its allocation observer records ordinary unaligned C++ `operator new` requests in one regression only; it is neither a general allocator cap nor a process-memory measurement. The other four CTest groups contain C's original 23 individually named tests.

## Rotated-box experiment

The initial coordinator positive test assumed the Euclidean fitter clearance and C's axis-expanded OBB clearance were equivalent. They are not. The original test failed; its log is preserved. Independent feature-distance diagnostics measured a minimum visible distance of approximately 5.155 mm against a 5 mm target, while C conservatively rejected the pose. The final test explicitly requires that rejection and no publication; it does not turn it into a visible Pass.

A separate, explicitly recorded experiment uses a 10 mm solver clearance and validates against the original 5 mm target; it passes C. This is a fixture result, not an adopted guard-band default or universal policy. Aligning solver and validator box-clearance profiles remains an integration requirement. The full final result is 52/52 CTest groups, including this expected-rejection control and the separate guard-band positive control.

The box diagnostic script enumerates disjoint triangle/box vertex-face and edge-edge feature distances after a zero-clearance C control establishes physical separation. It is a scoped independent diagnostic, not a general robustness proof or renderer qualification.
