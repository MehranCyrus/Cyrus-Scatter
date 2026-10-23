-- Owned Max 2027 scenarios for the already-loaded, matched product pair.
-- No product fileIn, injected failure API, artist asset or unbounded export.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")

global QRetainedPointCache,QRetainedWait,QRetainedImageCounts,QRetainedCapture,QRetainedMapCapture,QRetainedLeafMask,QRetainedProductDraw,QRetainedLog

fn QRetainedPointCache groups = (
    QRequire (groups>=1 and groups<=1025) "Point fixture exceeds its bounded group count"
    local rows=for i=1 to groups collect #((transMatrix [((mod (i-1) 20)*2.0)-20.0,((floor ((i-1)/20.0))*2.0)-20.0,2.0]),i,(i as integer64),1,[1,0,0],0,false,2)
    aminScatterBuildPreview rows (for i=1 to groups collect #([0,0,0])) #(1,1,(for i=1 to groups collect white),#(),false) 500000
)

-- The host container commits only after all requested items are ready. Calling
-- Matches requests that host update; Calculate is neither needed nor allowed.
fn QRetainedWait owner caches styles = (
    local deadline=timeStamp()+15000,state=cyrusRetainedPresentationStats owner
    while timeStamp()<deadline do (
        local matches=cyrusRetainedMatches owner caches styles
        completeRedraw();QSettle 60
        state=cyrusRetainedPresentationStats owner
        if state[4]==3 do throw ("Requested retained generation failed: "+state[14])
        if state[4]==2 and state[5] and state[2]==state[3] and (cyrusRetainedMatches owner caches styles) do return state
    )
    throw ("Retained presentation did not settle: "+(state as string))
)

-- Bounded image evidence: at most 512 sampled rows and 512 sampled pixels per
-- row. Count saturated red/green independently of gray grid, labels and icons.
fn QRetainedImageCounts image = (
    local reds=0,greens=0,whites=0,total=0
    local stepX=amax 1 (ceil (image.width/512.0)),stepY=amax 1 (ceil (image.height/512.0))
    for y=0 to (image.height-1) by stepY do (
        local row=getPixels image [0,y] image.width
        for x=1 to row.count by stepX do (
            local pixel=row[x]
            if pixel.r>90 and pixel.r>1.6*pixel.g and pixel.r>1.6*pixel.b do reds+=1
            if pixel.g>90 and pixel.g>1.6*pixel.r and pixel.g>1.6*pixel.b do greens+=1
            if pixel.r>200 and pixel.g>200 and pixel.b>200 do whites+=1
            total+=1
        )
    )
    #(reds,greens,whites,total,image.width,image.height)
)
fn QRetainedCapture label = (
    completeRedraw();QSettle 100
    local image=gw.getViewportDib(),counts=QRetainedImageCounts image
    image.filename=MCPFixtureDir+label+".png";save image;close image
    counts
)
fn QRetainedMapCapture map label data:false = (
    local image
    if data then (
        image=bitmap 128 128 hdr:true gamma:1.0 colorSpace:ColorPipelineMgr.DataColorSpace
        renderMap map into:image filter:false
    ) else image=renderMap map size:[128,128]
    local counts=QRetainedImageCounts image
    image.filename=MCPFixtureDir+label+".png"
    if data then save image gamma:1.0 outputColorConversion:#noConversion else save image
    close image
    counts
)
fn QRetainedLeafMask = (
    -- Opacity is data. The owned host may use an ACES display-view transform
    -- for automatic PNG output, which would turn authored white into gray.
    -- Keep both the saved data and the input renderMap oracle unconverted.
    local dataSpace=ColorPipelineMgr.DataColorSpace
    QRequire (dataSpace!="") "Owned host has no data color space"
    local path=MCPFixtureDir+"canonical-leaf-mask-rgb.png",image=bitmap 128 128 color:black gamma:1.0 colorSpace:dataSpace filename:path
    for y=0 to 127 do (
        local row=for x=0 to 127 collect (
            local u=(x-63.5)/50.0,v=(y-63.5)/60.0
            if (abs u)+v*v<=1.0 then white else black
        )
        setPixels image [0,y] row
    )
    QRequire (save image gamma:1.0 outputColorConversion:#noConversion) "Could not save the binary leaf data mask"
    close image
    local input=openBitmap path colorSpace:dataSpace gamma:1.0
    QRequire (input!=undefined) "Could not reload the binary leaf data mask"
    local inputCounts=QRetainedImageCounts input
    QRequire (inputCounts[3]==7984 and inputCounts[4]==16384) "Saved mask lost its exact binary white population"
    local map=bitmapTexture name:"Q binary leaf opacity" bitmap:input
    map.monoOutput=0;map.rgbOutput=0;map.alphaSource=2;map.preMultAlpha=true;map.filtering=2
    map.coords.mapChannel=1
    QRetainedLog "M11 explicit RGB mask" #(path,dataSpace,input.colorSpace,input.colorSpaceStatus,inputCounts,map.monoOutput,map.rgbOutput,map.alphaSource,map.preMultAlpha,map.filtering)
    map
)
fn QRetainedProductDraw = (
    CyrusPointSuspended=false
    QRoot.refreshDisplay();CyrusViewportRedraw()
    local owner=CyrusPointOwner QNode
    QRequire (isValidNode owner) "No product retained viewport owner"
    local record=undefined
    for entry in CyrusViewportRecords where entry[1]==QNode do record=entry
    QRequire (record!=undefined and record[3].count>0) "Product did not publish a retained cache"
    QRetainedWait owner record[3] record[4]
    #(owner,cyrusRetainedStats owner,cyrusRetainedPresentationStats owner,cyrusRetainedViewportStats owner,cyrusRetainedStreamStats())
)
fn QRetainedLog label values = (
    local output=openFile (MCPFixtureDir+"retained-regression-evidence.txt") mode:"a"
    format "%: %\n" label values to:output;close output
)

case QScenarioID of (
    "R7-M10": (
        QRequire (matchPattern MCPFixtureDir pattern:"*/build/*") "Owned test profile required"
        resetMaxFile #noPrompt
        CyrusPerfHeadless=true;CyrusPointSuspended=true;cyrusSetViewportMemoryLimit 0
        QRequire (not isSceneRedrawDisabled()) "Owned host redraw must be enabled before the scenario"
        QRequire (cyrusRetainedAvailable()) "Nitrous retained drawing is unavailable"
        hideByCategory.helpers=false
        viewport.setLayout #layout_1;viewport.setType #view_top;viewport.SetRenderLevel #smoothhighlights
        viewport.ZoomToBounds false [-35,-35,-5] [35,35,5]
        local controller=box name:"Q direct Point Cloud controller" width:0.1 length:0.1 height:0.1 pos:[-32,-32,-4]
        local owner=cyrusRetainedCreate(),first=QRetainedPointCache 3,styles=#(#(false,white))
        local drawBefore=(cyrusRetainedStats owner)[8],fallbackBefore=cyrusPreviewFallbackStats()
        QRequire (cyrusRetainedPublish owner controller #(first) styles) "Initial Point Cloud admission failed"
        local initial=QRetainedWait owner #(first) styles,before=cyrusRetainedStats owner
        completeRedraw();QSettle 100
        local drawn=cyrusRetainedStats owner,plan=cyrusRetainedViewportStats owner
        QRetainedLog "M10 initial" #(drawn,initial,plan,cyrusRetainedStreamStats())
        QAssert (initial[1]==1 and initial[4]==2 and initial[5] and initial[6]==3 and initial[7]==3 and initial[2]==initial[3] and drawn[1]==3 and plan[2]==3 and drawn[8]>drawBefore and (cyrusPreviewFallbackStats())[2]==fallbackBefore[2]) "R7-M10-01" "Three Point Cloud groups become one complete visible generation and execute actual retained draws without CPU fallback"

        before=cyrusRetainedStats owner
        local cameraTM=viewport.getTM()
        for i=1 to 6 do (
            local moved=copy cameraTM;moved.row4.x+=i*0.1;viewport.setTM moved
            QRequire (cyrusRetainedPublish owner controller #(first) styles) "Warm Point Cloud reuse failed"
            completeRedraw();QSettle 50
        )
        viewport.setTM cameraTM;completeRedraw();QSettle 50
        local after=cyrusRetainedStats owner
        QAssert (after[3]==before[3] and after[4]==before[4] and after[6]==before[6] and after[7]==before[7] and after[8]>before[8] and after[13]==before[13]) "R7-M10-02" "Warm camera movement and identical inputs draw existing Point Cloud buffers without preparation, publication or upload"

        local excessive=QRetainedPointCache 1025,oldPresentation=cyrusRetainedPresentationStats owner
        before=cyrusRetainedStats owner
        local admitted=cyrusRetainedPublish owner controller #(excessive) styles
        after=cyrusRetainedStats owner
        local rejected=cyrusRetainedPresentationStats owner,sameComplete=true
        for index in #(1,2,3,10,11,12,13) where after[index]!=before[index] do sameComplete=false
        QRetainedLog "M10 rejected preparation" #(admitted,before,after,oldPresentation,rejected)
        QAssert (not admitted and sameComplete and after[9]==before[9]+1 and rejected[2]==oldPresentation[2] and rejected[3]==oldPresentation[3] and rejected[4]==2 and rejected[5] and rejected[13]==oldPresentation[13]) "R7-M10-03" "Bounded 1025-group preparation rejection preserves the preceding complete visible bundle and both publication tickets"
        QRequire (cyrusRetainedMatches owner #(first) styles) "Failed preparation lost the visible Point Cloud"
        completeRedraw();QSettle 100;after=cyrusRetainedStats owner
        QAssert (after[6]==before[6] and after[7]==before[7] and after[8]>before[8] and (cyrusRetainedPresentationStats owner)[5]) "R7-M10-04" "The previous Point Cloud still draws after rejection without re-uploading its retained buffers"
        QRetainedCapture "point-cloud-after-rejected-preparation"

        local replacement=QRetainedPointCache 4
        QRequire (cyrusRetainedPublish owner controller #(replacement) styles) "Point Cloud recovery admission failed"
        local recovered=QRetainedWait owner #(replacement) styles
        after=cyrusRetainedStats owner
        QAssert (after[1]==4 and after[3]==before[3]+1 and recovered[2]==recovered[3] and recovered[4]==2 and recovered[5] and recovered[11]==0) "R7-M10-05" "A valid successor recovers with exactly one new complete Point Cloud publication"

        local sibling=QRetainedPointCache 1,twoStyles=#(styles[1],styles[1])
        QRequire (cyrusRetainedPublish owner controller #(replacement,sibling) twoStyles) "Two-layer Point Cloud admission failed"
        QRetainedWait owner #(replacement,sibling) twoStyles
        before=cyrusRetainedStats owner
        local streamBefore=cyrusRetainedStreamStats(),changed=QRetainedPointCache 2
        QRequire (cyrusRetainedPublish owner controller #(changed,sibling) twoStyles) "Changed-layer Point Cloud admission failed"
        QRetainedWait owner #(changed,sibling) twoStyles
        after=cyrusRetainedStats owner
        local streamAfter=cyrusRetainedStreamStats()
        QRetainedLog "M10 changed sibling" #(before,after,streamBefore,streamAfter)
        QAssert (after[1]==3 and after[6]-before[6]==4 and streamAfter[6]>streamBefore[6]) "R7-M10-06" "Only positions and owners for the two changed point groups upload; the unchanged sibling reuses its buffers"

        before=after
        QRequire (cyrusRetainedPublish owner controller #(changed,sibling) twoStyles) "Identical two-layer reuse failed"
        select controller;completeRedraw();clearSelection();completeRedraw();QSettle 100
        after=cyrusRetainedStats owner
        QAssert (after[3]==before[3] and after[4]==before[4] and after[6]==before[6] and after[7]==before[7] and after[8]>before[8] and (cyrusRetainedMatches owner #(changed,sibling) twoStyles) and not isSceneRedrawDisabled()) "R7-M10-07" "Identical multi-layer publication and selection reuse the complete Point Cloud without new uploads or preparation"
        QRetainedCapture "point-cloud-final"
    )
    "R7-M11": (
        QSetup();cyrusSetViewportMemoryLimit 0
        hideByCategory.helpers=false
        viewport.setLayout #layout_1;viewport.setType #view_top;viewport.SetRenderLevel #smoothhighlights
        local card=plane name:"Q canonical leaf card" width:80 length:80 widthsegs:1 lengthsegs:1 mapCoords:true pos:[1500,0,0]
        convertToMesh card
        local colorMap=checker name:"Q canonical leaf color" color1:(color 255 0 0) color2:(color 255 0 0)
        colorMap.coords.mapChannel=1
        local material=standardMaterial name:"Q self illuminated leaf" diffuse:white selfIllumAmount:100 opacity:100 twoSided:true
        material.diffuseMap=colorMap;material.diffuseMapEnable=true
        card.material=material
        QLayer.replacePointSource 1 card;QLayer.amount=1
        hide QModel;hide card
        QRoot.identificationMode=4;QRoot.setGroupDisplay 3
        QCalculate();hide QSurface;clearSelection()
        local row=(QRows())[1],center=row[1].row4
        viewport.ZoomToBounds false (center+[-60,-60,-5]) (center+[60,60,5])
        local state=QRetainedProductDraw(),owner=state[1],fingerprint=QFingerprint(),epoch=QRoot.procEpoch,builds=QRoot.groupBuilds
        local materialKey=cyrusMaterialPreviewKey #(card),redInput=QRetainedMapCapture colorMap "canonical-red-input",redPixels=QRetainedCapture "canonical-red-opaque"
        QRetainedLog "M11 red" #(materialKey,state,redInput,redPixels,cyrusMaterialPreviewStatus QLayer.cachedPoints)
        QAssert (QLayer.previewError=="" and CyrusPointLastError=="" and state[3][4]==2 and state[3][5] and state[4][6]==2 and state[4][8]==0 and redInput[1]>0.95*redInput[4] and redPixels[1]>100 and redPixels[1]>4*redPixels[2]) "R7-M11-01" "The mapped self-illuminated red card is a complete two-triangle Mesh and actual viewport pixels agree with the red input-map oracle"

        local redGeometry=state[5][2],redTransforms=state[5][3],bakes=(cyrusMaterialPreviewStats())[2]
        -- A pending Manual population edit must not leak through display work.
        QLayer.amount=7
        colorMap.color1=color 0 255 0;colorMap.color2=color 0 255 0
        state=QRetainedProductDraw()
        local greenKey=cyrusMaterialPreviewKey #(card),greenInput=QRetainedMapCapture colorMap "canonical-green-input",greenPixels=QRetainedCapture "canonical-green-opaque"
        QRetainedLog "M11 green" #(greenKey,state,greenInput,greenPixels,cyrusMaterialPreviewStats())
        QAssert (greenKey!=materialKey and (cyrusMaterialPreviewStats())[2]>bakes and greenInput[2]>0.95*greenInput[4] and greenPixels[2]>100 and greenPixels[2]>4*greenPixels[1] and greenPixels[2]>0.75*redPixels[1] and greenPixels[2]<1.25*redPixels[1]) "R7-M11-02" "A consumed red-to-green map edit invalidates appearance and changes actual complete-Mesh viewport color with stable visible coverage"
        QAssert (QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and QRoot.groupSnapshotRows[1].count==1 and QLayer.amount==7 and state[5][2]==redGeometry and state[5][3]==redTransforms) "R7-M11-03" "Material refresh reuses geometry and transform streams while preserving exact placements and the pending Manual Count"

        local opacityMap=QRetainedLeafMask()
        material.opacityMap=opacityMap;material.opacityMapEnable=true;material.opacityMapAmount=100
        QRetainedLog "M11 opacity material and UVs" #(material.opacity,material.opacityMapEnable,material.opacityMapAmount,(for i=1 to meshop.getNumMapVerts card 1 collect meshop.getMapVert card 1 i))
        local maskInput=QRetainedMapCapture opacityMap "canonical-opacity-input" data:true,maskFraction=maskInput[3]/(maskInput[4] as float)
        state=QRetainedProductDraw()
        local cutoutKey=cyrusMaterialPreviewKey #(card),cutoutPixels=QRetainedCapture "canonical-green-leaf-cutout",visibleFraction=cutoutPixels[2]/(greenPixels[2] as float)
        QRetainedLog "M11 leaf cutout" #(cutoutKey,state,maskInput,maskFraction,cutoutPixels,visibleFraction,cyrusMaterialPreviewStatus QLayer.cachedPoints)
        QAssert (cutoutKey!=greenKey and state[3][4]==2 and state[3][5] and state[4][6]==2 and state[4][8]==0 and maskFraction>0.35 and maskFraction<0.65 and visibleFraction>0.25 and visibleFraction<0.75 and abs(visibleFraction-maskFraction)<0.15) "R7-M11-04" "Actual green Mesh coverage follows the binary leaf opacity input within a bounded pixel tolerance; the input renderMap is an oracle, not a GPU-atlas readback"
        QAssert (QLayer.previewError=="" and CyrusPointLastError=="" and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and QLayer.amount==7 and state[5][2]==redGeometry and state[5][3]==redTransforms) "R7-M11-05" "Opacity refresh preserves the complete placement result, pending Manual Count, geometry and transforms"

        local before=state[2],beforePresentation=state[3]
        for i=1 to 6 do (completeRedraw();QSettle 50)
        state=QRetainedProductDraw()
        QAssert (state[2][3]==before[3] and state[2][4]==before[4] and state[2][6]==before[6] and state[2][7]==before[7] and state[2][8]>before[8] and state[3][3]==beforePresentation[3] and state[3][5] and QFingerprint()==fingerprint and QRoot.procEpoch==epoch) "R7-M11-06" "Warm textured-cutout Mesh draws retain the complete visible generation without new publication, preparation or upload"
        QRetainedLog "M11 final" #(state,QFingerprint(),QRoot.procEpoch,QLayer.amount)
    )
    default: throw "Unknown retained regression scenario"
)
