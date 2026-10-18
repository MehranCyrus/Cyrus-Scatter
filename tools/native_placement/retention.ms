(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native retention host required"
 local command=(dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")
 global NRNode,NRRoot,NRLeaf,NRTerrain,NRModel,NRPinned,NRPinHash,NRStorage,NRBefore
 fn NRcheck yes text=(if not yes do throw ("Native retention: "+text))
 fn NRapply=(NRRoot.refreshAll();for leaf in NRRoot.layerObjects do NRcheck (leaf.previewError=="") leaf.previewError)
 case command of (
  "compact": (
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    NRTerrain=plane width:100 length:100 widthsegs:64 lengthsegs:64;NRModel=pyramid width:.3 depth:.3 height:1 pos:[75,0,0]
    NRNode=AminScatterObject name:"Native retention";NRRoot=NRNode.baseObject;NRRoot.updateMode=1;NRRoot.autoRender=false;NRRoot.newLayer()
    NRLeaf=NRRoot.selectedLayer();NRRoot.setLayerSurfaces NRLeaf #(NRTerrain);NRLeaf.sources=#(NRModel);NRLeaf.amount=200000
    NRLeaf.procSelfOverride=true;NRLeaf.procSelfEnabled=true;NRLeaf.sourceRadiiWU=#(2.0);NRapply()
   )
   NRPinned=NRRoot.groupSnapshotRows[1];NRPinHash=cyrusRecipePublicationFingerprint #(NRPinned);NRStorage=cyrusPlacementStorageStats NRPinned
   NRcheck (NRStorage[1]>0 and NRStorage[1]<25000 and NRStorage[2]<=NRStorage[1]*96 and NRStorage[3]==0) "High-rejection accepted pin owns only compact records"
   NRLeaf.amount=5000;NRapply();gc light:true
   NRcheck (cyrusRecipePublicationFingerprint #(NRPinned)==NRPinHash) "Old compact pin remains immutable across successor"
  )
  "pinRelease": (
   NRNode=undefined;NRRoot=undefined;NRLeaf=undefined;NRTerrain=undefined;NRModel=undefined
   with undo off resetMaxFile #noPrompt;gc light:true
   NRcheck ((cyrusPlacementMemoryStats())[1]==NRStorage[2]) "Old accepted pin does not retain rejected pool after scene departure"
   NRPinned=undefined;gc light:true;NRcheck ((cyrusPlacementMemoryStats())[1]==0) "Compact pin final release"
  )
  "tenLayers": (
   with undo off (
    resetMaxFile #noPrompt
    NRTerrain=plane width:100 length:100 widthsegs:16 lengthsegs:16;NRModel=pyramid width:.3 depth:.3 height:1 pos:[75,0,0]
    NRNode=AminScatterObject name:"Native shared million cap";NRRoot=NRNode.baseObject;NRRoot.updateMode=1;NRRoot.autoRender=false
    for i=1 to 10 do (
     NRRoot.newLayer();NRLeaf=NRRoot.selectedLayer();NRRoot.setLayerSurfaces NRLeaf #(NRTerrain);NRLeaf.sources=#(NRModel);NRLeaf.amount=100000
     NRLeaf.procSelfOverride=true;NRLeaf.procSelfEnabled=false;NRLeaf.sourceRadiiWU=#(0.0)
    );NRapply()
   )
   NRcheck (NRRoot.layerObjects.count==10 and (for leaf in NRRoot.layerObjects where leaf.generatedCount!=100000 collect leaf).count==0) "Ten populations share one million bound"
   NRBefore=NRRoot.procNativePublication;NRPinHash=cyrusRecipePublicationFingerprint NRRoot.groupSnapshotRows
   NRLeaf.amount=100001;NRRoot.refreshAll()
   NRcheck (NRLeaf.previewError!="" and NRRoot.procNativePublication==NRBefore and cyrusRecipePublicationFingerprint NRRoot.groupSnapshotRows==NRPinHash) "Root cap rejection retains all ten populations"
   NRLeaf.amount=100000;NRapply()
  )
  "empty": (
   for leaf in NRRoot.layerObjects do leaf.amount=0
   NRapply();NRcheck ((NRRoot.procPublicationInfo())[5]==0) "Ten empty populations publish coherently"
   for i=1 to 9 do (NRRoot.selectLayer NRRoot.layerObjects.count;NRRoot.removePopulation())
   NRLeaf=NRRoot.layerObjects[1];NRTerrain.widthsegs=256;NRTerrain.lengthsegs=256;NRLeaf.amount=50000;NRapply()
   NRcheck (NRLeaf.generatedCount==50000 and (getPolygonCount NRTerrain)[1]>=131072) "High face-count receiver"
  )
  "release": (
   NRNode=undefined;NRRoot=undefined;NRLeaf=undefined;NRTerrain=undefined;NRModel=undefined;NRBefore=undefined
   with undo off resetMaxFile #noPrompt;gc light:true
   NRcheck ((cyrusPlacementMemoryStats())[1]==0) "Ten-population capacity and history release"
  )
  default:throw "Unknown native retention phase"
 )
 local log=openFile(MCPFixtureDir+"native-retention.txt") mode:"a";if log==undefined do log=createFile(MCPFixtureDir+"native-retention.txt")
 format "PASS % storage=% memory=%\n" command NRStorage (cyrusPlacementMemoryStats()) to:log;close log
)
