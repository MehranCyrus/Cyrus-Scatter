"""Versioned local response envelopes and actionable error categories."""
import argparse
import json

SEARCH_SCHEMA = "cyrus.search-response/2"
STATUS_SCHEMA = "cyrus.index-status/2"


class ContractParser(argparse.ArgumentParser):
    def __init__(self, *args, response_schema=SEARCH_SCHEMA, **kwargs):
        super().__init__(*args, **kwargs)
        self.response_schema = response_schema

    def error(self, message):
        print(json.dumps(error_response(RetrievalError(message), self.response_schema), ensure_ascii=False))
        raise SystemExit(2)


class RetrievalError(ValueError):
    error_type = "invalid_input"
    exit_code = 2
    rebuild_required = False

    def __init__(self, message, **details):
        super().__init__(message)
        self.details = details


class StaleIndex(RetrievalError):
    error_type = "stale_evidence"
    exit_code = 3
    rebuild_required = True


class SourceProblem(StaleIndex):
    def __init__(self, path, status, message):
        super().__init__(f"{status} source {path}: {message}; review evidence and rebuild", path=path, source_status=status)


class IncompatibleIndex(RetrievalError):
    error_type = "incompatible_index"
    rebuild_required = True


class IntegrityError(RetrievalError):
    error_type = "integrity_failure"
    exit_code = 3
    rebuild_required = True


class IndexIOError(RetrievalError):
    error_type = "io_failure"
    exit_code = 3


def error_response(exc, schema=SEARCH_SCHEMA, **request):
    if isinstance(exc, RetrievalError):
        kind, code, rebuild, details = exc.error_type, exc.exit_code, exc.rebuild_required, exc.details
    elif isinstance(exc, OSError):
        kind, code, rebuild, details = "io_failure", 3, False, {}
    else:
        kind, code, rebuild, details = "invalid_input", 2, False, {}
    response = {"schema": schema, "ok": False, "error": str(exc), "error_type": kind,
                "error_details": details, "exit_code": code, "rebuild_required": rebuild,
                "action": "Review changed definitions/evidence and build a fresh compatible generation; retain the prior generation." if rebuild else "Correct the input or restore read access, then retry explicitly.",
                "stale": isinstance(exc, StaleIndex), "results": [], **request}
    return response
