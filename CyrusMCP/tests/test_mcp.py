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
            assert names=={"connection_get_status","scene_get_context","scene_measure_objects","library_search","library_inspect_entry","recipes_search","recipes_inspect_entry","presets_search","presets_inspect_entry","assets_prepare_sources","assets_validate_use","scatter_validate_plan","scatter_validate_change","scatter_apply_plan","scatter_get_status","scatter_get_diagnostics","scatter_get_configuration","scatter_get_settings","scatter_export_record","scene_capture_viewport","scatter_read_diagnostic_events","scatter_get_publication","scatter_read_publication_page"}
            assert all("execute" not in name for name in names)
            schema=await client.read_resource("cyrus://plan-schema")
            assert '"schema_version"' in schema.contents[0].text
            for uri,expected in (("cyrus://feature-catalog","C34"),("cyrus://agent-workflows","investigate_ir_refresh"),("cyrus://error-guide","OUTCOME_UNKNOWN")):
                resource=await client.read_resource(uri)
                assert expected in resource.contents[0].text
            assert all(t.annotations.read_only_hint for t in tools.tools if t.name in
                       {"scene_measure_objects","library_search","library_inspect_entry","recipes_search","recipes_inspect_entry","presets_search","presets_inspect_entry","scatter_get_settings","assets_validate_use","scatter_read_diagnostic_events","scatter_get_publication","scatter_read_publication_page"})
            result=await client.call_tool("connection_get_status",{})
            assert "NOT_CONNECTED" in str(result)
            assert result.is_error and result.structured_content["ok"] is False
    asyncio.run(run())
