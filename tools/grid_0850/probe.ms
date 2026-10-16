(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-grid0850-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"probe-"+(timeStamp() as string)+".txt")
 local root=(getNodeByName "Grid qualification").baseObject,leaf=root.layerObjects[1]
 format "root % leaf %\nsettings %\nplan %\nerror %\n" root.placementMode leaf.placementMode (leaf.gridPayload()) leaf.procReceiverPlanData leaf.previewError to:log
 try(root.evaluateProcedural();format "PASS direct evaluate\n" to:log)catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)
