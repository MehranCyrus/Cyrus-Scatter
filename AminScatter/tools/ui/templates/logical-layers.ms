    -- Logical layers own policy; population objects are stable, independent sets.
    parameters layerOwnership (
        logicalParentID type:#string default:""
        paintSetName type:#string default:"Base"
        paintSetWeight type:#float default:1.0
        paintSetEnabled type:#boolean default:true
        paintSetVisible type:#boolean default:true
        uiPaintSetID type:#string default:""
        on logicalParentID set value do dirty=true
        on paintSetWeight set value do dirty=true
        on paintSetEnabled set value do dirty=true
    )
    fn logicalParent leaf = (
        if leaf.logicalParentID=="" do return leaf
        for candidate in layerObjects where candidate.layerID==leaf.logicalParentID and candidate.logicalParentID=="" do return candidate
        throw "Cyrus paint set has no owning layer. Restore its parent before evaluating."
    )
    fn logicalLayers = (for leaf in layerObjects where leaf.logicalParentID=="" collect leaf)
    fn layerSets parent = (for leaf in layerObjects where leaf==parent or leaf.logicalParentID==parent.layerID collect leaf)
    fn enabledLayer i = (
        if i<1 or i>layerObjects.count or not layerEnabled[i] do return false
        local leaf=layerObjects[i],parent=this.logicalParent leaf,p=findItem layerObjects parent
        p>0 and layerEnabled[p] and leaf.paintSetEnabled
    )
    fn visibleLayer i = (
        if i<1 or i>layerObjects.count do return false
        local leaf=layerObjects[i],parent=this.logicalParent leaf,p=findItem layerObjects parent
        p>0 and (p>layerVisible.count or layerVisible[p]) and (i>layerVisible.count or layerVisible[i]) and leaf.paintSetVisible
    )
    fn selectedPaintSet parent = (
        local members=this.layerSets parent
        for leaf in members where leaf.layerID==parent.uiPaintSetID do return leaf
        parent
    )
    fn layerCaption parent = (local i=findItem layerObjects parent;if i>0 then layerNames[i] else "Removed layer")
    fn setCaption leaf = ((this.layerCaption (this.logicalParent leaf))+" / "+leaf.paintSetName)
    fn populationAllocation leaf countOverride:undefined = (
        local parent=this.logicalParent leaf,members=this.layerSets parent,total=0.0,shares=#(),fractions=#()
        local budget=if countOverride==undefined then parent.amount else countOverride,remaining=budget
        for member in members do total+=if this.enabledLayer (findItem layerObjects member) then amax 0.0 member.paintSetWeight else 0.0
        if total<=0 do return #(0,0.0)
        for member in members do (
            local weight=if this.enabledLayer (findItem layerObjects member) then amax 0.0 member.paintSetWeight else 0.0
            local exact=budget*weight/total,n=(floor exact) as integer
            append shares n;append fractions (exact-n);remaining-=n
        )
        -- Largest remainder; creation order is stable when weights tie.
        for n=1 to remaining do (
            local best=0
            for i=1 to members.count where fractions[i]>=0 do if best==0 or fractions[i]>fractions[best] do best=i
            if best>0 do (shares[best]+=1;fractions[best]=-1)
        )
        local index=findItem members leaf
        #(shares[index],if this.enabledLayer (findItem layerObjects leaf) then parent.plantsPerM2*(amax 0.0 leaf.paintSetWeight)/total else 0.0)
    )
    fn effectivePopulation = (if overlapOwner==undefined then #(amount,plantsPerM2) else overlapOwner.populationAllocation this)
    fn effectiveSeed = (
        if overlapOwner==undefined or logicalParentID=="" then randomSeed else ((mod ((randomSeed as integer64)+(editLayerKey as integer64)*104729) 2147483647) as integer)
    )
    fn layerPaintActive = (
        if overlapOwner==undefined do return this.brushMaskActive()
        local parent=overlapOwner.logicalParent this
        for leaf in overlapOwner.layerSets parent where overlapOwner.enabledLayer (findItem overlapOwner.layerObjects leaf) and leaf.brushMaskActive() do return true
        false
    )
    fn syncLogicalSettings = (
        local own=#(#sources,#sourceWeights,#sourceColors,#sourceZOffsets,#sourceScales,#sourceForwardAxes,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#sourcePoint,#sourceEmpty,#bakedNodes,#paintDocument,#paintEnabled,#paintIdentity,#paintDensity,#paintView,#paintColor,#logicalParentID,#paintSetName,#paintSetWeight,#paintSetEnabled,#paintSetVisible,#uiPaintSetID)
        undo off for leaf in layerObjects where leaf.logicalParentID!="" do (
            local parent=this.logicalParent leaf
            if parent.diversityMode>=3 do throw "Line Pattern and Analyzer assignment require an independent layer. Multi-set layers currently support Random and Clusters; paint histories are preserved."
            for key in AminScatterLayerFields where findItem own key==0 do (
                local value=getProperty parent key,previous=getProperty leaf key
                local tab=findItem AminScatterLayerTabs key>0,same=false
                if tab then (
                    same=previous.count==value.count
                    if same do for i=1 to value.count where previous[i]!=value[i] do same=false
                ) else same=previous==value
                if not same do setProperty leaf key (if tab then value as array else value)
            )
            for key in #(#strokeSides,#patternPaths,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceNodes,#strokeMin,#strokeMax) do (
                local value=getProperty parent key
                local previous=getProperty leaf key,same=previous.count==value.count
                if same do for i=1 to value.count where previous[i]!=value[i] do same=false
                if not same do setProperty leaf key (value as array)
            )
            if leaf.analyzerNode!=parent.analyzerNode do leaf.analyzerNode=parent.analyzerNode
        )
    )
    fn addPaintSet parent label:"Paint set" = (
        if groupPolicy!=2 do throw "Paint sets require shared spacing. Existing legacy layers remain independent."
        if findItem layerObjects parent==0 or parent.logicalParentID!="" do throw "Choose an owning layer."
        if layerObjects.count>=10 do throw "Cyrus currently supports 10 total populations, including paint sets."
        if parent.diversityMode>=3 do throw "Use an independent layer for Line Pattern/Analyzer assignment, or choose Random/Clusters before adding paint sets."
        local leaf
        undo "Cyrus add paint set" on (
            this.newLayer();leaf=this.selectedLayer()
            leaf.logicalParentID=parent.layerID;leaf.paintSetName=label
            leaf.paintIdentity=true;leaf.paintEnabled=true
            local targets=this.validSurfaces()
            if targets.count==1 do leaf.paintDocument=cyrusBrushCreate targets[1]
            parent.uiPaintSetID=leaf.layerID
            this.syncLogicalSettings()
        )
        this.invalidateGroups();this.bindNativeUI();leaf
    )
    fn removeLogicalLayer parent = (
        local members=this.layerSets parent
        for member in members where (for node in member.bakedNodes where isValidNode node collect node).count>0 do throw "Remove the layer's baked output before deleting it."
        undo "Cyrus remove layer" on (
            for i=layerObjects.count to 1 by -1 where findItem members layerObjects[i]>0 do (activeLayer=i;this.removePopulation())
        )
        this.invalidateGroups();this.bindNativeUI()
    )
    fn removePaintSet leaf = (
        if leaf.logicalParentID=="" do throw "The base set belongs to the layer. Disable it or clear its sources/paint; remove the layer to delete it."
        undo "Cyrus remove paint set" on (activeLayer=findItem layerObjects leaf;this.removePopulation())
        this.invalidateGroups();this.bindNativeUI()
    )
    fn copyLogicalLayer origin = (
        local members=this.layerSets origin,copyParent
        if layerObjects.count+members.count>10 do throw "Copy exceeds the 10-population capacity."
        undo "Cyrus copy layer and paint sets" on (
            for member in members do (
                this.newLayer();local destination=this.selectedLayer()
                AminScatterCopyLayer member destination
                destination.bakedNodes=#()
                if member==origin then (
                    copyParent=destination;destination.logicalParentID="";destination.uiPaintSetID=""
                    layerNames[activeLayer]=(this.layerCaption origin)+" copy"
                    if groupPolicy==2 do this.copyGroupRules origin destination
                ) else destination.logicalParentID=copyParent.layerID
            )
        )
        this.invalidateGroups();this.bindNativeUI();copyParent
    )
    fn cleanLogicalLayer parent accepted = (
        if not parent.finalCleanup do return accepted
        local rows=#(),owners=#(),originals=#(),members=this.layerSets parent
        for i=1 to layerObjects.count where findItem members layerObjects[i]>0 do (
            for row in accepted[i] do (
                append owners i;append originals row
                append rows #(row[1],row[2],owners.count,(row.count==4 and row[4]==true))
            )
            accepted[i]=#()
        )
        if rows.count>0 do (
            local kept=cyrusCleanupGroup rows parent.finalNeighborRadius parent.finalMinNeighbors parent.finalMinIsland parent.overlapPlanar
            for row in kept do append accepted[owners[row[3]]] originals[row[3]]
        )
        accepted
    )
