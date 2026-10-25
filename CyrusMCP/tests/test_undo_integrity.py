"""Local Undo must preserve native-effect evidence and never repeat uncertainty."""
from types import SimpleNamespace

import pytest

from cyrus_mcp.contracts import Fault, canonical, require
from cyrus_mcp.service import Journal, Service
from test_operation_integrity import production_method, queue
from test_service import Host, service
from test_contracts import plan


def ready(service):
    queue(service)
    service.step()
    assert service.last_undo
    return service


def test_verified_undo_revokes_authority_and_has_durable_queryable_receipt(service):
    ready(service)
    epoch = service.epoch
    record = service.undo()["operation"]
    assert record["state"] == "succeeded" and record["effects"] == "committed"
    assert record["result"]["native_undo_verified"] and not record["recovery_required"]
    assert record["operation_kind"] == "undo" and record["target_identity"]["controller_id"] == "controller_1"
    assert service.epoch != epoch and service.scope is None and not service.owned
    assert not service.approved and service.last_undo is None and not service.recovery_required
    restarted = Service(Host(), Journal(service.journal.path))
    assert restarted.status(epoch, operation_id=record["operation_id"])["operation"] == record
    with pytest.raises(Fault):
        service.undo()


@pytest.mark.parametrize("failure", [RuntimeError("entered Undo"), Fault("UNDO_UNVERIFIED", "Restored state mismatch"), None])
def test_unwitnessed_undo_blocks_reentry_and_survives_reload(service, monkeypatch, failure):
    ready(service)
    entered = []

    def undo(_):
        entered.append(True)
        if failure:
            raise failure
        return None

    monkeypatch.setattr(service.host, "undo", undo)
    record = service.undo()["operation"]
    assert record["state"] == "outcome_unknown" and record["effects"] == "unknown"
    assert record["recovery_required"] and service.last_undo is None
    for candidate in (service, Service(Host(), Journal(service.journal.path))):
        with pytest.raises(Fault, match="reconciliation"):
            candidate.undo()
        with pytest.raises(Fault, match="reconciliation"):
            candidate.enroll(None, [], [])
    assert entered == [True]


def test_native_preflight_rejection_is_no_effect_and_can_be_reviewed(service, monkeypatch):
    ready(service)

    def reject(_):
        raise Fault("STALE_CONTEXT", "Another Undo item is first", effects="none")

    monkeypatch.setattr(service.host, "undo", reject)
    record = service.undo()["operation"]
    assert record["state"] == "failed" and record["effects"] == "none"
    assert not service.recovery_required and service.last_undo
    assert not Service(Host(), Journal(service.journal.path)).recovery_required


@pytest.mark.parametrize("invalid", [None, float("nan"), object()])
def test_known_undo_survives_presentation_or_receipt_failure(service, monkeypatch, invalid):
    ready(service)
    result = dict(native_undo_verified=True, controller_id="controller_1", generation_id="previous", configuration_id="old")
    if invalid is not None:
        result["malformed"] = invalid

    def undo(_):
        raise Fault("POST_COMMIT_FAILED", "Native restore verified; redraw failed", effects="committed", result=result)

    monkeypatch.setattr(service.host, "undo", undo)
    record = service.undo()["operation"]
    assert record["state"] == "failed" and record["effects"] == "committed"
    assert record["commit_identity"] == {key: result[key] for key in ("controller_id", "generation_id", "configuration_id")}
    assert ("result" in record) == (invalid is None)
    assert record["error"]["code"] == "POST_COMMIT_FAILED" and service.recovery_required
    assert canonical(record) and Service(Host(), Journal(service.journal.path)).recovery_required


@pytest.mark.parametrize("failed_save,entered", [(1, False), (2, False), (3, True), (4, True)])
def test_undo_storage_failures_do_not_erase_effects_or_reenter(service, monkeypatch, failed_save, entered):
    ready(service)
    save = service.journal.save
    calls = 0
    undo_calls = []

    def store():
        nonlocal calls
        calls += 1
        if calls == failed_save:
            raise OSError("Private journal failure")
        save()

    monkeypatch.setattr(service.journal, "save", store)
    monkeypatch.setattr(service.host, "undo", lambda _: undo_calls.append(True) or {"native_undo_verified": True})
    if entered:
        record = service.undo()["operation"]
    else:
        with pytest.raises(Fault) as error:
            service.undo()
        assert error.value.code == "JOURNAL_FAILED"
        record = list(service.journal.records.values())[-1]
    assert bool(undo_calls) == entered
    assert record["effects"] == ("committed" if entered else "none")
    assert record["state"] == "failed" and record["recovery_required"] and service.recovery_required
    with pytest.raises(Fault, match="reconciliation"):
        service.undo()


def test_pending_mutation_prevents_local_undo(service):
    ready(service)
    value = plan(service.context(service.scope["scope_id"])["context_id"])
    value.update(controller_id="controller_1", generation_id="generation_1")
    proposal = service.validate(value)
    service.approve(proposal["validation_id"])
    service.apply(proposal["validation_id"], proposal["digest"], proposal["scene_epoch"], proposal["scene_revision"], "next_key")
    count = len(service.journal.records)
    with pytest.raises(Fault, match="queued work"):
        service.undo()
    assert len(service.journal.records) == count


@pytest.mark.parametrize("case", ["busy", "wrong_top", "missing_witness", "verified", "mismatch", "native_fault", "presentation_fault"])
def test_native_adapter_checks_top_item_and_restored_witness(case):
    entered = []
    runtime = SimpleNamespace(theHold=SimpleNamespace(GetUndoNames=lambda: ["Other" if case == "wrong_top" else "Owned"]),
                              getUserProp=lambda node, key: "restored", redrawViews=lambda: None)

    def checkpoint(phase):
        if (case, phase) in (("native_fault", "undo_after_native"), ("presentation_fault", "undo_presentation")):
            raise RuntimeError("Private checkpoint failure")

    method = production_method("undo", {"rt": runtime, "pymxs": SimpleNamespace(run_undo=lambda: entered.append(True)),
                                       "Fault": Fault, "require": require})
    witness = dict(label="Owned", controllers={"owner": "old"}, masks={}, fingerprint="before", publications={}, created=[])
    host = SimpleNamespace(assert_main=lambda: None, busy=lambda: case == "busy", controllers={"owner": "current"},
                           undo_checkpoint=None if case == "missing_witness" else witness, checkpoint=checkpoint,
                           rollback_matches=lambda *_: case != "mismatch")
    if case == "verified":
        assert method(host, "Owned")["native_undo_verified"]
        assert host.undo_checkpoint is None and host.controllers == {}
    else:
        with pytest.raises((Fault, RuntimeError)) as error:
            method(host, "Owned")
        if case in ("busy", "wrong_top", "missing_witness"):
            assert error.value.details["effects"] == "none" and not entered
        elif case == "presentation_fault":
            assert error.value.details["effects"] == "committed" and error.value.details["result"]["native_undo_verified"]
        else:
            assert not isinstance(error.value, Fault) or "effects" not in error.value.details
    assert bool(entered) == (case not in ("busy", "wrong_top", "missing_witness"))
