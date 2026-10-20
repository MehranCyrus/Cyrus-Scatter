-- Experiment worker; ONLY an owned profile and a fresh verified working copy.
global CyrusBuildingStudyModifiers=#(),CyrusBuildingStudyLog
global CyrusBuildingReductionPolicy
fn CyrusBuildingReductionPolicy layer = (
    case layer of (
        "Fance-Peoxy":#(10,false)
        "500-Fance":#(10,true)
        "600-objects":#(15,true)
        "Objects Street":#(50,true)
        "030_ Landscape":#(50,true)
        default:#(100,true)
    )
)
(
    if MCPFixtureDir==undefined do throw "Owned host required."
    try(close CyrusBuildingStudyLog)catch()
    gc light:false
    CyrusBuildingStudyLog=createFile (MCPFixtureDir+"geometry-preparation-v6.jsonl") encoding:#utf8 writeBOM:false
    local log=CyrusBuildingStudyLog,beforeSelection=selection as array,prepared=0,seen=#()
    local sceneNodes=(for n in geometry where n.renderable and not n.isHidden collect n)
    try (
        for node in sceneNodes where findItem seen node.handle==0 do (
            local related=#()
            InstanceMgr.GetInstances node &related
            local instances=(for n in related where areNodesInstances node n collect n)
            appendIfUnique instances node
            local percent=0,keepUV=false,placements=#()
            for member in instances do (
                appendIfUnique seen member.handle
                local policy=CyrusBuildingReductionPolicy member.layer.name
                percent=amax percent policy[1];keepUV=keepUV or policy[2]
                append placements member.transform
            )
            local input=snapshotAsMesh node,before=#(0,0)
            if input!=undefined then before=#(input.numfaces,input.numverts) else (
                format "{\"nodeHandle\":%,\"name\":%,\"class\":%,\"skipped\":\"No evaluated mesh; retained unchanged\"}\n" node.handle (CyrusBuildingJsonString node.name) (CyrusBuildingJsonString ((classOf node) as string)) to:log
                flush log
            )
            input=undefined
            if percent<100 and before[1]>=5000 do (
                local op=ProOptimizer(),started=timestamp()
                op.KeepUV=keepUV;op.LockUV=false;op.LockMat=true;op.KeepNormals=keepUV;op.OptimizationMode=1
                node.isFrozen=false;select node;max modify mode
                addModifier node op
                modPanel.setCurrentObject op node:node
                local warm=snapshotAsMesh node;warm=undefined
                op.Calculate=true;op.VertexPercent=percent
                local evaluated=snapshotAsMesh node,after=#(evaluated.numfaces,evaluated.numverts);evaluated=undefined
                if not op.Calculate or after[1]<=0 or after[1]>before[1] do throw ("Invalid reduction: "+node.name+" before="+(before as string)+" after="+(after as string))
                for i=1 to instances.count do (
                    local tm=instances[i].transform,old=placements[i]
                    if tm.row1!=old.row1 or tm.row2!=old.row2 or tm.row3!=old.row3 or tm.row4!=old.row4 do throw "Instance placement changed."
                    if instances[i].modifiers[1]!=op do throw "Instance stack ownership changed."
                )
                if after[1]<before[1] then append CyrusBuildingStudyModifiers #(node,op,before,node.layer.name,instances) else deleteModifier node op
                format "{\"nodeHandle\":%,\"name\":%,\"layer\":%,\"percent\":%,\"beforeFaces\":%,\"afterFaces\":%,\"instances\":%,\"elapsedMs\":%,\"keepUV\":%}\n" node.handle (CyrusBuildingJsonString node.name) (CyrusBuildingJsonString node.layer.name) percent before[1] after[1] instances.count (timestamp()-started) (if keepUV then "true" else "false") to:log
                flush log;prepared+=1
            )
        )
    ) catch (try(close log)catch();throw())
    close log;select beforeSelection
    local receipt=createFile (MCPFixtureDir+"geometry-preparation-v6-complete.txt")
    format "preparedGroups=% uniqueVisitedNodes=%\n" prepared seen.count to:receipt;close receipt
)
