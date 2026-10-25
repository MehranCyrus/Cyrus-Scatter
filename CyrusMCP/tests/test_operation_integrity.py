"""Effect witnesses and durability faults execute the production coordinator."""
import ast
import json
from pathlib import Path
from types import SimpleNamespace

import pytest

from cyrus_mcp.contracts import Fault, digest, require
from cyrus_mcp.service import Journal, Service
from test_service import Host, apply, service, validated


def queue(service):
    value = validated(service)
    service.approve(value["validation_id"])
    apply(service, value)
    return value


def assert_replay_blocked(service, value):
    assert apply(service, value)["operation"]["recovery_required"]
    with pytest.raises(Fault, match="reconciliation"):
        apply(service, value, "another_key")
    service.reset()
    with pytest.raises(Fault, match="reconciliation"):
        service.enroll(None, [], [])


def test_commit_survives_fingerprint_failure_and_cannot_be_replayed(service, monkeypatch):
    value = queue(service)
    original = service.host.fingerprint

    def fingerprint():
        if service.host.generated:
            raise Fault("HOST_ERROR", "Post-commit inspection unavailable")
        return original()

    monkeypatch.setattr(service.host, "fingerprint", fingerprint)
    service.step()
    record = apply(service, value)["operation"]
    assert record["state"] == "failed"
    assert record["effects"] == "committed"
    assert record["error"]["code"] == "POST_COMMIT_FAILED"
    assert record["result"]["generation_id"] == "generation_1"
    assert service.owned["controller_1"] == record["result"]
    assert service.applications == 1 and service.last_undo is None
    assert service.scope["stale"] and not service.approved
    assert_replay_blocked(service, value)
    assert service.host.generated == 1


def test_commit_replaces_old_export_even_when_new_export_fails(service, monkeypatch):
    import cyrus_mcp.records

    value = queue(service)
    service.host.layouts = {"controller_1": {}}
    service.records["controller_1"] = {"old_generation": True}

    def fail(*_):
        raise Fault("BUDGET_EXCEEDED", "Export unavailable")

    monkeypatch.setattr(cyrus_mcp.records, "execution_record", fail)
    service.step()
    record = apply(service, value)["operation"]
    assert record["effects"] == "committed" and record["state"] == "failed"
    assert record["error"]["cause_code"] == "BUDGET_EXCEEDED"
    assert "controller_1" not in service.records
    assert service.status(service.epoch, controller_id="controller_1")["controller"]["generation_id"] == "generation_1"


@pytest.mark.parametrize("invalid", [float("nan"), object()])
def test_malformed_post_commit_receipt_keeps_json_safe_effect_evidence(service, monkeypatch, invalid):
    from cyrus_mcp.contracts import canonical

    value = queue(service)
    generate = service.host.generate

    def malformed(*args):
        return {**generate(*args), "configuration_id": "configuration_committed", "invalid": invalid}

    monkeypatch.setattr(service.host, "generate", malformed)
    service.step()
    record = apply(service, value)["operation"]
    assert record["effects"] == "committed" and record["state"] == "failed"
    assert record["commit_identity"] == {"controller_id": "controller_1", "generation_id": "generation_1", "configuration_id": "configuration_committed"}
    assert "result" not in record and service.applications == 1
    assert canonical(record)
    assert_replay_blocked(service, value)


def test_host_committed_fault_preserves_native_receipt(service, monkeypatch):
    value = queue(service)
    generate = service.host.generate

    def finalize_failed(*args):
        result = generate(*args)
        raise Fault("POST_COMMIT_FAILED", "Redraw failed", effects="committed", result=result)

    monkeypatch.setattr(service.host, "generate", finalize_failed)
    service.step()
    record = apply(service, value)["operation"]
    assert record["effects"] == "committed" and record["result"]["emitted"] == 99
    assert service.owned["controller_1"]["generation_id"] == "generation_1"
    assert service.applications == 1
    assert_replay_blocked(service, value)


@pytest.mark.parametrize("exception", [Fault("HOST_ERROR", "Unknown host state"), RuntimeError("Unknown host state")])
def test_throwing_host_without_a_witness_is_unknown(service, monkeypatch, exception):
    value = queue(service)

    def fail(*_):
        raise exception

    monkeypatch.setattr(service.host, "generate", fail)
    service.step()
    record = apply(service, value)["operation"]
    assert record["state"] == "outcome_unknown" and record["effects"] == "unknown"
    assert "result" not in record
    assert_replay_blocked(service, value)


