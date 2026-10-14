(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 gc light:true
 local log=createFile (MCPFixtureDir+"phase05-probe.txt")
 format "units=% scale=%\n" units.SystemType units.SystemScale to:log
 for n in objects where classof n.baseObject==AminScatterObject do (
  local root=n.baseObject
  for leaf in root.layerObjects do for area in leaf.paintAreas do (
   format "area=% target=% stats=%\n" area.layerID area.areaTarget (cyrusBrushStats area.paintDocument) to:log
   try(cyrusBrushBind area.paintDocument;format "bind OK\n" to:log)catch(format "bind ERROR %\n" (getCurrentException()) to:log)
  )
 )
 for n in objects where superclassof n==Shape or matchPattern n.name pattern:"*terrain*" do (
   format "% object=% node=%\n" n.name n.objectTransform n.transform to:log
 )
 close log
)
