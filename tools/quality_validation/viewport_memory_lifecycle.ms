-- Owned Max 2027 lifecycle scenarios for the exact script/native pair.
-- The run supplies the local asset baseline through hpm-input.ms. This file
-- deliberately does not fileIn viewport_memory.ms, whose case body executes.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
fileIn ((getFilenamePath(getSourceFileName()))+"maple_texture_inputs.ms")

global QHighPolyBaseline,QHighPolyFingerprint
global QMemoryLifeFingerprint,QMemoryLifeState,QMemoryLifeDraw,QMemoryLifeLoad,QMemoryLifeLayer,QMemoryLifeFull,QMemoryLifeLog,QMemoryLifePublicationLog
fn QMemoryLifeFingerprint root = cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("refinement") #()
fn QMemoryLifeState node = (
    local owner=CyrusPointOwner node
    QRequire (isValidNode owner) "No retained viewport owner"
    #(owner,cyrusRetainedStats owner,cyrusRetainedViewportStats owner,cyrusViewportMemoryStats(),cyrusRetainedMeshStats owner,cyrusRetainedStreamStats())
)
fn QMemoryLifeDraw node = (
    CyrusPointSuspended=false
    node.baseObject.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 1200
    QMemoryLifeState node
)
fn QMemoryLifeFull state triangles = (
    state[2][12]==1 and state[3][6]==triangles and state[3][7]==triangles and state[3][8]==0 and state[3][9]==0 and state[3][10]==0
)
fn QMemoryLifeLog stream label state = (
    format "%\nMemory: %\nRetained: %\nMesh: %\nPlan: %\nStreams: %\nMetadata: %\n" label state[4] state[2] state[5] state[3] state[6] (cyrusSourceGeometryMemoryStats()) to:stream
    flush stream
)
fn QMemoryLifePublicationLog stream label root = (
    format "%: system units % %, fingerprint %\n" label units.SystemType units.SystemScale (QMemoryLifeFingerprint root) to:stream
    QRequire (root.layerObjects.count<=3) "Lifecycle publication log exceeds its layer bound"
    for i=1 to root.layerObjects.count do (
        local data=root.groupSnapshotRows[i],radii=root.procPublishedRadii[i]
        QRequire (data.count<=16 and radii.count<=16) "Lifecycle publication log exceeds its row bound"
        local rows=if data.count==0 then #() else cyrusPlacementPage data (cyrusPlacementToken data) 0 data.count
        format "Layer % ID: %; rows: %; radii: %\n" i root.layerObjects[i].layerID rows (for r=1 to radii.count collect radii[r]) to:stream
    )
    flush stream
)
fn QMemoryLifeLoad draw:true = (
    QRequire (matchPattern MCPFixtureDir pattern:"*/build/*") "Owned test profile required"
    fileIn (MCPFixtureDir+"hpm-input.ms")
    QRequire (doesFileExist QHighPolyBaseline) "Missing exact high-poly baseline scene"
    cyrusSetViewportMemoryLimit 0
    local loadUnits=#(units.SystemType,units.SystemScale)
    loadMaxFile QHighPolyBaseline quiet:true useFileUnits:true
    CyrusPerfHeadless=true;CyrusPointSuspended=true
    QNode=getNodeByName "Tree Scatter" exact:true
    QRequire (isValidNode QNode) "Baseline controller missing"
    QRoot=QNode.baseObject;QLayer=QRoot.selectedLayer();QRoot.updateMode=1;QRoot.autoRender=false
    QCalculate()
    local baselineLog=openFile (MCPFixtureDir+"high-poly-lifecycle-load.txt") mode:"a"
    format "System units before load: %\n" loadUnits to:baselineLog
    QMemoryLifePublicationLog baselineLog "Loaded measured baseline" QRoot
    format "Expected baseline fingerprint: %\n" QHighPolyFingerprint to:baselineLog;close baselineLog
    QRequire (QFingerprint()==QHighPolyFingerprint) "Exact baseline placement fingerprint differs"
    QRequire (QRoot.layerObjects.count==1 and QLayer.sources.count==2) "Expected the measured two-source baseline"
    QResolveMapleTextureInputs QRoot
    QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000;QRoot.identificationMode=4
    if draw then (QRoot.setGroupDisplay 3;QMemoryLifeDraw QNode) else (QRoot.setGroupDisplay 1;undefined)
)
fn QMemoryLifeLayer root source receivers seed = (
    root.newLayer();local leaf=root.selectedLayer()
    root.setLayerSurfaces leaf receivers;QRequire (leaf.addModelSource source) "Cannot add measured source"
    leaf.amount=1;leaf.randomSeed=seed;leaf.sourceScales[1]=0.02
    leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
    leaf
)