@pytest.mark.parametrize("witness,effects", [({"effects": "none"}, "none"), ({"rollback": "verified"}, "verified_rollback")])
def test_explicit_no_change_or_rollback_witness_remains_recoverable(service, monkeypatch, witness, effects):
    value = queue(service)

    def fail(*_):
        raise Fault("GENERATION_FAILED", "Rejected safely", **witness)

    monkeypatch.setattr(service.host, "generate", fail)
    service.step()
    record = apply(service, value)["operation"]
    assert record["state"] == "failed" and record["effects"] == effects
    assert not service.recovery_required
    assert validated(service)


@pytest.mark.parametrize("failed_save,generated", [(1, 0), (2, 0), (3, 1), (4, 1)])
def test_storage_faults_at_each_mutation_boundary(service, monkeypatch, failed_save, generated):
    value = validated(service)
    service.approve(value["validation_id"])
    save = service.journal.save
    calls = 0

    def sometimes_fail():
        nonlocal calls
        calls += 1
        if calls == failed_save:
            raise OSError("Fixture storage unavailable")
        save()

    monkeypatch.setattr(service.journal, "save", sometimes_fail)
    if failed_save == 1:
        with pytest.raises(Fault) as error:
            apply(service, value)
        assert error.value.code == "JOURNAL_FAILED"
    else:
        apply(service, value)
        service.step()
    record = apply(service, value)["operation"]
    assert record["state"] == "failed" and record["error"]["code"] == "JOURNAL_FAILED"
    assert record["effects"] == ("committed" if generated else "none")
    assert service.pending is None and service.host.generated == generated
    if generated:
        assert record["result"]["generation_id"] == "generation_1"
    assert_replay_blocked(service, value)


def test_persistent_storage_failure_keeps_queries_and_restart_guard(service, monkeypatch):
    value = queue(service)
    save = service.journal.save

    def fail_after_commit():
        if service.host.generated:
            raise OSError("Fixture disk unavailable")
        save()

    monkeypatch.setattr(service.journal, "save", fail_after_commit)
    service.step()
    record = apply(service, value)["operation"]
    assert record["persistence"] == "unconfirmed"
    assert record["effects"] == "committed" and record["result"]["generation_id"] == "generation_1"
    restarted = Service(Host(), Journal(service.journal.path))
    old = apply(restarted, value)["operation"]
    assert old["state"] == "outcome_unknown" and old["effects"] == "unknown"
    assert_replay_blocked(restarted, value)


def test_restart_keeps_a_persisted_commit_witness(tmp_path):
    journal = Journal(tmp_path / "journal.json")
    journal.records["operation_x"] = {"operation_id": "operation_x", "state": "running", "effects": "committed",
                                       "result": {"controller_id": "controller_x", "generation_id": "generation_x"}}
    journal.save()
    restarted = Journal(journal.path)
    record = restarted.records["operation_x"]
    assert record["state"] == "outcome_unknown" and record["effects"] == "committed"
    assert record["result"]["generation_id"] == "generation_x" and record["recovery_required"]
    with pytest.raises(Fault, match="reconciliation"):
        Service(Host(), restarted).enroll(None, [], [])


def test_journal_eviction_preserves_unresolved_operations(tmp_path):
    journal = Journal(tmp_path / "journal.json")
    journal.records["unknown"] = {"operation_id": "unknown", "state": "outcome_unknown", "effects": "unknown"}
    for index in range(128):
        journal.records[str(index)] = {"operation_id": str(index), "state": "succeeded", "effects": "committed"}
    journal.save()
    assert len(journal.records) == 128 and "unknown" in journal.records and "0" not in journal.records


def test_journal_full_of_unresolved_work_refuses_eviction(tmp_path):
    journal = Journal(tmp_path / "journal.json")
    for index in range(129):
        journal.records[str(index)] = {"operation_id": str(index), "state": "outcome_unknown", "effects": "unknown"}
    with pytest.raises(Fault) as error:
        journal.save()
    assert error.value.code == "JOURNAL_FAILED"
    assert "0" in journal.records


def test_cancel_storage_failure_cannot_execute_or_clear_recovery(service, monkeypatch):
    value = queue(service)

    def fail():
        raise OSError("Fixture disk unavailable")

    monkeypatch.setattr(service.journal, "save", fail)
    service.cancel()
    service.step()
    record = apply(service, value)["operation"]
    assert record["effects"] == "none" and record["persistence"] == "unconfirmed"
    assert service.host.generated == 0 and not service.approved
    assert_replay_blocked(service, value)


