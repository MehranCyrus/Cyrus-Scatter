/*
  Independent native visual-channel and material Undo regression.
  Isolated Max 2027 batch only; no external content or computer use.
  SDK primary API references: samples/maxscript/mxsagni/meshop.cpp (map channels),
  MeshNormalSpec.h (inverse-transpose normal transforms), and MAXScript
  Edit_Normals/EditNormalsMod documentation GUID-9F33B780-7A98-4638-BD00-A1725FA1DB70.
*/
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caVLog = #(), caVPasses = 0, caVFailures = 0, caVFinished = false
global caVWrite, caVRecord, caVCheck, caVRequire, caVLeaf, caVMaterialKey
global caVMapUV, caVAuthorMesh, caVNormal, caVExpected, caVSourceState
global caVVerify, caVRows, caVFixture, caVObjectMesh, caVBindNormals, caVNormalDetail
global caVContext = "initialization"
fn caVWrite =
(
    local report = createFile (CA_TEST_OUTPUT + "result.txt")
    local state = if caVFinished then (if caVFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
    format "% passes=% failures=%\n" state caVPasses caVFailures to:report
    for line in caVLog do format "%\n" line to:report
    close report
)
fn caVRecord line = (append caVLog line; caVWrite())
fn caVCheck label condition =
(
    if condition then (caVPasses += 1; caVRecord ("PASS " + label))
    else (caVFailures += 1; caVRecord ("FAIL " + label))
    condition
)
fn caVRequire label condition =
(
    caVCheck label condition
    if not condition do throw ("Prerequisite failed: " + label)
    condition
)
fn caVLeaf material id =
(
    local result = material
    if material != undefined and isProperty material #materialIDList do
    (
        result = undefined
        for i = 1 to material.materialIDList.count where material.materialIDList[i] == id do result = material.materialList[i]
    )
    result
)
fn caVMaterialKey material =
(
    if material == undefined then "undefined"
    else
    (
        local map = material.diffuseMap
        #(material.name,material.diffuse,(if map == undefined then "" else map.name),(if map == undefined then 0 else map.coords.mapChannel)) as string
    )
)
fn caVMapUV meshValue channel face corner =
(
    local faceMap = meshop.getMapFace meshValue channel face
    meshop.getMapVert meshValue channel (faceMap[corner] as integer)
)
fn caVNormal normalValue objectTM =
(
    if classOf normalValue != Point3 do throw ("Normal reader returned " + (normalValue as string) + " in " + caVContext)
    local basis = copy objectTM
    basis.row4 = [0,0,0]
    local inv = inverse basis
    local normalTM = matrix3 [inv.row1.x,inv.row2.x,inv.row3.x] [inv.row1.y,inv.row2.y,inv.row3.y] [inv.row1.z,inv.row2.z,inv.row3.z] [0,0,0]
    normalize (normalValue * normalTM)
)
fn caVNormalDetail label node component sourceFace outputFace outputCorner sourceCorner outputID wanted actual =
(
    -- Diagnostic alternatives do not relax the independent normal assertion.
    -- At most 36 detailed rows per verification (six samples plus six first
    -- mismatches per source component); summaries still count every corner.
    local expected = wanted[6][sourceCorner]
    local raw = wanted[8][sourceCorner], sourceTM = copy wanted[9]
    sourceTM.row4 = [0,0,0]
    local linear = normalize (raw * sourceTM)
    local doubleTransformed = caVNormal expected sourceTM
    local outputWorldExpected = caVNormal expected node.objectTransform
    local sameFace = for k = 1 to 3 collect (dot actual wanted[6][k])
    local sourceVertexCorner = findItem wanted[11] (wanted[12][sourceCorner] as integer)
    local bySourceVertexDot = if sourceVertexCorner > 0 then dot actual wanted[6][sourceVertexCorner] else undefined
    local line = stringStream ""
    format "NORMAL stage=% output=% component=% sourceFace=% outputFace=% outputCorner=% sourceCorner=% outputNormalID=% sourceNormalID=% actual=% expected=% dot=% sameFaceCornerDots=% raw=% rawDot=% linearTransform=% linearDot=% doubleInverseTranspose=% doubleDot=% expectedThroughOutputTM=% outputWorldDot=% normalFaceVertexIDs=% snapshotFaceVertexIDs=% sourceVertexMappedCorner=% sourceVertexMappedDot=%\n" label node.name component sourceFace outputFace outputCorner sourceCorner outputID wanted[10][sourceCorner] actual expected (dot actual expected) sameFace raw (dot actual (normalize raw)) linear (dot actual linear) doubleTransformed (dot actual doubleTransformed) outputWorldExpected (dot actual outputWorldExpected) wanted[11] wanted[12] sourceVertexCorner bySourceVertexDot to:line
    local output = openFile (CA_TEST_OUTPUT + "visual-normal-details.txt") mode:"a"
    format "%" (line as string) to:output
    close output
    close line
)
fn caVObjectMesh node =
(
    -- SDK getWorldStateMesh() used by snapshotAsMesh returns WORLD vertices.
    -- Undo only that coordinate transform on the independent mesh copy; source
    -- fixtures have no world-space modifiers. Normal checks read modifier data.
    local result = snapshotAsMesh node renderMesh:false
    local inverseTM = inverse node.objectTransform
    for i = 1 to result.numverts do setVert result i ((getVert result i) * inverseTM)
    result
)
fn caVBindNormals node normalModifier label =
(
    -- Autodesk's EditNormals.cpp EnfnGetNormal/GetNormalID require mpInterface
    -- and GetModContexts, not merely an evaluated world mesh. Its SDK unit tests
    -- select the node and activate Modify before querying/authoring normals.
    caVContext = label + " | " + node.name + " | bind normal modifier"
    select node
    max modify mode
    modPanel.setCurrentObject normalModifier node:node ui:true
    local evaluated = snapshotAsMesh node renderMesh:false
    local normalCount = normalModifier.GetNumNormals node:node
    local faceCount = normalModifier.GetNumFaces node:node
    if modPanel.getCurrentObject() != normalModifier or normalCount <= 0 or faceCount != evaluated.numfaces do
        throw ("Normal edit context unavailable: " + caVContext + " | normals=" + (normalCount as string) + " faces=" + (faceCount as string) + " meshFaces=" + (evaluated.numfaces as string))
    normalCount
)
fn caVAuthorMesh node component material =
(
    convertToMesh node
    node.material = material
    meshop.setNumMaps node 3 keep:true
    local count = getNumFaces node
    for channel in #(1,2) do
    (
        meshop.setMapSupport node channel true
        meshop.setNumMapVerts node channel (count * 3) keep:false
        meshop.setNumMapFaces node channel count keep:false
        for f = 1 to count do
        (
            for k = 1 to 3 do
            (
                local index = (f-1)*3+k
                local uv = if channel == 1 then [component*0.1+f*0.01+k*0.001,k*0.2,f*0.003] else [component*1000+f*10+k,component*0.1+f*0.001+k*0.00001,component*0.01]
                meshop.setMapVert node channel index uv
            )
            meshop.setMapFace node channel f [(f-1)*3+1,(f-1)*3+2,(f-1)*3+3]
        )
    )
    for f = 1 to count do
    (
        setFaceSmoothGroup node f (bit.shift 1 (mod f 5))
        setFaceMatID node f (if component == 2 then (if mod f 2 == 0 then 7 else 3) else 1)
    )
    update node
    local normals = Edit_Normals()
    addModifier node normals
    caVBindNormals node normals "author fixture"
    local evaluated = snapshotAsMesh node
    local chosen = #{}
    for i = 1 to (normals.GetNumNormals node:node) do chosen[i] = true
    normals.Break selection:chosen node:node
    evaluated = snapshotAsMesh node
    -- Different values at every face corner are essential: a mirrored face's
    -- normal IDs can be swapped incorrectly while flat, identical normals hide
    -- the error. Break first, then author a distinct deterministic corner code.
    local perturbations = #([0.32,0.04,0.11],[-0.08,0.31,0.16],[0.12,-0.22,-0.27])
    local authored = #{}
    for f = 1 to count do for k = 1 to 3 do
    (
        local id = normals.GetNormalID f k node:node
        if id < 1 or id > (normals.GetNumNormals node:node) or authored[id] do throw ("Fixture normals did not break into independent corners: " + node.name + " face=" + (f as string) + " corner=" + (k as string))
        authored[id] = true
        local code = perturbations[k] + [id*0.0003,-id*0.0002,id*0.0001]
        local value = normalize ((normals.GetNormal id node:node) + code)
        normals.SetNormal id value node:node
        normals.SetNormalExplicit id explicit:true node:node
    )
    evaluated = snapshotAsMesh node
    caVRequire ("Fixture " + node.name + " authors nonempty explicit normals") ((normals.GetNumNormals node:node) > 0)
    local distinct = true
    for f = 1 to count do
    (
        local values = for k = 1 to 3 collect normals.GetNormal (normals.GetNormalID f k node:node) node:node
        for pair in #(#(1,2),#(1,3),#(2,3)) do
            if (dot values[pair[1]] values[pair[2]]) > 0.999 do distinct = false
    )
    caVRequire ("Fixture " + node.name + " has distinguishable normal directions at each face corner") distinct
    #(node,normals)
)
/* Expected row per source face: canonical vertex positions, UV1, UV2, smoothing,
   resolved material appearance, transformed explicit normals, geometric normal.
   UV2 contains unique source/corner markers, so no native face/merge order is assumed. */
fn caVExpected sources =
(
    local minimum = [1e20,1e20,1e20], maximum = [-1e20,-1e20,-1e20]
    for source in sources do
    (
        local m = caVObjectMesh source[1], tm = source[1].objectTransform
        for i = 1 to m.numverts do
        (
            local p = (getVert m i) * tm
            for axis = 1 to 3 do (minimum[axis] = amin minimum[axis] p[axis]; maximum[axis] = amax maximum[axis] p[axis])
        )
    )
    local anchor = [(minimum.x+maximum.x)*0.5,(minimum.y+maximum.y)*0.5,minimum.z]
    local result = #()
    for source in sources do
    (
        local node = source[1], normals = source[2], m = caVObjectMesh source[1], tm = source[1].objectTransform
        caVBindNormals node normals "expected fixture normals"
        caVRecord ("STAGE expected face channels | " + node.name + " | normals=" + ((normals.GetNumNormals node:node) as string))
        local faces = #()
        for f = 1 to m.numfaces do
        (
            local indices = getFace m f
            local positions = #(), uv1 = #(), uv2 = #(), explicitNormals = #(), rawNormals = #(), normalIDs = #(), normalVertexIDs = #()
            for k = 1 to 3 do
            (
                caVContext = "expected " + node.name + " face=" + (f as string) + " corner=" + (k as string)
                append positions (((getVert m (indices[k] as integer)) * tm) - anchor)
                append uv1 (caVMapUV m 1 f k)
                append uv2 (caVMapUV m 2 f k)
                local id = normals.GetNormalID f k node:node
                if id < 1 or id > (normals.GetNumNormals node:node) do throw ("Invalid normal ID " + (id as string) + " in " + caVContext)
                local raw = normals.GetNormal id node:node
                append rawNormals (copy raw)
                append normalIDs id
                append normalVertexIDs (normals.GetVertexID f k node:node)
                append explicitNormals (caVNormal raw tm)
            )
            append faces #(positions,uv1,uv2,(getFaceSmoothGroup m f),(caVMaterialKey (caVLeaf node.material (getFaceMatID m f))),explicitNormals,(caVNormal (getFaceNormal m f) tm),rawNormals,(copy tm),normalIDs,normalVertexIDs,(copy indices))
        )
        append result faces
    )
    result
)
fn caVSourceState sources =
(
    local result = #()
    for source in sources do
    (
        local node = source[1], m = caVObjectMesh source[1], normals = source[2]
        caVBindNormals node normals "source preservation snapshot"
        local vertices = for i = 1 to m.numverts collect getVert m i
        local faces = for i = 1 to m.numfaces collect #((getFace m i),(getFaceMatID m i),(getFaceSmoothGroup m i))
        local maps = #()
        for channel in #(1,2) do append maps #((for i = 1 to (meshop.getNumMapVerts m channel) collect meshop.getMapVert m channel i),(for i = 1 to m.numfaces collect meshop.getMapFace m channel i))
        local normalRows = for i = 1 to (normals.GetNumNormals node:node) collect #((normals.GetNormal i node:node),(normals.GetNormalExplicit i node:node))
        local materials = for i = 1 to m.numfaces collect caVMaterialKey (caVLeaf node.material (getFaceMatID m i))
        append result #(node.name,node.transform,(getHandleByAnim node.material),vertices,faces,maps,normalRows,materials)
    )
    result as string
)
fn caVRows setup =
(
    local result = #()
    for row in caOutputRows setup do append result #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8],(if isValidNode row[9] then getHandleByAnim row[9] else 0))
    result as string
)
fn caVVerify setup expected label =
(
    local rows = caOutputRows setup
    caVRequire (label + " has scene output") (rows.count > 0)
    local topology = true, uvSupported = true, uv1Correct = true, uv2Correct = true
    local positions = true, materials = true, smoothing = true, normalsCorrect = true, flagsCorrect = true, winding = true
    local normalStats = for component = 1 to expected.count collect #(0,0,1.0,0,0)
    local faceCount = 0
    for part in expected do faceCount += part.count
    for row in rows do
    (
        local node = row[9], m = caVObjectMesh row[9]
        if m.numfaces != faceCount do topology = false
        if not (meshop.getMapSupport m 1 and meshop.getMapSupport m 2) then uvSupported = false
        else
        (
            local probe, reader
            -- Probe creation is outside the measured Undo/Redo chain. Getters
            -- below read a copy; no modifier is added to managed output/source.
            undo off
            (
                probe = copy node
                probe.name = "CA_VISUAL_NORMAL_PROBE"
                reader = Edit_Normals()
                addModifier probe reader
                caVBindNormals probe reader (label + " output probe")
                local evaluated = snapshotAsMesh probe
            )
            for f = 1 to m.numfaces do
            (
                caVContext = label + " output=" + node.name + " face=" + (f as string)
                local ids = getFace m f
                local marker = caVMapUV m 2 f 1
                local component = (floor (marker.x / 1000)) as integer
                local originalFace = (floor ((mod marker.x 1000) / 10)) as integer
                if component < 1 or component > expected.count or originalFace < 1 or originalFace > expected[component].count then topology = false
                else
                (
                    local wanted = expected[component][originalFace]
                    if getFaceSmoothGroup m f != wanted[4] do smoothing = false
                    if (caVMaterialKey (caVLeaf node.material (getFaceMatID m f))) != wanted[5] do materials = false
                    if (dot (normalize (getFaceNormal m f)) wanted[7]) < 0.9999 do winding = false
                    for k = 1 to 3 do
                    (
                        local actualUV2 = caVMapUV m 2 f k
                        local originalCorner = (mod (actualUV2.x as integer) 10)
                        if originalCorner < 1 or originalCorner > 3 then uv2Correct = false
                        else
                        (
                            if distance actualUV2 wanted[3][originalCorner] > 0.0001 do uv2Correct = false
                            if distance (caVMapUV m 1 f k) wanted[2][originalCorner] > 0.0001 do uv1Correct = false
                            if distance (getVert m (ids[k] as integer)) wanted[1][originalCorner] > 0.003 do positions = false
                            local normalID = reader.GetNormalID f k node:probe
                            if normalID < 1 or normalID > (reader.GetNumNormals node:probe) do throw ("Invalid output normal ID " + (normalID as string) + " in " + caVContext)
                            if not (reader.GetNormalExplicit normalID node:probe) do flagsCorrect = false
                            local actualNormal = normalize (reader.GetNormal normalID node:probe)
                            local normalDot = dot actualNormal wanted[6][originalCorner]
                            local stats = normalStats[component]
                            stats[1] += 1; stats[3] = amin stats[3] normalDot
                            local mismatch = normalDot < 0.9999
                            if mismatch do (normalsCorrect = false;stats[2] += 1)
                            if stats[4] < 6 or (mismatch and stats[5] < 6) do
                            (
                                caVNormalDetail label node component originalFace f k originalCorner normalID wanted actualNormal
                                if stats[4] < 6 then stats[4] += 1 else stats[5] += 1
                            )
                        )
                    )
                )
            )
            undo off (delete probe)
        )
    )
    for component = 1 to normalStats.count do
        caVRecord ("NORMAL SUMMARY " + label + " component=" + (component as string) + " tested=" + (normalStats[component][1] as string) + " mismatches=" + (normalStats[component][2] as string) + " minimumDot=" + (normalStats[component][3] as string))
    caVCheck (label + " preserves all component triangle topology") topology
    caVCheck (label + " retains UV channels 1 and 2") uvSupported
    caVCheck (label + " preserves UV1 face/corner associations") uv1Correct
    caVCheck (label + " preserves UV2 face/corner associations") uv2Correct
    caVCheck (label + " preserves mirrored/nonuniform vertex-to-UV associations") positions
    caVCheck (label + " preserves resolved face materials and texture channels") materials
    caVCheck (label + " preserves original face smoothing bitmasks") smoothing
    caVCheck (label + " preserves explicit normal flags") flagsCorrect
    caVCheck (label + " preserves inverse-transpose authored normals") normalsCorrect
    caVCheck (label + " corrects mirrored geometric face winding") winding
)
fn caVFixture =
(
    resetMaxFile #noPrompt
    units.SystemType = #millimeters; units.SystemScale = 1
    local mm = units.decodeValue "1mm"
    local red = standardMaterial name:"CA_VISUAL_Red" diffuse:(color 190 45 30)
    local green = standardMaterial name:"CA_VISUAL_Green" diffuse:(color 40 150 70)
    local blue = standardMaterial name:"CA_VISUAL_Blue" diffuse:(color 40 70 180)
    local gold = standardMaterial name:"CA_VISUAL_Gold" diffuse:(color 185 145 45)
    red.diffuseMap = checker name:"CA_VISUAL_Checker_UV1" color1:white color2:black
    red.diffuseMap.coords.mapChannel = 1
    green.diffuseMap = checker name:"CA_VISUAL_Checker_UV2" color1:(color 10 30 20) color2:(color 150 210 160)
    green.diffuseMap.coords.mapChannel = 2
    local multi = multiMaterial numsubs:2 name:"CA_VISUAL_SparseMulti"
    multi.materialList = #(green,blue); multi.materialIDList = #(3,7)
    local a = box name:"CA_VISUAL_PartA" width:(60*mm) length:(50*mm) height:(20*mm) pos:[2445*mm,0,0]
    local b = box name:"CA_VISUAL_PartB" width:(50*mm) length:(40*mm) height:(25*mm)
    local bTM = (scaleMatrix [1.2,0.65,1.1]) * (rotateZMatrix 23); bTM.row4 = [2535*mm,0,0]; b.transform = bTM
    local c = mesh name:"CA_VISUAL_PartC" vertices:#([0,0,0],[24*mm,0,0],[0,20*mm,0],[0,0,28*mm]) faces:#([1,3,2],[1,2,4],[1,4,3],[2,3,4])
    local cTM = (scaleMatrix [-1.1,0.8,1.3]) * (rotateZMatrix -17); cTM.row4 = [2500*mm,65*mm,0]; c.transform = cTM
    local sources = #((caVAuthorMesh a 1 red),(caVAuthorMesh b 2 multi),(caVAuthorMesh c 3 gold))
    local head = group #(a,b,c) name:"CA_VISUAL_SOURCE"
    setGroupOpen head true
    local top = box name:"CA_VISUAL_TABLE" width:(1800*mm) length:(900*mm) height:(35*mm) pos:[0,0,420*mm]
    local sourceBefore = caVSourceState sources
    local setup = caCreateSetup #(top) 1
    setup.name = "CA_VISUAL_SETUP"
    caRegisterAsset setup head "Original Visual Regression Assembly" 1 31 #(0.0,90.0,180.0,270.0) 1.0 1.0 1.0 false
    local settings = (caSetupSummary setup)[9]
    settings[1] = 707; settings[2] = 0.1; settings[3] = 20; settings[4] = 15
    settings[7] = 0.65; settings[10] = 40; settings[11] = false
    caSetArrangeSettings setup settings
    caVCheck "Register/capture leaves source mesh/material/UV/normal state unchanged" ((caVSourceState sources) == sourceBefore)
    #(setup,sources,sourceBefore)
)

/* Native bound-accessory WSM visual regression, isolated Max 2027 runner only.
   Adds one original mixed-source fixture; the original 83 checks stay intact.
   Geometry oracle: raw snapshotAsMesh Mesh values, WORLD vertices, NO extra TM.
   UV/smoothing/material and prebinding normal checks use literal source data.
   Bound-WORLD normal fidelity uses frozen independent evaluated SOURCE normals;
   the Max deformation pipeline can change them from an ideal affine transform.
   Only a uniform planar Displace +Z translation is qualified by this fixture.
*/
global caVWVertices, caVWFaces, caVWUV, caVWLiteralNormal, caVWMaterial, caVWBandCenter
global caVWAuthor, caVWWorld, caVWProbe, caVWRead, caVWSourceState
global caVWYaw, caVWExpectedPoint, caVWExpectedNormal, caVWVerify, caVWRows, caVWRun
global caCreateSetup, caRegisterAsset, caSetupSummary, caSetArrangeSettings
global caCategoryRules, caSetCategoryRules, caSetCollisionScope, caAssetRows
global caAssetSupport, caGenerate, caOutputRows

fn caVWVertices component =
(
    if component == 1 then #([0,0,0],[60,0,0],[0,40,0],[0,0,50])
    else #([0,0,0],[25,0,0],[0,20,0],[0,0,35])
)
fn caVWFaces = #([1,3,2],[1,2,4],[1,4,3],[2,3,4])
fn caVWUV component channel face corner =
(
    if channel == 1 then [component*0.1+face*0.01+corner*0.001,corner*0.2,face*0.003]
    else [component*1000+face*10+corner,component*0.1+face*0.001+corner*0.00001,component*0.01]
)
fn caVWLiteralNormal component face corner =
(
    local vertices=caVWVertices component,indices=(caVWFaces())[face]
    local geometric=normalize (cross (vertices[indices.y as integer]-vertices[indices.x as integer]) (vertices[indices.z as integer]-vertices[indices.x as integer]))
    local perturbations=#([0.32,0.04,0.11],[-0.08,0.31,0.16],[0.12,-0.22,-0.27])
    normalize (geometric+perturbations[corner]+[component*0.005+face*0.003,corner*0.002,component*0.001])
)
fn caVWMaterial component face =
(
    if component == 1 then #("CA_WSM_Red",(color 190 45 30),"CA_WSM_Checker_UV1",1) as string
    else if mod face 2 == 0 then #("CA_WSM_Blue",(color 40 70 180),"",0) as string
    else #("CA_WSM_Green",(color 40 150 70),"CA_WSM_Checker_UV2",2) as string
)
fn caVWAuthor component frame material =
(
    local vertices=caVWVertices component,faces=caVWFaces()
    local node=mesh name:("CA_WSM_Part"+(component as string)) vertices:vertices faces:faces
    node.material=material
    meshop.setNumMaps node 3 keep:true
    for channel in #(1,2) do
    (
        meshop.setMapSupport node channel true
        meshop.setNumMapVerts node channel 12 keep:false
        meshop.setNumMapFaces node channel 4 keep:false
        for face=1 to 4 do
        (
            for corner=1 to 3 do meshop.setMapVert node channel ((face-1)*3+corner) (caVWUV component channel face corner)
            meshop.setMapFace node channel face [(face-1)*3+1,(face-1)*3+2,(face-1)*3+3]
        )
    )
    for face=1 to 4 do
    (
        setFaceSmoothGroup node face (bit.shift 1 (mod face 5))
        setFaceMatID node face (if component==1 then 1 else if mod face 2==0 then 7 else 3)
    )
    update node
    local reader=Edit_Normals()
    addModifier node reader
    caVBindNormals node reader "WSM fixture author literal normals"
    local selectionSet=#{}
    for i=1 to (reader.GetNumNormals node:node) do selectionSet[i]=true
    reader.Break selection:selectionSet node:node
    local used=#{}
    for face=1 to 4 do for corner=1 to 3 do
    (
        local id=reader.GetNormalID face corner node:node
        if id<1 or used[id] do throw "WSM fixture normals did not split into independent corners."
        used[id]=true
        reader.SetNormal id (caVWLiteralNormal component face corner) node:node
        reader.SetNormalExplicit id explicit:true node:node
    )
    -- Capture the authored affine basis before adding any WSM. It is an input,
    -- never a post-WSM query reused as the expected normal transformation.
    node.transform=frame
    #(node,reader,component,(copy frame),#())
)
fn caVWWorld node =
(
    local result=undefined
    in coordsys world (result=snapshotAsMesh node renderMesh:false)
    if result==undefined or result.numverts<1 or result.numverts>16 or result.numfaces>16 do throw "WSM oracle exceeded its small literal-mesh bound."
    result
)
fn caVWProbe worldMesh =
(
    -- setMesh <mesh> <TriMesh> copies the complete independent world snapshot.
    -- Identity transform: this probe's Edit Normals values are already WORLD.
    -- Fixture prerequisites below reject dropped/rebuilt specified normals.
    local probe=undefined,reader=undefined
    undo off
    (
        probe=mesh name:"CA_WSM_WORLD_NORMAL_PROBE"
        setMesh probe worldMesh
        probe.transform=matrix3 1
        reader=Edit_Normals()
        addModifier probe reader
        caVBindNormals probe reader "WSM independent world snapshot normal probe"
    )
    #(probe,reader)
)
-- Independent small-fixture world-triangle half-space clipping. No native
-- support/asset metadata is used to choose the expected contact center.
fn caVWBandCenter triangles minimumZ =
(
    if triangles.count!=8 do throw "WSM base oracle needs the eight literal source triangles."
    local plane=minimumZ+0.5,lo=[1e20,1e20,minimumZ],hi=[-1e20,-1e20,minimumZ],points=0
    for triangle in triangles do
    (
        if triangle.count!=3 do throw "WSM base oracle received a nontriangle."
        local areaVector=cross (triangle[2]-triangle[1]) (triangle[3]-triangle[1])
        if length areaVector<=0.000000001 do throw "WSM literal source triangle is degenerate."
        local clipped=#()
        for corner=1 to 3 do
        (
            local nextCorner=if corner==3 then 1 else corner+1
            local a=triangle[corner],b=triangle[nextCorner]
            local aInside=a.z<=plane,bInside=b.z<=plane
            if aInside do append clipped (copy a)
            if aInside!=bInside do
            (
                local fraction=(plane-a.z)/(b.z-a.z)
                append clipped (a+(b-a)*fraction)
            )
        )
        if clipped.count>4 do throw "WSM single-plane clipped triangle exceeded four vertices."
        for point in clipped do
        (
            lo.x=amin #(lo.x,point.x);lo.y=amin #(lo.y,point.y)
            hi.x=amax #(hi.x,point.x);hi.y=amax #(hi.y,point.y)
            points+=1
        )
    )
    if points<3 or points>32 or hi.x-lo.x<=0.000001 or hi.y-lo.y<=0.000001 do throw "WSM bottom band has no nondegenerate bounded contact envelope."
    #([(lo.x+hi.x)*0.5,(lo.y+hi.y)*0.5,minimumZ],lo,hi,points)
)

fn caVWRead sources displacement label =
(
    local allPoints=#(),worldTriangles=#(),lower=[1e20,1e20,1e20],upper=[-1e20,-1e20,-1e20],allCodes=#{}
    for source in sources do
    (
        local node=source[1],component=source[3],frame=source[4]
        local m=caVWWorld node,p=undefined,errorText=undefined,worldRows=#()
        local positions=true,uvCorrect=true,authoredNormals=true,evaluatedNormals=true,appearance=true,seen=#{}
        local evaluatedDirections=#(),minimumAnalyticDot=1.0
        try
        (
            -- The below-binding Edit Normals interface must still contain our
            -- original literal object-space values. This is distinct from the
            -- evaluated WORLD appearance after Max applies the WSM pipeline.
            caVBindNormals node source[2] "WSM original authored-normal prerequisite"
            for face=1 to 4 do for corner=1 to 3 do
            (
                local id=source[2].GetNormalID face corner node:node
                if not (source[2].GetNormalExplicit id node:node) or dot (normalize (source[2].GetNormal id node:node)) (caVWLiteralNormal component face corner)<0.9999 do authoredNormals=false
            )
            p=caVWProbe m
            if m.numfaces!=4 or m.numverts!=4 do positions=false
            for face=1 to m.numfaces do
            (
                local indices=getFace m face,trianglePoints=#()
                for corner=1 to 3 do
                (
                    local marker=caVMapUV m 2 face corner
                    local originalFace=(floor ((mod marker.x 1000)/10)) as integer
                    local originalCorner=mod (marker.x as integer) 10
                    if ((floor (marker.x/1000)) as integer)!=component or originalFace<1 or originalFace>4 or originalCorner<1 or originalCorner>3 then throw "WSM fixture lost its literal UV2 identity marker."
                    local key=(originalFace-1)*3+originalCorner
                    if seen[key] do throw "WSM fixture duplicated a literal face-corner marker."
                    seen[key]=true
                    local globalKey=(component-1)*12+key
                    if allCodes[globalKey] do throw "WSM fixture duplicated a complete component/face/corner code."
                    allCodes[globalKey]=true
                    local literalVertices=caVWVertices component,literalFace=(caVWFaces())[originalFace]
                    local expected=(literalVertices[(literalFace[originalCorner] as integer)]*frame)+(if component==1 then [0,0,displacement] else [0,0,0])
                    local actual=meshop.getVert m (indices[corner] as integer)
                    if distance actual expected>0.003 do positions=false
                    append allPoints (copy actual);append trianglePoints (copy actual)
                    for axis=1 to 3 do (lower[axis]=amin #(lower[axis],actual[axis]);upper[axis]=amax #(upper[axis],actual[axis]))
                    for channel in #(1,2) do if distance (caVMapUV m channel face corner) (caVWUV component channel originalFace originalCorner)>0.0001 do uvCorrect=false
                    local id=p[2].GetNormalID face corner node:p[1]
                    local expectedNormal=caVNormal (caVWLiteralNormal component originalFace originalCorner) frame
                    local isExplicit=p[2].GetNormalExplicit id node:p[1],actualNormal=normalize (p[2].GetNormal id node:p[1])
                    local normalDot=dot actualNormal expectedNormal
                    minimumAnalyticDot=amin #(minimumAnalyticDot,normalDot)
                    -- Controls retain the literal inverse-transpose oracle.
                    -- The bound source instead supplies its independently
                    -- measured, nondegenerate and specified WORLD appearance.
                    if not isExplicit or not ((length actualNormal)>0.9999 and (length actualNormal)<1.0001) do evaluatedNormals=false
                    if (displacement==0 or component==2) and normalDot<0.9999 do evaluatedNormals=false
                    evaluatedDirections[key]=copy actualNormal
                    if (caVMaterialKey (caVLeaf node.material (getFaceMatID m face)))!=(caVWMaterial component originalFace) or getFaceSmoothGroup m face!=(bit.shift 1 (mod originalFace 5)) do appearance=false
                    append worldRows #(component,originalFace,originalCorner,(copy actual),(copy actualNormal),isExplicit)
                )
                append worldTriangles trianglePoints
            )
            if seen.numberSet!=12 do positions=false
            for face=1 to 4 do for pair in #(#(1,2),#(1,3),#(2,3)) do
                if dot evaluatedDirections[(face-1)*3+pair[1]] evaluatedDirections[(face-1)*3+pair[2]]>0.999 do evaluatedNormals=false
        )
        catch (errorText=getCurrentException() as string)
        if p!=undefined and isValidNode p[1] do undo off (delete p[1])
        delete m
        if errorText!=undefined do throw errorText
        caVRequire (label+" part "+(component as string)+": raw world snapshot matches literal geometry and exact +Z displacement") positions
        caVRequire (label+" part "+(component as string)+": evaluated UV1/UV2 retain all literal corner codes") uvCorrect
        caVRecord ("WSM_SOURCE_NORMAL_SCOPE "+label+" component="+(component as string)+" minimumIdealAffineDot="+(minimumAnalyticDot as string)+" target="+(if displacement==0 or component==2 then "literal inverse-transpose control" else "independent evaluated WORLD appearance parity"))
        caVRequire (label+" part "+(component as string)+": literal authored normals remain intact; evaluated WORLD corners are specified, nondegenerate, distinct and pass applicable analytic controls") (authoredNormals and evaluatedNormals)
        caVRequire (label+" part "+(component as string)+": evaluated source materials and smoothing match literal fixture") appearance
        source[5]=worldRows
    )
    if allCodes.numberSet!=24 do throw "WSM fixture did not freeze all 24 independent evaluated source corner codes."
    #(lower,upper,[(lower.x+upper.x)*0.5,(lower.y+upper.y)*0.5,lower.z],allPoints,(caVWBandCenter worldTriangles lower.z))
)
fn caVWSourceState sources head warp =
(
    local rows=#()
    for source in sources do
    (
        local node=source[1],reader=source[2],m=copy node.baseObject.mesh
        caVBindNormals node reader "WSM source preservation, below binding"
        local vertices=for i=1 to m.numverts collect meshop.getVert m i
        local faces=for i=1 to m.numfaces collect #((getFace m i),(getFaceMatID m i),(getFaceSmoothGroup m i))
        local maps=for channel in #(1,2) collect #((for i=1 to (meshop.getNumMapVerts m channel) collect meshop.getMapVert m channel i),(for i=1 to m.numfaces collect meshop.getMapFace m channel i))
        local normals=for i=1 to (reader.GetNumNormals node:node) collect #((reader.GetNormal i node:node),(reader.GetNormalExplicit i node:node))
        local normalFaces=for f=1 to 4 collect (for k=1 to 3 collect #((reader.GetNormalID f k node:node),(reader.GetVertexID f k node:node)))
        local modifiers=for modifier in node.modifiers collect #((classOf modifier as string),(getHandleByAnim modifier))
        local materialRows=for i=1 to m.numfaces collect caVMaterialKey (caVLeaf node.material (getFaceMatID m i))
        local world=caVWWorld node
        local worldProbe=caVWProbe world,worldNormals=#(),worldNormalError=undefined
        try
        (
            for face=1 to world.numfaces do for corner=1 to 3 do
            (
                local marker=caVMapUV world 2 face corner
                local originalFace=(floor ((mod marker.x 1000)/10)) as integer,originalCorner=mod (marker.x as integer) 10
                if ((floor (marker.x/1000)) as integer)!=source[3] or originalFace<1 or originalFace>4 or originalCorner<1 or originalCorner>3 do throw "Source preservation snapshot lost a literal world-normal corner code."
                local key=(originalFace-1)*3+originalCorner,id=worldProbe[2].GetNormalID face corner node:worldProbe[1]
                if worldNormals[key]!=undefined do throw "Source preservation snapshot duplicated a literal world-normal corner code."
                worldNormals[key]=#((copy marker),(normalize (worldProbe[2].GetNormal id node:worldProbe[1])),(worldProbe[2].GetNormalExplicit id node:worldProbe[1]))
            )
            for key=1 to 12 where worldNormals[key]==undefined do throw "Source preservation snapshot is missing an evaluated world normal."
        )
        catch (worldNormalError=getCurrentException() as string)
        if isValidNode worldProbe[1] do undo off (delete worldProbe[1])
        if worldNormalError!=undefined do (delete world;delete m;throw worldNormalError)
        local worldGeometry=#((for i=1 to world.numverts collect meshop.getVert world i),(for i=1 to world.numfaces collect #((getFace world i),(getFaceMatID world i),(getFaceSmoothGroup world i))),(for channel in #(1,2) collect #((for i=1 to (meshop.getNumMapVerts world channel) collect meshop.getMapVert world channel i),(for i=1 to world.numfaces collect meshop.getMapFace world channel i))))
        append rows #((getHandleByAnim node),(copy node.transform),vertices,faces,maps,normals,normalFaces,modifiers,(getHandleByAnim node.material),materialRows,worldGeometry,worldNormals)
        delete world
        delete m
    )
    #(rows,(copy head.transform),(for child in head.children collect getHandleByAnim child),(getHandleByAnim warp),(copy warp.transform),warp.strength,warp.decay,warp.mapType,warp.lumCenterEnable)
)
fn caVWYaw value degrees =
(
    local c=cos degrees,s=sin degrees
    [c*value.x-s*value.y,s*value.x+c*value.y,value.z]
)
fn caVWExpectedPoint sources component face corner =
(
    local found=undefined
    for source in sources where source[3]==component do for row in source[5] where row[2]==face and row[3]==corner do found=row[4]
    if found==undefined do throw "Missing independent WSM source corner."
    found
)
fn caVWExpectedNormal sources component face corner =
(
    local found=undefined
    for source in sources where source[3]==component do for row in source[5] where row[2]==face and row[3]==corner do
    (
        if not row[6] do throw "Expected evaluated source normal was not specified."
        found=row[5]
    )
    if found==undefined do throw "Missing frozen independent evaluated WORLD source normal."
    found
)
fn caVWRows setup = for row in caOutputRows setup collect #(row[1],row[2],row[3],(copy row[4]),row[5],row[6],row[7],row[8])
fn caVWVerify setup sources geometry assetID label =
(
    local rows=caOutputRows setup,bodyCenter=geometry[3],anchor=geometry[5][1],size=geometry[2]-geometry[1]
    caVRequire (label+": produces one or two real full-scale source assemblies") (rows.count>0 and rows.count<=2)
    local positions=true,dimensions=true,contact=true,uv1=true,uv2=true,materials=true,smoothing=true,normals=true,flags=true,winding=true,topology=true
    local testedNormals=0,minimumNormalDot=1.0,normalDiagnostics=0
    local totalCorners=0,minimumOldError=1e20,wrongOldCenterRejected=true,sizeParity=true
    for row in rows do
    (
        local node=row[9],m=caVWWorld node,p=undefined,errorText=undefined,seen=#{}
        local lower=[1e20,1e20,1e20],upper=[-1e20,-1e20,-1e20]
        local maximumPositionError=0.0,maximumOldResidualError=0.0,firstOldResidual=undefined
        local expectedOldResidual=(caVWYaw (bodyCenter-anchor) row[5])*row[6]
        try
        (
            p=caVWProbe m
            if m.numfaces!=8 or m.numverts!=8 do topology=false
            if row[2]!=assetID or row[6]!=1 or row[8]!=0 do contact=false
            for face=1 to m.numfaces do
            (
                local indices=getFace m face
                for corner=1 to 3 do
                (
                    local marker=caVMapUV m 2 face corner
                    local component=(floor (marker.x/1000)) as integer
                    local originalFace=(floor ((mod marker.x 1000)/10)) as integer,originalCorner=mod (marker.x as integer) 10
                    if component<1 or component>2 or originalFace<1 or originalFace>4 or originalCorner<1 or originalCorner>3 then throw "WSM output lost literal corner identity."
                    local key=(component-1)*12+(originalFace-1)*3+originalCorner
                    if seen[key] do topology=false
                    seen[key]=true
                    local wanted=row[4]+(caVWYaw ((caVWExpectedPoint sources component originalFace originalCorner)-anchor) row[5])*row[6]
                    local actual=meshop.getVert m (indices[corner] as integer)
                    local positionError=distance actual wanted
                    if positionError>0.003 do positions=false
                    maximumPositionError=amax #(maximumPositionError,positionError)
                    local oldWanted=row[4]+(caVWYaw ((caVWExpectedPoint sources component originalFace originalCorner)-bodyCenter) row[5])*row[6]
                    local oldResidual=actual-oldWanted,oldError=distance actual oldWanted,residualError=distance oldResidual expectedOldResidual
                    totalCorners+=1;minimumOldError=amin #(minimumOldError,oldError)
                    maximumOldResidualError=amax #(maximumOldResidualError,residualError)
                    if firstOldResidual==undefined do firstOldResidual=copy oldResidual
                    if oldError<=0.003 or residualError>0.003 do wrongOldCenterRejected=false
                    for axis=1 to 3 do (lower[axis]=amin #(lower[axis],actual[axis]);upper[axis]=amax #(upper[axis],actual[axis]))
                    if distance (caVMapUV m 1 face corner) (caVWUV component 1 originalFace originalCorner)>0.0001 do uv1=false
                    if distance marker (caVWUV component 2 originalFace originalCorner)>0.0001 do uv2=false
                    if (caVMaterialKey (caVLeaf node.material (getFaceMatID m face)))!=(caVWMaterial component originalFace) do materials=false
                    if getFaceSmoothGroup m face!=(bit.shift 1 (mod originalFace 5)) do smoothing=false
                    local normalID=p[2].GetNormalID face corner node:p[1]
                    if not (p[2].GetNormalExplicit normalID node:p[1]) do flags=false
                    -- Frozen before Generate from an independent SOURCE world
                    -- snapshot. It already includes the actual WSM pipeline;
                    -- only the placement yaw remains, with no extra node TM.
                    local expectedNormal=caVWYaw (caVWExpectedNormal sources component originalFace originalCorner) row[5]
                    local actualNormal=normalize (p[2].GetNormal normalID node:p[1]),normalDot=dot actualNormal expectedNormal
                    testedNormals+=1;minimumNormalDot=amin #(minimumNormalDot,normalDot)
                    if normalDot<0.9999 do
                    (
                        normals=false
                        if normalDiagnostics<3 do
                        (
                            caVRecord ("WSM_OUTPUT_NORMAL "+label+" component="+(component as string)+" face="+(originalFace as string)+" corner="+(originalCorner as string)+" expected="+(expectedNormal as string)+" actual="+(actualNormal as string)+" dot="+(normalDot as string))
                            normalDiagnostics+=1
                        )
                    )
                )
                local marker=caVMapUV m 2 face 1,component=(floor (marker.x/1000)) as integer,originalFace=(floor ((mod marker.x 1000)/10)) as integer
                local v=caVWVertices component,ids=(caVWFaces())[originalFace]
                local literalGeometric=normalize (cross (v[ids.y as integer]-v[ids.x as integer]) (v[ids.z as integer]-v[ids.x as integer]))
                local expectedGeometric=caVWYaw (caVNormal literalGeometric sources[component][4]) row[5]
                local actualGeometric=normalize (cross ((meshop.getVert m (indices.y as integer))-(meshop.getVert m (indices.x as integer))) ((meshop.getVert m (indices.z as integer))-(meshop.getVert m (indices.x as integer))))
                if dot actualGeometric expectedGeometric<0.9999 do winding=false
            )
            if seen.numberSet!=24 do topology=false
            local expectedMin=[1e20,1e20,1e20],expectedMax=[-1e20,-1e20,-1e20]
            for point in geometry[4] do
            (
                local wanted=row[4]+(caVWYaw (point-anchor) row[5])*row[6]
                for axis=1 to 3 do (expectedMin[axis]=amin #(expectedMin[axis],wanted[axis]);expectedMax[axis]=amax #(expectedMax[axis],wanted[axis]))
            )
            if distance lower expectedMin>0.003 or distance upper expectedMax>0.003 do dimensions=false
            local actualSize=upper-lower,expectedSize=expectedMax-expectedMin,sizeError=distance actualSize expectedSize
            if sizeError>0.003 do sizeParity=false
            caVRecord ("WSM_ANCHOR_RESIDUAL "+label+" output="+node.name+" bodyC="+(bodyCenter as string)+" independentBandB="+(anchor as string)+" canonicalA="+((anchor-bodyCenter)as string)+" bandPoints="+(geometry[5][4]as string)+" expectedOldResidual="+(expectedOldResidual as string)+" firstActualOldResidual="+(firstOldResidual as string)+" maxOldResidualErrorMM="+(maximumOldResidualError as string)+" maxCorrectedCornerErrorMM="+(maximumPositionError as string)+" actualSize="+(actualSize as string)+" expectedSize="+(expectedSize as string)+" sizeErrorMM="+(sizeError as string))
            if abs(lower.z-500)>0.003 or abs(row[4].z-500)>0.003 or lower.x< -600-0.003 or upper.x>600+0.003 or lower.y< -350-0.003 or upper.y>350+0.003 do contact=false
        )
        catch (errorText=getCurrentException() as string)
        if p!=undefined and isValidNode p[1] do undo off (delete p[1])
        delete m
        if errorText!=undefined do throw errorText
    )
    local catalog=caAssetRows setup,support=caAssetSupport setup assetID
    caVRecord ("WSM_NORMAL_SUMMARY "+label+" tested="+(testedNormals as string)+" minimumDot="+(minimumNormalDot as string))
    caVCheck (label+": native numeric dimensions match independently evaluated mixed-group world bounds") (catalog.count==1 and distance catalog[1][4] size<0.003)
    caVCheck (label+": derived contact anchor matches independent bottom-band center while canonical bounds retain body-center normalization") (distance support[1] (anchor-bodyCenter)<0.003 and distance support[8] (geometry[1]-bodyCenter)<0.003 and distance support[9] (geometry[2]-bodyCenter)<0.003)
    caVCheck (label+": literal-source bottom band has a nonzero contact-center offset from the full body") (length(anchor-bodyCenter)>1.0 and geometry[5][4]>0)
    caVCheck (label+": wrong old body-center prediction misses every actual corner by the independently predicted rigid offset") (totalCorners>0 and minimumOldError>1.0 and wrongOldCenterRejected)
    caVCheck (label+": actual generated width depth height equal the full transformed source dimensions independently of origin") sizeParity
    caVCheck (label+": every generated world corner equals raw world snapshot minus independent anchor, then record yaw/scale/contact") positions
    caVCheck (label+": full actual generated dimensions match all source world points") dimensions
    caVCheck (label+": actual geometry and record anchor contact literal 500mm support within physical table bounds") contact
    caVCheck (label+": complete eight-triangle topology retains every literal source corner exactly once") topology
    caVCheck (label+": UV1 literal face/corner values survive WSM source capture") uv1
    caVCheck (label+": UV2 literal face/corner identities survive WSM source capture") uv2
    caVCheck (label+": resolved sparse materials and checker map channels match literal source appearance") materials
    caVCheck (label+": literal smoothing groups survive WSM source capture") smoothing
    caVCheck (label+": evaluated authored explicit normal flags survive capture") flags
    caVCheck (label+": every generated WORLD normal preserves frozen evaluated source appearance with placement yaw only") normals
    caVCheck (label+": geometric winding follows independently transformed literal outward face normals") winding
)
fn caVWRun =
(
    caVRecord "STAGE independent mixed accessory group with actual uniform world-space Displace"
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1
    local red=standardMaterial name:"CA_WSM_Red" diffuse:(color 190 45 30)
    local green=standardMaterial name:"CA_WSM_Green" diffuse:(color 40 150 70)
    local blue=standardMaterial name:"CA_WSM_Blue" diffuse:(color 40 70 180)
    red.diffuseMap=checker name:"CA_WSM_Checker_UV1" color1:white color2:black
    red.diffuseMap.coords.mapChannel=1
    green.diffuseMap=checker name:"CA_WSM_Checker_UV2" color1:black color2:white
    green.diffuseMap.coords.mapChannel=2
    local multi=multiMaterial numsubs:2 name:"CA_WSM_SparseMulti"
    multi.materialList=#(green,blue);multi.materialIDList=#(3,7)
    local firstTM=(scaleMatrix [1.2,0.7,1.3])*(rotateZMatrix 23)
    firstTM.row4=[2450,-20,45]
    local secondTM=(scaleMatrix [-1.1,0.8,1.1])*(rotateZMatrix -17)
    secondTM.row4=[2530,25,0]
    local first=caVWAuthor 1 firstTM red,second=caVWAuthor 2 secondTM multi
    local sources=#(first,second),head=group #(first[1],second[1]) name:"CA_WSM_MIXED_SOURCE"
    setGroupOpen head true
    local baseline=caVWRead sources 0 "Before binding"
    local originalTM=copy first[1].transform
    local warp=spaceDisplace name:"CA_WSM_UNIFORM_POSITIVE_Z" strength:35 decay:0 maptype:0 width:10000 length:10000 height:10000 pos:[0,0,0]
    warp.lumCenterEnable=false
    in coordsys world (warp.transform=matrix3 1)
    bindSpaceWarp first[1] warp
    local geometry=caVWRead sources 35 "Bound +35mm"
    caVRequire "Actual accessory WSM binding leaves NodeTM unchanged, has identity +Z warp basis and changes group height by exactly 35mm" ((deepEqual #(originalTM) #(first[1].transform) strictCompare:true) and (deepEqual #(warp.transform) #(matrix3 1) strictCompare:true) and abs(geometry[2].z-baseline[2].z-35)<0.003 and first[1].modifiers.count==2 and second[1].modifiers.count==1)
    local sourceBefore=caVWSourceState sources head warp
    local table=box name:"CA_WSM_SUPPORT" width:1200 length:700 height:30 pos:[0,0,470]
    local setup=caCreateSetup #(table) 1
    setup.name="CA_WSM_ACCESSORY_SETUP"
    local assetID=caRegisterAsset setup head "Actual WSM mixed visual assembly" 7 31 #(0.0,90.0) 1.0 1.0 1.0 false
    local settings=(caSetupSummary setup)[9]
    settings[1]=707;settings[2]=0.15;settings[3]=20;settings[4]=15;settings[5]=0;settings[6]=0;settings[7]=0.2;settings[10]=25;settings[11]=false
    caSetArrangeSettings setup settings
    local rules=caCategoryRules setup 1
    for rule in rules do (rule[2]=1;rule[3]=if rule[1]==7 then 2 else 0;rule[4]=false)
    caSetCategoryRules setup 1 rules
    caSetCollisionScope setup #() false
    caVCheck "WSM asset registration preserves complete base mesh, transforms, maps, materials, authored normals, modifiers and warp" (deepEqual sourceBefore (caVWSourceState sources head warp) strictCompare:true)
    -- This visual fixture needs two copies, independent of descriptive old caps.
    local quantitySettings=caPlacementSettings setup
    quantitySettings[2]=2;quantitySettings[3]=2
    local initialResult=caGeneratePlacement setup quantitySettings false
    caVWVerify setup sources geometry assetID "WSM initial Generate"
    caVCheck "WSM initial generation preserves complete source state" (deepEqual sourceBefore (caVWSourceState sources head warp) strictCompare:true)
    local originalRows=caVWRows setup
    local repeatedResult=caGenerate setup #()
    caVCheck "WSM repeated generation preserves every complete logical placement field and all six result fields" ((deepEqual originalRows (caVWRows setup) strictCompare:true) and (deepEqual initialResult repeatedResult strictCompare:true))
    caVWVerify setup sources geometry assetID "WSM repeat Generate"
    caVCheck "WSM repeated generation preserves complete source state" (deepEqual sourceBefore (caVWSourceState sources head warp) strictCompare:true)
    warp.strength=60
    geometry=caVWRead sources 60 "Edited +60mm"
    sourceBefore=caVWSourceState sources head warp
    caGenerate setup #()
    caVWVerify setup sources geometry assetID "WSM edited source Generate"
    caVCheck "WSM edited-source generation preserves complete current source state" (deepEqual sourceBefore (caVWSourceState sources head warp) strictCompare:true)
    local path=CA_TEST_OUTPUT+"native-visual-wsm-accessory.max"
    caVRequire "Save independent WSM accessory evidence scene" (saveMaxFile path quiet:true)
    caVRecord "WSM_SCOPE literal world geometry/UV/material/winding and untouched authored normals; generated specified normals match independently frozen evaluated WORLD SOURCE appearance, which Max may change during WSM evaluation. One uniformly translated bound nonuniform/rotated part, one unbound mirrored part; no ideal-normal correction, arbitrary nonlinear WSM, renderer or performance claim."
)

try
(
    local normalDetails = createFile (CA_TEST_OUTPUT + "visual-normal-details.txt")
    format "Bounded independent authored-normal diagnostics; alternatives do not change acceptance.\n" to:normalDetails
    close normalDetails
    caVRecord "STAGE original three-part source fixture"
    local fixture = caVFixture(), setup = fixture[1], sources = fixture[2]
    local expected = caVExpected sources
    caVRecord "STAGE first outer-hold generation"
    undo "Visual first generation outer hold" on (caGenerate setup #())
    caVVerify setup expected "Initial generation"
    caVCheck "Initial generation preserves complete source state" ((caVSourceState sources) == fixture[3])
    for cycle = 1 to 3 do
    (
        caVRecord ("STAGE repeat material generation / Undo / Redo " + (cycle as string))
        local before = caVRows setup
        local settings = (caSetupSummary setup)[9]; settings[1] += 1
        undo "Visual repeated generation outer hold" on (caSetArrangeSettings setup settings; caGenerate setup #())
        local after = caVRows setup
        max undo
        caVCheck ("Cycle " + (cycle as string) + " Undo restores native records and node ownership") ((caVRows setup) == before)
        max redo
        caVCheck ("Cycle " + (cycle as string) + " Redo restores complete successor") ((caVRows setup) == after)
        caVVerify setup expected ("Cycle " + (cycle as string))
        caVCheck ("Cycle " + (cycle as string) + " source state remains unchanged") ((caVSourceState sources) == fixture[3])
    )
    caVRecord "STAGE save/reopen visual channels"
    local scene = CA_TEST_OUTPUT + "native-visual-regression.max"
    saveMaxFile scene quiet:true
    loadMaxFile scene useFileUnits:true quiet:true
    setup = getNodeByName "CA_VISUAL_SETUP"
    sources = #()
    for label in #("CA_VISUAL_PartA","CA_VISUAL_PartB","CA_VISUAL_PartC") do
    (
        local node = getNodeByName label
        append sources #(node,node.modifiers[1])
    )
    expected = caVExpected sources
    caVVerify setup expected "Reopened output"
    undo "Visual reopened generation outer hold" on (caGenerate setup #())
    max undo
    max redo
    caVVerify setup expected "Reopened generation Undo/Redo"
    caVWRun()
)
catch
(
    local message = getCurrentException() as string
    local stack = getCurrentExceptionStackTrace() as string
    caVFailures += 1
    caVRecord ("ERROR " + message + " | context=" + caVContext)
    local detail = createFile (CA_TEST_OUTPUT + "visual-exception-stack.txt")
    format "%\ncontext=%\n%\n" message caVContext stack to:detail
    close detail
)
caVFinished = true
caVWrite()
