-- Real control events in a disposable Max session; not a pointer test.
(
if findString MCPFixtureDir "/procedural07-ui-071-"==undefined do throw "Private 0.7.1 fixture required"
global UI071Section,UI071EditorResults
fn UI071Section property = (
    for section in CyrusLayerEditor.editors where isProperty section property do return section
    throw ("Missing editor section: "+property as string)
)
P07Case="0.7.1 Layer Editor"
P07New count:240
local root=P07Root,a=P07Layer,node=P07Node,source=P07Source
local b=root.addPaintSet a label:"Understory",c=root.addPaintSet a label:"Flowers"
root.newLayer();local second=root.selectedLayer();second.amount=70
root.newLayer();local third=root.selectedLayer();third.amount=50
for leaf in root.layerObjects do (leaf.sources=#(source);leaf.sourceColors=#(color 70 180 80);leaf.sourceWeights=#(1.0);leaf.sourceRadii=#(4.0);leaf.paintEnabled=false)
a.uiPaintSetID=a.layerID
root.refreshAll()
select node;max modify mode;modPanel.setCurrentObject root
if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
local key=root.procInputKey(),epoch=root.procEpoch,builds=for leaf in root.layerObjects collect leaf.procPreparedBuilds
local start=timestamp()
root.mainUI.selectLayerView a expand:true
local firstMs=timestamp()-start,editor=CyrusLayerEditor
P07Assert (editor!=undefined and editor.root==root and editor.owner==a) "Wrong initial binding"
P07Assert (editor.editors.count==3) "All topics were eagerly created"
for topic=1 to 6 do editor.showTopic topic
P07Assert (editor.editors.count==16) "Missing topic sections"
local handles=for r in editor.editors collect r.hwnd
for topic=1 to 6 do (
    editor.showTopic topic
    for i=1 to 6 do for page in editor.pages[i] do P07Assert (page.visible==(i==topic)) "Hidden topic still visible"
)
for size in #([720,500],[1100,900],[680,420],[920,800]) do (
    setDialogSize editor size
    local actual=getDialogSize editor
    P07Assert (actual.x>=720 and actual.y>=500 and editor.clientSize==actual) "Resize lost the actual client size"
    P07Assert (editor.statisticsTab.pos.x+editor.statisticsTab.width<=actual.x-8) "Resize clipped the topic tabs"
    P07Assert (editor.refreshButton.pos.y==actual.y-34) "Resize left the footer outside the dialog"
    for page in editor.pages do (
        P07Assert (page[1].width==(actual.x-24)/2 and page[2].pos.x==actual.x/2+4) "Resize did not reflow both columns"
        P07Assert (page[1].height==actual.y-204) "Resize did not resize the scroll viewport"
    )
)
editor.showTopic 5
local cleanupLayout=UI071Section #cleanCheck
for pass=1 to 5 do (
    updateRolloutLayout cleanupLayout forceUpdate:true
    P07Assert (cleanupLayout.cleanCheck.pos.y==34 and cleanupLayout.neighborSpin.pos.y==62) "Resize restored obsolete cleanup positions"
)
P07Assert ((for r in editor.editors collect r.hwnd) as string==handles as string) "Navigation or resize replaced controls"
P07Assert (root.procInputKey()==key and root.procEpoch==epoch) "Browsing changed input key or published placements"
P07Assert ((for leaf in root.layerObjects collect leaf.procPreparedBuilds) as string==builds as string) "Browsing regenerated candidates"
local spacing=UI071Section #scopeList
editor.showTopic 5
for scope=1 to 4 do (spacing.scopeList.selection=scope;spacing.bindRule resetPeer:true)
P07Assert (root.procRuleScope.count==0 and not a.procSelfOverride) "Rule browsing authored overrides"
spacing.scopeList.selection=1;spacing.bindRule resetPeer:true
spacing.enabledCheck.checked=true;spacing.enabledCheck.changed true
spacing.multiplierSpin.value=1.5;spacing.multiplierSpin.changed 1.5
spacing.gapSpin.value=12;spacing.gapSpin.changed 12
P07Assert (a.procSelfOverride and a.procSelfEnabled and a.procSelfMultiplier==1.5 and a.procSelfGap==12) "Automatic self-spacing failed"
spacing.scopeList.selection=2;spacing.bindRule resetPeer:true
spacing.enabledCheck.checked=true;spacing.enabledCheck.changed true
spacing.gapSpin.value=8;spacing.gapSpin.changed 8
P07Assert (a.procSiblingEnabled and a.procSiblingGap==8) "Sibling defaults failed"
spacing.scopeList.selection=3;spacing.bindRule resetPeer:true
spacing.peerList.selection=2;spacing.bindRule()
local chosen=spacing.peers[2]
spacing.gapSpin.value=33;spacing.gapSpin.changed 33
P07Assert (root.procRuleGap[root.procPair 1 a chosen]==33) "Paint-set pair failed"
root.bindNativeUI()
P07Assert (spacing.peers[spacing.peerList.selection]==chosen and spacing.gapSpin.value==33) "Refresh lost selected peer"
spacing.scopeList.selection=4;spacing.bindRule resetPeer:true
spacing.peerList.selection=2;spacing.bindRule();chosen=spacing.peers[2]
spacing.enabledCheck.checked=true;spacing.enabledCheck.changed true
spacing.gapSpin.value=22;spacing.gapSpin.changed 22
P07Assert (root.procRuleEnabled[root.procPair 2 a chosen] and root.procRuleGap[root.procPair 2 a chosen]==22) "Layer pair failed"
P07Assert (root.procEpoch==epoch) "Manual rule edits published before Update"
root.refreshAll();epoch=root.procEpoch
clearUndoBuffer()
spacing.gapSpin.value=47;spacing.gapSpin.changed 47
max undo
P07Assert (spacing.gapSpin.value==22 and root.procRuleGap[root.procPair 2 a chosen]==22) "Undo did not refresh floating fields"
max redo
P07Assert (spacing.gapSpin.value==47 and spacing.peers[spacing.peerList.selection]==chosen) "Redo lost value or peer"
-- Selecting scene models closes the Modify panel but must keep owner bindings.
select source;windows.processPostedMessages()
P07Assert (CyrusLayerEditor==editor and editor.owner==a and not root.mainUI.controlsReady) "Selection lost the editor"
local oldAmount=a.amount,oldSecond=second.amount,pop=UI071Section #countSpin
editor.showTopic 2
pop.countSpin.value=oldAmount+17;pop.countSpin.changed (oldAmount+17)
P07Assert (a.amount==oldAmount+17 and second.amount==oldSecond) "Detached panel edited the wrong layer"
local switchMs=#()
for i=1 to 30 do (
    start=timestamp();editor.retarget root (if mod i 2==0 then a else second);append switchMs (timestamp()-start)
)
P07Assert ((for r in editor.editors collect r.hwnd) as string==handles as string) "Layer switching replaced controls"
P07Assert ((UI071Section #countSpin).countSpin.value==a.amount) "Rebinding lost population value"
-- Top-level set selector changes set fields, never layer population ownership.
editor.showTopic 1
local setIndex=findItem editor.sets b
editor.selectSet setIndex
P07Assert ((UI071Section #plantList).obj==b and (UI071Section #countSpin).owner==a) "Set/layer ownership crossed"
local pool=UI071Section #containersList
pool.modeList.selection=4;(pool.currentSet()).containerSetMode pool.modes[4]
pool.createContainer.pressed()
P07Assert (b.containerNodes.count==1 and b.containerMode==4) "Set source rectangle action failed"
editor.selectSet 1
-- Two independent roots share the editor object, not each other's values.
local node2=AminScatterObject name:"UI071_Second_Controller",root2=node2.baseObject
root2.updateMode=1;root2.newLayer();local layer2=root2.selectedLayer();layer2.amount=19
editor.retarget root2 layer2
editor.showTopic 2
P07Assert (editor.root==root2 and (UI071Section #countSpin).countSpin.value==19) "Second Scatter retained first values"
(UI071Section #countSpin).countSpin.value=27;(UI071Section #countSpin).countSpin.changed 27
P07Assert (layer2.amount==27 and a.amount==oldAmount+17) "Second Scatter edit crossed roots"
editor.showTopic 5
local cleanup=UI071Section #cleanCheck
P07Assert (cleanup.prioritySpin.visible and cleanup.boundaryRelaxCheck.visible) "Legacy controls were not restored on root switch"
editor.retarget root a;editor.showTopic 5
P07Assert (not cleanup.prioritySpin.visible and not cleanup.boundaryRelaxCheck.visible and cleanup.cleanCheck.visible) "Procedural page shows obsolete controls"
-- The documented ten-population capacity stays usable without ten page trees.
while root.layerObjects.count<10 do root.newLayer()
root.bindNativeUI();editor.retarget root a
P07Assert (editor.members.count==8 and root.layerObjects.count==10 and editor.editors.count==16) "Ten-population navigation failed"
local failed=false
try(root.copyLogicalLayer a)catch(failed=true)
P07Assert failed "Capacity limit was not enforced"
-- Removing a different layer keeps this editor; removing its owner closes it.
root.removeLogicalLayer (root.logicalLayers())[8]
P07Assert (CyrusLayerEditor==editor and editor.owner==a) "Unrelated removal closed editor"
root.removeLogicalLayer a
P07Assert (CyrusLayerEditor==undefined) "Deleted layer left an editable stale owner"
max undo
CyrusOpenLayerEditor root a
P07Assert (CyrusLayerEditor.owner==a) "Undo/reopen did not restore layer"
CyrusCloseLayerEditor()
P07Assert (CyrusLayerEditor==undefined) "Close retained the editor"
CyrusOpenLayerEditor root a
delete node
if CyrusLayerEditor!=undefined do CyrusLayerEditor.statusTimer.tick()
P07Assert (CyrusLayerEditor==undefined) "Deleted Scatter retained the editor"
CyrusOpenLayerEditor root2 layer2
saveMaxFile (MCPFixtureDir+"ui071-reopen.max") quiet:true
loadMaxFile (MCPFixtureDir+"ui071-reopen.max") quiet:true
P07Assert (CyrusLayerEditor==undefined) "File open retained old scene references"
node2=getNodeByName "UI071_Second_Controller";root2=node2.baseObject;layer2=root2.selectedLayer()
CyrusOpenLayerEditor root2 layer2
P07Assert (CyrusLayerEditor.owner==layer2 and layer2.amount==27) "Saved settings did not reopen"
resetMaxFile #noPrompt
P07Assert (CyrusLayerEditor==undefined) "Reset retained old editor"
UI071EditorResults=#(#("first_assets_open_ms",firstMs),#("warm_owner_switch_ms",switchMs),#("sections",16),#("all_feature_controls_preserved",true),#("two_roots",true),#("ten_populations",true),#("manual_autosave",true),#("undo_redo_fields",true),#("selection_retains_owner",true),#("source_rectangle_ui",true),#("lifecycle",true),#("pointer_test",false))
CSPWriteText (MCPFixtureDir+"layer-editor-071-events.json") (CSPObject UI071EditorResults)
)
