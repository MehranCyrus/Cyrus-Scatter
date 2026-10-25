"""Local retirement preserves uncertainty; it is not a public permission reset."""
from copy import deepcopy
from types import SimpleNamespace

import pytest

from cyrus_mcp.contracts import Fault, digest, require
from cyrus_mcp.service import Journal, Service, needs_recovery
from test_operation_integrity import queue, production_method
from test_service import Host, apply, service


@pytest.fixture
def unresolved(service, monkeypatch):
    value = queue(service)

    def fail(*_):
        raise Fault("HOST_ERROR", "Unclassified host outcome")

    def snapshot(record, selected):
        return {"scope": "fixture selection only", "scene_revision": service.host.revision,
                "selected_controller": {"owner_id": "controller_1", "accepted_count": 99} if selected else None,
                "comparison": "Fixture cached evidence; no scene-wide proof"}

    monkeypatch.setattr(service.host, "generate", fail)
    monkeypatch.setattr(service.host, "recovery_snapshot", snapshot, raising=False)
    service.step()
    return service, value


def review(unresolved, selected=None):
    service, value = unresolved
    record = apply(service, value)["operation"]
    return service.prepare_local_recovery(record["operation_id"], selected or [])


def test_local_retirement_preserves_unknown_effects_and_requires_fresh_scope(unresolved):
    service, value = unresolved
    old_epoch = service.epoch
    prepared = review(unresolved)
    assert service.recovery_required
    result = service.confirm_local_recovery(prepared["review_id"], prepared["digest"])
    assert result["resolution"]["actor"] == "local_artist"
    assert result["resolution"]["original_effects"] == "unknown"
    assert not result["recovery_required"] and not service.recovery_required
    assert service.scope is None and not service.approved and service.epoch != old_epoch
    original = apply(service, value)["operation"]
    assert original["effects"] == "unknown" and original["state"] == "outcome_unknown"
    assert original["resolution"]["status"] == "locally_retired"
    assert service.host.generated == 0
    with pytest.raises(Fault):
        apply(service, value, "new_key")
    service.enroll(None, [], [])
    assert service.host.generated == 0


def test_retirement_is_durable_and_exact_key_remains_a_receipt(unresolved):
    service, value = unresolved
    prepared = review(unresolved)
    service.confirm_local_recovery(prepared["review_id"], prepared["digest"])
    restarted = Service(Host(), Journal(service.journal.path))
    assert not restarted.recovery_required
    assert apply(restarted, value)["operation"]["resolution"]["status"] == "locally_retired"
    restarted.enroll(None, [], [])
    assert restarted.host.generated == 0


@pytest.mark.parametrize("method", ["scatter.recover", "prepare_local_recovery", "confirm_local_recovery"])
def test_recovery_is_not_model_callable(unresolved, method):
    service, _ = unresolved
    with pytest.raises(Fault) as error:
        service.dispatch(method, {})
    assert error.value.code == "UNSUPPORTED_CAPABILITY" and service.recovery_required


@pytest.mark.parametrize("changed", ["scene", "record", "digest", "expiry", "reset"])
def test_changed_or_expired_review_cannot_clear_mutation_block(unresolved, changed):
    service, value = unresolved
    prepared = review(unresolved, ["native_reference"])
    if changed == "scene":
        service.host.revision += 1
    elif changed == "record":
        service.journal.records[prepared["operation_id"]]["error"]["message"] = "Changed record"
    elif changed == "digest":
        prepared["digest"] = "0" * 64
    elif changed == "expiry":
        service.recovery_reviews[prepared["review_id"]]["deadline"] = 0
    else:
        service.reset()
    with pytest.raises(Fault) as error:
        service.confirm_local_recovery(prepared["review_id"], prepared["digest"])
    assert error.value.code == "STALE_CONTEXT"
    assert service.recovery_required and apply(service, value)["operation"]["effects"] == "unknown"
    with pytest.raises(Fault):
        service.confirm_local_recovery(prepared["review_id"], prepared["digest"])


def test_storage_failure_during_confirmation_does_not_retire_operation(unresolved, monkeypatch):
    service, value = unresolved
    prepared = review(unresolved)
    save = service.journal.save

    def fail():
        raise OSError("Fixture storage unavailable")

    monkeypatch.setattr(service.journal, "save", fail)
    with pytest.raises(Fault) as error:
        service.confirm_local_recovery(prepared["review_id"], prepared["digest"])
    assert error.value.code == "JOURNAL_FAILED"
    record = apply(service, value)["operation"]
    assert record["resolution"]["status"] == "storage_failed" and needs_recovery(record)
    assert service.recovery_required
    assert Service(Host(), Journal(service.journal.path)).recovery_required
    monkeypatch.setattr(service.journal, "save", save)
    prepared = review(unresolved)
    service.confirm_local_recovery(prepared["review_id"], prepared["digest"])
    assert not service.recovery_required


