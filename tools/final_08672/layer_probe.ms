(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2027/" do throw "Owned host required"
 local output=createFile (MCPFixtureDir+"layer-probe.txt")
 local layer=LRoot.selectedLayer()
 format "ROOT state epoch % error % count % layer %\n" LRoot.procEpoch LRoot.previewError LRoot.generatedCount LRoot.activeLayer to:output
 format "LAYER amount % mode % receivers % sources % generated % error % state %\n" layer.amount layer.populationMode (layer.validSurfaces()) layer.sources layer.generatedCount layer.previewError (CyrusUIResultText LRoot layer) to:output
 format "SNAPSHOT counts %\n" (for row in LRoot.groupSnapshotRows collect row.count) to:output
 close output
)
