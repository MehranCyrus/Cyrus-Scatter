(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global CChecks=#(),CAssert,CPump,CFixtureHeld=false
local originalInteractionHeld=CyrusInteractionHeld
fn CyrusInteractionHeld = CFixtureHeld
fn CPump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn CAssert value message = (
 if not value do throw ("Container qualification: "+message)
 append CChecks message
 local f=createFile (MCPFixtureDir+"container-checks.txt")
 for line in CChecks do format "PASS %\n" line to:f
 close f;true
)
try (
CyrusStopBrush();resetMaxFile #noPrompt
local receiver=plane name:"Container_receiver" width:100 length:100 pos:[1000,0,0]
local models=for i=1 to 64 collect (box name:("Container_model_"+i as string) width:1 length:1 height:2 pos:[(mod i 8)*4,(floor (i/8))*4,0])
local node=AminScatterObject name:"Container_scatter",root=node.baseObject
root.updateMode=1;root.autoRender=false;root.newLayer()
local leaf=root.selectedLayer();leaf.amount=100;root.setLayerSurfaces leaf #(receiver)
select node;max modify mode;modPanel.setCurrentObject root
if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
local panel=root.modelsUI;panel.open=true;root.mainUI.bindSection panel
panel.advancedToggle.checked=true;panel.layout()
local started=timeStamp()
panel.sourceContainersUI_createContainer.pressed()
local container=leaf.containerNodes[1];container.pos=[0,0,0]
leaf.containerRefresh();CPump 300
local creationMS=timeStamp()-started
CAssert (not container.collectEnabled and leaf.sources.count==0) "Create button starts with collection disabled and no registered models"
CAssert (leaf.containerScans==0 and leaf.containerTests==0) "Inactive rectangle performs zero scene scans and candidate membership tests"
CAssert (panel.sourceContainersUI_enabledCheck.visible and not panel.sourceContainersUI_enabledCheck.checked) "Models exposes the selected rectangle collection checkbox"
local savedPos=models[1].pos
container.pos=[15,0,0];leaf.containerRefresh()
CAssert (models[1].pos==savedPos and leaf.sources.count==0 and leaf.containerScans==0) "Positioning an inactive rectangle does not collect or carry scene models"
container.pos=[0,0,0]
select container;modPanel.setCurrentObject container.baseObject
container.mainUI.mountTimer.tick()
CAssert (container.mainUI.controlsReady and container.mainUI.root==root and container.mainUI.owner==leaf) "Selecting a layer rectangle mounts its linked Scatter panel without an exception"
CAssert (not container.containerUI.enabledCheck.checked) "Rectangle Modify panel exposes the same disabled collection state"
container.containerUI.enabledCheck.changed true
CAssert container.collectEnabled "Rectangle checkbox enables collection"
root.refreshAll()
CAssert (leaf.sources.count==64 and leaf.containerScans==1 and leaf.containerTests>0) "Enabled rectangle collects the expected source models in one scan"
CAssert (leaf.previewError=="" and root.groupSnapshotRows[1].count==100) "Update generates the requested population from collected models"
leaf.sourceWeights[1]=0.25
local stableEpoch=root.procEpoch,stableScans=leaf.containerScans,stableTests=leaf.containerTests
container.mainUI.mountTimer.tick();leaf.containerRefresh()
CAssert (root.procEpoch==stableEpoch and leaf.containerScans==stableScans and leaf.containerTests==stableTests) "Reselecting a rectangle does not scan or rebuild an unchanged population"
select node;modPanel.setCurrentObject root;root.mainUI.mountTimer.tick()
panel=root.modelsUI;panel.open=true;root.mainUI.bindSection panel;panel.advancedToggle.checked=true;panel.layout()
panel.sourceContainersUI_enabledCheck.changed false;CPump 250
CAssert (not container.collectEnabled and root.procEpoch==stableEpoch and root.groupSnapshotRows[1].count==100) "Disabling collection in Manual waits for Update"
root.refreshAll()
CAssert (root.groupSnapshotRows[1].count==0 and leaf.sources.count==64 and leaf.sourceWeights[1]==0.25) "Disable parks source rows and preserves their settings"
CAssert (container.savedSources.count==64 and container.cachedActiveCount==0) "Disabled rectangle keeps saved source identities but has no active models"
CAssert (leaf.containerScans==stableScans and leaf.containerTests==stableTests) "Disabling collection does not scan scene geometry"
max undo;root.refreshAll()
CAssert (container.collectEnabled and root.groupSnapshotRows[1].count==100) "Undo restores enabled collection and its population"
max redo;root.refreshAll()
CAssert (not container.collectEnabled and root.groupSnapshotRows[1].count==0) "Redo restores disabled collection"
root.updateMode=2;root.markInputDirty();CPump 400
panel.sourceContainersUI_enabledCheck.changed true;CPump 2200
CAssert (container.collectEnabled and root.groupSnapshotRows[1].count==100 and leaf.previewError=="") "Live enabling automatically publishes collected models"
panel.sourceContainersUI_enabledCheck.changed false;CPump 2200
CAssert (not container.collectEnabled and root.groupSnapshotRows[1].count==0) "Live disabling automatically parks the population"
root.updateMode=1
local globalRectangle=root.containerCreate globalPool:true;globalRectangle.pos=[0,0,0]
leaf.containerSetMode 3
select globalRectangle;modPanel.setCurrentObject globalRectangle.baseObject;globalRectangle.mainUI.mountTimer.tick()
CAssert (globalRectangle.mainUI.controlsReady and globalRectangle.mainUI.owner==leaf) "Global rectangle selection resolves the layer without retired paint-set calls"
globalRectangle.containerUI.enabledCheck.changed true;root.refreshAll()
CAssert (root.groupSnapshotRows[1].count==100 and leaf.sourceWeights[1]==0.25) "Global collection uses retained layer source settings"
root.newLayer();local second= root.selectedLayer();second.containerSetMode 3
globalRectangle.collectEnabled=false;CyrusContainerRefreshAll()
CAssert ((CyrusContainerLinks globalRectangle).count==2 and globalRectangle.consumerRows.count==2) "Disabled shared rectangle retains both linked layer editing contexts"
root.removeLogicalLayer second;root.selectLayer (findItem root.layerObjects leaf)
globalRectangle.collectEnabled=true;CyrusContainerRefreshAll()
local area=root.addPaintArea leaf target:receiver
select node;modPanel.setCurrentObject root;root.mainUI.mountTimer.tick()
local painting=root.coverageUI;painting.open=true;root.mainUI.bindSection painting;painting.layout()
CAssert (painting.brushUI_densitySpin.visible and painting.brushUI_overlayMode.visible and painting.brushUI_overlayColor.visible) "Area density and paint feedback are visible without Advanced"
CAssert (not painting.advancedToggle.visible) "Painting has no empty Advanced disclosure"
painting.brushUI_densitySpin.changed 35
CAssert (abs(area.paintDensity-.35)<1e-5) "Visible Area density writes to the selected paint area"
root.setGroupCoverage area false;painting.bind leaf;painting.layout()
CAssert (not painting.brushUI_densitySpin.visible and not painting.brushUI_overlayMode.visible) "Painting-specific controls hide when Paint Areas are disabled"
local snapshot=MCPFixtureDir+"container-roundtrip.max"
saveMaxFile snapshot quiet:true
loadMaxFile snapshot quiet:true useFileUnits:true
CPump 300
node=getNodeByName "Container_scatter";root=node.baseObject;leaf=root.selectedLayer()
container=leaf.containerNodes[1];globalRectangle=root.containerGlobalNodes[1]
CAssert (not container.collectEnabled and globalRectangle.collectEnabled) "Save/open preserves each rectangle collection switch independently"
CAssert (leaf.sources.count==64 and leaf.sourceWeights[1]==0.25) "Save/open preserves model registration and source settings"
select globalRectangle;max modify mode;modPanel.setCurrentObject globalRectangle.baseObject;CPump 200;globalRectangle.mainUI.mountTimer.tick()
CAssert (globalRectangle.mainUI.controlsReady) "Saved rectangle selection mounts correctly after reload"
local receipt=createFile (MCPFixtureDir+"container-metrics.txt")
format "Create + explicit refresh + 300 ms event pump: % ms\nDisabled scan/test counters: 0/0\nModels: 64\nAssertions: %\n" creationMS CChecks.count to:receipt
close receipt
CyrusInteractionHeld=originalInteractionHeld
)catch(CyrusInteractionHeld=originalInteractionHeld;throw())
)
