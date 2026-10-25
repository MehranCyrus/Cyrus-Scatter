from copy import deepcopy
import pytest
from cyrus_mcp.contracts import Fault
from cyrus_mcp.models import OwnedChange
from cyrus_mcp.service import Service, Journal
from test_service import Host, apply
from test_contracts import plan


class ChangeHost(Host):
    def generate(self, plan, compiled):
        result = super().generate(plan, compiled)
        result.update(configuration_id=result["generation_id"], publication_pending=False,
                      layers=[{"layer_id": "layer_1"}], requested=sum(x["count"] for x in plan["layers"]))
        return result

    def change(self, change, plan, compiled, previous):
        if change["mode"] != "configure":
            result = self.generate(plan, compiled)
        else:
            self.revision += 1
            result = deepcopy(previous)
        result.update(configuration_id="configuration_"+str(self.revision),
                      publication_pending=change["mode"] == "configure")
        return result


@pytest.fixture
def changed(tmp_path):
    service = Service(ChangeHost(), Journal(tmp_path/"operations.json"))
    service.enroll(None, [], [])
    value = service.validate(plan(service.context(service.scope["scope_id"])["context_id"]))
    service.approve(value["validation_id"])
    apply(service, value, "create"); service.step()
    return service


def proposal(service, mode="configure", **patch):
    context = service.context(service.scope["scope_id"])
    owner = service.owned["controller_1"]
    return dict(change_schema="cyrus.owned-change/1.0", context_id=context["context_id"], controller_id="controller_1",
                generation_id=owner["generation_id"], configuration_id=owner["configuration_id"], mode=mode,
                layers=[] if mode == "update" else [dict(layer_id="layer_1", **(patch or {"count": 150}))])


def execute(service, change, key):
    value = service.validate_change(change)
    service.approve(value["validation_id"])
    apply(service, value, key); service.step()
    return apply(service, value, key)["operation"]


def test_configure_then_update_keep_publication_separate_from_authored_definition(changed):
    service = changed
    service.records["controller_1"] = {"publication_plan": "old"}
    configured = execute(service, proposal(service), "configure")
    assert configured["state"] == "succeeded" and configured["effects"] == "committed"
    assert service.applications == 1 and service.configurations == 1
    assert service.host.generated == 1 and service.owned["controller_1"]["generation_id"] == "generation_1"
    assert service.authored["controller_1"]["plan"]["layers"][0]["count"] == 150
    assert service.records["controller_1"] == {"publication_plan": "old"}
    exported = service.export_record(service.epoch, "controller_1", "generation_1")
    assert exported["publication_pending"] and exported["record"] == {"publication_plan": "old"}
    updated = execute(service, proposal(service, "update"), "update")
    assert updated["state"] == "succeeded" and not updated["result"]["publication_pending"]
    assert service.applications == 2 and service.configurations == 1 and service.host.generated == 2
    assert "controller_1" not in service.records  # Fake host cannot supply a newly verified native layout.


@pytest.mark.parametrize("field,value", [("controller_id", []), ("generation_id", "old"),
                                        ("configuration_id", "old"), ("mode", "arbitrary"),
                                        ("change_schema", "1.0")])
def test_invalid_or_stale_change_never_enters_host(changed, field, value):
    change = proposal(changed); change[field] = value
    with pytest.raises(Fault):
        changed.validate_change(change)
    assert changed.host.generated == 1 and not changed.pending


@pytest.mark.parametrize("patch", [{}, {"count": True}, {"count": 2001}, {"seed": -1},
                                  {"count": 100}, {"property": "amount"}])
def test_closed_layer_patch_contract(changed, patch):
    change = proposal(changed); change["layers"] = [dict(layer_id="layer_1", **patch)]
    with pytest.raises(Fault):
        changed.validate_change(change)


def test_change_requires_approval_and_queued_cancel_does_not_configure(changed):
    value = changed.validate_change(proposal(changed))
    with pytest.raises(Fault, match="Approve"):
        apply(changed, value, "change")
    changed.approve(value["validation_id"]); apply(changed, value, "change")
    changed.cancel(); changed.step()
    assert apply(changed, value, "change")["operation"]["effects"] == "none"
    assert changed.configurations == 0 and changed.host.generated == 1


def test_live_configure_rejected_and_configuration_token_expires(changed):
    change = proposal(changed)
    changed.authored["controller_1"]["plan"]["display"]["update_mode"] = "real_time"
    with pytest.raises(Fault, match="Manual"):
        changed.validate_change(change)
    changed.authored["controller_1"]["plan"]["display"]["update_mode"] = "manual"
    execute(changed, change, "configuration")
    change["context_id"] = changed.context(changed.scope["scope_id"])["context_id"]
    with pytest.raises(Fault, match="configuration"):
        changed.validate_change(change)


def test_configuration_admission_and_external_schema(changed):
    value = proposal(changed)
    assert OwnedChange.model_validate(value).model_dump(exclude_none=True) == value
    for i in range(8):
        execute(changed, proposal(changed, count=151+i), "config_"+str(i))
    with pytest.raises(Fault, match="budget"):
        changed.validate_change(proposal(changed, count=170))
    assert changed.applications == 1 and changed.configurations == 8


def test_outcome_polls_and_exact_retries_do_not_drain_the_next_change_budget(changed):
    value = changed.validate_change(proposal(changed))
    changed.approve(value["validation_id"])
    args = {key:value[key] for key in ("validation_id", "digest", "scene_epoch", "scene_revision")}
    args["idempotency_key"] = "stable_key"
    queued = changed.dispatch("scatter.apply_plan", args)
    changed.step()
    before = changed.calls
    for _ in range(30):
        changed.dispatch("scatter.get_status", {"scene_epoch":changed.epoch, "operation_id":queued["operation"]["operation_id"]})
        changed.dispatch("scatter.apply_plan", args)
    assert changed.calls == before and changed.configurations == 1


def test_queued_change_records_only_the_approved_base_and_restart_blocks_enrollment(changed):
    change = proposal(changed)
    value = changed.validate_change(change)
    changed.approve(value["validation_id"])
    queued = apply(changed, value, "queued_loss")["operation"]
    assert queued["target_identity"] == {key:change[key] for key in ("controller_id", "generation_id", "configuration_id")}
    assert "commit_identity" not in queued and queued["effects"] == "none"
    restarted = Service(ChangeHost(), Journal(changed.journal.path))
    record = restarted.journal.records[queued["operation_id"]]
    assert record["state"] == "outcome_unknown" and record["effects"] == "unknown"
    assert record["target_identity"] == queued["target_identity"] and "commit_identity" not in record
    assert "local review" in restarted.connection()["message"]
    with pytest.raises(Fault) as error:
        restarted.enroll(None, [], [])
    assert error.value.code == "OUTCOME_UNKNOWN"
