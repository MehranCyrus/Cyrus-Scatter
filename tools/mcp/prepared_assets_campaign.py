"""Real external MCP SDK -> local approval -> native prepared-source import/use."""
import argparse
import asyncio
import json
from pathlib import Path
import shutil
import sys
import time
import uuid
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT,HERE,qualification,resume,verify_owned,close_owned
from recipe_catalog_campaign import launch as launch_native
from compatibility_host import bind_suite

def launch(base):
    from package import stage_payload
    stage_payload(base/"payload",2027,ROOT/"build/mcp-prepared-sources-20261024-01",ROOT/"build/ui-edit-08691-20261023/analyzer-2027-02")
    launch_native(base)

async def run(base,api_only=False):
    q=qualification(base)
    package=base/"plant-package"
    if not package.exists():
        shutil.copytree(ROOT/"build/mcp-source-use-20261024-03/host01/portable-source-package",package)
        bad=base/"bad-package";shutil.copytree(package,bad)
        graph=json.loads((bad/"assets.json").read_text());graph["nodes"][0]["name"]="Changed without manifest update"
        (bad/"assets.json").write_text(json.dumps(graph))
    else:
        assert api_only,"Existing test state requires explicit inspected API-only rerun; do not replay uncertain operations"
        verify_owned(q.folder)
        journal=q.folder/"connection/operations.json"
        assert not journal.exists() or not json.loads(journal.read_text()),"Inspect existing operations before resetting this fixture"
        bad=base/"bad-package"
    inputs={"prepared-assets-driver":Path(__file__)}
    inputs.update({"prepared-content-"+str(i):p for i,p in enumerate([*package.rglob("*"),*bad.rglob("*")]) if p.is_file()})
    meta=bind_suite(q.folder,inputs)
    receipt=q.folder/"prepared-assets.json"
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=[],
                qualification="Owned Max 2027 + real SDK; scripted native widget approval is not physical artist consent, full material/render or complete M03 acceptance.")
    result["approval_mode"]="scripted_service_API_only" if api_only else "scripted_native_approval_widget"
    def save():receipt.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            assert len((await client.list_tools()).tools)==19
            async def call(name,expected=None,**args):
                verify_owned(q.folder);v=await client.call_tool(name,args);verify_owned(q.folder)
                if expected:assert v.is_error and v.structured_content["error"]["code"]==expected,v
                else:assert not v.is_error,v
                return v.structured_content
            async def task():
                q.local("setup");ctx=q.local("prepared_source_task")
                receiver=next(v["object_id"] for v in ctx["scope"]["snapshot"]["objects"] if v["object_type"]=="Plane")
                boundary=next(v["object_id"] for v in ctx["scope"]["snapshot"]["objects"] if v["object_type"]=="SplineShape")
                q.local("scene_role",role="receiver",object_ids=[receiver]);q.local("scene_role",role="boundary",object_ids=[boundary])
                q.local("scene_brief",brief="Grass and flowers using the prepared source assets")
                q.local("sentinel_create");q.local("sentinel_edit")
                q.local("prepared_source_share",directory=str(package))
                deadline=time.monotonic()+60
                while True:
                    c=await call("connection_get_status")
                    if c["prepared_sources"]["status"]!="preparing":break
                    assert time.monotonic()<deadline,"Observe the original preparation job before retrying"
                    await asyncio.sleep(.3)
                assert c["prepared_sources"]["status"]=="ready",c
                assert len(c["prepared_sources"]["entries"])==2
                return await call("scene_get_context",scope_id=c["scope_id"])
            def use(ctx):
                return dict(use_schema="cyrus.asset-use/1.0",scope_id=ctx["scope"]["scope_id"],task_id=ctx["task"]["task_id"],
                    task_revision=ctx["task"]["task_revision"],grant_id=ctx["prepared_sources"]["grant_id"],
                    asset_refs=[row["asset_ref"] for row in reversed(ctx["prepared_sources"]["entries"])],destination="task_sources")
            async def apply(value,approve=True):
                if approve:q.local("approve" if api_only else "prepared_source_approve",validation_id=value["validation_id"])
                args={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
                args["idempotency_key"]="source_use_"+uuid.uuid4().hex
                queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
                while True:
                    operation=(await call("scatter_get_status",scene_epoch=value["scene_epoch"],operation_id=queued["operation"]["operation_id"]))["operation"]
                    if operation["state"] not in ("queued","running"):break
                    assert time.monotonic()<deadline,"Observe original source operation; never replay with a new key"
                    await asyncio.sleep(.3)
                assert (await call("scatter_apply_plan",**args))["operation"]==operation
                return operation
            ctx=await task();q.local("prepared_source_auto_key",enabled=True)
            before=q.local("prepared_source_state");request=use(ctx)
            value=await call("assets_validate_use",use=request)
            denial={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")};denial["idempotency_key"]="denied_"+uuid.uuid4().hex
            await call("scatter_apply_plan",expected="APPROVAL_REQUIRED",**denial)
            assert q.local("prepared_source_state")==before
            operation=await apply(value);assert operation["state"]=="succeeded",operation
            after=q.local("prepared_source_state")
            assert after["nodes"]==before["nodes"]+2 and after["applications"]==0 and after["selected"]==before["selected"]
            assert after["undo"][1:]==before["undo"]
            assert after["auto_key"]==before["auto_key"]==True and after["time"]==before["time"]
            current=await call("scene_get_context",scope_id=ctx["scope"]["scope_id"])
            assert current["task"]["task_id"]==ctx["task"]["task_id"]
            ids=[row["object_id"] for row in operation["result"]["sources"]]
            assert all(current["task"]["roles"][oid]==["source"] for oid in ids)
            measured=await call("scene_measure_objects",scope_id=ctx["scope"]["scope_id"],object_ids=ids,purpose="source")
            assert sorted(row["triangles"] for row in measured["measurements"])==[4360,17110]
            assert [r["asset_ref"] for r in operation["result"]["sources"]]==request["asset_refs"]
            expected_geometry={r["asset_ref"]:r["geometry"]["triangles"] for r in ctx["prepared_sources"]["entries"]}
            assert all(r["geometry"]["triangles"]==expected_geometry[r["asset_ref"]] for r in operation["result"]["sources"])
            await call("assets_validate_use",expected="BUDGET_EXCEEDED",use=use(current))
            undone=q.local("undo_receipt")
            assert undone["operation"]["state"]=="succeeded" and undone["operation"]["result"]["removed_created_nodes"]==2,undone
            q.local("redo")
            redone=q.local("prepared_source_receipt_check",sources=operation["result"]["sources"])
            result["cases"].append(dict(case="approved_sources_same_task_and_verified_undo",operation=operation,undo=undone,redo=redone,before=before,after=after,measured=measured));save()
            # Qualify an actual failure after both sources have been staged.
            ctx=await task();before=q.local("prepared_source_state");q.local("fault",phase="asset_after_stage")
            failed=await apply(await call("assets_validate_use",use=use(ctx)))
            q.local("fault",phase=None)
            assert failed["state"]=="failed" and failed["effects"]=="verified_rollback",failed
            assert q.local("prepared_source_state")==before
            result["cases"].append(dict(case="post_stage_failure",operation=failed));save()
            # Continue the same task after a verified rollback, with new approval.
            operation=await apply(await call("assets_validate_use",use=use(ctx)))
            assert operation["state"]=="succeeded",operation
            task_id=ctx["task"]["task_id"]
            review=q.local("task_prepare_grant");q.local("task_connect_grant",review_id=review["review_id"],digest=review["digest"])
            c=await call("connection_get_status");design=await call("scene_get_context",scope_id=c["scope_id"])
            assert design["task"]["task_id"]==task_id and not c["prepared_sources"]["shared"]
            assert not q.local("prepared_source_state")["asset_token"]
            plan=q.plan(design,count=80,layers=2)
            for layer,source in zip(plan["layers"],design["scope"]["sources"]):
                layer.update(name=source["label"],sources=[dict(source_id=source["source_id"],weight=1)])
            validation=await call("scatter_validate_plan",plan=plan)
            q.local("approve",validation_id=validation["validation_id"])
            generated=await apply(validation,approve=False)
            assert generated["state"]=="succeeded",generated
            exported=await call("scatter_export_record",scene_epoch=validation["scene_epoch"],controller_id=generated["result"]["controller_id"],generation_id=generated["result"]["generation_id"])
            assert len(exported["record"]["layout"]["instances"])==generated["result"]["emitted"]
            result["cases"].append(dict(case="prepared_sources_native_design_use",imported=operation,generated=generated));save()
            # A changed graph without the declared hash cannot become a ready grant.
            q.local("setup");q.local("prepared_source_task")
            before=q.local("prepared_source_state");q.local("prepared_source_share",directory=str(bad))
            deadline=time.monotonic()+30
            while True:
                c=await call("connection_get_status")
                if c["prepared_sources"]["status"]!="preparing":break
                assert time.monotonic()<deadline;await asyncio.sleep(.3)
            assert c["prepared_sources"]["status"]=="failed",c
            after=q.local("prepared_source_state")
            assert (before["nodes"],before["scope"],before["selected"],before["undo"])==(after["nodes"],after["scope"],after["selected"],after["undo"])
            assert not after["asset_token"]
            result["cases"].append(dict(case="tampered_graph_denied",status=c["prepared_sources"]));save()
            # Known committed assets must survive a later completion fault honestly.
            ctx=await task();before=q.local("prepared_source_state");q.local("fault",phase="asset_after_native_commit")
            committed=await apply(await call("assets_validate_use",use=use(ctx)))
            q.local("fault",phase=None)
            assert committed["state"]=="failed" and committed["effects"]=="committed" and committed["recovery_required"],committed
            assert committed["result"]["selection_preserved"] is None and committed["commit_identity"]["asset_use_id"]==committed["result"]["asset_use_id"]
            assert q.local("prepared_source_state")["nodes"]==before["nodes"]+2
            c=await call("connection_get_status");assert c["recovery_required"]
            await call("assets_validate_use",expected="OUTCOME_UNKNOWN",use=use(ctx))
            inspected=q.local("prepared_source_receipt_check",sources=committed["result"]["sources"])
            review=q.local("review_recovery",operation_id=committed["operation_id"])
            reviewed=q.local("prepared_source_state")
            retired=q.local("confirm_recovery",review_id=review["review_id"],digest=review["digest"])
            assert retired["recovery_required"] is False
            assert q.local("prepared_source_state")["nodes"]==reviewed["nodes"]
            historical=(await call("scatter_get_status",scene_epoch=committed["scene_epoch"],operation_id=committed["operation_id"]))["operation"]
            assert historical["effects"]=="committed" and historical["resolution"]["status"]=="locally_retired"
            result["cases"].append(dict(case="post_commit_completion_fault",operation=committed,new_writes_blocked=True,
                                        inspected=inspected,review=review,retired=retired,scene_nodes_preserved=True));save()
        result.update(status="passed");save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status="passed",cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=("launch","resume","exercise","close"));p.add_argument("--base",type=Path,required=True)
    p.add_argument("--api-only",action="store_true",help="Private API qualification while an already-observed review-text defect remains open")
    a=p.parse_args();base=a.base.resolve()
    if a.action=="launch":launch(base)
    elif a.action=="resume":resume(base)
    elif a.action=="exercise":asyncio.run(run(base,a.api_only))
    else:close_owned(base/"host01")
