"""Native high-detail source inspection/design and measured library import boundary."""
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
from foundation_campaign import ROOT,HERE,qualification,verify_owned,run_case,resume,close_owned
from recipe_catalog_campaign import launch as launch_native
from compatibility_host import bind_suite


def launch(base):
    from package import stage_payload
    stage_payload(base/"payload",2027,ROOT/"build/mcp-source-metadata-20261024-03",ROOT/"build/ui-edit-08691-20261023/analyzer-2027-02")
    launch_native(base)


async def run(base):
    q=qualification(base)
    module=base/"fixtures/source_use_host.py";shutil.copy2(HERE/"source_use_host.py",module)
    meta=bind_suite(q.folder,{"source-use-driver":Path(__file__),"source-use-module":module,"source-use-qualifier":HERE/"qualify.py"})
    path=q.folder/"source-use-results.json"
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=[],
                scope="Owned Max 2027 / real SDK; native source geometry and explicit local import measurement only. No remote asset import/approval or artist consent.")
    def save():path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        q.local("setup");fixture=q.local("source_use_fixture")
        async with Client(params) as client:
            async def call(name,expected=None,**args):
                verify_owned(q.folder);response=await client.call_tool(name,args);verify_owned(q.folder)
                value=response.structured_content
                if expected:assert response.is_error and value["error"]["code"]==expected,value
                else:assert not response.is_error,value
                return value
            connection=await call("connection_get_status");scope=connection["scope_id"]
            assert connection["host"]["source_measurement_api"]==1
            source=next(c["object_id"] for c in fixture["objects"] if c["object_type"].lower()=="editable_mesh")
            receiver=next(c["object_id"] for c in fixture["objects"] if c["object_type"]=="Plane")
            q.local("scene_role",role="source",object_ids=[source]);q.local("scene_role",role="receiver",object_ids=[receiver])
            run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],timeout=30,entrypoint="MCPScenePassiveRun")
            before=q.local("scene_state")
            await call("scene_measure_objects",expected="BUDGET_EXCEEDED",scope_id=scope,object_ids=[source])
            measured=await call("scene_measure_objects",scope_id=scope,object_ids=[source],purpose="source")
            value=measured["measurements"][0]
            assert value["triangles"]>10000 and abs(value["source_geometry"]["height_m"]-.8)<1e-5
            assert abs(value["source_geometry"]["radius_xy_from_pivot_m"]-.5)<1e-5
            assert not value["receiver_geometry"]["eligible"]
            assert q.local("scene_state")==before and not before["save_required"]
            q.local("source_use_edit")
            edited=await call("scene_measure_objects",scope_id=scope,object_ids=[source],purpose="source")
            assert edited["measurements"][0]["source_geometry"]["source_geometry_sha256"]!=value["source_geometry"]["source_geometry_sha256"]
            q.local("source_use_zero_offset")
            zero=await call("scene_measure_objects",scope_id=scope,object_ids=[source],purpose="source")
            q.local("source_use_move")
            moved=await call("scene_measure_objects",scope_id=scope,object_ids=[source],purpose="source")
            assert moved["measurements"][0]["source_geometry"]["source_geometry_sha256"]==zero["measurements"][0]["source_geometry"]["source_geometry_sha256"]
            assert moved["measurements"][0]["geometry_world_sha256"]!=zero["measurements"][0]["geometry_world_sha256"]
            result["cases"].append(dict(case="native_source_only_inspection",status="passed",measurement=value,before=before,
                                        vertex_change_detected=True,local_hash_stable_without_object_offset=True,world_change_detected=True))
            review=q.local("task_prepare_grant");q.local("task_connect_grant",review_id=review["review_id"],digest=review["digest"])
            current=await call("connection_get_status");ctx=await call("scene_get_context",scope_id=current["scope_id"])
            assert ctx["scope"]["sources"][0]["measurement_method"]=="native_baked_mesh"
            plan=q.plan(ctx,count=80,layers=2)
            validation=await call("scatter_validate_plan",plan=plan);q.local("approve",validation_id=validation["validation_id"])
            args={key:validation[key] for key in ("validation_id","digest","scene_epoch","scene_revision")};args["idempotency_key"]="native_source_"+uuid.uuid4().hex
            queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
            while True:
                operation=(await call("scatter_get_status",scene_epoch=validation["scene_epoch"],operation_id=queued["operation"]["operation_id"]))["operation"]
                if operation["state"] not in ("queued","running"):break
                assert time.monotonic()<deadline,"Observe original operation; never replay with a new key"
                await asyncio.sleep(.3)
            assert operation["state"]=="succeeded",operation
            exported=await call("scatter_export_record",scene_epoch=validation["scene_epoch"],controller_id=operation["result"]["controller_id"],generation_id=operation["result"]["generation_id"])
            assert exported["record"]["receipt"]["emitted"]==operation["result"]["emitted"]
            assert len(exported["record"]["layout"]["instances"])==operation["result"]["emitted"]
            result["cases"].append(dict(case="native_source_design_and_publication",status="passed",source=ctx["scope"]["sources"][0],operation=operation))
        q.local("source_use_restore")
        probes=[]
        for root,entry_id in ((ROOT/"build/viewport-0867-20261020/standard-fixture/Library","A027"),
                              (ROOT/"dist/CyrusScatter-0.86.7-20261020/Content/Library","A069"),
                              (ROOT/"dist/CyrusScatter-0.86.7-20261020/Content/Library","A062")):
            q.local("setup")
            probes.append(q.local("source_use_import",root=str(root),entry_id=entry_id))
        result["cases"].append(dict(case="existing_native_import_measurements",status="measured",probes=probes))
        result["status"]="passed";save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status=result["status"],cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("action",choices=("launch","resume","exercise","close"));parser.add_argument("--base",type=Path,required=True)
    args=parser.parse_args();base=args.base.resolve()
    if args.action=="launch":launch(base)
    elif args.action=="resume":resume(base)
    elif args.action=="exercise":asyncio.run(run(base))
    else:close_owned(base/"host01")
