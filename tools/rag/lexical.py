"""Bounded one-hop terminology hints; no labels, path mappings or recursive expansion."""
import json
import re
from pathlib import Path

from extract import normalize

GLOSSARY = Path(__file__).resolve().parent / "glossary-v1.json"
PROFILES = ("plain", "terminology")


def load_glossary():
    glossary = json.loads(GLOSSARY.read_text(encoding="utf-8"))
    if (glossary.get("schema") != "cyrus.terminology/1"
            or not 1 <= glossary["max_applied_entries"] <= 8
            or not 1 <= glossary["max_added_terms"] <= 16
            or not 1 <= len(glossary["entries"]) <= 32):
        raise ValueError("invalid bounded terminology configuration")
    concepts = set()
    for entry in glossary["entries"]:
        if entry["concept"] in concepts or not entry["aliases"] or not entry["terms"]:
            raise ValueError("duplicate or empty terminology entry")
        concepts.add(entry["concept"])
        if len(entry["aliases"]) > 8 or len(entry["terms"]) > 8:
            raise ValueError("terminology entry exceeds bounds")
        for alias in entry["aliases"]:
            if not re.fullmatch(r"[^\W\d_]+(?: [^\W\d_]+)*", normalize(alias)):
                raise ValueError("aliases must be literal words/phrases, not identifiers or versions")
        if any(not re.fullmatch(r"[^\W\d_]+", normalize(t)) for t in entry["terms"]):
            raise ValueError("expansions must be literal words")
    return glossary


def compile_query(query, mode, advanced, profile, max_terms):
    if profile not in PROFILES:
        raise ValueError("unsupported lexical profile")
    normalized = normalize(query)
    original = list(dict.fromkeys(re.findall(r"\w+", normalized)))
    if len(original) > max_terms:
        raise ValueError("query term bound exceeded")
    terms = list(original)
    applied = []
    bounded = False
    if mode == "keyword" and not advanced and profile != "plain":
        glossary = load_glossary()
        for entry in glossary["entries"]:
            alias = next((a for a in entry["aliases"] if re.search(
                r"(?<![\w./\\:-])" + re.escape(normalize(a)) + r"(?![\w./\\:-])", normalized)), None)
            if alias is None:
                continue
            if len(applied) == glossary["max_applied_entries"]:
                bounded = True
                break
            added = []
            for word in entry["terms"]:
                word = normalize(word)
                if word not in terms:
                    if len(terms) == max_terms or len(terms) - len(original) == glossary["max_added_terms"]:
                        bounded = True
                        break
                    terms.append(word)
                    added.append(word)
            applied.append({"concept": entry["concept"], "matched_alias": alias, "added_terms": added})
    expression = None if mode != "keyword" else query if advanced else " OR ".join('"' + t + '"' for t in terms)
    return {"normalized_query": normalized, "original_terms": original, "search_terms": terms,
            "applied_expansions": applied, "expansion_bound_reached": bounded,
            "glossary_bypassed": mode != "keyword" or advanced or profile == "plain",
            "fts_expression": expression, "profile": profile}
