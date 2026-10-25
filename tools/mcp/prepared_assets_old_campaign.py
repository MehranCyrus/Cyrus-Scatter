"""Current source client denies asset use on an exact older matched owned pair."""
import argparse
import asyncio
import json
from pathlib import Path
import shutil
import sys
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT,qualification,resume,verify_owned,close_owned
from recipe_catalog_campaign import launch as launch_native
from compatibility_host import bind_suite

def launch(base):
    from package import stage_package_payload
    # Original published pair is a negative compatibility witness, not current-source qualification.
    packages=ROOT/"dist/CyrusScatter-0.86.9.2-20261023"
    stage_package_payload(base/"payload",2027,packages/"CyrusScatter-0.86.9.2-Max2027.mzp",
                          packages/"CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp",historical=True)
    launch_native(base)

async def run(base):
    q=qualification(base);meta=bind_suite(q.folder,{"old-source-use-driver":Path(__file__)})
    q.local("setup");ctx=q.local("prepared_source_task")
    local=q.local("prepared_source_unsupported",directory=str(ROOT/"build/mcp-source-use-20261024-03/host01/portable-source-package"))
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    async with Client(params) as client:
        assert len((await client.list_tools()).tools)==19
        c=(await client.call_tool("connection_get_status",{})).structured_content
        assert c["host"]["prepared_source_use_api"] is None and not c["prepared_sources"]["shared"]
        use=dict(use_schema="cyrus.asset-use/1.0",scope_id=ctx["scope"]["scope_id"],task_id=ctx["task"]["task_id"],task_revision=ctx["task"]["task_revision"],
                 grant_id="not_granted",asset_refs=["not_granted"],destination="task_sources")
        denied=await client.call_tool("assets_validate_use",dict(use=use))
        assert denied.is_error and denied.structured_content["error"]["code"]=="STALE_CONTEXT",denied
    result=dict(status="passed",pid=meta["pid"],artifact_id=meta["artifact_id"],local=local,host=c["host"],remote=denied.structured_content,
                qualification="Older matched Max 2027 pair; source client discovery/denial only, no import or artist interaction")
    (q.folder/"prepared-assets-old.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    verify_owned(q.folder);print(json.dumps(dict(status="passed",artifact_id=meta["artifact_id"])),flush=True)

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=("launch","resume","exercise","close"));p.add_argument("--base",type=Path,required=True)
    a=p.parse_args();base=a.base.resolve()
    if a.action=="launch":launch(base)
    elif a.action=="resume":resume(base)
    elif a.action=="exercise":asyncio.run(run(base))
    else:close_owned(base/"host01")
