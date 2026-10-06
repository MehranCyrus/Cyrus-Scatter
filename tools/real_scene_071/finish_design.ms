(
 RSRoot.setLayerTransfer true
 RSFlowers.amount=28000;RSGrass.sourceScales=#(3.1,3.1)
 RSOwners[3].procAttemptFactor=32;RSOwners[3].procRounds=6
 RSSurface.material.texmapDiffuse.color1=color 16 23 7
 RSSurface.material.texmapDiffuse.color2=color 30 39 12
 local road=getNodeByName "South access road"
 road.material.texmapDiffuse.color1=color 9 10 10;road.material.texmapDiffuse.color2=color 15 16 16
 RSRoot.setLayerTransfer false;RSRoot.refreshAll()
 local op=renderers.current.colorMap_pipeline
 while op!=undefined do (if isProperty op #colorMappingOperator_simpleExposure do op.colorMappingOperator_simpleExposure=-3.8;op=op.colorMappingOperator_nextOperator)
 renderers.current.progressive_passLimit=32;renderers.current.progressive_timeLimit=0
 renderWidth=1600;renderHeight=1120
 viewport.setRenderLevel #smoothhighlights
 RSRoot.setGroupDisplay 1;viewport.setCamera (getNodeByName "01 HERO | garden pavilion")
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 CSPWriteText (MCPFixtureDir+"design-final.json") (CSPObject #(#("counts",for leaf in RSRoot.layerObjects collect #(leaf.paintSetName,leaf.generatedCount,leaf.procStatistics())),#("scene",RSOut+"Cyrus_071_Garden_Pavilion.max")))
)
