"""Local FTS5 baseline, bounded enrollment, atomic generations and checked citations."""
from __future__ import annotations

import hashlib
from contextlib import closing
import json
import os
import re
import sqlite3
import stat
import tempfile
import time
import tomllib
from pathlib import Path

import catalog
from contracts import (SEARCH_SCHEMA, IncompatibleIndex, IntegrityError, RetrievalError,
                       SourceProblem, StaleIndex)
from extract import EXTRACTION_VERSION, NORMALIZATION_VERSION, chunks, normalize
from integrity import INDEX_SCHEMA, verify_generation
from lexical import PROFILES, compile_query
from locations import corpus_location
from provenance import compact_identities
from rules import load_config, path_key, policy_for, relative_path

TOOL = Path(__file__).resolve().parent
SEARCH_VERSION = "0.3.0"
RUNTIME_FILES = ("extract.py", "retrieval.py", "build_index.py", "search.py", "evaluation.py", "evaluate.py", "verify_indexes.py", "retrieval.toml", "config.toml", "catalog.py", "rules.py", "contracts.py", "integrity.py", "lexical.py", "status.py", "ranking-v2.1.json", "glossary-v1.json")
RUNTIME_FILES += ("locations.py", "provenance.py", "adapter.py", "adapter_worker.py", "adapter_process.py", "adapter-requirements.lock.txt")


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def encoded(value) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


def write_json(path: Path, value) -> None:
    path.write_bytes(encoded(value))


def settings() -> dict:
    result = tomllib.loads((TOOL / "retrieval.toml").read_text(encoding="utf-8"))
    if result.get("schema_version") != 1 or any(type(v) is not int or v <= 0 for v in result.values()):
        raise RetrievalError("invalid retrieval configuration")
    if result["overlap_lines"] >= result["max_chunk_lines"]:
        raise RetrievalError("overlap must be smaller than chunk line bound")
    return result


def runtime_hashes() -> dict:
    return {name: digest((TOOL / name).read_bytes()) for name in RUNTIME_FILES}


def ranking_config() -> dict:
    try:
        result = json.loads((TOOL / "ranking-v2.1.json").read_text(encoding="utf-8"))
        if (result["schema"] != "cyrus.lexical-config/1" or result["default_profile"] not in PROFILES
                or len(result["bm25_weights"]) != 3
                or any(type(v) not in (int, float) or not 0 < v <= 10 for v in result["bm25_weights"])
                or any(type(result[k]) is not int or not 1024 <= result[k] <= 67108864
                       for k in ("max_response_bytes", "max_artifact_bytes"))):
            raise ValueError("invalid bounded ranking configuration")
        return result
    except (KeyError, TypeError, ValueError) as exc:
        raise IncompatibleIndex(f"invalid ranking configuration: {exc}") from exc


def read_source(root: Path, path: str, expected: str, policy: dict, limit: int) -> str:
    try:
        relative_path(path)
        if policy_for(path, False, policy)[0] != "full":
            raise SourceProblem(path, "forbidden", "current inspection policy does not permit content access")
        target = root / path
        for ancestor in [*reversed(target.parents), target]:
            if catalog.is_link(ancestor.lstat()):
                raise SourceProblem(path, "forbidden", "link/reparse point excluded")
        before = target.lstat()
        limit = min(limit, policy["max_hash_bytes"])
        if not stat.S_ISREG(before.st_mode) or before.st_size > limit:
            raise SourceProblem(path, "forbidden", "not a bounded regular text file")
        flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
        with os.fdopen(os.open(target, flags), "rb") as handle:
            if catalog.identity(before) != catalog.identity(os.fstat(handle.fileno())):
                raise SourceProblem(path, "changed", "identity changed before extraction")
            raw = handle.read(limit + 1)
            after = os.fstat(handle.fileno())
        if (len(raw) > limit or catalog.identity(before) != catalog.identity(after)
                or catalog.identity(before) != catalog.identity(target.lstat()) or digest(raw) != expected):
            raise SourceProblem(path, "changed", "hash/identity mismatch")
    except SourceProblem:
        raise
    except FileNotFoundError as exc:
        raise SourceProblem(path, "missing", str(exc)) from exc
    except OSError as exc:
        raise SourceProblem(path, "inaccessible", str(exc)) from exc
    except ValueError as exc:
        raise SourceProblem(path, "forbidden", str(exc)) from exc
    try:
        text = raw.decode("utf-8")
    except UnicodeError as exc:
        raise SourceProblem(path, "changed", "source is not UTF-8 text") from exc
    if "\0" in text:
        raise SourceProblem(path, "changed", "binary NUL in selected text")
    return text


