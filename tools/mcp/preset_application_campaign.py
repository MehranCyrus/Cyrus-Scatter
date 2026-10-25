"""Matched native preset prerequisite with SDK inspection; not public preset writes."""
import argparse
import asyncio
import json
import importlib.metadata
from pathlib import Path
import shutil
import sys
import time
import uuid
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT,HERE,qualification,resume,verify_owned,close_owned,run_case
from recipe_catalog_campaign import launch as launch_native
from compatibility_host import bind_suite


def launch(base):
    from package import stage_payload
    stage_payload(base/"payload",2027,ROOT/"build/mcp-preset-transactions-20261024-02",ROOT/"build/ui-edit-08691-20261023/analyzer-2027-02")
    launch_native(base)


async def exercise(base):
    path=base/"host01/preset-application.json";assert not path.exists(),"Observe the original request and receipt before replay"
    q=qualification(base);module=base/"fixtures/preset_application_host.py";probe=base/"fixtures/preset_curve_probe.ms";driver=base/"fixtures/preset_application_campaign.py"
    shutil.copy2(HERE/module.name,module);shutil.copy2(HERE/probe.name,probe);shutil.copy2(Path(__file__),driver)
    meta=bind_suite(q.folder,{"preset-application-driver":driver,"preset-application-module":module,
        "preset-curve-probe":probe,"preset-application-clean":HERE/"scene_passive.ms"})
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=[],external_python=sys.version,mcp_sdk=importlib.metadata.version("mcp"),
        qualification="Native preset transaction/evaluator prerequisite; actual external SDK creates and inspects owned setup. Native category changes use private local scripted probes, not a public MCP preset application or physical artist consent.")
    def save():path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    save();q.local("setup",kind=1)
    params=StdioServerParameters(command=sys.executable,args=["-c","import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()","--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            assert len((await client.list_tools()).tools)==23
            async def call(name,**args):
                verify_owned(q.folder);response=await client.call_tool(name,args);verify_owned(q.folder)
                assert not response.is_error,response.structured_content
                return response.structured_content
            connection=await call("connection_get_status");epoch=connection["scene_epoch"]
            context=await call("scene_get_context",scope_id=connection["scope_id"])
            plan=q.plan(context,count=100,layers=2);plan["name"]="Owned native preset transactions"
            validation=await call("scatter_validate_plan",plan=plan);q.local("approve",validation_id=validation["validation_id"])
            args={key:validation[key] for key in ("validation_id","digest","scene_epoch","scene_revision")};args["idempotency_key"]="preset_native_"+uuid.uuid4().hex
            queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
            while True:
                operation=(await call("scatter_get_status",scene_epoch=epoch,operation_id=queued["operation"]["operation_id"]))["operation"]
                if operation["state"] not in ("queued","running"):break
                assert time.monotonic()<deadline,"Observe the original owned operation";await asyncio.sleep(.3)
            assert operation["state"]=="succeeded",operation
            result["creation"]=operation;save()
            cid=operation["result"]["controller_id"]
            parity=q.local("preset_apply_parity");result["cases"].append(dict(case="native_vs_artist_curve_control",result=parity));save()
            run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],entrypoint="MCPScenePassiveRun",timeout=30)
            passive=q.local("preset_apply_passive",controller_id=cid);result["cases"].append(dict(case="passive_preparation_and_outer_hold",result=passive));save()
            rejected=q.local("preset_apply_reject",controller_id=cid);result["cases"].append(dict(case="incompatible_curve_rejected_before_mutation",result=rejected));save()
            for category in ("population","transforms","spacing","density_curve","scale_curve"):
                applied=q.local("preset_apply_category",controller_id=cid,category=category)
                settings=await call("scatter_get_settings",scene_epoch=epoch,controller_id=cid,layer_id=applied["layer_id"],categories=[category])
                actual=settings["settings"]["categories"][0]
                assert actual["exportable_as_preset"],actual
                if category in ("density_curve","scale_curve"):
                    assert len(actual["stored_samples"])==257 and actual["preset_document"]["values"]["graph"]
                    assert not actual["enabled"],"Applying a curve must not enable its target"
                else:assert actual["preset_document"]["values"]==applied["document"]["values"]
                result["cases"].append(dict(case="native_"+category+"_application",probe=applied,external_sdk_settings=settings));save()
            restored=q.local("preset_apply_editor_restore",controller_id=cid)
            result["cases"].append(dict(case="ordinary_editor_restores_uneven_five_point_graph",probe=restored));save()
            precise=q.local("preset_apply_precision_roundtrip",controller_id=cid)
            result["cases"].append(dict(case="nontrivial_float_curve_capture_roundtrip",probe=precise));save()
            legacy=q.local("preset_apply_legacy_browse",controller_id=cid)
            result["cases"].append(dict(case="older_graph_browse_preserves_stored_data",probe=legacy));save()
            edited=q.local("preset_apply_editor_edit",controller_id=cid)
            result["cases"].append(dict(case="ordinary_editor_still_authors_and_undoes",probe=edited));save()
            editor_preset=q.local("preset_apply_editor_preset",controller_id=cid)
            result["cases"].append(dict(case="ordinary_editor_preset_and_failed_prepare_rollback",probe=editor_preset));save()
            for name in ("guards","commit","rollback"):
                composed=q.local("preset_apply_caller_"+name,controller_id=cid)
                result["cases"].append(dict(case="caller_transaction_"+name,probe=composed));save()
            result["status"]="passed";save()
        print(json.dumps(dict(status=result["status"],cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=("launch","resume","exercise","close"));p.add_argument("--base",type=Path,required=True)
    args=p.parse_args();base=args.base.resolve()
    if args.action=="launch":launch(base)
    elif args.action=="resume":resume(base)
    elif args.action=="exercise":asyncio.run(exercise(base))
    else:close_owned(base/"host01")
