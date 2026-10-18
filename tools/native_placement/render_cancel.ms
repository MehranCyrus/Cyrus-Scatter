-- Actual production cancellation in an owned normal-build Max 2027 host.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned host required"
 local command=(dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")
 global NCancelRoot,NCancelNode,NCancelEpoch,NCancelHash
 if command=="start" then (
 UIRoot=undefined;UILeaf=undefined;UINode=undefined;UIBefore=undefined
 with undo off (
  resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1
  local surface=plane width:1000 length:1000,source=pyramid width:15 depth:15 height:40 pos:[800,0,0]
  hide source;NCancelNode=AminScatterObject name:"Native cancel fixture";NCancelRoot=NCancelNode.baseObject
  NCancelRoot.updateMode=1;NCancelRoot.autoRender=true;NCancelRoot.newLayer()
  local leaf=NCancelRoot.selectedLayer();NCancelRoot.setLayerSurfaces leaf #(surface);leaf.sources=#(source);leaf.amount=120
  leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.sourceRadiiWU=#(0.0)
  NCancelRoot.refreshAll();if leaf.previewError!="" do throw leaf.previewError
  renderers.current=CoronaRenderer();renderers.current.progressive_passLimit=50000
  renderWidth=512;renderHeight=512
  local cam=targetCamera name:"NativeCancelCamera" pos:[0,-1400,1100] target:(targetObject pos:[0,0,0])
  viewport.setCamera cam;source.material=standardMaterial diffuse:green;skylight multiplier:1
 )
 NCancelEpoch=NCancelRoot.procEpoch;NCancelHash=cyrusRecipePublicationFingerprint NCancelRoot.groupSnapshotRows
 local f=createFile(MCPFixtureDir+"production-cancel-before.txt");format "% %\n" NCancelEpoch NCancelHash to:f;close f
 -- The qualification operator must observe an active production render and
 -- press its real Stop control. A .NET Timer does not dispatch during this
 -- renderer's synchronous call; never pretend such a callback qualified it.
 local result=undefined,failure=""
 try(result=render camera:(getNodeByName "NativeCancelCamera") vfb:false)catch(failure=getCurrentException())
 if result!=undefined do close result
 f=createFile(MCPFixtureDir+"production-cancel-returned.txt");format "%\n" failure to:f;close f
 ) else if command=="verify" then (
 if CoronaRenderer.getRenderType()!=0 or CyrusPFProduction or CyrusPFBusy or CyrusPFTicking or CyrusPFLastError!="" do throw "Production cancel retained render state"
 if NCancelRoot.procEpoch!=NCancelEpoch or (cyrusRecipePublicationFingerprint NCancelRoot.groupSnapshotRows)!=NCancelHash do throw "Cancel changed the complete placement result"
 local f=createFile(MCPFixtureDir+"production-cancel.txt")
 format "PASS stopped production epoch=% fullResultUnchanged=true; actual input witness is recorded separately\n" NCancelEpoch to:f;close f
 renderers.current.progressive_passLimit=2;renderWidth=96;renderHeight=96
 local result=render camera:(getNodeByName "NativeCancelCamera") vfb:false outputFile:(MCPFixtureDir+"production-after-cancel.png")
 if result==undefined or result.width!=96 do throw "Subsequent render failed after cancellation"
 close result;NCancelRoot.refreshAll()
 if (NCancelRoot.selectedLayer()).previewError!="" do throw "Update after cancel failed"
 NCancelRoot=undefined;NCancelNode=undefined;resetMaxFile #noPrompt;gc light:true
 if CyrusPFNodes.count!=0 or CyrusPFData.count!=0 or CyrusPFTimer.Enabled do throw "Reset retained native render consumers"
 f=openFile(MCPFixtureDir+"production-cancel.txt") mode:"a";format "PASS subsequent render/update/reset releases PFlow consumers\n" to:f;close f
 ) else throw "Use start, physically Stop active production, then verify"
)
