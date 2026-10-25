"""Immediate native reset invalidation and panel-close reference release."""
import asyncio
import json
from pathlib import Path
import sys
import uuid

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification, verify_owned
from compatibility_host import bind_suite


async def run(base):
    q=qualification(base)
    meta=bind_suite(q.folder,{"scene-lifecycle-driver":Path(__file__)})
    receipt=q.folder/("scene-lifecycle-"+uuid.uuid4().hex+".json")
    result={"status":"running","pid":meta["pid"],"run_id":meta["run_id"],"artifact_id":meta["artifact_id"],
            "qualification":"Owned Max system reset callback and widget state before client refresh; not artist/task acceptance."}
    def save():receipt.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    try:
        initial=q.local("scene_fixture")
        plane=next(c["object_id"] for c in initial["objects"] if c["object_type"]=="Plane")
        q.local("scene_brief",brief="Keep this task until scene reset")
        q.local("scene_role",role="receiver",object_ids=[plane])
        before=q.local("scene_ui")
        assert before["enabled"] and before["details_enabled"] and before["brief"]
        reset=q.local("scene_event_reset")
        result.update(before=before,immediate_reset=reset);save()
        assert reset==dict(scope=None,task=None,references=0,details_enabled=False,dialog_enabled=False,table_rows=0,brief="",status="Scene changed; choose a new scope.")
        code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
        params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
        async with Client(params) as client:
            response=await client.call_tool("scene_get_context",{"scope_id":initial["scope_id"]})
            assert response.is_error,response
            response=await client.call_tool("connection_get_status",{})
            assert not response.is_error and response.structured_content["scope_id"] is None
            result["connection_after_reset"]=response.structured_content
        q.local("setup")
        q.local("scene_fixture")
        closed=q.local("scene_panel_close")
        result["closed"]=closed;save()
        assert closed==dict(references=0,task=None,bridge_closed=True)
        verify_owned(q.folder)
        result["status"]="passed";save()
        print(json.dumps({"passed":True,"receipt":str(receipt),"immediate_reset":True,"close_release":True}),flush=True)
    except BaseException as exc:
        result.update(status="failed",error=str(exc));save();raise


if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base",type=Path,required=True)
    args=parser.parse_args()
    asyncio.run(run(args.base.resolve()))