def production_method(name, globals):
    """Execute a production method without importing Max/Qt outside the host."""
    path = Path(__file__).resolve().parents[1] / "cyrus_mcp" / "max_host.py"
    tree = ast.parse(path.read_text(encoding="utf-8"))
    cls = next(node for node in tree.body if isinstance(node, ast.ClassDef) and node.name == "MaxHost")
    method = next(node for node in cls.body if isinstance(node, ast.FunctionDef) and node.name == name)
    exec(compile(ast.Module(body=[method], type_ignores=[]), str(path), "exec"), globals)
    return globals[name]


@pytest.mark.parametrize("field,value", [("state","unrecognized"),("effects","maybe"),("recovery_required","false"),("resolution",{"status":"unrecognized"})])
def test_unrecognized_journal_state_never_restores_mutation_authority(tmp_path, field, value):
    path=tmp_path/"journal.json"
    data={"operation_id":"operation_bad","state":"failed","effects":"committed",field:value}
    path.write_text(json.dumps([data]),encoding="utf-8")
    with pytest.raises(Fault) as error:
        Journal(path)
    assert error.value.code=="OUTCOME_UNKNOWN" and json.loads(path.read_text(encoding="utf-8"))==[data]


def test_failed_commit_without_a_recovery_flag_still_requires_local_review(tmp_path):
    path=tmp_path/"journal.json"
    path.write_text(json.dumps([{"operation_id":"operation_old","state":"failed","effects":"committed"}]),encoding="utf-8")
    assert Service(None,Journal(path)).recovery_required


def test_duplicate_journal_identity_cannot_hide_an_unresolved_operation(tmp_path):
    path=tmp_path/"journal.json"
    path.write_text(json.dumps([{"operation_id":"same","state":"outcome_unknown","effects":"unknown"},
                               {"operation_id":"same","state":"succeeded","effects":"committed"}]),encoding="utf-8")
    before=path.read_bytes()
    with pytest.raises(Fault) as error:
        Journal(path)
    assert error.value.code=="OUTCOME_UNKNOWN" and path.read_bytes()==before


def test_oversized_journal_save_preserves_previous_reloadable_receipt(tmp_path):
    path=tmp_path/"journal.json"; journal=Journal(path)
    journal.records["operation_a"]={"operation_id":"operation_a","state":"succeeded","effects":"committed"}
    journal.save(); before=path.read_bytes()
    journal.records["operation_a"]["large"]="x"*2_000_000
    with pytest.raises(Fault) as error:
        journal.save()
    assert error.value.code=="JOURNAL_FAILED" and path.read_bytes()==before
    assert list(Journal(path).records)==["operation_a"]


def fingerprint_fixture(read_only):
    runtime = SimpleNamespace(units=SimpleNamespace(decodeValue=lambda _: 1), sliderTime=0, isValidNode=lambda _: True)
    node = SimpleNamespace(transform=[1, 0, 0], isHidden=False, name="Source")
    host = SimpleNamespace(read_only=read_only, assert_main=lambda: None, nodes={"source_x": node}, controllers={}, masks={},
                           mesh=lambda *args: [1, 2, 3], diagnostics=lambda: {},has_native_source=lambda _:False)
    fingerprint = production_method("fingerprint", {"rt": runtime, "digest": digest, "require": require, "frozen": lambda v: v})
    return fingerprint, host, runtime


def test_static_design_ignores_unrelated_time_but_detects_geometry():
    fingerprint, host, runtime = fingerprint_fixture(False)
    before = fingerprint(host)
    runtime.sliderTime = 40
    assert fingerprint(host) == before
    del runtime.sliderTime  # Design inspection must not need to read the clock.
    assert fingerprint(host) == before
    host.mesh = lambda *args: [1, 2, 4]
    assert fingerprint(host) != before


def test_inspection_time_remains_conservative():
    fingerprint, host, runtime = fingerprint_fixture(True)
    before = fingerprint(host)
    runtime.sliderTime = 40
    assert fingerprint(host) != before


def test_native_preflight_fault_explicitly_proves_no_mutation():
    runtime = SimpleNamespace(cyrusLicenseAllows=lambda: False)
    generate = production_method("generate", {"rt": runtime, "require": require, "Fault": Fault})
    host = SimpleNamespace(assert_main=lambda: None)
    with pytest.raises(Fault) as error:
        generate(host, {}, [])
    assert error.value.code == "LICENSE_REQUIRED" and error.value.details["effects"] == "none"
