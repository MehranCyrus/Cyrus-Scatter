"""Installed discovery -> approved source copies -> same-task native planting/export."""
import argparse
import asyncio
import json
from pathlib import Path
import sys
import time
import uuid
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification,verify_owned
from compatibility_host import bind_suite
from installed_sources_campaign import CONTENT


async def run(base):
    q=qualification(base);path=q.folder/"installed-planting.json"
    assert not path.exists(),"Observe original receipt/operations before another run"
    meta=bind_suite(q.folder,{"installed-planting-driver":Path(__file__)})
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],
        qualification="Owned Max 2027 + real external SDK; scripted local permission/design/approval. Not physical artist consent, flower-zone authoring or rendered material equivalence.")
    def save():path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    save()
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        q.local("setup");ctx=q.local("prepared_source_task")
        for role,kind in (("receiver","Plane"),("boundary","SplineShape")):
            q.local("scene_role",role=role,object_ids=[next(row["object_id"] for row in ctx["scope"]["snapshot"]["objects"] if row["object_type"]==kind)])
        task_id=ctx["task"]["task_id"]
        q.local("scene_brief",brief="Create two editable layers of grass and flowers from installed library models")
        q.local("catalog_fixture",root=str(CONTENT));catalog=q.local("catalog_share")["grant"]
        permission=q.local("installed_source_enable")["permission"]
        async with Client(params) as client:
            async def call(name,**args):
                verify_owned(q.folder);response=await client.call_tool(name,args);verify_owned(q.folder)
                assert not response.is_error,response
                return response.structured_content
            async def apply(value,source=False):
                q.local("prepared_source_approve" if source else "approve",validation_id=value["validation_id"])
                args={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
                args["idempotency_key"]="installed_planting_"+uuid.uuid4().hex
                queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
                while True:
                    record=(await call("scatter_get_status",scene_epoch=value["scene_epoch"],operation_id=queued["operation"]["operation_id"]))["operation"]
                    if record["state"] not in ("queued","running"):break
                    assert time.monotonic()<deadline,"Observe original operation; never replay";await asyncio.sleep(.3)
                assert record["state"]=="succeeded" and record["effects"]=="committed",record
                assert (await call("scatter_apply_plan",**args))["operation"]==record
                return record
            refs=[]
            for identity in ("A069","A062"):
                row=await call("library_search",scope_id=ctx["scope"]["scope_id"],library_id=catalog["library_id"],query=identity)
                assert row["total_matches"]==1;refs.append(row["entries"][0]["asset_ref"])
            await call("assets_prepare_sources",scope_id=ctx["scope"]["scope_id"],library_id=catalog["library_id"],permission_id=permission["permission_id"],
                       asset_refs=refs,request_key="plants_"+uuid.uuid4().hex)
            deadline=time.monotonic()+60
            while True:
                connection=await call("connection_get_status")
                if connection["prepared_sources"]["status"]!="preparing":break
                assert time.monotonic()<deadline,"Observe original preparation";await asyncio.sleep(.3)
            assert connection["prepared_sources"]["status"]=="ready",connection
            ctx=await call("scene_get_context",scope_id=connection["scope_id"])
            use=dict(use_schema="cyrus.asset-use/1.0",scope_id=ctx["scope"]["scope_id"],task_id=task_id,task_revision=ctx["task"]["task_revision"],
                grant_id=ctx["prepared_sources"]["grant_id"],asset_refs=[row["asset_ref"] for row in ctx["prepared_sources"]["entries"]],destination="task_sources")
            imported=await apply(await call("assets_validate_use",use=use),source=True);result["import"]=imported;save()
            after=await call("scene_get_context",scope_id=connection["scope_id"])
            assert after["task"]["task_id"]==task_id and all(after["task"]["roles"][row["object_id"]]==["source"] for row in imported["result"]["sources"])
            review=q.local("task_prepare_grant");q.local("task_connect_grant",review_id=review["review_id"],digest=review["digest"])
            connection=await call("connection_get_status");ctx=await call("scene_get_context",scope_id=connection["scope_id"])
            assert ctx["task"]["task_id"]==task_id and not connection["installed_source_permission"]["enabled"]
            assert q.local("prepared_source_state")["retained_native_packages"]==0
            source_ids=[next(row["source_id"] for row in ctx["scope"]["sources"] if row["task_object_id"]==item["object_id"]) for item in imported["result"]["sources"]]
            plan=q.plan(ctx,count=80,layers=2);plan["name"]="Installed grass and flowers"
            for layer,name,identity in zip(plan["layers"],("Grass","Flowers"),source_ids):layer.update(name=name,sources=[dict(source_id=identity,weight=1)])
            planted=await apply(await call("scatter_validate_plan",plan=plan))
            exported=await call("scatter_export_record",scene_epoch=planted["scene_epoch"],controller_id=planted["result"]["controller_id"],generation_id=planted["result"]["generation_id"])
            rows=exported["record"]["layout"]["instances"]
            assert len(rows)==planted["result"]["emitted"]>0 and all(layer["emitted"]>0 for layer in planted["result"]["layers"])
            result.update(status="passed",same_task_id=task_id,design=planted,exported_rows=len(rows),plan=exported["record"]["plan"]);save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status="passed",emitted=result["exported_rows"],artifact_id=meta["artifact_id"])),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("--base",type=Path,required=True)
    asyncio.run(run(p.parse_args().base.resolve()))
