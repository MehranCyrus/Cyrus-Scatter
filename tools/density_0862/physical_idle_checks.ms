(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"physical-idle-phase.txt")
 if phase=="start" then (
  DRoot.refreshAll()
  global PhysicalIdle=#(DRoot.procEpoch,DRoot.groupBuilds,DRoot.groupSnapshotKey)
  DRoot.bindNativeUI();DRoot.mainUI.bindEditors()
 )else (
  if DRoot.groupSnapshotKey!=DRoot.procInputKey() do throw "Passive UI binding changed the input signature after Update"
  if DRoot.procEpoch!=PhysicalIdle[1] or DRoot.groupBuilds!=PhysicalIdle[2] do throw "Passive panel binding recalculated"
  if (for leaf in DRoot.layerObjects where leaf.dirty collect leaf).count!=0 do throw "Clean publication incorrectly remains pending"
  (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"physical-idle.txt") "PASS: Explicit Update clears pending inputs; passive panel binding and idle retain the same publication without new calculation or false pending state."
 )
)
