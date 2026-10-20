(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 gc light:false
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"elevation-phase.txt"),log=createFile (MCPFixtureDir+"elevation-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn refresh=(ERoot.refreshAll();ERoot.evaluateProcedural())
 fn fingerprint=(cyrusRecipePublicationFingerprint ERoot.groupSnapshotRows)
 fn fieldInfo=(cyrusDensityOverlayInfo (cyrusPrepareDensityOverlay #(ETerrain) (ELayer.meshMaskPayload()) undefined (ELayer.densityMappingPayload()) ELayer.densityUVChannel 2 4096 false (ELayer.surfaceFilterPayload()) false #() #(#(),#())))
 try(case phase of (
  "setup":(
   global ERoot,ELayer,ENode,ETerrain,EModel,EHash,EKey,ECounts,EMapSupport
   CyrusClearMeshMaskPreview undefined;CyrusPointSuspended=true
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.
    ETerrain=plane name:"Elevation terrain" width:1000 length:1000 widthsegs:1 lengthsegs:1 mapCoords:false;convertToMesh ETerrain
    EModel=box name:"Elevation model" width:5 length:5 height:10 pos:[-750,0,0];EModel.isHidden=true
    ENode=AminScatterObject name:"Elevation scatter";ERoot=ENode.baseObject;ERoot.updateMode=1;ERoot.newLayer();ELayer=ERoot.selectedLayer()
    ERoot.setLayerSurfaces ELayer #(ETerrain);ELayer.sources=#(EModel);ELayer.sourceWeights=#(1.);ELayer.sourceRadiiWU=#(0.);ELayer.amount=1000
    ELayer.procSelfOverride=true;ELayer.procSelfEnabled=false;ELayer.procLayerSelfEnabled=false
    ELayer.meshMaskSource=2;ELayer.meshMaskEnabled=true;ELayer.meshMaskChannel=2
   )
   EMapSupport=meshop.getMapSupport ETerrain 2
   select ENode;max modify mode;ERoot.bindNativeUI()
  )
  "flat":(
   refresh();local info=fieldInfo()
   check (ERoot.groupSnapshotRows[1].count==0 and info[2]==0 and info[3]==0) "Flat receiver is lowest elevation and excludes a non-inverted field" log
   ELayer.meshMaskInvert=true;refresh();info=fieldInfo()
   check (ERoot.groupSnapshotRows[1].count==1000 and info[2]==1 and info[3]==1) "Inverted flat field admits all plants with matching preview" log
   check (ELayer.previewError=="" and (meshop.getMapSupport ETerrain 2)==EMapSupport) "Relative elevation requires and creates no mesh channel" log
  )
  "slope":(
   ELayer.meshMaskInvert=false
   for i=1 to ETerrain.numverts do (local v=getVert ETerrain i;v.z=(v.x+500)/2;setVert ETerrain i v);update ETerrain;refresh()
   ECounts=ERoot.groupSnapshotRows[1].count;EKey=cyrusMeshDensityKey ETerrain (ELayer.meshMaskPayload());EHash=fingerprint()
   check (ECounts>350 and ECounts<650) "Linear receiver elevation admits approximately half the candidates" log
   local samples=cyrusMeshDensityPreview ETerrain (ELayer.meshMaskPayload()) 2048
   for sample in samples do check (abs(sample[2]-(sample[1].x+500)/1000)<0.00001) "Native field centroid agrees with analytic height fraction" log
   local info=fieldInfo();check (info[2]==0 and info[3]==1) "Continuous mask spans the receiver's lowest and highest points" log
  )
  "transforms":(
   ETerrain.pos=[70000,-20000,100000];ETerrain.rotation=eulerAngles 12 18 30;ETerrain.scale=[-1.2,.8,1.5];refresh()
   check ((cyrusMeshDensityKey ETerrain (ELayer.meshMaskPayload()))==EKey and ELayer.previewError=="") "Relative local height survives mirrored nonuniform scale, rotation and translation" log
   ETerrain.transform=matrix3 1
   for i=1 to ETerrain.numverts do (local v=getVert ETerrain i;v.z+=12000;setVert ETerrain i v);update ETerrain;refresh()
   check ((cyrusMeshDensityKey ETerrain (ELayer.meshMaskPayload()))==EKey and ERoot.groupSnapshotRows[1].count==ECounts) "Local height translation keeps exact eligibility" log
   for i=1 to ETerrain.numverts do setVert ETerrain i ((getVert ETerrain i)/100);update ETerrain
   units.SystemType=#meters;refresh()
   check ((cyrusMeshDensityKey ETerrain (ELayer.meshMaskPayload()))==EKey and ERoot.groupSnapshotRows[1].count==ECounts) "Physical unit rescaling keeps the same normalized field and eligibility" log
  )
  "channels":(
   EHash=fingerprint();ELayer.meshMaskSource=1;local failed=false
   try(ERoot.evaluateProcedural())catch(failed=true;format "EXPECTED: %\n" (getCurrentException()) to:log)
   check (failed and fingerprint()==EHash) "Explicit channel mode still rejects an absent channel and retains publication" log
   ELayer.meshMaskSource=2;refresh();check (fingerprint()==EHash) "Switching back to relative elevation recovers the exact result" log
   ELayer.meshMaskEnabled=false;refresh();check (ERoot.groupSnapshotRows[1].count==1000) "Disabling the field removes its density filtering" log
   ELayer.meshMaskEnabled=true;refresh();check (fingerprint()==EHash) "Re-enabling the field restores exact eligibility" log
  )
  "save":(check (saveMaxFile (MCPFixtureDir+"elevation.max") quiet:true) "Relative elevation saves" log)
  "reopen":(loadMaxFile (MCPFixtureDir+"elevation.max") quiet:true;ENode=getNodeByName "Elevation scatter";ERoot=ENode.baseObject;ELayer=ERoot.layerObjects[1];ETerrain=getNodeByName "Elevation terrain")
  "verifyReopen":(refresh();check (ELayer.meshMaskSource==2 and fingerprint()==EHash) "Scene reopen preserves field mode and exact publication" log)
  default:throw "Unknown elevation phase"
 );format "PASS: complete\n" to:log;close log)catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
