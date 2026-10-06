global CyrusSurfaceAnalyzerDraw
global CyrusSurfaceAnalyzer,CyrusAnalyzerOwners=#()
global CyrusAnalyzerRequest,CyrusAnalyzerRegister,CyrusAnalyzerResetOwners,CyrusAnalyzerPruneOwners,CyrusAnalyzerTimeChanged
global CyrusPerfTraceBegin,CyrusPerfTraceEnd,CyrusPerfTraceInput
global CyrusStreetEdges,CyrusStreetShapeFilter
fn CyrusStreetShapeFilter n = (isValidNode n and superClassOf n==Shape)
-- Boundary classification in each loop's plane; output retains original world edges.
fn CyrusStreetEdges loops street angleLimit distanceLimit samples minimumWidth:0 = (
 local streetSegments=#(),result=#()
 if not isValidNode street do return result
 in coordsys world (
  for curve=1 to numSplines street do (
   local steps=(numSegments street curve)*samples
   if steps>0 do (
    local previous=interpCurve3D street curve 0 pathParam:true
    for k=1 to steps do (
     local current=interpCurve3D street curve (k as float/steps) pathParam:true
     append streetSegments #(previous,current);previous=current
    )
   )
  )
 )
 fn inside2 p polygons = (
  local inside=false
  for poly in polygons do for i=1 to poly.count do (
   local a=poly[i],b=poly[if i==poly.count then 1 else i+1]
   if (a.y>p.y)!=(b.y>p.y) do if p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x do inside=not inside
  )
  inside
 )
 for loop in loops where loop.count>=3 do (
  local origin=loop[1],normal=[0,0,0]
  for i=2 to loop.count-1 do normal+=cross (loop[i]-origin) (loop[i+1]-origin)
  if length normal>0.000001 do (
   normal=normalize normal
   local u=normalize(loop[2]-origin),v=normalize(cross normal u)
   local polygons=#(),extent=0.0
   for other in loops do (
    local coplanar=true,poly=#()
    for p in other do (
     local d=p-origin
     if abs(dot d normal)>.001 do coplanar=false
     append poly [dot d u,dot d v,0];extent=amax extent (length d)
    )
    if coplanar do append polygons poly
   )
   local epsilon=amax .000001 (extent*0.000001)
   for i=1 to loop.count do (
    local aw=loop[i],bw=loop[if i==loop.count then 1 else i+1]
    local a=[dot (aw-origin) u,dot (aw-origin) v,0],b=[dot (bw-origin) u,dot (bw-origin) v,0]
    local edge=b-a,mid=(a+b)*.5
    if length edge>epsilon do (
     local outward=normalize [edge.y,-edge.x,0]
     if inside2 (mid+outward*epsilon) polygons do outward=-outward
     local nearest=undefined,best=1e30
     for seg in streetSegments do (
      local c=[dot (seg[1]-origin) u,dot (seg[1]-origin) v,0],d=[dot (seg[2]-origin) u,dot (seg[2]-origin) v,0]
      local delta=d-c,denom=dot delta delta
      local t=if denom>1e-20 then amin 1.0 (amax 0.0 ((dot (mid-c) delta)/denom)) else 0.0
      local q=c+delta*t,dist=distance mid q
      if dist<best do (best=dist;nearest=q)
     )
     if nearest!=undefined and best>epsilon and (distanceLimit==0 or best<=distanceLimit) do (
      if dot outward (normalize(nearest-mid))>=cos angleLimit do (
       -- First boundary hit along the inward normal: never jump across holes/gaps.
       local depth=1e30,inward=-outward
       if minimumWidth>0 do (
        for poly in polygons do for k=1 to poly.count do (
         local c=poly[k],d=poly[if k==poly.count then 1 else k+1],delta=d-c
         local det=inward.x*delta.y-inward.y*delta.x
         if abs det>epsilon do (
          local offset=c-mid
          local rayT=(offset.x*delta.y-offset.y*delta.x)/det
          local edgeT=(offset.x*inward.y-offset.y*inward.x)/det
          if rayT>epsilon and edgeT>=-0.000001 and edgeT<=1.000001 do depth=amin depth rayT
         )
        )
       )
       if minimumWidth<=0 or (depth<1e30 and depth+epsilon>=minimumWidth) do append result #(aw,bw)
      )
     )
    )
   )
  )
 )
 result
)
try(unRegisterRedrawViewsCallback CyrusSurfaceAnalyzerDraw)catch()
plugin simpleObject CyrusSurfaceAnalyzer
name:"Surface Analyzer"
classID:#(0x45a201c7,0x1829bc63)
category:"Cyrus"
version:13
(
 local liveDirty=true,liveBusy=false,analysisRuns=0
 local liveTimeValidity=undefined,liveTimeQueries=0,liveInputHandles=#()
 fn ensureTimeOwner = (
  for n in refs.dependentNodes this where isValidNode n and n.baseObject==this do CyrusAnalyzerRegister n
 )
 fn markLiveDirty schedule:true = (
  liveDirty=true;liveTimeValidity=undefined
  this.ensureTimeOwner()
  if schedule and CyrusAnalyzerRequest!=undefined do CyrusAnalyzerRequest()
 )
 fn livePending = (liveDirty and this.cyrusEnabled and this.updateMode==2 and not liveBusy)
 fn liveTimeExpired = (
  if not this.cyrusEnabled or this.updateMode!=2 or liveTimeValidity==undefined do return false
  local tick=currentTime as integer
  tick<liveTimeValidity[1] or tick>liveTimeValidity[2]
 )
 fn inputHandles = (
  local result=#()
  for source in #(this.surface,this.streetLine) where isValidNode source do (
   local n=source,visited=#()
   while isValidNode n do (
    local handle=getHandleByAnim n
    if findItem visited handle>0 or visited.count>=4096 do throw "Analyzer input parent chain exceeds the validity limit."
    append visited handle;appendIfUnique result handle;n=n.parent
   )
  )
  result
 )
 fn inputChanged event handles = (
  local dependencies=this.inputHandles()
  if event==#deleted do join dependencies liveInputHandles
  for handle in handles where findItem dependencies handle>0 do return true
  false
 )
 fn captureInputTime = (
  this.ensureTimeOwner()
  if cyrusAnalyzerInputValidity==undefined do throw "This Analyzer script requires matching native binaries with input validity support. Restart Max with the complete script/native pair."
  local nodes=for n in #(this.surface,this.streetLine) where isValidNode n collect n
  liveTimeValidity=cyrusAnalyzerInputValidity #(this) nodes #()
  liveTimeQueries+=1;liveInputHandles=this.inputHandles()
 )
 fn getLiveStats = (#(analysisRuns,liveTimeQueries,liveDirty,liveBusy,liveTimeValidity))
 parameters activation rollout:enableUI (
  cyrusEnabled type:#boolean default:true ui:enableCheck
  on cyrusEnabled set v do (this.markLiveDirty();analysisRuns+=1;redrawViews())
 )
 rollout enableUI "Surface Analyzer" (
  checkbox enableCheck "Enable Surface Analyzer" checked:true
 )
 parameters data rollout:analyzeUI (
  surface type:#node ui:surfacePick
  analysisMode type:#integer default:1 ui:modeList
  minimumWidth type:#worldUnits default:0
  minimumLength type:#worldUnits default:0 ui:lengthSpin
  pointCount type:#integer default:5
  resolution type:#integer default:256 ui:resolutionSpin
  ringFraction type:#float default:0.65 ui:ringSpin
  boundaryVertices type:#point3Tab tabSizeVariable:true
  boundaryCounts type:#intTab tabSizeVariable:true
  pathVertices type:#point3Tab tabSizeVariable:true
  pathCounts type:#intTab tabSizeVariable:true
  samplePoints type:#point3Tab tabSizeVariable:true
  totalArea type:#float default:0
  regionArea type:#float default:0
  pathLength type:#float default:0
  detectedMode type:#integer default:0
  resultText type:#string default:"Pick a surface, then Analyze."
  pointRadius type:#worldUnits default:0 ui:radiusSpin
  elementModes type:#intTab tabSizeVariable:true
  elementPointCounts type:#intTab tabSizeVariable:true
  minimumPoints type:#integer default:0 ui:minimumSpin
  elementRelaxed type:#intTab tabSizeVariable:true
  fitRadius type:#worldUnits default:-1 ui:fitSpin
  relaxIterations type:#integer default:20 ui:relaxSpin
  on fitRadius set value do this.markLiveDirty()
  on relaxIterations set value do this.markLiveDirty()
  on surface set value do this.markLiveDirty()
  on analysisMode set value do this.markLiveDirty()
  on pointCount set value do this.markLiveDirty()
  on minimumWidth set value do this.markLiveDirty()
  on minimumLength set value do this.markLiveDirty()
  on resolution set value do this.markLiveDirty()
  on ringFraction set value do this.markLiveDirty()
  on pointRadius set value do this.markLiveDirty()
  on minimumPoints set value do this.markLiveDirty()

 )
 parameters display rollout:displayUI (
  includeStreetBoundary type:#boolean default:true ui:includeStreetCheck
  on includeStreetBoundary set v do (analysisRuns+=1;redrawViews())
  showBoundary type:#boolean default:true ui:boundaryCheck
  showPaths type:#boolean default:true ui:pathsCheck
  showPoints type:#boolean default:true ui:pointsCheck
 )
 parameters streetSettings rollout:streetUI (
  streetLine type:#node ui:streetPick
  streetAngle type:#float default:75 ui:angleSpin
  streetDistance type:#worldunits default:0 ui:distanceSpin
  streetMinimumWidth type:#worldunits default:0 ui:streetWidthSpin
  on streetMinimumWidth set value do this.markLiveDirty()
  streetSamples type:#integer default:16 ui:samplesSpin
  showStreet type:#boolean default:true ui:streetCheck
  streetVertices type:#point3Tab tabSizeVariable:true
  streetCounts type:#intTab tabSizeVariable:true
  on streetLine set v do this.markLiveDirty()
  on streetAngle set v do this.markLiveDirty()
  on streetDistance set v do this.markLiveDirty()
  on streetSamples set v do this.markLiveDirty()
 )
 parameters updateSettings rollout:updateUI (
  updateMode type:#integer default:1 ui:updateChoice
  on updateMode set value do this.markLiveDirty()
 )
 fn packedLines verts counts = (
  local result=#(),cursorIndex=1
  for count in counts do (
   local line=#()
   for k=1 to count do (append line verts[cursorIndex];cursorIndex+=1)
   append result line
  )
  result
 )
 fn boundaryEdgeMask = (
  local flags=#(),streets=packedLines streetVertices streetCounts
  for loop in (packedLines boundaryVertices boundaryCounts) do for i=1 to loop.count do (
   local a=loop[i],b=loop[if i==loop.count then 1 else i+1],keep=true
   if not includeStreetBoundary do for edge in streets where edge.count==2 do (
    if ((distance a edge[1]<.00001 and distance b edge[2]<.00001) or (distance a edge[2]<.00001 and distance b edge[1]<.00001)) do keep=false
   )
   append flags keep
  )
  flags
 )
 fn boundaryOutput = (
  local loops=packedLines boundaryVertices boundaryCounts
  if includeStreetBoundary then loops else (
   local flags=boundaryEdgeMask(),result=#(),cursorIndex=0
   for loop in loops do for i=1 to loop.count do (
    cursorIndex+=1
    if flags[cursorIndex] do append result #(loop[i],loop[if i==loop.count then 1 else i+1])
   )
   result
  )
 )
 fn inputSignature = (
  local sig=(analysisMode as string)+"|"+(minimumWidth as string)+"|"+(minimumLength as string)+"|"+(pointRadius as string)+"|"+(minimumPoints as string)+"|"+(resolution as string)+"|"+(ringFraction as string)+"|"+(fitRadius as string)+"|"+(relaxIterations as string)
  if isValidNode surface then sig+="|"+((getHandleByAnim surface) as string)+"|"+(surface.transform as string) else sig+="|missing"
  sig+="|"+(streetAngle as string)+"|"+(streetDistance as string)+"|"+(streetSamples as string)+"|"+(streetMinimumWidth as string)
  if isValidNode streetLine then sig+="|"+((getHandleByAnim streetLine) as string)+"|"+(streetLine.transform as string) else sig+="|no-street"
  sig
 )
 fn cspImpl_runAnalysis = (
  if not cyrusEnabled do return false
  if not isValidNode surface do throw "Pick a surface first."
  if pointRadius<=0 do pointRadius=units.decodeValue "1m";if fitRadius<0 do fitRadius=minimumWidth*.5
  local started=timeStamp()
  local result=cyrusAnalyzeSurface surface (analysisMode-1) 0 minimumLength pointCount resolution ringFraction pointRadius minimumPoints fitRadius relaxIterations
  local bv=#(),bc=#(),pv=#(),pc=#()
  for line in result[1] do (append bc line.count;join bv line)
  for line in result[2] do (append pc line.count;join pv line)
  boundaryVertices=bv;boundaryCounts=bc;pathVertices=pv;pathCounts=pc
  streetVertices=#();streetCounts=#()
  if isValidNode streetLine do (
   local edges=CyrusStreetEdges result[1] streetLine streetAngle streetDistance streetSamples minimumWidth:streetMinimumWidth
   local sv=#(),sc=#()
   for edge in edges do (append sc edge.count;join sv edge)
   streetVertices=sv;streetCounts=sc
  )
  samplePoints=result[3];totalArea=result[4];regionArea=result[5];pathLength=result[6];detectedMode=result[7]
  elementModes=result[8];elementPointCounts=result[9];elementRelaxed=result[10]
  analysisRuns+=1
  resultText=(elementModes.count as string)+" elements | "+(samplePoints.count as string)+" points\n"+((timeStamp()-started) as string)+" ms"
  if samplePoints.count==0 do resultText="No region meets the current limits."
  if minimumPoints>0 and (for value in elementPointCounts where value<minimumPoints collect value).count>0 do resultText+="\nFit limit: minimum unmet."
  this.captureInputTime();liveDirty=false
  redrawViews()
  result
 )
 fn performanceTraceVersion = 1
 fn runAnalysis = (
  local token=undefined
  if CyrusPerfTraceBegin!=undefined do try(token=CyrusPerfTraceBegin this "analyzer_run")catch()
  try (
   local answer=cspImpl_runAnalysis()
   if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token #("",analysisRuns,samplePoints.count))catch()
   answer
  )catch(
   if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ("EXCEPTION: "+getCurrentException()))catch()
   throw()
  )
 )
 fn exportCurves which = (
  local lines=if which==1 then boundaryOutput() else if which==3 then packedLines streetVertices streetCounts else packedLines pathVertices pathCounts
  if lines.count==0 do throw "Analyze a surface first."
  local out=splineShape name:(uniqueName (if which==1 then "Cyrus_Boundary" else if which==3 then "Cyrus_StreetSide" else "Cyrus_CenterPath"))
  out.wirecolor=if which==1 then (color 235 95 65) else if which==3 then (color 255 40 40) else (color 150 220 70)
  out.renderable=false
  for line in lines do (
   addNewSpline out;local idx=numSplines out
   local closed=(which==1 and includeStreetBoundary) or (distance line[1] line[line.count]<0.0001)
   local last=if closed and which!=1 then line.count-1 else line.count
   for k=1 to last do addKnot out idx #corner #line line[k]
   if closed do close out idx
  )
  updateShape out;out
 )
 fn getAnalysisRuns = analysisRuns
 fn liveTick = (
  if (try((dotNetClass "System.Windows.Forms.Control").MouseButtons != (dotNetClass "System.Windows.Forms.MouseButtons").None)catch(false)) do return false
  if this.liveTimeExpired() do this.markLiveDirty schedule:false
  if this.livePending() then (
    liveBusy=true;liveDirty=false
    try(with undo off runAnalysis())catch(
     liveDirty=false;liveTimeValidity=undefined
     resultText="Update failed:\n"+(getCurrentException())
    )
    liveBusy=false
    try(this.analyzeUI.refreshStats this)catch()
    true
  ) else (
    false
  )
 )
 rollout updateUI "Update" width:170 (
  radioButtons updateChoice labels:#("Manual","Real-time") columns:2 default:1 align:#center
  label updateHelp "Real-time: input changes\nupdate automatically.\nManual: click Analyze." width:144 height:48 align:#center
  on updateChoice changed value do if value==2 do markLiveDirty()
 )
 rollout analyzeUI "Surface Analysis" width:170 (
  pickButton surfacePick "Pick Surface" width:144 height:26 align:#center autoDisplay:true
  dropdownList modeList "Path method" items:#("Auto","Straight region","Ring","Branched centerline") width:144 align:#center
  spinner fitSpin "Fit radius: " range:[0,1e9,0] type:#worldUnits fieldWidth:62 width:144 align:#center
  spinner lengthSpin "Min length: " range:[0,1e9,0] type:#worldUnits fieldWidth:62 width:144 align:#center
  spinner radiusSpin "Point radius: " range:[0.0001,1e9,100] type:#worldUnits fieldWidth:62 width:144 align:#center
  spinner minimumSpin "Min points: " range:[0,1000,0] type:#integer fieldWidth:62 width:144 align:#center
  spinner resolutionSpin "Resolution: " range:[48,768,256] type:#integer fieldWidth:62 width:144 align:#center
  spinner relaxSpin "Relax steps: " range:[0,200,20] type:#integer fieldWidth:62 width:144 align:#center
  spinner ringSpin "Ring factor: " range:[0.05,0.95,0.65] scale:0.01 fieldWidth:62 width:144 align:#center
  label help "Fit radius: hard boundary\nRelax steps: 0 = off\n* = point spacing reduced" width:144 height:48 align:#center
  button analyzeButton "Analyze / Update" width:144 height:28 align:#center
  label status "" width:144 height:40 align:#center
  label stats "" width:144 height:60 align:#center
  listBox elementList "Element results" items:#() width:144 height:4 align:#center
  fn refreshStats obj = (
   status.text=obj.resultText
   local modes=#("Straight","Ring","Branched")
   elementList.items=for i=1 to obj.elementModes.count collect ((i as string)+": "+modes[obj.elementModes[i]]+" | "+(obj.elementPointCounts[i] as string)+(if i<=obj.elementRelaxed.count and obj.elementRelaxed[i]==1 then " *" else ""))
   local meter=units.decodeValue "1m"
   stats.text="Surface: "+(formattedPrint (obj.totalArea/(meter*meter)) format:".3f")+" m2\nRegion*: "+(formattedPrint (obj.regionArea/(meter*meter)) format:".3f")+" m2\nPath: "+(formattedPrint (obj.pathLength/meter) format:".3f")+" m"
  )
  on analyzeUI open do (if pointRadius<=0 do pointRadius=units.decodeValue "1m";if fitRadius<0 do fitRadius=minimumWidth*.5;refreshStats this)
  on analyzeButton pressed do (
   try(undo "Analyze surface" on runAnalysis();refreshStats this)catch(status.text=getCurrentException())
  )
 )
 rollout streetUI "Street Side" width:170 (
  pickButton streetPick "Pick Street Line" filter:CyrusStreetShapeFilter autoDisplay:true width:144 height:26 align:#center
  button clearStreet "Clear Street Line" width:144 align:#center
  spinner angleSpin "Angle limit: " range:[0,89.9,75] fieldWidth:56 width:144 align:#center
  spinner distanceSpin "Max distance: " type:#worldunits range:[0,1e9,0] fieldWidth:56 width:144 align:#center
  spinner streetWidthSpin "Min width: " type:#worldunits range:[0,1e9,0] fieldWidth:56 width:144 align:#center
  spinner samplesSpin "Curve samples: " type:#integer range:[1,64,16] fieldWidth:56 width:144 align:#center
  label streetHelp "Angle: 0 = directly facing\nDistance: 0 = unlimited\nWidth: inward at midpoint\nMin width: 0 = disabled" width:144 height:64 align:#center
  checkbox streetCheck "Show Street Side" align:#left offset:[8,0]
  button updateStreet "Analyze / Update" width:144 align:#center
  button exportStreet "Create Street Side Spline" width:144 height:26 align:#center
  on clearStreet pressed do (streetLine=undefined;if updateMode==2 do liveTick())
  on streetCheck changed val do redrawViews()
  on updateStreet pressed do try(undo "Analyze Street Side" on runAnalysis();analyzeUI.refreshStats this)catch(messageBox(getCurrentException()))
  on exportStreet pressed do try(undo "Export Street Side" on exportCurves 3)catch(messageBox(getCurrentException()))
 )
 rollout displayUI "Viewport and Output" width:170 (
  checkbox includeStreetCheck "Include Street Side" width:144 align:#left offset:[8,0]
  checkbox boundaryCheck "Boundary" align:#left offset:[8,0]
  checkbox pathsCheck "Center paths" align:#left offset:[8,0]
  checkbox pointsCheck "Sample points" align:#left offset:[8,0]
  button exportBoundary "Create Boundary Spline" width:144 height:24 align:#center
  button exportPath "Create Path Spline" width:144 height:24 align:#center
  button exportPoints "Create Point Helpers" width:144 height:24 align:#center
  label note "Schematic v0.4\nPlanar elements only.\nRegion area depends\non the selected mode." width:144 height:64 align:#center
  on boundaryCheck changed val do redrawViews()
  on pathsCheck changed val do redrawViews()
  on pointsCheck changed val do redrawViews()
  on exportBoundary pressed do try(undo "Export boundary" on exportCurves 1)catch(messageBox (getCurrentException()))
  on exportPath pressed do try(undo "Export paths" on exportCurves 2)catch(messageBox (getCurrentException()))
  on exportPoints pressed do undo "Export analyzer points" on (
   local sz=units.decodeValue "5cm"
   for p in samplePoints do (local helper=point name:(uniqueName "Cyrus_Sample") pos:p size:sz cross:true box:false;helper.wirecolor=color 40 190 245)
  )
 )
 on create do (pointRadius=units.decodeValue "1m";fitRadius=units.decodeValue "0.5m")
 on load do (if pointRadius<=0 do pointRadius=units.decodeValue "1m";if fitRadius<0 do fitRadius=minimumWidth*.5)
 on attachedToNode n do (n.renderable=false;n.wirecolor=red;CyrusAnalyzerRegister n)
 parameters iconSettings (
  iconSize type:#worldunits default:10
 )
 fn iconLines = (
        local paths=#()
        local ring=for i=0 to 64 collect [cos(i*360.0/64),sin(i*360.0/64),0]
        append paths ring
        -- S outline, composed of two connected semicircular arcs.
        local letterS=#()
        for i=0 to 24 do (local a=i*270.0/24;append letterS [-0.35+0.23*cos(a),0.23+0.23*sin(a),0])
        for i=0 to 24 do (local a=90-i*270.0/24;append letterS [-0.35+0.23*cos(a),-0.23+0.23*sin(a),0])
        append paths letterS
        append paths #([0.08,-0.46,0],[0.35,0.46,0],[0.62,-0.46,0])
        append paths #([0.20,-0.08,0],[0.50,-0.08,0])

        for path in paths collect (for p in path collect p*iconSize)
 )
 on buildMesh do (
        -- Zero-area edges supply picking bounds; visible icon is drawn as lines.
        local verts=#(),faces=#()
        for path in iconLines() do for i=1 to path.count-1 do (
            local k=verts.count;join verts #(path[i],path[i+1]);append faces [k+1,k+2,k+2]
        )
        setMesh mesh vertices:verts faces:faces
 )
  tool create (
  on mousePoint click do (if click==1 do nodeTM.translation=gridPoint;if click==2 do #stop)
  on mouseMove click do if click==2 do iconSize=amax 0.1 (distance nodeTM.translation gridPoint)
 )
)
fn CyrusSurfaceAnalyzerDraw = (
 gw.setTransform (matrix3 1)
 for n in objects where classOf n==CyrusSurfaceAnalyzer and not n.isHidden do (
  local o=n.baseObject
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in o.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  if o.cyrusEnabled and o.showBoundary do (
   gw.setColor #line (color 235 95 65)
   for line in o.boundaryOutput() where line.count>1 do gw.polyline line o.includeStreetBoundary
  )
  if o.cyrusEnabled and o.showPaths do (
   gw.setColor #line (color 150 220 70)
   for line in (o.packedLines o.pathVertices o.pathCounts) where line.count>1 do gw.polyline line false
  )
  if o.cyrusEnabled and o.showStreet do (
   gw.setColor #line (color 255 40 40)
   for line in (o.packedLines o.streetVertices o.streetCounts) where line.count>1 do gw.polyline line false
  )
  if o.cyrusEnabled and o.showPoints do (for p in o.samplePoints do gw.marker p #hollowBox color:(color 40 190 245))
 )
 gw.enlargeUpdateRect #whole;gw.updateScreen()
)
registerRedrawViewsCallback CyrusSurfaceAnalyzerDraw




-- Changes only invalidate real inputs. The one-shot timer stops when settled;
-- registered owners handle relevant timeline changes without scene polling.
global CyrusAnalyzerEvents,CyrusAnalyzerChanged,CyrusAnalyzerTimer,CyrusAnalyzerPulse,CyrusAnalyzerRendering=false
try(CyrusAnalyzerEvents.enabled=false)catch()
try(CyrusAnalyzerTimer.Stop();CyrusAnalyzerTimer.Dispose())catch()
try(unRegisterTimeCallback CyrusAnalyzerTimeChanged)catch()
fn CyrusAnalyzerRegister n = (
 if isValidNode n and classof n.baseObject==CyrusSurfaceAnalyzer do appendIfUnique CyrusAnalyzerOwners n
)
fn CyrusAnalyzerPruneOwners = (
 CyrusAnalyzerOwners=for n in CyrusAnalyzerOwners where isValidNode n and classof n.baseObject==CyrusSurfaceAnalyzer collect n
)
fn CyrusAnalyzerRequest = (
 local pending=false
 for n in CyrusAnalyzerOwners where isValidNode n and n.baseObject.livePending() do pending=true
 if CyrusAnalyzerTimer!=undefined do (
  if pending and not CyrusAnalyzerRendering then CyrusAnalyzerTimer.Start() else CyrusAnalyzerTimer.Stop()
 )
 pending
)
fn CyrusAnalyzerResetOwners invalidate:true = (
 CyrusAnalyzerOwners=for n in objects where classof n.baseObject==CyrusSurfaceAnalyzer collect n
 if invalidate do for n in CyrusAnalyzerOwners do n.baseObject.markLiveDirty schedule:false
 CyrusAnalyzerRequest()
)
fn CyrusAnalyzerTimeChanged = (
 if CyrusAnalyzerRendering do return false
 local changed=false
 for n in CyrusAnalyzerOwners where isValidNode n and n.baseObject.liveTimeExpired() do (
  n.baseObject.markLiveDirty schedule:false;changed=true
 )
 if changed do CyrusAnalyzerRequest()
 changed
)
fn CyrusAnalyzerChanged event handles = (
 if CyrusPerfTraceInput!=undefined do try(CyrusPerfTraceInput "analyzer_input_received" event handles)catch()
 global CyrusPFDeletedHandles
 if event==#deleted and CyrusPFDeletedHandles!=undefined do (handles=for h in handles where findItem CyrusPFDeletedHandles h==0 collect h;if handles.count==0 do return false)
 if event==#added do for h in handles do CyrusAnalyzerRegister (getAnimByHandle h)
 for n in CyrusAnalyzerOwners where isValidNode n do (
  local obj=n.baseObject
  if obj.inputChanged event handles do obj.markLiveDirty schedule:false
 )
 if event==#deleted do CyrusAnalyzerPruneOwners()
 CyrusAnalyzerRequest()
)
fn CyrusAnalyzerPulse sender args = (
 CyrusAnalyzerTimer.Stop()
 if not CyrusAnalyzerRendering do for n in CyrusAnalyzerOwners where isValidNode n do n.baseObject.liveTick()
 -- A drag may defer pending work. Settled, Manual and failed inputs do not
 -- restart the timer; a later real input notification can request another try.
 CyrusAnalyzerRequest()
)
CyrusAnalyzerEvents=NodeEventCallback mouseUp:true delay:150 added:CyrusAnalyzerChanged deleted:CyrusAnalyzerChanged geometryChanged:CyrusAnalyzerChanged topologyChanged:CyrusAnalyzerChanged modelStructured:CyrusAnalyzerChanged controllerOtherEvent:CyrusAnalyzerChanged controllerStructured:CyrusAnalyzerChanged linkChanged:CyrusAnalyzerChanged
CyrusAnalyzerTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusAnalyzerTimer.Interval=250
dotNet.addEventHandler CyrusAnalyzerTimer "Tick" CyrusAnalyzerPulse
registerTimeCallback CyrusAnalyzerTimeChanged


callbacks.removeScripts id:#CyrusAnalyzerRealtime
callbacks.addScript #preRender "CyrusAnalyzerRendering=true;CyrusAnalyzerTimer.Stop()" id:#CyrusAnalyzerRealtime
callbacks.addScript #postRender "CyrusAnalyzerRendering=false;CyrusAnalyzerRequest()" id:#CyrusAnalyzerRealtime
callbacks.addScript #filePostOpen "CyrusAnalyzerResetOwners()" id:#CyrusAnalyzerRealtime persistent:false
callbacks.addScript #filePostMerge "CyrusAnalyzerResetOwners()" id:#CyrusAnalyzerRealtime persistent:false
callbacks.addScript #systemPostReset "CyrusAnalyzerResetOwners()" id:#CyrusAnalyzerRealtime persistent:false
callbacks.addScript #sceneUndo "CyrusAnalyzerResetOwners invalidate:false" id:#CyrusAnalyzerRealtime persistent:false
callbacks.addScript #sceneRedo "CyrusAnalyzerResetOwners invalidate:false" id:#CyrusAnalyzerRealtime persistent:false
callbacks.addScript #nodeCreated "CyrusAnalyzerRegister (callbacks.notificationParam())" id:#CyrusAnalyzerRealtime persistent:false
CyrusAnalyzerResetOwners()


fn CyrusAnalyzerRedIcons = (for n in objects where classof n==CyrusSurfaceAnalyzer do n.wirecolor=red)
callbacks.removeScripts id:#CyrusAnalyzerIconColor
callbacks.addScript #filePostOpen "CyrusAnalyzerRedIcons()" id:#CyrusAnalyzerIconColor
CyrusAnalyzerRedIcons()




