"""Return checked local citations; never synthesize answers or execute sources."""
import argparse
import json
import sqlite3
import sys
from pathlib import Path

from contracts import ContractParser, error_response
from lexical import PROFILES
from retrieval import encoded, search


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = ContractParser(description=__doc__)
    parser.add_argument("--index", type=Path, required=True)
    parser.add_argument("--query", required=True)
    parser.add_argument("--mode", choices=("keyword", "identifier", "path"), default="keyword")
    parser.add_argument("--top-k", type=int, default=10)
    parser.add_argument("--component")
    parser.add_argument("--role")
    parser.add_argument("--status", choices=("current", "historical", "unknown", "archive"))
    parser.add_argument("--advanced", action="store_true", help="explicit raw FTS5 expression; syntax errors exit 2")
    parser.add_argument("--profile", choices=PROFILES, help="default: frozen terminology profile; plain preserves baseline ranking")
    parser.add_argument("--root", type=Path, help="require this explicit repository/worktree identity")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        filters = {k: v for k, v in {"component": args.component, "role": args.role, "knowledge_status": args.status}.items() if v is not None}
        response = search(args.index, args.query, args.top_k, args.mode, filters, args.advanced, args.profile, args.root)
        if args.json:
            print(encoded(response).decode("utf-8"), end="")
        else:
            print(f"Query: {args.query} | generation {response['index_generation']} | {len(response['results'])} results")
            print(f"Normalization/expansion: {response['diagnostics']}")
            print(f"Freshness: {response['freshness_scope']}")
            for n, result in enumerate(response["results"], 1):
                s, loc = result["source"], result["locator"]
                print(f"\n{n}. {s['path']}:{loc['start_line']}-{loc['end_line']} columns {loc['start_column']}:{loc['end_column_exclusive']}")
                print(f"   {s['knowledge_status']} | {s['role']} | {s['component']} | SHA-256 {s['sha256']}")
                print(f"   Snapshot: {s['applicability']['snapshot']} | Limits: {s['applicability']['limits']}")
                print(f"   Match: {result['match']} | {len(result['equivalent_sources'])} equivalent citations")
                print(result["original_text"])
            if not response["results"]:
                print("No results. This does not establish that the repository lacks an answer.")
        return 0
    except (OSError, ValueError, KeyError, sqlite3.Error) as exc:
        response = error_response(exc, query=args.query, mode=args.mode, advanced=args.advanced,
                                  filters=filters, top_k=args.top_k, profile=args.profile)
        print(encoded(response).decode("utf-8"), end="")
        return response["exit_code"]


if __name__ == "__main__":
    raise SystemExit(main())
