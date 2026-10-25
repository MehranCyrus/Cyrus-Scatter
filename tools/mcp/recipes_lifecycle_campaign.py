"""Actual reset/open/close revocation before recipe snapshot publication."""
import asyncio
import json
from pathlib import Path
import shutil
import sys

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification,verify_owned,run_case,HERE
from compatibility_host import bind_suite


async def run(base):
    q=qualification(base)
    module=base/"fixtures/recipes_lifecycle_host.py"
    shutil.copy2(HERE/"recipes_lifecycle_host.py",module)
    meta=bind_suite(q.folder,{"recipe-lifecycle-driver":Path(__file__),"recipe-lifecycle-module":module,
                              "recipe-lifecycle-script":HERE/"recipes_lifecycle.ms"})
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    results=[]
    async with Client(params) as client:
        for case in ("reset","open","close"):
            q.local("setup");q.local("scene_fixture")
            response=await client.call_tool("connection_get_status",{});assert not response.is_error
            old_scope=response.structured_content["scope_id"]
            if case=="open":run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],timeout=30,entrypoint="MCPScenePassiveRun")
            shared=q.local("recipe_share",root=str(base/"data/large"),pause=True)
            library_id=shared["catalog"]["library_id"]
            run_case(q.folder,HERE/"recipes_lifecycle.ms",case,["recipe_grant_revoked","recipe_handle_released","native_handle_rejected","task_refs_released","lifecycle_boundary"],timeout=30,entrypoint="MCPRecipesLifecycleRun")
            result=json.loads((q.folder/("recipes-lifecycle-"+case+".json")).read_text());assert result["status"]=="passed"
            results.append(result)
            verify_owned(q.folder)
            response=await client.call_tool("recipes_search",dict(scope_id=old_scope,library_id=library_id))
            assert response.is_error and response.structured_content["error"]["code"]==("NOT_CONNECTED" if case=="close" else "UNKNOWN_REFERENCE"),response
    result=dict(status="passed",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=results)
    (q.folder/"recipes-lifecycle.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":"passed","cases":len(results),"artifact_id":meta["artifact_id"]}),flush=True)


if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--base",type=Path,required=True)
    asyncio.run(run(parser.parse_args().base.resolve()))
