(
 RSReload();RSRoot.cyrusEnabled=false
 local extra=AminScatterObject name:"OPTION LAB | containers points and radii",root=extra.baseObject
 root.setLayerTransfer true;root.surfaceNodes=#(RSSurface);root.updateMode=1;root.autoRender=false;root.newLayer()
 local leaf=root.selectedLayer(),models=#(RSGrass.sources[1],RSGrass.sources[2])
 leaf.sources=models;leaf.sourceWeights=#(1.0,1.0);leaf.amount=400;leaf.paintEnabled=false;leaf.collisionEnabled=false
 root.setLayerTransfer false;root.procUpgrade()
 root.containerGlobalNodes=#(getNodeByName "SOURCE CONTAINER | 06 Grasses");leaf.containerMode=3
 root.refreshAll()
 RSAssert (leaf.containerProvider()==root and leaf.sources.count==2) "Global container did not resolve the two grass models"
 local child=root.addPaintSet leaf label:"Inherited model container"
 child.sources=models;child.sourceWeights=#(1.0,1.0);child.paintEnabled=false;child.containerMode=2
 root.refreshAll();RSAssert (child.containerProvider()==root and child.sources.count==2) "Child container inheritance failed"
 local results=#(#("global_and_inherited_containers",true))
 leaf.sourceScales=#(2.0,1.0);leaf.sourceRadii=#(10.0,5.0);leaf.sourceFollowScale=#(true,false)
 root.refreshAll()
 local rows=leaf.placements (leaf.outputSources()),radii=leaf.procRadii rows (leaf.outputSources())
 for i=1 to rows.count do (
  local source=rows[i][2],tm=rows[i][1],expected=if source==1 then 10.0*(amax (length tm.row1) (amax (length tm.row2) (length tm.row3))) else 5.0
  RSAssert (abs(radii[i]-expected)<.0001) "Source radius scaling was applied incorrectly"
 )
 append results #("follow_scale_radius_oracle",rows.count)
 leaf.sourcePoint=#(true,false);root.refreshAll()
 local slots=leaf.generatedCount,meshes=(leaf.placements (leaf.outputSources())).count
 RSAssert (meshes>0 and meshes<slots) "Point placeholder was counted as render geometry"
 append results #("point_slots_vs_mesh_instances",#(slots,meshes))
 leaf.sourcePoint=#(false,false);leaf.sourceEmpty=#(true,false);root.refreshAll()
 local empty=leaf.generatedCount
 RSAssert (empty>0 and empty<200) "Weighted Empty did not reduce the candidate population"
 leaf.procPopulation=2;local denied=false;try(root.evaluateGroups())catch(denied=true)
 RSAssert denied "Accepted target silently filled intentional Empty slots"
 leaf.procPopulation=1;leaf.sourceEmpty=#(false,false);root.refreshAll()
 append results #("weighted_empty_and_target_guard",#(empty,denied))
 leaf.finalCleanup=true;leaf.finalNeighborRadius=10000;leaf.finalMinNeighbors=500
 root.refreshAll();RSAssert (leaf.generatedCount==0 and child.generatedCount==0) "Union cleanup did not remove isolated populations"
 leaf.finalCleanup=false;root.refreshAll()
 append results #("union_cleanup",true)
 saveMaxFile (RSOut+"Variant_Global_Containers_and_Radii.max") quiet:true
 CSPWriteText (MCPFixtureDir+"rare-options.json") (CSPObject #(#("passed",true),#("checks",results)))
 RSReload()
)
