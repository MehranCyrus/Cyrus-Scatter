-- Private Max 2027 successor checks. This file never creates malformed SDK
-- geometry or calls shipping fault hooks. The runner owns profile isolation.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
(
QSetup()
case QScenarioID of (
 "R7-M01": (
    QSurface.mapCoords=true
    QLayer.densityMap=checker name:"Q white native density" color1:white color2:white
    QLayer.distributionMode=3;QLayer.densityCoordinateMode=0;QLayer.densityResolution=64
    QLayer.relaxSpacing=200;QLayer.finalStrength=0.3;QLayer.finalMaxMove=20;QLayer.finalIterations=2
    QCalculate()
    local image=QLayer.procDensityWeights(),unrelaxed=QFingerprint(),count=QRoot.groupSnapshotRows[1].count
    QAssert (cyrusDensityImageCount image==4096 and count==400) "R7-M01-01" "Actual controller captures the white map into a native 64x64 density image"
    QMount()
    QClick QRoot.spacingUI.spacingUI_boundaryRelaxCheck
    QRequire QLayer.finalRelax "Generated Boundary Relax control did not change its owner"
    QClick QRoot.mainUI.updateNow
    local expected=QFingerprint(),epoch=QRoot.procEpoch
    QAssert (QLayer.previewError=="" and QRoot.groupSnapshotRows[1].count==count and expected!=unrelaxed and QLayer.procProjectionBudget==undefined) "R7-M01-02" "Generated Boundary control and Update publish a complete moved result and release the solve budget"
    -- A changed seed replaces caches; restoring the seed exercises a fresh
    -- deterministic successor instead of merely reading the unchanged cache.
    local seed=QLayer.randomSeed
    QLayer.randomSeed=seed+1;QClick QRoot.mainUI.updateNow
    QLayer.randomSeed=seed;QClick QRoot.mainUI.updateNow
    QAssert (QFingerprint()==expected and QLayer.previewError=="") "R7-M01-03" "Native image plus Boundary Relax reproduces full ordered publication after a changed-seed successor"
    -- Uniform white support makes each image coordinate mode an exact control.
    for coordinates in #(1,2,0) do (
        QLayer.densityCoordinateMode=coordinates;QClick QRoot.mainUI.updateNow
        QRequire (QFingerprint()==expected and QLayer.previewError=="") "World/Local/UV image Boundary control differs"
    )
    QAssert true "R7-M01-04" "World XY, Local XY and UV image paths agree for uniform support"
    epoch=QRoot.procEpoch
    local builds=(QLayer.procStatistics())[3],previewBuilds=QLayer.previewBuildCount
    QLayer.amount=450;QSettle 500;clearSelection();select QNode;QSettle 500
    QAssert (QFingerprint()==expected and QRoot.procEpoch==epoch and (QLayer.procStatistics())[3]==builds and QLayer.previewBuildCount==previewBuilds and QLayer.amount==450) "R7-M01-05" "Pending Manual amount and view callbacks retain the density/Boundary publication without preparation"
    QLayer.amount=400;QClick QRoot.mainUI.updateNow
    QAssert (QFingerprint()==expected and QLayer.previewError=="" and QLayer.procProjectionBudget==undefined) "R7-M01-06" "Restoring valid authored settings recovers the complete deterministic publication"
 )
 "R7-M02": (
    QSurface.widthsegs=80;QSurface.lengthsegs=100
    local upper=copy QSurface;upper.name="Q upper dense receiver";upper.pos.z=4
    QRoot.setLayerSurfaces QLayer #(QSurface,upper)
    QLayer.amount=1000;QLayer.advancedAxes=true;QLayer.projectMove=true
    QLayer.movXMinWU=-20;QLayer.movXMaxWU=20;QLayer.movYMinWU=-20;QLayer.movYMaxWU=20;QLayer.movZMinWU=-8;QLayer.movZMaxWU=8
    QMount();local started=timeStamp();QClick QRoot.mainUI.updateNow
    QRequire (QLayer.previewError=="" and QRoot.groupSnapshotRows[1].count==1000) "Dense projected Update did not complete"
    for row in QRows() do QRequire ((abs row[1].row4.z)<0.001 or (abs (row[1].row4.z-4))<0.001) "Projected row left its stacked receiver surface"
    QAssert (QLayer.procProjectionBudget==undefined) "R7-M02-01" ("Generated Update projects 1,000 rows on two 16,000-face stacked receivers; observed Update milliseconds="+((timeStamp()-started) as string))
    local before=QFingerprint(),epoch=QRoot.procEpoch,builds=(QLayer.procStatistics())[3]
    QLayer.amount=1100;QSettle 500;clearSelection();select QNode;QSettle 400
    QAssert (QFingerprint()==before and QRoot.procEpoch==epoch and (QLayer.procStatistics())[3]==builds and QLayer.amount==1100) "R7-M02-02" "Manual amount remains pending on the dense receiver until explicit Update"
    QClick QRoot.mainUI.updateNow;before=QFingerprint()
    QRequire (QRoot.groupSnapshotRows[1].count==1100) "Explicit Update ignored Manual amount"
    undo "Q projected movement setting" on QLayer.movXMaxWU=35
    QClick QRoot.mainUI.updateNow;local changed=QFingerprint()
    QRequire (changed!=before) "Movement edit did not change projected output"
    max undo;QRequire (QLayer.movXMaxWU==20) "Movement setting Undo did not restore authored input"
    QClick QRoot.mainUI.updateNow;QRequire (QFingerprint()==before) "Movement Undo plus Update changed the preceding deterministic result"
    max redo;QRequire (QLayer.movXMaxWU==35) "Movement setting Redo did not restore authored input"
    QClick QRoot.mainUI.updateNow
    QAssert (QFingerprint()==changed) "R7-M02-03" "Projected movement authored Undo/Redo and explicit Update restore exact ordered results"
    before=QFingerprint();epoch=QRoot.procEpoch
    local stats=QLayer.procLastStats as string,preview=QLayer.cachedPoints,prepared=QLayer.previewBuildCount,error=""
    -- Model a malformed transferred range, bypassing only the UI's ordinary
    -- paired-spinner normalization. The real native calculation must reject it.
    -- No malformed mesh or shipping fault hook is involved.
    QLayer.layerTransfer=true
    try(QLayer.movXMinWU=100)catch(QLayer.layerTransfer=false;throw())
    QLayer.layerTransfer=false
    try(QCalculate())catch(error=getCurrentException())
    local diagnostic=createFile (MCPFixtureDir+"native-invalid-successor.txt")
    format "Error: %\nFingerprint equal: %\nEpoch equal: %\nStatistics equal: %\nPreview identity equal: %\nBuilds: % -> %\nBudget released: %\n" error (QFingerprint()==before) (QRoot.procEpoch==epoch) (QLayer.procLastStats as string==stats) (QLayer.cachedPoints==preview) prepared QLayer.previewBuildCount (QLayer.procProjectionBudget==undefined) to:diagnostic;close diagnostic
    QAssert (error!="" and QFingerprint()==before and QRoot.procEpoch==epoch and QLayer.procLastStats as string==stats and QLayer.cachedPoints==preview and QLayer.previewBuildCount==prepared and QLayer.procProjectionBudget==undefined) "R7-M02-04" "Invalid movement successor retains rows, epoch, statistics and preview; solve budget is released"
    QLayer.movXMinWU=-20;QClick QRoot.mainUI.updateNow
    QRequire (QFingerprint()==before and QLayer.previewError=="") "Repair did not recover the prior complete projected result"
    CyrusPointSuspended=false;QRoot.updateMode=2;QSettle 900
    epoch=QRoot.procEpoch;QSurface.pos.x+=10
    local deadline=timeStamp()+15000
    while QRoot.procEpoch==epoch and timeStamp()<deadline do QSettle 100
    QRequire (QRoot.procEpoch>epoch and QLayer.previewError=="") "Relevant Live receiver transform did not publish through its callbacks"
    local liveEpoch=QRoot.procEpoch,liveKey=QFingerprint();QSettle 700
    QAssert (QRoot.procEpoch==liveEpoch and QFingerprint()==liveKey and QLayer.procProjectionBudget==undefined) "R7-M02-05" "Relevant Live receiver transform settles without forced calculation or repeated publication"
    builds=(QLayer.procStatistics())[3];prepared=QLayer.previewBuildCount
    local unrelated=box name:"Q unrelated Live node" pos:[3000,0,0];unrelated.pos.y+=10;QSettle 700
    QAssert (QRoot.procEpoch==liveEpoch and QFingerprint()==liveKey and (QLayer.procStatistics())[3]==builds and QLayer.previewBuildCount==prepared) "R7-M02-06" "Unrelated Live scene activity reuses the dense projection publication and preview"
    QRoot.updateMode=1;CyrusPointSuspended=true
 )
 "R7-M09": (
    local started=timeStamp()
    -- These are valid indexed triangles. Coincident bounds deliberately make
    -- every exact-distance tie eligible, exercising the worst-case work cap
    -- without malformed geometry, excessive allocations or a fault hook.
    local faces=for i=1 to 16384 collect [1,2,3]
    local first=mesh name:"Q shared projection A" vertices:#([-500,-500,0],[500,-500,0],[-500,500,0]) faces:faces
    local second=copy first;second.name="Q shared projection B";second.pos.z=4
    hide first;hide second;faces=undefined
    fn projectedReceiver receiver slot budget owner mapping = (
        local options=#(false,1.0,1.0,0.0,0.0,0.0,0.0,1,0L,("Q-shared-projection-"+(slot as string)),slot,1,undefined,mapping,budget)
        cyrusScatterCanonicalNative owner #(receiver) 5000 42 1 [1,1,1] [1,1,1] [0,0,0] [0,0,0] [0.1,0,0] [0.1,0,0] false true 0 #() 8 #(1) false 10.0 42 0.0 0.0 0.0 #() #() #(false,#()) #(false,1.0,0,0.5) #(1.0) undefined options
    )
    local budget=cyrusProjectionBudget(),owner=cyrusPlacementOwner(),mapping=QLayer.densityMappingPayload()
    local initial=cyrusProjectionBudgetStats budget
    QRequire (initial.count==8) "Projection budget counter schema changed"
    for counter in initial do QRequire (counter==0) "New projection budget is not empty"
    local firstResult=projectedReceiver first 1 budget owner mapping,firstStats=cyrusProjectionBudgetStats budget
    QAssert (firstResult[1].count==5000 and firstStats[1]==1 and firstStats[2]==5000 and firstStats[5]==81920000L and firstStats[6]>100000000L and firstStats[6]<200000000L and firstStats[6]==firstStats[3]+firstStats[4]+firstStats[5] and firstStats[7]>0 and firstStats[8]==0) "R7-M09-01" ("options[15] borrows the exact opaque budget; one valid receiver succeeds with eight counters="+(firstStats as string))
    local failure=""
    try(projectedReceiver second 2 budget owner mapping)catch(failure=getCurrentException())
    local failedStats=cyrusProjectionBudgetStats budget
    QAssert ((matchPattern failure pattern:"*shared solve work limit*") and failedStats.count==8 and failedStats[1]==2 and failedStats[2]>5000 and failedStats[2]<10000 and failedStats[5]>firstStats[5] and failedStats[6]==200000000L and failedStats[6]==failedStats[3]+failedStats[4]+failedStats[5] and failedStats[8]==0 and firstResult[1].count==5000) "R7-M09-02" ("The second receiver exhausts the same allowance and releases scratch; counters="+(failedStats as string))
    firstResult=undefined;budget=undefined
    local before=QFingerprint(),epoch=QRoot.procEpoch,rows=QRoot.groupSnapshotRows,publication=QRoot.procNativePublication
    local statistics=QLayer.procLastStats as string,preview=QLayer.cachedPoints,previewBuilds=QLayer.previewBuildCount
    local fields=#(#amount,#advancedAxes,#projectMove,#movXMinWU,#movXMaxWU,#movYMinWU,#movYMaxWU,#movZMinWU,#movZMaxWU,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#distributionMode)
    local original=for field in fields collect getProperty QLayer field
    QRoot.setLayerSurfaces QLayer #(first,second)
    QLayer.amount=10000;QLayer.advancedAxes=true;QLayer.projectMove=true
    QLayer.movXMinWU=0.1;QLayer.movXMaxWU=0.1;QLayer.movYMinWU=0;QLayer.movYMaxWU=0;QLayer.movZMinWU=0;QLayer.movZMaxWU=0
    QLayer.procPopulation=1;QLayer.procAttemptFactor=1;QLayer.procRounds=1;QLayer.procRepair=false;QLayer.distributionMode=1
    failure="";local hostStarted=timeStamp()
    try(QCalculate())catch(failure=getCurrentException())
    local hostMs=timeStamp()-hostStarted,plan=QLayer.procReceiverPlanData
    local equalPools=plan[1].count==2
    if equalPools do for receiver in plan[1] do equalPools=equalPools and receiver[2]==5000 and receiver[3]==5000 and receiver[4]==5000
    QAssert ((matchPattern failure pattern:"*shared solve work limit*") and equalPools and plan[3]==10000 and plan[4]==10000 and plan[2].count==10000) "R7-M09-03" ("Actual evaluateProcedural shares one allowance across two equal-area receivers; each 5,000-row receiver fits individually; host milliseconds="+(hostMs as string))
    QAssert (QFingerprint()==before and QRoot.procEpoch==epoch and QRoot.groupSnapshotRows==rows and QRoot.procNativePublication==publication and QLayer.procLastStats as string==statistics and QLayer.cachedPoints==preview and QLayer.previewBuildCount==previewBuilds and QLayer.procProjectionBudget==undefined and not QRoot.groupSolving) "R7-M09-04" "Actual shared-budget failure retains the preceding complete rows, epoch, native publication, statistics and preview, and clears the transient allowance"
    QRoot.setLayerSurfaces QLayer #(QSurface)
    for i=1 to fields.count do setProperty QLayer fields[i] original[i]
    QCalculate()
    QAssert (QFingerprint()==before and QLayer.previewError=="" and QLayer.procProjectionBudget==undefined and not QRoot.groupSolving) "R7-M09-05" "Restoring valid receiver/settings recovers the preceding complete deterministic publication with no retained allowance"
    QAssert (timeStamp()-started<30000) "R7-M09-06" ("Both native and controller shared-budget pairs finish within the 30-second fixture bound; total milliseconds="+((timeStamp()-started) as string))
 )
 default: throw ("Unknown native remediation scenario: "+QScenarioID)
)
)
