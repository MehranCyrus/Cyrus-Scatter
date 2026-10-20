global CyrusPrepareNative,CyrusPrepareGeometry,CyrusPrepareMaterials,CyrusPrepareJsonString,CyrusPrepareJsonNumber,CyrusPrepareTranslate,CyrusPrepareControllerCounts,CyrusPrepareExportSelection,CyrusPrepareExportCleanup
fn CyrusPrepareControllerCounts node = (
    local pending=#(node.transform.controller),seen=#(),counts=#()
    while pending.count>0 do (
        local controller=pending[pending.count];deleteItem pending pending.count
        if controller!=undefined and findItem seen controller==0 do (
            append seen controller;append counts (numKeys controller)
            if seen.count>10000 do throw "Transform controller graph exceeds preparation bound."
            if controller.numSubs>10000 do throw "Transform controller children exceed preparation bound."
            for i=1 to controller.numSubs do (
                local track=getSubAnim controller i
                if track.controller!=undefined do append pending track.controller
            )
        )
    )
    counts
)
fn CyrusPrepareTranslate directory delta metres = (
    local roots=(for n in objects where n.parent==undefined collect n)
    local animated=(for n in roots where n.transform.isAnimated collect n)
    local matrices=(for n in roots collect n.transform),keys=(for n in roots collect CyrusPrepareControllerCounts n)
    local firstTick=animationRange.start as integer,lastTick=animationRange.end as integer,stepTick=amax 1 ((ticksPerFrame as float)/2 as integer),times=#()
    if animated.count>0 do (
        local sampleCount=(ceil ((lastTick-firstTick) as double/stepTick) as integer)+1
        if sampleCount*animated.count>20000 do throw "Recentering exceeds 20,000 animated validation poses; use zero translation or a bounded prepared animation range."
        for tick=firstTick to lastTick by stepTick do append times tick
        appendIfUnique times lastTick
    )
    local references=(for tick in times collect (at time (tick as time / ticksPerFrame) (for n in animated collect n.transform)))
    local origin=dummy name:(uniqueName "CyrusPreparationOrigin")
    with animate off (
        origin.transform=matrix3 1
        for n in roots do n.parent=origin
        origin.pos=delta
    )
    local positionError=0.0,basisError=0.0
    for i=1 to roots.count do (
        local actual=roots[i].transform,expected=matrices[i]
        expected.row4+=delta
        positionError=amax positionError ((distance actual.row4 expected.row4)*metres)
        for row=1 to 3 do basisError=amax basisError (distance actual[row] expected[row])
        local afterKeys=CyrusPrepareControllerCounts roots[i]
        if afterKeys.count!=keys[i].count do throw "Recentering changed source controller structure."
        for k=1 to afterKeys.count where afterKeys[k]!=keys[i][k] do throw "Recentering changed source controller key counts."
    )
    for t=1 to times.count do at time (times[t] as time / ticksPerFrame) (
        for i=1 to animated.count do (
            local actual=animated[i].transform,expected=references[t][i]
            expected.row4+=delta
            positionError=amax positionError ((distance actual.row4 expected.row4)*metres)
            for row=1 to 3 do basisError=amax basisError (distance actual[row] expected[row])
        )
    )
    local audit=createFile (directory+"coordinate-audit.json") encoding:#utf8 writeBOM:false
    format "{\"method\":\"Static identity parent; original controllers retained\",\"sourceRoots\":%,\"animatedRoots\":%,\"animatedValidationPoses\":%,\"startTick\":%,\"endTick\":%,\"stepTick\":%,\"maximumPositionErrorMetres\":%,\"maximumBasisError\":%,\"keyCountsRetained\":true}" roots.count animated.count (times.count*animated.count) firstTick lastTick stepTick (CyrusPrepareJsonNumber positionError) (CyrusPrepareJsonNumber basisError) to:audit;close audit
    if positionError>0.0001 or basisError>0.00001 do throw "Recentering changes source animated poses beyond tolerance; inspect coordinate-audit.json. No final output is published."
    origin
)
fn CyrusPrepareNative config = (
    if (maxVersion())[1]!=29000 or MCPFixtureDir==undefined or not matchPattern MCPFixtureDir pattern:"*max-camera-2027-*" do throw "Owned Max 2027 host required."
    local input=config[1],sourceDirectory=config[2],directory=config[3],destination=config[4]
    if not doesFileExist input or not doesDirectoryExist directory or doesFileExist (directory+"native-complete.json") do throw "Invalid or previously completed staging directory."
    local loadStart=timestamp()
    if not loadMaxFile input useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg do throw "Source copy failed to load."
    sliderTime=config[5]
    mapPaths.add sourceDirectory
    local scale=1.0/(units.decodeValue "1m"),translation=config[6],delta=[translation.x,-translation.z,translation.y]/scale
    local loadMs=timestamp()-loadStart,nodes=objects as array
    if nodes.count>100000 do throw "Preparation exceeds 100,000 scene objects."
    local inventory=createFile (directory+"source-nodes.jsonl") encoding:#utf8 writeBOM:false
    for n in nodes do (
        local modifiers=#()
        if isProperty n #modifiers do for m in n.modifiers do append modifiers ((classOf m) as string)
        format "{\"handle\":%,\"name\":%,\"class\":%,\"parentHandle\":%,\"layer\":%,\"animatedTransform\":%,\"modifiers\":[" n.handle (CyrusPrepareJsonString n.name) (CyrusPrepareJsonString ((classOf n) as string)) (if n.parent==undefined then "null" else n.parent.handle as string) (CyrusPrepareJsonString n.layer.name) (if n.transform.isAnimated then "true" else "false") to:inventory
        for i=1 to modifiers.count do (if i>1 do format "," to:inventory;format "%" (CyrusPrepareJsonString modifiers[i]) to:inventory)
        format "]}\n" to:inventory
    )
    close inventory
    -- Inspect reachable material/map graphs rather than the loader's missing-file list.
    local materials=#(),maps=#(),materialStack=(for n in geometry where n.material!=undefined collect n.material)
    while materialStack.count>0 do (
        local m=materialStack[materialStack.count];deleteItem materialStack materialStack.count
        if findItem materials m==0 do (
            append materials m
            if materials.count>10000 do throw "Material graph exceeds preparation bound."
            for i=1 to getNumSubMtls m where getSubMtl m i!=undefined do append materialStack (getSubMtl m i)
            for i=1 to getNumSubTexmaps m where getSubTexmap m i!=undefined do append maps (getSubTexmap m i)
        )
    )
    local seenMaps=#(),dependencies=createFile (directory+"source-dependencies.jsonl") encoding:#utf8 writeBOM:false
    while maps.count>0 do (
        local m=maps[maps.count];deleteItem maps maps.count
        if findItem seenMaps m==0 do (
            append seenMaps m
            if seenMaps.count>10000 do throw "Map graph exceeds preparation bound."
            if isProperty m #filename do (
                local name=m.filename
                if name!=undefined and name!="" do (
                    local resolved=if doesFileExist name then name else pathConfig.appendPath sourceDirectory name
                    format "{\"mapName\":%,\"class\":%,\"filename\":%,\"resolved\":%,\"exists\":%}\n" (CyrusPrepareJsonString m.name) (CyrusPrepareJsonString ((classOf m) as string)) (CyrusPrepareJsonString name) (CyrusPrepareJsonString resolved) (if doesFileExist resolved then "true" else "false") to:dependencies
                    if doesFileExist resolved do m.filename=resolved
                )
            )
            for i=1 to getNumSubTexmaps m where getSubTexmap m i!=undefined do append maps (getSubTexmap m i)
        )
    )
    for n in geometry where isProperty n #filename do (
        local name=n.filename
        if name!=undefined and name!="" do format "{\"nodeName\":%,\"class\":%,\"filename\":%,\"exists\":%}\n" (CyrusPrepareJsonString n.name) (CyrusPrepareJsonString ((classOf n) as string)) (CyrusPrepareJsonString name) (if doesFileExist name then "true" else "false") to:dependencies
    )
    close dependencies
    if length delta>0 do CyrusPrepareTranslate directory delta scale
    local geometryResult=CyrusPrepareGeometry directory config[7] config[8] config[9]
    CyrusPrepareMaterials directory config[10] config[11]
    sliderTime=config[5]
    local allGeometry=geometry as array,exported=(for n in geometry where n.renderable and not n.isHidden collect n),names=(for n in geometry collect n.name)
    local sidecar=createFile (directory+"export-nodes.json") encoding:#utf8 writeBOM:false
    format "[" to:sidecar
    for i=1 to allGeometry.count do (
        local n=allGeometry[i],related=#(),owner=n.handle
        InstanceMgr.GetInstances n &related
        for other in related where areNodesInstances n other do owner=amin owner other.handle
        local tm=n.objectTransform,values=#()
        for row=1 to 4 do (append values (tm[row].x*scale);append values (tm[row].z*scale);append values (-tm[row].y*scale);append values (if row==4 then 1 else 0))
        local name="CyrusPreparedNode_"+(n.handle as string)
        if i>1 do format "," to:sidecar
        local evaluated=snapshotAsMesh n,faces=if evaluated==undefined then 0 else evaluated.numfaces;evaluated=undefined
        format "{\"exportName\":%,\"handle\":%,\"name\":%,\"layer\":%,\"parentHandle\":%,\"instanceOwner\":%,\"exportIncluded\":%,\"evaluatedTriangles\":%,\"objectMatrix\":[" (CyrusPrepareJsonString name) n.handle (CyrusPrepareJsonString n.name) (CyrusPrepareJsonString n.layer.name) (if n.parent==undefined then "null" else n.parent.handle as string) owner (if n.renderable and not n.isHidden then "true" else "false") faces to:sidecar
        for k=1 to values.count do (if k>1 do format "," to:sidecar;format "%" (CyrusPrepareJsonNumber values[k]) to:sidecar)
        format "]}" to:sidecar;n.name=name
    )
    format "]" to:sidecar;close sidecar
    local exportStart=timestamp(),okay=false,exportScope=undefined,exportClones=0
    try (
        exportScope=CyrusPrepareExportSelection exported directory
        exportClones=exportScope[2].count;select exportScope[1]
        GLTF_Export.fromJsonStr "{\"ShellMaterialUseBakedMtl\":true}"
        okay=exportFile (directory+"native.glb") #noPrompt selectedOnly:true using:GLTF_Export
        CyrusPrepareExportCleanup exportScope[2] exportScope[3];exportScope=undefined
    ) catch (
        if exportScope!=undefined do CyrusPrepareExportCleanup exportScope[2] exportScope[3]
        for i=1 to allGeometry.count do allGeometry[i].name=names[i]
        clearSelection();throw()
    )
    local exportMs=timestamp()-exportStart
    for i=1 to allGeometry.count do allGeometry[i].name=names[i]
    clearSelection()
    if not okay do throw "Native GLB export failed."
    -- Copy referenced bitmap assets, then save paths for the final published directory.
    local bitmapMaps=getClassInstances BitmapTexture,textureLog=createFile (directory+"prepared-textures.jsonl") encoding:#utf8 writeBOM:false
    for i=1 to bitmapMaps.count do (
        local m=bitmapMaps[i],filename=m.filename
        if filename!="" and doesFileExist filename do (
            local relative="textures/asset-"+(i as string)+(getFilenameType filename),copyPath=directory+relative
            if not copyFile filename copyPath do throw ("Texture copy failed: "+filename)
            m.filename=destination+relative
            format "{\"source\":%,\"path\":%}\n" (CyrusPrepareJsonString filename) (CyrusPrepareJsonString relative) to:textureLog
        )
    )
    close textureLog
    if not saveMaxFile (directory+"prepared.max") quiet:true do throw "Prepared scene save failed."
    local summary=createFile (directory+"native-complete.json") encoding:#utf8 writeBOM:false
    format "{\"maxVersion\":%,\"bakeFrame\":%,\"systemType\":%,\"systemScale\":%,\"unitsPerMetre\":%,\"canonicalTranslationMetres\":[%,%,%],\"sourceObjects\":%,\"sourceMaterials\":%,\"sourceMaps\":%,\"selectedGeometryPlacements\":%,\"temporaryExportClones\":%,\"loadMs\":%,\"nativeExportMs\":%}" (CyrusPrepareJsonString ((maxVersion()) as string)) config[5] (CyrusPrepareJsonString (units.SystemType as string)) (CyrusPrepareJsonNumber units.SystemScale) (CyrusPrepareJsonNumber (1.0/scale)) (CyrusPrepareJsonNumber translation.x) (CyrusPrepareJsonNumber translation.y) (CyrusPrepareJsonNumber translation.z) nodes.count materials.count seenMaps.count exported.count exportClones loadMs exportMs to:summary;close summary
    true
)
