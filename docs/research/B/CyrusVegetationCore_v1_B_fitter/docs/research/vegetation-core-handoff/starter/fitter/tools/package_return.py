#!/usr/bin/env python3
"""Package owner B's complete module with retained evidence, inventory and frozen hashes."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import shlex
import zipfile


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-zip", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    module = Path(__file__).resolve().parents[1]
    base = module.parent.parent
    root = base.parents[2]
    owned = str(module.relative_to(root))
    original = Path(args.input_zip).resolve()
    destination = Path(args.output).resolve()
    destination.mkdir(parents=True, exist_ok=True)
    frozen = json.loads((base / "FROZEN-FILES.json").read_text())
    for item in frozen["files"]:
        data = (base / item["path"]).read_bytes()
        if len(data) != item["bytes"] or sha(data) != item["sha256"]:
            raise ValueError("Frozen input mismatch: " + item["path"])

    with zipfile.ZipFile(original) as archive:
        original_files = {n for n in archive.namelist() if not n.endswith("/")}
        outside = sorted(n for n in original_files if not n.startswith(owned + "/"))
        changed = [n for n in outside if not (root / n).is_file() or (root / n).read_bytes() != archive.read(n)]
    additions = [str(p.relative_to(root)) for p in root.rglob("*") if p.is_file()
                 and not str(p.relative_to(root)).startswith(owned + "/")
                 and str(p.relative_to(root)) not in original_files]
    if changed or additions:
        raise ValueError("Changes outside owner B: " + repr((changed, additions)))
    scope = {"verification_kind": "Executed byte comparison against supplied ZIP plus frozen hash verification",
             "utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
             "input_zip_name": original.name, "input_zip_sha256": sha(original.read_bytes()),
             "owned_directory": owned, "unchanged_original_files_outside_owned_directory": len(outside),
             "changed_original_files_outside_owned_directory": [], "added_files_outside_owned_directory": [],
             "base_frozen_files": frozen["files"], "passed": True}
    (module / "evidence" / "scope_verification.json").write_text(json.dumps(scope, indent=2) + "\n")

    summaries = [json.loads((module / "evidence" / p / "execution_summary.json").read_text())
                 for p in ("executed", "executed_sanitized_without_leaks")]
    for summary in summaries:
        for item in summary["compiled_input_hashes"]:
            data = (module.parent / item["path_from_starter"]).read_bytes()
            if len(data) != item["bytes"] or sha(data) != item["sha256"]:
                raise ValueError("Source changed after retained run: " + item["path_from_starter"])
    if not any(x.get("observed_summary") == "100% tests passed, 0 tests failed out of 19"
               and x["label"] == "release_ctest" and x["exit_code"] == 0 for x in summaries[0]["executions"]):
        raise ValueError("Expected recorded Release gate is absent")
    if not any(x.get("observed_summary") == "100% tests passed, 0 tests failed out of 19"
               and x["label"] == "sanitized_ctest" and x["exit_code"] == 0 for x in summaries[1]["executions"]):
        raise ValueError("Expected recorded sanitizer gate is absent")

    coverage = [
        ("Frozen C++20 entry point / exported target / isolated ownership", "Implemented", "Only fitter/ plus root handback metadata; frozen hashes verified"),
        ("Array/numeric/frame/ID/revision/budget admission", "Implemented", "Malformed data and tight-memory ordering tests pass; external prepared-mesh revision comparison belongs to C/coordinator"),
        ("PositionOnly root", "Implemented", "Exact planted point; first span and frame may turn; actual root-angle residual reported"),
        ("ClampFrame root", "Implemented", "Exact first two nodes and root quaternion; independently tested feasible and conflicting controls"),
        ("SoftFrame root", "Unsupported", "Explicit Unsupported; no substitution or finite-compliance claim"),
        ("Whole-span capsule contact and simultaneous obstacles", "Implemented", "All returned qualified rows retained/refreshed; independent sphere/OBB positive controls"),
        ("Conservative width-envelope admission", "Implemented", "radius >= full bound-offset norm; no oriented-ribbon edge optimization"),
        ("Rest-shape/bend/length coupling", "Implemented", "Normalized rest gradient, endpoint contact projections, alternating length sweeps and full final audit"),
        ("Zero gradient / tiny coefficient handling", "Implemented", "Actual zero gives local RootConflict; u=1e-200 numerical row remains diagnostic WorkLimit"),
        ("Unit tangent frames / signs / incremental roll", "Implemented", "Positive deformed roll test and q/-q equivalence; chart limits explicit"),
        ("Hidden full turns / antipodal chart", "Unsupported", "No winding inference or arbitrary transport axis"),
        ("Bounded work/proposals and cancellation", "Implemented", "Iteration/query/node/contact limits; numerical-loop checkpoints; backend cancellation remains its responsibility"),
        ("B-controlled memory bounds and visible payload accounting", "Implemented", "Checked reservations and counting allocator; metric is payload accounting plus declared allowance"),
        ("Strict total cap across opaque backend allocations", "Partial", "Owning v1 query returns cannot be preempted; CONTRACT_CHANGE_REQUEST.md records needed extension"),
        ("Complete final checks and honest residuals", "Implemented", "Only audited installed pose can be candidate; unknown metrics are explicit sentinels"),
        ("Rest reset, input immutability and generation matching", "Implemented", "Repeated calls, changed obstacle and stale generations tested"),
        ("Independent visible-mesh validation / A+B+C integration", "Not executed", "C and A are not dependencies or available implementations here"),
        ("Release and ASan/UBSan execution", "Implemented", "19/19 in each successful profile; leak detection disabled in successful sanitizer profile"),
        ("LeakSanitizer qualification", "Partial", "Attempt failed with process-inspection fatal errors; failure retained, no leak pass claimed"),
        ("Windows/MSVC, Max 2027, renderer, Bake/export", "Not executed", "Reserved for coordinator host/delivery qualification"),
        ("Production scale/origin and performance qualification", "Not executed", "Synthetic local fixtures only; CTest timing is not benchmark evidence"),
    ]
    records = {x["fixture"]: x for x in summaries[0]["numerical_records"] if x.get("status") == 0}
    chosen = [("Catalog F02 sphere / PositionOnly", "F02_one_sphere"),
              ("Whole segment crosses sphere", "F04_single_segment_fit"),
              ("Admitted width envelope", "admitted_full_width"),
              ("Two simultaneous spheres", "F06_two_spheres"),
              ("Two rotated boxes", "F06_two_rotated_boxes"),
              ("Rotated / translated / scaled", "rotated_translated_scaled"),
              ("Different seven-node geometry", "different_discretization_geometry"),
              ("ClampFrame feasible fixture", "clamp_clear_initial_span_fit")]
    numerical_table = "| Executed fixture | Iterations | Queries | Root error m | Relative length error | Max penetration m | Root angle rad | Accounted bytes |\n|---|---:|---:|---:|---:|---:|---:|---:|\n"
    for label, key in chosen:
        r = records[key]
        numerical_table += f"| {label} | {r['iterations']} | {r['queries']} | {r['root_error']:.9g} | {r['relative_length_error']:.9g} | {r['penetration']:.9g} | {r['root_angle']:.9g} | {r['memory_accounting_bytes']} |\n"
    coverage_table = "| Requirement | Status | Evidence / limit |\n|---|---|---|\n" + "".join(f"| {a} | {b} | {c} |\n" for a, b, c in coverage)
    report = f"""# Owner B return report

