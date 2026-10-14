(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 global P05UIStage
 if P05UIStage==undefined do P05UIStage=0
 local stage=P05UIStage+1
 local log=if stage==1 then createFile (MCPFixtureDir+"phase05-ui.txt") else openFile (MCPFixtureDir+"phase05-ui.txt") mode:"a"
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  case stage of (
   1: (
    verify ((cyrusBrushStats P05UIArea.paintDocument)[1]==P05UIRevision+1) "Physical Pick spline button and viewport selection import into captured Paint Area" log
    verify (P05UIRoot.procEpoch==P05UIEpoch and (with printAllElements on (P05UIRoot.groupSnapshotRows as string))==P05UIRows) "Physical import preserves Manual publication" log
    verify (isValidNode P05UICurve and P05UICurve.radius==10 and selection[1]==P05UINode) "Picker preserves source and Scatter selection" log
    P05UIRevision=(cyrusBrushStats P05UIArea.paintDocument)[1]
   )
   2: (
    verify ((cyrusBrushStats P05UIArea.paintDocument)[1]==P05UIRevision and P05UIRoot.procEpoch==P05UIEpoch) "Physical picker cancellation leaves area and publication unchanged" log
   )
   3: (
    verify (selection.count==1 and superclassof selection[1]==Shape and selection[1]!=P05UICurve and numSplines selection[1]==1 and isClosed selection[1] 1) "Physical Export spline creates and selects closed snapshot" log
    verify ((cyrusBrushStats P05UIArea.paintDocument)[1]==P05UIRevision and P05UIRoot.procEpoch==P05UIEpoch) "Physical export stays passive across control teardown" log
    P05UIRoot.refreshAll()
    verify (P05UILeaf.generatedCount>80 and P05UILeaf.generatedCount<200) "Explicit Update applies picked circle coverage" log
    verify (not theHold.Holding()) "Physical conversion leaves no stranded hold" log
    format "COMPLETE\n" to:log
   )
  )
  P05UIStage=stage;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
