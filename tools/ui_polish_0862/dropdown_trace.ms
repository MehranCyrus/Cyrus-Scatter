(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 DropProbeTimer.Stop();close DropProbeLog
 global DropTrace=createFile (MCPFixtureDir+"dropdown-trace.txt"),DropOriginalLayout=DropProbePage.layout,DropOriginalBind=DropProbePage.bind
 fn DropTracedLayout = (
  format "LAYOUT time=% width=% previous=%\n" (timestamp()) DropProbePage.width DropProbePage.lastLayoutWidth to:DropTrace;flush DropTrace
  DropOriginalLayout()
 )
 fn DropTracedBind layer = (
  format "BIND time=%\n" (timestamp()) to:DropTrace;flush DropTrace
  DropOriginalBind layer
 )
 DropProbePage.layout=DropTracedLayout;DropProbePage.bind=DropTracedBind
 global DropOrigRedraw=CyrusViewportRedraw
 fn CyrusViewportRedraw = (
  format "REDRAW time=%\n" (timestamp()) to:DropTrace;flush DropTrace
  DropOrigRedraw()
 )
)
