import asyncio
import sys
from mcp import Client
from mcp.client.stdio import StdioServerParameters


def test_real_stdio_handshake_tools_schema_and_offline_error(tmp_path):
    async def run():
        params=StdioServerParameters(command=sys.executable,args=["-m","cyrus_mcp.server","--connection-dir",str(tmp_path)])
        async with Client(params) as client:
            tools=await client.list_tools()
            names={t.name for t in tools.tools}
            assert names=={"connection_get_status","scene_get_context","scatter_validate_plan","scatter_apply_plan","scatter_get_status","scatter_get_diagnostics","scatter_get_configuration","scatter_export_record","scene_capture_viewport"}
            assert all("execute" not in name for name in names)
            schema=await client.read_resource("cyrus://plan-schema")
            assert '"schema_version"' in schema.contents[0].text
            result=await client.call_tool("connection_get_status",{})
            assert "NOT_CONNECTED" in str(result)
            assert result.is_error and result.structured_content["ok"] is False
    asyncio.run(run())
