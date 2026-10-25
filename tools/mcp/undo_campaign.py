"""Owned Max 2027 qualification of production local Undo outcome witnesses."""
import json
import uuid

from foundation_campaign import qualification, verify_owned


def run(base):
    q = qualification(base)
    receipt = q.folder / ("undo-"+uuid.uuid4().hex+".json")
    evidence = {"status": "running", "cases": [],
                "qualification": "Owned Max 2027 API fixture; local actions scripted, not artist consent"}

    def save():
        meta = verify_owned(q.folder)
        evidence.update(run_id=meta["run_id"], artifact_id=meta["artifact_id"], pid=meta["pid"])
        receipt.write_text(json.dumps(evidence, indent=2)+"\n", encoding="utf-8")

    def create():
        q.local("setup"); q.local("sentinel_create")
        before = q.local("snapshot")
        first = q.apply(q.plan(q.context(), count=80, layers=2))
        assert first["state"] == "succeeded", first
        published = q.local("publication_snapshot", controller_id=first["result"]["controller_id"])
        return before, first, published

    def same(actual, expected):
        for field in ("rows_sha256", "authored_sha256", "generation_id", "configuration_id", "root_layer_id", "layer_ids", "nodes"):
            assert actual[field] == expected[field], field

    try:
        before, first, published = create()
        sentinel = q.local("sentinel_snapshot")
        undo_ui=q.local("undo_receipt",panel=True)
        undone = undo_ui["operation"]
        assert undo_ui["scope_label"]=="No scope connected" and not undo_ui["shared_checkbox"]
        after = q.local("snapshot")
        case = dict(scenario="creation_undo", before=before, first=first, undo=undone, after=after)
        evidence["cases"].append(case); save()
        assert undone["state"] == "succeeded" and undone["effects"] == "committed" and undone["result"]["controller_removed"]
        assert after["nodes"] == before["nodes"] and not q.call("connection.get_status")["scope_id"]
        assert q.local("sentinel_snapshot") == sentinel
        assert q.call("scatter.get_status", scene_epoch=undone["scene_epoch"], operation_id=undone["operation_id"])["operation"] == undone
        q.local("redo")
        case["redone"] = q.local("publication_snapshot", controller_id=first["result"]["controller_id"])
        same(case["redone"], published)
        case["passed"] = True; save()
        for phase in (None, "undo_after_native", "undo_presentation", "wrong_top"):
            _, first, old = create()
            plan = q.plan(q.context(), count=120, layers=2)
            plan.update(controller_id=first["result"]["controller_id"], generation_id=first["result"]["generation_id"])
            second = q.apply(plan)
            assert second["state"] == "succeeded", second
            cid = first["result"]["controller_id"]
            current = q.local("publication_snapshot", controller_id=cid)
            if phase == "wrong_top":
                q.local("sentinel_edit")
            sentinel = q.local("sentinel_snapshot")
            q.local("fault", phase=None if phase == "wrong_top" else phase)
            undo_ui=q.local("undo_receipt",panel=True)
            undone = undo_ui["operation"]
            if phase in ("undo_after_native","undo_presentation"):
                assert "local review" in undo_ui["scope_label"] and not undo_ui["undo_enabled"]
            elif phase is None:
                assert undo_ui["scope_label"]=="No scope connected"
            q.local("fault", phase=None)
            actual = q.local("publication_snapshot", controller_id=cid)
            case = dict(scenario=phase or "refinement_undo", first=first, second=second,
                        old=old, current=current, undo=undone, actual=actual)
            evidence["cases"].append(case); save()
            same(actual, current if phase == "wrong_top" else old)
            assert q.local("sentinel_snapshot") == sentinel
            if phase is None:
                assert undone["state"] == "succeeded" and undone["effects"] == "committed"
                q.local("redo")
                case["redone"] = q.local("publication_snapshot", controller_id=cid)
                same(case["redone"], current)
            elif phase == "wrong_top":
                assert undone["state"] == "failed" and undone["effects"] == "none" and not undone["recovery_required"]
            else:
                expected = "unknown" if phase == "undo_after_native" else "committed"
                assert undone["effects"] == expected and undone["recovery_required"]
                assert q.call("connection.get_status")["recovery_required"]
                review = q.local("review_recovery", operation_id=undone["operation_id"])
                case["retirement"] = q.local("confirm_recovery", review_id=review["review_id"], digest=review["digest"])
                same(q.local("publication_snapshot", controller_id=cid), actual)
                assert not case["retirement"]["recovery_required"]
                record = q.call("scatter.get_status", scene_epoch=undone["scene_epoch"], operation_id=undone["operation_id"])["operation"]
                assert record["effects"] == expected and record["resolution"]["status"] == "locally_retired"
            case["passed"] = True; save()
        evidence["status"] = "passed"; save()
        print(json.dumps({"passed": True, "receipt": str(receipt), "cases": len(evidence["cases"])}), flush=True)
    except Exception as exc:
        evidence.update(status="failed", error=str(exc)); save()
        raise
