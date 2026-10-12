"""Candidate-label validation and retrieval-only metrics; labels never enter FTS."""
from __future__ import annotations

import json
import math
import statistics
import time
from collections import Counter
from pathlib import Path

from extract import line_range
from retrieval import (RetrievalError, StaleIndex, TOOL, digest, encoded, load_config,
                       open_index, prepare_generation, ranking_config, read_source, search, settings, write_json)


def validate_labels(dataset: dict, sources: list[dict], texts: dict, require_full_set: bool = True) -> dict:
    if dataset.get("schema") != "cyrus.evaluation/1":
        raise RetrievalError("unsupported evaluation schema")
    questions, anchors = dataset["queries"], dataset.get("anchors", [])
    if require_full_set and dataset.get("dataset_kind") == "challenge":
        if not 1 <= len(questions) <= 40 or anchors or any(q["language"] != "en" for q in questions):
            raise RetrievalError("challenge must contain 1..40 English questions and no translated anchors")
    elif require_full_set:
        if (len(questions) != 40 or Counter(q["language"] for q in questions) != {"en": 16, "fa": 12, "finglish": 12}
                or Counter(q["category"] for q in questions) != {"workflow": 10, "ownership": 8, "history": 8, "boundary": 6, "website": 4, "contradiction": 4}
                or len(anchors) != 30 or len({q["base_id"] for q in anchors}) != 10):
            raise RetrievalError("evaluation category/language/anchor distribution is invalid")
        base = {q["id"]: q for q in questions}
        for base_id in {q["base_id"] for q in anchors}:
            variants = [q for q in anchors if q["base_id"] == base_id]
            if {q["language"] for q in variants} != {"en", "fa", "finglish"} or any(q["required_evidence"] != base[base_id]["required_evidence"] for q in variants):
                raise RetrievalError("anchor translations must preserve base evidence labels")
    entries = {s["path"]: s for s in sources}
    seen, validated = set(), 0
    for question in questions + anchors:
        if question["id"] in seen:
            raise RetrievalError("duplicate question ID")
        seen.add(question["id"])
        for field in ("language", "category", "query", "information_need", "required_qualifiers", "review_status", "split"):
            if not question.get(field):
                raise RetrievalError(f"missing evaluation field: {field}")
        if bool(question["required_evidence"]) != question["answerable"]:
            raise RetrievalError("answerable questions need evidence; unanswerable cases must not fabricate it")
        locations = [e for unit in question["required_evidence"] for e in unit["alternatives"]]
        locations += question.get("optional_evidence", [])
        locations += [n["evidence"] for n in question.get("misleading_substitutions", [])]
        for location in locations:
            path = location["path"]
            if path not in entries or location["sha256"] != entries[path]["sha256"]:
                raise RetrievalError(f"label has unknown source or mismatching hash: {path}")
            line_range(texts[path], location["start_line"], location["end_line"])
            if not any(a <= location["start_line"] <= location["end_line"] <= b for a, b in entries[path]["ranges"]):
                raise RetrievalError(f"label points outside enrolled ranges: {path}")
            validated += 1
    return {"questions": len(questions), "anchor_views": len(anchors), "hash_locators_validated": validated, "review_status": dataset["review_status"]}


def citations(result: dict) -> list[dict]:
    return [result, *result.get("equivalent_sources", [])]


def overlaps(citation: dict, location: dict, texts: dict) -> bool:
    if citation["path"] != location["path"] or citation["parent_sha256"] != location["sha256"]:
        return False
    start, end = line_range(texts[location["path"]], location["start_line"], location["end_line"])
    return citation["locator"]["start_offset"] < end and citation["locator"]["end_offset"] > start


def covered(location: dict, results: list[dict], texts: dict) -> bool:
    start, end = line_range(texts[location["path"]], location["start_line"], location["end_line"])
    intervals = sorted((c["locator"]["start_offset"], c["locator"]["end_offset"])
                       for r in results for c in citations(r) if overlaps(c, location, texts))
    through = start
    for a, b in intervals:
        if a > through:
            break
        through = max(through, b)
    return through >= end


