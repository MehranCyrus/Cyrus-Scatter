"""Current-pair Max 2027 campaign; private profile, frozen MCP code, no artist connection changes."""
from pathlib import Path
import argparse
import asyncio
import base64
import json
import shutil
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools/edit_0869"))
from compatibility_host import launch_owned, verify_owned, close_owned, run_case
from package import stage_package_payload


def launch(base):
    base = base.resolve()
    if not base.is_relative_to(ROOT / "build"):
        raise ValueError("Owned build directory required")
    packages = ROOT / "dist/CyrusScatter-0.86.9.2-20261023"
    payload = base / "payload"
    stage_package_payload(payload, 2027, packages / "CyrusScatter-0.86.9.2-Max2027.mzp",
                          packages / "CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp")
    source, fixtures, folder = base / "source", base / "fixtures", base / "host01"
    shutil.copytree(ROOT / "CyrusMCP/cyrus_mcp", source / "cyrus_mcp", ignore=shutil.ignore_patterns("__pycache__"))
    fixtures.mkdir()
    for name in ("foundation_host.py", "host_fixture.py"):
        shutil.copy2(HERE / name, fixtures / name)
    boot = base / "boot.py"
    boot.write_text("import sys\n" + "sys.path.insert(0," + repr(str(source)) + ")\n" +
                    "sys.path.insert(0," + repr(str(fixtures)) + ")\n" +
                    "from PySide6.QtCore import QTimer\nimport foundation_host\n" +
                    "QTimer.singleShot(100,lambda:foundation_host.start(" + repr(str(folder)) + "))\n", encoding="utf-8")
    bindings = {"foundation-boot": HERE / "foundation_boot.ms", "foundation-driver": Path(__file__), "python-boot": boot}
    bindings["undo-driver"] = HERE / "undo_campaign.py"
    bindings["scene-driver"] = HERE / "scene_campaign.py"
    for path in [*source.rglob("*.py"), *source.rglob("*.json"), *fixtures.glob("*.py")]:
        bindings["mcp-" + path.relative_to(base).as_posix().replace("/", "_")] = path
    metadata = launch_owned(folder, 2027, payload, bindings=bindings, require_edit_version=True, timeout=60)
    resume(base)


def resume(base):
    """Observe the existing process after an observation timeout; never relaunch/replay."""
    folder = base / "host01"
    metadata = verify_owned(folder)
    if not (folder / "ready.json").exists():
        print(json.dumps({"pid": metadata["pid"], "ready": False, "stage": "native startup"}), flush=True)
        return
    requests = [json.loads(path.read_text(encoding="utf-8")) for path in folder.glob("request-*.json")]
    if not any(request.get("scenario_id") == "start" for request in requests):
        run_case(folder, HERE / "foundation_boot.ms", "start", ["boot_scheduled"], entrypoint="MCPFoundationRun", timeout=30)
    if (folder / "foundation-error.txt").exists():
        raise RuntimeError((folder / "foundation-error.txt").read_text(encoding="utf-8"))
    print(json.dumps({"pid": metadata["pid"], "folder": str(folder),
                      "ready": (folder / "foundation-ready.json").exists(), "stage": "MCP bootstrap"}), flush=True)


def qualification(base):
    sys.path.insert(0, str(base / "source"))
    sys.path.insert(0, str(HERE))
    from qualify import Qualification

    class Owned(Qualification):
        def local(self, action, **args):
            verify_owned(self.folder)
            result = super().local(action, **args)
            verify_owned(self.folder)
            return result

        def call(self, method, **args):
            verify_owned(self.folder)
            result = super().call(method, **args)
            verify_owned(self.folder)
            return result

    return Owned(base / "host01")


