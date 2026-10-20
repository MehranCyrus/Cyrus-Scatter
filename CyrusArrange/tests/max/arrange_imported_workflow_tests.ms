/* Imported-model workflow regression. Isolated, root-controlled Max2027 process only.
   No source model is scaled, decimated, reoriented or repaired. Imported roots
   are grouped/translated explicitly; all original nodes remain in the scene.
   Orchestration requires a passed matching import probe before execution. No other test is fileIn'd.
   Optional Standard-diffuse/transparent-cover + Default Scanline renders run
   only after all non-render checks pass. Not an original PBR-fidelity claim. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI,CA_IMPORTED_RENDER
global CA_IMPORT_ASSET_ROOT,CA_IMPORT_SOURCE_MANIFEST_SHA256,CA_IMPORT_FILES,CA_IMPORT_CASES
global FBXImporterGetParam,FBXImporterSetParam
global caShowAdvancedArrangeUI,caArrangeUI,caShowAssetUI,caAssetUI
global caCreateSetup,caSetupSummary,caAnalyzeSetup,caRegionRows,caSetRegionRules
global caAssetRows,caAssetDetail,caAssetSupport,caCategoryRules,caSetCategoryRules,caSetCollisionScope
global caGenerate,caOutputRows,caCompositionRows,caCompositionStats,caPreviewInfo,caPreviewBounds
global caIWLog=#(),caIWPasses=0,caIWFailures=0,caIWFinished=false,caIWContext="initialization"
global caIWWrite,caIWNote,caIWStage,caIWCheck,caIWRequire,caIWNum,caIWCSV,caIWHash,caIWFinite
global caIWGeometry,caIWReadMesh,caIWMeshBounds,caIWLeaf,caIWMaterialKey,caIWMapName,caIWAdaptMaterial
global caIWMeshSignature,caRelocateImportedTextures,caImportedTexturePaths
global caIWMaterialInventory
global caIWAssets,caIWImports,caIWSetting,caIWReadSettings,caIWSettingsEqual,caIWConfigure,caIWSourceFiles
global caIWImportOne,caIWSourceRecord,caIWSourceSame,caIWFind,caIWCapture,caIWSame,caIWOnePose
global caIWHitXY,caIWTriangleBox,caIWPhysical,caIWVerifyVisual,caIWVisualInventory,caIWValidate
global caIWCreateCase,caIWBind,caIWConfigureUI,caIWRegister,caIWRegionRules,caIWRecipe,caIWRepeat
global caIWInitial,caIWReroll,caIWProtection,caIWPreviewCommit,caIWSave,caIWReload
global caIWPortable
global caIWLayer,caIWAssign,caIWHide,caIWCamera,caIWStageScene,caIWRender,caIWBootstrap
global caIWSourceRecords=#(),caIWFixtures=#(),caIWCameras=#(),caIWImporter=undefined,caIWSeenModels=#()

fn caIWWrite=
(
    if CA_TEST_OUTPUT!=undefined do
    (
        local stream=createFile (CA_TEST_OUTPUT+"result.txt")
        format "% passes=% failures=%\n" (if caIWFinished then (if caIWFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caIWPasses caIWFailures to:stream
        for line in caIWLog do format "%\n" line to:stream
        flush stream;close stream
    )
    true
)
fn caIWNote line=(append caIWLog line;caIWWrite();true)
fn caIWStage line=(caIWContext=line;caIWNote ("STAGE "+line))
fn caIWCheck label value=
(
    if value then (caIWPasses+=1;caIWNote ("PASS "+label))
    else
    (
        caIWFailures+=1;caIWNote ("FAIL "+label)
        if caArrangeUI!=undefined do try(caIWNote ("WORKFLOW_STATUS "+caArrangeUI.statusText.text))catch()
        if caAssetUI!=undefined do try(caIWNote ("ASSET_STATUS "+caAssetUI.statusText.text))catch()
    )
    value
)
fn caIWRequire label value=(caIWCheck label value;if not value do throw ("Prerequisite: "+label);true)
fn caIWNum value=
(
    if value==undefined then "undefined"
    else if classOf value==String then value
    else if classOf value==Integer then value as string
    else if classOf value==Integer64 then trimRight (value as string) "Ll"
    else if classOf value==IntegerPtr then trimRight ((value as Integer64) as string) "Ll"
    else if classOf value==Float or classOf value==Double then (dotNetClass "System.Convert").ToString value (dotNetClass "System.Globalization.CultureInfo").InvariantCulture
    else value as string
)
fn caIWCSV filename values=
(
    local stream=openFile (CA_TEST_OUTPUT+filename) mode:"a"
    if stream==undefined do throw ("Cannot append "+filename)
    for i=1 to values.count do
    (
        if i>1 do format "," to:stream
        format "\"%\"" (substituteString (caIWNum values[i]) "\"" "\"\"") to:stream
    )
    format "\n" to:stream;flush stream;close stream
)
fn caIWHash path=
(
    local stream=undefined,hasher=undefined,result=undefined,problem=undefined
    try
    (
        stream=(dotNetClass "System.IO.File").OpenRead path
        hasher=(dotNetClass "System.Security.Cryptography.SHA256").Create()
        result=toLower (substituteString ((dotNetClass "System.BitConverter").ToString (hasher.ComputeHash stream)) "-" "")
    ) catch (problem=getCurrentException() as string)
    if stream!=undefined do stream.Close()
    if hasher!=undefined do hasher.Dispose()
    if problem!=undefined do throw problem
    result
)
fn caIWFinite p=((classOf p)==Point3 and p.x==p.x and p.y==p.y and p.z==p.z and abs p.x<1e20 and abs p.y<1e20 and abs p.z<1e20)
fn caIWGeometry root=
(
    local pending=#(root),result=#(),visited=#()
    while pending.count>0 do
    (
        local node=pending[pending.count];deleteItem pending pending.count
        if not isValidNode node do throw "Missing imported source node."
        if (findItem visited node)==0 do
        (
            append visited node
            for child in node.children do append pending child
            if not (isGroupHead node) and (superClassOf node)==GeometryClass do append result node
        )
        if visited.count+pending.count>4096 do throw "Imported hierarchy exceeds4096 nodes."
    )
    result
)
fn caIWReadMesh node=
(
    -- Independent WORLD snapshot, including evaluated modifiers. No node is
    -- created/deleted and no ObjectTM is applied a second time.
    local result=undefined
    in coordsys world (result=snapshotAsMesh node renderMesh:false)
    if result==undefined or result.numverts>300000 or result.numfaces>100000 do throw "Mesh snapshot missing or exceeds admitted import size."
    result
)
fn caIWMeshBounds meshValue=
(
    if meshValue.numverts==0 do throw "Cannot bound an empty vertex collection."
    local low=[1e30,1e30,1e30],high=[-1e30,-1e30,-1e30]
    for i=1 to meshValue.numverts do
    (
        local p=meshop.getVert meshValue i
        if not (caIWFinite p) do throw "Nonfinite actual world vertex."
        for axis=1 to 3 do (low[axis]=amin #(low[axis],p[axis]);high[axis]=amax #(high[axis],p[axis]))
    )
    #(low,high)
)
fn caIWMeshSignature meshValue=
(
    local vertices=for i=1 to meshValue.numverts collect (meshop.getVert meshValue i)
    local faces=for i=1 to meshValue.numfaces collect #((getFace meshValue i),(getFaceMatID meshValue i),(getFaceSmoothGroup meshValue i),(meshop.getFaceRNormals meshValue i))
    local maps=#(),count=meshop.getNumMaps meshValue
    if count>16 do throw "Imported mapping admission exceeds16."
    for channel=-2 to (count-1) do if meshop.getMapSupport meshValue channel do
    (
        local nv=meshop.getNumMapVerts meshValue channel,nf=meshop.getNumMapFaces meshValue channel
        local uv=for i=1 to nv collect (meshop.getMapVert meshValue channel i)
        local indices=for i=1 to nf collect (meshop.getMapFace meshValue channel i)
        append maps #(channel,uv,indices)
    )
    #(vertices,faces,maps)
)
fn caIWLeaf materialValue id=
(
    if materialValue==undefined then undefined
    else if (classOf materialValue)==Multimaterial then
    (
        local found=undefined
        for i=1 to materialValue.materialIDList.count where materialValue.materialIDList[i]==id do found=materialValue.materialList[i]
        found
    )
    else materialValue
)
fn caIWMaterialKey materialValue fullPaths:false=
(
    if materialValue==undefined then #(undefined)
    else
    (
        if (classOf materialValue)!=Standardmaterial do throw "Expected declared Standard adapter at every used material leaf."
        local mapValue=materialValue.diffuseMap
        #(materialValue.name+"",(copy materialValue.diffuse),materialValue.opacity,materialValue.diffuseMapEnable,materialValue.diffuseMapAmount,
          (if mapValue==undefined then undefined else if fullPaths then mapValue.filename+"" else (getFilenameFile mapValue.filename)+(getFilenameType mapValue.filename)),
          (if mapValue==undefined then undefined else mapValue.coords.mapChannel),(if mapValue==undefined then undefined else classOf mapValue))
    )
)
fn caIWMaterialInventory materialValue meshValue fullPaths:false=
(
    local used=#(),result=#()
    for face=1 to meshValue.numfaces do appendIfUnique used (getFaceMatID meshValue face)
    for id in used do append result #(id,(caIWMaterialKey (caIWLeaf materialValue id) fullPaths:fullPaths))
    result
)
fn caIWMapName assetID originalName=
(
    -- Exact leaf names verified by same-candidate probe04.
    -- Unknown leaves fail instead of guessing a PBR conversion.
    case (assetID+"/"+originalName) of
    (
        "modern_wooden_cabinet/modern_wooden_cabinet": "modern_wooden_cabinet_diff_1k.jpg"
        "wooden_bookshelf_worn/wooden_bookshelf_worn": "wooden_bookshelf_worn_diff_1k.jpg"
        "standing_picture_frame_02/standing_picture_frame_02_artwork": "standing_picture_frame_02_artwork_diff_1k.png"
        "standing_picture_frame_02/standing_picture_frame_02": "standing_picture_frame_02_diff_1k.jpg"
        "standing_picture_frame_02/standing_picture_frame_02_glass": "TRANSPARENT_COVER"
        "ceramic_vase_02/ceramic_vase_02": "ceramic_vase_02_diff_1k.jpg"
        "wooden_bowl_02/wooden_bowl_02": "wooden_bowl_02_diff_1k.jpg"
        default: throw ("Unapproved imported material leaf: "+assetID+"/"+originalName)
    )
)
fn caIWAdaptMaterial assetID original depth:0=
(
    if original==undefined or depth>8 do throw "Missing/too-deep imported material."
    if (classOf original)==Multimaterial then
    (
        local count=getNumSubMtls original
        if count<1 or count>32 do throw "Imported MultiMaterial exceeds admitted slots."
        local adapted=multimaterial name:("CA_IMPORTED_STD_"+original.name) numsubs:count
        adapted.materialIDList=for id in original.materialIDList collect id
        for i=1 to count do
        (
            local child=getSubMtl original i
            if child==undefined then adapted.materialList[i]=undefined
            else adapted.materialList[i]=caIWAdaptMaterial assetID child depth:(depth+1)
        )
        adapted
    )
    else
    (
        if (getNumSubMtls original)!=0 do throw "Unapproved nested imported material class."
        local mapName=caIWMapName assetID original.name
        local adapted=standardMaterial name:("CA_IMPORTED_STD_"+original.name) diffuse:white
        if mapName=="TRANSPARENT_COVER" then
        (
            -- Deliberate simple transparent cover; retained glass triangles,
            -- not physical refraction or a source-PBR appearance guarantee.
            adapted.opacity=8;adapted.specularLevel=35;adapted.glossiness=50
        )
        else
        (
            local path=CA_TEST_OUTPUT+"inputs/assets/"+assetID+"/textures/"+mapName
            if not (doesFileExist path) do throw ("Missing pinned diffuse map: "+path)
            local mapValue=bitmapTexture name:("CA_IMPORTED_MAP_"+original.name) filename:path
            mapValue.coords.mapChannel=1
            adapted.diffuseMap=mapValue;adapted.diffuseMapEnable=true;adapted.diffuseMapAmount=100
            adapted.specularLevel=12;adapted.glossiness=25
        )
        caIWCSV "material-adapter.csv" #(assetID,original.name,classOf original,adapted.name,classOf adapted,mapName,adapted.opacity,"explicit declared approximation; original geometry/UV retained")
        adapted
    )
)
fn caIWSetting key wanted=
(
    local result=FBXImporterSetParam key wanted,actual=FBXImporterGetParam key
    local same=if (classOf wanted)==String or (classOf wanted)==Name then (toLower (trimLeft (actual as string) "#"))==(toLower (trimLeft (wanted as string) "#")) else actual==wanted
    caIWCSV "import-settings.csv" #(caIWContext,key,wanted,result,actual,classOf actual)
    caIWRequire ("FBX supports/readbacks "+key) (result!=unsupplied and same)
)
fn caIWReadSettings=
(
    local rows=#()
    for key in #("Mode","Animation","Cameras","Lights","Skin","Shape","PointCache","SmoothingGroups","AxisConversion","ScaleConversion","ConvertUnit","UpAxis","ScaleFactor","GenerateLog","Environment","GlobalAmbientColor","FillTimeline") do
    (
        local actual=FBXImporterGetParam key
        if actual==unsupplied do throw ("Documented FBX getter unsupported: "+key)
        append rows #(key,actual)
    )
    rows
)
fn caIWSettingsEqual a b=(deepEqual a b strictCompare:true)
fn caIWConfigure=
(
    caIWRequire "FBX reset supported" ((FBXImporterSetParam "ResetImport")!=unsupplied)
    local rows=#(#("Mode",#create),#("Animation",false),#("Cameras",false),#("Lights",false),#("Skin",false),#("Shape",false),#("PointCache",false),#("Environment",false),#("GlobalAmbientColor",false),#("FillTimeline",false),#("GenerateLog",false),#("SmoothingGroups",true),#("AxisConversion",true),#("ConvertUnit","mm"),#("ScaleConversion",true),#("UpAxis","Z"))
    for row in rows do caIWSetting row[1] row[2]
    for row in rows do
    (
        local actual=FBXImporterGetParam row[1],wanted=row[2]
        local same=if (classOf wanted)==String or (classOf wanted)==Name then (toLower (trimLeft (actual as string) "#"))==(toLower (trimLeft (wanted as string) "#")) else actual==wanted
        caIWRequire ("interdependent FBX readback "+row[1]) same
    )
)
fn caIWSourceFiles copyInputs:false=
(
    local io=dotNetClass "System.IO.Path"
    local base=substituteString (io.GetFullPath CA_IMPORT_ASSET_ROOT) "\\" "/"
    if not (matchPattern base pattern:"*/") do base+="/"
    caIWRequire "frozen original download manifest identity" ((caIWHash (base+"asset-download-manifest.json"))==CA_IMPORT_SOURCE_MANIFEST_SHA256)
    for row in CA_IMPORT_FILES do
    (
        local source=substituteString (io.GetFullPath (base+row[2])) "\\" "/",target=CA_TEST_OUTPUT+"inputs/"+row[2]
        caIWRequire ("bounded original source "+row[2]) ((findString (toLower source) (toLower base))==1 and doesFileExist source)
        caIWRequire ("exact original bytes "+row[2]) ((caIWHash source)==row[3] and (dotNetObject "System.IO.FileInfo" source).Length==row[4])
        if copyInputs do
        (
            makeDir (getFilenamePath target) all:true
            if doesFileExist target do throw "Owned input copy unexpectedly exists."
            caIWRequire ("private pinned input copy "+row[2]) ((copyFile source target) and (caIWHash target)==row[3])
            caIWCSV "source-provenance.csv" #(row[1],row[2],row[3],row[4],row[5],"CC0-1.0",CA_IMPORT_SOURCE_MANIFEST_SHA256)
        )
    )
)
fn caIWImportOne caseRow destination=
(
    local assetID=caseRow[1]
    caIWStage ("import/adapt "+assetID)
    caIWConfigure()
    local before=for node in objects collect getHandleByAnim node
    caIWRequire (assetID+" FBX import succeeds") (importFile (CA_TEST_OUTPUT+"inputs/"+caseRow[2]) #noPrompt using:caIWImporter quiet:true)
    local imported=for node in objects where (findItem before (getHandleByAnim node))==0 collect node
    caIWRequire (assetID+" retains bounded actual imported nodes") (imported.count>0 and imported.count<=256)
    local roots=for node in imported where node.parent==undefined or node.parent==rootNode or (findItem imported node.parent)==0 collect node
    if roots.count==0 do throw "Imported assembly has no root."
    local geometry=#(),triangleNodes=#(),low=[1e30,1e30,1e30],high=[-1e30,-1e30,-1e30],faces=0,vertices=0
    for node in imported do
    (
        caIWRequire (assetID+" imports no cameras/lights") ((superClassOf node)!=Camera and (superClassOf node)!=Light)
        if not (isGroupHead node) and (superClassOf node)==GeometryClass do
        (
            append geometry node
            local meshValue=caIWReadMesh node
            vertices+=meshValue.numverts;faces+=meshValue.numfaces
            caIWCSV "imported-geometry.csv" #(assetID,node.name,classOf node,meshValue.numverts,meshValue.numfaces,"all original imported nodes retained; vertex-only nodes have no support triangles")
            if meshValue.numfaces>0 do
            (
                append triangleNodes node
                local bounds=caIWMeshBounds meshValue
                for axis=1 to 3 do (low[axis]=amin #(low[axis],bounds[1][axis]);high[axis]=amax #(high[axis],bounds[2][axis]))
            )
            if node.material!=undefined do
            (
                local originalSignature=caIWMeshSignature meshValue
                node.material=caIWAdaptMaterial assetID node.material
                local adaptedMesh=caIWReadMesh node
                caIWRequire (assetID+" "+node.name+" adapter preserves original geometry/face IDs/smoothing/UVs exactly") (deepEqual originalSignature (caIWMeshSignature adaptedMesh) strictCompare:true)
                caIWCSV "adapter-inputs.csv" #(assetID,node.name,meshValue.numverts,meshValue.numfaces,meshop.getNumMaps meshValue,"pre/post material assignment exact geometry and UV signature; no UV reconstruction")
                delete adaptedMesh
            )
            delete meshValue
        )
    )
    caIWRequire (assetID+" actual nonempty triangle source") (faces>0 and faces<=100000 and vertices<=300000 and triangleNodes.count>0)
    local dimensions=high-low,physical=true
    for axis=1 to 3 do if abs(dimensions[axis]-caseRow[3][axis])>(amax #(5.0,caseRow[3][axis]*0.02)) do physical=false
    caIWRequire (assetID+" source is upright/full physical size without resize") physical
    -- Explicit artist-selected physical parts, based on the probe's actual
    -- inventory. The current plugin rejects a source containing zero-face
    -- geometry; do not silently pretend the entire cabinet import is supported.
    local expectedNames=if assetID=="modern_wooden_cabinet" then #("modern_wooden_cabinet_body","modern_wooden_cabinet_door_l","modern_wooden_cabinet_door_r") else #(assetID)
    local selectedParts=#()
    for expectedName in expectedNames do
    (
        local matched=for node in triangleNodes where node.name==expectedName collect node
        caIWRequire (assetID+" explicit physical part exists once: "+expectedName) (matched.count==1)
        append selectedParts matched[1]
    )
    caIWRequire (assetID+" all actual triangle parts are explicitly selected") (selectedParts.count==triangleNodes.count)
    for node in imported do caIWRequire (assetID+" known original roots before authored grouping") (node.parent==undefined or node.parent==rootNode)
    local shift=destination-[(low.x+high.x)*0.5,(low.y+high.y)*0.5,low.z]
    for node in roots do move node shift
    local assembly=group selectedParts name:("CA_IMPORTED_SOURCE_"+assetID)
    local unbound=for node in imported where (findItem selectedParts node)==0 collect node
    if assetID=="modern_wooden_cabinet" do
    (
        local names=for node in unbound collect node.name
        caIWRequire "cabinet retains exactly both inventoried original path controls unbound" (names.count==2 and (findItem names "modern_wooden_cabinet_path_l")>0 and (findItem names "modern_wooden_cabinet_path_r")>0)
        for node in unbound do
        (
            local controlMesh=caIWReadMesh node
            caIWRequire ("unbound original path has vertices and zero faces: "+node.name) (controlMesh.numverts>0 and controlMesh.numfaces==0)
            delete controlMesh
        )
    )
    for node in unbound do caIWCSV "unbound-original-components.csv" #(assetID,node.name,getHandleByAnim node,"retained original node, explicitly outside physical furniture source")
    caIWCSV "authored-transforms.csv" #(assetID,"explicitly group inventoried triangle parts; translate all original roots only",shift.x,shift.y,shift.z,dimensions.x,dimensions.y,dimensions.z,faces,caseRow[4])
    caIWCSV "credits.csv" #(assetID,caseRow[5],caseRow[6],caseRow[7],"CC0-1.0","https://polyhaven.com/license","Voluntary attribution; no endorsement")
    -- source row: asset slug, group, triangle nodes, original dimensions,
    -- actual face count, category, later captured visual record.
    #(assetID,assembly,triangleNodes,dimensions,faces,0,undefined,unbound,imported)
)

fn caIWSourceRecord sourceRow=
(
    local records=#()
    for node in sourceRow[9] do
    (
        local meshValue=caIWReadMesh node
        append records #(node,node.name+"",(copy node.transform),node.material,meshValue,node.parent,(caIWMaterialInventory node.material meshValue fullPaths:true))
    )
    if sourceRow[6]!=0 do
    (
        caIWRequire (sourceRow[1]+" accessory has one actual triangle mesh for full face/UV/normal comparison") (sourceRow[3].count==1)
        local meshValue=caIWReadMesh sourceRow[3][1],bounds=caIWMeshBounds meshValue
        local anchor=[(bounds[1].x+bounds[2].x)*0.5,(bounds[1].y+bounds[2].y)*0.5,bounds[1].z]
        sourceRow[7]=#(meshValue,anchor,sourceRow[3][1].material,(caIWMaterialInventory sourceRow[3][1].material meshValue))
    )
    records
)
fn caIWSourceSame records=
(
    local same=true
    for row in records while same do
    (
        local node=row[1]
        if not isValidNode node then same=false
        else if node.name!=row[2] or node.material!=row[4] or node.parent!=row[6] then same=false
        else
        (
            local actualTM=node.transform,wantedTM=row[3]
            for i=1 to 4 where actualTM[i]!=wantedTM[i] do same=false
            local meshValue=caIWReadMesh node,wanted=row[5]
            if not (deepEqual (caIWMeshSignature wanted) (caIWMeshSignature meshValue) strictCompare:true) do same=false
            if not (deepEqual row[7] (caIWMaterialInventory node.material meshValue fullPaths:true) strictCompare:true) do same=false
            delete meshValue
        )
    )
    same
)
fn caIWFind rows id=(local found=undefined;for row in rows while found==undefined do if row[1]==id do found=row;found)
fn caIWCapture setup=
(
    local poses=#(),handles=#(),bounds=#(),seen=#()
    for row in (caOutputRows setup) do
    (
        if row.count!=9 or not isValidNode row[9] or (findItem seen row[1])>0 do throw "Missing/duplicate real output binding."
        append seen row[1]
        append poses #(row[1],row[2],row[3],copy row[4],row[5],row[6],row[7],row[8])
        append handles (getHandleByAnim row[9])
        local meshValue=caIWReadMesh row[9],actual=caIWMeshBounds meshValue
        append bounds actual;delete meshValue
    )
    #(poses,caCompositionRows setup,handles,bounds)
)
fn caIWSame a b handles:false=
(
    local same=(deepEqual a[1] b[1] strictCompare:true) and (deepEqual a[2] b[2] strictCompare:true)
    if handles and not (deepEqual a[3] b[3] strictCompare:true) do same=false
    if a[4].count!=b[4].count then same=false
    else for i=1 to a[4].count while same do for k=1 to 2 where distance a[4][i][k] b[4][i][k]>0.03 do same=false
    same
)
fn caIWOnePose a b=(a!=undefined and b!=undefined and (deepEqual a b strictCompare:true))
fn caIWHitXY point a b c=
(
    local denominator=(b.y-c.y)*(a.x-c.x)+(c.x-b.x)*(a.y-c.y)
    if abs denominator<1e-10 then undefined
    else
    (
        local u=((b.y-c.y)*(point.x-c.x)+(c.x-b.x)*(point.y-c.y))/denominator
        local v=((c.y-a.y)*(point.x-c.x)+(a.x-c.x)*(point.y-c.y))/denominator
        local w=1.0-u-v
        if u < -1e-6 or v < -1e-6 or w < -1e-6 then undefined else u*a.z+v*b.z+w*c.z
    )
)
fn caIWTriangleBox a b c low high=
(
    -- Independent triangle-vs-interior-AABB SAT. Trial yaws are explicitly0.
    -- Shrink0.05mm avoids calling numerical contact an interior penetration.
    local center=(low+high)*0.5,half=(high-low)*0.5-[0.05,0.05,0.05]
    if half.x<=0 or half.y<=0 or half.z<=0 then false
    else
    (
        local v=#(a-center,b-center,c-center),separated=false
        for axis=1 to 3 do if amin #(v[1][axis],v[2][axis],v[3][axis])>half[axis] or amax #(v[1][axis],v[2][axis],v[3][axis]) < -half[axis] do separated=true
        if separated then false
        else
        (
            local edges=#(v[2]-v[1],v[3]-v[2],v[1]-v[3]),axes=#(cross (v[2]-v[1]) (v[3]-v[1]))
            for edge in edges do for worldAxis in #([1,0,0],[0,1,0],[0,0,1]) do append axes (cross edge worldAxis)
            for axis in axes while not separated do if (dot axis axis)>1e-14 do
            (
                local projections=#(dot v[1] axis,dot v[2] axis,dot v[3] axis)
                local radius=half.x*abs(axis.x)+half.y*abs(axis.y)+half.z*abs(axis.z)
                if (amin projections)>radius or (amax projections) < -radius do separated=true
            )
            not separated
        )
    )
)
fn caIWVerifyVisual row source=
(
    local output=caIWReadMesh row[9],original=source[7][1],base=source[7][2]
    local vertices=true,topology=true,maps=true,normals=true,materials=true
    if output.numverts!=original.numverts or output.numfaces!=original.numfaces then
        (vertices=false;topology=false;maps=false;normals=false;materials=false)
    else
    (
        for i=1 to output.numverts while vertices do
            if distance (meshop.getVert output i) ((meshop.getVert original i)-base+row[4])>0.03 do vertices=false
        local materialPairs=#()
        for face=1 to output.numfaces do
        (
            if (getFace output face)!=(getFace original face) or (getFaceSmoothGroup output face)!=(getFaceSmoothGroup original face) do topology=false
            local expectedNormals=meshop.getFaceRNormals original face,actualNormals=meshop.getFaceRNormals output face
            if expectedNormals.count!=actualNormals.count then normals=false
            else for corner=1 to expectedNormals.count do
            (
                local expected=expectedNormals[corner],actual=actualNormals[corner]
                if not (caIWFinite expected) or not (caIWFinite actual) then normals=false
                else if length expected>1e-8 and length actual>1e-8 then
                    (if dot (normalize expected) (normalize actual)<0.9999 do normals=false)
                else if length expected>1e-8 or length actual>1e-8 do normals=false
            )
            local expectedID=getFaceMatID original face,actualID=getFaceMatID output face
            if (caIWFind materialPairs expectedID)==undefined do append materialPairs #(expectedID,actualID)
        )
        for pair in materialPairs do
        (
            local frozen=caIWFind source[7][4] pair[1]
            if frozen==undefined do throw "Missing frozen used-material value signature."
            local wanted=frozen[2]
            local actual=caIWMaterialKey (caIWLeaf row[9].material pair[2])
            if not (deepEqual wanted actual strictCompare:true) do materials=false
        )
        -- A source material ID must not map inconsistently on later faces.
        for face=1 to output.numfaces do
        (
            local pair=caIWFind materialPairs (getFaceMatID original face)
            if pair==undefined or pair[2]!=(getFaceMatID output face) do materials=false
        )
        local sourceMaps=meshop.getNumMaps original,outputMaps=meshop.getNumMaps output
        if sourceMaps>16 or outputMaps>16 do throw "Mapping-channel admission exceeded."
        for channel=-2 to (amax #(sourceMaps,outputMaps)-1) do
        (
            local wanted=if channel>=sourceMaps then false else meshop.getMapSupport original channel
            local actual=if channel>=outputMaps then false else meshop.getMapSupport output channel
            if wanted!=actual then maps=false
            else if wanted do
            (
                local nv=meshop.getNumMapVerts original channel,nf=meshop.getNumMapFaces original channel
                if nv!=(meshop.getNumMapVerts output channel) or nf!=(meshop.getNumMapFaces output channel) then maps=false
                else
                (
                    for i=1 to nv while maps do if (meshop.getMapVert original channel i)!=(meshop.getMapVert output channel i) do maps=false
                    for f=1 to nf while maps do if (meshop.getMapFace original channel f)!=(meshop.getMapFace output channel f) do maps=false
                )
            )
        )
    )
    caIWCSV "output-visual-checks.csv" #(caIWContext,row[1],row[2],source[1],output.numverts,output.numfaces,vertices,topology,maps,normals,materials)
    delete output
    #(vertices,topology,maps,normals,materials)
)
fn caIWPhysical fixture snapshot=
(
    local triangles=fixture[5],valid=snapshot[1].count>0,support=true,solid=true,separate=true,scale=true
    for i=1 to snapshot[1].count do
    (
        local row=snapshot[1][i],bounds=snapshot[4][i],low=bounds[1],high=bounds[2]
        if row[5]!=0 or row[6]!=1 or row[8]!=0L or distance row[4] [(low.x+high.x)*0.5,(low.y+high.y)*0.5,low.z]>0.03 do scale=false
        -- Nine physical support probes on the actual full-size output envelope.
        -- This is sampled contact evidence, not complete contact-patch coverage.
        for u in #(0.0,0.5,1.0) do for v in #(0.0,0.5,1.0) do
        (
            local p=[low.x+(high.x-low.x)*u,low.y+(high.y-low.y)*v,low.z],best=undefined
            for triangle in triangles do if triangle[4] do
            (
                local z=caIWHitXY p triangle[1] triangle[2] triangle[3]
                if z!=undefined and z<=low.z+0.05 and (best==undefined or z>best) do best=z
            )
            if best==undefined or abs(low.z-best)>0.05 do support=false
        )
        for triangle in triangles while solid do
            if caIWTriangleBox triangle[1] triangle[2] triangle[3] low high do solid=false
        for j=i+1 to snapshot[1].count do
        (
            local other=snapshot[4][j]
            if (amin #(high.x,other[2].x)-amax #(low.x,other[1].x))>0.05 and
               (amin #(high.y,other[2].y)-amax #(low.y,other[1].y))>0.05 and
               (amin #(high.z,other[2].z)-amax #(low.z,other[1].z))>0.05 do separate=false
        )
    )
    caIWCheck (fixture[1]+" native yaw0/scale1/nonstack contact matches full world envelope") scale
    caIWCheck (fixture[1]+" nine independent triangle contact probes per prop") support
    caIWCheck (fixture[1]+" furniture triangles do not cross prop envelope interiors") solid
    caIWCheck (fixture[1]+" actual axis-aligned prop envelopes do not overlap") separate
    valid and scale and support and solid and separate
)
fn caIWValidate fixture=
(
    local setup=fixture[2],snapshot=caIWCapture setup,rows=caOutputRows setup
    caIWRequire (fixture[1]+" nonempty bounded actual outputs") (rows.count>0 and rows.count<=80)
    caIWCheck (fixture[1]+" ordinary accessories create no book-row relationships") ((caCompositionRows setup).count==0)
    caIWPhysical fixture snapshot
    local combined=#(true,true,true,true,true)
    for row in rows do
    (
        local binding=caIWFind fixture[4] row[2]
        if binding==undefined do throw "Output references an unregistered imported source."
        appendIfUnique caIWSeenModels binding[2][1]
        local checks=caIWVerifyVisual row binding[2]
        for k=1 to combined.count do combined[k]=combined[k] and checks[k]
    )
    for k=1 to 5 do caIWCheck (fixture[1]+" imported output "+(#("all evaluated vertices","face topology/smoothing","mapping topology and UV values","render-corner normals","effective Standard material leaves")[k])+" preserved") combined[k]
    caIWNote ("COUNTS "+fixture[1]+" placements="+(rows.count as string)+" publishedCompositionStats="+((caCompositionStats setup) as string))
    snapshot
)

fn caIWBind setup=
(
    caShowAdvancedArrangeUI setup:setup
    setDialogPos caArrangeUI [-10000,-10000]
    caIWRequire "artist workflow binds existing native setup" (caArrangeUI.currentSetup()==setup and caArrangeUI.onRefresh())
)
fn caIWConfigureUI seed=
(
    caArrangeUI.seedText.text=caIWNum seed
    caArrangeUI.style.selection=2;caArrangeUI.density.value=0.18
    caArrangeUI.spacing.value=45;caArrangeUI.edge.value=20
    caArrangeUI.cluster.value=0.25;caArrangeUI.heightVariation.value=0
    caArrangeUI.emptySpace.value=0.35;caArrangeUI.cellMM.value=25
    caArrangeUI.live.checked=false;caArrangeUI.regionText.text=""
)
fn caIWRegister setup source=
(
    select source[2]
    caIWRequire (source[1]+" real Use selected model/group action") (caAssetUI.useSource.pressed())
    caAssetUI.assetName.text="PolyHaven / "+source[1]
    caAssetUI.category.selection=source[6]
    caAssetUI.allowTV.checked=true;caAssetUI.allowShelf.checked=true
    caAssetUI.allowCoffee.checked=false;caAssetUI.allowCounter.checked=false;caAssetUI.allowDining.checked=false
    caAssetUI.yawText.text="0";caAssetUI.weight.value=1;caAssetUI.minScale.value=1;caAssetUI.maxScale.value=1;caAssetUI.stackable.checked=false
    caIWRequire (source[1]+" real Register new asset action") (caAssetUI.registerButton.pressed())
    local matched=for row in (caAssetRows setup) where row[2]==("PolyHaven / "+source[1]) collect row
    caIWRequire (source[1]+" registered once with real required source") (matched.count==1 and matched[1][10])
    local detail=caAssetDetail setup matched[1][1],support=caAssetSupport setup matched[1][1]
    caIWCheck (source[1]+" explicit category/mask/yaw/fixed scale") (detail[3]==source[6] and detail[4]==3 and detail[5].count==1 and detail[5][1]==0 and detail[7]==1 and detail[8]==1 and not detail[9] and detail[10]==1)
    caIWCheck (source[1]+" actual captured dimensions equal imported world mesh") (distance matched[1][4] source[4]<0.03)
    caIWCheck (source[1]+" default contact anchor is canonical base center") (distance support[1] [0,0,0]<0.0001)
    #(matched[1][1],source)
)
fn caIWRecipe setup category=
(
    local rules=caCategoryRules setup category
    for row in rules do
    (
        row[2]=(1.0 as double);row[4]=false
        row[3]=case row[1] of
        (
            5 : 2
            6 : 2
            8 : 3
            default : 0
        )
    )
    caSetCategoryRules setup category rules
    caIWCheck "explicit Frame/Vase/Bowl regional caps saved" (deepEqual rules (caCategoryRules setup category) strictCompare:true)
)
fn caIWRegionRules setup category label=
(
    caIWStage (label+" analyze and author physical surface roles")
    caIWRequire (label+" native analysis has real surfaces") ((caAnalyzeSetup setup)>0)
    local rows=caRegionRows setup,eligible=#(),highest=-1e30
    for row in rows do
    (
        -- Deliberate artist rule, not semantic compartment recognition.
        -- Require enough measured XY extent for the smallest full-size prop.
        local extent=row[6]-row[5]
        if extent.x>=170 and extent.y>=145 and abs extent.z<0.05 do
        (
            append eligible row[1];highest=amax #(highest,row[5].z)
        )
        caIWCSV "analyzed-surfaces.csv" #(label,row[1],row[5].x,row[5].y,row[5].z,row[6].x,row[6].y,row[6].z,row[7],row[8])
    )
    local active=#()
    for row in rows do
    (
        local enabled=(findItem eligible row[1])>0
        if category==1 do enabled=enabled and abs(row[5].z-highest)<0.05
        local role=if row[8] then 2 else 3
        local name=label+" / support "+(caIWNum row[1])
        caSetRegionRules setup row[1] name label role 176 1.0 false (not enabled) [0,-1,0]
        if enabled do append active row[1]
        caIWCSV "authored-surfaces.csv" #(label,row[1],name,role,176,1.0,false,not enabled,0,-1,0,"manual -Y front; verify actual view before gallery acceptance")
    )
    caIWRequire (label+" chosen intended supports exist") (active.count >= (if category==1 then 1 else 2))
    active
)
fn caIWCreateCase source category accessories seed=
(
    local label=if category==1 then "TV" else "SHELF"
    caIWStage (label+" artist setup and accessory registration")
    caShowAdvancedArrangeUI();setDialogPos caArrangeUI [-10000,-10000]
    caArrangeUI.category.selection=category;select source[2]
    caIWRequire (label+" real Create from selected furniture action") (caArrangeUI.createButton.pressed())
    local setup=caArrangeUI.currentSetup()
    setup.name="CA_IMPORTED_SETUP_"+label
    caIWRequire (label+" real Asset Library action") (caArrangeUI.assetsButton.pressed())
    setDialogPos caAssetUI [-10000,-10000]
    local bindings=for accessory in accessories collect (caIWRegister setup accessory)
    caIWRecipe setup category
    caSetCollisionScope setup #() true
    local active=caIWRegionRules setup category label
    local triangles=#()
    for node in source[3] do
    (
        local meshValue=caIWReadMesh node
        for face=1 to meshValue.numfaces do
        (
            local indices=getFace meshValue face
            local a=meshop.getVert meshValue (indices.x as integer),b=meshop.getVert meshValue (indices.y as integer),c=meshop.getVert meshValue (indices.z as integer)
            local normal=cross (b-a) (c-a),up=false
            if length normal>1e-10 do up=normal.z/(length normal)>=(cos 5.0)
            append triangles #(a,b,c,up)
        )
        delete meshValue
    )
    caIWRequire (label+" independent furniture triangle oracle is nonempty/bounded") (triangles.count==source[5] and triangles.count<=40000)
    -- fixture: label, setup, furniture source, asset-ID/source bindings,
    -- immutable independent world triangles, initial seed, chosen region IDs.
    local fixture=#(label,setup,source,bindings,triangles,seed,active)
    caIWBind setup;caIWConfigureUI seed
    fixture
)
fn caIWRepeat fixture reference=
(
    local first=caGenerate fixture[2] #(),captured=caIWCapture fixture[2]
    caIWCheck (fixture[1]+" public Generate repeats actual UI seeded poses/groups") (caIWSame reference captured)
    local second=caGenerate fixture[2] #(),again=caIWCapture fixture[2]
    caIWCheck (fixture[1]+" repeated full native result including warnings is exact") (deepEqual first second strictCompare:true)
    caIWCheck (fixture[1]+" repeated ordered native poses/groups are exact") (caIWSame captured again)
    caIWCSV "generation-results.csv" #(caIWContext,fixture[1],first[1],first[2],first[3],first[4],first[5],first[6].count,"Full warnings follow in warnings.csv; no timing/cache claim")
    for i=1 to first[6].count do caIWCSV "warnings.csv" #(caIWContext,fixture[1],i,first[6][i])
    caIWValidate fixture
)
fn caIWInitial fixture=
(
    caIWStage (fixture[1]+" first explicit UI Generate and exact repeat")
    caIWBind fixture[2];caIWConfigureUI fixture[6]
    caIWRequire (fixture[1]+" real Generate action succeeds") (caArrangeUI.generateButton.pressed())
    local first=caIWCapture fixture[2]
    caIWNote ("UI_STATUS "+caArrangeUI.statusText.text)
    caIWRepeat fixture first
)
fn caIWReroll fixture=
(
    caIWStage (fixture[1]+" actual unlocked reroll")
    caIWBind fixture[2]
    local before=caIWCapture fixture[2],seed=(caSetupSummary fixture[2])[9][1]
    caIWRequire (fixture[1]+" real Reroll unlocked action succeeds") (caArrangeUI.rerollButton.pressed())
    caIWCheck (fixture[1]+" reroll increments saved exact seed") ((caSetupSummary fixture[2])[9][1]==seed+1L)
    local after=caIWCapture fixture[2]
    caIWNote ("VARIETY "+fixture[1]+" exact poses changed="+((not (deepEqual before[1] after[1] strictCompare:true)) as string)+"; variation is observed, not guaranteed for every seed")
    caIWRepeat fixture after
)
fn caIWProtection fixture=
(
    caIWStage (fixture[1]+" artist lock and selective regeneration")
    caIWBind fixture[2]
    local rows=caOutputRows fixture[2]
    caIWRequire (fixture[1]+" has an actual output to lock") (rows.count>0)
    caArrangeUI.outputs.selection=#{};select rows[1][9]
    caIWRequire (fixture[1]+" real Lock selected outputs action") (caArrangeUI.lockButton.pressed())
    local protected=caIWCapture fixture[2],locked=caIWFind protected[1] rows[1][1]
    caIWRequire (fixture[1]+" actual record is locked") (locked!=undefined and locked[7])
    caIWRequire (fixture[1]+" reroll with protected output succeeds") (caArrangeUI.rerollButton.pressed())
    local changed=caIWCapture fixture[2]
    caIWCheck (fixture[1]+" locked native ID/asset/region/pose remains exact") (caIWOnePose locked (caIWFind changed[1] locked[1]))
    caIWNote "NODE_IDENTITY Successful successors may replace output nodes; record IDs/poses, not old node handles, are protected."
    local occupied=#()
    for row in changed[1] do appendIfUnique occupied row[3]
    if fixture[1]=="SHELF" do caIWRequire "shelf has outputs on two regions for a real selective-preservation check" (occupied.count>=2)
    if occupied.count>=2 then
    (
        local selectedRegion=occupied[1],retained=for row in changed[1] where row[3]!=selectedRegion collect row
        caArrangeUI.regionText.text=caIWNum selectedRegion
        caArrangeUI.seedText.text=caIWNum ((caSetupSummary fixture[2])[9][1]+1L)
        caIWRequire (fixture[1]+" UI selective Generate succeeds") (caArrangeUI.generateButton.pressed())
        local actual=(caIWCapture fixture[2])[1],same=true
        for row in retained where not (caIWOnePose row (caIWFind actual row[1])) do same=false
        caIWCheck (fixture[1]+" unselected-region records are exact by stable ID") (retained.count>0 and same)
        caArrangeUI.regionText.text=""
    )
    else caIWNote ("SCOPE "+fixture[1]+" only one occupied support; cross-region selective check runs on SHELF.")
    caIWValidate fixture
)
fn caIWPreviewCommit fixture=
(
    caIWStage (fixture[1]+" actual Preview and Commit actions")
    caIWBind fixture[2]
    local before=caIWCapture fixture[2]
    caArrangeUI.seedText.text=caIWNum ((caSetupSummary fixture[2])[9][1]+10L)
    caIWRequire (fixture[1]+" real Preview bounds action succeeds") (caArrangeUI.previewButton.pressed())
    local info=caPreviewInfo fixture[2],boxes=caPreviewBounds fixture[2]
    caIWRequire (fixture[1]+" staged preview is valid and nonempty") (info[1] and info[2] and info[3]>0 and boxes.count==info[3])
    caIWCheck (fixture[1]+" Preview preserves exact published records and actual node identities") (caIWSame before (caIWCapture fixture[2]) handles:true)
    caIWRequire (fixture[1]+" real Commit preview action succeeds") (caArrangeUI.commitButton.pressed())
    caIWCheck (fixture[1]+" committed preview clears transient state") (not ((caPreviewInfo fixture[2])[1]))
    local after=caIWCapture fixture[2],same=after[1].count==boxes.count
    for i=1 to boxes.count while same do
    (
        local bounds=after[4][i]
        if distance boxes[i][1] ((bounds[1]+bounds[2])*0.5)>0.03 or distance boxes[i][2] ((bounds[2]-bounds[1])*0.5)>0.03 or boxes[i][3]!=after[1][i][5] do same=false
    )
    caIWCheck (fixture[1]+" estimated preview envelopes match actual committed world meshes") same
    caIWRepeat fixture after
)
fn caIWLayer label=(local layer=LayerManager.getLayerFromName label;if layer==undefined do layer=LayerManager.newLayerFromName label;layer)
fn caIWAssign nodes layer=
(
    for node in nodes where isValidNode node do
    (
        layer.addNode node
        local children=for child in node.children collect child
        if children.count>0 do caIWAssign children layer
    )
    true
)
fn caIWHide node=(node.renderable=false;for child in node.children do caIWHide child;true)
fn caIWCamera label position aim fieldOfView=
(
    local target=targetObject name:(label+"_Target") pos:aim
    local camera=targetCamera name:label pos:position target:target fov:fieldOfView
    caIWAssign #(target,camera) (caIWLayer "CA_IMPORTED_CAMERAS")
    camera
)
fn caIWStageScene accessories=
(
    local sourceLayer=caIWLayer "CA_IMPORTED_ACCESSORY_SOURCES"
    for source in accessories do (caIWAssign #(source[2]) sourceLayer;caIWHide source[2])
    sourceLayer.isHidden=true
    local floor=box name:"CA_IMPORTED_STAGE" width:7800 length:4000 height:40 pos:[0,0,-40]
    floor.material=standardMaterial name:"CA_IMPORTED_StageMat" diffuse:(color 47 51 53)
    caIWAssign #(floor) (caIWLayer "CA_IMPORTED_STAGE")
    local key=omniLight name:"CA_IMPORTED_Key" pos:[-2800,-3200,5500] multiplier:0.9 color:(color 255 239 220)
    key.baseObject.castShadows=true;key.shadowGenerator=raytraceShadow()
    local fill=omniLight name:"CA_IMPORTED_Fill" pos:[3200,-1600,4200] multiplier:0.4 color:(color 220 233 255)
    local rim=omniLight name:"CA_IMPORTED_Rim" pos:[0,2400,4500] multiplier:0.25 color:(color 255 241 224)
    caIWAssign #(key,fill,rim) (caIWLayer "CA_IMPORTED_LIGHTS")
    caIWCameras=#(caIWCamera "CA_IMPORTED_CAMERA_OVERVIEW" [40,-7700,3865] [-400,0,950] 48,
                   caIWCamera "CA_IMPORTED_CAMERA_TV" [-2000,-3645,2087.5] [-2000,0,400] 48,
                   caIWCamera "CA_IMPORTED_CAMERA_SHELF" [1600,-3120,2040] [1600,0,1000] 48)
    renderers.current=Default_Scanline_Renderer()
    ambientLight=color 32 32 32;backgroundColor=color 25 29 32
    renderWidth=2200;renderHeight=1500
    viewport.setCamera caIWCameras[1]
    caIWNote ("RENDER_SETUP renderer="+((classOf renderers.current) as string)+"; Standard diffuse + transparent cover adapter; current color mode="+((try(colorManagementPrefs.mode)catch(#unavailable)) as string))
)
fn caIWSave filename=
(
    local path=CA_TEST_OUTPUT+filename
    caIWRequire ("owned scene saved: "+filename) (saveMaxFile path quiet:true useNewFile:false)
    path
)
fn caIWReload path expected=
(
    caIWStage "save/reopen native setups, source bindings, surface rules and real meshes"
    try(destroyDialog caAssetUI)catch()
    try(destroyDialog caArrangeUI)catch()
    caIWRequire "saved imported workflow loads" (loadMaxFile path quiet:true)
    caIWRequire "saved scene retains physical millimetre units" (abs((units.decodeValue "1mm")-1)<1e-7)
    for i=1 to caIWFixtures.count do
    (
        local fixture=caIWFixtures[i]
        fixture[2]=getNodeByName ("CA_IMPORTED_SETUP_"+fixture[1]) exact:true
        caIWRequire (fixture[1]+" native setup survives reopen") (isValidNode fixture[2])
        caIWCheck (fixture[1]+" saved native pose/group records persist exactly") (caIWSame expected[i][1] (caIWCapture fixture[2]))
        caIWCheck (fixture[1]+" full saved surface policies persist") (deepEqual expected[i][2] (caRegionRows fixture[2]) strictCompare:true)
        caIWCheck (fixture[1]+" saved complete recipe/settings persist") (deepEqual expected[i][3] (caSetupSummary fixture[2])[9] strictCompare:true)
        local assets=caAssetRows fixture[2],bound=true
        for row in assets do if not row[10] or (caAssetDetail fixture[2] row[1])[10]!=1 do bound=false
        caIWCheck (fixture[1]+" imported accessory bindings stay live scene sources") (assets.count==3 and bound)
        caIWBind fixture[2]
        caIWRequire (fixture[1]+" reopened artist Generate succeeds") (caArrangeUI.generateButton.pressed())
        caIWCheck (fixture[1]+" reopened Generate reproduces saved native records") (caIWSame expected[i][1] (caIWCapture fixture[2]))
        caIWValidate fixture
    )
)
fn caIWRender scene cameraName label width height=
(
    caIWStage ("optional actual Scanline render "+label)
    caIWRequire (label+" render scene loads") (loadMaxFile scene quiet:true)
    local camera=getNodeByName cameraName exact:true
    caIWRequire (label+" saved render camera exists") (isValidNode camera)
    renderers.current=Default_Scanline_Renderer();renderWidth=width;renderHeight=height
    local output=CA_TEST_OUTPUT+"CyrusArrange-Imported-"+label+".png",start=timeStamp()
    local bitmapValue=render camera:camera outputFile:output vfb:false
    caIWRequire (label+" render returned a bitmap") (bitmapValue!=undefined)
    close bitmapValue
    caIWCheck (label+" actual PNG written") (doesFileExist output)
    caIWNote ("RENDER "+label+" wall_ms="+((timeStamp()-start) as string)+"; observation only, not a performance benchmark")
)
fn caIWPortable finalScene expected=
(
    caIWStage "explicit copied-example texture relocation and reopen"
    local portableRoot=CA_TEST_OUTPUT+"portable-example/"
    makeDir portableRoot all:true
    for row in CA_IMPORT_FILES do
    (
        local source=CA_TEST_OUTPUT+"inputs/"+row[2],target=portableRoot+"inputs/"+row[2]
        makeDir (getFilenamePath target) all:true
        caIWRequire ("portable exact source/map copy "+row[2]) ((copyFile source target) and (caIWHash target)==row[3])
    )
    -- The same explicit helper can accompany a relocated source/example archive.
    -- Its known map names+SHA checks, not Max's fallback search paths, choose files.
    local helper=CA_TEST_ROOT+"tests/max/relocate_imported_textures.ms"
    caIWRequire "portable explicit relocation helper copied" (copyFile helper (portableRoot+"Relocate-Imported-Textures.ms"))
    caIWRequire "portable original source credits copied" (copyFile (CA_TEST_OUTPUT+"credits.csv") (portableRoot+"credits.csv"))
    caIWRequire "portable exact source/map provenance copied" (copyFile (CA_TEST_OUTPUT+"source-provenance.csv") (portableRoot+"source-provenance.csv"))
    fileIn helper
    local updated=caRelocateImportedTextures portableRoot
    caIWRequire "explicit helper updates actual assigned imported bitmaps" (updated>=6)
    local path=portableRoot+"CyrusArrange-Imported-Workflow.max"
    caIWRequire "portable prepared example saved" (saveMaxFile path quiet:true useNewFile:false)
    caIWReload path expected
    local loadedMaps=#(),loadedNames=#(),materials=for node in objects where isProperty node #material and node.material!=undefined collect node.material
    local visited=#(),valid=true,root=toLower (substituteString ((dotNetClass "System.IO.Path").GetFullPath portableRoot) "\\" "/")
    while materials.count>0 do
    (
        local materialValue=materials[materials.count];deleteItem materials materials.count
        if (findItem visited materialValue)==0 do
        (
            append visited materialValue
            if visited.count>4096 do throw "Portable material walk exceeds bound."
            for slot=1 to (getNumSubMtls materialValue) do
            (
                local child=getSubMtl materialValue slot
                if child!=undefined do append materials child
            )
            for slot=1 to (getNumSubTexmaps materialValue) do
            (
                local mapValue=getSubTexmap materialValue slot
                if mapValue!=undefined and (classOf mapValue)==Bitmaptexture and (matchPattern mapValue.name pattern:"CA_IMPORTED_MAP_*") do
                (
                    appendIfUnique loadedMaps mapValue
                    local filename=toLower (substituteString ((dotNetClass "System.IO.Path").GetFullPath mapValue.filename) "\\" "/")
                    if (findString filename root)!=1 or not (doesFileExist mapValue.filename) do valid=false
                    local basename=toLower ((getFilenameFile mapValue.filename)+(getFilenameType mapValue.filename)),binding=undefined
                    appendIfUnique loadedNames basename
                    for candidate in caImportedTexturePaths where (toLower candidate[1])==basename do binding=candidate
                    local digest=caIWHash mapValue.filename
                    if binding==undefined then valid=false else if digest!=binding[3] do valid=false
                    caIWCSV "portable-textures.csv" #(mapValue.name,mapValue.filename,doesFileExist mapValue.filename,digest)
                )
            )
        )
    )
    for binding in caImportedTexturePaths where (findItem loadedNames (toLower binding[1]))==0 do valid=false
    caIWCheck "reopened example references all six exact supplied maps at relocated paths" (valid and loadedMaps.count>=6 and loadedNames.count==6)
    caIWRequire "return to final original owned scene after portability check" (loadMaxFile finalScene quiet:true)
)
fn caIWBootstrap=
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Private owned runner paths required before any scene reset."
    caIWRequire "Max2027 only" ((maxVersion())[1]==29000)
    CA_AUTO_SHOW_UI=false
    if CA_IMPORTED_RENDER==undefined do CA_IMPORTED_RENDER=false
    fileIn (CA_TEST_ROOT+"tests/data/imported_model_probe_fixture.ms")
    if CA_IMPORT_FILES.count!=11 or CA_IMPORT_CASES.count!=5 do throw "Exact frozen CC0 fixture sidecar required."
    caIWSourceFiles copyInputs:true
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0f
    local candidates=for candidate in importerPlugin.classes where (findItem #("fbximp","fbximporter") (toLower (candidate as string)))>0 collect candidate
    caIWRequire "one actual FBX importer resolves" (candidates.count==1)
    caIWImporter=candidates[1];pluginManager.loadClass caIWImporter
    caIWRequire "FBX importer loaded" caIWImporter.dllIsLoaded
    caIWNote ("IMPORTER "+(caIWImporter as string)+" / "+caIWImporter.dllName+" / "+(caIWImporter.classID as string))
    -- Keep a declared mm scene for the trial. Probe03 disproved that context
    -- alone makes Push/Pop restore ConvertUnit; restore that documented setting
    -- explicitly below, then require the complete original17-field readback.
    local original=caIWReadSettings(),pushed=false,problem=undefined
    caIWImports=#()
    try
    (
        caIWRequire "FBX PushSettings supported" ((FBXImporterSetParam "PushSettings")!=unsupplied);pushed=true
        local destinations=#([-2000,0,0],[1600,0,0],[-600,8000,0],[0,8000,0],[600,8000,0])
        for i=1 to CA_IMPORT_CASES.count do append caIWImports (caIWImportOne CA_IMPORT_CASES[i] destinations[i])
    ) catch(problem=getCurrentException() as string)
    if pushed do
    (
        caIWRequire "FBX PopSettings supported" ((FBXImporterSetParam "PopSettings")!=unsupplied)
        local popped=caIWReadSettings()
        for i=1 to popped.count do
            caIWCSV "import-settings.csv" #("postPopBeforeExplicitRestore",popped[i][1],original[i][2],popped[i][2],classOf original[i][2],classOf popped[i][2],(deepEqual #(original[i][2]) #(popped[i][2]) strictCompare:true))
        local savedUnit=caIWFind original "ConvertUnit"
        if savedUnit==undefined do throw "Original ConvertUnit setting was not captured."
        local unitName=toLower (trimLeft (savedUnit[2] as string) "#")
        caIWRequire "saved FBX conversion unit is a documented name" ((findItem #("mm","cm","dm","m","km","in","ft","yd") unitName)>0)
        caIWSetting "ConvertUnit" unitName
        caIWRequire "all17 observed FBX settings restored exactly" (caIWSettingsEqual original (caIWReadSettings()))
    )
    if problem!=undefined do throw problem
    caIWImports[3][6]=5;caIWImports[4][6]=6;caIWImports[5][6]=8
    local accessories=#(caIWImports[3],caIWImports[4],caIWImports[5])
    caIWStageScene accessories
    for source in caIWImports do join caIWSourceRecords (caIWSourceRecord source)
    fileIn (CA_TEST_ROOT+"scripts/ArrangeAssets.ms")
    fileIn (CA_TEST_ROOT+"scripts/ArrangeWorkflow.ms")
    caIWFixtures=#(caIWCreateCase caIWImports[1] 1 accessories 11L,caIWCreateCase caIWImports[2] 2 accessories 21L)
    for fixture in caIWFixtures do caIWInitial fixture
    local firstScene=caIWSave "CyrusArrange-Imported-SeedA.max"
    for fixture in caIWFixtures do caIWReroll fixture
    local secondScene=caIWSave "CyrusArrange-Imported-SeedB.max"
    for fixture in caIWFixtures do (caIWProtection fixture;caIWPreviewCommit fixture)
    for source in accessories do caIWRequire (source[1]+" occurs in real generated/validated outputs in this bounded trial") ((findItem caIWSeenModels source[1])>0)
    caIWCheck "all original nodes/vertices/faces/source materials survive styling unchanged" (caIWSourceSame caIWSourceRecords)
    local expected=for fixture in caIWFixtures collect #(caIWCapture fixture[2],caRegionRows fixture[2],(caSetupSummary fixture[2])[9])
    local finalScene=caIWSave "CyrusArrange-Imported-Workflow.max"
    caIWReload finalScene expected
    caIWPortable finalScene expected
    local note=createFile (CA_TEST_OUTPUT+"ABOUT-IMPORTED-TRIAL.txt")
    format "Imported Poly Haven geometry trial / CC0-1.0 asset files. See credits.csv and source-provenance.csv.\nStandard diffuse and approximate transparent-cover adapter / Default Scanline. Source PBR appearance is not reproduced.\nOriginal-size models; grouped/translating source preparation declared in authored-transforms.csv.\nCabinet body+two doors explicitly bound; both original vertex-only paths retained unbound. Selecting every original cabinet component currently fails native empty-mesh admission.\nContact checks sample nine envelope points; triangle-vs-envelope interior checks are conservative, not exact accessory-mesh collision or physical stability.\nSource accessory models/maps remain in this scene/output directory. Portable geometry libraries do not preserve this appearance.\nOpen CyrusArrange-Imported-Workflow.max with its exact matched native/UI pair; use named CA_IMPORTED_SETUP_TV/SHELF.\n" to:note
    close note
    if CA_IMPORTED_RENDER and caIWFailures==0 do
    (
        try(destroyDialog caAssetUI)catch();try(destroyDialog caArrangeUI)catch()
        caIWRender firstScene "CA_IMPORTED_CAMERA_OVERVIEW" "Overview-SeedA" 2400 1500
        caIWRender firstScene "CA_IMPORTED_CAMERA_TV" "TV-Console" 1800 1200
        caIWRender firstScene "CA_IMPORTED_CAMERA_SHELF" "Open-Shelf" 1500 1800
        caIWRender secondScene "CA_IMPORTED_CAMERA_OVERVIEW" "Overview-SeedB" 2400 1500
        caIWRequire "final artist scene restored after renders" (loadMaxFile finalScene quiet:true)
    )
    caIWNote "SCOPE No cache speed/hit qualification, original PBR appearance guarantee, arbitrary importer/renderer claim, physical settling or automatic semantic interpretation."
)
try(caIWBootstrap())catch
(
    caIWFailures+=1;caIWNote ("EXCEPTION "+caIWContext+": "+(getCurrentException() as string))
    caIWNote ("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
    caIWNote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
-- Finally-style original-byte verification also runs after import/UI failures.
if CA_IMPORT_FILES!=undefined and CA_IMPORT_ASSET_ROOT!=undefined do
    try(caIWSourceFiles())catch
    (
        caIWFailures+=1;caIWNote ("EXCEPTION final immutable source verification: "+(getCurrentException() as string))
    )
caIWFinished=true;caIWWrite()
