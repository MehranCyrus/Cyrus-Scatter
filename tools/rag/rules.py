"""Small, explicit rules. No source body inference or model classification."""
from __future__ import annotations

import csv
import datetime as dt
import fnmatch
import io
import re
import tomllib
from pathlib import Path, PurePosixPath


class ConfigError(ValueError):
    pass


def path_key(path: str) -> str:
    return path.replace("\\", "/").casefold()


def relative_path(path: str) -> str:
    path = path.replace("\\", "/")
    if not path or path.startswith("/") or re.match(r"^[A-Za-z]:", path):
        raise ValueError("expected a repository-relative path")
    if any(part in ("", ".", "..") for part in path.split("/")):
        raise ValueError("empty, dot, or parent path segment")
    return path


def load_config(path: Path) -> dict:
    try:
        raw = path.read_bytes()
        config = tomllib.loads(raw.decode("utf-8"))
        if type(config["schema_version"]) is not int or config["schema_version"] != 1:
            raise ValueError("unsupported configuration schema")
        for field in ("max_hash_bytes", "max_control_bytes"):
            if type(config[field]) is not int or config[field] <= 0:
                raise ValueError(f"{field} must be a positive integer")
        for field in ("inventory", "readme"):
            relative_path(config[field])
        for value in config["source_manifests"]:
            relative_path(value)
        for value in config.get("maintained_source_manifests", []):
            relative_path(value)
            if value not in config["source_manifests"]:
                raise ValueError("maintained_source_manifests must be configured source_manifests")
        required = {"skip_directory_names", "skip_path_patterns", "sensitive_file_patterns",
                    "safe_file_exceptions", "metadata_directory_prefixes",
                    "metadata_path_patterns", "metadata_extensions"}
        if not required <= config["inspection"].keys():
            raise ValueError("missing inspection settings")
        for values in config["inspection"].values():
            if not isinstance(values, list) or any(not isinstance(v, str) for v in values):
                raise ValueError("inspection settings must be string arrays")
        for group in ("kinds", "components", "knowledge_rules", "generated_rules", "version_observations"):
            ids = set()
            for rule in config[group]:
                if rule["id"] in ids:
                    raise ValueError(f"duplicate {group} rule ID: {rule['id']}")
                ids.add(rule["id"])
                compiled = re.compile(rule["regex"], re.IGNORECASE)
                if group == "version_observations":
                    relative_path(rule["source"])
                    if compiled.groups != 1:
                        raise ValueError("version observations need exactly one capture group")
                elif group == "generated_rules":
                    rule["source"]
                else:
                    rule["value"]
                    if group == "knowledge_rules":
                        rule["evidence"]
            if not config[group]:
                raise ValueError(f"empty rule group: {group}")
        for key in ("version_regex", "date_regex", "version_candidate_regex", "date_candidate_regex"):
            pattern = config["parser"][key]
            compiled = re.compile(pattern)
            if key in ("version_regex", "date_regex") and "value" not in compiled.groupindex:
                raise ValueError(f"{key} requires a named value group")
        for value in [*config["inventory_status"].values(),
                      *(r["value"] for r in config["knowledge_rules"])]:
            if value not in ("current", "historical", "archive", "unknown"):
                raise ValueError(f"invalid knowledge status: {value}")
        if set(config["known_decisions"]) != set(config["inventory_status"]):
            raise ValueError("inventory decision/status keys disagree")
        return config
    except (OSError, ValueError, KeyError, TypeError, re.error) as exc:
        raise ConfigError(f"Invalid configuration {path}: {exc}") from exc


def match_rule(path: str, rules: list[dict]) -> dict | None:
    path = path.replace("\\", "/")
    return next((r for r in rules if re.search(r["regex"], path, re.IGNORECASE)), None)


def policy_for(path: str, is_dir: bool, config: dict) -> tuple[str, str]:
    """Evaluate ancestors too, so reconciliation cannot inspect a skipped subtree."""
    key = path_key(path)
    parts = key.split("/")
    settings = config["inspection"]
    dirs = parts if is_dir else parts[:-1]
    # These two boundaries cannot be relaxed by configuration.
    if any(p in (".git", "_local") for p in parts):
        return "skip", "mandatory repository metadata/runtime boundary"
    names = {n.casefold() for n in settings["skip_directory_names"]}
    if any(p in names for p in dirs):
        return "skip", "skip_directory_names"
    # Match directory entries themselves as well as their descendants.
    for pattern in settings["skip_path_patterns"]:
        if fnmatch.fnmatchcase(key, pattern.casefold()) or key == pattern.casefold().removesuffix("/**"):
            return "skip", f"skip_path_patterns:{pattern}"
    name = parts[-1]
    if name not in {n.casefold() for n in settings["safe_file_exceptions"]}:
        if any(fnmatch.fnmatchcase(p, pattern.casefold()) for p in parts
               for pattern in settings["sensitive_file_patterns"]):
            return "skip", "sensitive_file_patterns (contents not inspected)"
    for prefix in settings["metadata_directory_prefixes"]:
        if key == path_key(prefix) or key.startswith(path_key(prefix).rstrip("/") + "/"):
            return "metadata_only", f"metadata_directory_prefixes:{prefix}"
    for pattern in settings["metadata_path_patterns"]:
        normalized = path_key(pattern)
        if (fnmatch.fnmatchcase(key, normalized)
                or (is_dir and normalized.endswith("/**")
                    and fnmatch.fnmatchcase(key, normalized[:-3]))):
            return "metadata_only", f"metadata_path_patterns:{pattern}"
    if not is_dir and PurePosixPath(key).suffix in settings["metadata_extensions"]:
        return "metadata_only", "metadata_extensions"
    return "full", "ordinary repository file"


