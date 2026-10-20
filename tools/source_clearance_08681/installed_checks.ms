(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-perf-installed*-2027/" do throw "Owned installed host required"
 local log=createFile (MCPFixtureDir+"installed-checks.txt")
 fn verify value label log=(format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn key root=cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("installed") #()
 fn calculate root=(root.evaluateProcedural();root.refreshDisplay();for leaf in root.layerObjects do if leaf.previewError!="" do throw leaf.previewError)
 try(
  PFRoot.updateMode=1
  PFLeaf.sourceWeights[3]=0;calculate PFRoot
  local before=key PFRoot
  PFLeaf.setSourceClearance #{3} #clearancePreferred true;calculate PFRoot
  verify (key PFRoot==before) "Unused real model preference preserves placement and radii" log
  PFLeaf.setSourceClearance #{3} #clearancePreferred false
  PFLeaf.sourceWeights[3]=1;calculate PFRoot
  before=key PFRoot
  local identities=PFLeaf.sourceRowIDs as array
  local scene=MCPFixtureDir+"installed-three-leaves.max"
  saveMaxFile scene quiet:true
  loadMaxFile scene quiet:true
  PFNode=getNodeByName "200-leaf performance";PFRoot=PFNode.baseObject;PFLeaf=PFRoot.selectedLayer()
  PFModels=PFLeaf.validSources();PFThird=PFModels[3]
  calculate PFRoot
  verify (PFRoot.uiVersion()=="0.86.8.1" and PFModels.count==3) "Installed build reopens all three real models" log
  verify ((PFLeaf.sourceRowIDs as array) as string==identities as string and key PFRoot==before) "Save/reopen preserves source identities and placement fingerprint" log
  local maps=cyrusMaterialPreviewStats()
  PFRoot.identificationMode=1;PFRoot.setGroupDisplay 3;PFRoot.refreshDisplay()
  PFRoot.identificationMode=4;PFRoot.refreshDisplay()
  verify (key PFRoot==before and PFLeaf.previewError=="") "Installed Mesh/Textured switching preserves reopened placements" log
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)