async def stdio(q, source):
    from mcp import Client
    from mcp.client.stdio import StdioServerParameters
    q.local("setup")
    code = "import sys;sys.path.insert(0," + repr(str(source)) + ");from cyrus_mcp.server import main;main()"
    params = StdioServerParameters(command=sys.executable, args=["-c", code, "--connection-dir", str(q.folder / "connection")])
    async with Client(params) as client:
        async def call(name, **args):
            verify_owned(q.folder)
            result = await client.call_tool(name, args)
            assert not result.is_error, result
            assert result.structured_content and result.structured_content["ok"], result
            return result.structured_content
        tools = await client.list_tools()
        assert len(tools.tools) == 18
        connection = await call("connection_get_status")
        context = await call("scene_get_context", scope_id=connection["scope_id"])
        validated = await call("scatter_validate_plan", plan=q.plan(context, count=120, layers=2))
        q.local("approve", validation_id=validated["validation_id"])
        args = {k: validated[k] for k in ("validation_id", "digest", "scene_epoch", "scene_revision")}
        args["idempotency_key"] = "stdio_" + uuid.uuid4().hex
        queued = await call("scatter_apply_plan", **args)
        deadline = time.monotonic()+45
        while True:
            operation = (await call("scatter_get_status", scene_epoch=connection["scene_epoch"], operation_id=queued["operation"]["operation_id"]))["operation"]
            if operation["state"] not in ("queued", "running"):
                break
            if time.monotonic() >= deadline:
                raise TimeoutError("Observe operation " + operation["operation_id"] + " without replay")
            await asyncio.sleep(.2)
        assert operation["state"] == "succeeded" and operation["effects"] == "committed", operation
        assert (await call("scatter_apply_plan", **args))["operation"] == operation
        published = await call("scatter_get_publication", scene_epoch=connection["scene_epoch"], controller_id=operation["result"]["controller_id"])
        assert published["manifest"]["count"] == operation["result"]["emitted"] > 0
        cid = operation["result"]["controller_id"]
        exported = await call("scatter_export_record", scene_epoch=connection["scene_epoch"], controller_id=cid,
                              generation_id=operation["result"]["generation_id"])
        instances = exported["record"]["layout"]["instances"]
        assert len(instances) == operation["result"]["emitted"] and not exported["training_eligible"]
        page = await call("scatter_read_publication_page", scene_epoch=connection["scene_epoch"], controller_id=cid,
                          publication_id=published["manifest"]["publication_id"], offset=0, limit=500)
        assert [row["transform"] for row in page["page"]["rows"]] == [row["transform"] for row in instances]
        configuration = await call("scatter_get_configuration", scene_epoch=connection["scene_epoch"], controller_id=cid)
        diagnostics = await call("scatter_get_diagnostics", scene_epoch=connection["scene_epoch"])
        denied = await client.call_tool("scatter_read_diagnostic_events", {"scene_epoch": connection["scene_epoch"], "session_id": "not_shared"})
        assert denied.is_error and denied.structured_content["error"]["code"] == "APPROVAL_REQUIRED"
        capture = await client.call_tool("scene_capture_viewport", {"scene_epoch": connection["scene_epoch"],
                    "scene_revision": operation["scene_revision"], "viewport_id": context["viewport_id"],
                    "generation_id": operation["result"]["generation_id"]})
        assert not capture.is_error, capture
        images = [content for content in capture.content if content.type == "image"]
        assert len(images) == 1
        png = base64.b64decode(images[0].data)
        assert png.startswith(b"\x89PNG")
        capture_path = q.folder / ("viewport-"+operation["operation_id"]+".png")
        capture_path.write_bytes(png)
        return {"client": "MCP SDK stdio client", "tool_count": len(tools.tools), "operation": operation,
                "native_publication": published["manifest"], "exact_key_retry": True,
                "export_count": len(instances), "publication_transforms_match_export": True,
                "configuration": configuration, "diagnostics": diagnostics,
                "unshared_trace_denied": True, "viewport_png": str(capture_path)}


