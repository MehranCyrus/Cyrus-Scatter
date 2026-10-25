"""Real grass/flower source nodes and regional native publication through SDK."""
import asyncio
import json
from pathlib import Path
import shutil
import sys
import time
import uuid
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification,verify_owned,run_case,HERE,ROOT
from compatibility_host import bind_suite


async def run(base):
    q=qualification(base);module=q.folder/"planting_source_setup.py";shutil.copy2(HERE/"planting_source_setup.py",module)
    config=q.folder/"planting-source-input.json";config.write_text(json.dumps(dict(library_root=str(ROOT/"dist/CyrusScatter-0.86.7-20261020/Content/Library")))+"\n")
    meta=bind_suite(q.folder,{"planting-sources-driver":Path(__file__),"planting-sources-module":module,
                              "planting-sources-script":HERE/"planting_source_setup.ms","planting-sources-input":config})
    q.local("setup")
    fixture=q.local("planting_sources_fixture");ids=fixture["model_object_ids"]
    plane=next(c["object_id"] for c in fixture["objects"] if c["object_type"]=="Plane")
    boundaries=[c["object_id"] for c in fixture["objects"] if c["object_type"]=="SplineShape"]
    q.local("scene_role",role="receiver",object_ids=[plane]);q.local("scene_role",role="source",object_ids=list(ids.values()))
    q.local("scene_role",role="boundary",object_ids=boundaries)
    q.local("scene_brief",brief="Grass in the planting region; flowers only in the picked central patch")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    async with Client(params) as client:
        async def call(name,**args):
            verify_owned(q.folder);response=await client.call_tool(name,args);verify_owned(q.folder);assert not response.is_error,response;return response.structured_content
        measured=await call("scene_measure_objects",scope_id=fixture["scope_id"],object_ids=list(ids.values()),purpose="source")
        review=q.local("task_prepare_grant");q.local("task_connect_grant",review_id=review["review_id"],digest=review["digest"])
        connection=await call("connection_get_status");context=await call("scene_get_context",scope_id=connection["scope_id"])
        source_ids={key:next(s["source_id"] for s in context["scope"]["sources"] if s["task_object_id"]==oid) for key,oid in ids.items()}
        grass_region=next(r["region_id"] for r in context["scope"]["regions"] if r["label"]=="MCP Planting")
        flower_region=next(r["region_id"] for r in context["scope"]["regions"] if r["label"]=="Owned flower patch")
        plan=q.plan(context,count=100,layers=2);plan["name"]="Grass and central flower patch"
        for layer,key,name,count,region in zip(plan["layers"],("A069","A062"),("Grass","Flowers"),(100,40),(grass_region,flower_region)):
            layer.update(name=name,count=count,region_id=region,sources=[dict(source_id=source_ids[key],weight=1)])
        validated=await call("scatter_validate_plan",plan=plan);q.local("approve",validation_id=validated["validation_id"])
        args={key:validated[key] for key in ("validation_id","digest","scene_epoch","scene_revision")};args["idempotency_key"]="planting_"+uuid.uuid4().hex
        queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
        while True:
            operation=(await call("scatter_get_status",scene_epoch=validated["scene_epoch"],operation_id=queued["operation"]["operation_id"]))["operation"]
            if operation["state"] not in ("queued","running"):break
            assert time.monotonic()<deadline;await asyncio.sleep(.3)
        assert operation["state"]=="succeeded",operation
        export=await call("scatter_export_record",scene_epoch=validated["scene_epoch"],controller_id=operation["result"]["controller_id"],generation_id=operation["result"]["generation_id"])
        assert len(export["record"]["layout"]["instances"])==operation["result"]["emitted"]
        assert [x["region_id"] for x in export["record"]["plan"]["layers"]]==[grass_region,flower_region]
        result=dict(status="passed",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],measurements=measured,
                    plan=export["record"]["plan"],operation=operation,exported_count=len(export["record"]["layout"]["instances"]),
                    qualification="Owned explicit-source SDK/native slice with actual convex flower region. Local fixture import is not MCP import; scripted approval is not artist consent or full M04 acceptance.")
        (q.folder/"planting-sources.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(dict(status="passed",emitted=operation["result"]["emitted"],artifact_id=meta["artifact_id"])),flush=True)


if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--base",type=Path,required=True)
    asyncio.run(run(parser.parse_args().base.resolve()))
