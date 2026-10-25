-- Restore only the disposable owned scene, retaining its private transport.
global TOwner,TRoot,TEdit,TRocks,PWatching,PObserve,PSettle,CyrusPerfHeadless,CyrusPointSuspended,CyrusPFResume
PWatching=false;try(unregisterRedrawViewsCallback PObserve)catch()
loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/interactions087-pointer-20261025-05/Terraces_087_Artist_Stage.max" quiet:true useFileUnits:true
TOwner=getNodeByName "CyrusScatter 0.87 - Terrace contact study";TRoot=TOwner.baseObject;TEdit=TOwner.modifiers[1];TRocks=TRoot.layerObjects[6]
CyrusPerfHeadless=false;CyrusPointSuspended=false;CyrusPFResume=false
TRoot.identificationMode=4;TRoot.autoRender=true
local originalRock=getNodeByName "rock-foreground"
if isValidNode originalRock do (hide originalRock;originalRock.renderable=false)
TRoot.refreshAll();CyrusPointSync();completeRedraw();PSettle 900
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 700
local position=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation
viewport.setLayout #layout_1;viewport.setType #view_top;viewport.setRenderLevel #smoothhighlights
undo off (
    local frame=plane name:"087 temporary view frame" width:320 length:320 pos:position
    select frame;max zoomext sel all;delete frame
)
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 900
