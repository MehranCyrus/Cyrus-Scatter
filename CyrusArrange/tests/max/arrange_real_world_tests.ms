/* User-supplied prepared models. Disposable private Max 2027.1+ only.
   All source/library files stay immutable. This script resets its OWN test scene. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI,caRWInputSpecs
global CA_REAL_WORLD_RENDER
if CA_REAL_WORLD_RENDER==undefined do CA_REAL_WORLD_RENDER=false
global caCreateSetup,caSetArrangeSettings,caSetupSummary,caRegisterAssets,caAssetRows,caAssetDetail,caUpdateAsset
global caCategoryRules,caSetCategoryRules,caSetCollisionScope,caAnalyzeSetup,caRegionRows,caSetRegionRules
global caGenerate,caGenerateVariation,caOutputRows,caCompositionRows,caShowArrangeUI,caHomeUI,caTick
global caInspect,caRegion
global caRWStageScene,caRWRenderScene
global caRWPasses=0,caRWFailures=0,caRWFinished=false,caRWContext="entry",caRWLog=#(),caRWChecks=#()
global caRWSources=#(),caRWDependencies=#(),caRWFixtures=#(),caRWRenders=#(),caRWScene="CyrusArrange-Real-Models.max"
global caRWWrite,caRWNote,caRWCheck,caRWRequire,caRWNum,caRWQuote,caRWJ,caRWRawArray,caRWObject,caRWReport
global caRWHash,caRWMesh,caRWBounds,caRWSize,caRWNear,caRWGeometry,caRWFind,caRWLeaf,caRWMaterialTree
global caRWUnmappedShader,caRWNodeOrder,caRWSourceState,caRWMapState,caRWPrepareInputs,caRWMerge,caRWPlaceSource,caRWRegister,caRWSetup
global caRWArea,caRWClipAxis,caRWClipBox,caRWCross2,caRWClipEdge,caRWClipTriangle,caRWTop
global caRWTriangleBox,caRWCoverage,caRWDistanceBoxes,caRWPhysical,caRWVisual,caRWCapture,caRWSame
global caRWSquareCoverage,caRWCornerRegression,caRWDensityForFive,caRWSelectArtistSeed,caRWSourceJSON,caRWFixtureJSON,caRWOutputJSON,caRWExportGeometry,caRWRun
global caRWBaseTurn,caRWBaseXYOrder,caRWBaseHull,caRWBaseDescriptor,caRWDClipConvexTriangle,caRWDHullClearance,caRWBaseCoverage

fn caRWNum value =
(
    local t=if (classOf value)==Integer64 or (classOf value)==Integer then value as string else formattedPrint value format:".17g"
    if t.count>0 and (t[t.count]=="L" or t[t.count]=="l") do t=substring t 1 (t.count-1)
    t
)
fn caRWQuote value =
(
    local s=value as string
    s=substituteString s "\\" "\\\\";s=substituteString s "\"" "\\\""
    s=substituteString s "\n" "\\n";s=substituteString s "\r" "\\r";s=substituteString s "\t" "\\t"
    "\""+s+"\""
)
fn caRWRawArray values =
(
    local text="["
    for i=1 to values.count do (if i>1 do text+=",";text+=values[i])
    text+"]"
)
fn caRWJ value =
(
    case(classOf value)of
    (
        UndefinedClass:"null"
        String:(caRWQuote value)
        BooleanClass:(if value then"true"else"false")
        Point3:("["+caRWNum value.x+","+caRWNum value.y+","+caRWNum value.z+"]")
        Array:(local parts=for x in value collect(caRWJ x);caRWRawArray parts)
        default:(caRWNum value)
    )
)
fn caRWObject pairs =
(
    local parts=for p in pairs collect((caRWQuote p[1])+":"+p[2])
    "{"+(substring (caRWRawArray parts) 2 ((caRWRawArray parts).count-2))+"}"
)
fn caRWWrite =
(
    local f=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caRWFinished then(if caRWFailures==0 then"SUCCESS"else"ERROR")else"RUNNING") caRWPasses caRWFailures to:f
    for x in caRWLog do format "%\n" x to:f
    close f
)
fn caRWNote line=(append caRWLog line;caRWWrite();true)
fn caRWCheck label value details:"" =
(
    append caRWChecks #(label,value,details)
    if value then(caRWPasses+=1;caRWNote("PASS "+label))else(caRWFailures+=1;caRWNote("FAIL "+label+" ["+caRWContext+"] "+details))
    value
)
fn caRWRequire label value details:""=(caRWCheck label value details:details;if not value do throw("Real-world fixture prerequisite: "+label);true)
fn caRWHash path =
(
    local stream=undefined,algorithm=undefined,result=undefined
    try
    (
        stream=(dotNetClass "System.IO.File").OpenRead path
        algorithm=(dotNetClass "System.Security.Cryptography.SHA256").Create()
        result=toLower(substituteString((dotNetClass "System.BitConverter").ToString(algorithm.ComputeHash stream))"-" "")
        stream.Close();algorithm.Dispose();result
    )
    catch(if stream!=undefined do try(stream.Close())catch();if algorithm!=undefined do try(algorithm.Dispose())catch();throw())
)
fn caRWMesh node =
(
    -- WORLD snapshots already evaluate ObjectTM/WSM; never apply another TM.
    -- Group geometry is concatenated from actual leaves, never a helper box.
    if isGroupHead node then
    (
        local allVertices=#(),allFaces=#(),vertexBase=0
        for partNode in(caRWGeometry node)do
        (
            local partMesh=caRWMesh partNode
            if allVertices.count+partMesh.numverts>250000 or allFaces.count+partMesh.numfaces>250000 do throw "Group snapshot exceeds fixture admission."
            for i=1 to partMesh.numverts do append allVertices(getVert partMesh i)
            for i=1 to partMesh.numfaces do append allFaces((getFace partMesh i)+[vertexBase,vertexBase,vertexBase])
            vertexBase+=partMesh.numverts
            delete partMesh
        )
        if allVertices.count<3 or allFaces.count<1 do throw "Complete group has no evaluated geometry."
        mesh vertices:allVertices faces:allFaces
    )
    else
    (
        local result=undefined
        in coordsys world(result=snapshotAsMesh node renderMesh:false)
        if result==undefined or result.numverts<3 or result.numfaces<1 or result.numverts>250000 or result.numfaces>250000 do throw "Evaluated mesh missing or exceeds fixture admission."
        result
    )
)
fn caRWBounds meshValue =
(
    local low=[1e20,1e20,1e20],high=[-1e20,-1e20,-1e20]
    for i=1 to meshValue.numverts do
    (
        local p=getVert meshValue i
        for k=1 to 3 do(low[k]=amin #(low[k],p[k]);high[k]=amax #(high[k],p[k]))
    )
    #(low,high)
)
fn caRWSize bounds=(bounds[2]-bounds[1])
fn caRWNear a b tolerance:0.03=(distance a b)<=tolerance
fn caRWNodeOrder a b =
(
    local firstHandle=a.inode.handle,secondHandle=b.inode.handle
    if firstHandle<secondHandle then -1 else if firstHandle>secondHandle then 1 else 0
)
fn caRWGeometry root =
(
    local result=#()
    if isGroupHead root then(for child in root.children do join result(caRWGeometry child))
    else if(superClassOf root)==GeometryClass do append result root
    -- Native intake publishes the stable node-handle ordering of real leaves.
    -- Per-leaf topology/UV/material checks below retain each original identity.
    qsort result caRWNodeOrder
    result
)
fn caRWFind rows id=(local result=undefined;for row in rows while result==undefined do if row[1]==id do result=row;result)
fn caRWLeaf materialValue id =
(
    if materialValue==undefined then undefined
    else if isProperty materialValue #materialIDList then
    (
        local found=undefined
        for i=1 to materialValue.materialIDList.count where materialValue.materialIDList[i]==id do found=materialValue.materialList[i]
        found
    )
    else materialValue
)
fn caRWMaterialTree root =
(
    local pending=#(root),seen=#(),rows=#(),safe=true
    while pending.count>0 do
    (
        local item=pending[pending.count];deleteItem pending pending.count
        if item!=undefined and findItem seen item==0 do
        (
            if seen.count>=4096 do throw "Assigned material graph exceeds fixture admission."
            append seen item
            local cls=toLower((classOf item)as string)
            if matchPattern cls pattern:"*missing*" or matchPattern cls pattern:"*vray*" or matchPattern cls pattern:"*standin*" do safe=false
            local fileName=if isProperty item #filename then(item.filename as string)else""
            append rows #((classOf item)as string,item.name,fileName)
            if (superClassOf item)==material do for i=1 to(getNumSubMtls item)do append pending(getSubMtl item i)
            for i=1 to(getNumSubTexmaps item)do append pending(getSubTexmap item i)
        )
    )
    #(safe,rows,seen)
)
fn caRWUnmappedShader node =
(
    local materialValue=node.material
    caRWRequire(node.name+" unmapped original uses the inspected CoronaLegacyMtl class")((toLower((classOf materialValue)as string))=="coronalegacymtl")
    local anisotropyProperties=#()
    for propertyName in(getPropNames materialValue)do
    (
        if matchPattern(toLower(propertyName as string))pattern:"*aniso*"do
        (
            local value=try(getProperty materialValue propertyName)catch(undefined)
            if value!=undefined and(isKindOf value MAXWrapper)do value=((classOf value)as string)
            append anisotropyProperties #((propertyName as string),value)
        )
    )
    caRWNote("UNMAPPED_ANISOTROPY "+node.name+" "+caRWJ anisotropyProperties)
    caRWRequire(node.name+" exposes the inspected exact anisotropy property")(isProperty materialValue #anisotropy)
    local amount=getProperty materialValue #anisotropy
    caRWRequire(node.name+" has zero anisotropy before accepting SDK-added mapping faces")(amount==0.0)
    local tree=caRWMaterialTree materialValue,assignedSubmaps=0
    for item in tree[3]do for index=1 to(getNumSubTexmaps item)do
        if(getSubTexmap item index)!=undefined do assignedSubmaps+=1
    caRWRequire(node.name+" has no assigned texture submaps needing absent UV channels")(assignedSubmaps==0)
    local original=caRWMesh node,unsupported=true,supportRows=#()
    for channel=-2 to(meshop.getNumMaps original)-1 do
    (
        local supported=meshop.getMapSupport original channel
        append supportRows #(channel,supported)
        if supported do unsupported=false
    )
    delete original
    caRWNote("UNMAPPED_SOURCE_CHANNELS "+node.name+" "+caRWJ supportRows)
    caRWRequire(node.name+" retains the inspected original unsupported map-channel state")unsupported
    true
)
fn caRWMapState node =
(
    local result=#()
    for partNode in(caRWGeometry node)do append result #(partNode.name,(caRWMaterialTree partNode.material)[2])
    result
)
fn caRWSourceState node =
(
    if isGroupHead node then
    (
        local parts=for partNode in(caRWGeometry node)collect #(partNode.name,(caRWSourceState partNode))
        #((copy node.transform),parts)
    )
    else
    (
        local meshValue=caRWMesh node
        local vertices=for i=1 to meshValue.numverts collect(getVert meshValue i)
        local faces=for i=1 to meshValue.numfaces collect #((getFace meshValue i),(getFaceMatID meshValue i),(getFaceSmoothGroup meshValue i))
        local maps=#(),count=meshop.getNumMaps meshValue
        if count>16 do throw "Source mapping-channel admission exceeded."
        for channel=-2 to count-1 do if meshop.getMapSupport meshValue channel do
        (
            local uv=for i=1 to(meshop.getNumMapVerts meshValue channel)collect(meshop.getMapVert meshValue channel i)
            local mf=for i=1 to(meshop.getNumMapFaces meshValue channel)collect(meshop.getMapFace meshValue channel i)
            append maps #(channel,uv,mf)
        )
        delete meshValue
        #((copy node.transform),vertices,faces,maps,(caRWMapState node),node.material)
    )
)
fn caRWPrepareInputs =
(
    makeDir(CA_TEST_OUTPUT+"maps")
    for input in caRWInputSpecs do
    (
        caRWRequire (input[1]+" prepared model SHA unchanged") ((caRWHash input[2])==input[3])
        caRWRequire (input[1]+" metadata SHA unchanged") ((caRWHash input[4])==input[5])
        for mapRow in input[8] do
        (
            local target=CA_TEST_OUTPUT+"maps/"+mapRow[2]
            if doesFileExist target do throw("Dependency target already exists: "+target)
            caRWRequire ("dependency "+mapRow[2]+" original bytes") ((caRWHash mapRow[1])==mapRow[3])
            if not(copyFile mapRow[1] target)do throw("Cannot copy dependency: "+mapRow[1])
            if caRWHash target!=mapRow[3]do throw("Dependency copy differs: "+mapRow[2])
            append caRWDependencies #(mapRow[1],mapRow[3],"maps/"+mapRow[2],mapRow[3])
        )
    )
)
fn caRWMerge input =
(
    caRWContext="merge "+input[1];caRWNote("STAGE "+caRWContext)
    local merged=#()
    -- Explicit 2027.1 unit rescaling: source centimeters/books millimeters are
    -- converted into the owned millimeter scene; literal physical bounds test it.
    caRWRequire (input[1]+" merge succeeds") (mergeMAXFile input[2] #select #autoRenameDups #renameMtlDups #neverReparent quiet:true mergedNodes:&merged includeFullGroup:true ignoreFileUnits:false)
    local heads=for n in merged where isValidNode n and isGroupHead n collect n
    while heads.count>0 do
    (
        local root=heads[1]
        if isValidNode root and isGroupHead root do ungroup root
        heads=for n in merged where isValidNode n and isGroupHead n collect n
    )
    local kept=#()
    for spec in input[7] do
    (
        local matches=for n in merged where isValidNode n and n.name==spec[1] collect n
        caRWRequire (spec[1]+" uniquely exists in working merge") (matches.count==1)
        local node=matches[1],meshValue=caRWMesh node,bounds=caRWBounds meshValue
        local expectedLow=[spec[2][1][1],spec[2][1][2],spec[2][1][3]],expectedHigh=[spec[2][2][1],spec[2][2][2],spec[2][2][3]]
        caRWRequire (spec[1]+" literal source bounds preserve physical units") (caRWNear bounds[1] expectedLow and caRWNear bounds[2] expectedHigh) details:((bounds as string)+" versus "+(spec[2]as string))
        -- Prepared metadata used getPolygonCount, which reports the source's
        -- polygon representation. snapshotAsMesh is triangulated and need not
        -- have that face count. Exact raw triangle correspondence is checked
        -- against each independently evaluated source and exported below.
        local polygonCounts=getPolygonCount node
        caRWNote("MESH_COUNTS "+spec[1]+" metadataVertices="+caRWNum spec[3]+" metadataPolygons="+caRWNum spec[4]+" actualPolygonVertices="+caRWNum polygonCounts[2]+" actualPolygons="+caRWNum polygonCounts[1]+" snapshotVertices="+caRWNum meshValue.numverts+" snapshotTriangles="+caRWNum meshValue.numfaces)
        caRWRequire (spec[1]+" exact metadata polygon/vertex representation") (polygonCounts[2]==spec[3] and polygonCounts[1]==spec[4])
        delete meshValue
        local tree=caRWMaterialTree node.material
        caRWRequire (spec[1]+" assigned material graph has no Missing/VRay stand-ins") (node.material!=undefined and tree[1])
        if spec[1]=="Decor_Set_01_Part_031" or spec[1]=="Decor_Set_01_Part_032" do caRWUnmappedShader node
        for item in tree[3] do if isProperty item #filename do
        (
            local pathValue=item.filename as string
            if pathValue!="" do
            (
                local name=(getFilenameFile pathValue)+(getFilenameType pathValue),found=undefined
                for mapRow in input[8] while found==undefined do if toLower name==toLower mapRow[2] do found=mapRow
                if found==undefined do throw("Assigned file not covered by immutable input manifest: "+pathValue)
                item.filename="maps/"+found[2]
            )
        )
        append kept node
        append caRWSources #(spec[1],input[1],node,bounds,undefined,undefined,input[6])
    )
    local newGroup=undefined
    if input.count>=9 do
    (
        local groupSpec=input[9]
        caRWRequire "Complete plant retains exactly the three visually verified original parts" (kept.count==3 and groupSpec[2].count==3)
        for wantedName in groupSpec[2]do
        (
            local partMatches=for partNode in kept where partNode.name==wantedName collect partNode
            caRWRequire("Complete plant member retained: "+wantedName)(partMatches.count==1)
        )
        -- Only disposable merged copies are regrouped; leaf WORLD poses stay put.
        local beforeGrouping=for partNode in kept collect #(partNode,(caRWSourceState partNode))
        newGroup=group kept name:groupSpec[1]select:false
        caRWRequire "Original plant parts form one reusable native source group" (isValidNode newGroup and isGroupHead newGroup and(caRWGeometry newGroup).count==3)
        local groupMesh=caRWMesh newGroup,groupBounds=caRWBounds groupMesh
        delete groupMesh
        local wantedLow=[groupSpec[3][1][1],groupSpec[3][1][2],groupSpec[3][1][3]]
        local wantedHigh=[groupSpec[3][2][1],groupSpec[3][2][2],groupSpec[3][2][3]]
        caRWRequire "Complete plant literal full-size bounds include pot and foliage" (caRWNear groupBounds[1]wantedLow and caRWNear groupBounds[2]wantedHigh)
        for beforePart in beforeGrouping do
        (
            local originalState=beforePart[2],currentState=caRWSourceState beforePart[1]
            local unchanged=originalState[2].count==currentState[2].count,maxRegroupDelta=0.0
            if unchanged do for i=1 to originalState[2].count do
            (
                local pointError=distance originalState[2][i]currentState[2][i]
                maxRegroupDelta=amax #(maxRegroupDelta,pointError)
                if pointError>0.03 do unchanged=false
            )
            for field=3 to 6 do if not(deepEqual originalState[field]currentState[field]strictCompare:true)do unchanged=false
            for axis=1 to 3 do if distance originalState[1][axis]currentState[1][axis]>0.000001 do unchanged=false
            if distance originalState[1][4]currentState[1][4]>0.03 do unchanged=false
            caRWRequire(beforePart[1].name+" regroup preserves WORLD vertices, topology, UV and material bindings")unchanged details:("maximumVertexDeltaMM="+caRWNum maxRegroupDelta)
        )
        caRWSources=for sourceRow in caRWSources where sourceRow[2]!=input[1]collect sourceRow
        append caRWSources #(groupSpec[1],input[1],newGroup,groupBounds,undefined,undefined,input[6])
    )
    local discarded=for n in merged where isValidNode n and findItem kept n==0 collect n
    if discarded.count>0 do delete discarded
    if newGroup==undefined then
    (
        local retained=for n in kept where isValidNode n and(not isGroupMember n)and(not isGroupHead n)collect n
        caRWRequire(input[1]+" only selected complete meshes remain")(retained.count==kept.count)
        kept
    )
    else
    (
        caRWRequire "Only the complete three-part plant group remains from decor collection" ((caRWGeometry newGroup).count==kept.count)
        #(newGroup)
    )
)
fn caRWPlaceSource source target name =
(
    local node=source[3],meshValue=caRWMesh node,b=caRWBounds meshValue
    delete meshValue
    local delta=target-[(b[1].x+b[2].x)*0.5,(b[1].y+b[2].y)*0.5,b[1].z]
    node.position+=delta;node.name=name
    local actual=caRWMesh node;source[4]=caRWBounds actual;delete actual
    source[5]=caRWSourceState node
    source[6]=#() -- registrations across independent setups: #(setup,assetID)
    true
)
fn caRWRegister setup source category =
(
    -- Cache the independent original WORLD contact-band reference once per
    -- immutable source; reuse it across setups and all subsequent rows.
    if source.count==7 do
    (
        local envelope=caRWMesh source[3],base=undefined
        try(base=caRWBaseDescriptor envelope source[4])catch(delete envelope;throw())
        delete envelope
        append source base
        local bounds=source[4]
        local bodyCenter=[(bounds[1].x+bounds[2].x)*0.5,(bounds[1].y+bounds[2].y)*0.5,bounds[1].z]
        local contactCenter=[base[1][1],base[1][2],base[1][3]]
        caRWNote("SOURCE_CONTACT_REFERENCE source="+source[1]+" bodyCenterC_MM="+caRWJ bodyCenter+" independentBandCenterB_MM="+caRWJ base[1]+" canonicalBminusC_MM="+caRWJ(contactCenter-bodyCenter)+" referencedBandTriangles="+(base[4]as string)+" bandPoints="+(base[5]as string)+" hullVertices="+(base[2].count as string))
    )
    if source.count!=8 or source[8]==undefined do throw "Independent original contact reference was not cached."
    local result=caRegisterAssets setup #(source[3]) category
    caRWRequire (source[1]+" native intake adds exactly one source") (result.count==2 and result[1].count==1 and result[2].count==0)
    local id=result[1][1],detail=caAssetDetail setup id
    caUpdateAsset setup id source[1] category 31 #(0.0,90.0,180.0,270.0) 1.0 1.0 1.0 false
    detail=caAssetDetail setup id
    caRWCheck (source[1]+" explicit full-size independent asset") (detail[7]==1 and detail[8]==1 and not detail[9] and detail[11]==source[3])
    append source[6] #(setup,id)
    #(id,source)
)
fn caRWArea polygon =
(
    if polygon.count<3 then 0.0 else
    (
        local sum=0.0 as double,origin=polygon[1]
        for i=1 to polygon.count do
        (
            local j=if i==polygon.count then 1 else i+1
            local ax=(polygon[i].x as double)-(origin.x as double),ay=(polygon[i].y as double)-(origin.y as double)
            local termBX=(polygon[j].x as double)-(origin.x as double),termBY=(polygon[j].y as double)-(origin.y as double)
            sum+=ax*termBY-termBX*ay
        )
        abs sum*0.5
    )
)
fn caRWClipAxis polygon axis boundary less =
(
    local out=#()
    if polygon.count>0 do
    (
        local prev=polygon[polygon.count],dp=if less then boundary-prev[axis]else prev[axis]-boundary
        for current in polygon do
        (
            local dc=if less then boundary-current[axis]else current[axis]-boundary
            if (dp>=0)!=(dc>=0) do append out(prev+(current-prev)*(dp/(dp-dc)))
            if dc>=0 do append out current
            prev=current;dp=dc
        )
    )
    out
)
fn caRWClipBox polygon low high =
(
    local p=caRWClipAxis polygon 1 low.x false
    p=caRWClipAxis p 1 high.x true;p=caRWClipAxis p 2 low.y false
    caRWClipAxis p 2 high.y true
)
fn caRWCross2 a b=((a.x as double)*(b.y as double)-(a.y as double)*(b.x as double))
fn caRWClipEdge polygon a b signValue =
(
    local out=#()
    if polygon.count>0 do
    (
        local prev=polygon[polygon.count],dp=signValue*(caRWCross2(b-a)(prev-a))
        for current in polygon do
        (
            local dc=signValue*(caRWCross2(b-a)(current-a))
            if (dp>=0)!=(dc>=0) do append out(prev+(current-prev)*(dp/(dp-dc)))
            if dc>=0 do append out current
            prev=current;dp=dc
        )
    )
    out
)
fn caRWClipTriangle polygon triangle =
(
    local signValue=if(caRWCross2(triangle[2]-triangle[1])(triangle[3]-triangle[1]))>=0 then 1 else -1,p=polygon
    for i=1 to 3 do(local j=if i==3 then 1 else i+1;p=caRWClipEdge p triangle[i] triangle[j] signValue)
    p
)
/* BUILD-ONLY independent physical oracle. No plugin-fit/Clipper imports.
   Snapshot Point3 coordinates are converted once; all later XY operations use
   two-Double arrays, including clipping intersections and boundary distances. */