def test_other_unresolved_records_remain_blocking(unresolved):
    service, value = unresolved
    other = deepcopy(apply(service, value)["operation"])
    other.update(operation_id="operation_other", idempotency_key="key_other")
    service.journal.records[other["operation_id"]] = other
    service.journal.save()
    prepared = review(unresolved)
    service.confirm_local_recovery(prepared["review_id"], prepared["digest"])
    assert service.recovery_required
    assert service.unresolved_operations() == [{key: other.get(key) for key in ("operation_id", "scene_epoch", "state", "effects", "persistence")}]
    assert service.connection()["unresolved_operations"][0]["operation_id"] == "operation_other"


def test_preparing_recovery_is_read_only_and_bounded(unresolved):
    service, value = unresolved
    before = deepcopy(service.journal.records)
    for _ in range(12):
        review(unresolved)
    assert len(service.recovery_reviews) == 8 and service.journal.records == before
    assert service.recovery_required and service.host.generated == 0
    with pytest.raises(Fault):
        service.prepare_local_recovery(apply(service, value)["operation"]["operation_id"], [1, 2])


def test_oversized_evidence_is_not_saved_or_approved(unresolved, monkeypatch):
    service, _ = unresolved
    monkeypatch.setattr(service.host, "recovery_snapshot", lambda *_: {"large": "x" * 8192})
    with pytest.raises(Fault) as error:
        review(unresolved)
    assert error.value.code == "BUDGET_EXCEEDED" and not service.recovery_reviews


def test_unknown_controller_and_pending_work_are_rejected(service):
    with pytest.raises(Fault):
        service.prepare_local_recovery("missing", [])
    queue(service)
    with pytest.raises(Fault) as error:
        service.prepare_local_recovery("missing", [])
    assert error.value.code == "HOST_BUSY"


def test_native_empty_selection_snapshot_is_passive_and_uses_physical_units():
    runtime = SimpleNamespace(maxFilePath="", maxFileName="", units=SimpleNamespace(decodeValue=lambda _: 100))
    snapshot = production_method("recovery_snapshot", {"rt": runtime, "require": require, "digest": digest})
    host = SimpleNamespace(assert_main=lambda: None, busy=lambda: False)
    evidence = snapshot(host, {"effects": "unknown"}, [])
    assert evidence["metres_per_unit"] == .01 and evidence["selected_controller"] is None
    assert "not verified" in evidence["comparison"]


def test_native_busy_snapshot_does_not_inspect_scene():
    from cyrus_mcp.contracts import require
    snapshot = production_method("recovery_snapshot", {"require": require})
    host = SimpleNamespace(assert_main=lambda: None, busy=lambda: True)
    with pytest.raises(Fault) as error:
        snapshot(host, {}, [])
    assert error.value.code == "HOST_BUSY"


@pytest.mark.parametrize("layers,sources", [(33, 0), (0, 1025)])
def test_recovery_admits_metadata_before_traversing_large_owners(layers, sources):
    runtime = SimpleNamespace(maxFilePath="", maxFileName="", units=SimpleNamespace(decodeValue=lambda _: 1),
                              isValidNode=lambda _: True)
    snapshot = production_method("recovery_snapshot", {"rt": runtime, "require": require, "digest": digest})
    host = SimpleNamespace(assert_main=lambda: None, busy=lambda: False)
    node = SimpleNamespace(calculationModel=lambda: "CyrusUnified2", layerObjects=[None]*layers, sources=[None]*sources)
    with pytest.raises(Fault) as error:
        snapshot(host, {}, [node])
    assert error.value.code == "BUDGET_EXCEEDED"


def test_recovery_host_reader_shares_aggregate_budget_and_uses_only_constant_source():
    from cyrus_mcp.recovery import HOST_READER, MAX_CELLS, MAX_TEXT_UNITS
    seen, budgets = [], []
    def compiled(owner, key, budget, mode):
        budgets.append(budget)
        if len(budgets) == 3:
            raise RuntimeError("Cyrus recovery budget exceeded")
        return "bounded"
    runtime = SimpleNamespace(execute=lambda source: seen.append(source) or compiled,
                              Array=lambda *items: list(items), Name=lambda key: key)
    read_method = production_method("recovery_reader", {"rt":runtime, "frozen":lambda v:v, "Fault":Fault,
                                                       "__name__":"cyrus_mcp.max_host", "__package__":"cyrus_mcp"})
    host = SimpleNamespace(assert_main=lambda:None)
    read = read_method(host)
    assert read(object(), "amount") == read(object(), "randomSeed") == "bounded"
    assert budgets[0] is budgets[1] and budgets[0] == [MAX_CELLS, MAX_TEXT_UNITS]
    with pytest.raises(Fault) as error:
        read(object(), "densityResponseSamples")
    assert error.value.code == "BUDGET_EXCEEDED"
    read_method(host)
    assert seen == [HOST_READER]  # No scene text, key or reference is interpolated into code.
