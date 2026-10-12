"""Bounded read-only verification of owned generation exports and searchable SQLite."""
import hashlib
import json
import os
import sqlite3
import stat
from pathlib import Path

import catalog
from contracts import IncompatibleIndex, IndexIOError, IntegrityError, RetrievalError, StaleIndex
from extract import EXTRACTION_VERSION, NORMALIZATION_VERSION, normalize
from locations import corpus_location

INDEX_SCHEMA = "cyrus.lexical-index/2"


def artifact_bytes(path, limit):
    path = Path(os.path.abspath(path))
    try:
        for ancestor in [*reversed(path.parents), path]:
            if catalog.is_link(ancestor.lstat()):
                raise IntegrityError(f"generation artifact ancestor is a link/reparse point: {ancestor}")
        before = path.lstat()
        if not stat.S_ISREG(before.st_mode) or before.st_size > limit:
            raise IntegrityError(f"generation artifact is not a bounded regular file: {path}")
        flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
        with os.fdopen(os.open(path, flags), "rb") as handle:
            if catalog.identity(before) != catalog.identity(os.fstat(handle.fileno())):
                raise IntegrityError("generation artifact changed before reading")
            raw = handle.read(limit + 1)
            after = os.fstat(handle.fileno())
        if len(raw) > limit or catalog.identity(before) != catalog.identity(after) or catalog.identity(before) != catalog.identity(path.lstat()):
            raise IntegrityError("generation artifact changed during reading")
        return raw
    except OSError as exc:
        raise IndexIOError(f"cannot read generation input {path}: {exc}", path=str(path)) from exc


def parsed(raw):
    try:
        return json.loads(raw)
    except (ValueError, UnicodeError) as exc:
        raise IntegrityError("invalid generation JSON") from exc


