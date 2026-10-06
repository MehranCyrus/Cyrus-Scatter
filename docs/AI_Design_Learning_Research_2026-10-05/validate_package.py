"""Documentation-only consistency checks; does not call Max, models or the network."""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlsplit

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parent.parent
EVIDENCE = PACKAGE / "evidence"
INDEX_PARAGRAPH = "**AI/MCP/ML research: [Design learning research — 5 October 2026](AI_Design_Learning_Research_2026-10-05/README.md).** Current source audit, 40 initial primary-source entries plus 25 official Houdini/Autodesk documentation entries, artist preference workflow, MCP/graph architecture, 18 planned experiments and an updated phased roadmap. This is research and documentation; the ML system remains proposed.\n\n"


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main() -> int:
    errors: list[str] = []
    snapshot = read_json(EVIDENCE / "source_snapshot.json")
    changed = []
    for relative, expected in snapshot["files"].items():
        path = ROOT / relative
        actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        if actual != expected:
            changed.append(relative)
    if changed:
        errors.append("Source snapshot differs: " + ", ".join(changed))

    source_rows = []
    for line in (PACKAGE / "12_RESEARCH_LEDGER.md").read_text(encoding="utf-8").splitlines():
        if not re.match(r"\| S\d\d —", line):
            continue
        cells = [x.strip() for x in line.strip("|").split("|")]
        matches = re.findall(r"\[([^\]]+)\]\((https?://[^)]+)\)", cells[0])
        source_rows.append({"id": cells[0].split()[0], "title": matches[0][0],
                            "primary_url": matches[0][1], "additional_urls": [u for _, u in matches[1:]],
                            "date_status_reading_depth": cells[1], "lesson_and_limit": cells[2],
                            "accessed_on": "2026-10-05", "reproduced_in_cyrus": False})
    if {r["id"] for r in source_rows} != {f"S{i:02}" for i in range(1, 41)} or len(source_rows) != 40:
        errors.append("Primary source ledger must contain S01 through S40 exactly once")
    (EVIDENCE / "source_ledger_index.json").write_text(json.dumps(source_rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    vendor_rows = []
    for line in (PACKAGE / "17_VENDOR_SOURCE_LEDGER.md").read_text(encoding="utf-8").splitlines():
        if not re.match(r"\| [HA]\d\d —", line):
            continue
        cells = [x.strip() for x in line.strip("|").split("|")]
        matches = re.findall(r"\[([^\]]+)\]\((https?://[^)]+)\)", cells[0])
        if len(cells) != 3 or len(matches) != 1:
            errors.append("Malformed vendor ledger row: " + cells[0])
            continue
        vendor_rows.append({"id": cells[0].split()[0], "title": matches[0][0],
                            "primary_url": matches[0][1], "version_reading_depth": cells[1],
                            "lesson_and_limit": cells[2], "accessed_on": "2026-10-05",
                            "reproduced_in_cyrus": False})
    expected_vendor_ids = {f"H{i:02}" for i in range(1, 15)} | {f"A{i:02}" for i in range(1, 12)}
    if {r["id"] for r in vendor_rows} != expected_vendor_ids or len(vendor_rows) != 25:
        errors.append("Vendor ledger must contain H01 through H14 and A01 through A11 exactly once")
    if any(urlsplit(r["primary_url"]).hostname not in {"www.sidefx.com", "help.autodesk.com"} for r in vendor_rows):
        errors.append("Vendor ledger contains a non-primary vendor URL")
    (EVIDENCE / "vendor_source_index.json").write_text(json.dumps(vendor_rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    experiment_ids = re.findall(r"^## (E\d\d) —", (PACKAGE / "11_EXPERIMENTS.md").read_text(encoding="utf-8"), re.MULTILINE)
    if set(experiment_ids) != {f"E{i:02}" for i in range(1, 19)} or len(experiment_ids) != 18:
        errors.append("Experiment register must contain E01 through E18 exactly once")

    sdk_receipt = read_json(EVIDENCE / "vendor_sdk_crosscheck.json")
    sdk_changed = []
    for relative, expected in sdk_receipt["files"].items():
        path = ROOT / relative
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            sdk_changed.append(relative)
    if sdk_changed:
        errors.append("SDK cross-check files changed since inspection: " + ", ".join(sdk_changed))

    examples = {p.stem: read_json(p) for p in (PACKAGE / "examples").glob("*.json")}
    for name, record in examples.items():
        if record.get("synthetic") is not True or not record.get("schema", "").startswith("cyrus.proposed."):
            errors.append(f"Example {name} must be explicitly synthetic and proposed")
    pair = examples["candidate_pair"]
    candidates = pair["candidates"]
    candidate_ids = {c["candidate_id"] for c in candidates}
    feedback = examples["feedback_event"]
    if len(candidate_ids) != 2 or {feedback["candidate_a"], feedback["candidate_b"]} != candidate_ids:
        errors.append("Candidate/feedback references disagree")
    if set(feedback["display_order"]) != candidate_ids:
        errors.append("Display order references disagree")
    for c in candidates:
        if c["parent_candidate_id"] is not None and c["parent_candidate_id"] not in candidate_ids:
            errors.append("Unknown candidate parent")
        if abs(sum(c["recipe"]["source_weights"].values()) - 1.0) > 1e-9:
            errors.append("Example weights are not normalized")
        if set(c["recipe"]["source_weights"]) != set(pair["context"]["asset_ids"]):
            errors.append("Example weights reference unknown sources")
        if c["publication_id"] is not None or c["transform_digest"] is not None or c["view_artifacts"]:
            errors.append("Synthetic recipe must not invent executed evidence")
    if feedback["training_eligible"] or feedback["consent_record_id"] is not None:
        errors.append("Synthetic feedback cannot grant training eligibility")
    if any(v is not None for v in feedback["absolute_acceptance"].values()):
        errors.append("Relative preference must not invent absolute acceptance")
    scope = examples["batch_scope"]
    if scope["authorized"] or scope["authorization_record_id"] is not None or scope["training_consent"]:
        errors.append("Draft scope must not grant authorization/consent")
    if scope["study_id"] != pair["context"]["study_id"] or feedback["study_id"] != scope["study_id"]:
        errors.append("Study references disagree")
    graph = examples["scene_graph"]
    node_ids = {n["id"] for n in graph["nodes"]}
    if any(r["from"] not in node_ids or r["to"] not in node_ids for r in graph["relations"]):
        errors.append("Scene relation references unknown node")
    dataset = examples["dataset_manifest"]
    if dataset["training_eligible"] or dataset["included_candidate_ids"] or dataset["included_comparison_event_ids"]:
        errors.append("Synthetic dataset must be ineligible and empty")

    docs_index = ROOT / "docs" / "README.md"
    index_bytes = docs_index.read_bytes()
    addition = INDEX_PARAGRAPH.encode("utf-8")
    if b"\r\n" in index_bytes:
        addition = INDEX_PARAGRAPH.replace("\n", "\r\n").encode("utf-8")
    index_initial_preserved = False
    second_index_baseline = read_json(EVIDENCE / "docs_index_second_pass_before.json")
    if index_bytes.count(addition) != 1:
        errors.append("Docs index research paragraph missing or duplicated")
        index_preserved = False
    else:
        original = index_bytes.replace(addition, b"", 1)
        original_hash = hashlib.sha256(original).hexdigest()
        initial_index_hash = (EVIDENCE / "docs_index_before.sha256").read_text(encoding="utf-8-sig").strip().lower()
        index_initial_preserved = original_hash == initial_index_hash
        index_preserved = original_hash == second_index_baseline["outside_research_paragraph_sha256"]
        if not index_preserved:
            errors.append("Docs index changed outside the research paragraph after the second-pass amendment baseline")

    current_head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    if current_head != snapshot["head"]:
        errors.append("HEAD changed since research snapshot")

    # Write a receipt placeholder before checking its self-referencing Markdown link.
    receipt_path = EVIDENCE / "package_validation.json"
    if not receipt_path.exists():
        receipt_path.write_text("{}\n", encoding="utf-8")
    markdown_files = list(PACKAGE.rglob("*.md"))
    local_links = 0
    for path in markdown_files:
        body = path.read_text(encoding="utf-8")
        if any(token in body for token in ("turn0search", "turn1view", "\ue200", "\ue202")):
            errors.append(f"Internal browser citation token in {path.name}")
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", body):
            target = target.strip().strip("<>")
            if urlsplit(target).scheme or target.startswith("#"):
                continue
            local_links += 1
            relative = unquote(target.split("#", 1)[0])
            if not (path.parent / relative).resolve().exists():
                errors.append(f"Broken local link: {path.relative_to(PACKAGE)} -> {target}")
    json_files = list(PACKAGE.rglob("*.json"))
    for path in json_files:
        try:
            read_json(path)
        except (ValueError, UnicodeError) as exc:
            errors.append(f"Invalid JSON {path.name}: {exc}")
    test_output = (EVIDENCE / "mcp_offline_tests.txt").read_text(encoding="utf-8-sig")
    if "66 passed in 8.15s" not in test_output:
        errors.append("Offline test receipt differs from documented result")
    log_receipt = read_json(EVIDENCE / "renderer_log_observation.json")
    if log_receipt["render_starts_in_window"] != 485:
        errors.append("Renderer observation differs from documented count")

    result = {"checked_at_utc": datetime.now(timezone.utc).isoformat(),
              "purpose": "research documentation consistency, not production qualification",
              "passed": not errors, "markdown_files": len(markdown_files),
              "markdown_words": sum(len(p.read_text(encoding="utf-8").split()) for p in markdown_files),
              "local_links_checked": local_links, "json_files_checked": len(json_files),
              "primary_source_entries": len(source_rows), "vendor_documentation_entries": len(vendor_rows),
              "distinct_primary_urls": len({r["primary_url"] for r in source_rows + vendor_rows}),
              "planned_experiments": len(experiment_ids), "synthetic_example_files": len(examples),
              "source_files_compared": len(snapshot["files"]), "changed_source_files": changed,
              "docs_index_matches_first_pass_original": index_initial_preserved,
              "docs_index_second_pass_other_content_preserved": index_preserved,
              "other_index_updates_since_first_pass": second_index_baseline["other_index_updates_since_first_pass"],
              "head_unchanged": current_head == snapshot["head"],
              "sdk_files_compared": len(sdk_receipt["files"]), "changed_sdk_files": sdk_changed,
              "offline_test_receipt_origin": "first research pass, unchanged; not rerun in second pass",
              "fresh_max_tests": 0, "fresh_houdini_tests": 0, "trained_models": 0, "errors": errors}
    receipt_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
