(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/common.ms"
 global RSAdvanced=#(),RSBind,RSReload,RSAdvancedRecord,RSAssert,RSRows,RSEqual
 fn RSAdvancedRecord label evidence = (append RSAdvanced #(label,evidence);CSPWriteText (MCPFixtureDir+"advanced-campaign.json") (CSPObject #(#("checks",RSAdvanced),#("complete",false))))
 fn RSBind = (
  RSNode=getNodeByName "CYRUS 0.7.1 | Courtyard - Edit layer";RSRoot=RSNode.baseObject
  RSOwners=RSRoot.logicalLayers();RSFlowers=RSOwners[4]
  local sets=RSRoot.layerSets RSFlowers;RSClover=sets[2];RSGrass=sets[3]
  RSSurface=RSRoot.surfaceNodes[1]
 )
 fn RSReload = (loadMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true useFileUnits:true;RSBind();RSRoot.refreshAll())
 RSReload()
 local baseline=RSRows(),epoch=RSRoot.procEpoch,key=RSRoot.procInputKey()
 RSRoot.layerVisible[1]=false;RSFlowers.paintSetVisible=false;RSOwners[1].paintSetName="Shrub display name"
 completeRedraw();RSAssert (RSEqual baseline (RSRows())) "Visibility/rename altered exact output"
 RSAssert (epoch==RSRoot.procEpoch and RSRoot.procInputKey()==key) "Visibility/rename invalidated placements"
 RSRoot.layerVisible[1]=true;RSFlowers.paintSetVisible=true;RSOwners[1].paintSetName="Base"
 RSRoot.layerEnabled[1]=false;RSRoot.refreshAll();RSAssert ((RSRows())[1].count==0) "Disabled logical layer still contributes"
 RSRoot.layerEnabled[1]=true;RSRoot.refreshAll();RSAssert (RSEqual baseline (RSRows())) "Enable did not restore seeded publication"
 RSAdvancedRecord "Hidden versus disabled, rename and restore" "Hidden preserved exact output/cache; disabled removed its population; enable restored output"
 -- Density map endpoints and inverse are unambiguous tests on mapped real terrain.
 local leaf=RSOwners[1],old=#(leaf.procPopulation,leaf.areaNodes as array,leaf.areaModes as array,leaf.amount)
 leaf.procPopulation=1;leaf.amount=500;leaf.areaNodes=#();leaf.areaModes=#();leaf.procSelfEnabled=false
 leaf.distributionMode=3;leaf.densityMap=Noise size:100 color1:black color2:black
 RSRoot.refreshAll();RSAssert ((RSRows())[1].count==0) "Black density did not suppress candidates"
 leaf.invertDensity=true;RSRoot.refreshAll();local white=(RSRows())[1].count
 RSAssert (white==500) "Inverted black map did not admit the full budget"
 leaf.distributionMode=1;leaf.invertDensity=false;leaf.densityMap=undefined
 leaf.populationMode=2;leaf.plantsPerM2=.5;RSRoot.refreshAll()
 local expected=(floor((aminScatterSurfaceArea #(RSSurface))/10000.0*.5+.5)) as integer
 RSAssert ((RSRows())[1].count==expected) "Plants per square metre disagrees with terrain area"
 RSAdvancedRecord "Texture density, inversion and plants per square metre" #(white,expected)
 leaf.populationMode=1;leaf.amount=500;leaf.diversityMode=2;leaf.sourceColors=#(red,green,blue);leaf.diversitySize=250
 RSRoot.refreshAll();local clustered=RSRows()
 RSAssert (clustered[1].count==500) "Clusters lost a candidate budget without masks/rules"
 RSAdvancedRecord "Clustered source-color assignment" #(clustered[1].count,"real shrub models, three color groups")
 leaf.diversityMode=1;leaf.rotXMin=-4;leaf.rotXMax=4;leaf.rotYMin=-3;leaf.rotYMax=3;leaf.sclXMin=.85;leaf.sclXMax=1.1;leaf.sclYMin=.9;leaf.sclYMax=1.15;leaf.sclZMin=.7;leaf.sclZMax=1.3
 leaf.movXMin=-10;leaf.movXMax=10;leaf.movYMin=-10;leaf.movYMax=10;leaf.projectMove=true;leaf.sourceZOffsets=#(4,4,4)
 RSRoot.refreshAll();local transformed=RSRows()
 RSAssert (transformed[1].count>450 and not(RSEqual clustered transformed)) "XYZ/source transforms did not affect output"
 for r in transformed[1] do RSAssert (r[1].row4.z>=3.9) "Source height offset was lost"
 RSAdvancedRecord "XYZ variation, projected movement and per-source Z offset" transformed[1].count
 saveMaxFile (RSOut+"Variant_Clusters_Density_Transforms.max") quiet:true
 -- Preserve a real CS Edit demonstration and verify reopening its bindings.
 RSReload();RSRoot.updateMode=2
 local edit=CyrusScatterEdit();addModifier RSNode edit;RSRoot.evaluateGroups()
 cyrusEditSelect edit #(1,2)
 cyrusEditCommand edit 4 (transMatrix [15,0,8]);RSRoot.evaluateGroups()
 cyrusEditCommand edit 3 (transMatrix [70,0,0]);RSRoot.evaluateGroups()
 RSOwners[1].procSelectedRadius 1 65;RSRoot.evaluateGroups()
 RSAssert (RSOwners[1].procRadiusIDs.count>0) "Selected radius not recorded"
 local authored=RSRows(),idCount=RSOwners[1].procRadiusIDs.count
 RSOwners[1].amount=0;RSRoot.evaluateGroups()
 RSAssert ((RSRows())[1].count>=2) "Valid protected edits disappeared at zero quota"
 RSOwners[1].amount=52;RSRoot.refreshAll()
 authored=RSRows()
 saveMaxFile (RSOut+"Variant_Protected_Edits_Radii.max") quiet:true
 loadMaxFile (RSOut+"Variant_Protected_Edits_Radii.max") quiet:true useFileUnits:true;RSBind();RSRoot.refreshAll()
 RSAssert (RSEqual authored (RSRows())) "Saved Edit/radius bindings changed on reopen"
 RSAdvancedRecord "CS Edit move, clones, selected radii, zero quota and persistence" #(idCount,(RSRows())[1].count)
 RSReload()
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/legacy_campaign.ms"
 RSAssert (RSEqual baseline (RSRows())) "Baseline changed after variant reload"
 CSPWriteText (MCPFixtureDir+"advanced-campaign.json") (CSPObject #(#("checks",RSAdvanced),#("complete",true)))
)
