(
 local log=createFile (MCPFixtureDir+"demo-map-paths.txt")
 local root=(getNodeByName "CYRUS 0.86.2 | SELECT ME - six feature layers").baseObject
 for leaf in root.layerObjects where classof leaf.densityMap==Bitmaptexture do format "map=% bitmap=% expected=%\n" leaf.densityMap.filename leaf.densityMap.bitmap.filename MCPFixtureDir to:log
 close log
)
