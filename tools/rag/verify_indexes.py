"""Compare logical index and evaluation exports, excluding volatile timing/SQLite bytes."""
import argparse
import json
from pathlib import Path

from retrieval import INDEX_SCHEMA, digest


def compare(first: Path, second: Path, eval_first: Path, eval_second: Path) -> dict:
    runs = [json.loads((p / "run.json").read_text(encoding="utf-8")) for p in (first, second)]
    evaluations = [json.loads((p / "run.json").read_text(encoding="utf-8")) for p in (eval_first, eval_second)]
    if any(r.get("schema") != INDEX_SCHEMA or not r.get("complete") for r in runs) or any(not r.get("complete") for r in evaluations):
        raise ValueError("compatible complete index and evaluation generations required")
    logical = [digest((p / "logical.json").read_bytes()) for p in (first, second)]
    chunks = [digest((p / "chunks.jsonl").read_bytes()) for p in (first, second)]
    results = [digest((p / "results.json").read_bytes()) for p in (eval_first, eval_second)]
    result = {"logical_index_identical": logical[0] == logical[1], "chunks_identical": chunks[0] == chunks[1],
              "ranked_results_and_metrics_identical": results[0] == results[1],
              "exports_match_recorded_identities": all(h == r["generation_id"] for h, r in zip(logical, runs)) and all(h == e["results_sha256"] for h, e in zip(results, evaluations)),
              "evaluation_matches_index": all(e["index_generation"] == r["generation_id"] for e, r in zip(evaluations, runs)),
              "logical_sha256": logical, "chunks_sha256": chunks, "evaluation_sha256": results,
              "volatile_exclusions": ["run.json durations", "query timings", "raw SQLite bytes"]}
    result["passed"] = all(result[k] for k in ("logical_index_identical", "chunks_identical", "ranked_results_and_metrics_identical", "exports_match_recorded_identities", "evaluation_matches_index"))
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("first", "second", "eval_first", "eval_second"):
        parser.add_argument(name, type=Path)
    args = parser.parse_args(argv)
    try:
        result = compare(args.first, args.second, args.eval_first, args.eval_second)
        print(json.dumps(result, indent=2))
        return 0 if result["passed"] else 3
    except (OSError, ValueError, KeyError) as exc:
        print(json.dumps({"error": str(exc)}))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
