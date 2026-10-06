(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/inspect.ms"
 local f=createFile (MCPFixtureDir+"asset-properties.txt")
 for node in objects where (classof node.baseObject) == CProxy do (format "\nPROXY %\n" node.name to:f;showProperties node.baseObject to:f)
 format "\nLEGACY MATERIAL\n" to:f
 showProperties (CoronaLegacyMtl()) to:f
 format "\nSUN\n" to:f
 showProperties (getNodeByName "Corona Sun001") to:f
 format "\nSKY\n" to:f
 try(showProperties (CoronaSky()) to:f)catch(format "%\n" (getCurrentException()) to:f)
 format "\nTONEMAP\n" to:f
 showProperties renderers.current.colorMap_pipeline to:f
 format "\nSCATTER SETTINGS\n" to:f
 showProperties (getNodeByName "Cyrus Scatter001").baseObject to:f
 close f
)
