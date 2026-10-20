-- The native glTF exporter indexes MultiMaterial slots directly, ignoring sparse IDs.
-- Compact only disposable export clones; the prepared scene retains its original IDs.
global CyrusPrepareExportSelection,CyrusPrepareExportCleanup
fn CyrusPrepareExportCleanup clones propagation = (
    local valid=(for n in clones where isValidNode n collect n)
    if valid.count>0 do delete valid
    InstanceMgr.autoMtlPropagation=propagation
)
fn CyrusPrepareExportSelection nodes directory = (
    local clones=#(),chosen=#(),geometryCache=#(),materialCache=#(),propagation=InstanceMgr.autoMtlPropagation
    local audit=createFile (directory+"export-material-ids.jsonl") encoding:#utf8 writeBOM:false
    InstanceMgr.autoMtlPropagation=false
    try (
        for source in nodes do (
            local material=source.material,compact=false
            if material!=undefined and classOf material==Multimaterial do (
                for i=1 to material.materialIDList.count where material.materialIDList[i]!=i do compact=true
            )
            local evaluated=undefined
            if compact do (
                evaluated=snapshotAsMesh source
                if evaluated==undefined or evaluated.numfaces==0 do compact=false
                evaluated=undefined
            )
            if not compact then append chosen source
            else (
                local temp=copy source,template=undefined,ids=material.materialIDList as array,signature=ids as string
                append clones temp
                temp.name=source.name;temp.parent=source.parent;temp.transform=source.transform
                for record in geometryCache where template==undefined and record[2]==signature and areNodesInstances record[1] source do template=record[3]
                if template==undefined then (
                    temp.isFrozen=false;convertToMesh temp
                    local mesh=temp.mesh
                    for face=1 to mesh.numfaces do (
                        local original=getFaceMatID mesh face,replacementId=findItem ids original
                        if replacementId==0 do throw "A face uses an ID absent from its MultiMaterial; correct the source assignment before export."
                        setFaceMatID mesh face replacementId
                    )
                    temp.mesh=mesh;append geometryCache #(source,signature,temp)
                ) else instanceReplace temp template
                local exportedMaterial=undefined
                for record in materialCache where record[1]==material do exportedMaterial=record[2]
                if exportedMaterial==undefined do (
                    exportedMaterial=MultiMaterial numsubs:material.materialList.count name:("CPExport"+(materialCache.count as string))
                    exportedMaterial.materialList=material.materialList
                    exportedMaterial.materialIDList=(for i=1 to material.materialList.count collect i)
                    exportedMaterial.names=material.names;exportedMaterial.mapEnabled=material.mapEnabled
                    append materialCache #(material,exportedMaterial)
                )
                temp.material=exportedMaterial
                local before=source.objectTransform,after=temp.objectTransform
                for row=1 to 4 where distance before[row] after[row]>0.00001 do throw "Export clone changed its source object transform."
                append chosen temp
                format "{\"sourceHandle\":%,\"sourceName\":%,\"sourceIds\":[" source.handle (CyrusPrepareJsonString source.name) to:audit
                for i=1 to ids.count do (if i>1 do format "," to:audit;format "%" ids[i] to:audit)
                format "],\"exportIds\":[" to:audit
                for i=1 to ids.count do (if i>1 do format "," to:audit;format "%" i to:audit)
                format "],\"preparedSceneIdsRetained\":true}\n" to:audit;flush audit
            )
        )
        close audit
        #(chosen,clones,propagation)
    ) catch (
        try(close audit)catch();CyrusPrepareExportCleanup clones propagation;throw()
    )
)
