"""Fail-closed, request-bound results for owned Max 2027 scenarios."""
from dataclasses import dataclass
from pathlib import Path
import hashlib
import json


@dataclass(frozen=True)
class Expected:
    run_id: str
    request_id: str
    scenario_id: str
    artifact_id: str
    assertions: tuple[str, ...]


class IncompleteResult(ValueError):
    pass


def read_result(path: Path, expected: Expected) -> dict:
    if not path.is_file() or path.stat().st_size > 1024 * 1024:
        raise IncompleteResult('Missing or oversized scenario result')
    try:
        result = json.loads(path.read_text(encoding='utf-8-sig'))
    except (OSError, ValueError) as error:
        raise IncompleteResult('Unreadable or truncated scenario result') from error
    if not isinstance(result, dict):
        raise IncompleteResult('Scenario result must be an object')
    for key in ('run_id', 'request_id', 'scenario_id', 'artifact_id'):
        if result.get(key) != getattr(expected, key):
            raise IncompleteResult('Scenario identity differs: ' + key)
    if result.get('schema') != 'cyrus.max-scenario/1' or result.get('terminal') != 'complete':
        raise IncompleteResult('Scenario did not complete')
    assertions = result.get('assertions')
    if not isinstance(assertions, list) or not expected.assertions:
        raise IncompleteResult('Missing assertion manifest')
    ids = [row.get('id') for row in assertions if isinstance(row, dict)]
    if len(ids) != len(assertions) or len(ids) != len(set(ids)) or set(ids) != set(expected.assertions):
        raise IncompleteResult('Missing, duplicated or unexpected assertions: ' + str(result.get('error', '')))
    if result.get('status') != 'pass' or any(row.get('status') != 'pass' for row in assertions):
        raise IncompleteResult('Scenario assertion failed: ' + str(result.get('error', '')))
    return result


def artifact_identity(paths: dict[str, Path]) -> tuple[str, dict[str, str]]:
    hashes = {name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in sorted(paths.items())}
    identity = hashlib.sha256(json.dumps(hashes, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    return identity, hashes
