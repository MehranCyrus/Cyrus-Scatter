    -- Private transient publication metadata. All values are captured before
    -- commit. These read methods never call validSources/procInputKey/solve.
    fn procStagePublication accepted requests publishedSources finalKeep = (
        local sets=#(),count=0,parents=this.logicalLayers()
        for i=1 to layerObjects.count do (
            local leaf=layerObjects[i],parent=this.logicalParent leaf,assets=#()
            for s=1 to publishedSources[i].count do (
                local node=publishedSources[i][s],slot=leaf.sourceRow node
                local sourceID=if slot>0 and slot<=leaf.procSourceSlots.count then leaf.procSourceSlots[slot] else ("placeholder:"+(s as string))
                append assets #(sourceID,(if classof node==Integer then 0 else getHandleByAnim node),finalKeep[i][s],(leaf.isPointSource slot),(leaf.isEmptySource slot))
            )
            if assets.count==0 do append assets #("unassigned:1",0,false,true,false)
            count+=accepted[i].count
            append sets #(leaf.layerID,parent.layerID,(findItem parents parent),(findItem (this.layerSets parent) leaf),accepted[i].count,requests[i][1],requests[i][2],requests[i][3],leaf.procSamplingSalt,assets)
        )
        -- Rule values are retained in system units; the snapshot contains the
        -- unit conversion that was effective for this publication.
        local pairs=for i=1 to procRuleA.count collect #(procRuleScope[i],procRuleA[i],procRuleB[i],procRuleEnabled[i],procRuleMultiplier[i],procRuleGap[i],procRulePlanar[i])
        #(CyrusNewLayerID(),procEpoch+1,(currentTime as integer),1.0/(units.decodeValue "1m"),count,sets,pairs,CyrusLoadedScriptFingerprint)
    )
    fn procPublicationInfo = (
        if groupPolicy!=3 or procPublishedInfo.count==0 do throw "No cached procedural publication. Use Update locally first."
        if groupSnapshotKey.count>2097152 do throw "Publication input signature exceeds the inspection budget."
        local result=deepCopy procPublishedInfo
        append result groupSnapshotKey
        result
    )
    fn procPublicationPage publicationID offset limit = (
        if groupPolicy!=3 or procPublishedInfo.count==0 or procPublishedInfo[1]!=publicationID do throw "Procedural publication changed. Read its manifest again."
        if offset<0 or offset>procPublishedInfo[5] or limit<1 or limit>500 do throw "Publication page bounds are invalid."
        local result=#(),base=0
        for i=1 to groupSnapshotRows.count do (
            local rows=groupSnapshotRows[i],first=amax 1 (offset-base+1),last=amin rows.count (offset+limit-base)
            if first<=last do for j=first to last do (
                local row=rows[j],id=if classof row[3]==String then row[3] else ("c:"+(row[3] as string))
                local keep=row[2]<=procPublishedFinalKeep[i].count and procPublishedFinalKeep[i][row[2]]
                append result #(i,(copy row[1]),row[2],id,(row.count==4 and row[4]==true),procPublishedRadii[i][j],keep)
            )
            base+=rows.count
        )
        #(procPublishedInfo[1],procPublishedInfo[5],offset+result.count,result)
    )
