(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"physical-mask-phase.txt")
 case phase of (
  "shown":(
   if CyrusMeshMaskPreviewTarget!=DLayer or CyrusMeshMaskPreviewRows==undefined or CyrusMeshMaskPreviewError!="" do throw "Mouse Show mask failed"
   global PhysicalMaskBefore=#(DRoot.procEpoch,DRoot.groupBuilds,cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows,DLayer.invertDensity)
  )
  "inverted":(
   if DLayer.invertDensity==PhysicalMaskBefore[4] do throw "Mouse Invert did not change authored input"
   if CyrusMeshMaskPreviewTarget!=DLayer or CyrusMeshMaskPreviewRows==undefined or CyrusMeshMaskPreviewError!="" do throw "Invert lost visible mask"
   if DRoot.procEpoch!=PhysicalMaskBefore[1] or DRoot.groupBuilds!=PhysicalMaskBefore[2] or (cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows)!=PhysicalMaskBefore[3] do throw "Mask edit recalculated Manual plants"
  )
  "hidden":(
   if CyrusMeshMaskPreviewTarget!=undefined do throw "Mouse Hide mask failed"
  )
  default:throw "Unexpected physical mask phase"
 )
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"physical-mask-"+phase+".txt") ("PASS: Mouse density mask "+phase+" verified; Manual publication preserved.")
)
