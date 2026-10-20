-- Private 0.1.0 preparation candidate. Invoke only on a derivative in an owned host.
global CyrusPrepareJsonString,CyrusPrepareJsonNumber,CyrusPrepareGeometry
fn CyrusPrepareJsonString value = (
    local builder=dotNetObject "System.Text.StringBuilder"
    builder.Append "\""
    for i=1 to value.count do (
        local ch=value[i],code=bit.charAsInt value[i]
        case ch of (
            "\"":builder.Append "\\\""
            "\\":builder.Append "\\\\"
            default:if code<32 then builder.Append ("\\u"+(formattedPrint code format:"04x")) else builder.Append ch
        )
    )
    builder.Append "\"";builder.ToString()
)
fn CyrusPrepareJsonNumber value = ((dotNetObject "System.Double" value).ToString "R" (dotNetClass "System.Globalization.CultureInfo").InvariantCulture)

-- Rules are #(layerName, vertexPercent, keepUV). Unmatched/protected members win.
fn CyrusPrepareGeometry outputDirectory minimumFaces rules protectedLayers = (
    if (maxVersion())[1]!=29000 do throw "Scene preparation requires 3ds Max 2027."
    if MCPFixtureDir==undefined or not matchPattern MCPFixtureDir pattern:"*max-camera-2027-*" do throw "An owned Max 2027 preparation host is required."
    if not doesDirectoryExist outputDirectory do throw "Owned staging directory is missing."
    local logPath=outputDirectory+"geometry-audit.jsonl"
    if doesFileExist logPath do throw "Preserve the existing preparation audit; choose fresh staging."
    local log=createFile logPath encoding:#utf8 writeBOM:false
    local nodes=(for n in geometry where n.renderable and not n.isHidden collect n)
    local seen=#(),originalSelection=selection as array,oldPropagation=InstanceMgr.autoMtlPropagation
    local beforeTotal=0,afterTotal=0,groups=0,reduced=0,missing=0,started=timestamp()
    InstanceMgr.autoMtlPropagation=false
    try (
        for node in nodes where findItem seen node.handle==0 do (
            local related=#();InstanceMgr.GetInstances node &related
            local members=(for n in related where areNodesInstances node n collect n)
            appendIfUnique members node
            local percent=0,keepUV=false,visibleCount=0
            for member in members do (
                appendIfUnique seen member.handle
                if member.renderable and not member.isHidden do visibleCount+=1
                local value=100,uv=true
                if findItem protectedLayers member.layer.name==0 do (
                    for rule in rules where rule[1]==member.layer.name do (value=rule[2];uv=rule[3])
                )
                percent=amax percent value;keepUV=keepUV or uv
            )
            local input=snapshotAsMesh node,faces=0,vertices=0,before=0,decision="Retained"
            if input==undefined then (missing+=1;decision="No evaluated mesh; retained unchanged")
            else (faces=input.numfaces;vertices=input.numverts;before=faces)
            input=undefined
            if faces>0 and faces>=minimumFaces and percent<100 do (
                local states=(for n in members collect #(n.transform,n.material,n.handle,n.name,n.layer.name,n.parent,n.isFrozen))
                local op=ProOptimizer()
                op.KeepUV=keepUV;op.LockUV=false;op.LockMat=true;op.KeepNormals=keepUV;op.OptimizationMode=1
                node.isFrozen=false;select node;max modify mode;addModifier node op
                modPanel.setCurrentObject op node:node
                local warm=snapshotAsMesh node;warm=undefined
                op.Calculate=true;op.VertexPercent=percent
                local evaluated=snapshotAsMesh node
                if evaluated==undefined do throw ("No reduced mesh: "+node.name)
                faces=evaluated.numfaces;vertices=evaluated.numverts;evaluated=undefined
                if not op.Calculate or faces<=0 or faces>before do throw ("Invalid reduction: "+node.name)
                if faces==before then (deleteModifier node op;decision="Reduction made no change")
                else (
                    -- Freeze now: a later object's edits can invalidate Calculate caches.
                    convertToMesh node
                    for i=1 to members.count do (
                        local n=members[i],state=states[i]
                        if not areNodesInstances n node do instanceReplace n node
                        local check=snapshotAsMesh n
                        if check==undefined or check.numfaces!=faces or check.numverts!=vertices do throw "Frozen geometry differs from the validated result."
                        check=undefined
                        if n.transform!=state[1] or n.material!=state[2] or n.handle!=state[3] or n.name!=state[4] or n.layer.name!=state[5] or n.parent!=state[6] do throw "Preparation changed instance placement, identity, material, layer or parent."
                    )
                    reduced+=1;decision="Reduced, frozen immediately and re-instanced"
                )
                node.isFrozen=states[findItem members node][7]
            )
            groups+=1;beforeTotal+=before*visibleCount;afterTotal+=faces*visibleCount
            format "{\"handle\":%,\"name\":%,\"layer\":%,\"instances\":%,\"visibleInstances\":%,\"percent\":%,\"keepUV\":%,\"beforeTriangles\":%,\"afterTriangles\":%,\"decision\":%}\n" node.handle (CyrusPrepareJsonString node.name) (CyrusPrepareJsonString node.layer.name) members.count visibleCount percent (if keepUV then "true" else "false") before faces (CyrusPrepareJsonString decision) to:log
            flush log
        )
        close log;InstanceMgr.autoMtlPropagation=oldPropagation;select originalSelection
        local summary=createFile (outputDirectory+"geometry-summary.json") encoding:#utf8 writeBOM:false
        format "{\"version\":\"0.1.0\",\"groups\":%,\"reducedGroups\":%,\"missingEvaluatedOwners\":%,\"visiblePlacements\":%,\"beforeSubmittedTriangles\":%,\"afterSubmittedTriangles\":%,\"elapsedMs\":%}" groups reduced missing nodes.count beforeTotal afterTotal (timestamp()-started) to:summary;close summary
        #(beforeTotal,afterTotal,reduced,missing)
    ) catch (
        try(close log)catch();InstanceMgr.autoMtlPropagation=oldPropagation
        try(select originalSelection)catch();throw()
    )
)
