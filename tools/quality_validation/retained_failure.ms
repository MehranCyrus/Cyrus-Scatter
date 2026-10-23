-- Bounded Max 2027 host qualification of the already-loaded product pair.
-- R7-F00 belongs to the production build. R7-F01..03 require the separate
-- NEVER_SHIP fault build. This fixture never fileIns a product script.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
fileIn ((getFilenamePath(getSourceFileName()))+"maple_texture_inputs.ms")

global QFaultStart,QFaultPointCache,QFaultWait,QFaultRecord,QFaultProduct,QFaultCapture,QFaultImageSame,QFaultLog
global QHighPolyBaseline,QHighPolyFingerprint

fn QFaultStart = (
    QRequire (matchPattern MCPFixtureDir pattern:"*/build/*") "Owned test profile required"
    QRequire (cyrusOwnedPreviewFault!=undefined) "The separate NEVER_SHIP preview-fault build is required"
    cyrusOwnedPreviewFault 0 0
    resetMaxFile #noPrompt
    QNode=undefined;QRoot=undefined;QLayer=undefined
    CyrusPerfHeadless=true;CyrusPointSuspended=true;CyrusPointClear()
    cyrusSetViewportMemoryLimit 0
    QRequire (not isSceneRedrawDisabled()) "Owned host redraw must be enabled"
    QRequire (cyrusRetainedAvailable()) "Nitrous retained drawing is unavailable"
    hideByCategory.helpers=false
    viewport.setLayout #layout_1;viewport.setType #view_top;viewport.SetRenderLevel #smoothhighlights
    gc light:false;completeRedraw();QSettle 150
)
fn QFaultPointCache groups offset:0.0 = (
    QRequire (groups>=1 and groups<=8) "Point fault fixture exceeds its eight-group bound"
    local rows=for i=1 to groups collect #((transMatrix [offset+i*4.0-20.0,0,2]),i,(i as integer64),1,[1,0,0],0,false,2)
    aminScatterBuildPreview rows (for i=1 to groups collect #([0,0,0])) #(1,1,(for i=1 to groups collect white),#(),false) 500000
)
-- Matches is the host-side readiness observer. Never call Publish in this
-- wait: an observed failure must remain failed until the explicit retry.
fn QFaultWait owner caches styles wanted priorFailedTicket:undefined = (
    local deadline=timeStamp()+20000,state=cyrusRetainedPresentationStats owner,loggedPriorFailure=false
    while timeStamp()<deadline do (
        local matched=cyrusRetainedMatches owner caches styles
        completeRedraw();QSettle 50
        state=cyrusRetainedPresentationStats owner
        QRequire (state.count==14 and state[1]==1) "Unexpected presentation diagnostic schema"
        if wanted==#failed and state[4]==3 do (
            -- Permit host retirement of failed items, retaining its diagnostics.
            cyrusRetainedMatches owner caches styles;completeRedraw();QSettle 50
            return cyrusRetainedPresentationStats owner
        )
        if wanted==#ready and state[4]==3 do (
            -- An explicit product refresh can defer publication while the host
            -- is interacting. Only its already-failed predecessor may wait;
            -- a failure on any new requested ticket is still terminal here.
            if priorFailedTicket==undefined or state[2]!=priorFailedTicket do throw ("Unexpected realization failure: "+state[14])
            if not loggedPriorFailure do (QFaultLog "Retry awaiting new requested ticket" state;loggedPriorFailure=true)
        )
        if wanted==#ready and state[4]==2 and state[5] and state[2]==state[3] and (cyrusRetainedMatches owner caches styles) do return state
    )
    throw ("Requested presentation did not settle: "+(state as string))
)
fn QFaultRecord = (
    local record=undefined
    for entry in CyrusViewportRecords where entry[1]==QNode do record=entry
    QRequire (record!=undefined and isValidNode record[2] and record[3].count>0) "Product did not stage a retained record"
    record
)
fn QFaultProduct wanted = (
    local priorFailedTicket=undefined
    if wanted==#ready do for entry in CyrusViewportRecords where entry[1]==QNode and isValidNode entry[2] do (
        local prior=cyrusRetainedPresentationStats entry[2]
        QRequire (prior.count==14 and prior[1]==1) "Unexpected presentation diagnostic schema"
        if prior[4]==3 do priorFailedTicket=prior[2]
    )
    CyrusPointSuspended=false;QRoot.refreshDisplay()
    local record=QFaultRecord()
    if priorFailedTicket!=undefined do QFaultLog "Explicit retry requested" #(priorFailedTicket,cyrusRetainedPresentationStats record[2])
    QFaultWait record[2] record[3] record[4] wanted priorFailedTicket:priorFailedTicket
)
-- At most 256x256 samples. The RGB digest is quantized to four bits/channel;
-- the separate red/green mask detects a partially drawn material successor.
fn QFaultCapture label = (
    completeRedraw();QSettle 100
    local image=gw.getViewportDib(),reds=0,greens=0,mask=#(),rgb=#()
    local stepX=amax 1 (ceil (image.width/256.0)),stepY=amax 1 (ceil (image.height/256.0))
    for y=0 to (image.height-1) by stepY do (
        local row=getPixels image [0,y] image.width
        for x=1 to row.count by stepX do (
            local pixel=row[x],kind=0
            if pixel.r>90 and pixel.r>1.6*pixel.g and pixel.r>1.6*pixel.b do (kind=1;reds+=1)
            if pixel.g>90 and pixel.g>1.6*pixel.r and pixel.g>1.6*pixel.b do (kind=2;greens+=1)
            append mask kind
            append rgb ((floor(pixel.r/16.0))*256+(floor(pixel.g/16.0))*16+(floor(pixel.b/16.0)))
        )
    )
    image.filename=MCPFixtureDir+label+".png";save image
    local result=#(reds,greens,mask.count,image.width,image.height,mask,rgb)
    close image;result
)
fn QFaultImageSame before after colored:false = (
    if before[4]!=after[4] or before[5]!=after[5] or before[3]!=after[3] do return false
    local changed=0,index=if colored then 6 else 7
    for i=1 to before[3] where before[index][i]!=after[index][i] do changed+=1
    local population=if colored then before[1]+before[2] else before[3]
    changed<=amax 8 (population*0.02)
)
fn QFaultLog label data = (
    local stream=openFile (MCPFixtureDir+"retained-failure-evidence.txt") mode:"a"
    format "%: %\n" label data to:stream;close stream
)

