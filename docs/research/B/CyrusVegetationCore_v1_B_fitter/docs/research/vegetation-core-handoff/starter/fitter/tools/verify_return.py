#!/usr/bin/env python3
"""Verify the complete handback ZIP and, optionally, its frozen coordinator base."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import stat
import zipfile


def require(condition, message):
    if not condition:
        raise ValueError(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip")
    parser.add_argument("--base", help="Path to docs/research/vegetation-core-handoff in the coordinator tree")
    args = parser.parse_args()
    with zipfile.ZipFile(args.zip) as archive:
        require(archive.testzip() is None, "ZIP CRC failure")
        entries = archive.infolist()
        names = [x.filename for x in entries]
        require(len({x.casefold() for x in names}) == len(names), "Duplicate/case-colliding ZIP entries")
        for item in entries:
            p = PurePosixPath(item.filename)
            require(not p.is_absolute() and ".." not in p.parts and "\\" not in item.filename, "Unsafe path: " + item.filename)
            require(not stat.S_ISLNK(item.external_attr >> 16), "Symlink in handback")
            require(not item.is_dir(), "Unexpected directory-only entry")
        manifest = json.loads(archive.read("return-manifest.json"))
        require(manifest["role"] == "B", "Wrong owner")
        require(manifest["edition"] == "CyrusScatter_Vegetation_Core_Handoff_v1", "Wrong edition")
        owned = manifest["owned_directory"].rstrip("/") + "/"
        expected = {x["path"] for x in manifest["files"]}
        require(len(expected) == len(manifest["files"]), "Duplicate manifest paths")
        require(expected | {"return-manifest.json"} == set(names), "Manifest is not a complete inventory")
        for item in manifest["files"]:
            require(item["path"] == "RETURN-REPORT.md" or item["path"].startswith(owned), "File outside B's scope")
            content = archive.read(item["path"])
            require(len(content) == item["bytes"], "Size mismatch: " + item["path"])
            require(hashlib.sha256(content).hexdigest() == item["sha256"], "Hash mismatch: " + item["path"])
        if args.base:
            base = Path(args.base)
            for item in manifest["base_frozen_files"]:
                content = (base / item["path"]).read_bytes()
                require(len(content) == item["bytes"], "Frozen size mismatch: " + item["path"])
                require(hashlib.sha256(content).hexdigest() == item["sha256"], "Frozen hash mismatch: " + item["path"])
        print(json.dumps({"verified": True, "role": "B", "manifested_files": len(expected),
                          "frozen_base_checked": bool(args.base),
                          "archive_sha256": hashlib.sha256(Path(args.zip).read_bytes()).hexdigest()}, indent=2))


if __name__ == "__main__":
    main()
