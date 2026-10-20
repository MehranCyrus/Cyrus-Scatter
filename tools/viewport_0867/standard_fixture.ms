(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-content-2027/" do throw "Owned content host required"
 resetMaxFile #noPrompt
 mergeMAXFile @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library\Models\Leaves\A027 - Bent Leaf - 01\model.max" #autoRenameDups #renameMtlDups #neverReparent quiet:true
 local node=objects[1]
 node.material=standardMaterial diffuseMap:(checker color1:green color2:blue)
 saveNodes #(node) (MCPFixtureDir+"standard-leaf.max") quiet:true saveAsVersion:2024
 resetMaxFile #noPrompt
)