global caRWXY,caRWDArea,caRWDClipAxis,caRWTopBoundary
global caRWDPointSegmentDistance,caRWDSegmentDistance,caRWDRectangleClearance

fn caRWXY point = #((point.x as double),(point.y as double))
fn caRWDArea polygon =
(
    local result=0.0 as double
    if polygon.count>=3 do
    (
        local origin=polygon[1]
        for index=1 to polygon.count do
        (
            local nextIndex=if index==polygon.count then 1 else index+1
            local a=polygon[index],b=polygon[nextIndex]
            result+=(a[1]-origin[1])*(b[2]-origin[2])-(a[2]-origin[2])*(b[1]-origin[1])
        )
    )
    (abs result)*0.5
)
fn caRWDClipAxis polygon axis boundary less =
(
    local result=#()
    if polygon.count>0 do
    (
        local previous=polygon[polygon.count]
        local previousSide=if less then boundary-previous[axis] else previous[axis]-boundary
        for current in polygon do
        (
            local currentSide=if less then boundary-current[axis] else current[axis]-boundary
            if (previousSide>=0)!=(currentSide>=0) do
            (
                local fraction=previousSide/(previousSide-currentSide)
                append result #(previous[1]+(current[1]-previous[1])*fraction,previous[2]+(current[2]-previous[2])*fraction)
            )
            if currentSide>=0 do append result current
            previous=current;previousSide=currentSide
        )
    )
    result
)
fn caRWTopBoundary top =
(
    if top.count<2 or top.count>400 do throw "Independent support triangle admission exceeded."
    local points=#(),edges=#()
    for triangle in top do
    (
        if triangle.count!=3 do throw "Independent support requires actual triangles."
        local ids=#()
        for point in triangle do
        (
            local xy=caRWXY point,id=0
            -- <=1200 input endpoints; exact equality, never decimal-string keys.
            for index=1 to points.count while id==0 do
                if points[index][1]==xy[1] and points[index][2]==xy[2] do id=index
            if id==0 do (append points xy;id=points.count)
            append ids id
        )
        for index=1 to 3 do
        (
            local nextIndex=if index==3 then 1 else index+1
            local first=ids[index],second=ids[nextIndex]
            if first==second do throw "Projected support edge is collapsed."
            local direction=if first<second then 1 else -1
            local a=amin #(first,second),b=amax #(first,second),found=0
            for edgeIndex=1 to edges.count while found==0 do
                if edges[edgeIndex][1]==a and edges[edgeIndex][2]==b do found=edgeIndex
            if found==0 then append edges #(a,b,1,direction)
            else
            (
                edges[found][3]+=1;edges[found][4]+=direction
                if edges[found][3]>2 do throw "Nonmanifold support edge has more than two triangles."
            )
        )
    )
    if points.count>1200 or edges.count>1200 do throw "Independent support boundary admission exceeded."
    local degrees=for point in points collect 0
    local boundary=#()
    for edge in edges do
    (
        if edge[3]==1 then
        (
            append boundary #(points[edge[1]],points[edge[2]])
            degrees[edge[1]]+=1;degrees[edge[2]]+=1
        )
        else if edge[3]!=2 or edge[4]!=0 do
            throw "Shared support edge does not have two opposite orientations."
    )
    if boundary.count<3 do throw "Independent support has no closed exterior boundary."
    for degree in degrees do if degree!=0 and degree!=2 do
        throw "Independent support boundary is not closed with degree two."
    boundary
)
fn caRWDPointSegmentDistance point a b =
(
    local dx=b[1]-a[1],dy=b[2]-a[2],lengthSquared=dx*dx+dy*dy
    if lengthSquared<=0 do throw "Independent clearance segment is collapsed."
    local fraction=((point[1]-a[1])*dx+(point[2]-a[2])*dy)/lengthSquared
    fraction=amax #((0.0 as double),(amin #((1.0 as double),fraction)))
    local rx=point[1]-(a[1]+fraction*dx),ry=point[2]-(a[2]+fraction*dy)
    sqrt(rx*rx+ry*ry)
)
fn caRWDSegmentDistance a b c d =
(
    local ux=b[1]-a[1],uy=b[2]-a[2],vx=d[1]-c[1],vy=d[2]-c[2]
    local denominator=ux*vy-uy*vx
    if denominator!=0 do
    (
        local cx=c[1]-a[1],cy=c[2]-a[2]
        local first=(cx*vy-cy*vx)/denominator,second=(cx*uy-cy*ux)/denominator
        if first>=0 and first<=1 and second>=0 and second<=1 do return (0.0 as double)
    )
    amin #(caRWDPointSegmentDistance a c d,caRWDPointSegmentDistance b c d,caRWDPointSegmentDistance c a b,caRWDPointSegmentDistance d a b)
)
fn caRWDRectangleClearance boundary low high =
(
    if low[1]>=high[1] or low[2]>=high[2] or boundary.count<3 do throw "Independent clearance requires a positive rectangle and boundary."
    local rectangle=#(low,#(high[1],low[2]),high,#(low[1],high[2])),minimum=1.0e30 as double
    for segment in boundary do
    (
        for endpoint in segment do
            if endpoint[1]>=low[1] and endpoint[1]<=high[1] and endpoint[2]>=low[2] and endpoint[2]<=high[2] do
                return (0.0 as double) -- Also catches a complete hole inside the prop.
        for index=1 to 4 do
        (
            local nextIndex=if index==4 then 1 else index+1
            minimum=amin #(minimum,(caRWDSegmentDistance segment[1] segment[2] rectangle[index] rectangle[nextIndex]))
        )
    )
    minimum
)

