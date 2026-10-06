(
 RSRoot.setLayerTransfer true
 RSOwners[1].sourceWeights=#(1.0,.56,.39);RSOwners[2].sourceWeights=#(1.0,.33);RSOwners[3].sourceWeights=#(1.0,1.0,.3)
 RSFlowers.sourceWeights=#(.5,.3,1.0,.5);RSGrass.sourceWeights=#(.5,1.0)
 for leaf in RSOwners do (leaf.wholeScaleMin=.88;leaf.wholeScaleMax=1.15;leaf.rotZMin=0;leaf.rotZMax=360)
 if RSSurface.modifiers.count==0 do addModifier RSSurface (UVWMap maptype:0 width:3000 length:2300 height:100)
 RSRoot.setLayerTransfer false
 local started=timeStamp()
 RSRoot.refreshAll()
 local rows=RSRoot.evaluateGroups()
 for i=1 to rows.count do if rows[i].count==0 do throw ("Empty population "+i as string)
 viewport.setRenderLevel #smoothhighlights
 (LayerManager.getLayerFromName "05 Area guides").isHidden=true
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 CSPWriteText (MCPFixtureDir+"scene-build-final.json") (CSPObject #(#("version",RSRoot.uiVersion()),#("build_ms",timeStamp()-started),#("counts",for i=1 to rows.count collect #(RSRoot.layerObjects[i].paintSetName,rows[i].count,(RSRoot.layerObjects[i].cacheSnapshot())[4])),#("status",RSRoot.allStatus())))
)
