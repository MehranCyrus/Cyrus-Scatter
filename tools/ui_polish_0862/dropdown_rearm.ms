(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 global DropOriginalStats=DRoot.mainUI.refreshStats,DropOriginalManagerLayout=DRoot.mainUI.editors[1].layout
 fn DropTracedStats = (format "STATS time=%\n" (timestamp()) to:DropTrace;flush DropTrace;DropOriginalStats())
 fn DropTracedManagerLayout = (format "MANAGER_LAYOUT time=%\n" (timestamp()) to:DropTrace;flush DropTrace;DropOriginalManagerLayout())
 DRoot.mainUI.refreshStats=DropTracedStats;DRoot.mainUI.editors[1].layout=DropTracedManagerLayout
 DRoot.mainUI.slots[6].open=false
 DRoot.mainUI.slots[6].open=true
 DRoot.mainUI.bindSection DropProbePage
)