def exercise(base):
    q = qualification(base)
    result = {"stdio": asyncio.run(stdio(q, base / "source"))}
    q.local("setup")
    context = q.context()
    q.local("time", value=160)
    after = q.context()
    assert after["scene_revision"] == context["scene_revision"] and not after["scope"].get("stale")
    result["static_time_change"] = True
    q.local("fault", phase="layers")
    rolled_back = q.apply(q.plan(after))
    assert rolled_back["state"] == "failed" and rolled_back["effects"] == "verified_rollback", rolled_back
    q.local("fault", phase=None)
    result["rollback"] = rolled_back
    q.local("setup")
    q.local("post_commit_fault")
    committed = q.apply(q.plan(q.context()))
    assert committed["state"] == "failed" and committed["effects"] == "committed", committed
    assert committed["error"]["code"] == "POST_COMMIT_FAILED"
    publication = q.local("publication", controller_id=committed["result"]["controller_id"])
    assert publication["count"] == committed["result"]["emitted"] > 0
    q.local("clear_post_commit_fault")
    review = q.local("review_recovery", operation_id=committed["operation_id"])
    before = q.local("snapshot")
    retired = q.local("confirm_recovery", review_id=review["review_id"], digest=review["digest"])
    assert not retired["recovery_required"]
    assert q.local("snapshot") == before, "Retirement changed native scene state"
    original = q.call("scatter.get_status", scene_epoch=committed["scene_epoch"], operation_id=committed["operation_id"])["operation"]
    assert original["effects"] == "committed" and original["resolution"]["status"] == "locally_retired"
    result.update(post_commit=committed, recovery_review=review, retirement=retired, native_scene_preserved=True)
    verify_owned(q.folder)
    metadata = verify_owned(q.folder)
    result.update(run_id=metadata["run_id"], artifact_id=metadata["artifact_id"], pid=metadata["pid"],
                  qualification="Scripted owned-host/API evidence; not physical artist interaction or broad performance certification")
    receipt = q.folder / ("foundation-results-"+uuid.uuid4().hex+".json")
    receipt.write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"passed": True, "stdio": True, "static_time": True, "rollback": True,
                      "post_commit": True, "local_retirement": True, "native_scene_preserved": True,
                      "receipt": str(receipt)}), flush=True)


def refinement(base):
    """Real owned replacement, Undo, and failures before/after native publication."""
    q = qualification(base)
    receipt = q.folder / ("refinement-"+uuid.uuid4().hex+".json")
    evidence = {"cases": [], "status": "running", "qualification": "Owned Max API fixture, not physical artist interaction"}

    def save():
        metadata = verify_owned(q.folder)
        evidence.update(run_id=metadata["run_id"], artifact_id=metadata["artifact_id"], pid=metadata["pid"])
        receipt.write_text(json.dumps(evidence, indent=2)+"\n", encoding="utf-8")

    def create():
        q.local("setup")
        q.local("sentinel_create")
        first = q.apply(q.plan(q.context(), count=80, layers=2))
        assert first["state"] == "succeeded", first
        cid = first["result"]["controller_id"]
        return first, q.local("publication_snapshot", controller_id=cid), q.local("sentinel_snapshot")

    def next_plan(first):
        plan = q.plan(q.context(), count=120, layers=2)
        plan.update(controller_id=first["result"]["controller_id"], generation_id=first["result"]["generation_id"])
        return plan

    try:
        first, before, sentinel = create()
        second = q.apply(next_plan(first))
        after = q.local("publication_snapshot", controller_id=first["result"]["controller_id"])
        case = {"scenario": "owned_refinement_and_undo", "before": before, "first": first,
                "second": second, "after": after, "sentinel_before": sentinel}
        evidence["cases"].append(case); save()
        assert second["state"] == "succeeded" and second["result"]["controller_id"] == first["result"]["controller_id"], second
        assert second["result"]["generation_id"] != first["result"]["generation_id"]
        assert after["generation_id"] == second["result"]["generation_id"]
        assert q.local("sentinel_snapshot") == sentinel
        q.local("undo")
        restored = q.local("publication_snapshot", controller_id=first["result"]["controller_id"])
        case["after_undo"] = restored; save()
        assert restored["rows_sha256"] == before["rows_sha256"], "Own Undo did not restore the previous complete publication"
        assert restored["layer_ids"] == before["layer_ids"] and restored["authored_sha256"] == before["authored_sha256"]
        assert restored["generation_id"] == before["generation_id"]
        assert restored["root_layer_id"] == before["root_layer_id"] != ""
        assert q.local("sentinel_snapshot") == sentinel
        q.local("redo")
        redone = q.local("publication_snapshot", controller_id=first["result"]["controller_id"])
        case["after_redo"] = redone; save()
        for field in ("rows_sha256", "layer_ids", "authored_sha256", "generation_id", "root_layer_id", "nodes"):
            assert redone[field] == after[field], "Redo: "+field
        assert q.local("sentinel_snapshot") == sentinel
        case["passed"] = True; save()
        for phase in ("layers", "preview", "publish"):
            first, before, sentinel = create()
            q.local("fault", phase=phase)
            failed = q.apply(next_plan(first))
            q.local("fault", phase=None)
            after = q.local("publication_snapshot", controller_id=first["result"]["controller_id"])
            case = {"scenario": "failed_refinement_"+phase, "first": first, "failed": failed,
                    "before": before, "after": after, "sentinel_before": sentinel,
                    "sentinel_after": q.local("sentinel_snapshot")}
            evidence["cases"].append(case); save()
            assert failed["state"] == "failed" and failed["effects"] == "verified_rollback", failed
            assert after["rows_sha256"] == before["rows_sha256"], "Failed successor lost the previous publication"
            for field in ("layer_ids", "authored_sha256", "generation_id", "nodes"):
                assert after[field] == before[field], field
            assert case["sentinel_before"] == case["sentinel_after"]
            case["passed"] = True; save()
        evidence["status"] = "passed"; save()
        print(json.dumps({"passed": True, "refinement": True, "undo_previous_publication": True,
                          "failed_successor_retention": True, "receipt": str(receipt)}), flush=True)
    except Exception as exc:
        evidence.update(status="failed", error=str(exc)); save()
        raise


