"""Local filesystem/Git observations and bounded content identity."""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from urllib.parse import unquote

from rules import (audit_row, classify, knowledge_status, navigation_metadata, parse_folder_tokens,
                   path_key, policy_for, read_inventory, relative_path)

TOOL_VERSION = "0.2.0"
SCHEMA_VERSION = "cyrus.file-catalog/2"
FIELDS = ["schema_version", "path", "size_bytes", "ext", "mtime_utc", "sha256",
          "hash_status", "hash_skip_reason", "inspection_policy", "catalog_only", "git_status",
          "git_worktree_status", "kind", "component", "path_version", "path_date",
          "version_source", "date_source", "inventory_decision", "inventory_reason",
          "inventory_match", "knowledge_status", "status_source", "referenced_by_current_docs",
          "current_reference_sources", "generated",
          "generated_source", "duplicate_group", "classification_rule"]


def progress(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


def git(root: Path, *args: str, data: bytes | None = None, allowed=(0,)) -> bytes:
    env = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
    result = subprocess.run(["git", "-c", "core.quotepath=false", "-c", "core.fsmonitor=false", "-C", str(root), *args],
                            input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    if result.returncode not in allowed:
        raise RuntimeError(f"git {' '.join(args)}: {result.stderr.decode('utf-8', 'replace').strip()}")
    return result.stdout


def decode_paths(data: bytes) -> list[str]:
    return [p.decode("utf-8", "surrogateescape") for p in data.split(b"\0") if p]


def parse_git_status(data: bytes) -> list[dict]:
    parts = decode_paths(data)
    result = []
    index = 0
    while index < len(parts):
        entry = parts[index]
        row = {"path": entry[3:], "xy": entry[:2], "original_path": None}
        if "R" in row["xy"] or "C" in row["xy"]:
            index += 1
            row["original_path"] = parts[index]
        result.append(row)
        index += 1
    return sorted(result, key=lambda r: (path_key(r["path"]), r["path"]))


def git_snapshot(root: Path) -> dict:
    top = Path(git(root, "rev-parse", "--show-toplevel").decode("utf-8").strip()).resolve()
    if top != root:
        raise ValueError("--root must be the Git repository root")
    return {"branch": git(root, "branch", "--show-current").decode("utf-8").strip(),
            "head": git(root, "rev-parse", "HEAD").decode("ascii").strip(),
            "index_sha256": hashlib.sha256(git(root, "ls-files", "--stage", "-z")).hexdigest(),
            "working_tree": parse_git_status(git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")),
            "tracked": sorted(decode_paths(git(root, "ls-files", "--cached", "-z")))}


def assign_git(rows: list[dict], snapshot: dict, root: Path) -> None:
    tracked = {path_key(p) for p in snapshot["tracked"]}
    dirty = {path_key(r["path"]): r["xy"] for r in snapshot["working_tree"]}
    candidates = [r["path"] for r in rows if path_key(r["path"]) not in tracked]
    ignored = set()
    # Bound stdin allocations as well as command length. All path operations are NUL safe.
    for offset in range(0, len(candidates), 2000):
        payload = b"".join(p.encode("utf-8", "surrogateescape") + b"\0" for p in candidates[offset:offset + 2000])
        ignored.update(path_key(p) for p in decode_paths(git(root, "check-ignore", "--stdin", "-z", data=payload, allowed=(0, 1))))
    for row in rows:
        key = path_key(row["path"])
        row["git_status"] = "tracked" if key in tracked else "ignored" if key in ignored else "untracked"
        row["git_worktree_status"] = dirty.get(key, "  " if key in tracked else None)


def is_link(metadata: os.stat_result) -> bool:
    return stat.S_ISLNK(metadata.st_mode) or bool(getattr(metadata, "st_file_attributes", 0) & 0x400)


def identity(metadata: os.stat_result) -> tuple:
    return (metadata.st_dev, metadata.st_ino, metadata.st_size, metadata.st_mtime_ns, metadata.st_ctime_ns)


def safe_path(root: Path, relative: str) -> Path:
    """lstat every ancestor, without resolving or opening a link target."""
    relative_path(relative)
    current = root
    for segment in relative.split("/"):
        current = current / segment
        if is_link(current.lstat()):
            raise OSError(f"link/reparse point excluded: {relative}")
    return current


def stable_hash(path: Path, before: os.stat_result, limit: int, root: Path) -> tuple[str | None, str, str | None]:
    try:
        safe_path(root, path.relative_to(root).as_posix())
        digest = hashlib.sha256()
        # Verify the opened handle before reading any bytes, including on Windows.
        flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
        with os.fdopen(os.open(path, flags), "rb") as handle:
            if identity(os.fstat(handle.fileno())) != identity(before):
                return None, "changed_during_scan", "identity changed before reading"
            count = 0
            while chunk := handle.read(min(1024 * 1024, limit - count + 1)):
                count += len(chunk)
                if count > limit:
                    return None, "changed_during_scan", "file grew past maximum hash size"
                digest.update(chunk)
            after_handle = os.fstat(handle.fileno())
        after_path = path.lstat()
        if is_link(after_path) or identity(before) != identity(after_handle) or identity(before) != identity(after_path):
            return None, "changed_during_scan", "metadata/identity changed while reading"
        return digest.hexdigest(), "hashed", None
    except OSError as exc:
        return None, "error", str(exc)


def exclusion(path: str, reason: str, is_directory: bool | None) -> dict:
    return {"path": path, "policy": "skip", "reason": reason, "is_directory": is_directory,
            "file_count": None, "size_bytes": None, "traversed": False}


def error(path: str, operation: str, message: str) -> dict:
    return {"path": path, "operation": operation, "error": message}


def read_controls(root: Path, config: dict, errors: list[dict]) -> dict:
    """Only explicitly named provenance inputs are decoded; all other content is hashed only."""
    cache: dict[str, str] = {}
    hashes = {}

    def read(relative: str) -> str | None:
        if relative in cache:
            return cache[relative]
        try:
            if policy_for(relative, False, config)[0] != "full":
                raise OSError("control input does not have full inspection permission")
            path = safe_path(root, relative)
            before = path.lstat()
            if not stat.S_ISREG(before.st_mode) or before.st_size > min(config["max_control_bytes"], config["max_hash_bytes"]):
                raise OSError("control input is not a bounded regular file")
            with path.open("rb") as handle:
                if identity(before) != identity(os.fstat(handle.fileno())):
                    raise OSError("control input changed before reading")
                raw = handle.read(config["max_control_bytes"] + 1)
                if identity(before) != identity(os.fstat(handle.fileno())):
                    raise OSError("control input changed while reading")
            if len(raw) > config["max_control_bytes"] or identity(before) != identity(path.lstat()):
                raise OSError("control input changed/grew while reading")
            cache[relative] = raw.decode("utf-8-sig")
            hashes[relative] = hashlib.sha256(raw).hexdigest()
            return cache[relative]
        except (OSError, UnicodeError) as exc:
            errors.append(error(relative, "read_control_input", str(exc)))
            return None

    text = read(config["inventory"])
    inventory, audit = read_inventory(text, config) if text is not None else ({}, [])
    for item in audit:
        errors.append(error(item["path"], item["finding"], item["detail"]))
    references = defaultdict(set)
    maintained_sources = defaultdict(set)
    readme = read(config["readme"])
    if readme is not None:
        for target in re.findall(r"\[[^\]]+\]\(([^)#]+)(?:#[^)]*)?\)", readme):
            if re.match(r"[A-Za-z]+:", target):
                continue
            try:
                relative = relative_path(unquote(target))
            except ValueError:
                continue
            if Path(relative).suffix.casefold() == ".md":
                references[path_key(relative)].add(config["readme"])
    manifests = {}
    for source in config["source_manifests"]:
        value = read(source)
        if value is None:
            continue
        try:
            manifest = json.loads(value)
            if not isinstance(manifest, dict):
                raise ValueError("source manifest must be an object")
            for document in manifest.get("documents", []):
                relative = relative_path(document["path"])
                references[path_key(relative)].add(source)
                if source in config.get("maintained_source_manifests", []):
                    maintained_sources[path_key(relative)].add(source)
            if manifest.get("catalog") is not None:
                relative = relative_path(manifest["catalog"])
                references[path_key(relative)].add(source)
            for relative, digest in manifest.get("reviewedSourceHashes", {}).items():
                relative_path(relative)
                if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
                    raise ValueError(f"invalid reviewed hash: {relative}")
                references[path_key(relative)].add(source)
            manifests[source] = manifest
        except (ValueError, KeyError, TypeError) as exc:
            errors.append(error(source, "parse_source_manifest", str(exc)))
    versions = []
    for rule in config["version_observations"]:
        value = read(rule["source"])
        matches = list(dict.fromkeys(re.findall(rule["regex"], value or "", re.IGNORECASE | re.MULTILINE)))
        versions.append({"id": rule["id"], "component": rule["component"],
                         "version": matches[0] if len(matches) == 1 else None,
                         "source": rule["source"], "observation_status": "observed" if len(matches) == 1 else "missing_or_conflicting",
                         "candidates": matches})
    return {"inventory": inventory, "audit": audit,
            "references": {k: sorted(v, key=lambda p: (path_key(p), p)) for k, v in references.items()},
            "maintained_sources": {k: sorted(v, key=lambda p: (path_key(p), p)) for k, v in maintained_sources.items()},
            "source_manifests": manifests, "hashes": hashes, "versions": versions}


def scan_tree(root: Path, config: dict, controls: dict, errors: list[dict]) -> tuple:
    rows = []
    exclusions = []
    parser_issues = []
    identities = {}
    directory_entries = {}

    def visit(parent: Path) -> None:
        relative_parent = parent.relative_to(root).as_posix()
        try:
            if parent != root:
                safe_path(root, relative_parent)
            with os.scandir(parent) as iterator:
                entries = sorted(iterator, key=lambda e: (e.name.casefold(), e.name))
            directory_entries[relative_parent] = tuple(e.name for e in entries)
        except OSError as exc:
            errors.append(error(relative_parent, "enumerate_directory", str(exc)))
            return
        for entry in entries:
            path = Path(entry.path)
            relative = path.relative_to(root).as_posix()
            try:
                # On Windows DirEntry.stat() can return zero inode/device IDs.
                # Use lstat so identity checks compare like-for-like with fstat.
                metadata = path.lstat()
                directory = stat.S_ISDIR(metadata.st_mode)
                if is_link(metadata):
                    exclusions.append(exclusion(relative, "symlink/junction/reparse point; target not traversed", directory))
                    continue
                policy, reason = policy_for(relative, directory, config)
                if policy == "skip":
                    exclusions.append(exclusion(relative, reason, directory))
                    continue
                if directory:
                    visit(path)
                    continue
                if not stat.S_ISREG(metadata.st_mode):
                    exclusions.append(exclusion(relative, "not a regular file", False))
                    continue
                parsed = parse_folder_tokens(relative, config)
                parser_issues.extend(parsed.pop("issues"))
                inventory_row = controls["inventory"].get(path_key(relative))
                status, source = knowledge_status(relative, inventory_row, config, controls["maintained_sources"])
                row = {"schema_version": SCHEMA_VERSION, "path": relative,
                       "size_bytes": metadata.st_size, "ext": path.suffix.casefold(),
                       "mtime_utc": dt.datetime.fromtimestamp(metadata.st_mtime_ns // 10**9, dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S") + f".{metadata.st_mtime_ns % 10**9:09d}Z",
                       "sha256": None, "hash_status": "skipped_policy", "hash_skip_reason": reason if policy != "full" else None, "inspection_policy": policy,
                       "catalog_only": policy != "full", "git_status": None, "git_worktree_status": None,
                       **classify(relative, config), **parsed,
                       "inventory_decision": inventory_row["decision"] if inventory_row else None,
                       "inventory_reason": inventory_row["reason"] if inventory_row else None,
                       "inventory_match": "matched" if inventory_row else "not_listed",
                       "knowledge_status": status, "status_source": source,
                       **navigation_metadata(relative, controls["references"]), "duplicate_group": None}
                if policy == "full":
                    if metadata.st_size > config["max_hash_bytes"]:
                        row.update(hash_status="skipped_size", catalog_only=True,
                                   hash_skip_reason=f"size_bytes exceeds max_hash_bytes={config['max_hash_bytes']}")
                    else:
                        digest, hash_status, message = stable_hash(path, metadata, config["max_hash_bytes"], root)
                        row.update(sha256=digest, hash_status=hash_status)
                        if message:
                            errors.append(error(relative, "sha256", message))
                rows.append(row)
                identities[relative] = identity(metadata)
                if len(rows) % 1000 == 0:
                    progress(f"Cataloged {len(rows):,} files...")
            except OSError as exc:
                errors.append(error(relative, "stat_file", str(exc)))
    visit(root)
    return rows, exclusions, parser_issues, identities, directory_entries


def verify_scan(root: Path, rows: list[dict], identities: dict, directories: dict,
                errors: list[dict]) -> None:
    for row in rows:
        try:
            path = safe_path(root, row["path"])
            if identity(path.lstat()) == identities[row["path"]]:
                continue
            message = "identity changed after initial inspection"
        except OSError as exc:
            message = str(exc)
        row.update(sha256=None, hash_status="changed_during_scan", duplicate_group=None)
        errors.append(error(row["path"], "verify_snapshot", message))
    for relative, names in directories.items():
        try:
            path = root if relative == "." else safe_path(root, relative)
            with os.scandir(path) as iterator:
                after = tuple(e.name for e in sorted(iterator, key=lambda e: (e.name.casefold(), e.name)))
            if after != names:
                errors.append(error(relative, "verify_directory", "directory membership changed during scan"))
        except OSError as exc:
            errors.append(error(relative, "verify_directory", str(exc)))


def assign_duplicates(rows: list[dict]) -> list[dict]:
    groups = defaultdict(list)
    for row in rows:
        row["duplicate_group"] = None
        if row["hash_status"] == "hashed" and row["sha256"]:
            groups[row["sha256"]].append(row)
    result = []
    for digest, members in groups.items():
        if len(members) < 2:
            continue
        group_id = "sha256:" + digest
        for member in members:
            member["duplicate_group"] = group_id
        result.append({"duplicate_group": group_id, "file_count": len(members),
                       "size_bytes_each": members[0]["size_bytes"],
                       "potential_duplicate_bytes": sum(m["size_bytes"] for m in members[1:]),
                       "paths": sorted(m["path"] for m in members)})
    return sorted(result, key=lambda g: (-g["potential_duplicate_bytes"], g["duplicate_group"]))


def reconcile(rows: list[dict], exclusions: list[dict], controls: dict, config: dict) -> list[dict]:
    audit = list(controls["audit"])
    present = {path_key(r["path"]): r for r in rows}
    excluded = [path_key(r["path"]) for r in exclusions]
    for key, inventory_row in controls["inventory"].items():
        path = inventory_row["path"]
        if key in present:
            finding = "removed_but_present" if inventory_row["decision"] == "removed" else "exists"
        elif policy_for(path, False, config)[0] == "skip" or any(key == p or key.startswith(p + "/") for p in excluded):
            finding = "not_inspected"
        else:
            finding = "missing_intentionally_removed" if inventory_row["decision"] == "removed" else "missing_unexpected"
        audit.append(audit_row(path, finding, row=inventory_row))
    for row in rows:
        old_status = config["inventory_status"].get(row["inventory_decision"], "unknown")
        if row["inventory_match"] == "matched" and old_status != row["knowledge_status"]:
            audit.append(audit_row(row["path"], "authority_conflict",
                                   f"old decision implies {old_status}; current rule yields {row['knowledge_status']}: {row['status_source']}",
                                   controls["inventory"].get(path_key(row["path"]))))
        if row["inventory_match"] == "not_listed" and row["kind"] == "doc":
            if row["knowledge_status"] == "current":
                audit.append(audit_row(row["path"], "current_candidate_not_listed", row["status_source"]))
            elif row["component"] == "docs":
                audit.append(audit_row(row["path"], "unlisted_document_review", "coverage candidate; not a documentation defect"))
    for source, manifest in controls["source_manifests"].items():
        for path, digest in manifest.get("reviewedSourceHashes", {}).items():
            actual = present.get(path_key(path))
            if actual is None or actual["hash_status"] != "hashed":
                finding = "source_fingerprint_unverified"
            elif actual["sha256"] != digest:
                finding = "source_fingerprint_mismatch"
            else:
                continue
            audit.append(audit_row(path, finding, f"{source}: reviewed={digest}; observed={actual['sha256'] if actual else None}"))
    return sorted(audit, key=lambda r: (path_key(r["path"]), r["path"], r["finding"], r["row_number"] or 0))
