"""Bounded text chunks with exact character offsets; no AST claims or execution."""
from __future__ import annotations

import bisect
import hashlib
import re
import unicodedata
from pathlib import PurePosixPath

EXTRACTION_VERSION = "bounded-lines/3"
NORMALIZATION_VERSION = "unicode-persian/1"
CONTRACT_MAX_CHARS = 16384
CONTRACT_MAX_LINES = 128


def contract_sections(text: str, source: dict) -> list[tuple[int, int]]:
    """Explicit complete Markdown sections only; invalid/stale selections fail closed."""
    sections = source.get('contract_sections', [])
    if not isinstance(sections, list):
        raise ValueError('contract_sections must be a list')
    lines = text.splitlines(keepends=True)
    result = []
    previous = 0
    for interval in sections:
        if not isinstance(interval, list) or len(interval) != 2:
            raise ValueError('invalid contract section interval')
        first, last = interval
        start, stop = line_range(text, first, last)
        if (PurePosixPath(source['path']).suffix.casefold() != '.md' or first <= previous
                or not any(a <= first <= last <= b for a, b in source['ranges'])):
            raise ValueError('contract sections must be ordered, disjoint and enrolled Markdown')
        heading = re.match(r'^ {0,3}(#{1,6})\s+\S', lines[first - 1])
        if not heading:
            raise ValueError('contract section must start at its heading')
        level = len(heading[1])
        next_heading = next((i + 1 for i in range(first, len(lines))
            if (m := re.match(r'^ {0,3}(#{1,6})\s+\S', lines[i])) and len(m[1]) <= level), len(lines) + 1)
        if last != next_heading - 1:
            raise ValueError('contract section must include all text through the next peer heading')
        if stop - start > CONTRACT_MAX_CHARS or last - first + 1 > CONTRACT_MAX_LINES:
            raise ValueError('complete contract exceeds bounded section size; explicit editorial review required')
        result.append((start, stop));previous = last
    return result


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
    contracts = contract_sections(text, source)
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
            contract = next(((a, b) for a, b in contracts if a <= start < b), None)
            section_stop = contract[1] if contract else min([a for a, b in contracts if start < a < stop], default=stop)
            hard_stop = min(section_stop, start + max_chars, offsets[min(first_index + max_lines, len(offsets) - 1)] if first_index + max_lines < len(offsets) else section_stop)
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
                               "method": method,
                               "method_limits": "Heuristic boundaries, not AST parsing; oversized paragraphs/tables/functions use bounded line/character windows. Enclosing context may be incomplete.",
                               "extraction_version": EXTRACTION_VERSION, "normalization_version": NORMALIZATION_VERSION,
                               "source": source})
                if contract:
                    a,b=contract
                    first_line=bisect.bisect_right(offsets,a)-1
                    last_line=bisect.bisect_right(offsets,b-1)-1
                    original_section=text[a:b]
                    result[-1]['contract']={
                        'chunk_id':hashlib.sha256(f"contract\0{source['path']}\0{source['sha256']}\0{a}:{b}\0{EXTRACTION_VERSION}".encode()).hexdigest(),
                        'locator':{'start_line':first_line+1,'end_line':last_line+1,'start_column':1,
                                   'end_column_exclusive':b-offsets[last_line]+1,'start_offset':a,'end_offset':b},
                        'context':contexts[first_line], 'original_text':original_section,
                        'text_group':hashlib.sha256(normalize(original_section).encode()).hexdigest()}
            if end == stop:
                break
            if end == section_stop:
                start = end
                continue
            # Overlap full lines only when it advances; huge single lines use char windows.
            end_line = bisect.bisect_left(offsets, end)
            overlap_index = max(first_index + 1, end_line - settings["overlap_lines"])
            next_start = offsets[overlap_index] if overlap_index < len(offsets) else end
            start = next_start if start < next_start < end else end
    return result
