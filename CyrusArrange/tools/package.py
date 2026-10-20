"""Create an immutable qualified-source candidate, then certify that exact tested MZP."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import zipfile

from build import ROOT, sha, source_hashes

VERSION = "0.3.2"
MODULES = ("CyrusArrange.dlx", "CyrusArrangeStorage.dlh")
INSTALLED_MODULES = {name: "bin/" + name for name in MODULES}
UI_SCRIPTS = ("CyrusArrange.ms", "ArrangeAssets.ms", "ArrangeWorkflow.ms", "ArrangeRegions.ms", "ArrangeCollision.ms", "ArrangeModifier.ms")
REQUIRED_TESTS = tuple("tests/max/" + name for name in (
    "inspect_tests.ms", "arrange_native_tests.ms", "arrange_workflow_tests.ms",
    "arrange_lifecycle_tests.ms", "arrange_preview_tests.ms", "arrange_regions_tests.ms",
    "arrange_obstacles_tests.ms", "arrange_visual_tests.ms", "arrange_library_validation_tests.ms",
    "arrange_cache_tests.ms", "arrange_cache_atomic_tests.ms", "arrange_cache_boundaries_tests.ms", "arrange_gallery_tests.ms", "arrange_composition_tests.ms", "arrange_composition_lifecycle_tests.ms", "arrange_migration_tests.ms", "arrange_simple_workflow_tests.ms", "arrange_bulk_workflow_tests.ms", "arrange_modifier_workflow_tests.ms", "arrange_real_world_tests.ms",
    "arrange_unified_modify_tests.ms", "arrange_status_undo_tests.ms",
    "arrange_geometry_workflow_tests.ms", "arrange_base_support_tests.ms",
    "arrange_fit_feedback_tests.ms", "arrange_path_workflow_tests.ms",
    "arrange_shelves_stairs_tests.ms", "arrange_compound_collision_tests.ms",
    "arrange_road_scene_tests.ms", "arrange_device_imported_tests.ms",
    "arrange_packing_recovery_tests.ms", "arrange_legacy_minimum_workflow_tests.ms",
))
INTERACTIVE_TESTS = frozenset("tests/max/" + name for name in (
    "arrange_workflow_tests.ms", "arrange_simple_workflow_tests.ms",
    "arrange_bulk_workflow_tests.ms", "arrange_modifier_workflow_tests.ms",
    "arrange_unified_modify_tests.ms", "arrange_status_undo_tests.ms",
    "arrange_fit_feedback_tests.ms", "arrange_road_scene_tests.ms",
    "arrange_device_imported_tests.ms", "arrange_packing_recovery_tests.ms",
    "arrange_legacy_minimum_workflow_tests.ms",
))
PERFORMANCE_TESTS = tuple("tests/max/" + name for name in (
    "arrange_cache_performance_tests.ms", "arrange_cache_performance_reverse_tests.ms",
))
PERFORMANCE_INPUTS = tuple(name + ".csv" for name in (
    "assets", "cache-commands", "cache-phases", "composition-stats", "groups", "metrics",
    "poses", "preview-bounds", "regions", "sources", "warnings",
)) + ("performance-environment.txt", "result.txt")
PERFORMANCE_SCOPE = "Native ordinary and explicitly requested legacy book-row backend commands; no Modify gesture, FPS, rendering, general-scene or machine-idleness claim."
ACCEPTANCE_POLICY = "geometry-first-032-exact-proofs-v1"
HOST_FLAGS = ("loaded_path_matches", "loaded_storage_path_matches", "binaries_unchanged", "private_ini_matches", "artist_profiles_unchanged")
DEPLOYMENT_INPUTS = (
    "installer/install.ms", "installer/CyrusArrangeStartup.ms", "installer/CyrusArrange.mcr", "installer/mzp.run",
    "tools/package.py", "tools/run_installer_tests.py", "tests/max/installer_tests.ms", "tests/max/installed_startup_tests.ms",
)
EXACT_POLICY = "exact-all-inputs-v1"
REUSE_POLICY = "deployment-only-functional-reuse-v1"
EXPORT_FILES = tuple(name + ".json" for name in ("tv-console", "open-shelf", "hole", "transformed", "reopened"))


def mesh_inputs(names, settings=False):
    return tuple(name + suffix for name in names for suffix in
                 (("-meshes.txt", "-settings.txt") if settings else ("-meshes.txt",)))


# These are all files read by each verifier, including settings that older result
# files did not hash. Dependency lists include transitive local imports.
PROOFS = {
    "inspector": ("inspect_tests.ms", "verify_exports.py", "json-validation.json", EXPORT_FILES,
                  ("verify_exports.py",), 5, 0),
    "base": ("arrange_base_support_tests.ms", "verify_base_support.py", "independent-base-support.json",
             mesh_inputs(("round-original", "round-fit", "random-three", "path-base", "path-fit", "prepared-plant")),
             ("verify_base_support.py", "verify_shelves_stairs.py"), 6, 5),
    "shelves": ("arrange_shelves_stairs_tests.ms", "verify_shelves_stairs.py", "independent-shelves-stairs.json",
                mesh_inputs(("shelves100", "stairs48")), ("verify_shelves_stairs.py",), 2, 4),
    "compound": ("arrange_compound_collision_tests.ms", "verify_compound_colliders.py", "independent-compound-colliders.json",
                 mesh_inputs(("nested", "static", "path")), ("verify_compound_colliders.py", "verify_shelves_stairs.py"), 3, 4),
    "road": ("arrange_road_scene_tests.ms", "verify_road_scene.py", "independent-road-scene.json",
             mesh_inputs(("original", "variation", "fit", "spacing", "centimetres", "inches"), True),
             ("verify_road_scene.py", "verify_base_support.py", "verify_shelves_stairs.py"), 6, 5),
    "device": ("arrange_device_imported_tests.ms", "verify_device_imported.py", "independent-device-imported.json",
               mesh_inputs(("cabinet-original", "cabinet-fit", "cabinet-random", "imported-two-level-original", "imported-two-level-fit", "imported-rim-original"), True),
               ("verify_device_imported.py", "verify_road_scene.py", "verify_base_support.py", "verify_shelves_stairs.py"), 6, 7),
    "packing": ("arrange_packing_recovery_tests.ms", "verify_packing_recovery.py", "independent-packing-recovery.json",
                mesh_inputs(("packing-original", "protected-original", "minimum-original", "random", "obstacle-original"), True),
                ("verify_packing_recovery.py", "verify_device_imported.py", "verify_road_scene.py", "verify_base_support.py", "verify_shelves_stairs.py"), 5, 5),
}


def now():
    return datetime.now(timezone.utc).isoformat()


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def functional_source_map(sources):
    return {name: value for name, value in sources.items() if name not in DEPLOYMENT_INPUTS}


def deployment_changes(original, current):
    return {name: {"qualified": original.get(name), "candidate": current.get(name)}
            for name in DEPLOYMENT_INPUTS if original.get(name) != current.get(name)}


def validate_host(folder, build, allowed):
    path = folder / "receipt.json"
    run = read_json(path)
    test = run.get("test_script")
    require(test in allowed, "Unexpected host test: " + str(test))
    require(run.get("status") == "passed" and run.get("exit_code") == 0 and run.get("report", "").startswith("SUCCESS"), "Host did not complete successfully: " + test)
    require(run.get("package_qualification_eligible") is not False, "Development-only host cannot qualify a package: " + test)
    expected_mode = "owned-interactive-command-panel" if test in INTERACTIVE_TESTS else "owned-batch"
    require(run.get("host_mode") == expected_mode, "Wrong owned host mode for " + test)
    require(run.get("sources") == build["sources"] and run.get("test_sha256") == build["sources"].get(test), "Host/test source mismatch against the original complete build map: " + test)
    require(all(run.get(flag) is True for flag in HOST_FLAGS), "Actual two-module/private-profile identity checks missing: " + test)
    require(run.get("native_sha256") == build["binaries"][MODULES[0]] and run.get("storage_sha256") == build["binaries"][MODULES[1]], "Host native pair mismatch: " + test)
    require(run.get("computer_use") is False and run.get("installed") is False and run.get("artist_scene_opened") is False, "Functional qualification must use the owned non-installed host")
    # Bind the actual terminal result, both private module files and identity log.
    require((folder / "result.txt").read_text(encoding="utf-8-sig") == run["report"], "Host terminal report differs from receipt: " + test)
    require(all(sha(folder / "bin" / name) == build["binaries"][name] for name in MODULES), "Private loaded native payload changed: " + test)
    loaded = (folder / "loaded-native.txt").read_text(encoding="utf-8-sig").splitlines()
    require(len(loaded) >= 4 and Path(loaded[0]).resolve() == (folder / "bin" / MODULES[0]).resolve()
            and Path(loaded[2]).resolve() == (folder / "private.ini").resolve()
            and Path(loaded[3]).resolve() == (folder / "bin" / MODULES[1]).resolve(), "Loaded native/private INI paths differ: " + test)
    require(run.get("loaded_native") == loaded, "Loaded identity log differs from receipt: " + test)
    return test, {"path": str(path), "sha256": sha(path), "sources": run["sources"]}


def snapshot_inputs(source, target, names):
    target.mkdir(parents=True, exist_ok=False)
    records = {}
    for name in names:
        original, copied = source / name, target / name
        value = sha(original)
        shutil.copy2(original, copied)
        require(sha(copied) == value, "Independent input copy differs: " + name)
        records[name] = {"source_path": str(original), "copy_path": str(copied), "sha256": value}
    return records


def check_inputs(records, expected):
    require(set(records) == set(expected), "Independent proof input coverage changed")
    for item in records.values():
        require(sha(Path(item["source_path"])) == item["sha256"] == sha(Path(item["copy_path"])), "Independent source/copy identity changed: " + item["source_path"])


def verifier_records(names, sources):
    result = {}
    for name in names:
        path = ROOT / "tools" / name
        value = sha(path)
        require(value == sources.get("tools/" + name), "Independent verifier differs from frozen inputs: " + name)
        result[name] = {"path": str(path), "sha256": value}
    return result


def run_verifier(command, log):
    run = subprocess.run(command, cwd=ROOT, text=True, encoding="utf-8", stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    log.write_text(run.stdout, encoding="utf-8")
    require(run.returncode == 0, "Independent verifier failed; see " + str(log))
    return run.stdout


def check_proof_result(key, result, producer_sha):
    spec = PROOFS[key]
    require(result.get("status") == "passed", "Independent proof failed: " + key)
    if key == "inspector":
        require(set(result.get("files", {})) == {Path(n).stem for n in EXPORT_FILES}, "Incomplete inspector proof")
        return
    require(result.get("host_receipt_sha256") == producer_sha, "Independent proof has a different producer: " + key)
    cases = result.get("cases", {})
    require(len(cases) == spec[5] and all(item.get("status") == "passed" for item in cases.values()), "Incomplete independent mesh cases: " + key)
    controls = result.get("negative_controls", [])
    require(len(controls) == spec[6] and len({c.get("case") for c in controls}) == spec[6]
            and all(c.get("status") == "correctly-rejected" for c in controls), "Missing independent invalid-geometry controls: " + key)


def independent_proofs(hosts, sources, evidence_root):
    by_test = {read_json(folder / "receipt.json")["test_script"]: folder for folder in hosts}
    proofs = {}
    for key, (test, verifier, output, inputs, dependencies, _, _) in PROOFS.items():
        source = by_test["tests/max/" + test]
        copied = evidence_root / key
        records = snapshot_inputs(source, copied, ("receipt.json",) + inputs)
        verifiers = verifier_records(dependencies, sources)
        run_verifier([sys.executable, str(ROOT / "tools" / verifier), str(copied)], copied / "verification.log")
        result = copied / output
        check_proof_result(key, read_json(result), records["receipt.json"]["sha256"])
        check_inputs(records, ("receipt.json",) + inputs)
        proofs[key] = {"status": "passed", "producer_test": "tests/max/" + test,
                       "inputs": records, "verifiers": verifiers,
                       "result": {"path": str(result), "sha256": sha(result)}}
    return proofs


def check_performance_isolation(path, runs):
    record = read_json(path)
    expected = [{"receipt": str(folder / "receipt.json"), "sha256": sha(folder / "receipt.json")} for folder in runs]
    require(record.get("no_overlapping_qa_workload") is True, "Final performance requires an explicit no-overlapping-QA attestation")
    require(record.get("scope") == PERFORMANCE_SCOPE, "Performance scope must match the bounded backend workload")
    require(record.get("runs") == expected, "Performance isolation record does not bind the ordered exact receipts")
    return {"path": str(path), "sha256": sha(path), "kind": "explicit-driver-or-operator-attestation; not independently measured machine idleness"}


def check_performance_result(result, ordered):
    require(result.get("status") == "validated_two_opposite_order_runs" and len(result.get("runs", [])) == 2,
            "Incomplete opposite-order cache proof")
    for index, (item, folder) in enumerate(zip(result["runs"], ordered)):
        receipt = read_json(folder / "receipt.json")
        require(item.get("status") == "validated_raw_cache_command_samples"
                and item.get("reverse_order") is bool(index)
                and item.get("owned_pid") == receipt.get("pid"),
                "Cache raw evidence PID/schedule differs from its actual host receipt")
    require(result["runs"][0]["owned_pid"] != result["runs"][1]["owned_pid"], "Performance needs distinct owned processes")


def independent_performance(runs, isolation, build, sources, evidence_root):
    require(len(runs) == 2 and len(set(runs)) == 2, "Supply exactly two distinct performance runs")
    records = {}
    for folder in runs:
        test, record = validate_host(folder, build, PERFORMANCE_TESTS)
        require(test not in records, "Duplicate performance schedule: " + test)
        records[test] = (folder, record)
    require(set(records) == set(PERFORMANCE_TESTS), "Both normal and reverse performance schedules are required")
    ordered = [records[test][0] for test in PERFORMANCE_TESTS]
    attestation = check_performance_isolation(isolation, ordered)
    inputs = {}
    for label, folder in zip(("normal", "reverse"), ordered):
        inputs[label] = snapshot_inputs(folder, evidence_root / label, ("receipt.json",) + PERFORMANCE_INPUTS)
    verifiers = verifier_records(("verify_cache_performance.py",), sources)
    output = evidence_root / "cache-performance-validation.json"
    command = [sys.executable, str(ROOT / "tools/verify_cache_performance.py"), str(evidence_root / "normal"), "--opposite-run", str(evidence_root / "reverse")]
    result_text = run_verifier(command, evidence_root / "verification.log")
    result = json.loads(result_text)
    check_performance_result(result, ordered)
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    for captured in inputs.values():
        check_inputs(captured, ("receipt.json",) + PERFORMANCE_INPUTS)
    require(sha(isolation) == attestation["sha256"], "Performance isolation record changed during validation")
    return {"status": "validated_two_opposite_order_runs", "scope": PERFORMANCE_SCOPE,
            "host_receipts": {test: record for test, (_, record) in records.items()},
            "isolation": attestation, "inputs": inputs, "verifiers": verifiers,
            "result": {"path": str(output), "sha256": sha(output)}}


def validate_receipts(native, hosts, performance_runs, performance_isolation, reuse_functional_runtime=False):
    sources = source_hashes()
    build = read_json(native / "receipt.json")
    require(build.get("status") == "passed" and build.get("version") == VERSION and build.get("max_year") == 2027,
            "A passed full Max 2027 build of version " + VERSION + " is required")
    original = build.get("sources", {})
    require(set(original) == set(sources), "Source input paths were added or removed after the qualified build")
    require(bool(original) and functional_source_map(original) == functional_source_map(sources), "Runtime/functional inputs changed after the qualified build")
    require(reuse_functional_runtime or original == sources, "Build does not match every current input; deployment-only evidence reuse requires explicit --reuse-functional-runtime")
    require(all(build.get("binaries", {}).get(n) == sha(native / n) for n in MODULES), "Both native binaries must match the build receipt")
    require({s["name"] for s in build.get("stages", []) if s.get("exit_code") == 0} >= {"configure", "build", "tests"}, "Full build/CTest stages must pass")
    receipts = {}
    for folder in hosts:
        test, record = validate_host(folder, build, REQUIRED_TESTS)
        require(test not in receipts, "Supply exactly one final receipt for " + test)
        receipts[test] = record
    require(set(receipts) == set(REQUIRED_TESTS), "Missing functional suites: " + ", ".join(sorted(set(REQUIRED_TESTS) - set(receipts))))
    (ROOT / "build").mkdir(exist_ok=True)
    evidence_root = Path(tempfile.mkdtemp(prefix="package-032-proofs-", dir=ROOT / "build"))
    proofs = independent_proofs(hosts, original, evidence_root)
    performance = independent_performance(performance_runs, performance_isolation, build, original, evidence_root / "performance")
    require(sources == source_hashes(), "Source inputs changed during qualification")
    return build, sources, receipts, proofs, performance


def validate_saved_proofs(proofs, performance, sources, hosts, build):
    require(set(proofs) == set(PROOFS), "Independent proof families are incomplete")
    (ROOT / "build").mkdir(exist_ok=True)
    rerun = Path(tempfile.mkdtemp(prefix="package-032-recheck-", dir=ROOT / "build"))
    for key, (test, verifier, output, inputs, dependencies, _, _) in PROOFS.items():
        proof = proofs[key]
        expected_test = "tests/max/" + test
        producer = hosts[expected_test]
        require(proof.get("status") == "passed" and proof.get("producer_test") == expected_test, "Independent producer family changed: " + key)
        check_inputs(proof["inputs"], ("receipt.json",) + inputs)
        require(proof["verifiers"] == verifier_records(dependencies, sources), "Independent verifier dependency identity changed: " + key)
        receipt_input = proof["inputs"]["receipt.json"]
        require(Path(receipt_input["source_path"]).resolve() == Path(producer["path"]).resolve()
                and receipt_input["sha256"] == producer["sha256"], "Independent proof is not bound to the exact accepted host: " + key)
        source_dir = Path(producer["path"]).parent
        copy_dir = Path(receipt_input["copy_path"]).parent
        require(all(Path(item["source_path"]).resolve() == (source_dir / name).resolve()
                    and Path(item["copy_path"]).resolve() == (copy_dir / name).resolve()
                    for name, item in proof["inputs"].items()), "Independent input path is outside its exact producer/snapshot: " + key)
        result_path = Path(proof["result"]["path"])
        require(result_path == copy_dir / output and sha(result_path) == proof["result"]["sha256"], "Independent result identity changed: " + key)
        saved = read_json(result_path)
        check_proof_result(key, saved, producer["sha256"])
        target = rerun / key
        snapshot_inputs(copy_dir, target, ("receipt.json",) + inputs)
        run_verifier([sys.executable, str(ROOT / "tools" / verifier), str(target)], target / "verification.log")
        require(read_json(target / output) == saved, "Recomputed independent proof differs: " + key)
    require(performance.get("status") == "validated_two_opposite_order_runs" and performance.get("scope") == PERFORMANCE_SCOPE, "Performance gate is missing or has a broader scope")
    require(set(performance.get("host_receipts", {})) == set(PERFORMANCE_TESTS), "Performance host coverage changed")
    require(set(performance.get("inputs", {})) == {"normal", "reverse"}, "Performance input coverage changed")
    ordered = []
    for label, test in zip(("normal", "reverse"), PERFORMANCE_TESTS):
        record = performance["host_receipts"][test]
        path = Path(record["path"])
        require(sha(path) == record["sha256"], "Performance producer receipt changed")
        actual_test, actual_record = validate_host(path.parent, build, PERFORMANCE_TESTS)
        require(actual_test == test and actual_record == record, "Performance producer identity changed")
        captured = performance["inputs"][label]
        check_inputs(captured, ("receipt.json",) + PERFORMANCE_INPUTS)
        require(captured["receipt.json"]["sha256"] == record["sha256"], "Performance input receipt differs from accepted host")
        copy_dir = Path(captured["receipt.json"]["copy_path"]).parent
        require(all(Path(item["source_path"]).resolve() == (path.parent / name).resolve()
                    and Path(item["copy_path"]).resolve() == (copy_dir / name).resolve()
                    for name, item in captured.items()), "Performance inputs are outside the exact producer/snapshot")
        snapshot_inputs(copy_dir, rerun / label, ("receipt.json",) + PERFORMANCE_INPUTS)
        ordered.append(path.parent)
    isolation = performance["isolation"]
    require(sha(Path(isolation["path"])) == isolation["sha256"]
            and check_performance_isolation(Path(isolation["path"]), ordered) == isolation, "Performance isolation record changed")
    require(performance["verifiers"] == verifier_records(("verify_cache_performance.py",), sources), "Cache verifier identity changed")
    path = Path(performance["result"]["path"])
    require(sha(path) == performance["result"]["sha256"], "Performance result changed")
    text = run_verifier([sys.executable, str(ROOT / "tools/verify_cache_performance.py"), str(rerun / "normal"), "--opposite-run", str(rerun / "reverse")], rerun / "performance-verification.log")
    result = json.loads(text)
    check_performance_result(result, ordered)
    require(result == read_json(path), "Recomputed performance proof differs")


def mxs_rows(files):
    return "#(" + ",".join("#(" + json.dumps(n) + "," + json.dumps(digest(data)) + ")" for n, data in sorted(files.items())) + ")"


def render(text, tokens):
    for key, value in tokens.items():
        text = text.replace(key, value)
    require("__PAYLOAD_" not in text and "__CORE_" not in text and "__INSTALL_" not in text and "__VERSION__" not in text, "Unresolved installer template token")
    return text.encode("utf-8")


def create_candidate(native, hosts, out, performance_runs, performance_isolation, reuse_functional_runtime=False):
    require(out.is_relative_to(ROOT / "dist") and out != ROOT / "dist", "Use a fresh candidate folder under CyrusArrange/dist")
    require(not out.exists(), "Candidate output already exists; preserve it")
    build, sources, runs, proofs, performance = validate_receipts(native, hosts, performance_runs, performance_isolation, reuse_functional_runtime)
    core = {INSTALLED_MODULES[n]: (native / n).read_bytes() for n in MODULES}
    core.update({n: (ROOT / "scripts" / n).read_bytes() for n in UI_SCRIPTS})
    require(all(digest(core[INSTALLED_MODULES[name]]) == build["binaries"][name] for name in MODULES), "Copied native payload bytes differ from the qualified build")
    require(all(digest(core[name]) == sources["scripts/" + name] == build["sources"]["scripts/" + name] for name in UI_SCRIPTS), "Copied UI payload bytes differ from the qualified/current script inputs")
    docs = {"README.md": (ROOT / "README.md").read_bytes(), "licenses/Clipper2-LICENSE.txt": (ROOT / "third_party/clipper2/LICENSE").read_bytes()}
    docs.update({p.relative_to(ROOT).as_posix(): p.read_bytes() for p in (ROOT / "docs").rglob("*") if p.is_file()})
    templates = {p.name: p.read_text(encoding="utf-8") for p in (ROOT / "installer").iterdir() if p.is_file()}
    identity_data = {"version": VERSION, "files": {n: digest(b) for n, b in sorted((core | docs).items())}, "templates": {n: digest(t.encode()) for n, t in sorted(templates.items())}}
    identity = digest(json.dumps(identity_data, sort_keys=True, separators=(",", ":")).encode())[:16]
    tokens = {"__VERSION__": VERSION, "__PAYLOAD_ID__": identity, "__CORE_FILES__": mxs_rows(core)}
    startup = render(templates["CyrusArrangeStartup.ms"], tokens)
    macro = render(templates["CyrusArrange.mcr"], tokens)
    installed = core | docs | {"CyrusArrangeStartup.ms": startup, "CyrusArrange.mcr": macro}
    installed_record = {"product": "Cyrus Arrange", "version": VERSION, "max_year": 2027, "payload_id": identity, "files": {n: digest(b) for n, b in sorted(installed.items())}}
    installed["installed-manifest.json"] = (json.dumps(installed_record, indent=2) + "\n").encode()
    tokens["__INSTALL_FILES__"] = mxs_rows(installed)
    payload = installed | {"install.ms": render(templates["install.ms"], tokens), "mzp.run": render(templates["mzp.run"], tokens)}
    manifest = {"product": "Cyrus Arrange", "version": VERSION, "max_year": 2027, "payload_id": identity, "utc": now(), "status": "candidate-awaiting-isolated-installer-qualification", "files": {n: digest(b) for n, b in sorted(payload.items())}, "installed_files": {n: digest(b) for n, b in sorted(installed.items())}, "sources": sources, "functional_sources": functional_source_map(sources), "qualification_policy": REUSE_POLICY if reuse_functional_runtime else EXACT_POLICY, "acceptance_policy": ACCEPTANCE_POLICY, "deployment_inputs": list(DEPLOYMENT_INPUTS), "deployment_source_changes": deployment_changes(build["sources"], sources), "build_receipt": {"path": str(native / "receipt.json"), "sha256": sha(native / "receipt.json"), "sources": build["sources"]}, "host_receipts": runs, "independent_proofs": proofs, "cache_performance": performance, "required_tests": list(REQUIRED_TESTS), "artist_installation_executed": False}
    payload["manifest.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    require(sources == source_hashes(), "Source inputs changed while constructing candidate")
    out.mkdir(parents=True, exist_ok=False)
    archive = out / ("CyrusArrange-" + VERSION + "-Max2027.mzp")
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as handle:
        for name, data in sorted(payload.items()):
            handle.writestr(name, data)
    with zipfile.ZipFile(archive) as handle:
        require(handle.testzip() is None and set(handle.namelist()) == set(payload), "Archive integrity/member mismatch")
        require(all(handle.read(n) == data for n, data in payload.items()), "Archive bytes differ from qualified candidate")
    receipt = manifest | {"archive": str(archive), "archive_sha256": sha(archive), "archive_payload_verified": True, "manifest_sha256": digest(payload["manifest.json"])}
    (out / "package-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return receipt


def validate_candidate(folder):
    receipt = read_json(folder / "package-receipt.json")
    archive = Path(receipt["archive"])
    require(archive.parent.resolve() == folder.resolve() and sha(archive) == receipt["archive_sha256"], "Candidate archive changed")
    require(receipt.get("version") == VERSION and receipt.get("sources") == source_hashes(), "Candidate no longer matches current inputs")
    original = receipt["build_receipt"].get("sources", {})
    require(set(original) == set(receipt["sources"]), "Candidate source input paths were added or removed")
    require(receipt.get("deployment_inputs") == list(DEPLOYMENT_INPUTS), "Candidate has a different deployment dependency partition")
    require(receipt.get("qualification_policy") in (EXACT_POLICY, REUSE_POLICY), "Candidate has an unknown qualification policy")
    require(receipt.get("acceptance_policy") == ACCEPTANCE_POLICY, "Candidate has a different release acceptance policy")
    require(receipt["qualification_policy"] == REUSE_POLICY or original == receipt["sources"], "Strict candidate source identity changed")
    require(bool(original) and receipt.get("functional_sources") == functional_source_map(receipt["sources"]) == functional_source_map(original), "Candidate runtime/functional identity differs from the qualified build")
    require(receipt.get("deployment_source_changes") == deployment_changes(original, receipt["sources"]), "Candidate deployment changes are not recorded exactly")
    require(receipt.get("required_tests") == list(REQUIRED_TESTS) and set(receipt.get("host_receipts", {})) == set(REQUIRED_TESTS), "Candidate functional suite coverage is incomplete")
    require(receipt.get("archive_payload_verified") is True and receipt.get("artist_installation_executed") is False, "Candidate has not passed archive/isolation validation")
    require({name for name in receipt["installed_files"] if name.startswith("bin/")} == set(INSTALLED_MODULES.values()), "The registered bin directory must contain exactly the two native modules")
    require(all(name in receipt["installed_files"] for name in UI_SCRIPTS) and not set(MODULES) & set(receipt["installed_files"]), "Native modules and UI scripts must use their distinct installed paths")
    for evidence in [receipt["build_receipt"], *receipt["host_receipts"].values()]:
        require(sha(Path(evidence["path"])) == evidence["sha256"], "Qualified build/host evidence changed: " + evidence["path"])
        require(evidence.get("sources") == original == read_json(Path(evidence["path"])).get("sources"), "Original complete source maps do not match: " + evidence["path"])
    build = read_json(Path(receipt["build_receipt"]["path"]))
    for test, record in receipt["host_receipts"].items():
        actual_test, actual_record = validate_host(Path(record["path"]).parent, build, REQUIRED_TESTS)
        require(actual_test == test and actual_record == record, "Current host evidence no longer matches candidate: " + test)
    require(all(receipt["installed_files"][INSTALLED_MODULES[name]] == build["binaries"][name] for name in MODULES), "Candidate native modules differ from the qualified build")
    validate_saved_proofs(receipt["independent_proofs"], receipt["cache_performance"], original, receipt["host_receipts"], build)
    with zipfile.ZipFile(archive) as handle:
        require(handle.testzip() is None, "Candidate ZIP is damaged")
        expected = set(receipt["files"]) | {"manifest.json"}
        require(set(handle.namelist()) == expected and len(handle.namelist()) == len(expected), "Candidate ZIP member list changed")
        require(all(digest(handle.read(n)) == value for n, value in receipt["files"].items()), "Candidate payload mismatch")
        require(all(digest(handle.read(name)) == receipt["sources"]["scripts/" + name] == original["scripts/" + name] for name in UI_SCRIPTS), "Archived UI bytes differ from the qualified/current script inputs")
        require(digest(handle.read("manifest.json")) == receipt["manifest_sha256"], "Candidate manifest changed")
        manifest = json.loads(handle.read("manifest.json"))
        require(all(manifest.get(key) == receipt.get(key) for key in manifest), "External candidate receipt differs from the embedded manifest")
        require(set(receipt["installed_files"]) <= set(receipt["files"]) and all(receipt["files"][name] == value for name, value in receipt["installed_files"].items()), "Installed payload hashes differ from archive hashes")
    require(receipt["sources"] == source_hashes(), "Source inputs changed during candidate revalidation")
    return receipt


def finalize(folder, installer_run):
    candidate = validate_candidate(folder)
    path = installer_run / "receipt.json"
    run = read_json(path)
    require(run.get("status") == "passed" and run.get("archive_sha256") == candidate["archive_sha256"] and run.get("sources") == candidate["sources"], "Installer qualification does not match the unchanged candidate")
    require(all(run.get(k) is True for k in ("actual_mzp_executed", "installed_startup_passed", "installed_payload_verified", "artist_profiles_unchanged", "private_profiles_verified")), "Installer/startup/isolation gates are incomplete")
    require(run.get("computer_use") is False and run.get("artist_installation_executed") is False, "Artist profile installation is forbidden for qualification")
    require(run.get("archive_unchanged") is True and run.get("loaded_path_matches") is True and run.get("private_ini_matches") is True, "Installed module/private INI identity checks are missing")
    require(run.get("installed_modules") == {name: candidate["files"][INSTALLED_MODULES[name]] for name in MODULES}, "Installed native pair does not match the candidate")
    require(run.get("candidate_receipt", {}).get("sha256") == sha(folder / "package-receipt.json"), "Installer run used a different candidate receipt")
    for phase, test in (("install", "tests/max/installer_tests.ms"), ("startup", "tests/max/installed_startup_tests.ms")):
        data = run.get("phases", {}).get(phase, {})
        require(data.get("status") == "passed" and data.get("exit_code") == 0 and data.get("report", "").startswith("SUCCESS") and data.get("private_profile_marker") is True, "Missing installer phase: " + phase)
        require(data.get("test_script") == test and data.get("test_sha256") == candidate["sources"][test], "Installer test identity mismatch: " + phase)
        if phase == "startup":
            require(data.get("host_mode") == "owned-interactive-command-panel", "Installed Modify controls require an owned interactive host")
    final = {"status": "qualified", "version": VERSION, "utc": now(), "archive": candidate["archive"], "archive_sha256": candidate["archive_sha256"], "sources": candidate["sources"], "functional_sources": candidate["functional_sources"], "qualification_policy": candidate["qualification_policy"], "acceptance_policy": candidate["acceptance_policy"], "deployment_inputs": candidate["deployment_inputs"], "deployment_source_changes": candidate["deployment_source_changes"], "build_receipt": candidate["build_receipt"], "host_receipts": candidate["host_receipts"], "independent_proofs": candidate["independent_proofs"], "cache_performance": candidate["cache_performance"], "installer_receipt": {"path": str(path), "sha256": sha(path)}, "artist_installation_executed": False, "archive_unchanged_after_installer_tests": True}
    output = folder / "qualification-receipt.json"
    require(not output.exists(), "Qualification receipt already exists; preserve it")
    output.write_text(json.dumps(final, indent=2) + "\n", encoding="utf-8")
    return final


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="mode", required=True)
    candidate = sub.add_parser("candidate")
    candidate.add_argument("--binary-dir", type=Path, required=True)
    candidate.add_argument("--host-run", type=Path, action="append", required=True)
    candidate.add_argument("--performance-run", type=Path, action="append", required=True, help="Normal and reverse backend benchmark folders; separate from the 32 correctness suites")
    candidate.add_argument("--performance-isolation", type=Path, required=True, help="Exact-receipt no-overlapping-QA driver/operator attestation; see release policy")
    candidate.add_argument("--output", type=Path, required=True)
    candidate.add_argument("--reuse-functional-runtime", action="store_true", help="Explicitly permit only the eight named deployment inputs to differ from the original full build/host source maps")
    final = sub.add_parser("finalize")
    final.add_argument("--candidate", type=Path, required=True)
    final.add_argument("--installer-run", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = create_candidate(args.binary_dir.resolve(), [p.resolve() for p in args.host_run], args.output.resolve(), [p.resolve() for p in args.performance_run], args.performance_isolation.resolve(), args.reuse_functional_runtime) if args.mode == "candidate" else finalize(args.candidate.resolve(), args.installer_run.resolve())
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        parser.exit(1, str(error) + "\n")
    print(json.dumps({k: result[k] for k in ("status", "version", "archive", "archive_sha256")}, indent=2))


if __name__ == "__main__":
    main()
