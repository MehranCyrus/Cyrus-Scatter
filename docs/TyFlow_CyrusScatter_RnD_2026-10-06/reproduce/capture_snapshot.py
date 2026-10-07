"""Record/compare review inputs without changing product files or vendor binaries."""
import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def digest(path):
    with path.open("rb") as stream:
        h = hashlib.sha256()
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
        return h.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--compare", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    old = json.loads((root / "docs/Integrated_UI_0.72_2026-10-06/evidence/snapshot.json").read_text())
    git = lambda *a: subprocess.check_output(["git", *a], cwd=root).decode("utf-8").strip()
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
    protected = {p: digest(root / p) for p in tracked if p and not p.startswith("docs/") and p != "README.md"}
    sources = {p: digest(root / p) for p in old["source_files"]}
    analysis = Path(r"C:\Users\Mehran\Documents\ChatGPT\Play\tyflow-analysis")
    inputs = [Path(r"C:\Program Files\Autodesk\3ds Max 2027\Plugins\tyFlow_2027.dlo"), analysis / "inputs/tyFlow_2027.dlo"]
    snapshot = {
        "schema": "cyrus.rnd-snapshot/1.0", "utc": datetime.now(timezone.utc).isoformat(),
        "head": git("rev-parse", "HEAD"), "branch": git("branch", "--show-current"),
        "status": git("status", "--short"), "source_files": sources, "protected_tracked_files": protected,
        "previous_072_inventory_mismatches": [p for p, h in sources.items() if h != old["source_files"][p]],
        "vendor_inputs": [{"path": str(p), "bytes": p.stat().st_size, "sha256": digest(p)} for p in inputs],
        "tools": json.loads((analysis / "tools.json").read_text()),
    }
    if args.compare:
        before = json.loads(args.compare.read_text())
        snapshot["comparison"] = {
            "changed_protected_files": [p for p, h in protected.items() if before["protected_tracked_files"].get(p) != h],
            "removed_protected_files": [p for p in before["protected_tracked_files"] if p not in protected],
            "changed_source_files": [p for p, h in sources.items() if before["source_files"].get(p) != h],
            "vendor_hashes_unchanged": snapshot["vendor_inputs"] == before["vendor_inputs"],
            "head_unchanged": snapshot["head"] == before["head"],
        }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.output.exists():
        raise FileExistsError(args.output)
    args.output.write_text(json.dumps(snapshot, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "sources": len(sources), "protected": len(protected),
                      "previous_mismatches": snapshot["previous_072_inventory_mismatches"],
                      "comparison": snapshot.get("comparison")}))


if __name__ == "__main__":
    main()
