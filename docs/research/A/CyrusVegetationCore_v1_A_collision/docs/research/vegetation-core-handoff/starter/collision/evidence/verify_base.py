#!/usr/bin/env python3
"""Read-only baseline audit; writes only the requested owned-module receipt.

Run against the original supplied ZIP and the extracted packet after overlaying
Owner A's module. No historical harness, fixture generator or build is invoked.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import shlex
import sys
import zipfile

HANDOFF = "docs/research/vegetation-core-handoff"
OWNED = HANDOFF + "/starter/collision/"
FROZEN = HANDOFF + "/FROZEN-FILES.json"
HEADER = HANDOFF + "/starter/include/cyrus_vegetation/prototype_v1.hpp"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def safe_relative(name):
    path = PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts or "\\" in name:
        raise ValueError("Unsafe archive path: " + name)
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--original-zip", type=Path, required=True)
    parser.add_argument("--packet-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = args.packet_root.resolve()
    output = args.output.resolve()
    output.relative_to(root / OWNED)  # Refuse to write outside Owner A's module.
    original_zip = args.original_zip.resolve()
    errors = []
    records = []
    frozen_records = []
    with zipfile.ZipFile(original_zip) as archive:
        entries = [entry for entry in archive.infolist() if not entry.is_dir()]
        names = [entry.filename for entry in entries]
        if len(set(names)) != len(names):
            errors.append("Duplicate original ZIP file names")
        for entry in entries:
            name = str(safe_relative(entry.filename))
            expected = archive.read(entry)
            actual_path = root / name
            actual = None
            # Reject a symlink anywhere on the file's route through the packet.
            route = [actual_path, *actual_path.parents]
            safe = not any(path.is_symlink() for path in route if path != root.parent)
            if safe and actual_path.is_file():
                actual = actual_path.read_bytes()
            match = actual == expected
            owned = name.startswith(OWNED)
            if not match and not owned:
                errors.append("Original outside owned module changed/missing: " + name)
            records.append({
                "path": name, "owned": owned, "byte_identical": match,
                "archive_bytes": len(expected), "archive_sha256": sha256(expected),
                "actual_bytes": None if actual is None else len(actual),
                "actual_sha256": None if actual is None else sha256(actual),
            })
        original_manifest = json.loads(archive.read("PACKAGE-MANIFEST.json"))
        frozen_manifest = json.loads(archive.read(FROZEN))
        edition = original_manifest["edition"]
        if edition != frozen_manifest["edition"]:
            errors.append("Package and frozen editions differ")
        if len(frozen_manifest["files"]) != 4:
            errors.append("Expected four frozen file records")
        for item in frozen_manifest["files"]:
            name = HANDOFF + "/" + str(safe_relative(item["path"]))
            original = archive.read(name)
            target = root / name
            actual = target.read_bytes() if target.is_file() and not target.is_symlink() else b""
            match = (len(original) == len(actual) == item["bytes"] and
                     sha256(original) == sha256(actual) == item["sha256"])
            if not match:
                errors.append("Frozen bytes/hash mismatch: " + name)
            frozen_records.append({
                "path": name, "declared_bytes": item["bytes"],
                "declared_sha256": item["sha256"],
                "archive_bytes": len(original), "archive_sha256": sha256(original),
                "actual_bytes": len(actual), "actual_sha256": sha256(actual),
                "verified": match,
            })
    paths = list(root.rglob("*"))
    symlinks = sorted(str(path.relative_to(root)) for path in paths if path.is_symlink())
    if symlinks:
        errors.append("Packet contains symlinks")
    current_files = {path.relative_to(root).as_posix() for path in paths if path.is_file()}
    additions = current_files - set(names)
    outside_additions = sorted(name for name in additions if not name.startswith(OWNED))
    if outside_additions:
        errors.append("Files added outside owned module")
    header = next(item for item in frozen_records if item["path"] == HEADER)
    exit_code = 0 if not errors else 1
    receipt = {
        "schema": 1, "role": "Owner A - collision", "edition": edition,
        "result": "PASS" if exit_code == 0 else "FAIL",
        "archive": {"path": str(original_zip), "bytes": original_zip.stat().st_size,
                    "sha256": sha256(original_zip.read_bytes())},
        "packet_root": str(root), "owned_directory": OWNED,
        "header_actual_sha256": header["actual_sha256"],
        "counts": {
            "original_files": len(records),
            "original_files_outside_owned": sum(not item["owned"] for item in records),
            "original_files_byte_identical": sum(item["byte_identical"] for item in records),
            "outside_originals_byte_identical": sum(item["byte_identical"] and not item["owned"] for item in records),
            "frozen_files": len(frozen_records),
            "frozen_files_verified": sum(item["verified"] for item in frozen_records),
            "added_files_outside_owned": len(outside_additions),
        },
        "added_files_outside_owned": outside_additions,
        "symlinks": symlinks, "errors": errors,
        "frozen_files": frozen_records, "original_files": records,
        "receipt": {
            "argv": [sys.executable, *sys.argv],
            "command": shlex.join([sys.executable, *sys.argv]),
            "working_directory": str(Path.cwd()),
            "completed_at_utc": datetime.now(timezone.utc).isoformat(),
            "exit_code": exit_code,
            "script_sha256": sha256(Path(__file__).read_bytes()),
        },
        "scope": "Byte comparison and SHA-256 checks only. Module additions are permitted and are not frozen by this receipt. No historical tests or host validation executed.",
    }
    output.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"result": receipt["result"], "edition": edition,
                      "header_actual_sha256": header["actual_sha256"],
                      "counts": receipt["counts"], "exit_code": exit_code}))
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
