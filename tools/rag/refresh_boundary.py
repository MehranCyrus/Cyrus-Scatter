"""Detector-owned startup primitives; imports only the Python standard library.

Policy schema/deny semantics and process ownership deliberately match the existing
contracts. No inspected runtime module is imported or executed by this boundary.
"""
from __future__ import annotations
import ctypes
import fnmatch
import os
from pathlib import Path, PurePosixPath
import re
import signal
import stat
import tomllib
import unicodedata
from ctypes import wintypes


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


def is_link(metadata: os.stat_result) -> bool:
    return stat.S_ISLNK(metadata.st_mode) or bool(getattr(metadata, "st_file_attributes", 0) & 0x400)


def identity(metadata: os.stat_result) -> tuple:
    return (metadata.st_dev, metadata.st_ino, metadata.st_size, metadata.st_mtime_ns, metadata.st_ctime_ns)


class WorkerJob:
    def __init__(self, pid):
        self.handle = None
        if os.name != "nt":
            return
        kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        class Basic(ctypes.Structure):
            _fields_ = [("ProcessTime", ctypes.c_int64), ("JobTime", ctypes.c_int64),
                        ("Flags", wintypes.DWORD), ("Min", ctypes.c_size_t), ("Max", ctypes.c_size_t),
                        ("Active", wintypes.DWORD), ("Affinity", ctypes.c_size_t),
                        ("Priority", wintypes.DWORD), ("Scheduling", wintypes.DWORD)]
        class IO(ctypes.Structure):
            _fields_ = [(name, ctypes.c_uint64) for name in ("r", "w", "o", "rb", "wb", "ob")]
        class Extended(ctypes.Structure):
            _fields_ = [("Basic", Basic), ("IO", IO), ("ProcessMemory", ctypes.c_size_t),
                        ("JobMemory", ctypes.c_size_t), ("PeakProcess", ctypes.c_size_t),
                        ("PeakJob", ctypes.c_size_t)]
        for name, args, result in (
            ("CreateJobObjectW", [ctypes.c_void_p, wintypes.LPCWSTR], wintypes.HANDLE),
            ("OpenProcess", [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD], wintypes.HANDLE),
            ("SetInformationJobObject", [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD], wintypes.BOOL),
            ("AssignProcessToJobObject", [wintypes.HANDLE, wintypes.HANDLE], wintypes.BOOL),
            ("CloseHandle", [wintypes.HANDLE], wintypes.BOOL)):
            function = getattr(kernel, name); function.argtypes = args; function.restype = result
        self.kernel = kernel
        job = kernel.CreateJobObjectW(None, None)
        info = Extended(); info.Basic.Flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        process = kernel.OpenProcess(0x0100 | 0x0001, False, pid)
        try:
            if not job or not process or not kernel.SetInformationJobObject(job, 9, ctypes.byref(info), ctypes.sizeof(info)) or not kernel.AssignProcessToJobObject(job, process):
                raise OSError("cannot establish owned worker kill scope")
            self.handle = job
        finally:
            if process: kernel.CloseHandle(process)
            if job and self.handle is None: kernel.CloseHandle(job)

    def close(self):
        if self.handle is not None:
            self.kernel.CloseHandle(self.handle)
            self.handle = None


def kill_worker(process):
    if process.returncode is None:
        if os.name == "nt":
            process.kill()
        else:
            os.killpg(process.pid, signal.SIGKILL)


# Tiny unicode-persian/1 derivation, limited to this known producer identity.
# This is an independent calculation; extract.py is never executed.
NORMALIZER_SOURCE_SHA256 = "2806b4b303cf6145a2414f8766e59461756137cdf8d2900924f3304b8310b717"


def normalize_v1(text):
    text = unicodedata.normalize("NFKC", text).translate(str.maketrans(
        {"ي": "ی", "ى": "ی", "ك": "ک", "\u200c": " ", "\u200d": " ", "\ufeff": " "}))
    return " ".join(text.casefold().split())