**Role:** B — rooted static fitter.  
**Edition:** `{frozen['edition']}`.  
**Starting actual frozen header SHA-256:** `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`.  
**Owned path:** `{owned}/`.

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
- All {len(outside)} original files outside B's directory match the supplied ZIP byte
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
cmake -S docs/research/vegetation-core-handoff/starter \\
  -B docs/research/vegetation-core-handoff/starter/fitter/build-release \\
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

{numerical_table}

All candidate rows have zero unresolved contacts beyond tolerance. The sphere
fixture's measured rest objective is {records['F02_one_sphere']['rest_objective']:.12g};
ClampFrame's is {records['clamp_clear_initial_span_fit']['rest_objective']:.12g}.
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

{coverage_table}

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

Merge only `{owned}/`, keep the frozen header/scaffold/catalog, and link
`cyrus_vegetation_fitter`. Supply a qualified immutable CollisionWorld and prepared
rest guide to `fit_rooted_guide`; retain stable identities and generation checks.
Pass only a current ConvergedCandidate to C for independent visible-mesh validation
before publication. SoftFrame stays Unsupported; resolve the recorded aggregate
memory-contract gap at the coordinator boundary. Every obstacle change refits
affected placements from immutable rest.
"""
    executions = []
    for summary in summaries:
        for record in summary["executions"]:
            item = dict(record)
            item["command"] = shlex.join(item["command"])
            item["log_path"] = owned + "/" + item["log_path"]
            executions.append(item)
    not_executed = [
        {"requirement_or_test": "Owner A / Jolt backend and combined A+B+C integration", "reason": "Independent module; no other owner implementation used"},
        {"requirement_or_test": "C canonical evaluator and independent visible-mesh validation", "reason": "Not B's module; mandatory later integration gate"},
        {"requirement_or_test": "Windows/MSVC, Max 2027, renderer, viewport, Bake/export", "reason": "No host/renderer dependency or access in this task"},
        {"requirement_or_test": "Production asset/scale/origin qualification, threaded orchestration and controlled performance", "reason": "Only recorded synthetic analytic/fake headless fixtures executed"},
    ]
    manifest = {
        "schema": 1, "edition": frozen["edition"], "role": "B", "owned_directory": owned,
        "starting_contract_header_sha256": "f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f",
        "input_zip_sha256": scope["input_zip_sha256"], "base_frozen_files": frozen["files"], "files": [],
        "environment": {**summaries[0]["environment"], "compiler": "GCC 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04)", "build_system": "CMake 3.31.6; Unix Makefiles; C++20; Release and ASan+UBSan Debug"},
        "executions": executions, "not_executed": not_executed,
        "implemented_requirements": [a for a, status, _ in coverage if status == "Implemented"],
        "unsupported_or_partial": [{"requirement": a, "status": status, "reason": c} for a, status, c in coverage if status in ("Unsupported", "Partial")],
        "coverage": [{"requirement": a, "status": b, "evidence_or_limit": c} for a, b, c in coverage],
        "known_limitations": [
            "First feasible local projection result, not minimum energy/global convergence/infeasibility proof",
            "Second-difference regularization depends on guide discretization; weights are not material properties",
            "SoftFrame, hidden full turns, antipodal charts and oriented-ribbon contact are unsupported",
            "B trusts qualified complete whole-span witnesses from the immutable CollisionWorld",
            "Payload accounting is not OS/allocator/backend scratch peak; opaque returned allocations cannot be preempted",
            "LeakSanitizer attempt failed with runtime process-inspection errors; successful ASan/UBSan profile disables leaks",
            "No general small/large-coordinate, production-asset, Windows/Max/renderer or performance qualification",
            "ConvergedCandidate still requires C's independent visible-mesh validation and coordinator revision checks"],
        "contract_change_requested": True,
        "contract_change_request_path": owned + "/CONTRACT_CHANGE_REQUEST.md",
        "max_host_validation": "Not executed; reserved for local Max 2027 integration",
    }
    content = {"RETURN-REPORT.md": report.encode()}
    for p in sorted(module.rglob("*")):
        if not p.is_file():
            continue
        relative = p.relative_to(module)
        if any(part.startswith("build-") or part in ("__pycache__", ".git") for part in relative.parts):
            continue
        if p.is_symlink():
            raise ValueError("Symlink cannot be packaged: " + str(p))
        content[owned + "/" + str(relative)] = p.read_bytes()
    manifest["files"] = [{"path": name, "bytes": len(data), "sha256": sha(data)} for name, data in sorted(content.items())]
    manifest_bytes = (json.dumps(manifest, indent=2, allow_nan=False) + "\n").encode()
    content["return-manifest.json"] = manifest_bytes
    output_zip = destination / "CyrusVegetationCore_v1_B_fitter.zip"
    with zipfile.ZipFile(output_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(content.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 10, 24, 0, 0, 0))
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data)
    (destination / "CyrusVegetationCore_v1_B_fitter_manifest.json").write_bytes(manifest_bytes)
    print(json.dumps({"zip": str(output_zip), "bytes": output_zip.stat().st_size,
                      "sha256": sha(output_zip.read_bytes()), "manifested_files": len(manifest["files"]),
                      "source_matches_execution_receipts": True, "outside_owned_originals_unchanged": len(outside)}, indent=2))


if __name__ == "__main__":
    main()
