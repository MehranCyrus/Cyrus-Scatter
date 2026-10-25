global MCPPreparedLifecycleRun
fn MCPPreparedLifecycleRun scenario = (
    python.Execute ("import json,host_fixture\nfrom pathlib import Path\np=host_fixture.PANEL\na=p.host.prepared_sources\nPath("+(QQuote (MCPFixtureDir+"prepared-assets-close-state.json"))+").write_text(json.dumps(dict(grant=p.service.asset_grant,token_active=bool(a and a.token is not None),references=len(p.host.scene_nodes),task=p.service.task,bridge_closed=p.bridge.closed)))")
    QAssert true "closed_source_state" "Private Python source/grant ownership recorded after panel closure"
)
