"""Owned recovery/UI evidence; approval input is deliberately left to Computer Use."""
from pathlib import Path
import argparse
import json
import time
import uuid
from foundation_campaign import ROOT, qualification, verify_owned


def save(base, name, data):
    metadata = verify_owned(base/"host01")
    data.update(run_id=metadata["run_id"], artifact_id=metadata["artifact_id"], pid=metadata["pid"])
    (base/name).write_text(json.dumps(data, indent=2)+"\n", encoding="utf-8")


def prepare(base):
    q = qualification(base)
    q.local("setup"); q.local("sentinel_create")
    first = q.apply(q.plan(q.context(), count=80, layers=2))
    assert first["state"] == "succeeded", first
    owner = first["result"]
    ctx = q.context()
    change = dict(change_schema="cyrus.owned-change/1.0", context_id=ctx["context_id"],
                  controller_id=owner["controller_id"], generation_id=owner["generation_id"],
                  configuration_id=owner["configuration_id"], mode="configure",
                  layers=[dict(layer_id=owner["layers"][0]["layer_id"], count=120)])
    value = q.call("scatter.validate_change", change=change)
    q.local("post_commit_fault", kind="change")
    save(base, "ui-configure-proposal.json", dict(validation=value, change=change,
         before=q.local("publication_snapshot", controller_id=owner["controller_id"]),
         sentinel=q.local("sentinel_snapshot"), ui=q.local("ui_state")))
    print(json.dumps(q.local("show_panel")), flush=True)


def inspect(base):
    q = qualification(base)
    from cyrus_mcp.service import Journal, Service
    from cyrus_mcp.contracts import Fault
    proposal = json.loads((base/"ui-configure-proposal.json").read_text(encoding="utf-8"))
    value = proposal["validation"]
    assert value["validation_id"] in q.local("ui_state")["approved"], "Approve this concrete proposal in the owned panel first"
    args = {key:value[key] for key in ("validation_id", "digest", "scene_epoch", "scene_revision")}
    args["idempotency_key"] = uuid.uuid4().hex
    queued = q.call("scatter.apply_plan", **args)
    deadline = time.monotonic()+45
    while True:
        operation = q.call("scatter.get_status", scene_epoch=value["scene_epoch"], operation_id=queued["operation"]["operation_id"])["operation"]
        if operation["state"] not in ("queued", "running"):
            break
        if time.monotonic() >= deadline:
            raise TimeoutError("Observe original operation "+operation["operation_id"]+" without replay")
        time.sleep(.2)
    q.local("clear_post_commit_fault")
    assert operation["state"] == "failed" and operation["effects"] == "committed", operation
    assert q.call("scatter.apply_plan", **args)["operation"] == operation
    after = q.local("publication_snapshot", controller_id=proposal["change"]["controller_id"])
    assert after["rows_sha256"] == proposal["before"]["rows_sha256"]
    assert after["generation_id"] == proposal["before"]["generation_id"]
    assert after["configuration_id"] != proposal["before"]["configuration_id"]
    assert operation["commit_identity"]["configuration_id"] == after["configuration_id"]
    reloaded = Service(None, Journal(base/"host01/connection/operations.json"))
    assert reloaded.recovery_required
    restored = reloaded.journal.records[operation["operation_id"]]
    assert restored["commit_identity"] == operation["commit_identity"] and restored["effects"] == "committed"
    try:
        reloaded.require_reconciled()
    except Fault as exc:
        assert exc.code == "OUTCOME_UNKNOWN"
    else:
        raise AssertionError("Journal reload cleared uncertain-outcome recovery")
    review = q.local("review_recovery", operation_id=operation["operation_id"])
    assert review["evidence"]["selected_controller"]["recorded_configuration_matches"] is True
    assert q.local("sentinel_snapshot") == proposal["sentinel"]
    save(base, "ui-configure-committed-failure.json", dict(operation=operation, native_after=after,
          review=review, journal_reload_retains_configuration=True, same_publication=True,
          qualification="Physical panel approval; native/transport execution; journal object reload, not host crash/reopen"))
    print(json.dumps(dict(committed_configure=True, same_publication=True, journal_reload=True)), flush=True)


def finish(base):
    q = qualification(base)
    evidence = json.loads((base/"ui-configure-committed-failure.json").read_text(encoding="utf-8"))
    review = evidence["review"]
    result = q.local("confirm_recovery", review_id=review["review_id"], digest=review["digest"])
    after = q.local("publication_snapshot", controller_id=evidence["operation"]["result"]["controller_id"])
    assert after["rows_sha256"] == evidence["native_after"]["rows_sha256"]
    assert after["authored_sha256"] == evidence["native_after"]["authored_sha256"]
    assert not result["recovery_required"]
    save(base, "configure-retirement.json", dict(retirement=result, same_rows_and_authored=True,
         qualification="Scripted local retirement after separate physical recovery test; not artist consent"))
    print(json.dumps(dict(retired=True, native_state_preserved=True)), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["prepare", "inspect", "finish"])
    parser.add_argument("--base", type=Path, required=True)
    args = parser.parse_args()
    base = args.base.resolve()
    if not base.is_relative_to(ROOT/"build"):
        raise ValueError("Owned build directory required")
    globals()[args.action](base)
