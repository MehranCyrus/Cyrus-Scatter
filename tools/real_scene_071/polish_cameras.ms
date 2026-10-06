(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/common.ms"
 CyrusCloseLayerEditor();RSReload()
 local before=RSRows(),hero=getNodeByName "01 HERO | garden pavilion"
 hero.pos=[2850,-3850,3300];hero.target.pos=[0,-180,50];hero.fov=50
 for index in #(7,8) do cyrusBrushSettings RSRoot.layerObjects[index].paintDocument 38 1 .2 false 1
 RSRoot.layerObjects[7].uiPaintSetID=RSRoot.layerObjects[7].layerID
 viewport.setCamera hero;viewport.setRenderLevel #smoothhighlights
 RSRoot.refreshAll();RSAssert (RSEqual before (RSRows())) "Camera or next-stroke settings changed planting"
 renderWidth=1400;renderHeight=980;renderers.current.progressive_passLimit=24;renderers.current.progressive_timeLimit=0
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 RSReload();RSAssert (RSEqual before (RSRows())) "Presentation save changed planting"
 select RSNode;max modify mode;modPanel.setCurrentObject RSRoot;completeRedraw()
)
