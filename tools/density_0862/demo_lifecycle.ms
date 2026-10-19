(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"demo-phase.txt"),log=createFile (MCPFixtureDir+"demo-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  case phase of (
   "curvature":(
    global CurvLayer=Demo0862Root.layerObjects[6],CurvTerrain=(CurvLayer.validSurfaces())[1],CurvModifier=undefined,CurvKey="",CurvBuilds=0L,CurvHash="",CurvValue=0.
    CurvModifier=CurvTerrain.modifiers[1];CurvValue=CurvModifier.operators[1].scale
    CyrusMaskView=3;CyrusMaskDetail=2;CyrusShowMeshMaskPreview CurvLayer
    CurvKey=cyrusMeshDensityKey CurvTerrain (CurvLayer.meshMaskPayload());CurvBuilds=(cyrusDensityOverlayStats())[1]
    CurvHash=cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows
    undo "Curvature channel edit" on CurvModifier.operators[1].scale=0.15
   )
   "curvatureVerify":(
    check ((cyrusMeshDensityKey CurvTerrain (CurvLayer.meshMaskPayload()))!=CurvKey) "Real Data Channel curvature edit changes numeric data at the same frame" log
    check (CyrusMeshMaskPreviewTarget==CurvLayer and (cyrusDensityOverlayStats())[1]>CurvBuilds and CyrusMeshMaskPreviewError=="") "Visible field follows the modifier edit without Hide/Show" log
    check ((cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows)==CurvHash) "Curvature field editing retains Manual plant output" log
    max undo
   )
   "curvatureUndo":(
    check (CurvModifier.operators[1].scale==CurvValue and (cyrusMeshDensityKey CurvTerrain (CurvLayer.meshMaskPayload()))==CurvKey) "Modifier Undo restores exact channel values" log
    check (CyrusMeshMaskPreviewTarget==CurvLayer and CyrusMeshMaskPreviewError=="") "Mask stays visible after modifier Undo" log
    CyrusClearMeshMaskPreview undefined
   )
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