def parse_folder_tokens(path: str, config: dict) -> dict:
    versions: dict[str, list[str]] = {}
    dates: dict[str, list[str]] = {}
    issues = []
    parser = config["parser"]
    folders = path.replace("\\", "/").split("/")[:-1]
    for index, folder in enumerate(folders):
        source = "/".join(folders[:index + 1])
        valid_versions = list(re.finditer(parser["version_regex"], folder))
        for match in valid_versions:
            versions.setdefault(match["value"], []).append(source)
        for match in re.finditer(parser["version_candidate_regex"], folder):
            if not any(m.span() == match.span() for m in valid_versions):
                issues.append({"folder": source, "issue": "malformed_version", "token": match[0]})
        valid_dates = list(re.finditer(parser["date_regex"], folder))
        for match in valid_dates:
            try:
                dt.date.fromisoformat(match["value"])
                dates.setdefault(match["value"], []).append(source)
            except ValueError:
                issues.append({"folder": source, "issue": "malformed_date", "token": match[0]})
        for match in re.finditer(parser["date_candidate_regex"], folder):
            if not any(m.span() == match.span() for m in valid_dates):
                issues.append({"folder": source, "issue": "malformed_date", "token": match[0]})
    result = {"path_version": None, "path_date": None, "version_source": None, "date_source": None}
    for label, values in (("version", versions), ("date", dates)):
        if len(values) == 1:
            value = next(iter(values))
            result[f"path_{label}"] = value
            result[f"{label}_source"] = "; ".join(dict.fromkeys(values[value]))
        elif len(values) > 1:
            issues.append({"folder": "/".join(folders), "issue": f"conflicting_{label}",
                           "token": "; ".join(sorted(values))})
    result["issues"] = issues
    return result


def classify(path: str, config: dict) -> dict:
    kind = match_rule(path, config["kinds"])
    component = match_rule(path, config["components"])
    generated = match_rule(path, config["generated_rules"])
    return {"kind": kind["value"] if kind else "other",
            "component": component["value"] if component else "other",
            "classification_rule": f"kind:{kind['id'] if kind else 'fallback'};component:{component['id'] if component else 'fallback'}",
            "generated": generated is not None,
            "generated_source": generated["source"] if generated else None}


def navigation_metadata(path: str, references: dict[str, list[str]]) -> dict:
    """References observed only in configured entrypoints, independent of authority."""
    sources = sorted(set(references.get(path_key(path), [])), key=lambda p: (path_key(p), p))
    return {"referenced_by_current_docs": bool(sources), "current_reference_sources": sources}


def knowledge_status(path: str, inventory: dict | None, config: dict,
                     maintained_sources: dict[str, list[str]]) -> tuple[str, str]:
    rule = match_rule(path, config["knowledge_rules"])
    if rule:
        return rule["value"], f"rule:{rule['id']} | {rule['evidence']}"
    if path_key(path) in maintained_sources:
        sources = sorted(set(maintained_sources[path_key(path)]), key=lambda p: (path_key(p), p))
        return "current", "rule:curated-maintained-source | " + "; ".join(s + "#documents" for s in sources)
    if inventory:
        decision = inventory["decision"]
        return config["inventory_status"].get(decision, "unknown"), f"inventory:{decision} | {config['inventory']}"
    return "unknown", "rule:no-current-evidence"


AUDIT_FIELDS = ["row_number", "path", "decision", "reason", "finding", "detail"]


def audit_row(path: str, finding: str, detail: str = "", row: dict | None = None) -> dict:
    row = row or {}
    return dict(row_number=row.get("row_number"), path=path, decision=row.get("decision"),
                reason=row.get("reason"), finding=finding, detail=detail)


def read_inventory(text: str, config: dict) -> tuple[dict[str, dict], list[dict]]:
    rows: dict[str, dict] = {}
    audit = []
    duplicates = set()
    reader = csv.DictReader(io.StringIO(text.lstrip("\ufeff")), strict=True)
    if reader.fieldnames != ["path", "decision", "reason"]:
        return {}, [audit_row("", "invalid_inventory_header", "expected path,decision,reason")]
    try:
        for row_number, raw in enumerate(reader, 2):
            row = {**raw, "row_number": row_number}
            path = row.get("path") or ""
            try:
                if None in row or any(row.get(k) is None for k in ("path", "decision", "reason")):
                    raise ValueError("wrong number of columns")
                path = relative_path(path)
                if row["decision"] not in config["known_decisions"]:
                    raise ValueError(f"unknown decision: {row['decision']}")
            except ValueError as exc:
                audit.append(audit_row(path, "invalid_inventory_row", str(exc), row))
                continue
            key = path_key(path)
            row["path"] = path
            if key in rows or key in duplicates:
                if key in rows:
                    previous = rows.pop(key)
                    audit.append(audit_row(previous["path"], "duplicate_inventory_row", "ambiguous join; all copies excluded", previous))
                duplicates.add(key)
                audit.append(audit_row(path, "duplicate_inventory_row", "ambiguous join; all copies excluded", row))
            else:
                rows[key] = row
    except csv.Error as exc:
        audit.append(audit_row("", "invalid_inventory_csv", f"line {reader.line_num}: {exc}"))
    return rows, audit
