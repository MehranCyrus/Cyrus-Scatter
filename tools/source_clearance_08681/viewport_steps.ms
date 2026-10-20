(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-perf-*-2027/" do throw "Owned performance host required"
 global VPBefore,VPMaps,VPKey,VPEpoch,VPLevel,VPModifier,VPOriginalMap,VPAnimatedMap,VPPeer
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"generation-command.txt")
 local log=openFile (MCPFixtureDir+"viewport-steps-r2.txt") mode:"a"
 fn verify value label log=(format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn key root=cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("steps") #()
 fn draw root=(root.refreshDisplay();redrawViews();completeRedraw())
 try(
  case phase of(
   "texture":(PFRoot.identificationMode=4;draw PFRoot)
   "colored":(PFRoot.identificationMode=1;draw PFRoot)
   "radius":(
    VPBefore=cyrusRetainedStreamStats();VPMaps=cyrusMaterialPreviewStats()
    PFLeaf.setSourceRadius #{1} 7;PFRoot.evaluateProcedural();draw PFRoot
   )
   "check-radius":(
    local stats=cyrusRetainedStreamStats()
    format "Radius streams before %, after %\n" VPBefore stats to:log
    verify (stats[2]==VPBefore[2] and stats[3]>VPBefore[3]) "Radius uploads transforms while retaining source geometry" log
    verify ((cyrusMaterialPreviewStats())[2]==VPMaps[2]) "Radius does not bake textures across presented frames" log
    VPBefore=stats;VPMaps=cyrusMaterialPreviewStats();VPKey=key PFRoot;VPEpoch=PFRoot.procEpoch
    clearSelection();select PFNode;draw PFRoot
   )
   "check-selection":(
    local stats=cyrusRetainedStreamStats()
    verify (stats[2]==VPBefore[2] and stats[3]==VPBefore[3] and (cyrusMaterialPreviewStats())[2]==VPMaps[2]) "Selection does not rebuild or upload geometry/transforms/textures" log
    verify (key PFRoot==VPKey and PFRoot.procEpoch==VPEpoch) "Selection preserves placement publication" log
   )
   "opacity":(
    VPMaps=cyrusMaterialPreviewStats();VPKey=key PFRoot;VPEpoch=PFRoot.procEpoch
    VPLevel=PFThird.material.opacityLevel;PFThird.material.opacityLevel=0;draw PFRoot
   )
   "check-opacity":(
    verify ((cyrusMaterialPreviewStats())[2]>VPMaps[2]) "Opacity material edit refreshes source appearance" log
    verify (key PFRoot==VPKey and PFRoot.procEpoch==VPEpoch) "Opacity edit preserves placement publication" log
    PFThird.material.opacityLevel=VPLevel;draw PFRoot
   )
   "geometry":(
    VPKey=key PFRoot;VPEpoch=PFRoot.procEpoch
    VPModifier=Push();VPModifier.push_value=2;addModifier PFThird VPModifier
    draw PFRoot
    verify (key PFRoot==VPKey and PFRoot.procEpoch==VPEpoch) "Manual geometry edit preserves previous placements" log
    verify (PFLeaf.previewError!="") "Pending geometry refuses incompatible material correspondence" log
   )
   "update-geometry":(
    PFRoot.refreshAll();draw PFRoot
    verify (PFLeaf.previewError=="" and PFRoot.procEpoch>VPEpoch) "Explicit Update accepts changed source geometry" log
    deleteModifier PFThird VPModifier;PFRoot.refreshAll();draw PFRoot
   )
   "uv":(
    PFRoot.refreshAll();draw PFRoot
    VPKey=key PFRoot;VPEpoch=PFRoot.procEpoch;VPMaps=cyrusMaterialPreviewStats()
    VPModifier=UVWMap();VPModifier.mapChannel=1;VPModifier.maptype=0
    VPModifier.length=10;VPModifier.width=10;addModifier PFThird VPModifier;draw PFRoot
    verify ((cyrusMaterialPreviewStats())[2]>VPMaps[2]) "Source UV modifier invalidates appearance data" log
    verify (key PFRoot==VPKey and PFRoot.procEpoch==VPEpoch and PFLeaf.previewError=="") "UV-only edit refreshes appearance without changing placements" log
    deleteModifier PFThird VPModifier;draw PFRoot
   )
   "live-radius":(
    PFRoot.updateMode=2;CyrusPointSuspended=false
    VPEpoch=PFRoot.procEpoch;VPMaps=cyrusMaterialPreviewStats()
    PFLeaf.setSourceRadius #{1} 8;draw PFRoot
   )
   "check-live":(
    verify (PFRoot.procEpoch>VPEpoch and PFLeaf.previewError=="") "Live radius edit publishes automatically" log
    verify ((cyrusMaterialPreviewStats())[2]==VPMaps[2]) "Live radius edit does not rebake materials" log
    VPKey=key PFRoot;VPEpoch=PFRoot.procEpoch;VPMaps=cyrusMaterialPreviewStats()
    sliderTime=20f;draw PFRoot
   )
   "check-time":(
    verify (key PFRoot==VPKey and PFRoot.procEpoch==VPEpoch and (cyrusMaterialPreviewStats())[2]==VPMaps[2]) "Unrelated animation time preserves static placement and appearance" log
    sliderTime=0f;draw PFRoot;PFRoot.updateMode=1;CyrusPointSuspended=true
   )
   "animate-map":(
    PFRoot.newLayer();VPPeer=PFRoot.selectedLayer();VPPeer.amount=10
    VPPeer.addModelSource PFModels[1];PFRoot.setGroupDisplay 3;PFRoot.identificationMode=4
    PFRoot.refreshAll();draw PFRoot
    VPOriginalMap=PFModels[1].material.baseTexmap;VPAnimatedMap=Noise()
    with animate on (at time 0f VPAnimatedMap.phase=0;at time 20f VPAnimatedMap.phase=1)
    PFModels[1].material.baseTexmap=VPAnimatedMap;sliderTime=0f;draw PFRoot
    VPKey=key PFRoot;VPEpoch=PFRoot.procEpoch
   )
   "animate-frame":(
    VPMaps=cyrusMaterialPreviewStats();sliderTime=10f;draw PFRoot
   )
   "check-animated":(
    local stats=cyrusMaterialPreviewStats()
    format "Animated shared source: before %, after %\n" VPMaps stats to:log
    verify (stats[2]>VPMaps[2] and stats[3]>VPMaps[3]) "Animated map refreshes and shares its new appearance with both layers" log
    verify (key PFRoot==VPKey and PFRoot.procEpoch==VPEpoch) "Animated material does not recalculate placements" log
    VPMaps=stats;sliderTime=0f;draw PFRoot
   )
   "restore-animation":(
    verify ((cyrusMaterialPreviewStats())[2]>VPMaps[2]) "Reverse timeline updates animated map data" log
    PFModels[1].material.baseTexmap=VPOriginalMap;draw PFRoot
    PFRoot.removeLogicalLayer VPPeer;PFRoot.refreshAll();PFRoot.selectLayer 1;draw PFRoot
   )
   "save":(saveMaxFile (MCPFixtureDir+"three-leaves-final.max") quiet:true;format "SUCCESS\n" to:log)
   default:throw ("Unknown viewport step "+phase)
  )
 )catch(format "ERROR %: %\n%\n" phase (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)
