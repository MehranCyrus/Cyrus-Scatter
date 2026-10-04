"""Exercise the shipped MCP interface, not a direct service stand-in."""
import argparse
import asyncio
import base64
import json
from pathlib import Path
import sys
import uuid
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from qualify import Qualification


async def run(folder):
    q=Qualification(folder)
    q.local("setup")
    params=StdioServerParameters(command=sys.executable,args=["-m","cyrus_mcp.server","--connection-dir",str(q.folder/"connection")])
    async with Client(params) as client:
        async def call(name,**args):
            result=await client.call_tool(name,args)
            assert not result.is_error,result
            value=result.structured_content
            assert value and value["ok"],result
            return value
        tools=await client.list_tools()
        assert len(tools.tools)==9
        plan_tool=next(t for t in tools.tools if t.name=="scatter_validate_plan")
        assert "layers" in json.dumps(plan_tool.input_schema),"Plan schema was not advertised"
        connection=await call("connection_get_status")
        context=await call("scene_get_context",scope_id=connection["scope_id"])
        plan=q.plan(context,count=0)
        validation=await call("scatter_validate_plan",plan=plan)
        q.local("approve",validation_id=validation["validation_id"])
        args={k:validation[k] for k in ("validation_id","digest","scene_epoch","scene_revision")}
        args["idempotency_key"]=uuid.uuid4().hex
        operation=(await call("scatter_apply_plan",**args))["operation"]
        for _ in range(5):
            operation=(await call("scatter_get_status",scene_epoch=connection["scene_epoch"],operation_id=operation["operation_id"]))["operation"]
            if operation["state"] not in ("queued","running"):break
            await asyncio.sleep(.3)
        assert operation["state"]=="succeeded" and operation["result"]["emitted"]==0,operation
        context=await call("scene_get_context",scope_id=connection["scope_id"])
        plan=q.plan(context,count=600,layers=3)
        for layer in plan["layers"]:
            layer["sources"]=[{"source_id":s["source_id"],"weight":.5} for s in context["scope"]["sources"]]
        plan.update(controller_id=operation["result"]["controller_id"],generation_id=operation["result"]["generation_id"])
        validation=await call("scatter_validate_plan",plan=plan)
        q.local("approve",validation_id=validation["validation_id"])
        args={k:validation[k] for k in ("validation_id","digest","scene_epoch","scene_revision")};args["idempotency_key"]=uuid.uuid4().hex
        operation=(await call("scatter_apply_plan",**args))["operation"]
        for _ in range(5):
            operation=(await call("scatter_get_status",scene_epoch=connection["scene_epoch"],operation_id=operation["operation_id"]))["operation"]
            if operation["state"] not in ("queued","running"):break
            await asyncio.sleep(.3)
        assert operation["state"]=="succeeded",operation
        repeated=(await call("scatter_apply_plan",**args))["operation"]
        assert repeated==operation
        capture=await client.call_tool("scene_capture_viewport",{"scene_epoch":connection["scene_epoch"],"scene_revision":operation["scene_revision"],"viewport_id":context["viewport_id"],"generation_id":operation["result"]["generation_id"]})
        assert not capture.is_error,capture
        images=[c for c in capture.content if c.type=="image"]
        assert len(images)==1,capture
        png=base64.b64decode(images[0].data)
        assert png.startswith(b"\x89PNG")
        (q.folder/"mcp-capture.png").write_bytes(png)
        diagnostics=await call("scatter_get_diagnostics",scene_epoch=connection["scene_epoch"])
        evidence={"stdio_handshake":True,"tool_count":len(tools.tools),"advertised_plan_schema":True,"zero_count_valid":True,"mixed_sources_three_layers":operation["result"],"retry_exactly_once":True,"image_content_block":True,"image_bytes":len(png),"diagnostics":diagnostics}
        (q.folder/"stdio-acceptance.json").write_text(json.dumps(evidence,indent=2))
        print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    asyncio.run(run(parser.parse_args().folder))
