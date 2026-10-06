(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/common.ms"
 RSReload();try(CoronaRenderer.CoronaFp.showVfb false)catch()
 global RSPointerBaseline=RSRows(),RSPointerHistory,RSPointerLeaf,RSPointerBrush
 RSPointerLeaf=RSRoot.layerObjects[7];RSPointerHistory=cyrusBrushHistory RSPointerLeaf.paintDocument
 RSRoot.updateMode=1;RSPointerLeaf.uiPaintSetID=RSPointerLeaf.layerID
 viewport.setCamera (getNodeByName "03 PLAN | layout and roads")
 viewport.setRenderLevel #smoothhighlights;RSRoot.setGroupDisplay 1
 select RSNode;max modify mode;modPanel.setCurrentObject RSRoot
 CyrusOpenLayerEditor RSRoot RSPointerLeaf
 CyrusLayerEditor.showTopic 3
 RSPointerBrush=undefined
 for section in CyrusLayerEditor.activeEditors() where isProperty section #beginButton do RSPointerBrush=section
 RSAssert (RSPointerBrush!=undefined) "Paint editor did not mount"
 RSPointerBrush.modeRadio.state=1;RSPointerBrush.radiusSpin.value=140;RSPointerBrush.strengthSpin.value=100;RSPointerBrush.softSpin.value=20
 RSPointerBrush.saveOptions()
 setDialogPos CyrusLayerEditor [980,130]
 completeRedraw()
)
