"""A clean-scene read witness, not just equal already-dirty flags."""
import asyncio
import json
from pathlib import Path
import sys
import uuid

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification, verify_owned, run_case
from compatibility_host import bind_suite


async def run(base):
    q=qualification(base)
    here=Path(__file__).resolve().parent
    meta=bind_suite(q.folder,{"scene-passive-driver":Path(__file__),"scene-passive-fixture":here/"scene_passive.ms"})
    receipt=q.folder/("scene-passive-"+uuid.uuid4().hex+".json")
    result={"status":"running","pid":meta["pid"],"run_id":meta["run_id"],"artifact_id":meta["artifact_id"],
            "qualification":"Owned Max/real SDK. Clean flag set by private fixed fixture; product calls remain read-only."}
    def save():receipt.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    try:
        q.local("setup")
        first=q.apply({**q.plan(q.context(),count=80),"display":{"mode":"mesh"}})
        assert first["state"]=="succeeded",first
        cid=first["result"]["controller_id"]
        q.local("publication_snapshot",controller_id=cid)
        initial=q.local("scene_fixture")
        plane=next(c["object_id"] for c in initial["objects"] if c["object_type"]=="Plane")
        before_save=q.local("publication_snapshot",controller_id=cid)
        run_case(q.folder,here/"scene_passive.ms","clean",["clean_before_reads"],timeout=30,entrypoint="MCPScenePassiveRun")
        # Existing native save hooks remove/recreate transient display owners.
        # Warm that independent lifecycle before the public-read comparison.
        published=q.local("publication_snapshot",controller_id=cid)
        before=q.local("scene_state")
        assert not before["save_required"]
        result.update(before=before,publication_before=published,publication_before_save=before_save);save()
        code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
        params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
        async with Client(params) as client:
            for name,args in (("scene_get_context",dict(scope_id=initial["scope_id"])),
                              ("scene_measure_objects",dict(scope_id=initial["scope_id"],object_ids=[plane]))):
                verify_owned(q.folder)
                response=await client.call_tool(name,args)
                verify_owned(q.folder)
                assert not response.is_error,response
                result[name]=response.structured_content
                after=q.local("scene_state")
                result["after_"+name]=after;save()
                assert after==before,"Read changed clean-scene state: "+name
        after=q.local("publication_snapshot",controller_id=cid)
        for key in ("rows_sha256","authored_sha256","cache_builds","native_retained","generation_id","configuration_id"):
            assert after[key]==published[key],key
        result.update(status="passed",publication_after=after);save()
        print(json.dumps({"passed":True,"receipt":str(receipt),"save_required_before_and_after":False}),flush=True)
    except BaseException as exc:
        result.update(status="failed",error=str(exc));save();raise


if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base",type=Path,required=True)
    args=parser.parse_args()
    asyncio.run(run(args.base.resolve()))
