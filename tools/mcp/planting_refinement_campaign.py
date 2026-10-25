"""Refine only the flower candidate budget in the existing owned SDK task."""
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

async def run(base):
    q=qualification(base);meta=bind_suite(q.folder,{"planting-refinement-driver":Path(__file__)})
    original=json.loads((q.folder/"planting-sources.json").read_text())
    owner=original["operation"]["result"]
    before=q.local("publication_snapshot",controller_id=owner["controller_id"])
    grass,flower=[v["layer_id"] for v in owner["layers"]]
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    async with Client(params) as client:
        async def call(name,**args):
            verify_owned(q.folder);v=await client.call_tool(name,args);verify_owned(q.folder);assert not v.is_error,v;return v.structured_content
        connection=await call("connection_get_status")
        context=await call("scene_get_context",scope_id=connection["scope_id"])
        change=dict(change_schema="cyrus.owned-change/1.0",context_id=context["context_id"],controller_id=owner["controller_id"],
                    generation_id=owner["generation_id"],configuration_id=owner["configuration_id"],mode="configure_and_update",
                    layers=[dict(layer_id=flower,count=700)])
        validated=await call("scatter_validate_change",change=change)
        q.local("approve",validation_id=validated["validation_id"])
        args={key:validated[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
        args["idempotency_key"]="flowers_"+uuid.uuid4().hex
        queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
        while True:
            operation=(await call("scatter_get_status",scene_epoch=validated["scene_epoch"],operation_id=queued["operation"]["operation_id"]))["operation"]
            if operation["state"] not in ("queued","running"):break
            assert time.monotonic()<deadline,"Observe original operation before any replay"
            await asyncio.sleep(.3)
        assert operation["state"]=="succeeded",operation
        after=q.local("publication_snapshot",controller_id=owner["controller_id"])
        assert after["layer_ids"]==before["layer_ids"]
        assert [v for v in before["rows"] if v["layer_id"]==grass]==[v for v in after["rows"] if v["layer_id"]==grass]
        assert operation["result"]["layers"][1]["emitted"]>owner["layers"][1]["emitted"]
        exported=await call("scatter_export_record",scene_epoch=validated["scene_epoch"],controller_id=owner["controller_id"],generation_id=operation["result"]["generation_id"])
        assert len(exported["record"]["layout"]["instances"])==operation["result"]["emitted"]
        assert [v["region_id"] for v in exported["record"]["plan"]["layers"]]==[v["region_id"] for v in original["plan"]["layers"]]
        result=dict(status="passed",pid=meta["pid"],artifact_id=meta["artifact_id"],change=change,operation=operation,
                    grass_rows_unchanged=True,layer_ids_unchanged=True,regions_unchanged=True,before=before,after=after,
                    qualification="Scripted local approval; explicit sources and picked convex flower patch. Counts are whole-receiver candidate budgets filtered by region, not exact per-zone targets or density.")
        (q.folder/"planting-refinement.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
        print(json.dumps(dict(status="passed",layers=operation["result"]["layers"],artifact_id=meta["artifact_id"])),flush=True)

if __name__=="__main__":
    import argparse
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("--base",type=Path,required=True)
    asyncio.run(run(p.parse_args().base.resolve()))
