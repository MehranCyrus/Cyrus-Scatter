    -- Session-only validity. Scene identities and publication records are unchanged.
    local inputTimeValidity=undefined,inputTimeStamp=0,inputTimeObserved=0
    local inputTimeQueries=0,inputTimeInvalidations=0
    local timeOwnerRegistered=false
    fn ensureTimeOwner = (
        if not timeOwnerRegistered do (
            for node in refs.dependentNodes this where isValidNode node and node.baseObject==this do (
                CyrusRegisterTimeOwner node;timeOwnerRegistered=true
            )
        )
    )
    fn markInputDirty = (inputTimeValidity=undefined;dirty=true)
    fn inputTimeExpired = (
        if inputTimeValidity==undefined do return false
        local tick=currentTime as integer
        tick<inputTimeValidity[1] or tick>inputTimeValidity[2] or inputTimeStamp!=inputTimeObserved
    )
    fn inputTimeKey = (
        local tick=currentTime as integer
        if inputTimeValidity==undefined or tick<inputTimeValidity[1] or tick>inputTimeValidity[2] do (
            if cyrusScatterInputValidity==undefined do throw "This Scatter script requires matching native binaries with input validity support. Restart Max with the complete script/native pair."
            local nodes=this.validSurfaces(),settings=#(this),maps=#()
            join nodes (this.sources as array);join nodes (this.areaNodes as array);join nodes (this.patternLines as array)
            -- Analyzer is a cached producer. checkAnalyzerRevision() observes
            -- its published output; its icon/receiver clock must not bypass
            -- the Analyzer's own Manual mode or real-time scheduling.
            if this.proceduralPolicy() do join nodes (this.effectiveContainers())
            nodes=for n in nodes where isValidNode n collect n
            if this.overlapOwner==undefined do join settings (this.procModifiers())
            this.procWatchDensity()
            if this.densityMap!=undefined and this.distributionMode==3 do append maps this.densityMap
            local interval=cyrusScatterInputValidity settings nodes maps
            inputTimeQueries+=1
            -- Keep one key throughout a validity interval, including stepped keys.
            -- FOREVER has no time component. A dirty notification re-arms the
            -- interval without unnecessarily changing a still-valid time stamp.
            if interval[3] then inputTimeStamp=0
            else if inputTimeStamp<interval[1] or inputTimeStamp>interval[2] do inputTimeStamp=tick
            inputTimeValidity=interval
        )
        inputTimeStamp
    )
    fn invalidateInputTime = (
        if not this.inputTimeExpired() do return false
        inputTimeInvalidations+=1
        CyrusDiagnosticEmit "time.invalidated" "host_callback" this.layerID inputTimeInvalidations "dependency_interval_expired"
        this.markInputDirty();true
    )
    fn liveTimeChanged = (
        if this.updateMode!=2 or not this.cyrusEnabled do return false
        local rootChanged=this.invalidateInputTime(),changed=rootChanged
        for i=1 to this.layerObjects.count where this.enabledLayer i do (
            local leaf=this.layerObjects[i]
            if rootChanged then leaf.markInputDirty()
            else if leaf.invalidateInputTime() do changed=true
        )
        changed
    )
    fn inputTimeStats = (#(inputTimeQueries,inputTimeInvalidations,inputTimeStamp,inputTimeObserved,inputTimeValidity))
    fn publishedInputTime = inputTimeObserved