case QScenarioID of (
    "R7-M07": (
        QMemoryLifeLoad draw:false
        local green=QLayer.sources[1],red=QLayer.sources[2],receivers=QLayer.validSurfaces()
        local greenCopy=copy green;greenCopy.name="Q distinct green maple";hide greenCopy
        -- Three explicit populations avoid a random source choice leaving one
        -- asset unused. A097 + A098 + a distinct A097 exceed the former aggregate
        -- two-million limit while each original tree remains below that limit.
        QLayer.amount=1;QLayer.sourceWeights=#(1.0,0.0)
        QLayer.procSelfOverride=true;QLayer.procSelfEnabled=false;QLayer.procLayerSelfEnabled=false
        local redLayer=QMemoryLifeLayer QRoot red receivers 1001
        local copyLayer=QMemoryLifeLayer QRoot greenCopy receivers 1002
        QCalculate()
        local expectedSources=#(green,red,greenCopy),accepted=true
        for i=1 to 3 do (
            local data=QRoot.groupSnapshotRows[i]
            if data.count!=1 then accepted=false else (
                local row=(cyrusPlacementPage data (cyrusPlacementToken data) 0 1)[1]
                if QRoot.procPublishedSources[i][row[2]]!=expectedSources[i] do accepted=false
            )
        )
        QAssert accepted "R7-M07-01" "Both measured tree assets and the distinct green copy each have one explicitly accepted row"
        local fingerprint=QFingerprint(),epoch=QRoot.procEpoch,triangles=3496532
        QRoot.setGroupDisplay 3
        local before=QMemoryLifeDraw QNode,log=createFile (MCPFixtureDir+"high-poly-aggregate-memory.txt")
        QMemoryLifeLog log "Three distinct sources, Automatic" before
        QAssert ((QMemoryLifeFull before triangles) and before[5][3]==triangles and QFingerprint()==fingerprint and QRoot.procEpoch==epoch) "R7-M07-02" "3,496,532 distinct source triangles actually prepare as full Mesh without changing placements"
        local bakes=cyrusMaterialPreviewStats(),materialKey=cyrusMaterialPreviewKey #(red)
        local displayKey=QRoot.procPublishedDisplayKey,presentation=cyrusRetainedPresentationStats before[1]
        red.material=standardMaterial name:"Q red material successor" diffuse:(color 150 35 20)
        local after=QMemoryLifeDraw QNode,afterBakes=cyrusMaterialPreviewStats()
        local afterKey=cyrusMaterialPreviewKey #(red),afterPresentation=cyrusRetainedPresentationStats after[1]
        -- A scalar Standard material has no Texmap to bake. Prove that the
        -- changed material key was committed and its complete successor became
        -- visible; map-bake counts are diagnostic only for this replacement.
        local consumed=afterKey!=materialKey and QRoot.procPublishedDisplayKey!=displayKey and QRoot.procPublishedDisplayKey==QRoot.procDisplayInputKey() and (findString QRoot.procPublishedDisplayKey ("Materials:"+afterKey+"|"))!=undefined
        local presented=after[1]==before[1] and afterPresentation[3]>presentation[3] and afterPresentation[2]==afterPresentation[3] and afterPresentation[4]==2 and afterPresentation[5] and afterPresentation[6]==afterPresentation[7] and afterPresentation[11]==0
        format "Material successor predicates: %\n" #(#("full Mesh",QMemoryLifeFull after triangles),#("fingerprint",QFingerprint()==fingerprint,QFingerprint(),fingerprint),#("epoch",QRoot.procEpoch==epoch,QRoot.procEpoch,epoch),#("geometry upload",after[6][2]==before[6][2],after[6][2],before[6][2]),#("transform upload",after[6][3]==before[6][3],after[6][3],before[6][3]),#("consumed material key",consumed,materialKey,afterKey),#("new complete visible generation",presented,presentation,afterPresentation),#("observed map bakes",bakes,afterBakes)) to:log
        QMemoryLifeLog log "Material successor, Automatic" after
        QAssert ((QMemoryLifeFull after triangles) and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and after[6][2]==before[6][2] and after[6][3]==before[6][3] and consumed and presented) "R7-M07-03" "Automatic scalar material refresh commits a complete visible successor, preserves placements and reuses geometry and transform streams across the aggregate tree result"
        -- A tiny non-TriObject conversion must still support placement/Auto
        -- metadata when the display ceiling is below retained tree resources.
        QRequire (after[4][4]>268435456L) "Fixture did not exceed the low custom display ceiling"
        cyrusSetViewportMemoryLimit 256
        local tiny=box name:"Q metadata independence" width:3 length:4 height:5 pos:[5000,0,0];hide tiny
        local info=(cyrusSourceGeometryInfo #(tiny))[1],metadata=cyrusSourceGeometryMemoryStats(),limited=cyrusViewportMemoryStats()
        QAssert (info[1]==1 and info[6] and metadata[2]==0 and metadata[4]==0 and limited[2]==256 and limited[4]==after[4][4] and QFingerprint()==fingerprint and QRoot.procEpoch==epoch) "R7-M07-04" "Low display preference cannot reject or charge bounded Auto Radius metadata conversion; temporary metadata ownership releases"
        cyrusSetViewportMemoryLimit 0
        QMemoryLifeLog log "Metadata conversion after lowering display ceiling" (QMemoryLifeState QNode)
        close log
    )
    "R7-M08": (
        local firstState=QMemoryLifeLoad(),firstNode=QNode,firstRoot=QRoot,firstLayer=QLayer
        local firstFingerprint=QMemoryLifeFingerprint firstRoot,firstEpoch=firstRoot.procEpoch
        local source=firstLayer.sources[1],receivers=firstLayer.validSurfaces(),greenFaces=1640630
        local secondNode=AminScatterObject name:"Q second high-poly Scatter",secondRoot=secondNode.baseObject
        secondRoot.updateMode=1;secondRoot.autoRender=false
        secondRoot.viewportFaces=20000000;secondRoot.viewportNavigationFaces=20000000;secondRoot.identificationMode=4
        local secondLayer=QMemoryLifeLayer secondRoot source receivers 1201
        secondRoot.evaluateProcedural();QRequire (secondLayer.previewError=="") secondLayer.previewError
        secondRoot.setGroupDisplay 3
        local secondState=QMemoryLifeDraw secondNode,firstNow=QMemoryLifeState firstNode
        local secondFingerprint=QMemoryLifeFingerprint secondRoot,secondEpoch=secondRoot.procEpoch
        local log=createFile (MCPFixtureDir+"high-poly-owner-lifecycle-memory.txt")
        QMemoryLifeLog log "First owner before second owner" firstState
        QMemoryLifeLog log "Two independent controllers" secondState
        QAssert ((QMemoryLifeFull firstNow (2*greenFaces)) and (QMemoryLifeFull secondState greenFaces) and firstNow[1]!=secondState[1] and firstNow[2][13]==firstState[2][13] and (QMemoryLifeFingerprint firstRoot)==firstFingerprint and firstRoot.procEpoch==firstEpoch and secondState[4][4]>firstState[4][4]) "R7-M08-01" "A second full-Mesh controller adds real owned resources and preserves the first complete result"
        -- Pin the old CPU caches exactly as a history/client reference can.
        -- New appearance allocations coexist with these genuine old resources;
        -- the test does not clear Undo or evict caches to admit the successor.
        local pinnedFirst=firstLayer.cachedPoints,pinnedSecond=secondLayer.cachedPoints
        local oldFirstStatus=cyrusMaterialPreviewStatus pinnedFirst,oldSecondStatus=cyrusMaterialPreviewStatus pinnedSecond
        local beforeMemory=cyrusViewportMemoryStats(),beforeStreams=cyrusRetainedStreamStats()
        source.material=standardMaterial name:"Q shared green material successor" diffuse:(color 35 145 65)
        firstRoot.refreshDisplay();secondRoot.refreshDisplay()
        secondState=QMemoryLifeDraw secondNode;firstNow=QMemoryLifeState firstNode
        local afterMemory=cyrusViewportMemoryStats(),afterStreams=cyrusRetainedStreamStats()
        QMemoryLifeLog log "New appearance while old CPU caches are pinned" secondState
        -- The source appearance is physically shared between controllers: one
        -- old float32 UV array remains pinned, not two. Allow 100 MiB for
        -- the maximum two-owner SDK/device atlas reduction (96 MiB) and
        -- dependency bookkeeping when the new material has only one tile.
        local minimumPinnedGrowth=(1L*greenFaces*72)-104857600L
        QAssert ((QMemoryLifeFull firstNow (2*greenFaces)) and (QMemoryLifeFull secondState greenFaces) and (QMemoryLifeFingerprint firstRoot)==firstFingerprint and (QMemoryLifeFingerprint secondRoot)==secondFingerprint and firstRoot.procEpoch==firstEpoch and secondRoot.procEpoch==secondEpoch and afterStreams[2]==beforeStreams[2] and afterStreams[3]==beforeStreams[3] and afterMemory[4]>=beforeMemory[4]+minimumPinnedGrowth and afterMemory[5]>=afterMemory[4] and (cyrusMaterialPreviewStatus pinnedFirst)==oldFirstStatus and (cyrusMaterialPreviewStatus pinnedSecond)==oldSecondStatus) "R7-M08-02" "Automatic material replacement retains pinned old appearance storage, counts real overlap and reuses unchanged geometry and transforms for both owners"
        pinnedFirst=undefined;pinnedSecond=undefined;gc light:true
        QMemoryLifeLog log "After releasing explicit old-cache pins" (QMemoryLifeState secondNode)
        undo "Q high-poly amount" on secondLayer.amount=2
        secondState=QMemoryLifeDraw secondNode
        QAssert (secondLayer.amount==2 and secondRoot.groupSnapshotRows[1].count==1 and (QMemoryLifeFingerprint secondRoot)==secondFingerprint and secondRoot.procEpoch==secondEpoch) "R7-M08-03" "Display refresh preserves a pending Manual Count edit and its preceding complete publication"
        secondRoot.refreshAll();secondState=QMemoryLifeDraw secondNode
        local changedFingerprint=QMemoryLifeFingerprint secondRoot
        QRequire (secondRoot.groupSnapshotRows[1].count==2 and changedFingerprint!=secondFingerprint) "Explicit Update did not publish the pending Count"
        max undo;QSettle 300
        QRequire (secondLayer.amount==1) "Count Undo did not restore authored input"
        secondRoot.refreshAll();QMemoryLifeDraw secondNode
        QRequire ((QMemoryLifeFingerprint secondRoot)==secondFingerprint) "Undo plus Update did not restore exact rows"
        max redo;QSettle 300
        QRequire (secondLayer.amount==2) "Count Redo did not restore authored input"
        secondRoot.refreshAll();secondState=QMemoryLifeDraw secondNode
        QAssert ((QMemoryLifeFull secondState (2*greenFaces)) and (QMemoryLifeFingerprint secondRoot)==changedFingerprint and (QMemoryLifeFingerprint firstRoot)==firstFingerprint) "R7-M08-04" "Authored Count Undo/Redo plus explicit Update restores exact full-Mesh results without altering the other controller"
        secondRoot.updateMode=2;QSettle 900
        local liveBefore=secondRoot.procEpoch
        receivers[1].pos.x+=10
        local deadline=timeStamp()+20000
        while secondRoot.procEpoch==liveBefore and timeStamp()<deadline do QSettle 100
        QRequire (secondRoot.procEpoch>liveBefore and secondLayer.previewError=="") "Relevant Live receiver edit did not publish"
        local liveEpoch=secondRoot.procEpoch,liveFingerprint=QMemoryLifeFingerprint secondRoot
        QSettle 700
        local unrelated=box name:"Q unrelated high-poly Live activity" pos:[6000,0,0];unrelated.pos.y+=10;QSettle 700
        secondState=QMemoryLifeState secondNode
        QAssert ((QMemoryLifeFull secondState (2*greenFaces)) and secondRoot.procEpoch==liveEpoch and (QMemoryLifeFingerprint secondRoot)==liveFingerprint and liveFingerprint!=changedFingerprint and (QMemoryLifeFingerprint firstRoot)==firstFingerprint and firstRoot.procEpoch==firstEpoch) "R7-M08-05" "Relevant Live edits settle once; unrelated activity and the other Manual controller preserve their publications"
        secondRoot.updateMode=1
        -- Publish the first owner's pending receiver change before testing a
        -- deterministic save/reopen. Saved authored state must reproduce both.
        firstRoot.refreshAll();firstNow=QMemoryLifeDraw firstNode
        local savedFirst=QMemoryLifeFingerprint firstRoot,savedSecond=QMemoryLifeFingerprint secondRoot
        local firstID=firstLayer.layerID,secondID=secondLayer.layerID,scene=MCPFixtureDir+"high-poly-two-owner.max"
        QMemoryLifePublicationLog log "First published inputs before save" firstRoot
        QMemoryLifePublicationLog log "Second published inputs before save" secondRoot
        format "Save baseline: IDs % / %, fingerprints % / %, first full %, second full %, requested limit %\n" firstID secondID savedFirst savedSecond (QMemoryLifeFull firstNow (2*greenFaces)) (QMemoryLifeFull secondState (2*greenFaces)) (cyrusViewportMemoryStats())[2] to:log
        QMemoryLifeLog log "First owner immediately before save" firstNow
        QMemoryLifeLog log "Second owner immediately before save" secondState
        saveMaxFile scene quiet:true
        resetMaxFile #noPrompt;loadMaxFile scene quiet:true useFileUnits:true
        CyrusPerfHeadless=true;CyrusPointSuspended=true
        firstNode=getNodeByName "Tree Scatter" exact:true;secondNode=getNodeByName "Q second high-poly Scatter" exact:true
        QRequire (isValidNode firstNode and isValidNode secondNode) "Save/reopen lost a controller"
        firstRoot=firstNode.baseObject;secondRoot=secondNode.baseObject
        firstLayer=firstRoot.layerObjects[1];secondLayer=secondRoot.layerObjects[1]
        firstRoot.evaluateProcedural();secondRoot.evaluateProcedural()
        firstNow=QMemoryLifeDraw firstNode;secondState=QMemoryLifeDraw secondNode
        QMemoryLifePublicationLog log "First published inputs after reopen" firstRoot
        QMemoryLifePublicationLog log "Second published inputs after reopen" secondRoot
        format "Reopen predicates: %\n" #(#("first ID",firstLayer.layerID==firstID,firstLayer.layerID,firstID),#("second ID",secondLayer.layerID==secondID,secondLayer.layerID,secondID),#("first fingerprint",(QMemoryLifeFingerprint firstRoot)==savedFirst,QMemoryLifeFingerprint firstRoot,savedFirst),#("second fingerprint",(QMemoryLifeFingerprint secondRoot)==savedSecond,QMemoryLifeFingerprint secondRoot,savedSecond),#("first full",QMemoryLifeFull firstNow (2*greenFaces)),#("second full",QMemoryLifeFull secondState (2*greenFaces)),#("Automatic",(cyrusViewportMemoryStats())[2]==0,(cyrusViewportMemoryStats())[2])) to:log
        QMemoryLifeLog log "First owner after reopen before assertion" firstNow
        QMemoryLifeLog log "Second owner after reopen before assertion" secondState
        QAssert (firstLayer.layerID==firstID and secondLayer.layerID==secondID and (QMemoryLifeFingerprint firstRoot)==savedFirst and (QMemoryLifeFingerprint secondRoot)==savedSecond and (QMemoryLifeFull firstNow (2*greenFaces)) and (QMemoryLifeFull secondState (2*greenFaces)) and (cyrusViewportMemoryStats())[2]==0) "R7-M08-06" "Save/reopen retains identities and reproduces exact complete full-Mesh results for both controllers"
        QMemoryLifeLog log "Both owners after save/reopen" secondState
        undo "Q delete second high-poly controller" on delete secondNode
        QSettle 400;firstNow=QMemoryLifeDraw firstNode
        QRequire ((QMemoryLifeFull firstNow (2*greenFaces)) and (QMemoryLifeFingerprint firstRoot)==savedFirst) "Deleting the second controller damaged the first"
        max undo;QSettle 500
        secondNode=getNodeByName "Q second high-poly Scatter" exact:true
        QRequire (isValidNode secondNode) "Delete Undo lost the second controller"
        secondRoot=secondNode.baseObject;secondRoot.evaluateProcedural();secondState=QMemoryLifeDraw secondNode
        QAssert ((QMemoryLifeFull secondState (2*greenFaces)) and (QMemoryLifeFingerprint secondRoot)==savedSecond and (QMemoryLifeFingerprint firstRoot)==savedFirst) "R7-M08-07" "Controller deletion and Undo preserve the surviving owner and restore the second complete result"
        QMemoryLifeLog log "Second owner restored by Undo" secondState
        close log
    )
    default: throw "Unknown viewport memory lifecycle scenario"
)
