"""Deterministic artifact writers; volatile observations belong in run.json."""
from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path

from catalog import FIELDS
from rules import AUDIT_FIELDS


def write_json(path: Path, value) -> None:
    path.write_text(json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")


def write_jsonl(path: Path, values: list[dict]) -> None:
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        for value in values:
            handle.write(json.dumps(value, ensure_ascii=True, separators=(",", ":")) + "\n")


def write_csv(path: Path, values: list[dict], fields: list[str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for value in values:
            writer.writerow({key: (json.dumps(item, ensure_ascii=True, separators=(",", ":")) if isinstance(item, list)
                                    else str(item).lower() if isinstance(item, bool) else item)
                             for key, item in value.items()})


def table(headers: list[str], rows: list[list]) -> list[str]:
    def cell(value):
        return str(value).replace("|", "\\|").replace("\n", " ").replace("\r", " ")
    return ["| " + " | ".join(headers) + " |", "| " + " | ".join("---" for _ in headers) + " |",
            *("| " + " | ".join(cell(v) for v in row) + " |" for row in rows), ""]


def statistics(rows: list[dict], duplicates: list[dict], errors: list[dict]) -> dict:
    return {"cataloged_files": len(rows), "known_size_bytes": sum(r["size_bytes"] for r in rows),
            "hash_coverage": dict(sorted(Counter(r["hash_status"] for r in rows).items())),
            "git_membership": dict(sorted(Counter(r["git_status"] for r in rows).items())),
            "duplicate_groups": len(duplicates),
            "potential_duplicate_bytes": sum(g["potential_duplicate_bytes"] for g in duplicates),
            "inventory_not_listed": sum(r["inventory_match"] == "not_listed" for r in rows),
            "missing_path_version": sum(r["path_version"] is None for r in rows),
            "missing_path_date": sum(r["path_date"] is None for r in rows), "error_count": len(errors)}


def summary(rows: list[dict], duplicates: list[dict], audit: list[dict], exclusions: list[dict],
            issues: list[dict], versions: list[dict], errors: list[dict], config: dict) -> str:
    stats = statistics(rows, duplicates, errors)
    complete = not errors
    lines = ["# CyrusScatter file catalog audit", "",
             "**Complete within the declared inspection scope.**" if complete else "**INCOMPLETE — partial artifacts; consult errors.jsonl.**", "",
             "[Run/provenance](run.json) · [JSONL](manifest.jsonl) · [CSV](manifest.csv) · "
             "[Inventory reconciliation](inventory_audit.csv) · [Exclusions](exclusions.csv) · "
             "[Duplicates](duplicates.json) · [Path token issues](path_token_issues.csv) · [Errors](errors.jsonl)", "",
             "## Scope and coverage", "",
             f"Cataloged **{len(rows):,} files**, known total **{stats['known_size_bytes']:,} bytes**. "
             f"Maximum hash size: {config['max_hash_bytes']:,} bytes. Contents are streamed for identity only; "
             "the explicitly named README/inventory/source-manifest control inputs are decoded for provenance. "
             "No document extraction, OCR, archive extraction, application execution, or network use.", "",
             "Skipped directory counts and bytes are **unknown**, not zero. Metadata-only entries include "
             "artist scene assets, textures, PSDs, installers, native binaries and archives. "
             "Links/reparse points are reported without following targets. Git ignore status alone does not control inspection.", ""]
    lines += table(["Inspection policy", "Files", "Known bytes"],
                   [[p, sum(r["inspection_policy"] == p for r in rows),
                     sum(r["size_bytes"] for r in rows if r["inspection_policy"] == p)] for p in ("full", "metadata_only")])
    for field, title in (("kind", "Kind"), ("component", "Component"),
                         ("knowledge_status", "Knowledge status"), ("git_status", "Git membership (tracked vs ignored vs untracked)")):
        lines += [f"## {title}", ""]
        lines += table([title, "Files", "Known bytes"],
                       [[key, sum(r[field] == key for r in rows), sum(r["size_bytes"] for r in rows if r[field] == key)]
                        for key in sorted({r[field] for r in rows})])
    lines += ["## Hash coverage and exclusions", ""]
    lines += table(["Hash status", "Files"], [[k, v] for k, v in stats["hash_coverage"].items()])
    lines += table(["Configured boundary", "Policy / reason"],
                   [[", ".join(config["inspection"]["skip_directory_names"]), "skip: dependencies, outputs, caches, private material"],
                    [", ".join(config["inspection"]["metadata_directory_prefixes"]), "metadata_only"],
                    [", ".join(config["inspection"]["metadata_path_patterns"]), "metadata_only: root and nested directory segments"],
                    ["Sensitive filenames / private keys", "skip (see config.toml)"],
                    ["Symlinks / junctions / reparse points", "skip target traversal"]])
    lines += [f"Encountered {len(exclusions):,} excluded entries; target file counts and target sizes remain unknown. "
              "Exact paths, reasons and null counts are in [exclusions.csv](exclusions.csv). "
              "Size-based skips remain full-policy candidates with catalog_only=true and hash_status=skipped_size.", "",
              "## Current version observations", ""]
    lines += table(["Component / observation", "Version", "Source", "Result"],
                   [[v["component"], v["version"] or "unknown", v["source"], v["observation_status"]] for v in versions])
    lines += ["Path tokens describe a directory name, not claim applicability or a tested build. "
              "Navigation references are separate from knowledge_status and do not promote authority. "
              "Each record has its own rule/source; component versions are never copied onto files.", "",
              "## Content redundancy", "",
              f"**{len(duplicates):,} confirmed duplicate groups**; **{stats['potential_duplicate_bytes']:,} potential duplicate bytes** "
              "(sum of all but one member in each group). These are content observations, not guaranteed reclaimable "
              "disk space. Copies may be required at their paths; hard links and compressed storage also affect physical usage. "
              "Unhashed files are never confirmed duplicates.", ""]
    lines += table(["SHA-256 group", "Copies", "Potential bytes", "Example paths (complete lists in duplicates.json)"],
                   [[g["duplicate_group"], g["file_count"], g["potential_duplicate_bytes"], "; ".join(g["paths"][:3])]
                    for g in duplicates[:12]])
    new_folder = [r for r in rows if r["path"].casefold().startswith("landing page design/new folder/")]
    designs = {r["sha256"] for r in rows if r["hash_status"] == "hashed" and
               any(r["path"].casefold().startswith(f"landing page design/design {n}/") for n in (1, 2, 3))}
    matches = [r for r in new_folder if r["hash_status"] == "hashed" and r["sha256"] in designs]
    lines += [f"`Landing Page Design/New folder/`: {len(new_folder)} cataloged files, "
              f"{sum(r['hash_status'] == 'hashed' for r in new_folder)} hashed, "
              f"{len(matches)} confirmed content matches with Design 1/2/3. "
              "This establishes matching bytes where hashed, not the copying direction or ownership.", "",
              "## Inventory reconciliation and authority", "",
              f"{stats['inventory_not_listed']:,} catalog entries are not listed in the historical documentation inventory. "
              "Source, test and image omissions are expected. Documentation review candidates and conflicts are recorded "
              "separately; absence alone is not a defect. Original decisions/reasons remain verbatim.", ""]
    counts = Counter(a["finding"] for a in audit)
    lines += table(["Finding", "Rows"], [[k, v] for k, v in sorted(counts.items())])
    highlights = [a for a in audit if a["finding"] in ("authority_conflict", "source_fingerprint_mismatch", "missing_unexpected")]
    lines += table(["Example", "Finding", "Evidence / detail"],
                   [[a["path"], a["finding"], a["detail"]] for a in highlights[:10]])
    lines += ["`preserved-excluded`, `preserved-data`, `preserved-tool-guide` and `consolidated` do not establish "
              "currency or obsolescence. They default to unknown unless explicit current evidence applies. "
              "A removed but present file requires review; absent files have audit rows, never fabricated manifest rows.", "",
              f"{sum(r['referenced_by_current_docs'] for r in rows):,} files have references observed in the configured "
              "README and source-manifest entrypoints. current_reference_sources preserves their sorted, deduplicated "
              "source paths; other current documents were not analyzed for links. Only explicit maintained rules and "
              "documents[] entries in configured maintained_source_manifests may establish current authority. "
              "Supporting hashes/catalog references do not establish authority.", "",
              "## Folder version/date parsing", "",
              f"Missing path version: {stats['missing_path_version']:,}; missing path date: {stats['missing_path_date']:,}. "
              "Missing tokens are normal. Malformed/conflicting tokens are listed separately in "
              f"[path_token_issues.csv](path_token_issues.csv): {len(issues):,} unique findings.", "",
              "## Top 30 largest cataloged files", ""]
    lines += table(["Path", "Bytes", "Policy", "Hash status"],
                   [[r["path"], r["size_bytes"], r["inspection_policy"], r["hash_status"]]
                    for r in sorted(rows, key=lambda r: (-r["size_bytes"], r["path"]))[:30]])
    lines += ["## Decisions, limits and next acceptance", "",
              "- Review authority conflicts and unexpected missing paths before using status as a retrieval filter. "
              "Review website fingerprint mismatches if reported; this scan does not refresh them.",
              "- Unknown classifications and generated-source mappings are explicit rules, not a comprehensive semantic audit. "
              "Folder versions and duplicate hashes cannot validate engineering claims.",
              "- This is a bounded observation, not a filesystem transaction. Metadata/handle checks, a final metadata and "
              "directory-membership check, control-input hash checks and final Git state detect ordinary concurrent changes. "
              "Unhashed contents and changes that restore all observed metadata cannot be verified.",
              "- Protected directories were not traversed; metadata-only and oversized files have no content identity. "
              "Their contents, duplicates and preservation are unverified. No protected scenes or applications were opened.",
              "- Phase 2 gate: approve canonical sources and unknown-status policy, curate the 40-question gold evidence set, "
              "and measure keyword baseline retrieval before validating any local embedding/store/reranker choice.", ""]
    if errors:
        lines += [f"**{len(errors)} scan/integrity errors. This run is incomplete; partial manifests must not be consumed as a complete snapshot.**", ""]
    return "\n".join(lines)


def write_artifacts(destination: Path, rows: list[dict], duplicates: list[dict], audit: list[dict],
                    exclusions: list[dict], issues: list[dict], versions: list[dict], errors: list[dict],
                    config: dict, run: dict) -> None:
    stem = "manifest" if not errors else "manifest.partial"
    write_jsonl(destination / f"{stem}.jsonl", rows)
    write_csv(destination / f"{stem}.csv", rows, FIELDS)
    write_csv(destination / "inventory_audit.csv", audit, AUDIT_FIELDS)
    write_csv(destination / "exclusions.csv", exclusions,
              ["path", "policy", "reason", "is_directory", "file_count", "size_bytes", "traversed"])
    write_csv(destination / "path_token_issues.csv", issues, ["folder", "issue", "token"])
    write_json(destination / "duplicates.json", duplicates)
    write_jsonl(destination / "errors.jsonl", errors)
    report = summary(rows, duplicates, audit, exclusions, issues, versions, errors, config)
    if errors:
        report = report.replace("(manifest.jsonl)", "(manifest.partial.jsonl)").replace("(manifest.csv)", "(manifest.partial.csv)")
    (destination / "summary.md").write_text(report, encoding="utf-8", newline="\n")
    write_json(destination / "run.json", run)
