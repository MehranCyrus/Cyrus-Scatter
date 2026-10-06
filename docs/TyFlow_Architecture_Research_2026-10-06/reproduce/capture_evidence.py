"""Record this research's identities and verify artifacts/links without host execution.

Reads the attributed earlier source inventory; does not recreate a claimed
initial snapshot. Writes only this research folder's JSON receipts and private
syntax-check files. The caller saves/closes the analysis server separately.
"""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import platform
from pathlib import Path
import py_compile
import re
import struct
import subprocess
from urllib.parse import unquote


EXPECTED = "5b1068b5b3627f64f78cd2b51ca0c23d616be09943077d5ffcf1c6fecc713fd9"
BATCHES = ("batch01", "batch02", "batch03-v2", "batch04", "batch05-v2", "batch06", "batch06-v2")


def sha(path):
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def file_record(path):
    return {"path": str(path), "bytes": path.stat().st_size, "sha256": sha(path)}


def git(repo, *args):
    return subprocess.check_output(["git", *args], cwd=repo, text=True).strip()


def binary_record(path):
    result = file_record(path)
    with path.open("rb") as stream:
        stream.seek(0x3c)
        pe = struct.unpack("<I", stream.read(4))[0]
        stream.seek(pe)
        header = stream.read(264)
    assert header[:4] == b"PE\0\0"
    machine = struct.unpack_from("<H", header, 4)[0]
    magic = struct.unpack_from("<H", header, 24)[0]
    clr_rva, clr_bytes = struct.unpack_from("<II", header, 24 + 112 + 14 * 8)
    result.update(machine=hex(machine), optional_header_magic=hex(magic),
                  clr_rva=clr_rva, clr_bytes=clr_bytes,
                  pinned_hash_matches=result["sha256"] == EXPECTED)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", type=Path)
    parser.add_argument("analysis", type=Path)
    args = parser.parse_args()
    repo, analysis = args.repo.resolve(), args.analysis.resolve()
    folder = repo / "docs/TyFlow_Architecture_Research_2026-10-06"
    private = analysis / "research-20261006"
    evidence = folder / "evidence"
    evidence.mkdir(exist_ok=True)
    problems = []
    now = datetime.now(timezone.utc).isoformat()
    targets = [binary_record(Path("C:/Program Files/Autodesk/3ds Max 2027/Plugins/tyFlow_2027.dlo")),
               binary_record(analysis / "inputs/tyFlow_2027.dlo")]
    if not all(t["pinned_hash_matches"] and t["clr_rva"] == 0 for t in targets):
        problems.append("Target fingerprint/technology differs")

    baseline_path = repo / "docs/TyFlow_CyrusScatter_Assessment_2026-10-06/evidence/source-state-before.json"
    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
    source_files, changed = {}, []
    for name, previous in baseline["sources"].items():
        path = repo / name
        if not path.is_file():
            changed.append({"path": name, "reason": "missing"})
            continue
        current = {"sha256": sha(path), "bytes": path.stat().st_size}
        source_files[name] = current
        if current != previous:
            changed.append({"path": name, "before": previous, "after": current})
    if changed:
        problems.append("Attributed source baseline differs")
    head, branch = git(repo, "rev-parse", "HEAD"), git(repo, "branch", "--show-current")
    staged = git(repo, "diff", "--cached", "--name-only").splitlines()
    if head != baseline["head"] or branch != baseline["branch"] or staged != baseline["staged_names"]:
        problems.append("HEAD/branch/staged state differs")

    batches = []
    for name in BATCHES:
        directory = private / name
        manifest_path = directory / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        mismatches = []
        for item in manifest["files"]:
            path = directory / item["name"]
            if not path.is_file() or path.stat().st_size != item["bytes"] or sha(path) != item["sha256"]:
                mismatches.append(item["name"])
        if mismatches:
            problems.append(f"Artifact mismatch in {name}")
        response = (directory / "script-response.txt").read_text(encoding="utf-8")
        rows = []
        for line in response.splitlines():
            fields = line.strip().split("\t")
            if len(fields) >= 7 and fields[0] in {e["label"] for e in manifest["selection"]}:
                rows.append(dict(label=fields[0], va_begin=fields[1], va_last=fields[2],
                                 disassembly_return=fields[3], instructions=int(fields[4]),
                                 instruction_bytes=int(fields[5]), decompile_completed=fields[6] == "true",
                                 errors=fields[7:]))
        if len(rows) != len(manifest["selection"]):
            problems.append(f"Missing region receipt in {name}")
        batches.append(dict(name=name, manifest=file_record(manifest_path),
                            artifact_count=len(manifest["files"]), hash_mismatches=mismatches,
                            selection=manifest["selection"], results=rows))

    anchors = private / "anchors-v3/static-anchors.json"
    scan = json.loads(anchors.read_text(encoding="utf-8"))
    raw_counts = Counter(row["import_symbol"]["name"] for row in scan["selected_import_refs"])
    sdk_path = private / "sdk-layout-v4/receipt.json"
    sdk = json.loads(sdk_path.read_text(encoding="utf-8"))
    sdk_log = private / "sdk-layout-v4/compile.txt"
    sdk_source = private / "sdk-layout-v4/sdk_layout.cpp"
    if any(sdk["exit_codes"]) or sha(sdk_log) != sdk["log_sha256"] or sha(sdk_source) != sdk["source_sha256"]:
        problems.append("SDK receipt/log mismatch")

    syntax_dir = private / "syntax-check"
    syntax_dir.mkdir(exist_ok=True)
    python_scripts = sorted((folder / "reproduce").glob("*.py"))
    for path in python_scripts:
        py_compile.compile(str(path), cfile=str(syntax_dir / (path.stem + ".pyc")), doraise=True)
    links, link_errors = 0, []
    for document in sorted(folder.glob("*.md")):
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", document.read_text(encoding="utf-8")):
            target = target.strip("<>")
            if re.match(r"https?://", target):
                continue
            file_name, _, fragment = target.partition("#")
            path = (document.parent / unquote(file_name)).resolve()
            links += 1
            if not path.exists():
                link_errors.append(dict(document=document.name, target=target, reason="missing"))
            elif fragment.startswith("L") and not fragment[1:].isdigit():
                link_errors.append(dict(document=document.name, target=target, reason="invalid line"))
            elif fragment.startswith("L") and int(fragment[1:]) > len(path.read_text(encoding="utf-8-sig").splitlines()):
                link_errors.append(dict(document=document.name, target=target, reason="line exceeds file"))
    # Receipt links are checked again after these receipts have been written.
    pending = {"evidence/research-receipt.json", "evidence/verification.json"}
    link_errors = [e for e in link_errors if e["target"] not in pending]
    if link_errors:
        problems.append("Local Markdown link errors")

    lifecycle_path = private / "server-lifecycle.json"
    lifecycle = json.loads(lifecycle_path.read_text(encoding="utf-8")) if lifecycle_path.exists() else None
    if not lifecycle or not lifecycle.get("program_saved") or not lifecycle.get("project_closed") or not lifecycle.get("owned_process_stopped"):
        problems.append("Analysis server lifecycle incomplete")
    diff = subprocess.run(["git", "diff", "--check"], cwd=repo, capture_output=True, text=True)
    if diff.returncode:
        problems.append("git diff --check failed")

    tool_paths = [analysis / "tools/ghidra/ghidra_12.1.4_PUBLIC/Ghidra/application.properties",
                  analysis / "tools/java/jdk-21.0.12.1+1/release",
                  analysis / "tools/ghidra-mcp/GhidraMCP/lib/GhidraMCP-6.0.0.jar",
                  analysis / "start_headless.py", analysis / "mcp_request.py"]
    extra_paths = [private / "program-info.json", private / "selected-class-hierarchies.json",
                   private / "tflow-host-vtable.json", private / "display-thunks.json",
                   private / "sdk-layout-v4/vtable-maps.json", private / "server-lifecycle.json",
                   private / "target-version.json", private / "save-program.json", private / "close-project.json"]
    receipt = dict(recorded_at_utc=now, scope="bounded static research; no target/Max runtime execution",
                   python_version=platform.python_version(),
                   target=targets, tools=[file_record(p) for p in tool_paths if p.is_file()],
                   raw_pe_scan=dict(file=file_record(anchors), imports=len(scan["imports"]),
                                    selected_instruction_pattern_candidates=len(scan["selected_import_refs"]),
                                    selected_rtti=len(scan["selected_rtti"]), raw_counts=raw_counts,
                                    warning="Raw pattern counts are not verified call counts"),
                   batches=batches, sdk=dict(receipt=file_record(sdk_path), exit_codes=sdk["exit_codes"],
                                            source=file_record(sdk_source), log=file_record(sdk_log), linked=False, executed=False),
                   additional_artifacts=[file_record(p) for p in extra_paths if p.is_file()],
                   research_scripts={p.name:file_record(p) for p in sorted((folder / "reproduce").glob("*.py"))})
    (evidence / "research-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    source = dict(recorded_at_utc=now, root=str(repo), head=head, branch=branch,
                  staged_names=staged, status_porcelain=git(repo, "status", "--porcelain"),
                  comparison_baseline=file_record(baseline_path),
                  comparison_baseline_recorded_at_utc=baseline["recorded_at_utc"],
                  comparison_baseline_provenance="Earlier independent assessment capture, not our initial capture",
                  sources=source_files, changes=changed)
    (evidence / "source-comparison.json").write_text(json.dumps(source, indent=2) + "\n", encoding="utf-8")
    verification = dict(recorded_at_utc=now, passed=not problems, problems=problems,
                        source_files_compared=len(baseline["sources"]), source_changes=changed,
                        head_branch_staged_match=not (head != baseline["head"] or branch != baseline["branch"] or staged != baseline["staged_names"]),
                        binary_hashes_match=all(t["pinned_hash_matches"] for t in targets),
                        artifact_hash_mismatches=sum(len(b["hash_mismatches"]) for b in batches),
                        sdk_compile_exit_codes=sdk["exit_codes"], local_links_checked=links,
                        local_link_errors=link_errors, python_scripts_syntax_checked=len(python_scripts),
                        git_diff_check=dict(exit_code=diff.returncode, output=diff.stdout + diff.stderr),
                        analysis_lifecycle=lifecycle,
                        not_run=["Interactive Max", "tyFlow runtime", "presented FPS", "Corona IR", "production/native/Python regression campaigns"],
                        preservation_scope="Inventoried source/configuration hashes match; no scene/profile/package actions were performed. Not an all-files filesystem audit.")
    (evidence / "verification.json").write_text(json.dumps(verification, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": not problems, "problems": problems, "source_files": len(source_files),
                      "export_regions": sum(len(b["results"]) for b in batches),
                      "decompilation_failures": [r["label"] for b in batches for r in b["results"] if not r["decompile_completed"]],
                      "local_links": links}, indent=2))
    raise SystemExit(0 if not problems else 1)


if __name__ == "__main__":
    main()
