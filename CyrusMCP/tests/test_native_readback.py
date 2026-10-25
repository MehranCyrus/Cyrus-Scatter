"""Regression for the real native count/non-iterability boundary found in Max 2027."""
from types import SimpleNamespace

import pytest

from cyrus_mcp.contracts import Fault, require
from test_operation_integrity import production_method


class NativeBuffer:
    def __init__(self, count):
        self.count = count

    def __len__(self):
        return self.count

    def __iter__(self):
        return iter(())  # The observed pymxs behavior; direct iteration silently skips work.

    def __getitem__(self, index):
        raise AssertionError("Native storage must be accessed through its paging API")


def reader(count, short=False):
    calls = []
    rows = NativeBuffer(count)

    def page(value, token, offset, size):
        assert value is rows and token == "immutable_token"
        calls.append((offset, size))
        return list(range(offset, offset+size-(1 if short else 0)))

    runtime = SimpleNamespace(cyrusPlacementIsNative=lambda value: isinstance(value, NativeBuffer),
                              cyrusPlacementToken=lambda value: "immutable_token", cyrusPlacementPage=page,
                              classOf=lambda value: "Array")
    method = production_method("placement_rows", {"rt": runtime, "require": require})
    host = SimpleNamespace(assert_main=lambda: None)
    return method, host, rows, calls


@pytest.mark.parametrize("count", [0, 1, 500, 501, 2000])
def test_readback_visits_every_native_row_in_bounded_pages(count):
    method, host, rows, calls = reader(count)
    assert list(method(host, rows)) == [(i, i) for i in range(count)]
    assert calls == [(offset, min(500, count-offset)) for offset in range(0, count, 500)]


def test_native_short_read_is_not_a_successful_partial_export():
    method, host, rows, calls = reader(10, short=True)
    with pytest.raises(Fault) as error:
        list(method(host, rows))
    assert error.value.code == "GENERATION_FAILED" and calls == [(0, 10)]


def test_readback_rejects_work_above_the_enrolled_budget():
    method, host, rows, calls = reader(2001)
    with pytest.raises(Fault) as error:
        list(method(host, rows))
    assert error.value.code == "BUDGET_EXCEEDED" and not calls


def test_empty_or_materialized_script_arrays_are_indexed_safely():
    method, host, _, calls = reader(0)
    assert list(method(host, [])) == []
    assert list(method(host, ["first", "second"])) == [(0, "first"), (1, "second")]
    assert not calls


@pytest.mark.parametrize("changed", ["publication", "generation", "missing_owner", "created_node", "authored"])
def test_rollback_requires_the_previous_native_publication_and_authored_state(changed):
    runtime = SimpleNamespace(isValidNode=lambda node: node == "live")
    method = production_method("rollback_matches", {"rt": runtime})
    host = SimpleNamespace(fingerprint=lambda: "before", controllers={"owner": "root"},
                           publication_identity=lambda node: "old_frame_and_generation")
    created = ["deleted"]
    assert method(host, "before", {"owner": "old_frame_and_generation"}, created)
    if changed in ("publication", "generation"):
        host.publication_identity = lambda node: "changed_"+changed
    elif changed == "missing_owner":
        host.controllers.clear()
    elif changed == "created_node":
        created.append("live")
    else:
        host.fingerprint = lambda: "changed"
    assert not method(host, "before", {"owner": "old_frame_and_generation"}, created)
