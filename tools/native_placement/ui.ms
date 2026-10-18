(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native UI host required"
 global UINode,UIRoot,UILeaf,UIBefore
 with undo off (
  resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
  local terrain=plane width:100 length:100,model=pyramid width:.3 depth:.3 height:1 pos:[75,0,0]
  UINode=AminScatterObject name:"Native 0.86 UI test";UIRoot=UINode.baseObject;UIRoot.autoRender=false;UIRoot.updateMode=1;UIRoot.showCenters=true
  UIRoot.newLayer();UILeaf=UIRoot.selectedLayer();UIRoot.setLayerSurfaces UILeaf #(terrain);UILeaf.sources=#(model);UILeaf.amount=50000;UILeaf.showCenters=true
  UILeaf.procSelfOverride=true;UILeaf.procSelfEnabled=false;UILeaf.sourceRadiiWU=#(0.0);UIRoot.refreshAll()
 )
 if UILeaf.previewError!="" do throw UILeaf.previewError
 select UINode;max modify mode;modPanel.setCurrentObject UINode
 if not UIRoot.mainUI.controlsReady do UIRoot.mainUI.mountTimer.tick()
 for slot in UIRoot.mainUI.slots do (slot.open=true;slot.rolledUp false)
 cyrusPlacementTransportStats true
 UIBefore=#(UIRoot.procEpoch,UIRoot.groupBuilds,UILeaf.procPreparedBuilds,UILeaf.previewBuildCount,cyrusPlacementTransportStats())
 saveMaxFile (MCPFixtureDir+"Native086-UI-"+((GetUIScaleFactor()) as string)+".max") quiet:true
 local f=createFile(MCPFixtureDir+"native-ui-before.txt");format "%\n%\n" (GetUIScaleFactor()) UIBefore to:f;close f
)