def load_corpus(root: Path, corpus_path: Path, audit: Path, policy: dict, bounds: dict) -> tuple[dict, dict, dict]:
    corpus_path = corpus_location(root, corpus_path)
    corpus = json.loads(corpus_path.read_text(encoding="utf-8"))
    run = json.loads((audit / "run.json").read_text(encoding="utf-8"))
    if corpus.get("schema") != "cyrus.corpus/1" or run.get("schema_version") != catalog.SCHEMA_VERSION or not run.get("scan_complete") or run.get("errors"):
        raise RetrievalError("unsupported corpus/audit schema or incomplete audit")
    if str(root.resolve()) != run["root"]:
        raise RetrievalError("audit belongs to a different root")
    rows = {path_key(r["path"]): r for r in map(json.loads, (audit / "manifest.jsonl").read_text(encoding="utf-8").splitlines())}
    sources = corpus["sources"]
    if not 0 < len(sources) <= bounds["max_sources"]:
        raise RetrievalError("corpus source count exceeds bounds")
    seen, texts, total = set(), {}, 0
    for source in sources:
        path = relative_path(source["path"])
        key = path_key(path)
        if key in seen or key.startswith("tools/rag/") or key.startswith("_local/"):
            raise RetrievalError(f"duplicate or tooling/evaluation enrollment forbidden: {path}")
        seen.add(key)
        row = rows.get(key)
        if not row or row["hash_status"] != "hashed" or row["inspection_policy"] != "full" or row["catalog_only"] or not row["sha256"] or row["sha256"] != source["sha256"]:
            raise RetrievalError(f"source lacks a matching complete full-policy hash: {path}")
        for field in ("knowledge_status", "status_source", "inventory_decision", "inventory_reason", "referenced_by_current_docs", "current_reference_sources", "component", "generated", "generated_source"):
            if source.get(field) != row.get(field):
                raise RetrievalError(f"corpus provenance differs from audit: {path}: {field}")
        if not source.get("selection_reason") or not source.get("review_status") or source.get("role") not in ("maintained_guide", "implementation", "test", "historical_evidence", "proposal", "editorial", "delivered_artifact"):
            raise RetrievalError(f"missing review/role/reason: {path}")
        relative_path(source["canonical"]["preferred_path"])
        texts[path] = read_source(root, path, source["sha256"], policy, bounds["max_source_bytes"])
        total += len(texts[path].encode("utf-8"))
        if total > bounds["max_corpus_bytes"]:
            raise RetrievalError("corpus byte bound exceeded")
        previous = 0
        from extract import line_range
        for start, end in source["ranges"]:
            line_range(texts[path], start, end)
            if start <= previous:
                raise RetrievalError("corpus ranges must be ordered and non-overlapping")
            previous = end
    return corpus, texts, run


