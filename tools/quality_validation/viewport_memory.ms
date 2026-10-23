-- Exact product-pair host scenarios. Large assets are supplied by the owned run,
-- never shipped with the test or fetched from an artist's open scene.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
fileIn ((getFilenamePath(getSourceFileName()))+"maple_texture_inputs.ms")
global QMemoryDraw,QMemoryLoadTrees,QHighPolyBaseline,QHighPolyFingerprint
fn QMemoryDraw = (
    CyrusPointSuspended=false
    QRoot.refreshDisplay();CyrusViewportRedraw();QSettle 1200
    local owner=CyrusPointOwner QNode
    QRequire (isValidNode owner) "No retained viewport owner"
    #(owner,cyrusRetainedStats owner,cyrusRetainedViewportStats owner,cyrusViewportMemoryStats())
)
fn QMemoryLoadTrees = (
    fileIn (MCPFixtureDir+"hpm-input.ms")
    QRequire (doesFileExist QHighPolyBaseline) "Missing exact high-poly baseline scene"
    cyrusSetViewportMemoryLimit 0
    loadMaxFile QHighPolyBaseline quiet:true useFileUnits:true
    CyrusPerfHeadless=true;CyrusPointSuspended=true
    QNode=getNodeByName "Tree Scatter" exact:true;QRoot=QNode.baseObject;QLayer=QRoot.selectedLayer()
    QRoot.updateMode=1;QRoot.autoRender=false
    QCalculate()
    QRequire (QFingerprint()==QHighPolyFingerprint) "Placement IDs/transforms/radii differ from the saved .6 baseline"
    QResolveMapleTextureInputs QRoot
    QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000
    QRoot.identificationMode=4;QRoot.setGroupDisplay 3
    QMemoryDraw()
)
case QScenarioID of (
    "R7-M03": (
        QSetup();local fingerprint=QFingerprint(),epoch=QRoot.procEpoch
        QLayer.amount=401
        undo "Viewport preference sentinel" on box name:"Memory sentinel"
        local sentinel=getNodeByName "Memory sentinel" exact:true
        QMount pages:#("displayUISlot")
        -- Exercise the actual generated entry button and dialog handlers.
        QClick QRoot.displayUI.flow_previewUI_memoryButton
        QRequire (CyrusViewportMemoryDialog.hwnd!=0) "Memory dialog did not open"
        CyrusViewportMemoryDialog.mode.state=2;CyrusViewportMemoryDialog.customLimit.value=512
        QClick CyrusViewportMemoryDialog.applyButton
        QAssert ((cyrusViewportMemoryStats())[2]==512 and getINISetting (CyrusViewportMemoryPreferences()) "Memory" "LimitMiB"=="512") "R7-M03-01" "Actual Apply saves installation preference and selects native allowance"
        QAssert (QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QLayer.amount==401) "R7-M03-02" "Applying memory allowance preserves published placements and pending Manual edits"
        QClick CyrusViewportMemoryDialog.refreshButton
        QAssert (QFingerprint()==fingerprint and QRoot.procEpoch==epoch) "R7-M03-03" "Display retry does not publish pending Manual edits"
        destroyDialog CyrusViewportMemoryDialog
        max undo
        QAssert (not isValidNode sentinel) "R7-M03-04" "Preference changes do not consume or clear the earlier Undo sentinel"
        CyrusOpenViewportMemory QRoot
        QAssert (CyrusViewportMemoryDialog.mode.state==2 and CyrusViewportMemoryDialog.customLimit.value==512) "R7-M03-05" "Dialog reopen binds saved preference"
        destroyDialog CyrusViewportMemoryDialog;CyrusApplyViewportMemory 0
    )
    "R7-M04": (
        local state=QMemoryLoadTrees(),owner=state[1],before=state[2],plan=state[3],fp=QFingerprint(),epoch=QRoot.procEpoch
        QAssert (QLayer.previewError=="" and before[12]==1 and plan[6]>0 and plan[8]==0 and plan[10]==0) "R7-M04-01" "Former failing green maple is a ready full mesh with no memory or triangle boxes"
        local nativeMemory=cyrusViewportMemoryStats(),log=createFile (MCPFixtureDir+"high-poly-memory.txt")
        format "Fingerprint: %\nRows: %\nMemory: %\nRetained: %\nMesh: %\nPlan: %\n" fp (QRows() as string) nativeMemory before (cyrusRetainedMeshStats owner) plan to:log;close log
        select QNode;clearSelection();select QNode;QSettle 500;CyrusViewportRedraw();QSettle 500
        local after=cyrusRetainedStats owner
        QAssert (QRoot.procEpoch==epoch and QFingerprint()==fp and before[4]==after[4] and before[6]==after[6] and before[7]==after[7]) "R7-M04-02" "Selection and idle reuse placements, retained preparation and uploads"
        local row=(QRows())[1],center=row[1].row4
        local camera=targetCamera name:"HPM evidence camera" pos:(center+[30,-45,24]) target:(targetObject pos:(center+[0,0,8]))
        viewport.setCamera camera;completeRedraw();QSettle 500
        local bitmap=gw.getViewportDib();bitmap.filename=MCPFixtureDir+"high-poly-full-mesh.png";save bitmap;close bitmap
        QAssert (doesFileExist (MCPFixtureDir+"high-poly-full-mesh.png")) "R7-M04-03" "Captured actual Max viewport for full-mesh visual inspection"
        QAssert (QMapleTextureInputs[1]==1 and QMapleTextureInputs[2]==2 and QMapleTextureInputs[3]>0 and QMapleTextureInputs[4]==9 and QMapleTextureInputs[5] and QMapleTextureInputs[6] and QMapleTextureInputs[7] and QMapleTextureInputs[8]==QMapleTextureInputs[9] and QFingerprint()==fp and QRoot.procEpoch==epoch) "R7-M04-04" "Both maple materials resolve all nine installed images through Gallery while original material paths, source geometry and exact placement publication remain unchanged"
    )
    "R7-M05": (
        QSetup();cyrusSetViewportMemoryLimit 0
        local dense=box name:"Over two million source" width:100 length:200 height:100 widthsegs:200 lengthsegs:200 heightsegs:200 mapCoords:true
        hide dense
        convertToMesh dense
        QRequire (dense.numfaces==480000) "Base Box topology differs"
        local originalFaces=#{1..480000}
        for copyIndex=1 to 4 do meshop.cloneFaces dense originalFaces
        update dense
        QRequire (dense.numfaces==2400000) "High-poly fixture did not evaluate to 2.4 million triangles"
        local info=(cyrusSourceGeometryInfo #(dense))[1]
        QAssert (info[1]==1 and info[6] and distance info[4] [-50,-100,0]<0.001 and distance info[5] [50,100,100]<0.001) "R7-M05-01" "2.4-million-face source has exact face-referenced bounds and valid Auto capability"
        local key=info[3];dense.objectOffsetScale=[1.02,1,1]
        local changed=(cyrusSourceGeometryInfo #(dense))[1]
        QAssert (changed[3]!=key and distance changed[4] [-51,-100,0]<0.001) "R7-M05-02" "Above-two-million geometry changes invalidate the exact signature and bounds"
        QLayer.replacePointSource 1 dense
        QLayer.sourceAutoRadius[1]=true
        QLayer.scaleMinimum=1.0;QLayer.scaleMaximum=1.0;QLayer.tiltDegrees=0.0;QLayer.yawMinimum=0.0;QLayer.yawMaximum=0.0
        hide dense;QLayer.amount=1;QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000
        QCalculate();QRoot.setGroupDisplay 3
        local drawn=QMemoryDraw()
        local log=createFile (MCPFixtureDir+"over-two-million-memory.txt")
        format "Info: %\nChanged: %\nError: %\nPoint error: %\nRetained: %\nPlan: %\nMesh: %\n" info changed QLayer.previewError CyrusPointLastError drawn[2] drawn[3] (cyrusRetainedMeshStats drawn[1]) to:log;close log
        QAssert (QLayer.previewError=="" and drawn[2][12]==1 and drawn[3][6]==2400000 and drawn[3][8]==0) "R7-M05-03" "2.4-million-face source actually uploads and draws as a complete Mesh"
        local radius=QRoot.procPublishedRadii[1][1]
        QAssert (abs(radius[1]-sqrt(51.0*51.0+100.0*100.0))<0.001 and abs(radius[2]-sqrt(51.0*51.0+100.0*100.0+100.0*100.0))<0.001) "R7-M05-04" "Above-two-million Auto radii match the exact face-referenced bounds independently of display admission"
    )
    "R7-M06": (
        local state=QMemoryLoadTrees(),owner=state[1],fp=QFingerprint(),epoch=QRoot.procEpoch,old=cyrusRetainedStats state[1]
        local oldCache=QLayer.cachedPoints,oldPlan=state[3]
        QRequire (state[4][4]>268435456L) "Fixture does not exceed the low display ceiling"
        cyrusSetViewportMemoryLimit 256
        local lowered=cyrusRetainedStats owner
        QAssert (old[3]==lowered[3] and old[6]==lowered[6] and QRoot.procEpoch==epoch) "R7-M06-01" "Lowering the allowance retains existing resources without eviction or rebuild"
        -- A changed material needs a distinct appearance allocation.
        QLayer.sources[1].material=standardMaterial diffuse:(color 90 180 60)
        QRoot.refreshDisplay();CyrusViewportRedraw();QSettle 300
        local failed=cyrusRetainedStats owner
        local failedPlan=cyrusRetainedViewportStats owner
        QAssert (failed[3]==old[3] and failed[12]==1 and failed[13]==old[13] and QLayer.cachedPoints==oldCache and failedPlan[6]==oldPlan[6] and failedPlan[8]==0 and QFingerprint()==fp and QRoot.procEpoch==epoch) "R7-M06-02" "A rejected material successor retains the exact ready display, full-mesh plan, preview cache and publication"
        QAssert (QLayer.previewError!="" or CyrusPointLastError!="") "R7-M06-03" "This admission failure is explicit in the current display or layer status"
        cyrusSetViewportMemoryLimit 0
        local recovered=QMemoryDraw()
        QAssert (QLayer.previewError=="" and recovered[2][12]==1 and QFingerprint()==fp and QRoot.procEpoch==epoch) "R7-M06-04" "Restoring allowance recovers Mesh display without changing placements"
    )
    default: throw "Unknown viewport memory scenario"
)
