"""Verify this review's documentation and preserved source without running Max."""
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote
import hashlib
import json
import re
import subprocess

HERE = Path(__file__).resolve().parent
PACKAGE = HERE.parents[1]
ROOT = HERE.parents[3]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    baseline = json.loads((HERE / "preserved_source.json").read_text(encoding="utf-8"))
    changes = [name for name, expected in baseline["sha256"].items() if not (ROOT / name).is_file() or sha(ROOT / name) != expected]
    documents = sorted(PACKAGE.glob("*.md")) + [HERE / "README.md", ROOT / "docs/Release_Versioning.md"]
    missing, fences, trailing, links, sources = [], [], [], set(), set()
    for path in documents:
        content = path.read_text(encoding="utf-8")
        if sum(line.startswith("```") for line in content.splitlines()) % 2:
            fences.append(str(path.relative_to(ROOT)))
        for i, line in enumerate(content.splitlines(), 1):
            if line.rstrip() != line:
                trailing.append(f"{path.relative_to(ROOT)}:{i}")
        for target in re.findall(r"\[[^\]\r\n]*\]\(([^)\r\n]+)\)", content):
            if target.startswith(("https://", "http://")):
                sources.add(target)
                continue
            if target.startswith("#"):
                continue
            target = unquote(target.split("#", 1)[0].strip("<>"))
            resolved = (path.parent / target).resolve()
            links.add(str(resolved))
            if not resolved.exists() and resolved != (HERE / "verification.json").resolve():
                missing.append({"file":str(path.relative_to(ROOT)), "target":target})
    checks = json.loads((HERE / "checks.json").read_text(encoding="utf-8"))
    native = (HERE / "native-tests.txt").read_text(encoding="utf-8")
    mcp = (HERE / "mcp-tests.txt").read_text(encoding="utf-8")
    ok = not (changes or missing or fences or trailing)
    ok = ok and checks["source_commit"] == baseline["source_commit"] and all(c["exit_code"] == 0 for c in checks["commands"])
    ok = ok and all(checks["generated_artifacts_match"].values()) and "100% tests passed, 0 tests failed out of 13" in native and "61 passed" in mcp
    report = {
        "status":"passed" if ok else "failed",
        "verified_at_utc":datetime.now(timezone.utc).isoformat(),
        "source_commit":baseline["source_commit"],
        "head_at_verification":subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(),
        "scope":"Documentation, source preservation, current core/local MCP/generator evidence; no new-policy Max qualification",
        "tracked_baseline_files_checked":len(baseline["sha256"]),
        "changed_baseline_files":changes,
        "markdown_documents_checked":len(documents),
        "unique_local_link_targets_checked":len(links),
        "missing_links":missing, "unbalanced_fences":fences, "trailing_whitespace":trailing,
        "native_tests_passed":13, "mcp_tests_passed":61,
        "isolated_generated_artifacts_match":checks["generated_artifacts_match"],
        "external_urls_listed_not_rebrowsed_this_followup":len(sources),
        "documentation_sha256":{str(p.relative_to(ROOT)):sha(p) for p in documents},
        "evidence_sha256":{p.name:sha(p) for p in sorted(HERE.iterdir()) if p.is_file() and p.name != "verification.json"},
        "out_of_scope_untracked_work_observed":["CyrusLicensing/", "tools/licensing_lab/"],
        "not_performed":["Production feature implementation", "Max SDK plugin build/load", "Max scene or interactive UI test", "Renderer test", "FPS benchmark", "MCP apply to actual Max", "ML training", "Git commit/push"],
    }
    (HERE / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k not in ("documentation_sha256", "evidence_sha256")}, indent=2))
    if not ok:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
