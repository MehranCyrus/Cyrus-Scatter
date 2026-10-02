"""Preserve the dated experiment with identities and explicit rejected evidence.

No binaries or artist scenes are copied. This is an evidence pack, not an installer.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "build/heavy-viewport-2026-10-02"
DEST = ROOT / "docs/Heavy_Scene_Viewport_2026-10-02/evidence"
PROBE = Path(__file__).parent


def identity(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return {"path": str(path), "bytes": path.stat().st_size, "sha256": digest.hexdigest()}


def save(name, data):
    (DEST / name).write_text(json.dumps(data, indent=2), encoding="utf-8")


def copy(source, relative=None):
    target = DEST / (relative or source.name)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    expected = json.loads((BASE / "input-identity.json").read_text())
    preservation = []
    for name, old in expected.items():
        current = identity(ROOT / name)
        current["matches_pre_launch"] = current["sha256"] == old["sha256"]
        preservation.append(current)
    assert all(row["matches_pre_launch"] for row in preservation), "An experiment input changed"
    save("preservation.json", preservation)

    for pattern in ("points*.csv", "points*.json", "points*.png", "recipe-*.ms"):
        for source in BASE.glob(pattern):
            copy(source, (Path("recipes") / source.name) if pattern == "recipe-*.ms" else None)
    for name in (
        "summary.json", "presentmon-official.csv", "presentmon-summary.json", "presentmon-tool.json",
        "ready.json", "machine.json", "input-identity.json", "launch.json", "plugins.ini",
        "lifecycle.json", "lifecycle-extra.json", "gesture.json", "redraw-check.json",
        "lifecycle-replaced.png", "lifecycle-cleared.png", "lifecycle-four-views-active.png",
        "pilot-gw.png", "pilot-retained.png", "pilot-off.png", "shutdown-requested.json",
        "shutdown-observed.json", "matrix-complete.txt", "population-complete.txt", "lifecycle-complete.txt",
    ):
        copy(BASE / name)

    # The successful reset recipe used Integer64 values whose MAXScript textual
    # form includes L suffixes. Preserve the original and normalize only those
    # array numeric tokens; do not alter the observations or silently discard it.
    cleanup = (BASE / "cleanup.json").read_text(encoding="utf-8-sig")
    copy(BASE / "cleanup.json", "cleanup-raw-maxscript.txt")
    normalized = re.sub(r"(?<=[\[,])([0-9]+)L(?=[,\]])", r"\1", cleanup)
    parsed = json.loads(normalized)
    assert parsed["status"] == "SUCCESS" and parsed["after_reset"][9] == 0
    save("cleanup.json", parsed)
    save("normalization.json", {"source": "cleanup-raw-maxscript.txt", "output": "cleanup.json", "change": "Remove MAXScript Integer64 L suffixes on array numbers for strict JSON. Cleanup assertions and process exit passed. The checked-in cleanup.ms now casts these bounded counters before serialization; see the as-executed recipe for the measured version."})

    for pattern in ("pilot25k-*", "launch-0*.json", "listener-0*.log", "startup-*.txt", "lifecycle-invalid-*.txt"):
        for source in BASE.glob(pattern):
            copy(source, Path("rejected") / source.name)

    binaries = []
    for year in (2026, 2027):
        build = BASE / f"probe-{year}"
        for name in ("identity.json", "build-0.log", "build-1.log", "CMakeCache.txt"):
            copy(build / name, Path(f"build-{year}") / name)
        for binary in build.glob("*.dl?"):
            binaries.append(identity(binary))
    binaries.append(identity(BASE / "PresentMon-2.6.0-x64.exe"))
    save("binary-identities.json", binaries)

    sources = []
    for source in sorted(PROBE.iterdir()):
        if source.is_file() and source.suffix in (".cpp", ".ms", ".py", ".txt", ".md"):
            sources.append(identity(source))
            copy(source, Path("probe-source") / source.name)
    save("probe-source-identities.json", sources)

    downloads = Path("C:/Users/Mehran/Downloads")
    inputs = [ROOT / "docs/Codebase_Research_2026-10-01" / name for name in ("REPORT.md", "claims.csv", "decisions.csv", "COVERAGE.md")]
    inputs += [downloads / name for name in (
        "claim_source_ledger.csv", "decision_experiment_ledger.csv", "deep-research-report.md",
        "deep-research-report (1).md", "Research_Report.html", "Cyrus_External_Engineering_Research.md", "Three_Experiments.md",
    )]
    inputs += [Path("C:/Users/Mehran/.codex/attachments") / name / "Pasted text.txt" for name in (
        "46d1d376-61f9-4289-9047-2e901077cbae", "c9e80891-abea-44ce-98a1-c3555e43f9ae",
    )]
    save("research-input-identities.json", [identity(path) for path in inputs])
    files = []
    for path in sorted(DEST.rglob("*")):
        if path.is_file() and path.name != "manifest.json":
            entry = identity(path)
            entry["path"] = path.relative_to(DEST).as_posix()
            files.append(entry)
    save("manifest.json", {"schema": 1, "description": "Dated first-loop evidence; binaries and external original reports are fingerprinted, not bundled.", "files": files})
    print(f"Archived {len(files)} files ({sum(row['bytes'] for row in files):,} bytes); all {len(preservation)} pre-launch input hashes match.")


if __name__ == "__main__":
    main()
