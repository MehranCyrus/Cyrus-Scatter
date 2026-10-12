#!/usr/bin/env python3
"""Build a bounded, local-only file catalog. Python 3.11+, standard library only."""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import os
import sys
import tempfile
import time
from pathlib import Path

if sys.version_info < (3, 11):
    sys.stderr.write("ERROR: Python 3.11+ is required. On Windows use py -3.11.\n")
    raise SystemExit(2)

from catalog import (SCHEMA_VERSION, TOOL_VERSION, assign_duplicates, assign_git,
                     error, git_snapshot, is_link, progress, read_controls,
                     reconcile, scan_tree, verify_scan)
from reporting import statistics, write_artifacts
from rules import ConfigError, load_config, path_key

SUCCESS, INVALID, INCOMPLETE = 0, 2, 3


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds")


def prepare_output(root: Path, output: Path) -> Path:
    # Inspect ancestors without resolving a possible junction into its target.
    output = Path(os.path.abspath(output))
    allowed = root / "_local" / "rag" / "out"
    if not output.is_relative_to(allowed) or output == allowed:
        raise ConfigError("--out must be a fresh run directory inside <root>/_local/rag/out/")
    current = root
    for part in output.relative_to(root).parts:
        current = current / part
        try:
            metadata = current.lstat()
        except FileNotFoundError:
            continue
        if is_link(metadata):
            raise ConfigError(f"output ancestor is a link/reparse point: {current}")
    if output.exists():
        raise ConfigError(f"destination already exists (even an empty directory): {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    return Path(tempfile.mkdtemp(prefix=f".{output.name}.partial-", dir=output.parent))


def run_audit(root: Path, output: Path, config_path: Path) -> tuple[int, Path]:
    started = utc_now()
    timer = time.monotonic()
    root = root.resolve(strict=True)
    config = load_config(config_path)
    configuration_hash = hashlib.sha256(config_path.read_bytes()).hexdigest()
    initial = git_snapshot(root)
    stage = prepare_output(root, output)
    output = Path(os.path.abspath(output))
    errors = []
    rows, excluded, issues, duplicates, audit = [], [], [], [], []
    controls = {"versions": [], "hashes": {}, "inventory": {}, "source_manifests": {}}
    final = None
    try:
        progress(f"Scanning {root} | {initial['branch'] or '(detached)'} @ {initial['head']}")
        controls = read_controls(root, config, errors)
        rows, excluded, issues, identities, directories = scan_tree(root, config, controls, errors)
        progress(f"Verifying {len(rows):,} cataloged files and Git membership...")
        assign_git(rows, initial, root)
        verify_scan(root, rows, identities, directories, errors)
        observed = {path_key(r["path"]): r for r in rows}
        for path, digest in controls["hashes"].items():
            if observed.get(path_key(path), {}).get("sha256") != digest:
                errors.append(error(path, "verify_control_input", "control input hash differs from catalog snapshot"))
        if hashlib.sha256(config_path.read_bytes()).hexdigest() != configuration_hash:
            errors.append(error(str(config_path), "verify_configuration", "configuration changed during run"))
        final = git_snapshot(root)
        if initial != final:
            errors.append(error(".", "verify_git_state", "branch, HEAD, index membership or working-tree state changed during scan"))
        duplicates = assign_duplicates(rows)
        audit = reconcile(rows, excluded, controls, config)
    except (OSError, RuntimeError, ValueError) as exc:
        errors.append(error(".", "scan", str(exc)))
    rows.sort(key=lambda r: (path_key(r["path"]), r["path"]))
    excluded.sort(key=lambda r: (path_key(r["path"]), r["path"]))
    issues = [dict(zip(("folder", "issue", "token"), item)) for item in
              sorted({(i["folder"], i["issue"], i["token"]) for i in issues})]
    errors.sort(key=lambda e: (path_key(e["path"]), e["operation"], e["error"]))
    run = {"tool_version": TOOL_VERSION, "schema_version": SCHEMA_VERSION, "root": str(root),
           "branch": initial["branch"], "head": initial["head"], "initial_git_state": initial,
           "final_git_state": final, "started_utc": started, "ended_utc": utc_now(),
           "duration_seconds": round(time.monotonic() - timer, 6),
           "configuration_path": str(config_path.resolve()), "configuration_sha256": configuration_hash,
           "documentation_inventory_sha256": controls["hashes"].get(config["inventory"]),
           "control_input_sha256": controls["hashes"],
           "source_manifest_sha256": {p: controls["hashes"].get(p) for p in config["source_manifests"]},
           "versions": controls["versions"], "scan_complete": not errors,
           "outcome": "complete" if not errors else "incomplete", "errors": errors,
           "inspection_policy": config["inspection"], "max_hash_bytes": config["max_hash_bytes"],
           "statistics": statistics(rows, duplicates, errors),
           "tool_source_sha256": {r["path"]: r["sha256"] for r in rows if r["path"].startswith("tools/rag/")},
           "artifact_directory": str(output if not errors else stage)}
    try:
        write_artifacts(stage, rows, duplicates, audit, excluded, issues, controls["versions"], errors, config, run)
        run.update(ended_utc=utc_now(), duration_seconds=round(time.monotonic() - timer, 6))
        from reporting import write_json
        write_json(stage / "run.json", run)
        if errors:
            for item in errors:
                progress(f"ERROR {item['path']} [{item['operation']}]: {item['error']}")
            progress(f"INCOMPLETE: diagnostics and partial artifacts retained at {stage}")
            return INCOMPLETE, stage
        if output.exists():
            raise OSError("destination appeared concurrently; refusing publication")
        stage.rename(output)
    except OSError as exc:
        progress(f"ERROR publishing output: {exc}; temporary artifacts, if writable: {stage}")
        # Existing successful output is never replaced. Mark any surviving staged run incomplete.
        from reporting import write_json, write_jsonl
        run.update(scan_complete=False, outcome="incomplete", artifact_directory=str(stage))
        run["errors"].append(error(str(stage), "publish", str(exc)))
        run["statistics"]["error_count"] = len(run["errors"])
        try:
            write_json(stage / "run.json", run)
            write_jsonl(stage / "errors.jsonl", run["errors"])
            (stage / "summary.md").write_text("# INCOMPLETE publication\n\nSee run.json and errors.jsonl. Artifacts in this temporary directory are partial.\n", encoding="utf-8")
            for suffix in ("jsonl", "csv"):
                if (stage / f"manifest.{suffix}").exists():
                    (stage / f"manifest.{suffix}").rename(stage / f"manifest.partial.{suffix}")
        except OSError:
            pass  # The stderr diagnostic remains available when storage cannot accept diagnostics.
        return INCOMPLETE, stage
    progress(f"COMPLETE: {len(rows):,} files, {len(duplicates):,} duplicate groups, "
             f"{run['duration_seconds']:.3f}s; {output}")
    return SUCCESS, output


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="Git repository root")
    parser.add_argument("--out", type=Path, required=True, help="fresh <root>/_local/rag/out/<run-name>")
    parser.add_argument("--config", type=Path, default=Path(__file__).with_name("config.toml"))
    args = parser.parse_args(argv)
    try:
        return run_audit(args.root, args.out, args.config)[0]
    except (ConfigError, OSError, RuntimeError, ValueError) as exc:
        progress(f"ERROR configuration/usage: {exc}")
        return INVALID


if __name__ == "__main__":
    sys.exit(main())
