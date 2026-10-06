"""Bounded, plain-data diagnostic pages and explicit local report export.

This module has no Max, MCP transport or renderer dependency. Reading a page
cannot start recording; recording and sharing are separate local decisions.
"""
from copy import deepcopy
from pathlib import Path
import os
import tempfile

from .contracts import canonical, decode, fields, identifier, number, require, digest

PAGE_BYTES = 2_500_000  # Includes worst-case JSON escaping of 500 bounded UTF-8 events.
REPORT_BYTES = 16 * 1024 * 1024


def validate_page(raw, session_id, after=0, limit=100):
    identifier(session_id)
    number(after, 0, 2**53, True)
    number(limit, 1, 500, True)
    page = decode(raw.encode("utf-8") if isinstance(raw, str) else raw, PAGE_BYTES)
    fields(page, ("schema", "purpose", "session_id", "started_unix_ms", "elapsed_ms",
                  "active", "expired", "limits", "health", "oldest_sequence", "last_sequence",
                  "events", "next_sequence", "has_more", "training_eligible"))
    require(page["schema"] == "cyrus.diagnostic-page/1.0" and page["purpose"] == "engineering",
            "Unsupported diagnostic page")
    require(page["session_id"] == session_id, "Diagnostic session changed", "STALE_CONTEXT")
    require(page["training_eligible"] is False, "Diagnostics cannot grant training consent")
    for key in ("active", "expired", "has_more"):
        require(type(page[key]) is bool, "Invalid diagnostic state")
    for key in ("started_unix_ms", "elapsed_ms", "oldest_sequence", "last_sequence", "next_sequence"):
        number(page[key], 0, 2**53, True)
    fields(page["limits"], ("events", "bytes", "duration_ms"))
    number(page["limits"]["events"], 1, 16384, True)
    number(page["limits"]["bytes"], 2048, 4 * 1024 * 1024, True)
    number(page["limits"]["duration_ms"], 1, 600000, True)
    health = page["health"]
    fields(health, ("retained", "retained_bytes", "high_water_bytes", "evicted", "lock_drops", "failures", "truncated"))
    for value in health.values():
        number(value, 0, 2**53, True)
    require(health["retained"] <= page["limits"]["events"] and
            health["retained_bytes"] <= health["high_water_bytes"] <= page["limits"]["bytes"],
            "Diagnostic recorder exceeded its limits")
    require(after <= page["last_sequence"], "Cursor is ahead of this diagnostic session", "STALE_CONTEXT")
    require(type(page["events"]) is list and len(page["events"]) <= limit, "Oversized diagnostic page")
    previous, elapsed = after, 0
    for event in page["events"]:
        fields(event, ("sequence", "elapsed_ms", "epoch", "name", "origin", "owner_id", "detail"))
        number(event["sequence"], previous + 1, page["last_sequence"], True)
        number(event["elapsed_ms"], elapsed, page["elapsed_ms"], True)
        number(event["epoch"], 0, 2**53, True)
        for key, size in (("name", 64), ("origin", 32), ("owner_id", 96), ("detail", 512)):
            require(type(event[key]) is str and len(event[key].encode("utf-8")) <= size,
                    "Invalid diagnostic event field")
        previous, elapsed = event["sequence"], event["elapsed_ms"]
    require(page["next_sequence"] == previous and page["has_more"] == (previous < page["last_sequence"]),
            "Inconsistent diagnostic cursor")
    require(not page["has_more"] or bool(page["events"]), "Diagnostic page made no progress")
    return page


def collect_report(read_page, session_id, identity):
    """Collect a *stopped* session. Fail rather than silently mixing recordings."""
    pages, events, cursor, first = 0, [], 0, None
    while True:
        page = validate_page(read_page(cursor, 500), session_id, cursor, 500)
        require(not page["active"], "Stop recording before exporting a report", "HOST_BUSY")
        fixed = {key: page[key] for key in ("session_id", "started_unix_ms", "limits", "health", "last_sequence", "oldest_sequence")}
        if first is None:
            first = fixed
        require(fixed == first, "Diagnostic recording changed during export", "STALE_CONTEXT")
        pages += 1
        require(pages <= 33 and len(events) + len(page["events"]) <= 16384,
                "Report exceeded the bounded recorder", "BUDGET_EXCEEDED")
        events.extend(page["events"])
        cursor = page["next_sequence"]
        if not page["has_more"]:
            break
    require(len(events) == first["health"]["retained"], "Incomplete diagnostic report")
    if events:
        require(events[0]["sequence"] == first["oldest_sequence"] and
                all(b["sequence"] == a["sequence"] + 1 for a, b in zip(events, events[1:])),
                "Diagnostic report has missing retained events")
    manifest = {key: value for key, value in page.items() if key not in ("events", "next_sequence", "has_more")}
    report = {"schema": "cyrus.diagnostic-report/1.0", "recording": manifest,
              "build_identity": deepcopy(identity), "events": events, "events_sha256": digest(events),
              "training_eligible": False,
              "timing_semantics": "Monotonic callback-receipt times; not action latency, GPU time or presented FPS.",
              "complete_retained_history": True,
              "lossless": not any(first["health"][key] for key in ("evicted", "lock_drops", "failures", "truncated"))}
    require(len(canonical(report).encode("utf-8")) <= REPORT_BYTES, "Report exceeds 16 MiB", "BUDGET_EXCEEDED")
    return report


def save_report(path, report):
    """Atomic explicit export; no background logging, retention or upload."""
    data = canonical(report).encode("utf-8")
    require(len(data) <= REPORT_BYTES, "Report exceeds 16 MiB", "BUDGET_EXCEEDED")
    target = Path(path)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=target.parent, prefix=".cyrus-report-", suffix=".tmp", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
