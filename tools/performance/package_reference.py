"""Create an exact pre-performance Scatter rollback package from local evidence.

The original MZP is preserved. Its native modules must match the frozen engine;
the frozen script includes the later diagnostic hooks used for the comparison.
No installation or changes to a running Max process are performed.
"""
from pathlib import Path
import argparse
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, default=ROOT / "build/performance-reference/20261001-cpu-v1")
    parser.add_argument("--original-package", type=Path, default=ROOT / "dist/CyrusScatter-0.59-Max2027.mzp")
    parser.add_argument("--output", type=Path, default=ROOT / "dist/CyrusScatter-0.59-PrePerformance-Max2027.mzp")
    args = parser.parse_args()
    reference = args.reference.resolve()
    manifest_path = reference / "manifest.json"
    frozen = json.loads(manifest_path.read_text())
    for name, expected in frozen["files"].items():
        if digest((reference / name).read_bytes()) != expected:
            raise SystemExit(f"Frozen reference changed: {name}")
    if args.output.resolve() == args.original_package.resolve():
        raise SystemExit("The original package must be preserved")
    with zipfile.ZipFile(args.original_package) as archive:
        if archive.testzip() is not None:
            raise SystemExit("Original package integrity failed")
        payload = {name: archive.read(name) for name in archive.namelist()}
    manifest = json.loads(payload.pop("manifest.json"))
    for name, expected in manifest["files"].items():
        if digest(payload[name]) != expected:
            raise SystemExit(f"Original package hash mismatch: {name}")
    for name in ("AminScatter.dlx", "CyrusScatterEdit.dlm"):
        if payload[name] != (reference / "build/max2027-release/AminScatter" / name).read_bytes():
            raise SystemExit(f"Original package does not match the frozen native engine: {name}")
    payload["AminScatterObject.ms"] = (reference / "AminScatter/scripts/AminScatterObject.ms").read_bytes()
    payload["INSTALL.txt"] = (
        "Cyrus Scatter 0.59 - Max 2027 pre-performance comparison reference\n"
        "Contains the frozen native engine and frozen script, including diagnostic hooks.\n"
        "Run using Scripting > Run Script; save work, close Max and restart.\n"
        "Reopen the original saved test copy when comparing or rolling back.\n"
        "This package installs no CPU performance changes.\n"
    ).encode("utf-8")
    manifest["purpose"] = "Exact local pre-performance comparison reference, including tracing"
    manifest["reference_manifest_sha256"] = digest(manifest_path.read_bytes())
    manifest["files"] = {name: digest(data) for name, data in sorted(payload.items())}
    payload["manifest.json"] = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(payload.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 10, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data)
    with zipfile.ZipFile(args.output) as archive:
        if archive.testzip() is not None:
            raise SystemExit("Reference package integrity failed")
        for name, expected in manifest["files"].items():
            if digest(archive.read(name)) != expected:
                raise SystemExit(f"Reference package verification failed: {name}")
    args.output.with_suffix(".sha256").write_text(digest(args.output.read_bytes()) + "  " + args.output.name + "\n")
    print(f"Verified reference package: {args.output}")


if __name__ == "__main__":
    main()
