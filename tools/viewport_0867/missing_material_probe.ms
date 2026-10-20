(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test*-2024/" do throw "Owned missing dependency host required"
 local output=createFile (MCPFixtureDir+"missing-material-probe.txt")
 try(
  resetMaxFile #noPrompt
  mergeMAXFile @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library\Models\Leaves\A027 - Bent Leaf - 01\model.max" #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg
  for node in objects do (
   format "NODE % % MATERIAL % superclass %\n" node.name (classof node) (classof node.material) (superclassof node.material) to:output
   format "MATERIAL PROPERTIES %\n" (getPropNames node.material) to:output
  )
  resetMaxFile #noPrompt
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
