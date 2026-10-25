"""Prepared-source grant release on native scene lifecycle and panel closure."""
import asyncio
import json
from pathlib import Path
import sys
import time
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification,verify_owned,run_case,HERE
from compatibility_host import bind_suite

async def run(base):
    q=qualification(base);meta=bind_suite(q.folder,{"prepared-lifecycle-driver":Path(__file__),"prepared-lifecycle-script":HERE/"prepared_assets_lifecycle.ms"})
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],cases=[],qualification="Scripted native reset/open/panel callbacks on an owned Max; no artist interaction or interrupted file-IO guarantee.")
    path=q.folder/"prepared-assets-lifecycle.json"
    def save():path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            async def shared():
                q.local("setup");q.local("prepared_source_task")
                q.local("prepared_source_share",directory=str(base/"plant-package"))
                deadline=time.monotonic()+60
                while True:
                    verify_owned(q.folder);v=await client.call_tool("connection_get_status",{});assert not v.is_error,v
                    if v.structured_content["prepared_sources"]["status"]!="preparing":break
                    assert time.monotonic()<deadline;await asyncio.sleep(.3)
                assert v.structured_content["prepared_sources"]["status"]=="ready"
                return v.structured_content
            for event in ("scene_disconnect","scene_event_reset","save_reopen"):
                before=await shared();assert q.local("prepared_source_state")["asset_token"]
                observed=q.local(event)
                state=q.local("prepared_source_state")
                v=await client.call_tool("connection_get_status",{});assert not v.is_error,v
                assert not state["asset_token"] and state["grant"] is None
                assert v.structured_content["scope_id"] is None and not v.structured_content["prepared_sources"]["shared"]
                result["cases"].append(dict(event=event,before_grant=before["prepared_sources"]["grant_id"],observed=observed,token_released=True));save()
            await shared()
            closed=q.local("scene_panel_close")
            assert closed==dict(references=0,task=None,bridge_closed=True)
        run_case(q.folder,HERE/"prepared_assets_lifecycle.ms","close",["closed_source_state"],entrypoint="MCPPreparedLifecycleRun",timeout=30)
        closed=json.loads((q.folder/"prepared-assets-close-state.json").read_text())
        assert closed==dict(grant=None,token_active=False,references=0,task=None,bridge_closed=True),closed
        result["cases"].append(dict(event="panel_close",observed=closed));result["status"]="passed";save()
        print(json.dumps(dict(status="passed",cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise

if __name__=="__main__":
    import argparse
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("--base",type=Path,required=True);asyncio.run(run(p.parse_args().base.resolve()))
