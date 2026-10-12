"""Build a fresh, bounded local FTS5 corpus generation."""
import argparse
import json
import sqlite3
import sys
from pathlib import Path

from retrieval import RetrievalError, StaleIndex, TOOL, build


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--corpus", type=Path, default=TOOL / "corpus.json")
    parser.add_argument("--audit", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        result = build(args.root, args.corpus, args.audit, args.out)
        print(json.dumps({k: result[k] for k in ("generation_id", "source_count", "chunk_count", "database_bytes", "duration_seconds")}))
        return 0
    except (OSError, ValueError, KeyError, sqlite3.Error) as exc:
        print(json.dumps({"error": str(exc), "rebuild_required": isinstance(exc, StaleIndex)}))
        return 3 if isinstance(exc, (StaleIndex, OSError)) else 2


if __name__ == "__main__":
    raise SystemExit(main())
