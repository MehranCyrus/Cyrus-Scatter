(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
resetMaxFile #noPrompt
local node=AminScatterObject name:"Container_baseline",root=node.baseObject
root.updateMode=1;root.autoRender=false;root.newLayer()
local leaf=root.selectedLayer(),model=box pos:[0,0,0],container=leaf.containerCreate()
container.pos=[0,0,0];leaf.containerRefresh()
local f=createFile (MCPFixtureDir+"container-baseline.txt")
format "version=% registered=% scans=% tests=%\n" (root.uiVersion()) leaf.sources.count leaf.containerScans leaf.containerTests to:f
select container;max modify mode;modPanel.setCurrentObject container.baseObject
try(container.mainUI.mountTimer.tick();format "selection=no exception\n" to:f)catch(format "selection=%\n" (getCurrentException()) to:f)
container.mainUI.mountTimer.active=false
close f
)
