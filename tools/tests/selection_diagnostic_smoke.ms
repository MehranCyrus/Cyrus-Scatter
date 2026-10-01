-- Fresh batch process only; this script creates a disposable scene.
(
 global AminScatterObject,CyrusSurfaceAnalyzer,CyrusSelectionDiagnosticHeadless,CyrusSelectionDiagnostic
 global CyrusSelectionNodes,CyrusSelectionState,CyrusSelectionReport,CyrusSelectDirect
 global CyrusSelectionCore,CyrusSelectionLocked,CyrusSelectionUnlock
 global CyrusIconPickingHeadless,CyrusIconPickingTest,CyrusIconProbeCreate,CyrusIconProbeRemove,CyrusIconProbeNodes,CyrusIconProbeDraw
 local root=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath(getSourceFileName()))+"../../")
 local folder=root+"build/selection-diagnostic-test/"
 makeDir folder all:true
 local log=createFile (folder+"result.txt")
 fn require condition reason = (if not condition do throw reason)
 try (
  fileIn(root+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
  fileIn(root+"AminScatter/scripts/AminScatterObject.ms")
  local scatter=AminScatterObject name:"Selection_Test_Scatter"
  local analyzer=CyrusSurfaceAnalyzer name:"Selection_Test_Analyzer"
  local normal=box name:"Selection_Test_Box" pos:[100,0,0]
  local testLayer=LayerManager.newLayerFromName "Selection_Test_Layer"
  testLayer.addNode analyzer
  testLayer.isFrozen=true
  local beforeHandles=for n in selection collect n.handle
  CyrusSelectionDiagnosticHeadless=true
  fileIn(root+"tools/CyrusSelectionDiagnostic.ms")
  local core=CyrusSelectionCore()
  local previousLock=CyrusSelectionLocked()
  require(previousLock!=undefined) "Selection lock API unavailable"
  select normal
  core.FreezeSelection()
  format "Selection lock native value after FreezeSelection: %\n" core.SelectionFrozen to:log;flush log
  require(CyrusSelectionLocked()==true) "Failed to detect selection lock ON"
  CyrusSelectionReport (CyrusSelectionNodes())
  require(CyrusSelectionLocked()==true) "Read-only report changed selection lock"
  require(CyrusSelectionUnlock()) "Explicit selection unlock failed"
  require(CyrusSelectionLocked()==false) "Failed to detect selection lock OFF"
  if previousLock do core.FreezeSelection()
  clearSelection()
  format "PASS selection lock ON/OFF detection, read-only reporting and explicit unlock\n" to:log;flush log
  local nodes=CyrusSelectionNodes()
  require(nodes.count==2) "Did not find both controller types"
  local filterBefore=#(ViewportFilter.Enabled,ViewportFilter.ShowRenderable)
  ViewportFilter.ShowRenderable=true
  ViewportFilter.Enabled=true
  local filteredReport=CyrusSelectionReport nodes
  require(matchPattern filteredReport pattern:"*ViewportFilter enabled: true | renderable-only: true*") "Viewport filter missing from report"
  require(not (ViewportFilter.IsNodeShown scatter)) "Renderable-only filter did not exclude Scatter"
  require(ViewportFilter.IsNodeShown normal) "Renderable-only filter unexpectedly excluded renderable Box"
  require(ViewportFilter.Enabled and ViewportFilter.ShowRenderable) "Report changed viewport filter"
  ViewportFilter.Enabled=false
  require(ViewportFilter.IsNodeShown scatter) "Scatter still excluded with viewport filter disabled"
  ViewportFilter.ShowRenderable=filterBefore[2]
  ViewportFilter.Enabled=filterBefore[1]
  format "PASS viewport renderable-only filter exclusion and read-only reporting\n" to:log;flush log
  local report=CyrusSelectionReport nodes
  require(testLayer.isFrozen and analyzer.isFrozen) "Diagnostic changed frozen flags"
  require((for n in selection collect n.handle) as string==beforeHandles as string) "Diagnostic changed selection"
  require(matchPattern report pattern:"*frozen=true*") "Layer freeze missing from report"
  local output=createFile(folder+"scene-state.txt")
  format "%" report to:output;close output
  format "PASS read-only scan and inherited layer freeze reporting\n" to:log;flush log
  testLayer.isFrozen=false
  for n in #(scatter,analyzer) do (
   select normal;clearSelection()
   require(CyrusSelectDirect n) "Direct reselection failed"
   require(selection.count==1 and selection[1]==n) "Wrong selected node"
   clearSelection()
   require(CyrusSelectDirect n) "Second reselection failed"
   local m=snapshotAsMesh n
   local degenerate=0
   for f=1 to m.numfaces do (
    local face=getFace m f
    local a=getVert m (face.x as integer),b=getVert m (face.y as integer),c=getVert m (face.z as integer)
    if length(cross(b-a)(c-a))<0.0000001 do degenerate+=1
   )
   format "%: direct reselection PASS; icon faces=% degenerate=%\n" n.name m.numfaces degenerate to:log;flush log
   delete m
  )
  createDialog CyrusSelectionDiagnostic
  destroyDialog CyrusSelectionDiagnostic
  format "PASS diagnostic dialog creation\n" to:log;flush log
  CyrusIconPickingHeadless=true
  fileIn(root+"tools/CyrusIconPickingTest.ms")
  local countBefore=objects.count
  local sizeBefore=#(scatter.iconSize,analyzer.iconSize)
  CyrusIconProbeCreate()
  require(CyrusIconProbeNodes.count==4 and objects.count==countBefore+4) "Wrong probe count"
  for i=1 to 4 do (
   local n=CyrusIconProbeNodes[i]
   require(not n.renderable) "Probe could render"
   local m=snapshotAsMesh n
   local zero=0
   for f=1 to m.numfaces do (
    local face=getFace m f
    local a=getVert m (face.x as integer),b=getVert m (face.y as integer),c=getVert m (face.z as integer)
    if length(cross(b-a)(c-a))<0.0000001 do zero+=1
   )
   if mod i 2==0 then require(zero==0) "Valid probe has degenerate faces"
   else require(zero==m.numfaces) "Original probe differs from degenerate construction"
   select n
   require(n.isSelected) "Probe cannot be selected by script"
   format "% faces=% degenerate=%\n" n.name m.numfaces zero to:log;flush log
   delete m
  )
  createDialog CyrusIconPickingTest
  destroyDialog CyrusIconPickingTest
  require(objects.count==countBefore) "Closing test panel left probe objects"
  require(isValidNode scatter and isValidNode analyzer) "Test removed a controller"
  require(scatter.iconSize==sizeBefore[1] and analyzer.iconSize==sizeBefore[2]) "Test changed icon sizes"
  format "PASS icon probe geometry, non-renderable flags, dialog and owned cleanup\nSUCCESS\n" to:log;close log
 )catch(
  format "FAILED: %\n" (getCurrentException()) to:log;close log;throw()
 )
)
