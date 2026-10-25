"""Real SDK / owned Max 2027 installed selection, multi-package import and rollback."""
import argparse
import asyncio
import json
from pathlib import Path
import sys
import time
import uuid
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT,qualification,resume,verify_owned,close_owned
from recipe_catalog_campaign import launch as launch_native
from compatibility_host import bind_suite

CONTENT=ROOT/"build/mcp-installed-models-20261024-01/Library"
MANUAL=ROOT/"build/mcp-source-use-20261024-03/host01/portable-source-package"


def launch(base):
    from package import stage_payload
    stage_payload(base/"payload",2027,ROOT/"build/mcp-retained-sources-20261024-01",ROOT/"build/ui-edit-08691-20261023/analyzer-2027-02")
    launch_native(base)


async def run(base):
    q=qualification(base)
    binding={"installed-sources-driver":Path(__file__),"installed-source-index":CONTENT/"prepared-sources.json",
             "installed-source-catalog":CONTENT/"model-catalog.json"}
    for identity in ("A062","A068","A069"):
        binding.update({"installed-"+identity+"-"+str(i):path for i,path in enumerate((CONTENT/"PreparedModels"/identity/"package").rglob("*")) if path.is_file()})
    binding.update({"manual-source-"+str(i):path for i,path in enumerate(MANUAL.rglob("*")) if path.is_file()})
    meta=bind_suite(q.folder,binding)
    receipt=q.folder/"installed-sources.json"
    assert not receipt.exists(),"Observe existing requests/receipts; never replay a campaign after observation timeout"
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=[],
        qualification="Owned Max 2027 / real external MCP SDK; scripted local permission/approval widgets, not physical artist consent or rendered material equivalence")
    def save():receipt.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    save()
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            tools=await client.list_tools();assert len(tools.tools)==20
            result["tools"]=[tool.name for tool in tools.tools]
            async def call(name,expected=None,**args):
                verify_owned(q.folder);response=await client.call_tool(name,args);verify_owned(q.folder)
                value=response.structured_content
                if expected:assert response.is_error and value["error"]["code"]==expected,value
                else:assert not response.is_error,value
                return value
            async def task():
                q.local("setup");ctx=q.local("prepared_source_task")
                receiver=next(row["object_id"] for row in ctx["scope"]["snapshot"]["objects"] if row["object_type"]=="Plane")
                q.local("scene_role",role="receiver",object_ids=[receiver]);q.local("scene_brief",brief="Plant grass and flowers from installed library sources")
                q.local("sentinel_create");q.local("sentinel_edit")
                q.local("catalog_fixture",root=str(CONTENT));shared=q.local("catalog_share")
                assert shared["grant"]["entry_count"]==96 and shared["grant"]["prepared_entries"]==13
                connection=await call("connection_get_status")
                refs=[]
                for identity in ("A062","A068","A069"):
                    rows=await call("library_search",scope_id=connection["scope_id"],library_id=shared["grant"]["library_id"],query=identity)
                    assert rows["total_matches"]==1 and rows["entries"][0]["prepared_source"]["status"]=="prepared"
                    refs.append(rows["entries"][0]["asset_ref"])
                args=dict(scope_id=connection["scope_id"],library_id=shared["grant"]["library_id"],permission_id="not_enabled",
                          asset_refs=refs,request_key="select_"+uuid.uuid4().hex)
                await call("assets_prepare_sources",expected="APPROVAL_REQUIRED",**args)
                permission=q.local("installed_source_enable")["permission"]
                args["permission_id"]=permission["permission_id"]
                return args
            async def ready(args):
                before=q.local("prepared_source_state")
                first=await call("assets_prepare_sources",**args)
                assert first["prepared_sources"]["status"]=="preparing"
                deadline=time.monotonic()+60
                while True:
                    connection=await call("connection_get_status")
                    if connection["prepared_sources"]["status"]!="preparing":break
                    assert time.monotonic()<deadline,"Observe original native preparation; do not issue a new request key"
                    await asyncio.sleep(.3)
                assert connection["prepared_sources"]["status"]=="ready",connection
                same=await call("assets_prepare_sources",**args)
                assert same["prepared_sources"]["grant_id"]==first["prepared_sources"]["grant_id"]
                assert connection["installed_source_permission"]["preparations_remaining"]==7
                after=q.local("prepared_source_state")
                assert after["nodes"]==before["nodes"] and after["undo"]==before["undo"] and after["scope"]==before["scope"]
                assert after["asset_tokens"]==after["retained_native_packages"]==3
                return await call("scene_get_context",scope_id=args["scope_id"])
            def use(ctx):
                return dict(use_schema="cyrus.asset-use/1.0",scope_id=ctx["scope"]["scope_id"],task_id=ctx["task"]["task_id"],
                    task_revision=ctx["task"]["task_revision"],grant_id=ctx["prepared_sources"]["grant_id"],
                    asset_refs=[row["asset_ref"] for row in reversed(ctx["prepared_sources"]["entries"])],destination="task_sources")
            async def apply(value):
                q.local("prepared_source_approve",validation_id=value["validation_id"])
                args={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
                args["idempotency_key"]="installed_use_"+uuid.uuid4().hex
                queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
                while True:
                    operation=(await call("scatter_get_status",scene_epoch=value["scene_epoch"],operation_id=queued["operation"]["operation_id"]))["operation"]
                    if operation["state"] not in ("queued","running"):break
                    assert time.monotonic()<deadline,"Observe original operation; do not replay"
                    await asyncio.sleep(.3)
                assert (await call("scatter_apply_plan",**args))["operation"]==operation
                return operation
            args=await task();ctx=await ready(args)
            assert [row["catalog_entry_id"] for row in ctx["prepared_sources"]["entries"]]==["A062","A068","A069"]
            q.local("prepared_source_auto_key",enabled=True);before=q.local("prepared_source_state")
            request=use(ctx);validation=await call("assets_validate_use",use=request)
            denial={key:validation[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
            await call("scatter_apply_plan",expected="APPROVAL_REQUIRED",**denial,idempotency_key="denied_"+uuid.uuid4().hex)
            operation=await apply(validation);assert operation["state"]=="succeeded" and operation["effects"]=="committed",operation
            after=q.local("prepared_source_state")
            assert after["nodes"]==before["nodes"]+3 and after["undo"][1:]==before["undo"] and after["selected"]==before["selected"]
            assert after["auto_key"]==before["auto_key"]==True and after["time"]==before["time"]
            assert [row["asset_ref"] for row in operation["result"]["sources"]]==request["asset_refs"]
            q.local("prepared_source_receipt_check",sources=operation["result"]["sources"])
            undone=q.local("undo_receipt");assert undone["operation"]["result"]["removed_created_nodes"]==3
            q.local("redo");redone=q.local("prepared_source_receipt_check",sources=operation["result"]["sources"])
            result["cases"].append(dict(case="three_installed_packages_one_approved_undo",operation=operation,before=before,after=after,undo=undone,redo=redone));save()
            args=await task();ctx=await ready(args);before=q.local("prepared_source_state")
            q.local("fault",phase="asset_after_package")
            failed=await apply(await call("assets_validate_use",use=use(ctx)));q.local("fault",phase=None)
            assert failed["state"]=="failed" and failed["effects"]=="verified_rollback",failed
            after=q.local("prepared_source_state")
            assert (before["nodes"],before["scope"],before["undo"],before["selected"])==(after["nodes"],after["scope"],after["undo"],after["selected"])
            result["cases"].append(dict(case="failure_after_first_package_staging",operation=failed,scene_and_history_preserved=True));save()
            q.local("installed_source_revoke");revoked=await call("connection_get_status")
            assert not revoked["installed_source_permission"]["enabled"] and not revoked["prepared_sources"]["shared"]
            released=q.local("prepared_source_state");assert released["asset_tokens"]==released["retained_native_packages"]==0
            await call("assets_prepare_sources",expected="APPROVAL_REQUIRED",**args)
            result["cases"].append(dict(case="permission_revoke_releases_all_handles",status=revoked));save()
            args=await task();await call("assets_prepare_sources",**args)
            q.local("scene_disconnect")
            disconnected=await call("connection_get_status")
            assert not disconnected["prepared_sources"]["shared"] and not disconnected["installed_source_permission"]["enabled"]
            released=q.local("prepared_source_state");assert released["asset_tokens"]==released["retained_native_packages"]==0
            result["cases"].append(dict(case="disconnect_releases_preparation_cohort",status=disconnected));save()
            q.local("setup");q.local("prepared_source_task")
            q.local("prepared_source_share",directory=str(MANUAL));deadline=time.monotonic()+60
            while True:
                connection=await call("connection_get_status")
                if connection["prepared_sources"]["status"]!="preparing":break
                assert time.monotonic()<deadline,"Observe original manual preparation";await asyncio.sleep(.3)
            assert connection["prepared_sources"]["status"]=="ready" and not connection["installed_source_permission"]["enabled"]
            assert q.local("prepared_source_state")["retained_native_packages"]==1
            ctx=await call("scene_get_context",scope_id=connection["scope_id"])
            manual=await apply(await call("assets_validate_use",use=use(ctx)))
            assert manual["state"]=="succeeded" and len(manual["result"]["sources"])==2,manual
            undone=q.local("undo_receipt");assert undone["operation"]["result"]["removed_created_nodes"]==2
            assert q.local("prepared_source_state")["retained_native_packages"]==0
            q.local("redo");q.local("prepared_source_receipt_check",sources=manual["result"]["sources"])
            result["cases"].append(dict(case="manual_two_source_package_with_retained_snapshot",operation=manual,undo=undone));save()
        result["status"]="passed";save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status=result["status"],cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=("launch","resume","exercise","close"));p.add_argument("--base",type=Path,required=True)
    a=p.parse_args();base=a.base.resolve()
    if a.action=="launch":launch(base)
    elif a.action=="resume":resume(base)
    elif a.action=="exercise":asyncio.run(run(base))
    else:close_owned(base/"host01")
