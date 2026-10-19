(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"mask-probe.txt")
 format "target_same=% rows_same=% pending=% error=% channel=% enabled=% owner=% layer=%\n" (CyrusMeshMaskPreviewTarget==DLayer) (CyrusMeshMaskPreviewRows==MaskComplete) CyrusMeshMaskPreviewPending CyrusMeshMaskPreviewError DLayer.meshMaskChannel DLayer.meshMaskEnabled CyrusMeshMaskPreviewTarget.layerID DLayer.layerID to:log
 format "ROWS=% COMPLETE=% STATS=%\n" CyrusMeshMaskPreviewRows MaskComplete (cyrusDensityOverlayStats()) to:log
 try(format "KEY=%\n" (cyrusMeshDensityKey DTerrain (DLayer.meshMaskPayload())) to:log)catch(format "KEY ERROR=%\n" (getCurrentException()) to:log)
 close log
)
