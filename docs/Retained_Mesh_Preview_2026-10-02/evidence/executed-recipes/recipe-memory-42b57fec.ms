-- Run in the copied artist scene after the 2M Mesh case. Hidden helpers test
-- reservation limits without allocating a gigabyte of actual GPU resources.
(
    local controllers=for n in objects where classof n.baseObject==AminScatterObject collect n
    local controller=controllers[1],cache=undefined,best=0,largest=0
    local baseline=(MIStats controller)[5],owners=#(),results=#(),accepted=0,rejected=0
    local probe=cyrusRetainedCreate();hide probe;append owners probe
    for entry in controller.layerEntries() do (
        local candidate=entry[2].previewCache(),faces=cyrusPreviewFaces candidate
        RIAssert (cyrusRetainedPublish probe controller #(candidate) #(#(false,white))) "Single layer reservation failed"
        local payload=(cyrusRetainedMeshStats probe)[4] as integer
        if payload>largest do (cache=candidate;best=faces;largest=payload)
        cyrusRetainedPublish probe controller #() #()
    )
    RIAssert (cache!=undefined and best>0) "Need a real Mesh cache"
    RIAssert (cyrusRetainedPublish probe controller #(cache) #(#(false,white))) "Single cache failed"
    local bytes=(cyrusRetainedMeshStats probe)[4] as integer
    cyrusRetainedPublish probe controller #() #()
    local copies=amin 10 (amax 1 (floor(450.0*1024*1024/bytes) as integer))
    local caches=for i=1 to copies collect cache,styles=for i=1 to copies collect #(false,white)
    for attempt=1 to 6 do (
        local owner=cyrusRetainedCreate();hide owner;append owners owner
        local ok=cyrusRetainedPublish owner controller caches styles
        if ok then accepted+=1 else rejected+=1
        local stats=for v in (cyrusRetainedMeshStats owner) collect (v as integer)
        append results #(ok,stats)
        RIAssert (stats[5]<=stats[7]) "Process Mesh payload exceeds cap"
        if not ok do RIAssert ((cyrusRetainedStats owner)[12]==2) "Rejected allocation not observable"
    )
    RIAssert (accepted>0 and rejected>0) "Did not exercise allocation fallback"
    RIAssert (cyrusPreviewFaces cache==best) "Reservation failure altered geometry cache"
    for owner in owners do cyrusRetainedPublish owner controller #() #()
    CyrusPointDelete owners;completeRedraw();gc light:true;MISettle()
    RIAssert ((MIStats controller)[5]==baseline) "Mesh reservation leak after cleanup"
    CSPWriteText (RIDir+"mesh-memory.json") (CSPObject #(#("accepted",accepted),#("rejected",rejected),#("single_cache_bytes",bytes),#("copies_per_attempt",copies),#("baseline_process_bytes",baseline),#("after_process_bytes",(MIStats controller)[5]),#("attempts",results),#("fallback_cache_faces",best)))
)