/* Replaces the previous square-buffer test. Existing published area allowance
   is retained; existing world-measurement allowance0.03mm applies to distance.
   Result: #(passes,unexpandedArea,coveredArea,minEuclideanMM,requestedMM,allowanceMM). */
fn caRWCoverage top boundary low high edge =
(
    local a=caRWXY low,b=caRWXY high
    if edge<0 or a[1]>=b[1] or a[2]>=b[2] do throw "Independent support footprint or edge setting is invalid."
    local area=(b[1]-a[1])*(b[2]-a[2]),covered=0.0 as double
    for triangle in top do
    (
        local polygon=for point in triangle collect caRWXY point
        polygon=caRWDClipAxis polygon 1 a[1] false
        polygon=caRWDClipAxis polygon 1 b[1] true
        polygon=caRWDClipAxis polygon 2 a[2] false
        polygon=caRWDClipAxis polygon 2 b[2] true
        covered+=caRWDArea polygon
    )
    local minimum=caRWDRectangleClearance boundary a b
    local allowance=0.03 as double,target=edge as double
    local fullSupport=abs(covered-area)<=amax #((0.05 as double),area*0.000001)
    #(fullSupport and minimum>=target-allowance,area,covered,minimum,target,allowance)
)

fn caRWTop node expectedZ =
(
    local meshValue=caRWMesh node,all=#(),top=#()
    for i=1 to meshValue.numfaces do
    (
        local f=getFace meshValue i,a=getVert meshValue(f.x as integer),b=getVert meshValue(f.y as integer),c=getVert meshValue(f.z as integer)
        local n=cross(b-a)(c-a),triangle=#(a,b,c)
        append all triangle
        if n.z>0 and abs(a.z-expectedZ)<=0.02 and abs(b.z-expectedZ)<=0.02 and abs(c.z-expectedZ)<=0.02 and(caRWArea triangle)>1e-5 do append top triangle
    )
    delete meshValue
    caRWRequire (node.name+" has near-horizontal actual top triangles at literal height") (top.count>=2 and top.count<=400)
    local overlaps=false,maxOverlap=0.0
    for i=1 to top.count do for j=i+1 to top.count where j<=top.count do
    (
        local shared=caRWClipTriangle top[i] top[j],area=caRWArea shared
        maxOverlap=amax #(maxOverlap,area)
        if area>0.02 do overlaps=true
    )
    caRWRequire (node.name+" independent top triangulation has no positive-area overlaps") (not overlaps) details:("max intersection mm2="+caRWNum maxOverlap)
    local boundary=caRWTopBoundary top
    caRWNote("SUPPORT_BOUNDARY "+node.name+" topTriangles="+(top.count as string)+" trueBoundarySegments="+(boundary.count as string))
    #(all,top,expectedZ,boundary)
)
fn caRWTriangleBox triangle low high =
(
    local center=(low+high)*0.5,half=(high-low)*0.5-[0.03,0.03,0.03]
    if half.x<=0 or half.y<=0 or half.z<=0 then false else
    (
        local v=#(triangle[1]-center,triangle[2]-center,triangle[3]-center),separated=false
        for axis=1 to 3 do if(amin #(v[1][axis],v[2][axis],v[3][axis]))>half[axis]or(amax #(v[1][axis],v[2][axis],v[3][axis]))< -half[axis]do separated=true
        local edges=#(v[2]-v[1],v[3]-v[2],v[1]-v[3]),axes=#(cross edges[1] edges[2])
        for edge in edges do for unitAxis in #([1,0,0],[0,1,0],[0,0,1])do append axes(cross edge unitAxis)
        for axis in axes while not separated do if(dot axis axis)>1e-14 do
        (
            local p=#(dot v[1] axis,dot v[2] axis,dot v[3] axis),r=half.x*abs axis.x+half.y*abs axis.y+half.z*abs axis.z
            if(amin p)>r or(amax p)< -r do separated=true
        )
        not separated
    )
)
fn caRWDistanceBoxes a b =
(
    local dx=amax #(0.0,a[1].x-b[2].x,b[1].x-a[2].x),dy=amax #(0.0,a[1].y-b[2].y,b[1].y-a[2].y)
    sqrt(dx*dx+dy*dy)
)
/* Independent fixture-only geometry. Expected anchors never read native support.
   Fixed inputs are immutable and checked below; source descriptors cache once.
   Output descriptors use each already captured actual mesh once per row.
   Point3 input coordinates convert to Double before clipping/hull/edge math. */
fn caRWBaseTurn a b c = (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])
fn caRWBaseXYOrder a b =
(
    if a[1]<b[1] then -1 else if a[1]>b[1] then 1 else if a[2]<b[2] then -1 else if a[2]>b[2] then 1 else 0
)
fn caRWBaseHull points =
(
    if points.count<3 or points.count>16384 do throw "Independent contact-band point admission exceeded."
    qsort points caRWBaseXYOrder
    local unique=#()
    for point in points do
        if unique.count==0 or point[1]!=unique[unique.count][1] or point[2]!=unique[unique.count][2] do append unique point
    if unique.count<3 do throw "Independent contact band has no projected polygon."
    local hull=#()
    for pass=1 to 2 do
    (
        local chain=#()
        for index=1 to unique.count do
        (
            local point=if pass==1 then unique[index] else unique[unique.count-index+1]
            while chain.count>=2 and (caRWBaseTurn chain[chain.count-1] chain[chain.count] point)<=0 do deleteItem chain chain.count
            append chain point
        )
        if chain.count>0 do deleteItem chain chain.count
        join hull chain
    )
    if hull.count<3 or hull.count>256 or (caRWDArea hull)<=0.000001 do throw "Independent contact hull has no bounded positive area."
    hull
)
fn caRWBaseDescriptor meshValue measuredBounds =
(
    if meshValue.numverts<3 or meshValue.numverts>250000 or meshValue.numfaces<1 or meshValue.numfaces>250000 do throw "Independent base mesh admission exceeded."
    local z=measuredBounds[1].z as double,plane=z+(0.5 as double),points=#(),referenced=false,clippedTriangles=0
    local low=#((1e30 as double),(1e30 as double)),high=#((-1e30 as double),(-1e30 as double))
    for face=1 to meshValue.numfaces do
    (
        local ids=getFace meshValue face
        local pa=getVert meshValue (ids.x as integer),pb=getVert meshValue (ids.y as integer),pc=getVert meshValue (ids.z as integer)
        if (amin #(pa.z,pb.z,pc.z))<=plane do
        (
            local a=#((pa.x as double),(pa.y as double),(pa.z as double)),b=#((pb.x as double),(pb.y as double),(pb.z as double)),c=#((pc.x as double),(pc.y as double),(pc.z as double))
            local ux=b[1]-a[1],uy=b[2]-a[2],uz=b[3]-a[3],vx=c[1]-a[1],vy=c[2]-a[2],vz=c[3]-a[3]
            local nx=uy*vz-uz*vy,ny=uz*vx-ux*vz,nz=ux*vy-uy*vx
            if nx*nx+ny*ny+nz*nz>1e-18 do
            (
                if (amin #(a[3],b[3],c[3]))<=z+0.002 do referenced=true
                local triangle=#(a,b,c),clipped=#()
                for corner=1 to 3 do
                (
                    local nextCorner=if corner==3 then 1 else corner+1
                    local first=triangle[corner],second=triangle[nextCorner],inside=first[3]<=plane,other=second[3]<=plane
                    if inside do append clipped #(first[1],first[2])
                    if inside!=other do
                    (
                        local fraction=(plane-first[3])/(second[3]-first[3])
                        append clipped #(first[1]+fraction*(second[1]-first[1]),first[2]+fraction*(second[2]-first[2]))
                    )
                )
                if clipped.count>4 do throw "Independent one-plane clipped triangle exceeded four vertices."
                if clipped.count>0 do clippedTriangles+=1
                for point in clipped do
                (
                    if points.count>=16384 do throw "Independent contact-band point admission exceeded."
                    low[1]=amin #(low[1],point[1]);low[2]=amin #(low[2],point[2])
                    high[1]=amax #(high[1],point[1]);high[2]=amax #(high[2],point[2])
                    append points point
                )
            )
        )
    )
    if not referenced do throw "Independent source/output minimum has no referenced nondegenerate triangle contact."
    local count=points.count,hull=caRWBaseHull points
    -- World contact center B, actual referenced band hull, independent band
    -- bounds/counts. Native anchor/footprint is never an input to this tuple.
    #(#((low[1]+high[1])*0.5,(low[2]+high[2])*0.5,z),hull,#(low,high),clippedTriangles,count)
)
fn caRWDClipConvexTriangle polygon triangle =
(
    local vertices=#(caRWXY triangle[1],caRWXY triangle[2],caRWXY triangle[3]),result=polygon
    local signValue=if (caRWBaseTurn vertices[1] vertices[2] vertices[3])>=0 then 1 else -1
    for edge=1 to 3 do
    (
        if result.count>0 do
        (
            local nextEdge=if edge==3 then 1 else edge+1
            local a=vertices[edge],b=vertices[nextEdge],clipped=#(),previous=result[result.count]
            local previousSide=signValue*(caRWBaseTurn a b previous)
            for current in result do
            (
                local currentSide=signValue*(caRWBaseTurn a b current)
                if (previousSide>=0)!=(currentSide>=0) do
                (
                    local fraction=previousSide/(previousSide-currentSide)
                    append clipped #(previous[1]+fraction*(current[1]-previous[1]),previous[2]+fraction*(current[2]-previous[2]))
                )
                if currentSide>=0 do append clipped current
                previous=current;previousSide=currentSide
            )
            result=clipped
        )
    )
    result
)
fn caRWDHullClearance boundary hull =
(
    if hull.count<3 or hull.count>256 or boundary.count<3 or boundary.count>1200 do throw "Independent base/boundary clearance admission exceeded."
    local minimum=1e30 as double
    for segment in boundary do
    (
        -- Includes a whole receiving hole/boundary enclosed by the base.
        for endpoint in segment do
        (
            local inside=true
            for index=1 to hull.count while inside do
            (
                local nextIndex=if index==hull.count then 1 else index+1
                if (caRWBaseTurn hull[index] hull[nextIndex] endpoint)<0 do inside=false
            )
            if inside do return (0.0 as double)
        )
        for index=1 to hull.count do
        (
            local nextIndex=if index==hull.count then 1 else index+1
            minimum=amin #(minimum,(caRWDSegmentDistance segment[1] segment[2] hull[index] hull[nextIndex]))
        )
    )
    minimum
)
fn caRWBaseCoverage top boundary hull edge =
(
    if edge<0 or hull.count<3 or hull.count>256 or top.count<2 or top.count>400 do throw "Independent base support admission exceeded."
    local area=caRWDArea hull,covered=0.0 as double
    for triangle in top do covered+=(caRWDArea (caRWDClipConvexTriangle hull triangle))
    local minimum=caRWDHullClearance boundary hull
    local allowance=0.03 as double,target=edge as double
    local fullSupport=abs(covered-area)<=amax #((0.05 as double),area*0.000001)
    #(fullSupport and minimum>=target-allowance,area,covered,minimum,target,allowance)
)

fn caRWVisual row source =
(
    -- The pose locates the referenced bottom-band center B. Full source
    -- vertices still all have to match; no native support data is an oracle.
    if source.count!=8 or source[8]==undefined do throw "Independent source contact reference missing."
    local base=source[8],anchor=[base[1][1],base[1][2],base[1][3]]
    local output=caRWMesh row[9],parts=caRWGeometry source[3]
    local vertices=true,faces=true,maps=true,materials=true,maxError=0.0,vertexBase=0,faceBase=0
    local outputCount=meshop.getNumMaps output,channelStates=#()
    if outputCount>16 do throw "Output UV admission exceeded."
    for channel=-2 to outputCount-1 do append channelStates #(channel,0,0,(meshop.getMapSupport output channel))
    for partNode in parts do
    (
        local original=caRWMesh partNode
        if vertexBase+original.numverts>output.numverts then vertices=false else
        (
            for i=1 to original.numverts do
            (
                local pointValue=(getVert original i)-anchor
                local wanted=row[4]+[(cos row[5])*pointValue.x-(sin row[5])*pointValue.y,(sin row[5])*pointValue.x+(cos row[5])*pointValue.y,pointValue.z]
                local error=distance wanted(getVert output(vertexBase+i))
                maxError=amax #(maxError,error)
                if error>0.03 do vertices=false
            )
        )
        if faceBase+original.numfaces>output.numfaces then faces=false else
        (
            for i=1 to original.numfaces do
            (
                local wantedFace=(getFace original i)+[vertexBase,vertexBase,vertexBase]
                if wantedFace!=(getFace output(faceBase+i))or(getFaceSmoothGroup original i)!=(getFaceSmoothGroup output(faceBase+i))do faces=false
                local sourceID=getFaceMatID original i,outputID=getFaceMatID output(faceBase+i)
                local sourceLeaf=caRWLeaf partNode.material sourceID,outputLeaf=caRWLeaf row[9].material outputID
                if sourceLeaf==undefined then
                (
                    -- An original empty MultiMaterial slot is preserved only
                    -- by the same root reference AND unchanged face ID.
                    if partNode.material==undefined or partNode.material!=row[9].material or sourceID!=outputID do materials=false
                )
                else if sourceLeaf!=outputLeaf do materials=false
            )
        )
        local originalCount=meshop.getNumMaps original
        if originalCount>16 do throw "Source UV admission exceeded."
        if originalCount>outputCount do maps=false
        for state in channelStates do
        (
            local channel=state[1]
            local supported=if channel<originalCount then meshop.getMapSupport original channel else false
            if supported then
            (
                if not state[4]then maps=false else
                (
                    local nv=meshop.getNumMapVerts original channel,nf=meshop.getNumMapFaces original channel
                    local outputNV=meshop.getNumMapVerts output channel,outputNF=meshop.getNumMapFaces output channel
                    if nf!=original.numfaces do maps=false
                    if state[2]+nv>outputNV or state[3]+nf>outputNF then maps=false else
                    (
                        -- Full arrays and exact mapping-triangle IDs prove
                        -- exact coordinates at every authored face corner.
                        for i=1 to nv do if(meshop.getMapVert original channel i)!=(meshop.getMapVert output channel(state[2]+i))do maps=false
                        for i=1 to nf do
                        (
                            local wantedMapFace=(meshop.getMapFace original channel i)+[state[2],state[2],state[2]]
                            if wantedMapFace!=(meshop.getMapFace output channel(state[3]+i))do maps=false
                        )
                    )
                    state[2]+=nv;state[3]+=nf
                )
            )
            else if state[4]do
            (
                -- This source leaf had no authored map data. SDK CombineMeshes
                -- extends existing channels over its geometry with valid faces.
                -- No particular fill coordinate is invented or assumed here.
                local outputNV=meshop.getNumMapVerts output channel,outputNF=meshop.getNumMapFaces output channel
                if outputNV<1 or state[3]+original.numfaces>outputNF then maps=false else
                (
                    for i=1 to original.numfaces do
                    (
                        local generatedMapFace=meshop.getMapFace output channel(state[3]+i)
                        for corner=1 to 3 do if generatedMapFace[corner]<1 or generatedMapFace[corner]>outputNV do maps=false
                    )
                )
                state[3]+=original.numfaces
            )
        )
        vertexBase+=original.numverts;faceBase+=original.numfaces
        delete original
    )
    if vertexBase!=output.numverts do vertices=false
    if faceBase!=output.numfaces do faces=false
    for state in channelStates where state[4]do
        if state[2]!=(meshop.getNumMapVerts output state[1])or state[3]!=(meshop.getNumMapFaces output state[1])do maps=false
    -- One bounded scan of the already-owned actual output snapshot,
    -- reused by this row's support check and the named corner regression.
    local outputBase=undefined
    try(outputBase=caRWBaseDescriptor output row[10])catch(delete output;throw())
    delete output
    #(vertices,faces,maps,materials,maxError,outputBase)
)
fn caRWCapture setup =
(
    local rows=#()
    for r in(caOutputRows setup)do
    (
        local meshValue=caRWMesh r[9],b=caRWBounds meshValue
        append rows #(r[1],r[2],r[3],(copy r[4]),r[5],r[6],r[7],r[8],r[9],b,meshValue.numverts,meshValue.numfaces)
        delete meshValue
    )
    rows
)
fn caRWSame a b =
(
    if a.count!=b.count then false else
    (
        local same=true
        for i=1 to a.count do for k=1 to 8 do if not(deepEqual a[i][k]b[i][k]strictCompare:true)do same=false
        same
    )
)
fn caRWPhysical fixture =
(
    local savedSettings=(caSetupSummary fixture[2])[9]
    caRWNote("PHYSICAL_STATE fixture="+fixture[1]+" stage="+caRWContext+" actualSavedSettings="+caRWJ savedSettings)
    local rows=caRWCapture fixture[2],contact=true,separation=true,fullSize=true,vertexParity=true,topology=true,maps=true,materials=true,evidence=#()
    caRWRequire (fixture[1]+" publishes nonzero real-model placements") (rows.count>0)
    for row in rows do
    (
        local sourcePair=caRWFind fixture[4] row[2]
        if sourcePair==undefined do throw "Output references an unrecognized fixture source."
        local source=sourcePair[2],b=row[10],yaw=mod(row[5]+360.0)360.0
        local quarter=abs(yaw)<0.0001 or abs(yaw-90)<0.0001 or abs(yaw-180)<0.0001 or abs(yaw-270)<0.0001
        local wanted=caRWSize source[4],sideways=abs(yaw-90)<0.0001 or abs(yaw-270)<0.0001
        if sideways do wanted=[wanted.y,wanted.x,wanted.z]
        if not quarter or row[6]!=1 or row[8]!=0L or distance(caRWSize b)wanted>0.04 do fullSize=false
        if abs(b[1].z-fixture[5][3])>0.03 do contact=false
        local visual=caRWVisual row source
        row[13]=visual[6]
        local cover=caRWBaseCoverage fixture[5][2] fixture[5][4] row[13][2] 10.0
        if not cover[1]do contact=false
        -- Preserve full-body bounds coverage as evidence. Empty upper-body
        -- corners are not a contact requirement; collision below stays whole-body.
        local bodyCover=caRWCoverage fixture[5][2] fixture[5][4] b[1] b[2] 10.0
        caRWNote("FULL_BODY_BOUNDS_DIAGNOSTIC fixture="+fixture[1]+" stage="+caRWContext+" placement="+caRWNum row[1]+" passes="+(bodyCover[1]as string)+" areaMM2="+caRWNum bodyCover[2]+" coveredMM2="+caRWNum bodyCover[3]+" minimumEuclideanMM="+caRWNum bodyCover[4]+" actualContactBandAreaMM2="+caRWNum cover[2]+" actualContactBandCoveredMM2="+caRWNum cover[3]+" actualContactBandMinimumEuclideanMM="+caRWNum cover[4]+" actualContactHullVertices="+(row[13][2].count as string))
        for triangle in fixture[5][1]while separation do if caRWTriangleBox triangle b[1]b[2]do separation=false
        vertexParity=vertexParity and visual[1];topology=topology and visual[2];maps=maps and visual[3];materials=materials and visual[4]
        append evidence #(row[1],source[1],cover[2],cover[3],visual[5],cover[4],cover[5],cover[6])
    )
    for i=1 to rows.count do for j=i+1 to rows.count where j<=rows.count do
    (
        if caRWDistanceBoxes rows[i][10]rows[j][10]<14.97 do separation=false
    )
    caRWCheck (fixture[1]+" full source dimensions survive yaw with fixed scale 1") fullSize
    -- Footprint here is the convex hull of actual referenced triangles clipped
    -- to minZ+0.5mm; the complete mesh remains the collision/shape oracle.
    caRWCheck (fixture[1]+" actual unexpanded footprint is fully supported with 10mm Euclidean edge clearance") contact details:(evidence as string)
    caRWCheck (fixture[1]+" furniture triangles avoid envelope interiors; props keep 15mm separation") separation
    caRWCheck (fixture[1]+" every actual output vertex matches full-size source under recorded pose") vertexParity
    caRWCheck (fixture[1]+" topology and smoothing remain from actual source") topology
    caRWCheck (fixture[1]+" all authored mapping arrays/faces stay exact; added unmapped-part faces have valid indices") maps
    caRWCheck (fixture[1]+" original Corona material bindings and empty-slot semantics remain intact") materials
    fixture[7]=rows;fixture[8]=evidence
    rows
)
fn caRWDensityForFive setup furniture registered settings height =
(
    -- Same native inspector settings as CreateSetup: grid15, clearance1, slope0.
    -- This independent retained inspector snapshot does not alter the setup.
    local inspection=caInspect #(furniture[3])settings[10]1.0 0.0
    local usableArea=0.0 as double,activeRegions=0
    for index=1 to inspection[4]do
    (
        local region=caRegion index
        if abs(region[2].z-height)<0.03 and abs(region[3].z-height)<0.03 do
        (
            usableArea+=region[5]
            activeRegions+=1
        )
    )
    caRWRequire "Density calculation has one eligible measured top region" (activeRegions==1 and usableArea>0)
    local totalSlot=0.0 as double,totalWeight=0.0 as double
    for sourcePair in registered do
    (
        local dimensions=caRWSize sourcePair[2][4]
        local footprintArea=(dimensions.x as double)*(dimensions.y as double)
        local slot=((sqrt footprintArea)+(settings[3]as double))^2
        -- Authored source/category weights and scales are exactly1.
        totalSlot+=slot;totalWeight+=1.0
    )
    local meanSlot=totalSlot/totalWeight
    local denominator=usableArea*(1.0-(settings[7]as double))
    local lower=4.0*meanSlot/denominator,upper=5.0*meanSlot/denominator
    local midpoint=((lower+upper)*0.5)as float
    caRWRequire "Five-slot authored amount interval lies inside UI range" (lower>=0 and upper<=1 and midpoint>lower and midpoint<upper)
    settings[2]=midpoint
    caSetArrangeSettings setup settings
    local actual=(caSetupSummary setup)[9]
    local predicted=ceil(denominator*(actual[2]as double)/meanSlot)
    caRWRequire "Float-roundtripped midpoint still predicts exactly five slots" (predicted==5 and actual[2]>lower and actual[2]<upper)
    caRWNote("DENSITY_CALC usableAreaMM2="+caRWNum usableArea+" meanSlotMM2="+caRWNum meanSlot+" stable5Interval=("+caRWNum lower+","+caRWNum upper+"] chosen="+caRWNum actual[2]+" predicted="+caRWNum predicted)
    #(usableArea,meanSlot,lower,upper,actual[2],predicted)
)
fn caRWSelectArtistSeed fixture authoredSeed requireAllSources =
(
    local selected=false,trials=#(),chosen=undefined
    local maximumTrials=if requireAllSources then 32 else 1
    for trial=0 to maximumTrials-1 while not selected do
    (
        local settings=for value in fixture[6]collect value
        settings[1]=authoredSeed+trial
        local stats=caGenerateVariation fixture[2]settings #()false
        local actualSettings=(caSetupSummary fixture[2])[9]
        local rows=caRWCapture fixture[2],usedAssets=#()
        for row in rows do if findItem usedAssets row[2]==0 do append usedAssets row[2]
        local complete=not requireAllSources or(rows.count==5 and usedAssets.count==fixture[4].count)
        append trials #(actualSettings[1],stats[1],stats[2],stats[5],usedAssets.count,complete)
        caRWNote("ARTIST_SEED_TRIAL "+fixture[1]+" seed="+caRWNum actualSettings[1]+" requested="+caRWNum stats[1]+" accepted="+caRWNum stats[2]+" underfilled="+caRWNum stats[5]+" distinctSources="+caRWNum usedAssets.count+" chosen="+(complete as string))
        if complete do
        (
            selected=true;chosen=actualSettings[1]
            fixture[6]=actualSettings;fixture[9]=stats
        )
    )
    caRWRequire(fixture[1]+" bounded explicit artist seed search finds complete original-source composition")selected
    fixture[11]=trials
    caRWContext=fixture[1]+" artistGenerate"
    local first=caRWPhysical fixture
    caRWContext=fixture[1]+" artistRepeat"
    fixture[9]=caGenerate fixture[2]#()
    local repeated=caRWPhysical fixture
    caRWCheck(fixture[1]+" selected saved artist seed repeats all placement fields exactly")(caRWSame first repeated)
    chosen
)

-- Retained only to demonstrate the old, stronger square-margin oracle mismatch.
-- Its result is diagnostic evidence; it is never the physical acceptance rule.
fn caRWSquareCoverage top low high edge =
(
    local a=low-[edge,edge,0],b=high+[edge,edge,0],area=(b.x-a.x)*(b.y-a.y),covered=0.0
    for triangle in top do covered+=caRWArea(caRWClipBox triangle a b)
    #(abs(covered-area)<=amax #(0.05,area*0.000001),area,covered)
)
fn caRWCornerRegression fixture =
(
    local settings=for value in(caSetupSummary fixture[2])[9]collect value
    settings[1]=412004L
    caRWContext=fixture[1]+" deterministicCornerGenerate"
    fixture[9]=caGenerateVariation fixture[2]settings #()false
    fixture[6]=(caSetupSummary fixture[2])[9]
    caRWRequire "Side diagonal-boundary regression saves explicit seed 412004" (fixture[6][1]==412004L)
    local first=caRWPhysical fixture
    caRWRequire "Side deterministic diagonal-boundary regression has one real full-size vase" (first.count==1)
    local bounds=first[1][10]
    local physical=caRWBaseCoverage fixture[5][2]fixture[5][4]first[1][13][2]10.0
    local oldSquare=caRWSquareCoverage fixture[5][2]bounds[1]bounds[2]10.0
    local oldDeficit=(oldSquare[2]as double)-(oldSquare[3]as double)
    caRWNote("DIAGONAL_BOUNDARY_REGRESSION seed="+caRWNum fixture[6][1]+" actualFootprintAreaMM2="+caRWNum physical[2]+" actualCoveredMM2="+caRWNum physical[3]+" minEuclideanMM="+caRWNum physical[4]+" requiredMM="+caRWNum physical[5]+" measurementAllowanceMM="+caRWNum physical[6]+" oldSquareAreaMM2="+caRWNum oldSquare[2]+" oldSquareCoveredMM2="+caRWNum oldSquare[3]+" oldSquareDeficitMM2="+caRWNum oldDeficit)
    caRWCheck "Side diagonal-boundary footprint is fully supported with 10 mm Euclidean edge within 0.03 mm measurement allowance" (physical[1] and physical[4]>=10.0-0.03)
    caRWCheck "Side diagonal-boundary regression retains old square-margin deficit above 1 mm2" (oldDeficit>1.0)
    caRWContext=fixture[1]+" deterministicCornerRepeat"
    fixture[9]=caGenerate fixture[2]#()
    local repeated=caRWPhysical fixture
    caRWCheck "Side diagonal-boundary seed repeats every complete placement field exactly" (caRWSame first repeated)
    true
)

fn caRWSetup label furniture sources seed caps amount =
(
    local setup=caCreateSetup #(furniture[3]) 3;setup.name=label+"_Arrange"
    local registered=#()
    for sourceRow in sources do
    (
        local accessoryCategory=1
        if sourceRow[1]=="Decor_Set_01_Complete_Plant" do accessoryCategory=3
        if sourceRow[1]=="Decor_Vases_01" do accessoryCategory=6
        local registration=caRWRegister setup sourceRow accessoryCategory
        append registered registration
    )
    local settings=#(seed,amount,15.0,10.0,0.4,0.0,0.2,2,3,15.0,false)
    caSetArrangeSettings setup settings;caSetCollisionScope setup #()false
    local rules=caCategoryRules setup 3
    for categoryRule in rules do
    (
        categoryRule[2]=(1.0 as double)
        categoryRule[3]=0
        if categoryRule[1]==1 do categoryRule[3]=caps[1]
        if categoryRule[1]==3 do categoryRule[3]=caps[2]
        if categoryRule[1]==6 do categoryRule[3]=caps[3]
        categoryRule[4]=false
    )
    caSetCategoryRules setup 3 rules
    caRWRequire (label+" explicit category limits retained") (deepEqual rules(caCategoryRules setup 3)strictCompare:true)
    caRWRequire (label+" native analysis finds actual surfaces") ((caAnalyzeSetup setup)>0)
    local height=furniture[4][2].z,active=0,regions=caRegionRows setup
    for region in regions do
    (
        local keep=abs(region[5].z-height)<0.03 and abs(region[6].z-height)<0.03
        caSetRegionRules setup region[1](label+" / top")label 2 37 1.0 false(not keep)[0,-1,0]
        if keep do active+=1
    )
    caRWRequire (label+" intended top alone remains eligible") (active>0)
    local geometry=caRWTop furniture[3]height,densityEvidence=undefined
    if caps[1]==3 and caps[2]==1 and caps[3]==1 do densityEvidence=caRWDensityForFive setup furniture registered settings height
    settings=(caSetupSummary setup)[9]
    local fixture=#(label,setup,furniture,registered,geometry,settings,#(),#(),#(),densityEvidence,#())
    append caRWFixtures fixture
    caRWContext=label+" fixedGenerate"
    fixture[9]=caGenerate setup #()
    caRWNote("NATIVE_STATS "+label+" "+(fixture[9]as string))
    local first=caRWPhysical fixture
    caRWContext=label+" fixedRepeat"
    caGenerate setup #()
    local repeatRows=caRWPhysical fixture
    caRWCheck (label+" unchanged fixed seed exactly repeats complete native placement records") (caRWSame first repeatRows)
    local oldSeed=fixture[6][1]
    caRWContext=label+" freshGenerate"
    fixture[9]=caGenerateVariation setup settings #()true
    fixture[6]=(caSetupSummary setup)[9]
    caRWCheck(label+" fresh native variation changes saved seed")(fixture[6][1]!=oldSeed)
    local variation=caRWPhysical fixture
    caRWContext=label+" freshRepeat"
    caGenerate setup #()
    local repeatedVariation=caRWPhysical fixture
    caRWCheck(label+" final fresh variation can be repeated exactly")(caRWSame variation repeatedVariation)
    if label=="REAL_Side" do caRWCornerRegression fixture
    caRWSelectArtistSeed fixture seed (caps[1]==3 and caps[2]==1 and caps[3]==1)
    fixture
)
fn caRWSourceJSON input =
(
    caRWObject #(#("name",caRWJ input[1]),#("max_path",caRWJ input[2]),#("max_sha256",caRWJ input[3]),#("metadata_path",caRWJ input[4]),#("metadata_sha256",caRWJ input[5]),#("source_mm_per_unit",caRWJ input[6]),#("count_semantics",caRWJ"selected_nodes_expected rows: nodeName, literal world bounds_mm, getPolygonCount vertices, getPolygonCount polygons; pose counts are actual snapshot vertices/triangles"),#("selected_nodes_expected",caRWJ input[7]),#("assembled_group_expected",caRWJ(if input.count>=9 then input[9]else undefined)))
)
fn caRWOutputJSON row fixture =
(
    local pair=caRWFind fixture[4]row[2]
    caRWObject #(#("placement_id",caRWJ(caRWNum row[1])),#("asset_id",caRWJ(caRWNum row[2])),#("region_id",caRWJ(caRWNum row[3])),#("source_name",caRWJ pair[2][1]),#("source_scene_node",caRWJ pair[2][3].name),#("locked",caRWJ row[7]),#("parent_stack_id",caRWJ(caRWNum row[8])),#("position_mm",caRWJ row[4]),#("yaw_degrees",caRWJ row[5]),#("uniform_scale",caRWJ row[6]),#("world_bounds_mm",caRWJ row[10]),#("vertices",caRWJ row[11]),#("triangles",caRWJ row[12]))
)
fn caRWFixtureJSON fixture =
(
    local poses=for row in fixture[7]collect(caRWOutputJSON row fixture)
    caRWObject #(#("label",caRWJ fixture[1]),#("setup",caRWJ fixture[2].name),#("furniture",caRWJ fixture[3][1]),#("furniture_world_bounds_mm",caRWJ fixture[3][4]),#("settings",caRWJ fixture[6]),#("top_height_mm",caRWJ fixture[5][3]),#("top_triangle_count",caRWJ fixture[5][2].count),#("generated_count",caRWJ fixture[7].count),#("placements",caRWRawArray poses),#("physical_evidence",caRWJ fixture[8]),#("native_stats",caRWJ fixture[9]),#("density_calculation",caRWJ fixture[10]),#("artist_seed_trials",caRWJ fixture[11]))
)
fn caRWExportGeometry =
(
    local stream=createFile(CA_TEST_OUTPUT+"real-world-geometry.csv")
    format "fixture,role,node,placement_id,record,index,a,b,c\n" to:stream
    for fixture in caRWFixtures do
    (
        local objects=#(#("furniture",fixture[3][3],"0",fixture[3][3].name))
        for sourcePair in fixture[4]do append objects #("source",sourcePair[2][3],caRWNum sourcePair[1],sourcePair[2][1])
        for row in fixture[7]do append objects #("output",row[9],caRWNum row[1],row[9].name)
        for object in objects do
        (
            local meshValue=caRWMesh object[2]
            for i=1 to meshValue.numverts do
            (
                local p=getVert meshValue i
                format "%,%,%,%,vertex,%,%,%,%\n" fixture[1]object[1]object[4]object[3]i(caRWNum p.x)(caRWNum p.y)(caRWNum p.z)to:stream
            )
            for i=1 to meshValue.numfaces do
            (
                local f=getFace meshValue i
                format "%,%,%,%,face,%,%,%,%\n" fixture[1]object[1]object[4]object[3]i(f.x as integer)(f.y as integer)(f.z as integer)to:stream
            )
            delete meshValue
        )
    )
    close stream
)
fn caRWReport =
(
    local sources=for input in caRWInputSpecs collect(caRWSourceJSON input)
    local deps=#(),fixtures=#(),checks=#(),renders=#()
    for dep in caRWDependencies do append deps(caRWObject #(#("source_path",caRWJ dep[1]),#("source_sha256",caRWJ dep[2]),#("local_path",caRWJ dep[3]),#("local_sha256",caRWJ dep[4]),#("exists",caRWJ(doesFileExist(CA_TEST_OUTPUT+dep[3])))))
    for fixture in caRWFixtures do append fixtures(caRWFixtureJSON fixture)
    for row in caRWChecks do append checks(caRWObject #(#("label",caRWJ row[1]),#("passed",caRWJ row[2]),#("details",caRWJ row[3])))
    for row in caRWRenders do append renders(caRWObject #(#("path",caRWJ row[1]),#("renderer",caRWJ row[2]),#("passes_limit",caRWJ row[3]),#("width",caRWJ row[4]),#("height",caRWJ row[5]),#("sha256",caRWJ row[6])))
    local scenePath=CA_TEST_OUTPUT+caRWScene,sceneSHA=if doesFileExist scenePath then caRWHash scenePath else""
    local text=caRWObject #(#("schema", "1"),#("status",caRWJ(if caRWFinished and caRWFailures==0 then"passed"else"failed")),#("passes",caRWJ caRWPasses),#("failures",caRWJ caRWFailures),#("units_mm_per_system_unit",caRWJ(1.0/(units.decodeValue"1mm"))),#("sources",caRWRawArray sources),#("dependencies",caRWRawArray deps),#("scene",caRWObject #(#("path",caRWJ caRWScene),#("sha256",caRWJ sceneSHA))),#("geometry_csv",caRWJ"real-world-geometry.csv"),#("fixtures",caRWRawArray fixtures),#("checks",caRWRawArray checks),#("renders",caRWRawArray renders),#("tolerances",caRWObject #(#("world_vertex_mm","0.03"),#("dimensions_mm","0.04"),#("contact_height_mm","0.03"),#("top_triangle_plane_mm","0.02"),#("interior_shrink_mm","0.03"),#("support_area_abs_mm2","0.05"),#("support_area_relative","0.000001"),#("edge_mm","10"),#("edge_distance_allowance_mm","0.03"),#("edge_semantics",caRWJ"Euclidean actual referenced minZ+0.5mm contact-band convex hull to true union boundary; full-body bounds retained as diagnostic"),#("spacing_mm","15"))))
    local stream=createFile(CA_TEST_OUTPUT+"real-world-report.json");format "%\n" text to:stream;close stream
)
fn caRWRun =
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    fileIn(CA_TEST_ROOT+"scripts/CyrusArrange.ms");fileIn(CA_TEST_ROOT+"scripts/ArrangeAssets.ms");fileIn(CA_TEST_ROOT+"scripts/ArrangeWorkflow.ms")
    fileIn(CA_TEST_ROOT+"scripts/ArrangeModifier.ms")
    fileIn(CA_TEST_ROOT+"tests/max/real_world_models_data.ms")
    fileIn(CA_TEST_ROOT+"tests/max/real_world_render_helpers.ms")
    mapPaths.add CA_TEST_OUTPUT
    caRWPrepareInputs()
    for input in caRWInputSpecs do caRWMerge input
    local coffee=undefined,side=undefined,bookA=undefined,bookB=undefined,plant=undefined,decor=undefined
    for s in caRWSources do case s[1]of
    (
        "Coffee_Table_04":coffee=s
        "Side_Table_01":side=s
        "Books_01_Book_002":bookA=s
        "Books_01_Book_019":bookB=s
        "Decor_Set_01_Complete_Plant":plant=s
        "Decor_Vases_01":decor=s
    )
    caRWPlaceSource coffee [-800,0,0]"REAL_Coffee_Table"
    caRWPlaceSource side [500,0,0]"REAL_Side_Table"
    caRWPlaceSource bookA [-800,2600,0]"SOURCE_Flat_Book_A"
    caRWPlaceSource bookB [-400,2600,0]"SOURCE_Flat_Book_B"
    caRWPlaceSource plant [100,2600,0]"SOURCE_Potted_Plant"
    caRWPlaceSource decor [600,2600,0]"SOURCE_Decor_Vases"
    local sources=#(bookA,bookB,plant,decor)
    local sourceLayer=LayerManager.newLayerFromName"REAL_90_ORIGINAL_PROP_SOURCES"
    for source in sources do
    (
        sourceLayer.addNode source[3]
        source[3].renderable=false
        for partNode in(caRWGeometry source[3])do(sourceLayer.addNode partNode;partNode.renderable=false)
    )
    caRWNote "PLANT_VISUAL_PREREQUISITE complete Group006 parts030/031/032: 488.401x499.938x528.660mm, scale1, original-material closeup confirmed; no lamp substitute"

    caRWSetup "REAL_Coffee" coffee sources 412031L #(3,1,1) 0.30
    caRWSetup "REAL_Side" side #(decor) 412032L #(0,0,1) 0.35
    local usedBook=false,usedPlant=false,usedDecor=false
    for fixture in caRWFixtures do for row in fixture[7]do
    (
        local sourcePair=caRWFind fixture[4]row[2],name=sourcePair[2][1]
        if matchPattern name pattern:"Books_*"do usedBook=true
        if name=="Decor_Set_01_Complete_Plant"do usedPlant=true
        if name=="Decor_Vases_01"do usedDecor=true
    )
    caRWRequire "accepted full-size book, plant and decor all occur in the actual output" (usedBook and usedPlant and usedDecor)
    for source in caRWSources do caRWCheck(source[1]+" evaluated geometry/material paths/transform preserved by native operations")(deepEqual source[5](caRWSourceState source[3])strictCompare:true)
    sourceLayer.isHidden=true;sourceLayer.isFrozen=true
    caRWContext="front arrangement icons without changing physical placements"
    for fixture in caRWFixtures do
    (
        local beforeIconMove=caRWCapture fixture[2]
        local furnitureBounds=fixture[3][4]
        local frontPosition=[(furnitureBounds[1].x+furnitureBounds[2].x)*0.5,furnitureBounds[1].y-200.0,80.0]
        fixture[2].position=frontPosition
        caRWCheck(fixture[1]+" arrangement icon has the requested clear front position")(caRWNear fixture[2].position frontPosition)
        local afterIconMove=caRWCapture fixture[2]
        local geometryUnchanged=caRWSame beforeIconMove afterIconMove
        if beforeIconMove.count==afterIconMove.count do for i=1 to beforeIconMove.count do
            if not(deepEqual beforeIconMove[i][10]afterIconMove[i][10]strictCompare:true)do geometryUnchanged=false
        caRWCheck(fixture[1]+" moving only the arrangement icon retains actual output geometry")geometryUnchanged
        caRWContext=fixture[1]+" iconMoveFixedGenerate"
        fixture[9]=caGenerate fixture[2]#()
        local repeatedAfterIconMove=caRWPhysical fixture
        caRWCheck(fixture[1]+" fixed-seed generation is independent of arrangement icon position")(caRWSame beforeIconMove repeatedAfterIconMove)
    )
    caRWStageScene()
    caRWContext="save and reopen actual real-model scene"
    caRWRequire "self-contained real-model scene saves" (saveMaxFile(CA_TEST_OUTPUT+caRWScene)quiet:true)
    local before=for fixture in caRWFixtures collect(caRWCapture fixture[2])
    local setupNames=for fixture in caRWFixtures collect fixture[2].name
    local nodeNames=for source in caRWSources collect source[3].name
    caRWRequire "owned saved scene reopens" (loadMaxFile(CA_TEST_OUTPUT+caRWScene)quiet:true)
    for i=1 to caRWSources.count do caRWSources[i][3]=getNodeByName nodeNames[i]exact:true
    for i=1 to caRWFixtures.count do
    (
        local fixture=caRWFixtures[i];fixture[2]=getNodeByName setupNames[i]exact:true
        fixture[3][3]=getNodeByName(if fixture[1]=="REAL_Coffee"then"REAL_Coffee_Table"else"REAL_Side_Table")exact:true
        local reopened=caRWCapture fixture[2]
        caRWCheck(fixture[1]+" save/reopen retains complete logical poses")(caRWSame before[i]reopened)
        caRWContext=fixture[1]+" savedSceneReopen"
        caRWPhysical fixture
    )
    for source in sources do for partNode in(caRWGeometry source[3])do
    (
        local tree=caRWMaterialTree partNode.material
        caRWCheck(partNode.name+" reopened assigned Corona graph remains supported")(partNode.material!=undefined and tree[1])
        for item in tree[3]do if isProperty item #filename and(item.filename as string)!=""do
        (
            local relative=item.filename as string
            caRWRequire("reopened dependency resolves "+relative)(doesFileExist(CA_TEST_OUTPUT+relative))
        )
    )
    caRWExportGeometry()
    if CA_REAL_WORLD_RENDER then caRWRenderScene()else caRWNote"RENDER_SCOPE physical fixture only; explicit render wrapper required for image evidence"
    caRWContext="final source integrity"
    for input in caRWInputSpecs do
    (
        caRWCheck(input[1]+" library Max remains byte-identical")((caRWHash input[2])==input[3])
        caRWCheck(input[1]+" asset metadata remains byte-identical")((caRWHash input[4])==input[5])
    )
    caRWFinished=true;caRWWrite();caRWReport()
)
try(caRWRun())catch
(
    caRWFailures+=1;caRWFinished=true
    caRWNote("EXCEPTION ["+caRWContext+"] "+(getCurrentException()as string))
    try(caRWNote(getCurrentExceptionStackTrace()))catch()
    try(caRWReport())catch()
    caRWWrite()
)
