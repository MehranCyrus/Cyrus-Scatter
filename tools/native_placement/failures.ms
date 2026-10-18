-- Nonshipping native fault qualification, only in the guarded owned host.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativegenerate-hold-*/" or cyrusOwnedNativeFault==undefined do throw "Owned fault build required"
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NFNode,NFRoot,NFLeaf,NFEdit,NFTerrain,NFModel,NFPaint
 fn NFcheck yes text=(if not yes do throw ("Native failure qualification: "+text))
 fn NFhash=(cyrusPlacementPublicationFingerprint NFRoot.groupSnapshotRows NFRoot.procPublishedRadii #("failure") (for leaf in NFRoot.layerObjects collect #(leaf.procLastStats,leaf.procLastRounds,leaf.procLastSurfaceStats)))
 fn NFapply=(NFRoot.refreshAll();for leaf in NFRoot.layerObjects do NFcheck (leaf.previewError=="") leaf.previewError)
 fn NFlog text=(local f=openFile(MCPFixtureDir+"native-failures.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-failures.txt");format "% bytes=% edit=% leases=%\n" text (cyrusPlacementMemoryStats()) (cyrusEditMemoryStats()) (cyrusOwnedNativeLeaseCounts()) to:f;close f)
 case command[1] of (
  "setup": (
   cyrusOwnedNativeFault 0 0;with undo off (
    resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    NFTerrain=plane width:100 length:100 widthsegs:32 lengthsegs:32;NFModel=pyramid width:0.3 depth:0.3 height:1 pos:[75,0,0]
    NFNode=AminScatterObject name:"Native failure fixture";NFRoot=NFNode.baseObject;if isProperty NFRoot #procNativeRoute do NFRoot.procNativeRoute=true;NFRoot.updateMode=1;NFRoot.autoRender=false
    for i=1 to 2 do (NFRoot.newLayer();local leaf=NFRoot.selectedLayer();NFRoot.setLayerSurfaces leaf #(NFTerrain);leaf.sources=#(NFModel);leaf.amount=1001;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.sourceRadiiWU=#(0.0);leaf.showCenters=true)
    NFLeaf=NFRoot.layerObjects[1];NFEdit=CyrusScatterEdit();addModifier NFNode NFEdit
    NFPaint=NFRoot.addPaintArea NFLeaf target:NFTerrain;NFPaint.paintView=0;cyrusBrushFill NFPaint.paintDocument 1;NFLeaf.paintEnabled=true;NFapply()
   )
   undo "Native failure preceding marker" on box pos:[-75,0,0]
  )
  "fault": (
   local stage=command[2] as integer,occurrence=command[3] as integer
   local frame=NFRoot.procNativePublication,epoch=NFRoot.procEpoch,hash=NFhash(),undoNames=theHold.GetUndoNames(),caches=for leaf in NFRoot.layerObjects collect leaf.cachedPoints
   -- Both owners need changed geometry to exercise the second preview allocation.
   -- An unchanged sibling correctly reuses its retained cache.
   for leaf in NFRoot.layerObjects do leaf.amount+=1
   cyrusOwnedNativeFault stage occurrence
   try(NFRoot.refreshAll())catch()
   cyrusOwnedNativeFault 0 0
   NFcheck (NFLeaf.previewError!="") "Injected stage rejects successor"
   NFcheck (NFRoot.procNativePublication==frame and NFRoot.procEpoch==epoch and NFhash()==hash) "Previous complete epoch/fields/radii/statistics retained"
   for i=1 to caches.count do NFcheck (cyrusPreviewContentEqual caches[i] NFRoot.layerObjects[i].cachedPoints) "Every previous display retained"
   NFcheck (CyrusPresetSameValues undoNames (theHold.GetUndoNames())) "Failure preserves authored history"
   NFcheck (CyrusPresetSameValues (cyrusOwnedNativeLeaseCounts()) #(0L,0L)) "Failed Brush builder and lease release"
   NFapply();NFcheck (NFRoot.procEpoch==epoch+1) "Normal successor recovers without reset"
   NFlog ("PASS stage="+(stage as string)+" occurrence="+(occurrence as string))
  )
  "authored": (
   local before=NFhash(),selected=cyrusEditSelectedIDs #(NFEdit) NFLeaf.editLayerKey,names=theHold.GetUndoNames(),failed=false
   theHold.Begin();cyrusOwnedNativeFault 5 2
   try(cyrusEditSelect NFEdit (for i=1 to 1000 collect i))catch(failed=true)
   cyrusOwnedNativeFault 0 0;theHold.Cancel()
   NFcheck (failed and CyrusPresetSameValues selected (cyrusEditSelectedIDs #(NFEdit) NFLeaf.editLayerKey) and NFhash()==before) "Partial selection allocation leaves authored state intact"
   undo "Native failure select" on cyrusEditSelect NFEdit (for i=1 to 1000 collect i)
   NFapply();before=NFhash();selected=cyrusEditSelectedIDs #(NFEdit) NFLeaf.editLayerKey;names=theHold.GetUndoNames();failed=false
   theHold.Begin();cyrusOwnedNativeFault 5 8
   try(cyrusEditCommand NFEdit 4 (transMatrix [1,2,3]))catch(failed=true)
   cyrusOwnedNativeFault 0 0;theHold.Cancel();NFapply()
   NFcheck (failed and NFhash()==before and CyrusPresetSameValues selected (cyrusEditSelectedIDs #(NFEdit) NFLeaf.editLayerKey) and CyrusPresetSameValues names (theHold.GetUndoNames())) "Partial transform allocation leaves output, selection and history intact"
   theHold.Begin();cyrusEditCommand NFEdit 4 (transMatrix [1,0,0])
   local size=cyrusOwnedPlacementProbeHoldSize()
   NFcheck (size>0 and size<1000000L) "Actual SDK Hold Size uses changed blocks"
   theHold.Restore();theHold.Restore();theHold.Cancel();NFapply();NFcheck (NFhash()==before) "Actual repeated Restore false and Cancel retain exact output"
   NFlog ("PASS authored failure and SDK Size="+(size as string))
  )
  "bake": (
   NFLeaf.bakeInstances NFNode;local baked=NFLeaf.bakedNodes as array,hash=NFhash(),failed=false,prior=objects as array
   cyrusOwnedNativeFault 10 2
   try(NFLeaf.bakeInstances NFNode)catch(failed=true)
   cyrusOwnedNativeFault 0 0
   NFcheck (failed and CyrusPresetSameValues baked (NFLeaf.bakedNodes as array)) "Second-page Bake failure preserves previous bake ownership"
   NFcheck ((for n in baked where not isValidNode n collect n).count==0 and CyrusPresetSameValues prior (objects as array)) "500 partially created nodes removed; previous scene retained"
   NFcheck (NFhash()==hash and findItem (theHold.GetUndoNames()) "Native failure preceding marker">0) "Bake failure retains native publication and preceding Undo"
   NFLeaf.bakeInstances NFNode;NFlog "PASS partial Bake cleanup and retry"
  )
  "release": (
   cyrusOwnedNativeFault 0 0;NFNode=undefined;NFRoot=undefined;NFLeaf=undefined;NFEdit=undefined;NFPaint=undefined;NFTerrain=undefined;NFModel=undefined
   with undo off resetMaxFile #noPrompt;gc light:true
   NFcheck ((cyrusPlacementMemoryStats())[1]==0 and (cyrusEditMemoryStats())[1]==0 and CyrusPresetSameValues (cyrusOwnedNativeLeaseCounts()) #(0L,0L)) "Failure fixture releases all tracked native owners"
   NFlog "PASS final release"
  )
  default:throw "Unknown failure command"
 )
)
