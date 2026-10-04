"""Reproduce this research package's documentation and contract checks.

Run from the repository with its existing MCP virtual environment:
    build/mcp-venv/Scripts/python.exe docs/Artist_Style_ML_2026-10-04/evidence/verify_examples.py

This does not connect to Max, run a model, or implement a recipe compiler.
It rewrites only this folder's source_snapshot.json and validation.json.
"""
from __future__ import annotations

import copy
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parents[1]
EVIDENCE = PACKAGE / "evidence"
EXPECTED_HEAD = "e3518f8f87f3144d531f20afbb6790ce243f2cfc"
sys.path.insert(0, str(ROOT / "CyrusMCP"))

from cyrus_mcp.contracts import Fault, validate_shape
from cyrus_mcp.models import DesignPlanV2
from cyrus_mcp.settings import normalize_v2
from pydantic import ValidationError


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    head = git("rev-parse", "HEAD")
    if head != EXPECTED_HEAD:
        raise RuntimeError("Source baseline changed; review and update this dated verification before rerunning.")
    changed = git("diff", "--name-only", "HEAD").splitlines()
    unexpected = [p for p in changed if p != "README.md" and not p.startswith("docs/")]
    untracked = git("ls-files", "--others", "--exclude-standard").splitlines()
    unexpected += [p for p in untracked if not p.startswith("docs/")]
    if unexpected:
        raise RuntimeError(f"Non-documentation changes require separate review: {unexpected}")

    source_paths = [
        "CyrusMCP/cyrus_mcp/server.py", "CyrusMCP/cyrus_mcp/models.py",
        "CyrusMCP/cyrus_mcp/contracts.py", "CyrusMCP/cyrus_mcp/settings.py",
        "CyrusMCP/cyrus_mcp/service.py", "CyrusMCP/cyrus_mcp/max_host.py",
        "CyrusMCP/cyrus_mcp/records.py", "AminScatter/include/scatter.h",
        "AminScatter/src/scatter.cpp", "AminScatter/src/cluster.inc",
        "AminScatter/src/edge_border.inc", "AminScatter/src/max_bridge.cpp",
        "AminScatter/tools/ui/templates/logical-layers.ms",
        "AminScatter/tools/ui/planting-groups.cjs",
        "AminScatter/tools/ui/procedural-brush.cjs", "CyrusMCP/README.md",
        "docs/Layers_First_2026-10-03/CAPABILITIES.md",
    ]
    snapshot = {
        "source_commit": head,
        "hash_kind": "SHA-256 of working-tree bytes; not normalized Git blobs",
        "files": [{"path": p, "sha256": hashlib.sha256((ROOT / p).read_bytes()).hexdigest()} for p in source_paths],
    }
    write_json(EVIDENCE / "source_snapshot.json", snapshot)

    plan = read_json(PACKAGE / "examples/compiled-plan-v2.json")
    recipe = read_json(PACKAGE / "examples/design-recipe.json")
    profile = read_json(PACKAGE / "examples/artist-style-profile.json")
    parsed = DesignPlanV2.model_validate(plan)
    total = validate_shape(plan)
    normalized = normalize_v2(plan)
    if total != 640 or validate_shape(normalized) != total:
        raise AssertionError("Unexpected example candidate count")
    model_dump = parsed.model_dump(exclude_none=True)
    if normalize_v2(model_dump) != normalized:
        raise AssertionError("Pydantic and host-side normalized examples differ")
    if recipe["profile_id"] != profile["profile_id"] or recipe["profile_revision"] != profile["revision"]:
        raise AssertionError("Profile linkage mismatch")
    if recipe["expressibility"]["apply_ready"] is not False:
        raise AssertionError("Synthetic recipe must not be apply-ready")
    for proposal, actual in zip(recipe["layers"], plan["layers"], strict=True):
        binding = recipe["example_binding"]
        assert actual["name"] == proposal["name"]
        assert actual["count"] == proposal["population"]["count"]
        assert actual["region_id"] == binding["zones"][proposal["zone"]]
        assert actual["sources"][0]["source_id"] == binding["roles"][proposal["role"]]
        for key in ("seed", "scale", "yaw_degrees", "underfill"):
            assert actual[key] == proposal[key]

    unsupported = copy.deepcopy(plan)
    unsupported["style_profile"] = {"profile_id": profile["profile_id"]}
    rejected = []
    for name, validator, expected_exception in (
        ("Pydantic", DesignPlanV2.model_validate, ValidationError),
        ("independent_host_shape", validate_shape, Fault),
    ):
        try:
            validator(unsupported)
        except expected_exception:
            rejected.append(name)
        else:
            raise AssertionError(f"{name} accepted unsupported style_profile")

    with (PACKAGE / "sources.csv").open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    assert len(rows) == 24 and len({r["id"] for r in rows}) == len(rows)
    assert all(None not in r and all(v for v in r.values()) for r in rows)
    assert all(r["url"].startswith("https://") for r in rows)

    # Create the report before checking links to it; overwrite it with complete results below.
    report = {
        "checked_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_commit": head,
        "scope": "Documentation and synthetic schema examples only",
        "production_source_changed": False,
        "runtime_checks": {"max_opened": False, "scene_applied": False, "model_inference": False, "training": False, "performance_benchmark": False},
        "checks": {},
    }
    write_json(EVIDENCE / "validation.json", report)
    checked_links = 0
    md_files = sorted(PACKAGE.rglob("*.md"))
    indexed_files = [ROOT / "README.md", ROOT / "docs/README.md", ROOT / "docs/AI_MCP_ML_Roadmap_2026-09-30/README.md"]
    for md in md_files + indexed_files:
        for _, target in re.findall(r"\[([^\]]+)\]\(([^)]+)\)", md.read_text(encoding="utf-8")):
            if target.startswith(("https://", "http://", "#")):
                continue
            if md in indexed_files and "Artist_Style_ML_2026-10-04" not in target:
                continue
            local = target.split("#", 1)[0].strip("<>")
            if not (md.parent / local).resolve().exists():
                raise AssertionError(f"Broken file link in {md.name}: {target}")
            checked_links += 1
    for example in sorted((PACKAGE / "examples").glob("*.json")):
        read_json(example)
    diff_check = subprocess.run(["git", "diff", "--check"], cwd=ROOT, capture_output=True, text=True)
    if diff_check.returncode:
        raise AssertionError(diff_check.stdout + diff_check.stderr)
    whitespace_issues = []
    for path in PACKAGE.rglob("*"):
        if path.is_file() and path.suffix in {".md", ".json", ".csv", ".py"}:
            for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if line != line.rstrip():
                    whitespace_issues.append(f"{path.name}:{i}")
    assert not whitespace_issues, whitespace_issues
    report["checks"] = {
        "pydantic_plan_2_0": "passed",
        "independent_host_shape_and_settings": "passed",
        "normalized_contract_equivalence": "passed",
        "example_linkage_and_hand_authored_mapping": "passed; not an implemented compiler",
        "aggregate_candidate_count": total,
        "unsupported_style_key_rejected_by": rejected,
        "local_file_links_checked": checked_links,
        "markdown_files_in_new_package": len(md_files),
        "primary_source_ledger_rows": len(rows),
        "source_files_hashed": len(source_paths),
        "git_diff_check": "passed",
        "new_package_trailing_whitespace": "none",
        "non_documentation_tracked_changes": unexpected,
    }
    write_json(EVIDENCE / "validation.json", report)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
