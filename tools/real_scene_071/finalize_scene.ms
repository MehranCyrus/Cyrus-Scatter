(
 RSReload()
 local before=RSRows(),oldKey=RSRoot.procInputKey()
 local camera=getNodeByName "04 SOURCES | model containers"
 if camera==undefined do (
  camera=TargetCamera name:"04 SOURCES | model containers" pos:[4550,-3200,3100] target:(Targetobject pos:[4550,-1000,0]) fov:51
  (LayerManager.getLayerFromName "06 Cameras and light").addNode camera
  (LayerManager.getLayerFromName "06 Cameras and light").addNode camera.target
 )
 RSRoot.setGroupDisplay 1;RSRoot.updateMode=1
 viewport.setCamera (getNodeByName "01 HERO | garden pavilion");viewport.setRenderLevel #smoothhighlights
 select RSNode;max modify mode;modPanel.setCurrentObject RSRoot
 if not RSRoot.mainUI.controlsReady do RSRoot.mainUI.mountTimer.tick()
 RSAssert (oldKey==RSRoot.procInputKey() and RSEqual before (RSRows())) "Camera/display setup changed placements"
 renderers.current.progressive_passLimit=24;renderers.current.progressive_timeLimit=0;renderWidth=1400;renderHeight=980
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 RSReload();RSAssert (RSEqual before (RSRows())) "Final scene did not roundtrip"
 CSPWriteText (MCPFixtureDir+"final-roundtrip.json") (CSPObject #(#("passed",true),#("counts",for r in before collect r.count),#("brush_histories",#(cyrusBrushHistory RSOwners[2].paintDocument,cyrusBrushHistory RSFlowers.paintDocument)),#("product",RSRoot.uiVersion())))
)