async def change_campaign(base, edges=False):
    """Current client schema and actual native Manual publication semantics."""
    from mcp import Client
    from mcp.client.stdio import StdioServerParameters
    q = qualification(base)
    receipt = q.folder / (("change-edges-" if edges else "changes-")+uuid.uuid4().hex+".json")
    evidence = {"status": "running", "cases": [], "qualification": "Real SDK stdio; scripted owned local approval, not physical artist interaction"}

    def save():
        metadata = verify_owned(q.folder)
        evidence.update(run_id=metadata["run_id"], artifact_id=metadata["artifact_id"], pid=metadata["pid"])
        receipt.write_text(json.dumps(evidence, indent=2)+"\n", encoding="utf-8")

    code = "import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params = StdioServerParameters(command=sys.executable, args=["-c", code, "--connection-dir", str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            async def call(name, **args):
                verify_owned(q.folder)
                response = await client.call_tool(name, args)
                assert not response.is_error and response.structured_content["ok"], response
                verify_owned(q.folder)
                return response.structured_content

            assert len((await client.list_tools()).tools) == 18

            async def context():
                connection = await call("connection_get_status")
                return await call("scene_get_context", scope_id=connection["scope_id"])

            async def apply_validation(value):
                q.local("approve", validation_id=value["validation_id"])
                args = {key:value[key] for key in ("validation_id", "digest", "scene_epoch", "scene_revision")}
                args["idempotency_key"] = uuid.uuid4().hex
                queued = await call("scatter_apply_plan", **args)
                deadline = time.monotonic()+45
                while True:
                    operation = (await call("scatter_get_status", scene_epoch=value["scene_epoch"], operation_id=queued["operation"]["operation_id"]))["operation"]
                    if operation["state"] not in ("queued", "running"):
                        assert (await call("scatter_apply_plan", **args))["operation"] == operation
                        return operation
                    if time.monotonic() >= deadline:
                        raise TimeoutError("Observe original operation "+operation["operation_id"]+" without replay")
                    await asyncio.sleep(.2)

            async def create(display="proxy", live=False):
                q.local("setup"); q.local("sentinel_create")
                ctx = await context()
                plan = q.plan(ctx, count=80, layers=2)
                plan["display"] = {"mode": display, "update_mode": "real_time" if live else "manual"}
                operation = await apply_validation(await call("scatter_validate_plan", plan=plan))
                assert operation["state"] == "succeeded", operation
                return operation["result"], q.local("publication_snapshot", controller_id=operation["result"]["controller_id"]), q.local("sentinel_snapshot")

            async def propose(owner, mode="configure"):
                ctx = await context()
                return dict(change_schema="cyrus.owned-change/1.0", context_id=ctx["context_id"],
                            controller_id=owner["controller_id"], generation_id=owner["generation_id"],
                            configuration_id=owner["configuration_id"], mode=mode,
                            layers=[] if mode == "update" else [dict(layer_id=owner["layers"][0]["layer_id"], count=120, seed=123)])

            for display in (() if edges else ("proxy", "mesh", "point_cloud")):
                owner, before, sentinel = await create(display)
                case = {"scenario": "manual_configure_update_"+display, "before": before, "sentinel_before": sentinel}
                evidence["cases"].append(case); save()
                configured = await apply_validation(await call("scatter_validate_change", change=await propose(owner)))
                case["configure"] = configured; save()
                assert configured["state"] == "succeeded", configured
                cid = owner["controller_id"]
                pending = q.local("publication_snapshot", controller_id=cid)
                case["pending"] = pending; save()
                assert pending["manifest"]["publication_id"] == before["manifest"]["publication_id"]
                assert pending["rows_sha256"] == before["rows_sha256"] and pending["cache_builds"] == before["cache_builds"]
                assert pending["layer_ids"] == before["layer_ids"] and pending["generation_id"] == before["generation_id"]
                expected = json.loads(json.dumps(before["authored"]))
                expected["layers"][0].update(amount=120, randomSeed=123)
                assert pending["authored"] == expected, "Configure changed an unmentioned authored field"
                assert pending["pending_flags"][0]
                if display != "proxy":
                    assert all(o["available"] for o in before["retained"]["owners"])
                    assert pending["retained"]["process_totals"]["uploads"] == before["retained"]["process_totals"]["uploads"], "Configure re-uploaded warm buffers"
                configuration = await call("scatter_get_configuration", scene_epoch=configured["scene_epoch"], controller_id=cid)
                exported = await call("scatter_export_record", scene_epoch=configured["scene_epoch"], controller_id=cid, generation_id=owner["generation_id"])
                assert configuration["publication_pending"] and exported["publication_pending"]
                assert exported["record"]["plan"]["layers"][0]["count"] == 80
                assert q.local("sentinel_snapshot") == sentinel
                updated = await apply_validation(await call("scatter_validate_change", change=await propose(configured["result"], "update")))
                case["update"] = updated; save()
                assert updated["state"] == "succeeded" and not updated["result"]["publication_pending"], updated
                after = q.local("publication_snapshot", controller_id=cid)
                case["after"] = after; save()
                assert after["manifest"]["publication_id"] != before["manifest"]["publication_id"]
                assert after["layer_ids"] == before["layer_ids"] and after["authored"] == pending["authored"]
                assert after["configuration_id"] == pending["configuration_id"]
                exported = await call("scatter_export_record", scene_epoch=updated["scene_epoch"], controller_id=cid, generation_id=updated["result"]["generation_id"])
                assert not exported["publication_pending"] and exported["record"]["plan"]["layers"][0]["count"] == 120
                assert [row["transform"] for row in after["rows"]] == [row["transform"] for row in exported["record"]["layout"]["instances"]]
                q.local("undo")
                undone = q.local("publication_snapshot", controller_id=cid)
                case["undo"] = undone; save()
                assert undone["rows_sha256"] == pending["rows_sha256"] and undone["authored_sha256"] == pending["authored_sha256"]
                q.local("redo")
                redone = q.local("publication_snapshot", controller_id=cid)
                case["redo"] = redone; save()
                assert redone["rows_sha256"] == after["rows_sha256"] and redone["authored_sha256"] == after["authored_sha256"]
                assert q.local("sentinel_snapshot") == sentinel
                case["passed"] = True; save()

            for mode, phase in (() if edges else (("configure", "change_settings"), ("configure_and_update", "change_preview"), ("configure_and_update", "change_publish"))):
                owner, before, sentinel = await create()
                change = await propose(owner, mode)
                validation = await call("scatter_validate_change", change=change)
                q.local("fault", phase=phase)
                failed = await apply_validation(validation)
                q.local("fault", phase=None)
                after = q.local("publication_snapshot", controller_id=owner["controller_id"])
                case = dict(scenario="failed_"+phase, before=before, after=after, operation=failed)
                evidence["cases"].append(case); save()
                assert failed["state"] == "failed" and failed["effects"] == "verified_rollback", failed
                for field in ("rows_sha256", "authored_sha256", "generation_id", "configuration_id", "layer_ids", "nodes"):
                    assert after[field] == before[field], field
                assert after["manifest"]["publication_id"] == before["manifest"]["publication_id"]
                assert q.local("sentinel_snapshot") == sentinel
                case["passed"] = True; save()
            owner, before, sentinel = await create(live=True)
            denied = await client.call_tool("scatter_validate_change", {"change": await propose(owner)})
            assert denied.is_error and denied.structured_content["error"]["code"] == "UNSUPPORTED_CAPABILITY"
            after = q.local("publication_snapshot", controller_id=owner["controller_id"])
            assert after["authored_sha256"] == before["authored_sha256"] and after["rows_sha256"] == before["rows_sha256"]
            evidence["cases"].append(dict(scenario="live_configure_denied", passed=True))
            if edges:
                applied = await apply_validation(await call("scatter_validate_change", change=await propose(owner, "configure_and_update")))
                after = q.local("publication_snapshot", controller_id=owner["controller_id"])
                case = dict(scenario="live_configure_and_update", operation=applied, before=before, after=after)
                evidence["cases"].append(case); save()
                assert applied["state"] == "succeeded", applied
                assert after["authored"]["root"]["updateMode"] == before["authored"]["root"]["updateMode"] == 2
                assert after["layer_ids"] == before["layer_ids"] and after["nodes"] == before["nodes"]
                assert after["manifest"]["publication_id"] != before["manifest"]["publication_id"]
                assert q.local("sentinel_snapshot") == sentinel
                case["passed"] = True; save()
                owner, before, sentinel = await create()
                configured = await apply_validation(await call("scatter_validate_change", change=await propose(owner)))
                pending = q.local("publication_snapshot", controller_id=owner["controller_id"])
                case = dict(scenario="configure_only_undo_redo", before=before, pending=pending, operation=configured)
                evidence["cases"].append(case); save()
                assert configured["state"] == "succeeded", configured
                q.local("undo")
                undone = q.local("publication_snapshot", controller_id=owner["controller_id"])
                case["undo"] = undone; save()
                for field in ("authored_sha256", "rows_sha256", "generation_id", "configuration_id", "layer_ids", "nodes"):
                    assert undone[field] == before[field], "Configure Undo: "+field
                q.local("redo")
                redone = q.local("publication_snapshot", controller_id=owner["controller_id"])
                case["redo"] = redone; save()
                for field in ("authored_sha256", "rows_sha256", "generation_id", "configuration_id", "layer_ids", "nodes"):
                    assert redone[field] == pending[field], "Configure Redo: "+field
                assert q.local("sentinel_snapshot") == sentinel
                case["passed"] = True; save()
            evidence["status"] = "passed"; save()
            print(json.dumps(dict(passed=True, changes=True, receipt=str(receipt))), flush=True)
    except BaseException as exc:
        evidence.update(status="failed", error=str(exc)); save()
        raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["launch", "resume", "status", "exercise", "refinement", "undo", "scene", "changes", "change_edges", "close"])
    parser.add_argument("--base", type=Path, required=True)
    args = parser.parse_args()
    base = args.base.resolve()
    if not base.is_relative_to(ROOT / "build"):
        raise ValueError("Owned build directory required")
    if args.action == "launch":
        launch(base)
    elif args.action == "resume":
        resume(base)
    elif args.action == "exercise":
        exercise(base)
    elif args.action == "refinement":
        refinement(base)
    elif args.action == "undo":
        from undo_campaign import run
        run(base)
    elif args.action == "scene":
        from scene_campaign import run
        asyncio.run(run(base))
    elif args.action == "changes":
        asyncio.run(change_campaign(base))
    elif args.action == "change_edges":
        asyncio.run(change_campaign(base, edges=True))
    elif args.action == "close":
        close_owned(base / "host01")
    else:
        print(json.dumps({"pid": verify_owned(base / "host01")["pid"], "ready": (base / "host01/foundation-ready.json").exists()}))
