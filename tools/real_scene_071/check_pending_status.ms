(
 fn recordStage = #(RSRoot.groupSnapshotKey==RSRoot.procInputKey(),for leaf in RSRoot.layerObjects collect #(leaf.dirty,(leaf.uiLayerStats()).needsUpdate,(leaf.cacheSnapshot())[4]),RSRoot.procEpoch)
 local before=recordStage()
 RSRoot.refreshAll();local immediate=recordStage()
 windows.processPostedMessages();completeRedraw();windows.processPostedMessages()
 local after=recordStage()
 CSPWriteText (MCPFixtureDir+"pending-status.json") (CSPObject #(#("before",before),#("after_update",immediate),#("after_redraw",after)))
)
