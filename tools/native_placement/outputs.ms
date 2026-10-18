-- Actual PFlow evaluation and paged instance Bake in an owned Max 2027 host.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned output host required"
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NOExpected,NOGroupExpected,NOParticles,NOBaked,NOHash,NOPin
 fn NOcheck yes message=(if not yes do throw ("Native outputs: "+message))
 fn NOwrite text=(local f=openFile(MCPFixtureDir+"native-outputs.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-outputs.txt");format "% %\n" NCKind text to:f;close f)
 fn NOapply=(NCRoot.refreshAll();if NCLeaf.previewError!="" do throw NCLeaf.previewError)
 fn NOequal a b=(local worst=0.0;for row=1 to 4 do worst=amax worst (distance a[row] b[row]);worst<0.00001)
 fn NOactual=(
  local groups=#()
  for pf in CyrusPFNodes where classof pf==PF_Source do (
   pf.updateParticles pf currentTime
   append groups (for i=1 to pf.numParticles() collect #(pf.getParticleTM i,pf.getParticleScaleXYZ i))
  );groups
 )
 case command[1] of (
  "compare": (
   NCRoot.updateMode=1;CyrusPFTimer.Stop();CyrusPFClear()
   with undo off (
    NCLeaf.autoRender=true;NCRoot.autoRender=true;NCLeaf.amount=1001
    append NCModels (box name:"Native output second source" width:0.2 length:0.4 height:0.8 pos:[75,5,0])
    NCModels[1].material=standardMaterial diffuse:red;NCModels[2].material=standardMaterial diffuse:green
    NCLeaf.sources=NCModels;NCLeaf.sourceWeights=#(0.4,0.6);NCLeaf.sourceScales=#(1.3,0.7)
    NCLeaf.wholeScaleMin=0.5;NCLeaf.wholeScaleMax=1.7
    NCLeaf.yawMinimum=0;NCLeaf.yawMaximum=360;NCLeaf.tiltDegrees=15
   )
   NCRoot.procNativeRoute=false;NOapply();NOExpected=NCLeaf.placements (NCLeaf.outputSources())
   NOGroupExpected=for source in NCModels collect #()
   for row in NOExpected do append NOGroupExpected[row[2]] row[1]
   NOcheck (CyrusPFBuild()) CyrusPFLastError;NOParticles=NOactual();CyrusPFClear()
   NCRoot.procNativeRoute=true;NOapply();NOHash=cyrusRecipePublicationFingerprint NCRoot.groupSnapshotRows
   local before=cyrusPlacementTransportStats(),groups=cyrusPlacementTransformGroups NCRoot.groupSnapshotRows[1]
   NOcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Grouping creates no script matrices/rows"
   NOcheck (groups.count==NOGroupExpected.count) "All source slots retained"
   for k=1 to groups.count do (
    NOcheck (groups[k].count==NOGroupExpected[k].count) "Group count"
    for i=1 to groups[k].count do NOcheck (NOequal groups[k][i] NOGroupExpected[k][i]) "Every accessor matrix matches"
   )
   local detached=groups[1][1];detached.row4=[999,999,999]
   NOcheck (NOequal groups[1][1] NOGroupExpected[1][1]) "Accessor is detached"
   local rejected=false;try(groups[1][0])catch(rejected=true);NOcheck rejected "Zero index rejects"
   rejected=false;try(groups[1][groups[1].count+1])catch(rejected=true);NOcheck rejected "Oversize index rejects"
   NOcheck (CyrusPFBuild()) CyrusPFLastError
   NOcheck (CyrusPFPublications.count==1) "PFlow pins its complete native publication"
   local actual=NOactual();NOcheck (actual.count==NOParticles.count) "Actual PF source count"
   for k=1 to actual.count do (
    NOcheck (actual[k].count==NOParticles[k].count) "Actual PF particle count"
    for i=1 to actual[k].count do (
     NOcheck (NOequal actual[k][i][1] NOParticles[k][i][1]) "Actual PF matrix equals legacy PF"
     NOcheck (distance actual[k][i][2] NOParticles[k][i][2]<0.00001) "Actual PF scale equals legacy PF"
    )
   )
   NOwrite "PASS native accessor and every actual PFlow matrix/scale"
   NOPin=CyrusPFPublications[1];local frame=NCRoot.procNativePublication
   NCLeaf.amount=2003;NOapply()
   NOcheck (CyrusPFPublications[1]==frame and NOPin==frame) "Active PF data keeps old generation across a successor"
   NOcheck (CyrusPFBuild()) CyrusPFLastError;NOcheck (CyrusPFPublications[1]==NCRoot.procNativePublication) "Explicit PF rebuild adopts complete successor"
   NOPin=undefined;CyrusPFClear();NOcheck (CyrusPFPublications.count==0 and CyrusPFData.count==0) "Clear releases PF pins"
   NCLeaf.amount=1001;NOapply();NOcheck (NOHash==cyrusRecipePublicationFingerprint NCRoot.groupSnapshotRows) "Restored output is exact"
   NCLeaf.bakeInstances NCNode;NOBaked=NCLeaf.bakedNodes as array
   NOcheck (NOBaked.count==NOExpected.count) "Bake crosses 500-row page boundaries without omissions"
   for i=1 to NOBaked.count do (
    NOcheck (NOBaked[i].baseObject==NCModels[NOExpected[i][2]].baseObject) "Bake instances exact source"
    NOcheck (NOequal NOBaked[i].transform NOExpected[i][1]) "Bake matrix"
    NOcheck (NOBaked[i].material==NCModels[NOExpected[i][2]].material) "Bake material"
   )
   NOwrite "PASS paged Bake 1001 instances source/material/matrix"
   max undo
  )
  "undo": (NOcheck (NCLeaf.bakedNodes.count==0 and (for n in NOBaked where isValidNode n collect n).count==0 and NCLeaf.autoRender) "Bake Undo restores authored visibility/render settings and deletes output";max redo)
  "redo": (
   NOcheck (NCLeaf.bakedNodes.count==1001 and (for n in NOBaked where isValidNode n collect n).count==1001) "Bake Redo restores the same nodes"
   -- Render/preview settings belong to the root. Its normal callback rebinds
   -- leaves after history; calling the leaf Bake command does not author root flags.
   NOcheck (NCLeaf.autoRender==NCRoot.autoRender and NCLeaf.showPoints==NCRoot.showPoints) "History preserves controller-owned display/render settings"
   NOwrite "PASS Bake Undo/Redo"
   NCLeaf.clearBaked NCNode;NOBaked=#();NCLeaf.amount=0;NOapply();NCLeaf.bakeInstances NCNode
   NOcheck (NCLeaf.bakedNodes.count==0) "Empty native Bake produces no nodes"
   NOExpected=undefined;NOGroupExpected=undefined;NOParticles=undefined;NOBaked=undefined;NOPin=undefined
   CyrusPFClear();NOwrite "PASS empty Bake and PF clear"
  )
  default:throw "Unknown output test phase"
 )
)
