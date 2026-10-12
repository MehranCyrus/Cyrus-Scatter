"""Compare complete runs without treating run timestamps as deterministic data."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ARTIFACTS = ("manifest.jsonl", "manifest.csv", "inventory_audit.csv", "summary.md",
             "duplicates.json", "exclusions.csv", "path_token_issues.csv", "errors.jsonl")


def compare_runs(first: Path, second: Path) -> dict:
    runs = [json.loads((p / "run.json").read_text(encoding="utf-8")) for p in (first, second)]
    schemas = [r["schema_version"] for r in runs]
    if schemas[0] != schemas[1]:
        raise ValueError(f"incompatible manifest schemas: {schemas[0]} vs {schemas[1]}; not a determinism comparison")
    if not all(r["scan_complete"] for r in runs):
        raise ValueError("both inputs must be complete published runs")
    artifacts = {name: [hashlib.sha256((p / name).read_bytes()).hexdigest() for p in (first, second)] for name in ARTIFACTS}
    equal = all(pair[0] == pair[1] for pair in artifacts.values())
    config_equal = runs[0]["configuration_sha256"] == runs[1]["configuration_sha256"]
    control_equal = runs[0]["control_input_sha256"] == runs[1]["control_input_sha256"]
    git_equal = runs[0]["initial_git_state"] == runs[1]["initial_git_state"]
    snapshots = [{r["path"]: r for r in (json.loads(line) for line in (p / "manifest.jsonl").read_text(encoding="utf-8").splitlines())} for p in (first, second)]
    changed_paths = sorted(p for p in snapshots[0].keys() | snapshots[1].keys() if snapshots[0].get(p) != snapshots[1].get(p))
    return {"deterministic_artifacts_identical": equal, "configuration_identical": config_equal,
            "control_inputs_identical": control_equal, "initial_git_state_identical": git_equal,
            "observed_inputs_unchanged": config_equal and control_equal and git_equal and not changed_paths,
            "changed_paths": changed_paths, "artifact_sha256": artifacts}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("first", type=Path)
    parser.add_argument("second", type=Path)
    args = parser.parse_args(argv)
    try:
        result = compare_runs(args.first, args.second)
    except (OSError, ValueError, KeyError) as exc:
        print(json.dumps({"error": str(exc)}))
        return 2
    print(json.dumps(result, indent=2))
    return 0 if result["deterministic_artifacts_identical"] and result["observed_inputs_unchanged"] else 3


if __name__ == "__main__":
    raise SystemExit(main())
