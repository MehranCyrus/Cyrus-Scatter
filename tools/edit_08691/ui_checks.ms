-- Focused Max 2027 acceptance. Only an owned disposable profile may run this.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/quality_validation/common.ms"
global UIRun,UIPage,UIMap,UIEpoch,UIBuilds,UIFingerprint,UICounters,UIRenders
fn UIRun scenario = (
 case scenario of (
  "density": (
   QSetup();QMount pages:#("managerUISlot","populationUISlot")
   UIPage=QRoot.populationUI;UIEpoch=QRoot.procEpoch;UIBuilds=QRoot.groupBuilds;UIFingerprint=QFingerprint()
   QLayer.amount=517
   QAssert (UIPage.distributionUI_mapBrowseButton.map==undefined and UIPage.distributionUI_mapBrowseButton.visible and UIPage.distributionUI_densityButton.visible) "map_empty" "Both native map targets remain visible while empty."
   UIMap=Checker name:"UI91 procedural checker"
   UIPage.distributionUI_mapBrowseButton.picked UIMap
   QAssert (QLayer.densityMap==UIMap and UIPage.distributionUI_mapBrowseButton.map==UIMap and classof UIPage.distributionUI_imageThumbnail.bitmap==Bitmap) "map_preview" "The actual Map handler retains an editable procedural graph and displays a bitmap preview."
   UIRenders=UIPage.distributionUI_thumbnailRenders;UICounters=QLayer.densityCacheStats()
   for i=1 to 50 do (UIPage.distributionUI_syncControls();UIPage.layout())
   QAssert (UIPage.distributionUI_thumbnailRenders==UIRenders and CyrusPresetSameValues UICounters (QLayer.densityCacheStats())) "preview_reuse" "Fifty passive bindings reuse the thumbnail without placement-density bakes."
   UIMap.color1=color 200 10 40;QSettle 300;UIPage.distributionUI_syncControls()
   QAssert (UIPage.distributionUI_thumbnailRenders==UIRenders+1) "preview_revision" "A procedural-map parameter edit invalidates exactly one thumbnail."
   UIPage.distributionUI_mapBrowseButton.picked undefined
   QAssert (QLayer.densityMap==undefined and UIPage.distributionUI_imageThumbnail.bitmap==undefined and UIPage.distributionUI_densityButton.visible) "map_clear" "Clear releases the preview and leaves an empty drop target."
   max undo;QSettle 200;UIPage.distributionUI_syncControls()
   QAssert (QLayer.densityMap==UIMap and UIPage.distributionUI_imageThumbnail.bitmap!=undefined) "map_undo" "Undo restores the same map graph and a usable preview."
   QAssert (QRoot.procEpoch==UIEpoch and QRoot.groupBuilds==UIBuilds and QFingerprint()==UIFingerprint and QLayer.amount==517) "manual_preserved" "Thumbnail and map authoring preserve the complete publication and pending Manual count."
  )
  "drop_prepare": (
   QSetup();QMount pages:#("populationUISlot")
   UIPage=QRoot.populationUI;UIMap=Checker name:"Drag this density map"
   UIEpoch=QRoot.procEpoch;UIBuilds=QRoot.groupBuilds;UIFingerprint=QFingerprint()
   meditMaterials[1]=UIMap;MatEditor.mode=#basic;MatEditor.open()
   QAssert (QLayer.densityMap==undefined) "drop_ready" "Native Map target empty; the Compact Material Editor exposes a real texture-map swatch."
  )
  "drop_verify": (
   QSettle 400
   QAssert (QLayer.densityMap==UIMap and UIPage.distributionUI_mapBrowseButton.map==UIMap) "drop_assigned" "Physical swatch drag to the initially empty Map button assigns the map instance."
   QAssert (UIPage.distributionUI_imageThumbnail.bitmap!=undefined and QRoot.procEpoch==UIEpoch and QRoot.groupBuilds==UIBuilds and QFingerprint()==UIFingerprint) "drop_preview_manual" "Dropped procedural map has a thumbnail and preserves Manual placements."
   MatEditor.close()
  )
  "layout_prepare": (
   MatEditor.close();QSetup();QMount pages:#("managerUISlot","surfacesUISlot","containersUISlot","populationUISlot")
   UIEpoch=QRoot.procEpoch;UIFingerprint=QFingerprint();QLayer.amount=517
   QAssert true "layout_ready" "Real command-panel controls ready for width changes."
  )
  "layout_verify": (
   QSettle 300
   local main=QRoot.mainUI,manager=QRoot.managerUI
   local inner=windows.getWindowPos main.hwnd removeUIScaling:true,outer=windows.getWindowPos (windows.getHWNDData main.hwnd)[2] removeUIScaling:true,width=outer.w
   QAssert (abs(inner.x-outer.x)<1 and abs(inner.w-width)<2 and abs(main.updateNow.pos.x-8)<1 and abs(main.updateNow.width-(width-16))<2) "main_width" "Main dialog fills its actual native rollup body; buttons have eight-unit insets from that body."
   local hostWidth=(windows.getWindowPos QRoot.managerUISlot.hwnd removeUIScaling:true).w
   inner=windows.getWindowPos manager.hwnd removeUIScaling:true;outer=windows.getWindowPos QRoot.managerUISlot.hwnd removeUIScaling:true
   local shell=windows.getWindowPos (windows.getHWNDData QRoot.managerUISlot.hwnd)[2] removeUIScaling:true
   local listRect=windows.getWindowPos manager.flow_layersUI_layerList_colored.hwnd[1] removeUIScaling:true
   -- Max can retain an oversized nested HWND after column reflow. Verify the
   -- visible controls against the clipping slot, rather than that hidden width.
   QAssert (abs(outer.x-shell.x)<1 and abs(outer.w-shell.w)<2 and abs(inner.x-outer.x)<1 and listRect.x-outer.x>=4 and listRect.x-outer.x<=12 and outer.x+outer.w-listRect.x-listRect.w>=4 and outer.x+outer.w-listRect.x-listRect.w<=20) "layers_width" "Layers fills its native column body, and its visible list has bounded insets within the clipping slot."
   QAssert (QRoot.procEpoch==UIEpoch and QFingerprint()==UIFingerprint and QLayer.amount==517) "layout_manual" "Column resizing preserves placements and pending Manual edits."
   local f=createFile (MCPFixtureDir+"layout-widths.txt")
   format "main=% control_x=% control_width=% layers_slot=% layers_body=%\n" width main.updateNow.pos.x main.updateNow.width hostWidth manager.lastLayoutWidth to:f;close f
  )
  "geometry_probe": (
   local main=QRoot.mainUI,f=createFile (MCPFixtureDir+"geometry-probe.txt")
   format "scale=% main.width=% main.rect=% removed=%\n" (GetUIScaleFactor()) main.width (windows.getWindowPos main.hwnd) (windows.getWindowPos main.hwnd removeUIScaling:true) to:f
   for c in #(main.updateNow,main.licenseButton) do format "control % pos=% width=% rect=% removed=% parent=%\n" c c.pos c.width (windows.getWindowPos c.hwnd[1]) (windows.getWindowPos c.hwnd[1] removeUIScaling:true) (windows.getHWNDData c.hwnd[1]) to:f
   local handle=main.hwnd
   for i=1 to 6 while handle!=0 do (format "ancestor=% data=% rect=%\n" handle (windows.getHWNDData handle) (windows.getWindowPos handle) to:f;handle=(windows.getHWNDData handle)[2])
   close f;QAssert true "geometry_recorded" "Read-only rollout/control and ancestor geometry captured."
  )
  "width_prototype": (
   local page=QRoot.mainUI,rect=windows.getWindowPos page.hwnd,parent=(windows.getHWNDData page.hwnd)[2],outer=windows.getWindowPos parent
   local localPos=windows.screenToClient parent rect.x rect.y
   windows.setWindowPos page.hwnd 0 localPos.y outer.w rect.h true
   QSettle 100
   QAssert (abs(page.updateNow.width-(outer.w-16))<2) "native_resize_event" "A native dialog-width change invokes the existing MAXScript resize handler."
  )
  "layout_reselect": (
   for i=1 to 3 do (clearSelection();QSettle 100;select QNode;max modify mode;QSettle 500)
   QAssert (QRoot.mainUI.controlsReady and QRoot.procEpoch==UIEpoch and QFingerprint()==UIFingerprint and QLayer.amount==517) "layout_reselect" "Repeated teardown and remount preserve pending Manual edits and the complete publication."
  )
  default:throw "Unknown UI91 scenario"
 )
)
