-- Owned disposable host only. Load after Max_Procedural_07_Acceptance.ms.
global F75Checks=#(),F75Check,F75Settle,F75Proxy,F75Update,F75Analyzer
fn F75Check ok label = (
 if not ok do throw ("Courtyard fix: "+label)
 append F75Checks label
 CSPWriteText (MCPFixtureDir+"courtyard-fix-checks.json") (CSPObject #(#("checks",F75Checks)))
 true
)
fn F75Settle = (CyrusPointSync();completeRedraw();windows.processPostedMessages();CyrusPointSync();completeRedraw())
fn F75Proxy = (
 P07New count:3000;local r=P07Root,a=P07Layer,n=P07Node,s=P07Source
 r.viewportInstances=3000;r.viewportFaces=2000000
 a.sclXMin=.7;a.sclXMax=1.3;a.sclYMin=.5;a.sclYMax=1.8;a.rotXMax=30;a.rotYMax=20
 -- Deliver pending source-creation/transform notifications before the baseline.
 F75Settle();r.refreshAll();F75Settle();local fp=P07Fingerprint r,epoch=r.procEpoch
 viewport.setLayout #layout_1;viewport.setType #view_persp_user
 viewport.setTM (matrix3 [1,0,0] [0,.7,.7] [0,-.7,.7] [0,0,-1600])
 for shape=1 to 3 do (
  r.proxyShape=shape;r.setGroupDisplay 2;r.refreshDisplay();F75Settle()
  local owner=CyrusPointOwner n,before=cyrusRetainedStats owner,mesh=cyrusRetainedMeshStats owner,cache=a.cachedPoints
  F75Check (mesh[2]==3000 and mesh[1]==3000*#(12,168,6)[shape]) ("Proxy shape "+shape as string+": correct instanced faces and population")
  F75Check (before[12]==1 and CyrusPointLastError=="") "Proxy retained publication accepted"
  F75Check ((cyrusPreviewDrawStats cache)[5]==0) "No expanded proxy triangle allocation"
  local builds=a.previewBuildCount,base=viewport.getTM()
  for i=1 to 8 do (viewport.setTM ((rotateZMatrix (i as float))*base);completeRedraw())
  local after=cyrusRetainedStats owner
  F75Check (after[8]>before[8] and after[9]==before[9]) "Proxy actually drew without new failures"
  for k in #(3,4,5,6,7) do F75Check (after[k]==before[k]) "Navigation reused generation, resources and upload buffers"
  F75Check (a.previewBuildCount==builds and r.procEpoch==epoch) "Proxy navigation did not prepare or publish placements"
  CyrusRetainedMeshDrawing false;F75Settle()
  F75Check (a.cachedPoints==cache and r.procEpoch==epoch and a.previewBuildCount==builds) "CPU fallback uses the same immutable proxy cache"
  CyrusRetainedMeshDrawing true;F75Settle()
  F75Check ((cyrusRetainedStats (CyrusPointOwner n))[12]==1) "Retained drawing recovered after fallback"
  r.pointColorMode=1;r.solidPointColor=(color 35 100 220);r.refreshDisplay();F75Settle()
  F75Check (r.procEpoch==epoch and (P07Fingerprint r) as string==fp as string) "Solid color is display-only"
  r.pointColorMode=2;r.identificationMode=2;r.refreshDisplay();F75Settle()
  F75Check (r.procEpoch==epoch) "Layer identification color is display-only"
 )
 for mode in #(1,3,2) do (r.setGroupDisplay mode;r.refreshDisplay();F75Settle();F75Check (r.procEpoch==epoch) "Point / Mesh / Proxy switch preserves placement publication")
 local scene=MCPFixtureDir+"proxy-fixes.max"
 saveMaxFile scene quiet:true;loadMaxFile scene quiet:true
 n=getNodeByName "P07_Controller";r=n.baseObject;r.refreshAll();F75Settle()
 F75Check ((P07Fingerprint r) as string==fp as string) "Proxy save/reopen preserves placement positions/models"
 F75Check (not (CyrusPointOwner n).renderable) "Proxy helper excluded from rendering"
 true
)
fn F75Update = (
 P07New count:1000;local r=P07Root,a=P07Layer,s=P07Source
 for i=1 to 9 do (r.newLayer();local b=r.selectedLayer();b.sources=#(s);b.amount=1000;b.paintEnabled=false)
 r.refreshAll();local old=r.procEpoch,fp=P07Fingerprint r,builds=for leaf in r.layerObjects collect leaf.procPreparedBuilds
 r.refreshAll()
 F75Check (r.procEpoch==old+1) "Ten-layer explicit Update makes one publication"
 for i=1 to 10 do F75Check (r.layerObjects[i].procPreparedBuilds==builds[i]+1 and not r.layerObjects[i].dirty and r.layerObjects[i].previewError=="") "Explicit Update prepares each layer once and marks every layer current"
 F75Check ((P07Fingerprint r) as string==fp as string) "Forced Update preserves deterministic output"
 local old=r.procEpoch;fp=P07Fingerprint r
 r.layerObjects[10].amount=500
 F75Settle();F75Check (r.procEpoch==old) "Manual pending edit waits"
 r.refreshAll();F75Check (r.procEpoch==old+1 and r.layerObjects[10].generatedCount==500) "Explicit Update handles a change in the last layer"
 fp=P07Fingerprint r;old=r.procEpoch
 r.layerObjects[10].procRounds=0
 r.refreshAll()
 F75Check (r.procEpoch==old and (for rows in r.groupSnapshotRows collect cyrusEditFingerprint rows "proc07") as string==fp as string) "Failed batched Update retains all previous rows"
 F75Check ((for leaf in r.layerObjects where leaf.previewError!="" collect leaf).count==10) "Failed Update reports every affected layer"
 true
)
fn F75Analyzer = (
 P07New count:3000;local r=P07Root,a=P07Layer,s=P07Source
 local guide=CyrusSurfaceAnalyzer name:"F75_Analyzer",an=guide.baseObject
 an.surface=P07Surface;an.resolution=48;an.pointRadius=70;an.fitRadius=40;an.relaxIterations=0;an.updateMode=1;an.runAnalysis()
 a.diversityMode=4;a.analyzerNode=guide;a.patternLines=#(guide);a.patternWidths=#(80.0);a.strokeSides=#(2);a.strokeModes=#(2)
 a.strokeSourceRows=#(1);a.strokeSourceNodes=#(s);a.strokeMin=#(1.0);a.strokeMax=#(1.0)
 r.refreshAll();F75Check (a.generatedCount>0 and a.previewError=="") "Current Analyzer produces a border"
 local old=r.procEpoch,fp=P07Fingerprint r,runs=an.getAnalysisRuns()
 r.updateMode=2;F75Settle();old=r.procEpoch
 for i=1 to 5 do (a.checkAnalyzerRevision();F75Check (not a.dirty) "Unchanged Analyzer revision leaves Live layer current";F75Settle())
 F75Check (r.procEpoch==old and an.getAnalysisRuns()==runs) "Live redraw neither republishes nor reanalyzes unchanged guides"
 r.updateMode=1;P07Surface.pos.z=10
 r.refreshAll()
 F75Check (r.procEpoch==old and findString a.previewError "Update Surface Analyzer"!=undefined) "Moved Analyzer receiver rejected with actionable error"
 F75Check ((for rows in r.groupSnapshotRows collect cyrusEditFingerprint rows "proc07") as string==fp as string) "Stale guides retain last complete scatter"
 F75Check (an.getAnalysisRuns()==runs) "Scatter Update respects Analyzer Manual mode"
 an.runAnalysis();r.refreshAll()
 F75Check (a.generatedCount>0 and a.previewError=="" and r.procEpoch==old+1) "Explicit Analyze then Update recovers"
 old=r.procEpoch;P07Surface.width+=100
 r.refreshAll()
 F75Check (r.procEpoch==old and findString a.previewError "Update Surface Analyzer"!=undefined) "Immediate geometry edit is rejected before delayed events fire"
 an.runAnalysis();r.refreshAll()
 F75Check (a.previewError=="" and an.analysisCurrent()) "Analyze consumes pending events without a false stale result"
 fp=P07Fingerprint r
 local scene=MCPFixtureDir+"analyzer-current.max"
 saveMaxFile scene quiet:true;loadMaxFile scene quiet:true
 r=(getNodeByName "P07_Controller").baseObject;a=r.layerObjects[1];an=(getNodeByName "F75_Analyzer").baseObject
 F75Check (an.analysisCurrent()) "Current Analyzer freshness survives reopen"
 r.refreshAll();F75Check ((P07Fingerprint r) as string==fp as string and a.previewError=="") "Current Analyzer scatter survives reopen"
 -- No intervening validation or message pump: save must drain pending events.
 an.surface.width+=100
 saveMaxFile (MCPFixtureDir+"analyzer-pending.max") quiet:true;loadMaxFile (MCPFixtureDir+"analyzer-pending.max") quiet:true
 r=(getNodeByName "P07_Controller").baseObject;a=r.layerObjects[1];an=(getNodeByName "F75_Analyzer").baseObject
 F75Check (not an.analysisCurrent()) "Saved pending Analyzer stays stale after reopen"
 r.refreshAll();F75Check (findString a.previewError "Update Surface Analyzer"!=undefined) "Reopen cannot silently consume stale guides"
 an.runAnalysis();r.refreshAll();F75Check (a.previewError=="") "Saved pending Analyzer can recover explicitly"
 resetMaxFile #noPrompt
 mergeMAXFile scene #select #autoRenameDups quiet:true
 an=(getNodeByName "F75_Analyzer").baseObject
 F75Check (an.analysisCurrent() and not CyrusAnalyzerRestoring) "Merged current Analyzer preserves freshness and exits restore mode"
 true
)