def score_question(question: dict, results: list[dict], texts: dict) -> dict:
    units = question["required_evidence"]
    scores = {}
    expected = [e for unit in units for e in unit["alternatives"]] + question.get("optional_evidence", [])
    for k in (5, 10):
        ranked = results[:k]
        hits = [any(covered(e, ranked, texts) for e in unit["alternatives"]) for unit in units]
        relevant = sum(any(overlaps(c, e, texts) for c in citations(r) for e in expected) for r in ranked)
        bad = [{**n, "ranks": [i for i, r in enumerate(ranked, 1) if any(overlaps(c, n["evidence"], texts) for c in citations(r))]}
               for n in question.get("misleading_substitutions", [])
               if any(overlaps(c, n["evidence"], texts) for r in ranked for c in citations(r))]
        scores[str(k)] = {"unit_hits": hits, "required_units": len(units), "found_units": sum(hits),
                          "required_recall": sum(hits) / len(units) if units else None,
                          "all_required": all(hits) if units else None,
                          "source_precision": relevant / len(ranked) if ranked else 0.0,
                          "misleading_hits": bad, "returned_count": len(ranked)}
    canonical_rank = next((i for i, r in enumerate(results, 1)
                           if any(r["path"] in unit["canonical_paths"] and overlaps(r, e, texts)
                                  for unit in units for e in unit["alternatives"])), None)
    top_one = bool(results and any(overlaps(c, e, texts) for c in citations(results[0]) for e in expected))
    return {"at_k": scores, "canonical_rank": canonical_rank,
            "canonical_reciprocal_rank": 1 / canonical_rank if canonical_rank else 0.0,
            "top_one_relevant": top_one, "empty": not results}


def aggregate(questions: list[dict]) -> dict:
    answerable = [q for q in questions if q["answerable"]]
    result = {"questions": len(questions), "answerable": len(answerable), "unanswerable": len(questions) - len(answerable)}
    def mean(values):
        return statistics.mean(values) if values else None
    for k in (5, 10):
        values = [q["scores"]["at_k"][str(k)] for q in answerable]
        units = sum(v["required_units"] for v in values)
        negatives = [q for q in questions if q["misleading_substitutions"]]
        result[f"required_evidence_coverage_at_{k}"] = mean([v["required_recall"] for v in values])
        result[f"micro_required_recall_at_{k}"] = sum(v["found_units"] for v in values) / units if units else None
        result[f"complete_evidence_queries_at_{k}"] = mean([float(v["all_required"]) for v in values])
        result[f"complete_evidence_query_count_at_{k}"] = sum(bool(v["all_required"]) for v in values)
        result[f"required_unit_count_at_{k}"] = units
        result[f"found_required_unit_count_at_{k}"] = sum(v["found_units"] for v in values)
        result[f"answerable_returned_result_count_at_{k}"] = sum(v["returned_count"] for v in values)
        result[f"source_precision_at_{k}"] = mean([v["source_precision"] for v in values])
        result[f"labeled_misleading_query_rate_at_{k}"] = mean([float(bool(q["scores"]["at_k"][str(k)]["misleading_hits"])) for q in negatives])
        result[f"wrong_build_hits_at_{k}"] = sum(n["kind"] == "wrong_build" for q in questions for n in q["scores"]["at_k"][str(k)]["misleading_hits"])
        result[f"historical_current_hits_at_{k}"] = sum(n["kind"] == "historical_current" for q in questions for n in q["scores"]["at_k"][str(k)]["misleading_hits"])
    result.update(canonical_mrr=mean([q["scores"]["canonical_reciprocal_rank"] for q in answerable]),
                  top_one_relevant_rate=mean([float(q["scores"]["top_one_relevant"]) for q in answerable]),
                  answerable_empty_rate=mean([float(q["scores"]["empty"]) for q in answerable]),
                  unanswerable_nonempty_count=sum(not q["scores"]["empty"] for q in questions if not q["answerable"]),
                  answerable_empty_count=sum(q["scores"]["empty"] for q in answerable),
                  labeled_misleading_query_count=sum(bool(q["misleading_substitutions"]) for q in questions),
                  unanswerable_result_counts={q["id"]: q["scores"]["at_k"]["10"]["returned_count"] for q in questions if not q["answerable"]})
    return result


