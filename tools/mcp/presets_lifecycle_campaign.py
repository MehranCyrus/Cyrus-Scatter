"""Actual Max lifecycle and external-client denial of revoked preset references."""
import argparse
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
    q=qualification(base);module=base/"fixtures/presets_lifecycle_host.py"
    shutil.copy2(HERE/"presets_lifecycle_host.py",module)
    meta=bind_suite(q.folder,{"preset-lifecycle-sdk-driver":Path(__file__),"preset-lifecycle-module":module,"preset-lifecycle-script":HERE/"presets_lifecycle.ms"})
    path=q.folder/"presets-lifecycle-sdk.json";assert not path.exists(),"Observe original lifecycle requests before rerunning"
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=[])
    def save():path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    save()
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            capabilities=json.loads((await client.read_resource("cyrus://capabilities")).contents[0].text)
            assert capabilities["content_discovery"]["settings_presets"]["tools"]==["presets_search","presets_inspect_entry"]
            assert capabilities["prepared_source_use"]["installed_preparation"]["local_permission_required"]
            result["capability_resource_matches_tools"]=True
            for case in ("reset","open","close"):
                q.local("setup");q.local("scene_fixture")
                connection=(await client.call_tool("connection_get_status",{})).structured_content
                if case=="open":run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],entrypoint="MCPScenePassiveRun",timeout=30)
                shared=q.local("preset_share",root=str(base/"preset-large"),pause=True)
                run_case(q.folder,HERE/"presets_lifecycle.ms",case,["preset_grant_revoked","preset_handle_released","native_handle_rejected","task_refs_released","lifecycle_boundary"],entrypoint="MCPPresetsLifecycleRun",timeout=30)
                receipt=json.loads((q.folder/("presets-lifecycle-"+case+".json")).read_text());assert receipt["status"]=="passed"
                verify_owned(q.folder)
                response=await client.call_tool("presets_search",dict(scope_id=connection["scope_id"],library_id=shared["catalog"]["library_id"]))
                expected="NOT_CONNECTED" if case=="close" else "UNKNOWN_REFERENCE"
                assert response.is_error and response.structured_content["error"]["code"]==expected,response
                result["cases"].append({**receipt,"external_client_denial":response.structured_content});save()
        result["status"]="passed";save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status="passed",cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("--base",type=Path,required=True)
    asyncio.run(run(p.parse_args().base.resolve()))
