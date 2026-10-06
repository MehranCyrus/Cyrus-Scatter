(
 if findString MCPFixtureDir "/procedural07-real-scene-071"==undefined do throw "Private real-scene host required"
 global CyrusSurfaceAnalyzer
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms"
 if not(loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/real-scene-071/Original_Artist_Scene_Copy.max" quiet:true useFileUnits:true) do throw "Could not reload preserved copy"
 if classof (getNodeByName "Surface Analyzer001").baseObject!=CyrusSurfaceAnalyzer do throw "Analyzer did not recover"
 for obj in getClassInstances AminScatterObject do obj.updateMode=1
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/relink.ms"
 local names=#("grass_bush","grass_small","clover_pack_004","crp_Lavander_01","crp_Lavander_05","crp_MT_PM_V33_Glossy_abelia_01_006","crp_MT_PM_V33_Myrtle_01_003","crp_MT_PM_Rosa_rugosa_01_02","crp_MT_PM_Sambucus_nigra_02_01","MT_PM_V41_Geranium_robertianum_01_04","MT_PM_V41_Lamium_maculatum_01_04","MT_PM_V41_Phlox_stolonifera_01_01","MT_PM_V41_Viola_sororia_01_05","MT_PM_V41_Arthropodium_01_04","MT_PM_V41_Arthropodium_01_01")
 local assets=for name in names collect (getNodeByName name)
 for asset in assets do if not isValidNode asset do throw "Expected source asset missing"
 saveNodes assets @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/real-scene-071/Plant_Library.max" quiet:true
 resetMaxFile #noPrompt
 mergeMAXFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/real-scene-071/Plant_Library.max" #select #autoRenameDups quiet:true
 local assetRows=#()
 for n in objects do (
  if classof n.baseObject==CProxy do n.previzType=3
  local bounds=nodeGetBoundingBox n (matrix3 1)
  append assetRows #(n.name,(classof n.baseObject) as string,bounds[1] as string,bounds[2] as string,getPolygonCount n)
 )
 CSPWriteText (MCPFixtureDir+"prepared-assets.json") (CSPObject #(#("analyzer_recovered",true),#("assets",assetRows)))
 saveMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/real-scene-071/Prepared_Library.max" quiet:true
)