if QScenarioID=="R7-F00" then (
    QAssert (cyrusOwnedPreviewFault==undefined) "R7-F00-01" "Production payload exposes no owned preview-fault primitive"
) else try (
    case QScenarioID of (
        "R7-F01": (
            QFaultStart();viewport.ZoomToBounds false [-35,-25,-5] [35,25,5]
            local initialMemory=cyrusPreviewResourceStats()
            local controller=box name:"Q fault Point controller" width:0.1 length:0.1 height:0.1 pos:[-32,-22,-4]
            local owner=cyrusRetainedCreate(),first=QFaultPointCache 3,styles=#(#(false,white))
            cyrusOwnedPreviewFault 1 1
            QRequire (cyrusRetainedPublish owner controller #(first) styles) "Initial point preparation rejected before the injected realization"
            local failed=QFaultWait owner #(first) styles #failed
            QFaultLog "F01 initial failure" #(failed,cyrusRetainedStats owner,cyrusViewportMemoryStats())
            QAssert (failed[4]==3 and failed[3]==0 and not failed[5] and failed[6]==0 and failed[7]==3 and failed[8] and failed[14]!="" and not (cyrusRetainedMatches owner #(first) styles)) "R7-F01-01" "Initial shader failure reports no invented visible generation and permits explicit retry"
            cyrusOwnedPreviewFault 0 0
            QRequire (cyrusRetainedPublish owner controller #(first) styles) "Identical first input could not retry"
            local ready=QFaultWait owner #(first) styles #ready,before=cyrusRetainedStats owner
            completeRedraw();QSettle 80
            QAssert (ready[2]>failed[2] and ready[2]==ready[3] and ready[5] and ready[6]==3 and ready[11]==0 and (cyrusRetainedStats owner)[8]>before[8]) "R7-F01-02" "The same point inputs retry as one complete visible generation and perform actual draws"

            before=cyrusRetainedStats owner;hide controller;completeRedraw();QSettle 100
            local hidden=cyrusRetainedPresentationStats owner
            QRequire (not hidden[5] and not hidden[10] and hidden[3]==ready[3]) "Hide left a retained generation drawable"
            unhide controller
            local shown=QFaultWait owner #(first) styles #ready
            QAssert (shown[3]==ready[3] and shown[10] and (cyrusRetainedStats owner)[6]==before[6]) "R7-F01-03" "Hide/unhide disables and restores the same complete point buffers without upload"
            undo "Q fault controller deletion" on delete controller
            completeRedraw();QSettle 100
            local deleted=cyrusRetainedPresentationStats owner
            QRequire (not deleted[5] and not deleted[10]) "Deleting the controller left SDK-pinned items drawable"
            max undo;QSettle 100
            controller=getNodeByName "Q fault Point controller" exact:true
            QRequire (isValidNode controller and cyrusRetainedPublish owner controller #(first) styles) "Deleted controller could not rebind after Undo"
            shown=QFaultWait owner #(first) styles #ready
            QAssert (shown[3]==ready[3] and shown[5] and (cyrusRetainedStats owner)[6]==before[6]) "R7-F01-04" "Deletion hides retained items immediately and Undo plus valid controller rebinding restores unchanged buffers"

            local next=QFaultPointCache 4 offset:1.0,latest=QFaultPointCache 5 offset:2.0
            local staged=undefined,superseding=undefined,uploadsBefore=(cyrusRetainedStats owner)[6]
            with redraw off (
                QRequire (cyrusRetainedPublish owner controller #(next) styles) "First pending point successor rejected"
                staged=cyrusRetainedPresentationStats owner
                QRequire (cyrusRetainedPublish owner controller #(latest) styles) "Superseding point successor rejected"
                superseding=cyrusRetainedPresentationStats owner
            )
            QRequire (staged[4]==1 and superseding[4]==1 and staged[3]==ready[3] and superseding[3]==ready[3] and superseding[2]==staged[2]+1) "Pending replacement changed visible identity before realization"
            local newest=QFaultWait owner #(latest) styles #ready,after=cyrusRetainedStats owner
            QAssert (newest[3]==superseding[2] and newest[3]!=staged[2] and newest[11]==0 and after[1]==5 and after[6]-uploadsBefore==10) "R7-F01-05" "Rapid replacement presents only the latest complete five-group successor and never uploads the superseded pending generation"
            QFaultLog "F01 superseded then ready" #(staged,superseding,newest,after)

            resetMaxFile #noPrompt;CyrusPointClear()
            controller=undefined;owner=undefined;first=undefined;next=undefined;latest=undefined
            gc light:false;completeRedraw();QSettle 300
            local released=cyrusPreviewResourceStats(),deadline=timeStamp()+5000
            while (released[2]>initialMemory[2] or released[5]>initialMemory[5]) and timeStamp()<deadline do (
                gc light:false;completeRedraw();QSettle 100;released=cyrusPreviewResourceStats()
            )
            QAssert (released[2]<=initialMemory[2] and released[5]<=initialMemory[5]) "R7-F01-06" "Owned scene reset and last cache release return point and mesh reservations to the starting baseline"
            QFaultLog "F01 reset release" #(initialMemory,released)
        )
        "R7-F02": (
            QFaultStart();QSetup();cyrusSetViewportMemoryLimit 0
            hideByCategory.helpers=false
            viewport.setLayout #layout_1;viewport.setType #view_top;viewport.SetRenderLevel #smoothhighlights
            QSurface.width=45;QSurface.length=45;QSurface.pos=[-55,0,0]
            local secondSurface=copy QSurface;secondSurface.name="Q second fault receiver";secondSurface.pos=[55,0,0]
            local sources=#(),maps=#()
            for i=1 to 2 do (
                local card=plane name:("Q fault card "+i as string) width:30 length:30 widthsegs:1 lengthsegs:1 mapCoords:true pos:[1400+i*100,0,0]
                convertToMesh card
                local map=checker name:("Q fault color "+i as string) color1:(color 255 0 0) color2:(color 255 0 0)
                map.coords.mapChannel=1
                local material=standardMaterial name:("Q fault material "+i as string) diffuse:white selfIllumAmount:100 opacity:100 twoSided:true
                material.diffuseMap=map;material.diffuseMapEnable=true;card.material=material
                append sources card;append maps map;hide card
            )
            QLayer.replacePointSource 1 sources[1];QLayer.amount=1
            QRoot.newLayer();local secondLayer=QRoot.selectedLayer()
            QRoot.setLayerSurfaces secondLayer #(secondSurface);secondLayer.addModelSource sources[2]
            secondLayer.amount=1;secondLayer.procSelfOverride=true;secondLayer.procSelfEnabled=false;secondLayer.procLayerSelfEnabled=false
            QRoot.identificationMode=4;QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000;QRoot.setGroupDisplay 3
            QCalculate();hide QSurface;hide secondSurface;hide QModel;clearSelection()
            viewport.ZoomToBounds false [-100,-55,-5] [100,55,5]
            local old=QFaultProduct #ready,record=QFaultRecord(),owner=record[2]
            local fingerprint=QFingerprint(),epoch=QRoot.procEpoch,builds=QRoot.groupBuilds
            local original=QFaultCapture "fault-cards-red-ready",streams=cyrusRetainedStreamStats(),plan=cyrusRetainedViewportStats owner
            QFaultLog "F02 ready baseline" #(old,fingerprint,epoch,builds,streams,plan,#(original[1],original[2],original[3],original[4],original[5]),QLayer.amount,QRoot.groupSnapshotRows[1].count)
            QAssert (old[5] and old[6]==2 and old[7]==2 and plan[6]==4 and plan[8]==0 and original[1]>100 and original[1]>4*original[2]) "R7-F02-01" "Two mapped red card populations actually draw as one complete four-triangle Mesh generation"
            QLayer.amount=7
            local fallback=cyrusPreviewFallbackStats(),oldTicket=old[3],oldHash=old[13]
            cyrusOwnedPreviewFault 6 1
            for map in maps do (map.color1=color 0 255 0;map.color2=color 0 255 0)
            local failed=QFaultProduct #failed
            local failedImage=QFaultCapture "fault-cards-uv-failure-retained-red",failedStats=cyrusRetainedStats owner
            QFaultLog "F02 UV failure" #(old,failed,failedStats,cyrusViewportMemoryStats(),cyrusRetainedStreamStats())
            QAssert (failed[4]==3 and failed[2]>oldTicket and failed[3]==oldTicket and failed[5] and failed[8] and failed[11]==1 and failed[13]==oldHash and failed[14]!="" and failedStats[12]==2 and failedStats[13]==oldHash and (QFaultImageSame original failedImage colored:true) and (cyrusPreviewFallbackStats())[2]==fallback[2]) "R7-F02-02" "A real post-texture/pre-UV failure preserves the complete old red image and visible ticket without CPU marker overlay"
            QRequire (QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QLayer.amount==7) "UV failure changed placement publication or pending Manual inputs"
            cyrusOwnedPreviewFault 0 0
            local recovered=QFaultProduct #ready,green=QFaultCapture "fault-cards-green-recovered",afterStreams=cyrusRetainedStreamStats()
            QFaultLog "F02 recovery predicates" #(#("new visible ticket",recovered[3]>failed[2],recovered[3],failed[2]),#("current visible",recovered[2]==recovered[3],recovered[2],recovered[3]),#("old bundle retired",recovered[11]==0,recovered[11]),#("green population",green[2]>100,green[2]),#("green dominates",green[2]>4*green[1],green[2],green[1]),#("fingerprint",QFingerprint()==fingerprint,QFingerprint(),fingerprint),#("epoch",QRoot.procEpoch==epoch,QRoot.procEpoch,epoch),#("builds",QRoot.groupBuilds==builds,QRoot.groupBuilds,builds),#("pending amount",QLayer.amount==7,QLayer.amount),#("published rows",QRoot.groupSnapshotRows[1].count==1,QRoot.groupSnapshotRows[1].count),#("geometry upload",afterStreams[2]==streams[2],afterStreams[2],streams[2]),#("transform upload",afterStreams[3]==streams[3],afterStreams[3],streams[3]),recovered,afterStreams,cyrusRetainedStats owner)
            QAssert (recovered[3]>failed[2] and recovered[2]==recovered[3] and recovered[11]==0 and green[2]>100 and green[2]>4*green[1] and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and QLayer.amount==7 and QRoot.groupSnapshotRows[1].count==1 and afterStreams[2]==streams[2] and afterStreams[3]==streams[3]) "R7-F02-03" "Explicit same-input retry presents the green successor, reuses geometry/transforms and preserves pending Manual Count"

            old=recovered;fallback=cyrusPreviewFallbackStats()
            cyrusOwnedPreviewFault 3 2
            for map in maps do (map.color1=color 255 0 0;map.color2=color 255 0 0)
            failed=QFaultProduct #failed
            local partialImage=QFaultCapture "fault-cards-later-group-retained-green"
            QAssert (failed[4]==3 and failed[6]==1 and failed[7]==2 and failed[3]==old[3] and failed[5] and failed[8] and (QFaultImageSame green partialImage colored:true) and (cyrusPreviewFallbackStats())[2]==fallback[2]) "R7-F02-04" "Failure in the second Mesh group leaves the first uploaded successor invisible and retains the entire preceding green image"
            local failedTicket=failed[2],failures=(cyrusRetainedStats owner)[9]
            for i=1 to 4 do (completeRedraw();QSettle 50)
            local idle=cyrusRetainedPresentationStats owner
            QAssert (idle[2]==failedTicket and idle[3]==old[3] and idle[4]==3 and idle[8] and (cyrusRetainedStats owner)[9]==failures and QFingerprint()==fingerprint and QRoot.procEpoch==epoch) "R7-F02-05" "Idle drawing retains explicit failure and retry eligibility without an automatic failing publication loop"
            cyrusOwnedPreviewFault 0 0
            recovered=QFaultProduct #ready
            local red=QFaultCapture "fault-cards-red-recovered"
            QAssert (recovered[3]>failedTicket and recovered[5] and recovered[11]==0 and red[1]>100 and red[1]>4*red[2] and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QLayer.amount==7 and (cyrusRetainedStreamStats())[2]==streams[2]) "R7-F02-06" "Explicit recovery after a later-group failure atomically restores both red populations with exact placement retention"
            QFaultLog "F02 final recovery" #(recovered,cyrusRetainedStats owner,cyrusViewportMemoryStats(),QFingerprint(),QRoot.procEpoch)
        )
        "R7-F03": (
            QFaultStart();fileIn (MCPFixtureDir+"hpm-input.ms")
            QRequire (doesFileExist QHighPolyBaseline) "Missing measured high-poly baseline"
            loadMaxFile QHighPolyBaseline quiet:true useFileUnits:true
            CyrusPerfHeadless=true;CyrusPointSuspended=true
            QNode=getNodeByName "Tree Scatter" exact:true;QRequire (isValidNode QNode) "Baseline Scatter missing"
            QRoot=QNode.baseObject;QLayer=QRoot.selectedLayer();QRoot.updateMode=1;QRoot.autoRender=false
            QCalculate();QRequire (QFingerprint()==QHighPolyFingerprint) "Exact measured baseline placement fingerprint differs"
            QResolveMapleTextureInputs QRoot
            QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000;QRoot.identificationMode=4;QRoot.setGroupDisplay 3
            local row=(QRows())[1],center=row[1].row4
            local camera=targetCamera name:"Q fault maple camera" pos:(center+[30,-45,24]) target:(targetObject pos:(center+[0,0,8]))
            viewport.setCamera camera;clearSelection()
            local old=QFaultProduct #ready,record=QFaultRecord(),owner=record[2],plan=cyrusRetainedViewportStats owner
            local fingerprint=QFingerprint(),epoch=QRoot.procEpoch,before=cyrusRetainedStats owner,streams=cyrusRetainedStreamStats()
            local original=QFaultCapture "fault-maple-ready"
            QAssert (old[5] and plan[6]==3281260 and plan[8]==0 and before[12]==1) "R7-F03-01" "Exact two-placement measured maple baseline is a complete 3,281,260-triangle Mesh before injection"
            local fallback=cyrusPreviewFallbackStats(),memoryBefore=cyrusViewportMemoryStats()
            cyrusOwnedPreviewFault 6 1
            QLayer.sources[1].material=standardMaterial name:"Q maple material failure" diffuse:(color 35 180 65)
            local failed=QFaultProduct #failed,failedImage=QFaultCapture "fault-maple-uv-failure-retained"
            local failedPlan=cyrusRetainedViewportStats owner,memoryFailed=cyrusViewportMemoryStats()
            QFaultLog "F03 real maple late failure" #(old,failed,memoryBefore,memoryFailed,failedPlan,cyrusRetainedStats owner,cyrusRetainedStreamStats())
            QAssert (failed[4]==3 and failed[2]>old[2] and failed[3]==old[3] and failed[5] and failed[8] and failed[13]==old[13] and failed[14]!="" and failedPlan[6]==plan[6] and failedPlan[8]==0 and (QFaultImageSame original failedImage) and (cyrusPreviewFallbackStats())[2]==fallback[2]) "R7-F03-02" "Measured high-poly UV upload failure retains the old visible ticket, full-Mesh plan and sampled viewport image without markers"
            cyrusOwnedPreviewFault 0 0
            local recovered=QFaultProduct #ready,after=cyrusRetainedStats owner,afterPlan=cyrusRetainedViewportStats owner
            QAssert (recovered[3]>failed[2] and recovered[5] and recovered[11]==0 and after[12]==1 and afterPlan[6]==plan[6] and afterPlan[8]==0 and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and (cyrusRetainedStreamStats())[2]==streams[2] and (cyrusRetainedStreamStats())[3]==streams[3]) "R7-F03-03" "Same-input high-poly recovery presents a complete successor with exact placements and reused geometry/transforms"
            local memoryAfter=cyrusViewportMemoryStats()
            QAssert (memoryAfter[8]==0 and memoryAfter[4]<=memoryAfter[3] and memoryAfter[7]<=memoryAfter[13] and memoryAfter[5]>=memoryAfter[4]) "R7-F03-04" "After high-poly recovery pending reservations release and live total/device payloads remain within the admitted policy"
            QFaultCapture "fault-maple-recovered"
            QFaultLog "F03 recovery" #(recovered,memoryAfter,after,QFingerprint(),QRoot.procEpoch)
        )
        default: throw "Unknown retained failure scenario"
    )
    cyrusOwnedPreviewFault 0 0
) catch (
    if cyrusOwnedPreviewFault!=undefined do cyrusOwnedPreviewFault 0 0
    throw()
)
