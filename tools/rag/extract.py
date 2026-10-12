"""Bounded text chunks with exact character offsets; no AST claims or execution."""
from __future__ import annotations

import bisect
import hashlib
import re
import unicodedata
from pathlib import PurePosixPath

EXTRACTION_VERSION = "bounded-lines/1"
NORMALIZATION_VERSION = "unicode-persian/1"


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKC", text).translate(str.maketrans({"ي": "ی", "ى": "ی", "ك": "ک", "\u200c": " ", "\u200d": " ", "\ufeff": " "}))
    return " ".join(text.casefold().split())


def line_offsets(text: str) -> list[int]:
    return [0] + [m.end() for m in re.finditer("\n", text)]


def line_range(text: str, start: int, end: int) -> tuple[int, int]:
    offsets = line_offsets(text)
    count = len(text.splitlines())
    if type(start) is not int or type(end) is not int or not 1 <= start <= end <= count:
        raise ValueError(f"invalid line range {start}:{end} for {count} lines")
    return offsets[start - 1], offsets[end] if end < len(offsets) else len(text)


def chunks(text: str, source: dict, settings: dict) -> list[dict]:
    offsets = line_offsets(text)
    lines = text.splitlines(keepends=True)
    suffix = PurePosixPath(source["path"]).suffix.casefold()
    prose = suffix in (".md", ".txt")
    structured = suffix in (".json", ".csv", ".toml")
    method = "heading-paragraph" if prose else "structured-line-window" if structured else "declaration-line-window"
    contexts = []
    context = ""
    boundaries = {0, len(text)}
    for index, line in enumerate(lines):
        if prose:
            match = re.match(r"^\s{0,3}(#{1,6})\s+(.+)", line)
            if match:
                context = match[2].strip()
                boundaries.add(offsets[index])
            elif not line.strip():
                boundaries.add(offsets[index] + len(line))
        elif not structured:
            match = re.match(r"\s*(?:(?:async\s+)?def|class|fn|function|struct|namespace)\s+([\w:]+)", line)
            if match:
                context = match[1]
                boundaries.add(offsets[index])
        contexts.append(context)
    result = []
    max_chars, max_lines = settings["max_chunk_chars"], settings["max_chunk_lines"]
    for first, last in source["ranges"]:
        start, stop = line_range(text, first, last)
        while start < stop:
            first_index = bisect.bisect_right(offsets, start) - 1
            hard_stop = min(stop, start + max_chars, offsets[min(first_index + max_lines, len(offsets) - 1)] if first_index + max_lines < len(offsets) else stop)
            if hard_stop <= start:
                hard_stop = min(stop, start + max_chars)
            # Prefer complete paragraphs/declarations; fall back to full lines.
            preferred = [p for p in boundaries if start < p <= hard_stop]
            line_ends = [p for p in offsets if start < p <= hard_stop]
            end = max(preferred) if preferred else max(line_ends) if line_ends else hard_stop
            if hard_stop == stop:
                end = stop
            original = text[start:end]
            if original.strip():
                end_index = bisect.bisect_right(offsets, max(start, end - 1)) - 1
                locator = {"start_line": first_index + 1, "end_line": end_index + 1,
                           "start_column": start - offsets[first_index] + 1,
                           "end_column_exclusive": end - offsets[end_index] + 1,
                           "start_offset": start, "end_offset": end}
                identity = f"{source['path']}\0{source['sha256']}\0{start}:{end}\0{EXTRACTION_VERSION}\0{NORMALIZATION_VERSION}"
                result.append({"chunk_id": hashlib.sha256(identity.encode()).hexdigest(),
                               "path": source["path"], "parent_sha256": source["sha256"],
                               "locator": locator, "context": contexts[first_index] if first_index < len(contexts) else "",
                               "original_text": original, "search_text": normalize(original),
                               "text_group": hashlib.sha256(normalize(original).encode()).hexdigest(),
                               "method": method, "method_limits": "Heuristic boundaries, not AST parsing; oversized paragraphs/tables/functions use bounded line/character windows. Enclosing context may be incomplete.",
                               "extraction_version": EXTRACTION_VERSION, "normalization_version": NORMALIZATION_VERSION,
                               "source": source})
            if end == stop:
                break
            # Overlap full lines only when it advances; huge single lines use char windows.
            end_line = bisect.bisect_left(offsets, end)
            overlap_index = max(first_index + 1, end_line - settings["overlap_lines"])
            next_start = offsets[overlap_index] if overlap_index < len(offsets) else end
            start = next_start if start < next_start < end else end
    return result
