"""Validate review scope, local references and receipts without changing product data."""
import argparse
import ast
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote


def sha(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def heading_ids(path):
    ids, counts = set(), {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        match = re.match(r"^#{1,6}\s+(.*?)\s*#*\s*$", line)
        if not match:
            continue
        base = re.sub(r"[^\w\- ]", "", match[1].lower()).replace(" ", "-")
        count = counts.get(base, 0)
        ids.add(base + (f"-{count}" if count else ""))
        counts[base] = count + 1
    return ids


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    parser.add_argument("--preflight", action="store_true")
    args = parser.parse_args()
    folder = Path(__file__).resolve().parents[1]
    root = folder.parents[1]
    self_result = args.output.resolve() if args.output else None
    if self_result:
        self_result.relative_to(folder)
        if self_result.exists():
            raise FileExistsError(self_result)
    git = lambda *a: subprocess.check_output(["git", *a], cwd=root).decode().strip()
    changed = git("diff", "--name-only").splitlines()
    untracked = git("ls-files", "--others", "--exclude-standard").splitlines()
    errors, links, parsed = [], 0, []
    allowed_docs = {"README.md", "CyrusMCP/README.md"}
    unexpected = [p for p in changed if p not in allowed_docs and
                  (not p.startswith("docs/") or not p.endswith(".md"))]
    unexpected += [p for p in untracked if not p.startswith(folder.relative_to(root).as_posix() + "/")]
    if unexpected:
        errors.append({"unexpected_diff": unexpected})
    check = subprocess.run(["git", "diff", "--check"], cwd=root, capture_output=True, text=True)
    if check.returncode:
        errors.append({"diff_check": check.stdout + check.stderr})
    docs = sorted(set(folder.glob("*.md")) | {root / p for p in changed if p.endswith(".md")})
    planned = {"index.json", "end-snapshot.json", "validation.json"}
    for doc in docs:
        text = doc.read_text(encoding="utf-8-sig")
        for target in re.findall(r"\]\(([^)]+)\)", text):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I):
                continue
            raw, _, anchor = target.partition("#")
            path = (doc.parent / unquote(raw.strip("<>"))).resolve() if raw else doc
            links += 1
            if not path.exists():
                if self_result and path == self_result:
                    continue  # This report's own validated output is written below.
                if args.preflight and path.parent == folder / "evidence" and path.name in planned:
                    continue
                errors.append({"doc": str(doc.relative_to(root)), "missing": target})
                continue
            if re.fullmatch(r"L\d+", anchor):
                line = int(anchor[1:])
                count = len(path.read_text(encoding="utf-8-sig").splitlines())
                if line < 1 or line > count:
                    errors.append({"doc": str(doc.relative_to(root)), "line": target})
            elif anchor and path.suffix == ".md" and anchor not in heading_ids(path):
                errors.append({"doc": str(doc.relative_to(root)), "heading": target})
    for path in folder.rglob("*.json"):
        json.loads(path.read_text(encoding="utf-8-sig"))
        parsed.append(path.relative_to(folder).as_posix())
    for path in (folder / "reproduce").glob("*.py"):
        ast.parse(path.read_text(encoding="utf-8-sig"), filename=str(path))
    before = json.loads((folder / "evidence/start-snapshot.json").read_text())
    hashes = {}
    def cached(path):
        if path not in hashes:
            hashes[path] = sha(root / path) if (root / path).exists() else None
        return hashes[path]
    modified_protected = [p for p, h in before["protected_tracked_files"].items() if cached(p) != h]
    modified_sources = [p for p, h in before["source_files"].items() if cached(p) != h]
    if set(modified_protected) != {"CyrusMCP/README.md"} or set(modified_sources) != {"CyrusMCP/README.md"}:
        errors.append({"inventory_scope": [modified_protected, modified_sources]})
    head = git("rev-parse", "HEAD")
    if head != before["head"]:
        errors.append({"head_changed": head})
    vendor = [{"path": v["path"], "matches": sha(Path(v["path"])) == v["sha256"]}
              for v in before["vendor_inputs"]]
    if not all(v["matches"] for v in vendor):
        errors.append({"vendor_changed": vendor})
    server = ast.parse((root / "CyrusMCP/cyrus_mcp/server.py").read_text())
    surface = {"tool": 0, "resource": 0}
    for node in ast.walk(server):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            for decorator in node.decorator_list:
                if isinstance(decorator, ast.Call) and isinstance(decorator.func, ast.Attribute):
                    key = decorator.func.attr
                    if key in surface:
                        surface[key] += 1
    if surface != {"tool": 12, "resource": 7}:
        errors.append({"public_surface": surface})
    matrix = root / "docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md"
    mapping = folder / "CAPABILITY_MAP.md"
    families = {f"C{i:02d}" for i in range(1, 35)}
    for path in (matrix, mapping):
        ids = re.findall(r"^\| (C\d\d)\b", path.read_text(encoding="utf-8"), re.M)
        if set(ids) != families or len(ids) != 34:
            errors.append({"capability_rows": str(path.relative_to(root))})
    catalog = json.loads((root / "CyrusMCP/cyrus_mcp/feature-catalog.json").read_text())
    if len(catalog["controls"]) != 245:
        errors.append({"control_count": len(catalog["controls"])})
    source_hash_matches = catalog["capability_source_sha256"] == sha(matrix)
    c28 = next(f for f in catalog["features"] if f["feature_id"] == "C28")
    if source_hash_matches or "open IR restart issue" not in c28["native"]:
        errors.append({"deferred_catalog_boundary_unexpected": True})
    index_path = folder / "evidence/index.json"
    if index_path.exists():
        index = json.loads(index_path.read_text())
        for name, expected in index["files"].items():
            path = folder / name
            if path.stat().st_size != expected["bytes"] or sha(path) != expected["sha256"]:
                errors.append({"index_mismatch": name})
    elif not args.preflight:
        errors.append({"missing_evidence_index": True})
    result = {
        "schema": "cyrus.rnd-validation/1.0", "utc": datetime.now(timezone.utc).isoformat(),
        "passed": not errors, "errors": errors, "head": head, "changed_tracked_docs": changed,
        "untracked_review_files": untracked, "markdown_files": len(docs), "local_links_checked": links,
        "parsed_json": parsed, "public_surface": surface, "capability_families": 34,
        "controls": len(catalog["controls"]), "changed_protected_files": modified_protected,
        "changed_inventory_files": modified_sources,
        "unchanged_source_inventory_entries": len(before["source_files"]) - len(modified_sources),
        "unchanged_protected_entries": len(before["protected_tracked_files"]) - len(modified_protected),
        "vendor": vendor, "deferred_catalog_source_hash_mismatch": not source_hash_matches,
        "runtime_executed": False, "computer_use": False, "preflight": args.preflight,
        "self_result_link": str(self_result.relative_to(folder)) if self_result else None,
    }
    if args.output:
        output = args.output.resolve()
        output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