def prepare_generation(root: Path, destination: Path, kind: str) -> Path:
    destination = Path(os.path.abspath(destination))
    allowed = root / "_local" / "rag" / kind
    if destination == allowed or not destination.is_relative_to(allowed):
        raise RetrievalError(f"output must be fresh inside {allowed}")
    current = root
    for part in destination.relative_to(root).parts:
        current = current / part
        try:
            if catalog.is_link(current.lstat()):
                raise RetrievalError("output ancestor is a link/reparse point")
        except FileNotFoundError:
            pass
    if destination.exists():
        raise RetrievalError(f"output already exists: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    return Path(tempfile.mkdtemp(prefix=f".{destination.name}.partial-", dir=destination.parent))


def build(root: Path, corpus_path: Path, audit: Path, out: Path) -> dict:
    started = time.perf_counter()
    root = root.resolve(strict=True)
    out = Path(os.path.abspath(out))
    stage = prepare_generation(root, out, "indexes")
    try:
        corpus_path = corpus_location(root, corpus_path)
        if audit is None:
            audit = root / json.loads(corpus_path.read_text(encoding="utf-8"))["initial_audit"]
        policy, bounds, ranking = load_config(TOOL / "config.toml"), settings(), ranking_config()
        before = catalog.git_snapshot(root)
        inputs = {"corpus_sha256": digest(corpus_path.read_bytes()), "runtime_sha256": runtime_hashes(),
                  "audit_manifest_sha256": digest((audit / "manifest.jsonl").read_bytes()),
                  "audit_run_sha256": digest((audit / "run.json").read_bytes())}
        corpus, texts, audit_run = load_corpus(root, corpus_path, audit, policy, bounds)
        records = []
        for source in sorted(corpus["sources"], key=lambda s: (path_key(s["path"]), s["path"])):
            records.extend(chunks(texts[source["path"]], source, bounds))
            if len(records) > bounds["max_chunks"]:
                raise RetrievalError("chunk count exceeds configured bound")
        records.sort(key=lambda c: (path_key(c["path"]), c["path"], c["locator"]["start_offset"], c["chunk_id"]))
        identities = {**inputs, "root": str(root), "corpus_path": str(corpus_path.resolve()), "audit_path": str(audit.resolve()),
                      "audit_schema": audit_run["schema_version"], "git_state": before,
                      "tool_version": SEARCH_VERSION, "extraction_version": EXTRACTION_VERSION,
                      "normalization_version": NORMALIZATION_VERSION, "settings": bounds, "ranking": ranking}
        logical = {"schema": INDEX_SCHEMA, "identities": identities, "sources": corpus["sources"], "chunks": records}
        generation = digest(encoded(logical))
        db = stage / "index.sqlite3"
        with closing(sqlite3.connect(db)) as connection:
            connection.execute("CREATE TABLE metadata (value TEXT NOT NULL)")
            connection.execute("CREATE TABLE chunks (id INTEGER PRIMARY KEY, path TEXT, component TEXT, role TEXT, status TEXT, data TEXT)")
            connection.execute("CREATE VIRTUAL TABLE search_chunks USING fts5(text, context, path, tokenize='unicode61 remove_diacritics 2')")
            metadata = {"schema": INDEX_SCHEMA, "generation_id": generation, "identities": identities, "sources": corpus["sources"]}
            connection.execute("INSERT INTO metadata VALUES (?)", (encoded(metadata).decode(),))
            for n, record in enumerate(records, 1):
                s = record["source"]
                connection.execute("INSERT INTO chunks VALUES (?,?,?,?,?,?)", (n, s["path"], s["component"], s["role"], s["knowledge_status"], encoded(record).decode()))
                connection.execute("INSERT INTO search_chunks(rowid,text,context,path) VALUES (?,?,?,?)", (n, record["search_text"], normalize(record["context"]), normalize(s["path"])))
            connection.commit()
        # Full selected-source verification again before publication.
        for source in corpus["sources"]:
            read_source(root, source["path"], source["sha256"], policy, bounds["max_source_bytes"])
        if (before != catalog.git_snapshot(root) or inputs["runtime_sha256"] != runtime_hashes()
                or inputs["corpus_sha256"] != digest(corpus_path.read_bytes())
                or inputs["audit_manifest_sha256"] != digest((audit / "manifest.jsonl").read_bytes())
                or inputs["audit_run_sha256"] != digest((audit / "run.json").read_bytes())):
            raise StaleIndex("index inputs changed during build")
        write_json(stage / "logical.json", logical)
        (stage / "chunks.jsonl").write_bytes(b"".join(encoded(r) for r in records))
        artifacts = ("logical.json", "chunks.jsonl", "index.sqlite3")
        if any((stage / name).stat().st_size > ranking["max_artifact_bytes"] for name in artifacts):
            raise RetrievalError("generation artifact exceeds configured byte bound")
        run = {"schema": INDEX_SCHEMA, "generation_id": generation, "complete": True, "identities": identities,
               "source_count": len(corpus["sources"]), "chunk_count": len(records), "database_bytes": db.stat().st_size,
               "artifact_sha256": {name: digest((stage / name).read_bytes()) for name in artifacts},
               "python_version": __import__("platform").python_version(), "sqlite_version": sqlite3.sqlite_version,
               "duration_seconds": round(time.perf_counter() - started, 6)}
        write_json(stage / "run.json", run)
        if out.exists():
            raise RetrievalError("destination appeared during publication")
        stage.rename(out)
        return run
    except Exception as exc:
        write_json(stage / "failure.json", {"complete": False, "error": str(exc), "requested_output": str(out)})
        raise


def open_index(path: Path, expected_root: Path | None = None, verify_searchable: bool = False) -> tuple[sqlite3.Connection, dict]:
    return verify_generation(Path(path), runtime_hashes(), settings(), ranking_config(), expected_root, verify_searchable)


def search(index: Path, query: str, top_k: int = 10, mode: str = "keyword", filters: dict | None = None, advanced: bool = False,
           profile: str | None = None, expected_root: Path | None = None) -> dict:
    started = time.perf_counter()
    bounds, ranking = settings(), ranking_config()
    if (not isinstance(query, str) or len(query) > bounds["max_query_chars"] or type(top_k) is not int
            or not 1 <= top_k <= bounds["max_top_k"] or type(advanced) is not bool
            or mode not in ("keyword", "identifier", "path") or (advanced and mode != "keyword")):
        raise RetrievalError("invalid query, mode, or top-k bound")
    filters = {} if filters is None else filters
    names = {"component": "component", "role": "role", "knowledge_status": "status"}
    if (not isinstance(filters, dict) or not filters.keys() <= names.keys()
            or any(not isinstance(v, str) or len(v) > 256 for v in filters.values())):
        raise RetrievalError("unsupported metadata filter")
    clauses = [f"chunks.{names[k]} = ?" for k in sorted(filters)]
    args = [filters[k] for k in sorted(filters)]
    where = " AND ".join(clauses) or "1"
    try:
        diagnostics = compile_query(query, mode, advanced, ranking["default_profile"] if profile is None else profile, bounds["max_query_terms"])
    except (ValueError, KeyError, TypeError) as exc:
        raise RetrievalError(f"invalid terminology/query configuration: {exc}") from exc
    connection, metadata = open_index(index, expected_root)
    try:
        normalized = diagnostics["normalized_query"]
        expression = diagnostics["fts_expression"]
        if mode == "keyword":
            if not expression.strip():
                candidates = []
            else:
                try:
                    weights = ",".join(str(w) for w in ranking["bm25_weights"])
                    candidates = connection.execute(f"SELECT chunks.data, bm25(search_chunks,{weights}) FROM search_chunks JOIN chunks ON chunks.id=search_chunks.rowid WHERE search_chunks MATCH ? AND " + where, [expression, *args]).fetchall()
                except sqlite3.OperationalError as exc:
                    raise RetrievalError(f"invalid explicit FTS expression: {exc}") from exc
        else:
            candidates = connection.execute("SELECT data,0.0 FROM chunks WHERE " + where, args).fetchall()
        ranked = []
        for raw, bm25 in candidates:
            record = json.loads(raw)
            exact_path = path_key(query.strip()) == path_key(record["path"])
            # Dotted names/versions are indivisible; a sentence-ending period is punctuation.
            exact_identifier = bool(normalized and re.search(r"(?<!\w)(?<!\w\.)" + re.escape(normalized) + r"(?!\w|\.\w)", normalize(record["original_text"])))
            if mode == "path" and not exact_path or mode == "identifier" and not exact_identifier:
                continue
            record["match"] = {"exact_path": exact_path, "exact_identifier": exact_identifier, "fts_bm25": bm25 if mode == "keyword" else None}
            ranked.append(record)
        ranked.sort(key=lambda r: (not r["match"]["exact_path"], not r["match"]["exact_identifier"], r["match"]["fts_bm25"] or 0.0, path_key(r["path"]), r["path"], r["locator"]["start_offset"], r["chunk_id"]))
        groups = {}
        rank_order = {r["chunk_id"]: i for i, r in enumerate(ranked)}
        for record in ranked:
            groups.setdefault(record["text_group"], []).append(record)
        results = []
        for members in groups.values():
            # A returned exact path always keeps that path; otherwise prefer an enrolled canonical original within identical text.
            representative = min(members, key=lambda r: (not r["match"]["exact_path"], r["source"]["canonical"]["preferred_path"] != r["path"], rank_order[r["chunk_id"]]))
            representative["equivalent_sources"] = [{"path": r["path"], "parent_sha256": r["parent_sha256"], "locator": r["locator"], "source": r["source"], "match": r["match"]} for r in members if r is not representative]
            representative["excerpt"] = representative["original_text"][:600]
            representative["excerpt_truncated"] = len(representative["original_text"]) > 600
            representative["rank"] = len(results) + 1
            results.append(representative)
            if len(results) == top_k:
                break
        root = Path(metadata["identities"]["root"])
        policy = load_config(TOOL / "config.toml")
        checked = {}
        for result in results:
            for source in [result["source"], *(a["source"] for a in result["equivalent_sources"])]:
                if source["path"] not in checked:
                    checked[source["path"]] = read_source(root, source["path"], source["sha256"], policy, bounds["max_source_bytes"])
            for citation in [result, *result["equivalent_sources"]]:
                loc = citation["locator"]
                fresh = checked[citation["path"]][loc["start_offset"]:loc["end_offset"]]
                if (citation is result and fresh != result["original_text"]) or digest(normalize(fresh).encode()) != result["text_group"]:
                    raise StaleIndex("indexed citation text/locator disagrees with source; rebuild required")
        response = {"schema": SEARCH_SCHEMA, "ok": True, "query": query, "mode": mode, "advanced": advanced,
                "filters": filters, "top_k": top_k, "fts_expression": expression, "diagnostics": diagnostics,
                "configuration_identities": compact_identities(metadata), "index_schema": INDEX_SCHEMA,
                "index_generation": metadata["generation_id"], "results": results, "stale": False,
                "freshness_scope": "Returned sources and duplicate provenance only; not a filesystem transaction",
                "sources_checked": len(checked), "all_sources_verified": False,
                "verification_checks": metadata["verification_checks"],
                "duration_seconds": round(time.perf_counter() - started, 6)}
        if len(encoded(response)) > ranking["max_response_bytes"]:
            raise RetrievalError("response byte bound exceeded; reduce top-k or narrow filters")
        return response
    finally:
        connection.close()
