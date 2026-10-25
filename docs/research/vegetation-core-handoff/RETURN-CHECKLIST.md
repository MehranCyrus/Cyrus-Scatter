# Return checklist for each GPT Web chat

Return one source ZIP named `CyrusVegetationCore_v1_A_collision.zip`, `CyrusVegetationCore_v1_B_fitter.zip`, or `CyrusVegetationCore_v1_C_delivery.zip`.

## Required contents

1. `return-manifest.json`, based on the [template](return-manifest.template.json), plus a short `RETURN-REPORT.md` at the ZIP root.
2. Complete owned module under its original `docs/research/vegetation-core-handoff/starter/{collision|fitter|delivery}/` path. Include source, private headers, CMake, tests, README and required small test data. Do not send just patches, fragments, screenshots or prose instructions.
3. A `files` entry giving SHA-256 and byte count for every returned file except the manifest itself. Use portable relative paths; no absolute paths, symlinks, `..` or case-colliding names.
4. Actual starting edition and hashes of every file in `FROZEN-FILES.json`. Frozen files themselves need not be duplicated in the return. Do not rewrite them.
5. Commands, environment/compiler/dependency options, exit codes and real test logs in the owned module's evidence directory. List tests Not executed separately, with reason. Assertions/expected outputs do not count as observed runs.
6. A coverage table of implemented, partial, Unsupported and Not executed requirements. State all numerical/model/scale/platform limitations, measured residuals, and whether memory figures are estimates, upper bounds or measured peaks.
7. A concise integration note: exported target, entry points, dependency setup, deterministic fixtures, unresolved risks and any contract change request.

Exclude compiled binaries, build trees, caches, downloaded SDKs, full Jolt/vendor trees, private credentials, unrelated repository files and edited research originals. Preserve any necessary third-party license notices. You may include minimal attributed dependencies only when required and clearly recorded.

## Integrity and completion

The report must distinguish: authored fixture, analytic expectation, executed headless test, measured performance, independent validation and Max host qualification. You cannot claim Max qualification without Max access. Do not mark the research matrix or historical report results as newly passed.

If your environment cannot produce ZIPs, provide an exact file tree and complete file contents with a manifest and honest execution status. If the interface is insufficient, return `CONTRACT_CHANGE_REQUEST.md` in the owned module with the smallest change, reason and affected test; do not silently build an incompatible interface.

The local coordinator will inspect source/scripts before executing, check scope and hashes, compile the three modules together, add combined tests, and perform Max 2027 integration separately. Returning source does not merge or publish it.
