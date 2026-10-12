"""Validate frozen candidate labels and run provisional retrieval evaluation."""
import argparse
import json
import sqlite3
from pathlib import Path

from evaluation import run_evaluation
from contracts import error_response
from lexical import PROFILES
from retrieval import StaleIndex, TOOL


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index", type=Path, required=True)
    parser.add_argument("--questions", type=Path, default=TOOL / "evaluation.json")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--profile", choices=PROFILES)
    args = parser.parse_args(argv)
    try:
        results = run_evaluation(args.index, args.questions, args.out, args.profile)
        print(json.dumps({"provisional": True, "metrics": results["metrics"]}, indent=2))
        return 0
    except (OSError, ValueError, KeyError, sqlite3.Error) as exc:
        print(json.dumps({"error": str(exc)}))
        return 3 if isinstance(exc, (StaleIndex, OSError)) else 2


if __name__ == "__main__":
    raise SystemExit(main())
