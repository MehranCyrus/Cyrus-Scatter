-- Owned host only. Capture real bridge data before asserting counts.
(
 P07Case="0.75 render bridge probe";P07New count:100
 local r=P07Root,a=P07Layer,first=P07Source
 first.pos=[1000,0,0]
 local second=box width:4 length:4 height:6 pos:[1050,0,0]
 local rect=rectangle width:300 length:200 pos:[1000,0,0]
 a.containerMode=4;a.containerNodes=#(rect);r.autoRender=true;r.refreshAll()
 local ok=CyrusPFBuild()
 CSPWriteText (MCPFixtureDir+"output075-probe.json") (CSPObject #(
  #("build_ok",ok),#("error",CyrusPFLastError),#("generated",a.generatedCount),
  #("sources",for n in a.sources collect (if isValidNode n then n.name else "placeholder")),
  #("active",a.containerActive as array),#("output_sources",for n in a.outputSources() collect n.name),
  #("group_counts",for rows in r.groupSnapshotRows collect rows.count),
  #("pflow_counts",for rows in CyrusPFData collect rows.count),#("bridge_owners",CyrusPFOwners as string)))
)
