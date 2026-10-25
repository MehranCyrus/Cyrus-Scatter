loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-dense-probe-20261024-05/" "CyrusDenseVegetationProbe.dlx"
(
    fn require condition message = (if not condition do throw message)
    fn write name value = ((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+name) value)
    fn memory name =
    (
        local p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        (dotNetClass "System.IO.File").AppendAllText (CVLTestDir+"memory.tsv") (name+"\t"+(p.WorkingSet64 as string)+"\t"+(p.PrivateMemorySize64 as string)+"\n")
    )
    local scene=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/Shrubs/A084 - Lavender - 05/model.max"
    cvlStage "load dense source"
    loadMaxFile scene quiet:true useFileUnits:true
    local source=getNodeByName "CyrusModel_A084"
    require (isValidNode source) "Selected lavender source missing."
    memory "loaded"
    local counts=getPolygonCount source
    write "source-counts.txt" (counts as string)
    local b=nodeGetBoundingBox source (matrix3 1), origin=[(b[1].x+b[2].x)*.5,(b[1].y+b[2].y)*.5,b[1].z], height=b[2].z-b[1].z
    cvlStage "load private native probe"
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local modules=process.Modules
    local log=createFile (CVLTestDir+"probe-loaded.tsv")
    for i=0 to modules.Count-1 do (local item=modules.Item[i];if matchPattern item.ModuleName pattern:"CyrusDenseVegetation*" do format "%\t%\n" item.ModuleName item.FileName to:log)
    close log
    cvlStage "prepare 577792 vertices"
    global DVPHandle=dvpPrepare source
    write "prepared.json" (dvpStats DVPHandle)
    memory "prepared"
    cvlStage "strict cold control"
    write "cold-control.json" (dvpColdControl DVPHandle)
    memory "cold_control"
    global DVPOutput=mesh mesh:(dvpMesh DVPHandle) name:"DVP_Dense_Lavender_Output" pos:origin
    DVPOutput.material=source.material
    local initial=snapshotAsMesh DVPOutput
    require (initial.numverts==577792 and initial.numfaces==832240) "Dense mesh was reduced or changed."
    local sourceMesh=snapshotAsMesh source
    require ((meshop.getNumMapVerts initial 1)==(meshop.getNumMapVerts sourceMesh 1)) "UV topology changed."
    sourceMesh=undefined;initial=undefined
    hide source
    global DVPSphere=sphere name:"DVP_Moving_Sphere" radius:(height*.14) segments:48 pos:(origin+[height*.9,0,height*.65])
    DVPSphere.material=standardMaterial name:"Probe stone" diffuse:(color 158 151 137)
    -- Geometry preview uses a deliberately plain material: no Corona/opacity qualification implied.
    DVPOutput.material=standardMaterial name:"Probe geometry preview" diffuse:(color 83 120 62) twoSided:true
    local floor=plane name:"DVP_Ground" length:(height*3) width:(height*3) lengthSegs:1 widthSegs:1 pos:(origin-[0,0,height*.003])
    floor.material=standardMaterial diffuse:(color 101 91 76)
    local cam=targetCamera name:"DVP_Camera" pos:(origin+[-height*1.8,-height*2.3,height*1.45]) target:(targetObject pos:(origin+[height*.12,0,height*.5])) fov:42
    renderers.current=Default_Scanline_Renderer()
    ambientLight=color 45 45 45
    omniLight name:"DVP_Key" pos:(origin+[-height*2,-height*2,height*3]) multiplier:.8
    omniLight name:"DVP_Fill" pos:(origin+[height*2,-height,height]) multiplier:.5
    select #(DVPOutput,DVPSphere);max zoomext sel all
    viewport.setCamera cam
    cvlStage "rest render"
    render camera:cam outputfile:(CVLTestDir+"Rest.png") vfb:false outputwidth:1100 outputheight:850
    local clearance=units.decodeValue "1mm"
    local bench=createFile (CVLTestDir+"sweep.tsv")
    format "step\trequested_fraction\taccepted\twall_ms\n" to:bench
    local clock=dotNetClass "System.Diagnostics.Stopwatch"
    cvlStage "direct full-resolution sphere sweep"
    local acceptedPositions=#()
    for i=0 to 16 do
    (
        local x=.9-.035*i
        DVPSphere.pos=origin+[height*x,0,height*.65]
        local started=clock.GetTimestamp()
        local ok=dvpUpdate DVPHandle DVPSphere DVPOutput clearance
        local elapsed=1000.*((clock.GetTimestamp()-started) as double)/(clock.Frequency as double)
        format "%\t%\t%\t%\n" i x ok elapsed to:bench;flush bench
        if ok do append acceptedPositions (copy DVPSphere.pos)
        write "sweep-progress.json" (dvpStats DVPHandle)
    )
    close bench
    require (acceptedPositions.count>0) "No dense candidate passed the visible contact/root controls."
    write "direct-sweep.json" (dvpStats DVPHandle)
    memory "after_sweep"
    cvlStage "dense candidate audit"
    DVPSphere.pos=acceptedPositions[acceptedPositions.count]
    dvpUpdate DVPHandle DVPSphere DVPOutput clearance
    write "candidate-audit.json" (dvpAudit DVPHandle DVPSphere)
    cvlStage "deformed render"
    render camera:cam outputfile:(CVLTestDir+"Bent.png") vfb:false outputwidth:1100 outputheight:850
    saveMaxFile (CVLTestDir+"Dense_Lavender_Bent_Max2027.max") quiet:true
    cvlStage "automatic live timer"
    dvpWatch DVPHandle DVPSphere DVPOutput clearance
    -- Move the real scene sphere, pump the Max event loop, and let the native timer react.
    -- No Fit/Update call occurs inside this movement loop.
    local liveLog=createFile (CVLTestDir+"live-movement.tsv")
    format "step\trequested_x_fraction\tobserved_stats\n" to:liveLog
    for i=0 to 11 do
    (
        local x=.75-.025*i
        dvpMark DVPHandle
        DVPSphere.pos=origin+[height*x,0,height*.65]
        local deadline=timeStamp()+200
        while timeStamp()<deadline do (windows.processPostedMessages();sleep .005)
        format "%\t%\t%\n" i x (dvpStats DVPHandle) to:liveLog;flush liveLog
    )
    close liveLog
    write "live.json" (dvpStats DVPHandle)
    cvlStage "unrelated and idle"
    local unrelated=box width:1 length:1 height:1 pos:(origin+[height*3,0,0])
    for i=1 to 8 do (unrelated.pos.x+=1;windows.processPostedMessages();sleep .03)
    write "unrelated.json" (dvpStats DVPHandle)
    dvpMark DVPHandle;DVPSphere.pos=origin+[height*2,0,height*.65]
    local deadline=timeStamp()+300
    while timeStamp()<deadline do (windows.processPostedMessages();sleep .005)
    write "away.json" (dvpStats DVPHandle)
    dvpStop DVPHandle
    cvlStage "failure retention"
    DVPSphere.pos=origin+[0,0,height*.1]
    dvpUpdate DVPHandle DVPSphere DVPOutput clearance
    write "blocked-root.json" (dvpStats DVPHandle)
    DVPSphere.scale=[1,2,1]
    dvpUpdate DVPHandle DVPSphere DVPOutput clearance
    write "unsupported.json" (dvpStats DVPHandle)
    DVPSphere.scale=[1,1,1]
    DVPSphere.pos=origin+[height*2,0,height*.65]
    dvpUpdate DVPHandle DVPSphere DVPOutput clearance
    write "final.json" (dvpStats DVPHandle)
    memory "finished"
    local finalCounts=getPolygonCount source
    require (finalCounts[1]==counts[1] and finalCounts[2]==counts[2]) "Original source topology changed."
    saveMaxFile (CVLTestDir+"Dense_Lavender_Restored_Max2027.max") quiet:true
    cvlStage "done"
)