def run_evaluation(index: Path, dataset_path: Path, out: Path, profile: str | None = None) -> dict:
    started = time.perf_counter()
    out = out.absolute()
    connection, metadata = open_index(index)
    connection.close()
    root = Path(metadata["identities"]["root"])
    stage = prepare_generation(root, out, "evaluations")
    try:
        dataset_bytes = dataset_path.read_bytes()
        dataset = json.loads(dataset_bytes)
        bounds, policy = settings(), load_config(TOOL / "config.toml")
        texts = {s["path"]: read_source(root, s["path"], s["sha256"], policy, bounds["max_source_bytes"]) for s in metadata["sources"]}
        validation = validate_labels(dataset, metadata["sources"], texts)
        scored, timings = [], []
        for group, questions in (("base", dataset["queries"]), ("anchors", dataset["anchors"])):
            for question in questions:
                response = search(index, question["query"], top_k=10, mode=question.get("mode", "keyword"), profile=profile)
                timing = response.pop("duration_seconds")
                timings.append({"id": question["id"], "group": group, "seconds": timing})
                ranked = [{k: r[k] for k in ("rank", "chunk_id", "path", "parent_sha256", "locator", "context", "excerpt", "original_text", "source", "match", "equivalent_sources")} for r in response["results"]]
                scored.append({**question, "group": group, "ranked_results": ranked,
                               "query_diagnostics": response["diagnostics"],
                               "scores": score_question(question, response["results"], texts),
                               "resolved_source_qualifiers": {e["path"]: next(s["applicability"] for s in metadata["sources"] if s["path"] == e["path"])
                                                              for unit in question["required_evidence"] for e in unit["alternatives"]}})
        if dataset_path.read_bytes() != dataset_bytes:
            raise StaleIndex("evaluation labels changed during run")
        for s in metadata["sources"]:
            read_source(root, s["path"], s["sha256"], policy, bounds["max_source_bytes"])
        base = [q for q in scored if q["group"] == "base"]
        anchor_scores = [q for q in scored if q["group"] == "anchors"]
        metrics = {"base": aggregate(base), "anchors": aggregate(anchor_scores)}
        for field in ("language", "category", "split"):
            metrics["by_" + field] = {value: aggregate([q for q in base if q[field] == value]) for value in sorted({q[field] for q in base})}
        metrics["anchors_by_language"] = {lang: aggregate([q for q in anchor_scores if q["language"] == lang]) for lang in ("en", "fa", "finglish")}
        metrics["anchors_by_base_id"] = {id: {q["language"]: q["scores"]["at_k"]["10"]["required_recall"] for q in anchor_scores if q["base_id"] == id} for id in sorted({q["base_id"] for q in anchor_scores})}
        results = {"schema": "cyrus.retrieval-evaluation/2", "metric_definition_version": 1, "provisional": True,
                   "variant": profile or ranking_config()["default_profile"], "index_generation": metadata["generation_id"],
                   "configuration_identities": metadata["identities"],
                   "evaluation_sha256": digest(dataset_bytes), "validation": validation, "metrics": metrics, "questions": scored}
        write_json(stage / "results.json", results)
        write_json(stage / "labels-snapshot.json", dataset)
        seconds = sorted(t["seconds"] for t in timings)
        run = {"complete": True, "evaluation_sha256": digest(dataset_bytes), "index_generation": metadata["generation_id"],
               "index_path": str(index.resolve()), "results_sha256": digest(encoded(results)),
               "duration_seconds": round(time.perf_counter() - started, 6), "query_timings": timings,
               "median_query_seconds": statistics.median(seconds), "p95_query_seconds": seconds[math.ceil(.95 * len(seconds)) - 1],
               "measurement_conditions": "Sequential single-process queries; fresh read-only SQLite connection, bounded artifact fingerprints and quick_check per query; returned parents rehashed; OS cache generally warm; background activity uncontrolled; no answer generation"}
        write_json(stage / "run.json", run)
        if out.exists():
            raise RetrievalError("evaluation output appeared concurrently")
        stage.rename(out)
        return results
    except Exception as exc:
        write_json(stage / "failure.json", {"complete": False, "error": str(exc)})
        raise
