-- Private Max integration test of rule events and native page lifetime.
if findString MCPFixtureDir "/procedural07-ui-"==undefined do throw "Private UI fixture required"
global P07New,P07Root,P07Node,P07Layer,P07Source,P07Assert,P07Case,CSPWriteText,CSPObject
global P07UIResult,P07UIBaseline,P07UIHandles,P07UIRollouts
P07Case="native UI and automatic spacing"
P07New count:240
local root=P07Root,a=P07Layer,b=root.addPaintSet P07Layer label:"Blue",c=root.addPaintSet P07Layer label:"Yellow"
root.newLayer();local second=root.selectedLayer();second.amount=30
root.newLayer();local third=root.selectedLayer();third.amount=30
a.uiPaintSetID=a.layerID
for leaf in root.layerObjects do (leaf.sources=#(P07Source);leaf.sourceColors=#(color 70 180 80);leaf.sourceWeights=#(1.0);leaf.sourceRadii=#(4.0);leaf.paintEnabled=false)
root.refreshAll()
saveMaxFile (MCPFixtureDir+"PRIVATE-UI-TEST.max") quiet:true
select P07Node;max modify mode;modPanel.setCurrentObject root
if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
root.mainUI.selectLayerView a expand:true
local panel=root.layerPanels[1],u=panel.editors[10]
u.open=true;root.mainUI.layoutPanels()
P07Assert (cyrusBindRolloutScroll panel.hwnd>0) "Nested sections were not bound to their current native column"
local before=(root.procStatistics())[5],builds=for leaf in root.layerObjects collect (leaf.procStatistics())[3]
-- Selectors and programmatic binding must never create or change a rule.
local oldRules=root.procRuleScope as string
for scope=1 to 4 do (u.scopeList.selection=scope;u.bindRule resetPeer:true;u.bind a)
P07Assert (root.procRuleScope as string==oldRules and (root.procStatistics())[5]==before) "Browsing rules edited scene data"
u.scopeList.selection=1;u.bindRule resetPeer:true
u.enabledCheck.checked=true;u.enabledCheck.changed true
u.multiplierSpin.value=1.5;u.multiplierSpin.changed 1.5
u.gapSpin.value=12;u.gapSpin.changed 12
u.planarCheck.checked=true;u.planarCheck.changed true
P07Assert (a.procSelfOverride and a.procSelfEnabled and a.procSelfMultiplier==1.5 and a.procSelfGap==12 and a.procSelfPlanar) "Self rule did not save automatically"
u.scopeList.selection=2;u.bindRule resetPeer:true
u.enabledCheck.checked=true;u.enabledCheck.changed true
u.gapSpin.value=8;u.gapSpin.changed 8
P07Assert (a.procSiblingEnabled and a.procSiblingGap==8) "Sibling default did not save"
u.scopeList.selection=3;u.bindRule resetPeer:true
u.peerList.selection=2;u.bindRule()
local chosen=u.peers[2]
u.gapSpin.value=33;u.gapSpin.changed 33
local pair=root.procPair 1 a chosen
P07Assert (pair>0 and root.procRuleGap[pair]==33) "Paint-set pair did not save"
root.bindNativeUI()
P07Assert (u.peerList.selection==2 and u.peers[2]==chosen and u.gapSpin.value==33) "Binding changed selected spacing peer"
u.scopeList.selection=4;u.bindRule resetPeer:true
u.peerList.selection=2;u.bindRule();chosen=u.peers[2]
u.enabledCheck.checked=true;u.enabledCheck.changed true
u.gapSpin.value=22;u.gapSpin.changed 22
pair=root.procPair 2 a chosen
P07Assert (pair>0 and root.procRuleEnabled[pair] and root.procRuleGap[pair]==22) "Layer pair did not save"
windows.processPostedMessages();completeRedraw()
P07Assert ((root.procStatistics())[5]==before) "Manual mode published before Update"
root.refreshAll()
P07Assert ((root.procStatistics())[5]>before) "Update failed to publish saved rules"
before=(root.procStatistics())[5]
-- A field change has a real scene Undo entry; browsing afterwards is read-only.
clearUndoBuffer()
u.gapSpin.value=47;u.gapSpin.changed 47
max undo
P07Assert (root.procRuleGap[root.procPair 2 a chosen]==22) "Automatic spacing Undo failed"
max redo
P07Assert (root.procRuleGap[root.procPair 2 a chosen]==47) "Automatic spacing Redo failed"
u.bind a
P07Assert (u.peerList.selection==2 and u.gapSpin.value==47) "Redo lost pair selection/value"
u.resetRule.pressed()
P07Assert ((root.procPair 2 a chosen)==0 and u.peerList.selection==2) "Inheritance reset failed"
root.refreshAll()
-- Resize re-evaluates native layout expressions. It must preserve fitted
-- subrollout height, controls, accepted rows and retained preview data.
for r in panel.editors do r.open=true
root.mainUI.layoutPanels()
local expected=panel.contentHeight,handles=for r in panel.editors collect r.hwnd
before=(root.procStatistics())[5]
builds=for leaf in root.layerObjects collect (leaf.procStatistics())[3]
local display=for leaf in root.layerObjects collect (leaf.cacheSnapshot())[6]
for i=1 to 20 do (
    updateRolloutLayout panel forceUpdate:true
    P07Assert (panel.sections.height==expected) "Resize reset the content height"
    panel.open=false;panel.open=true
)
for i=1 to panel.editors.count do P07Assert (panel.editors[i].hwnd==handles[i]) "Rollup toggle replaced native controls"
P07Assert ((root.procStatistics())[5]==before) "Layout regenerated placements"
P07Assert ((for leaf in root.layerObjects collect (leaf.procStatistics())[3]) as string==builds as string) "Layout rebuilt candidate caches"
P07Assert ((for leaf in root.layerObjects collect (leaf.cacheSnapshot())[6]) as string==display as string) "Layout rebuilt preview caches"
-- EndEditParams/BeginEditParams and add/copy/reorder/remove/Undo exercise
-- hidden native slots without touching generation order or random seeds.
for i=1 to 3 do (
    clearSelection();windows.processPostedMessages()
    select P07Node;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.bindNativeUI()
    P07Assert (root.layerPanels.count==3 and root.layerPanels[1].owner==a) "Reopening lost layer ownership"
)
local clone=root.copyLogicalLayer a
root.bindNativeUI();P07Assert (root.layerPanels.count==4) "Copied layer page missing"
root.procMove clone -1;root.bindNativeUI()
P07Assert (root.layerPanels[3].owner==clone) "Layer order not reflected by native pages"
root.removeLogicalLayer clone;root.bindNativeUI()
P07Assert (root.layerPanels.count==3) "Removed layer page remains"
max undo
root.bindNativeUI();P07Assert (root.layerPanels.count==4) "Undo failed to restore layer page"
max redo
root.bindNativeUI();P07Assert (root.layerPanels.count==3) "Redo failed to remove layer page"
root.refreshAll()
for p in root.layerPanels do (p.open=true;p.mount();for r in p.editors do r.open=false)
root.layerPanels[1].editors[10].open=true
root.layersUI.open=true;root.previewUI.open=true
root.mainUI.layoutPanels();root.mainUI.scrollPos=0
P07UIRollouts=join (root.nativeEditors()) root.layerPanels
P07UIHandles=for p in root.layerPanels collect #(p.hwnd,for r in p.editors collect r.hwnd)
P07UIBaseline=#((root.procStatistics())[5],for leaf in root.layerObjects collect (leaf.procStatistics())[3],for leaf in root.layerObjects collect (leaf.cacheSnapshot())[6])
P07UIResult=#(#("passed",true),#("automatic_scopes",4),#("manual_publish_guard",true),#("undo_redo",true),#("peer_preserved",true),#("layout_cycles",20),#("zero_generation",true),#("zero_preview_builds",true),#("reopen_cycles",3),#("layer_structure_undo",true))
CSPWriteText (MCPFixtureDir+"ui-acceptance.json") (CSPObject P07UIResult)
saveMaxFile (MCPFixtureDir+"PRIVATE-UI-TEST.max") quiet:true
