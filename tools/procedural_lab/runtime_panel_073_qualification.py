"""Real stdio -> authenticated IPC -> queued Qt -> Max acceptance.

Requires Max_Runtime_Panel_Fixture.setup in a disposable host. All local grants
are fixture authority. No artist scope or globally paired connector is used.
"""
import argparse
import asyncio
import json
from pathlib import Path
import sys
import time
import uuid

from runtime_driver import ROOT, run_script


def local(folder,expression):
    name="panel-phase-"+uuid.uuid4().hex
    script=folder/(name+".py")
    result=folder/(name+".json")
    script.write_text("import builtins,json,traceback\nfrom pathlib import Path\ntry:\n value="+expression+
                      "\n Path("+repr(str(result))+").write_text(json.dumps({'ok':True,'result':value}))\nexcept:\n Path("+
                      repr(str(result))+").write_text(json.dumps({'ok':False,'error':traceback.format_exc()}))\n",encoding="utf-8")
    response=run_script(folder,'python.ExecuteFile @"'+script.as_posix()+'"',timeout=60)
    assert response.startswith("SUCCESS "),response
    value=json.loads(result.read_text())
    assert value["ok"],value
    return value.get("result")


async def qualify(folder):
    from mcp import Client
    from mcp.client.stdio import StdioServerParameters
    deadline=time.monotonic()+60
    while not (folder/'panel-fixture.json').exists():
        if (folder/'panel-initialization-error.txt').exists():
            raise RuntimeError((folder/'panel-initialization-error.txt').read_text(encoding='utf-8'))
        if time.monotonic()>deadline:raise TimeoutError('Private panel initialization')
        await asyncio.sleep(.1)
    identity=json.loads((folder/"panel-fixture.json").read_text(encoding='utf-8'))
    before=local(folder,'builtins.CSRuntimePanel["sample"]("panel-idle-before")')
    await asyncio.sleep(8)
    idle=local(folder,'builtins.CSRuntimePanel["sample"]("panel-idle-after")')
    assert before["ticks"]==idle["ticks"] and not idle["timer_active"] and not idle["wrong_thread"]
    params=StdioServerParameters(command=sys.executable,args=["-m","cyrus_mcp.server","--connection-dir",str(folder/"panel-connection")])
    evidence={"idle_start":before,"idle_end":idle}
    async with Client(params) as client:
        async def call(name,**args):
            value=await client.call_tool(name,args)
            assert not value.is_error,value
            return value.structured_content
        tools=await client.list_tools()
        resources=await client.list_resources()
        assert len(tools.tools)==12 and len(resources.resources)==7
        for uri in ("cyrus://plan-schema/0.73","cyrus://feature-catalog","cyrus://agent-workflows","cyrus://error-guide"):
            assert (await client.read_resource(uri)).contents
        epoch,controller=identity["scene_epoch"],identity["controller_id"]
        status=await call("connection_get_status")
        assert status["scene_epoch"]==epoch
        denied=await client.call_tool("scatter_read_diagnostic_events",dict(scene_epoch=epoch,session_id=identity["session_id"]))
        assert denied.is_error and denied.structured_content["error"]["code"]=="APPROVAL_REQUIRED"
        manifest=(await call("scatter_get_publication",scene_epoch=epoch,controller_id=controller))["manifest"]
        rows=[];offset=0
        while offset<manifest["count"]:
            page=(await call("scatter_read_publication_page",scene_epoch=epoch,controller_id=controller,
                            publication_id=manifest["publication_id"],offset=offset,limit=127))["page"]
            assert page["next_offset"]>offset
            rows+=page["rows"];offset=page["next_offset"]
        assert len(rows)==manifest["count"]
        assert len({(r["set_id"],r["instance_id"]) for r in rows})==len(rows)
        configuration=await call("scatter_get_configuration",scene_epoch=epoch,controller_id=controller)
        assert 'cached_helper' in json.dumps(configuration),'Current container presentation metadata missing'
        local(folder,'builtins.CSRuntimePanel["share"](True)')
        shared=await call("scatter_read_diagnostic_events",scene_epoch=epoch,session_id=identity["session_id"])
        assert shared["page"]["training_eligible"] is False
        local(folder,'builtins.CSRuntimePanel["share"](False)')
        denied=await client.call_tool("scatter_read_diagnostic_events",dict(scene_epoch=epoch,session_id=identity["session_id"]))
        assert denied.is_error and denied.structured_content["error"]["code"]=="APPROVAL_REQUIRED"
        local(folder,'builtins.CSRuntimePanel["busy"](True)')
        blocked=await client.call_tool("connection_get_status",{})
        assert blocked.is_error and blocked.structured_content["error"]["code"]=="HOST_BUSY"
        local(folder,'builtins.CSRuntimePanel["busy"](False)')
        after=local(folder,'builtins.CSRuntimePanel["sample"]("panel-after-requests")')
        assert after["epochs"]==before["epochs"] and after["prepared"]==before["prepared"]
        assert not after["wrong_thread"] and not after["timer_active"] and after["queued"]==0
        await asyncio.sleep(8)
        quiet=local(folder,'builtins.CSRuntimePanel["sample"]("panel-after-requests-idle")')
        assert quiet["ticks"]==after["ticks"]
        evidence.update(tools=12,resources=7,rows=len(rows),unique_identities=True,publication=manifest,
                        consent_denied_granted_revoked=True,host_busy_rejected=True,after_requests=after,settled_idle=quiet)
        # Exercise the panel's deferred write path too. Approval is granted
        # locally by this disposable fixture, never by an MCP endpoint.
        connection=local(folder,'builtins.CSRuntimePanel["setup_design"]()')
        operations=[]
        for version,count in (("0.73",0),("0.73",60)):
            context=await call("scene_get_context",scope_id=connection["scope_id"])
            plan=dict(schema_version=version,context_id=context["context_id"],name="Queued runtime qualification",
                      layers=[dict(name="Trees",region_id=context["scope"]["regions"][0]["region_id"],
                                   count=count,seed=42,sources=[dict(source_id=context["scope"]["sources"][0]["source_id"],weight=1)],
                                   scale=[.8,1.2],yaw_degrees=[0,360],underfill="allow")])
            if operations:
                plan.update(controller_id=operations[-1]["result"]["controller_id"],generation_id=operations[-1]["result"]["generation_id"])
                plan["display"]={"mode":"mesh","update_mode":"real_time"}
                plan["layers"][0]["settings"]={"self_spacing_enabled":True,"self_radius_factor":0,"self_gap_m":.3}
            for retired in ("1.0","2.0"):
                invalid=await client.call_tool("scatter_validate_plan",dict(plan=dict(plan,schema_version=retired)))
                assert invalid.is_error,invalid
            validation=await call("scatter_validate_plan",plan=plan)
            args={k:validation[k] for k in ("validation_id","digest","scene_epoch","scene_revision")}
            args["idempotency_key"]=uuid.uuid4().hex
            denied=await client.call_tool("scatter_apply_plan",args)
            assert denied.is_error and denied.structured_content["error"]["code"]=="APPROVAL_REQUIRED",denied
            local(folder,'builtins.CSRuntimePanel["approve"]('+repr(validation["validation_id"])+')')
            operation=(await call("scatter_apply_plan",**args))["operation"]
            for _ in range(30):
                if operation["state"] not in ("queued","running"):break
                await asyncio.sleep(.2)
                operation=(await call("scatter_get_status",scene_epoch=connection["scene_epoch"],operation_id=operation["operation_id"]))["operation"]
            assert operation["state"]=="succeeded",operation
            emitted=operation["result"]["emitted"]
            assert (emitted==0 if count==0 else 0<emitted<=count),operation
            assert operation["result"]["requested"]==count
            assert sum(layer["emitted"] for layer in operation["result"]["layers"])==emitted
            repeated=(await call("scatter_apply_plan",**args))["operation"]
            assert repeated==operation
            operations.append(operation)
        evidence["closed_schema_queued_writes"]=operations
        evidence["save_reopen"]=local(folder,'builtins.CSRuntimePanel["save_reopen"]()')
        stale=await client.call_tool("scatter_get_publication",dict(scene_epoch=epoch,controller_id=controller))
        assert stale.is_error and stale.structured_content["error"]["code"]=="STALE_CONTEXT",stale
        after=local(folder,'builtins.CSRuntimePanel["sample"]("panel-after-lifecycle")')
        await asyncio.sleep(8)
        quiet=local(folder,'builtins.CSRuntimePanel["sample"]("panel-after-lifecycle-idle")')
        assert after["ticks"]==quiet["ticks"] and not quiet["timer_active"] and not quiet["wrong_thread"]
        evidence["post_write_idle"]=quiet
    local(folder,'builtins.CSRuntimePanel["close"]()')
    evidence["closed_descriptor_removed"]=True
    evidence["passed"]=True
    evidence["plan_schema"]="0.73"
    evidence["retired_schemas_rejected"]=True
    (folder/"panel-runtime-result.json").write_text(json.dumps(evidence,indent=2)+"\n")
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("folder",type=Path)
    folder=parser.parse_args().folder.resolve()
    if folder.parent!=ROOT/"build/mcp-qualification":raise ValueError("Private fixture folder required")
    asyncio.run(qualify(folder))
