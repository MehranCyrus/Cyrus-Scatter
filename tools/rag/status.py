"""Inspect one explicit generation without refreshing, enrolling or modifying evidence."""
import argparse
import sys
from pathlib import Path

from contracts import STATUS_SCHEMA, ContractParser, RetrievalError, SourceProblem, error_response
from retrieval import (INDEX_SCHEMA, TOOL, encoded, load_config, open_index,
                       ranking_config, read_source, settings)
from provenance import compact_identities


def index_status(index, verify_sources=False, expected_root=None):
    if type(verify_sources) is not bool:
        raise RetrievalError("verify_sources must be Boolean")
    connection, metadata = open_index(Path(index), expected_root, verify_searchable=True)
    connection.close()
    identities = metadata["identities"]
    issues, verified, attempted = [], 0, 0
    if verify_sources:
        policy, bounds = load_config(TOOL / "config.toml"), settings()
        for source in metadata["sources"]:
            attempted += 1
            try:
                read_source(Path(identities["root"]), source["path"], source["sha256"], policy, bounds["max_source_bytes"])
                verified += 1
            except SourceProblem as exc:
                issues.append({**exc.details, "error": str(exc)})
    response = {"schema": STATUS_SCHEMA, "ok": not issues, "exit_code": 3 if issues else 0,
            "index_schema": INDEX_SCHEMA, "index_generation": metadata["generation_id"],
            "configuration_identities": compact_identities(metadata), "compatible": True,
            "corpus_scope": {**metadata["verified_counts"],
                             "paths": [s["path"] for s in metadata["sources"]],
                             "limits": "Explicit reviewed enrollment only; not the whole repository"},
            "verification_checks": metadata["verification_checks"],
            "source_verification_requested": verify_sources, "sources_checked": attempted,
            "sources_verified": verified, "all_sources_verified": verify_sources and not issues,
            "source_issues": issues, "stale": bool(issues), "rebuild_required": bool(issues),
            "error_type": "stale_evidence" if issues else None,
            "action": "Review source issues and publish a fresh compatible successor; retain this generation." if issues else None,
            "freshness_scope": "All enrolled parents individually rehashed; no filesystem transaction" if verify_sources else "Generation artifacts and definitions only; parent contents not checked"}
    if len(encoded(response)) > ranking_config()["max_response_bytes"]:
        raise RetrievalError("status response byte bound exceeded")
    return response


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = ContractParser(description=__doc__, response_schema=STATUS_SCHEMA)
    parser.add_argument("--index", type=Path, required=True)
    parser.add_argument("--root", type=Path, help="require this explicit repository/worktree identity")
    parser.add_argument("--verify-sources", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        response = index_status(args.index, args.verify_sources, args.root)
    except (OSError, ValueError) as exc:
        response = error_response(exc, STATUS_SCHEMA, compatible=False,
                                  source_verification_requested=args.verify_sources,
                                  sources_checked=0, sources_verified=0, all_sources_verified=False,
                                  verification_checks=getattr(exc, "details", {}).get("checks_performed", {}))
    if args.json:
        print(encoded(response).decode("utf-8"), end="")
    else:
        print(f"Index status: {'OK' if response['ok'] else 'FAILED'} | {response.get('index_generation', 'unverified generation')}")
        print(f"Checks: {response['verification_checks']}")
        print(f"Enrolled parents checked: {response['sources_checked']} | fully verified: {response['all_sources_verified']}")
        for issue in response.get("source_issues", []):
            print(issue["error"])
        if response.get("error"):
            print(response["error"])
    return response["exit_code"]


if __name__ == "__main__":
    raise SystemExit(main())