def verify_generation(path, runtime, bounds, ranking, expected_root=None, verify_searchable=False):
    checks = {}
    connection = None
    try:
        if path.name.startswith("."):
            raise IntegrityError("partial generations cannot be searched")
        limit = ranking["max_artifact_bytes"]
        run = parsed(artifact_bytes(path / "run.json", limit))
        if run.get("schema") != INDEX_SCHEMA:
            raise IncompatibleIndex("index/schema incompatibility; rebuild for lexical-index/2")
        if not run.get("complete") or (path / "failure.json").exists():
            raise IntegrityError("only complete published generations are readable")
        checks["complete_generation_metadata"] = True
        raw_logical = artifact_bytes(path / "logical.json", limit)
        logical = parsed(raw_logical)
        if hashlib.sha256(raw_logical).hexdigest() != run["generation_id"] or logical["schema"] != INDEX_SCHEMA:
            raise IntegrityError("logical generation fingerprint mismatch")
        if logical["identities"] != run["identities"] or len(logical["sources"]) != run["source_count"] or len(logical["chunks"]) != run["chunk_count"]:
            raise IntegrityError("run metadata disagrees with logical export")
        if not 0 < run["source_count"] <= bounds["max_sources"] or not 0 < run["chunk_count"] <= bounds["max_chunks"]:
            raise IntegrityError("generation exceeds configured corpus/chunk bounds")
        checks["logical_generation_fingerprint"] = True
        identities = logical["identities"]
        if (identities.get("normalization_version") != NORMALIZATION_VERSION
                or identities.get("extraction_version") != EXTRACTION_VERSION
                or identities["settings"] != bounds or identities["runtime_sha256"] != runtime
                or identities["ranking"] != ranking):
            raise IncompatibleIndex("index/configuration/tool incompatibility; rebuild index")
        root = Path(identities["root"])
        if expected_root is not None and Path(expected_root).resolve() != root.resolve():
            raise IncompatibleIndex("index belongs to a different explicitly selected repository/worktree")
        checks["runtime_configuration_and_repository"] = True
        corpus_path = Path(identities["corpus_path"])
        if not corpus_path.is_absolute() or not corpus_path.is_relative_to(root):
            raise IntegrityError("corpus definition is outside the declared repository")
        try:
            try:
                corpus_path = corpus_location(root, corpus_path)
            except RetrievalError as exc:
                raise IntegrityError(str(exc)) from exc
            corpus_raw = artifact_bytes(corpus_path, limit)
        except (IndexIOError, OSError) as exc:
            raise StaleIndex("corpus definition missing or inaccessible; restore reviewed definition and rebuild",
                             source_status="definition_unavailable") from exc
        if hashlib.sha256(corpus_raw).hexdigest() != identities["corpus_sha256"]:
            raise StaleIndex("corpus definition changed; review labels and rebuild", source_status="definition_changed")
        if parsed(corpus_raw)["sources"] != logical["sources"]:
            raise IntegrityError("enrolled metadata differs from corpus definition")
        checks["corpus_definition_identity"] = True
        # Schema is checked before byte hashes for a useful incompatibility diagnostic.
        db = path / "index.sqlite3"
        db_bytes = artifact_bytes(db, limit)
        connection = sqlite3.connect(db.absolute().as_uri() + "?mode=ro", uri=True)
        connection.execute("PRAGMA query_only=ON")
        rows = connection.execute("SELECT value FROM metadata").fetchall()
        if len(rows) != 1:
            raise IntegrityError("one SQLite metadata record is required")
        metadata = parsed(rows[0][0])
        if metadata.get("schema") != INDEX_SCHEMA:
            raise IncompatibleIndex("SQLite metadata schema incompatibility; rebuild index")
        if metadata != {"schema": INDEX_SCHEMA, "generation_id": run["generation_id"], "identities": identities, "sources": logical["sources"]}:
            raise IntegrityError("SQLite metadata disagrees with generation export")
        checks["sqlite_metadata_identity"] = True
        hashes = run["artifact_sha256"]
        if set(hashes) != {"logical.json", "chunks.jsonl", "index.sqlite3"}:
            raise IntegrityError("unexpected artifact fingerprint set")
        raw_chunks = artifact_bytes(path / "chunks.jsonl", limit)
        for name, raw in (("logical.json", raw_logical), ("chunks.jsonl", raw_chunks), ("index.sqlite3", db_bytes)):
            if hashlib.sha256(raw).hexdigest() != hashes[name]:
                raise IntegrityError(f"artifact fingerprint mismatch: {name}; indexed text/locator cannot be trusted")
        if len(db_bytes) != run["database_bytes"]:
            raise IntegrityError("SQLite size differs from publication receipt")
        if [parsed(line) for line in raw_chunks.splitlines()] != logical["chunks"]:
            raise IntegrityError("chunk export differs from logical generation")
        checks["all_artifact_fingerprints_and_chunk_export"] = True
        if connection.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
            raise IntegrityError("SQLite quick_check failed")
        if any(connection.execute(f"SELECT count(*) FROM {table}").fetchone()[0] != run["chunk_count"] for table in ("chunks", "search_chunks")):
            raise IntegrityError("searchable row counts disagree with generation")
        checks["sqlite_quick_check_and_counts"] = True
        if verify_searchable:
            actual = connection.execute("SELECT id,path,component,role,status,data FROM chunks ORDER BY id").fetchall()
            fts = connection.execute("SELECT rowid,text,context,path FROM search_chunks ORDER BY rowid").fetchall()
            for n, record in enumerate(logical["chunks"], 1):
                source = record["source"]
                row = actual[n-1]
                if row[:5] != (n, source["path"], source["component"], source["role"], source["knowledge_status"]) or parsed(row[5]) != record:
                    raise IntegrityError("searchable chunk rows disagree with export")
                if fts[n-1] != (n, record["search_text"], normalize(record["context"]), normalize(record["path"])):
                    raise IntegrityError("searchable FTS rows disagree with export")
            checks["all_searchable_rows_against_export"] = True
        metadata["verification_checks"] = checks
        metadata["verified_counts"] = {"source_count": run["source_count"], "chunk_count": run["chunk_count"]}
        return connection, metadata
    except RetrievalError as exc:
        if connection is not None:
            connection.close()
        exc.details["checks_performed"] = checks
        raise
    except (KeyError, IndexError, AttributeError, TypeError, ValueError, sqlite3.Error) as exc:
        if connection is not None:
            connection.close()
        raise IntegrityError(f"malformed or corrupted generation: {exc}", checks_performed=checks) from exc
