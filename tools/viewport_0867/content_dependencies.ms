(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-content-2027/" do throw "Owned content host required"
 local output=createFile (MCPFixtureDir+"content-dependencies.txt")
 try(
  local path=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library\Models\Leaves\A027 - Bent Leaf - 01\model.max"
  resetMaxFile #noPrompt;loadMaxFile path quiet:true
  local node=objects[1]
  format "MODEL % % OpenPBR in model %\n" node.name (classof node.material) (try((getClassInstances OpenPBR_Material target:node.material).count)catch(-1)) to:output
  for i=1 to 24 do meditMaterials[i]=standardMaterial()
  renderers.current=Default_Scanline_Renderer()
  environmentMap=undefined
  local result=saveNodes #(node) (MCPFixtureDir+"dependency-cleanup.max") quiet:true saveAsVersion:2024
  format "SAVED %\n" result to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
