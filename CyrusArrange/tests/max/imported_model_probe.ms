/* Stage1 FBX import/inventory probe. OWNED PRIVATE Max2027 runner only.
   Resets five scenes; no Generate, renderer, material adaptation or source edits.
   Must promote with its frozen fixture-data sidecar; no other test is fileIn'd. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global CA_IMPORT_ASSET_ROOT, CA_IMPORT_SOURCE_MANIFEST_SHA256, CA_IMPORT_FILES, CA_IMPORT_CASES
global FBXImporterGetParam, FBXImporterSetParam
global caILog=#(),caIPasses=0,caIFailures=0,caIFinished=false,caIStage="initialization"
global caIWrite,caINote,caICheck,caIRequire,caINumber,caICSV,caIHash,caIFinite,caIPointFinite
global caIEnum,caISetting,caIReadSettings,caIConfigure,caISettingsEqual,caIHistAdd,caIMaterial
global caIMesh,caIImport,caIBootstrap,caIPaths,caISourceCheck,caIRunCase

fn caIWrite=
(
    if CA_TEST_OUTPUT!=undefined do
    (
        local report=createFile (CA_TEST_OUTPUT+"result.txt")
        format "% passes=% failures=%\n" (if caIFinished then (if caIFailures==0 then "SUCCESS" else "ERROR") else "RUNNING") caIPasses caIFailures to:report
        for line in caILog do format "%\n" line to:report
        close report
    )
)
fn caINote line=(append caILog line;caIWrite();true)
fn caICheck label condition=
(
    if condition then (caIPasses+=1;caINote ("PASS "+label)) else (caIFailures+=1;caINote ("FAIL "+label))
    condition
)
fn caIRequire label condition=(caICheck label condition;if not condition do throw ("Prerequisite: "+label);true)
fn caINumber value=
(
    if value==undefined then "undefined"
    else if classOf value==String then value
    else if classOf value==Integer then value as string
    else if classOf value==Integer64 then trimRight (value as string) "Ll"
    else if classOf value==IntegerPtr then trimRight ((value as Integer64) as string) "Ll"
    else if classOf value==Float or classOf value==Double then (dotNetClass "System.Convert").ToString value (dotNetClass "System.Globalization.CultureInfo").InvariantCulture
    else value as string
)
fn caICSV filename values=
(
    local stream=openFile (CA_TEST_OUTPUT+filename) mode:"a"
    if stream==undefined do throw ("Cannot append "+filename)
    for i=1 to values.count do
    (
        if i>1 do format "," to:stream
        format "\"%\"" (substituteString (caINumber values[i]) "\"" "\"\"") to:stream
    )
    format "\n" to:stream;flush stream;close stream
)
fn caIHash path=
(
    local stream=undefined,hasher=undefined,answer=undefined,problem=undefined
    try
    (
        stream=(dotNetClass "System.IO.File").OpenRead path
        hasher=(dotNetClass "System.Security.Cryptography.SHA256").Create()
        answer=toLower (substituteString ((dotNetClass "System.BitConverter").ToString (hasher.ComputeHash stream)) "-" "")
    ) catch (problem=getCurrentException() as string)
    if stream!=undefined do stream.Close()
    if hasher!=undefined do hasher.Dispose()
    if problem!=undefined do throw problem
    answer
)
fn caIFinite value=(value==value and abs value<1.0e30)
fn caIPointFinite value=((classOf value)==Point3 and caIFinite value.x and caIFinite value.y and caIFinite value.z)
fn caIEnum value=toLower (trimLeft (value as string) "#")
fn caISetting key wanted=
(
    local returned=FBXImporterSetParam key wanted,actual=FBXImporterGetParam key
    caICSV "import-settings.csv" #(caIStage,key,"set",wanted,classOf wanted,returned,actual,classOf actual)
    caIRequire ("FBX setter supports "+key) (returned!=unsupplied)
    local same=if (classOf wanted)==String or (classOf wanted)==Name then (caIEnum actual)==(caIEnum wanted) else actual==wanted
    caIRequire ("FBX readback matches "+key) same
    actual
)
fn caIReadSettings=
(
    local rows=#()
    for key in #("Mode","Animation","Cameras","Lights","Skin","Shape","PointCache","SmoothingGroups","AxisConversion","ScaleConversion","ConvertUnit","UpAxis","ScaleFactor","GenerateLog","Environment","GlobalAmbientColor","FillTimeline") do
    (
        local actual=FBXImporterGetParam key
        caICSV "import-settings.csv" #(caIStage,key,"get","","","",actual,classOf actual)
        if actual==unsupplied do throw ("Documented FBX getter unsupported: "+key)
        append rows #(key,actual)
    )
    rows
)
fn caISettingsEqual first second=
(
    local same=first.count==second.count
    for i=1 to first.count while same do same=first[i][1]==second[i][1] and first[i][2]==second[i][2]
    same
)
fn caIConfigure=
(
    local result=FBXImporterSetParam "ResetImport"
    caINote ("FBX ResetImport returned="+(result as string))
    caIRequire "factory import reset is supported" (result!=unsupplied)
    local settings=#(#("Mode",#create),#("Animation",false),#("Cameras",false),#("Lights",false),#("Skin",false),#("Shape",false),#("PointCache",false),#("Environment",false),#("GlobalAmbientColor",false),#("FillTimeline",false),#("GenerateLog",false),#("SmoothingGroups",true),#("AxisConversion",true),#("ConvertUnit","mm"),#("ScaleConversion",true),#("UpAxis","Z"))
    for row in settings do caISetting row[1] row[2]
    -- Automatic conversion targets the declared mm scene; never force ScaleFactor1
    -- over a source-cm to host-mm conversion. Log the importer's actual result.
    local configured=caIReadSettings(),scale=FBXImporterGetParam "ScaleFactor"
    caIRequire "automatic FBX scale factor is finite and positive" (caIFinite scale and scale>0 and scale<1.0e6)
    for row in settings do
    (
        local actual=FBXImporterGetParam row[1],wanted=row[2]
        local same=if (classOf wanted)==String or (classOf wanted)==Name then (caIEnum actual)==(caIEnum wanted) else actual==wanted
        caIRequire ("final interdependent FBX readback matches "+row[1]) same
    )
    configured
)
fn caIHistAdd rows value=
(
    local index=0
    for i=1 to rows.count where rows[i][1]==value do index=i
    if index==0 then (if rows.count>=128 do throw "Histogram exceeds128 categories.";append rows #(value,1)) else rows[index][2]+=1
    rows
)
fn caIMaterial caseId node=
(
    local pending=#(#(node.material,"root",0)),seen=#(),count=0
    while pending.count>0 do
    (
        local item=pending[pending.count];deleteItem pending pending.count
        local materialValue=item[1],path=item[2],depth=item[3]
        if materialValue==undefined then caICSV "materials.csv" #(caseId,getHandleByAnim node,path,"undefined","","","",0,0)
        else if findItem seen materialValue==0 do
        (
            append seen materialValue;count+=1
            if count>128 or depth>8 do throw "Material hierarchy exceeds128 nodes/depth8."
            local cid=materialValue.classID,subCount=getNumSubMtls materialValue,mapCount=getNumSubTexmaps materialValue
            if subCount>128 or mapCount>128 do throw "Material slot admission exceeded."
            caICSV "materials.csv" #(caseId,getHandleByAnim node,path,materialValue.name,classOf materialValue,cid[1],cid[2],subCount,mapCount)
            for slot=1 to subCount do
            (
                local child=getSubMtl materialValue slot,materialId=slot
                if isProperty materialValue #materialIDList do if slot<=materialValue.materialIDList.count do materialId=materialValue.materialIDList[slot]
                caICSV "material-slots.csv" #(caseId,getHandleByAnim node,path,slot,materialId,getSubMtlSlotName materialValue slot,(if child==undefined then "undefined" else child.name))
                if child!=undefined do append pending #(child,path+"/"+(slot as string),depth+1)
            )
            for slot=1 to mapCount do
            (
                local mapValue=getSubTexmap materialValue slot
                if mapValue!=undefined do
                (
                    local filename=if isProperty mapValue #filename then getProperty mapValue #filename else ""
                    local channel=if isProperty mapValue #coords and isProperty mapValue.coords #mapChannel then mapValue.coords.mapChannel else undefined
                    caICSV "texture-slots.csv" #(caseId,getHandleByAnim node,path,slot,getSubTexmapSlotName materialValue slot,mapValue.name,classOf mapValue,filename,channel,(if filename=="" then undefined else doesFileExist filename))
                )
            )
        )
    )
)
fn caIMesh caseId node=
(
    local meshValue=undefined,result=undefined,errorText=undefined
    try
    (
        in coordsys world (meshValue=snapshotAsMesh node renderMesh:false)
        local nv=meshValue.numverts,nf=meshValue.numfaces
        if nv<1 or nv>300000 or nf<0 or nf>100000 do throw "Imported mesh exceeds300k vertices/100k triangles or has no vertices."
        local role=if nf==0 then "vertex_only_no_triangle_surface" else "triangle_surface"
        local minimum=[1e30,1e30,1e30],maximum=[-1e30,-1e30,-1e30],bad=0
        for i=1 to nv do
        (
            local p=meshop.getVert meshValue i
            if not (caIPointFinite p) do bad+=1
            for axis=1 to 3 do (minimum[axis]=amin #(minimum[axis],p[axis]);maximum[axis]=amax #(maximum[axis],p[axis]))
        )
        caIRequire (caseId+" "+node.name+" has finite world vertices") (bad==0)
        local faceIds=#(),smooth=#(),normalCount=0,invalidNormals=0,zeroNormals=0,minNormal=1e30,maxNormal=0
        for face=1 to nf do
        (
            local indices=getFace meshValue face
            for corner=1 to 3 do if indices[corner]<1 or indices[corner]>nv do throw "Invalid imported face vertex index."
            caIHistAdd faceIds (getFaceMatID meshValue face);caIHistAdd smooth (getFaceSmoothGroup meshValue face)
            local normals=meshop.getFaceRNormals meshValue face
            for corner=1 to normals.count do
            (
                local n=normals[corner],magnitude=length n
                normalCount+=1
                if not (caIPointFinite n) then invalidNormals+=1
                else (minNormal=amin #(minNormal,magnitude);maxNormal=amax #(maxNormal,magnitude);if magnitude<1e-8 do zeroNormals+=1)
                if face<=4 do caICSV "normal-samples.csv" #(caseId,getHandleByAnim node,face,corner,n.x,n.y,n.z)
            )
        )
        for row in faceIds do caICSV "face-material-ids.csv" #(caseId,getHandleByAnim node,row[1],row[2])
        for row in smooth do caICSV "smoothing-groups.csv" #(caseId,getHandleByAnim node,row[1],row[2])
        caICSV "normal-inventory.csv" #(caseId,getHandleByAnim node,"render-corner normals on independent world mesh; not original explicit-normal IDs",normalCount,invalidNormals,zeroNormals,(if normalCount==0 then undefined else minNormal),(if normalCount==0 then undefined else maxNormal))
        if nf>0 then caIRequire (caseId+" "+node.name+" render normals are finite") (invalidNormals==0)
        else caINote ("INVENTORY "+caseId+" node="+node.name+" role="+role+" vertices="+(nv as string)+" triangles=0 worldBounds="+(minimum as string)+","+(maximum as string)+"; original node retained, excluded only from triangle-surface support/dimension aggregate")
        local mapChannels=meshop.getNumMaps meshValue,uv1=false
        if mapChannels<0 or mapChannels>16 do throw "Imported mapping-channel admission exceeds16."
        for channel=-2 to (mapChannels-1) do if meshop.getMapSupport meshValue channel do
        (
            local mapVerts=meshop.getNumMapVerts meshValue channel,mapFaces=meshop.getNumMapFaces meshValue channel,badMap=0
            if mapVerts>300000 or mapFaces>100000 do throw "Imported map topology admission exceeded."
            for i=1 to mapVerts do if not (caIPointFinite (meshop.getMapVert meshValue channel i)) do badMap+=1
            for f=1 to mapFaces do
            (
                local indices=meshop.getMapFace meshValue channel f
                for k=1 to 3 do if indices[k]<1 or indices[k]>mapVerts do badMap+=1
            )
            caICSV "mapping-channels.csv" #(caseId,getHandleByAnim node,channel,mapVerts,mapFaces,badMap)
            caIRequire (caseId+" "+node.name+" map channel"+(channel as string)+" has valid finite topology") (badMap==0 and (mapFaces==0 or mapFaces==nf))
            if nf>0 and channel==1 and mapVerts>0 and mapFaces==nf do uv1=true
        )
        caICSV "meshes.csv" #(caseId,getHandleByAnim node,nv,nf,minimum.x,minimum.y,minimum.z,maximum.x,maximum.y,maximum.z,uv1,role)
        result=#(minimum,maximum,nv,nf,uv1,role)
    ) catch (errorText=getCurrentException() as string)
    -- Independent snapshot only; never delete or modify the source node mesh.
    if meshValue!=undefined do delete meshValue
    if errorText!=undefined do throw errorText
    result
)
fn caIImport caseRow=
(
    local caseId=caseRow[1],relativePath=caseRow[2],catalogue=caseRow[3],catalogueTriangles=caseRow[4]
    caIStage="import "+caseId;caINote ("STAGE "+caIStage)
    caICSV "case-provenance.csv" #(caseId,caseRow[5],caseRow[6],caseRow[7],"CC0-1.0",catalogue.x,catalogue.y,catalogue.z,catalogueTriangles,"approximate provider measurements; not an evaluated Max oracle")
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0f
    caIRequire "fresh scene uses one millimetre per system unit" (abs((units.decodeValue "1mm")-1)<1e-7 and objects.count==0)
    caIConfigure()
    local filename=CA_TEST_OUTPUT+"inputs/"+relativePath
    local imported=importFile filename #noPrompt using:caIPaths[1] quiet:true
    caIRequire (caseId+" quiet FBX import succeeds") imported
    caIStage="post-import "+caseId;caIReadSettings()
    local allNodes=objects as array
    caIRequire (caseId+" bounded imported node inventory") (allNodes.count>0 and allNodes.count<=256)
    local geometries=0,triangleMeshes=0,vertexOnlyMeshes=0,triangles=0,vertices=0,uvNodes=0,minimum=[1e30,1e30,1e30],maximum=[-1e30,-1e30,-1e30]
    for node in allNodes do
    (
        local handle=getHandleByAnim node,cid=node.classID,tm=node.transform,objectTM=node.objectTransform
        local values=#(caseId,handle,node.name,classOf node,superClassOf node,cid[1],cid[2],(if node.parent==undefined or node.parent==rootNode then 0 else getHandleByAnim node.parent))
        for m in #(tm,objectTM) do for row in #(m.row1,m.row2,m.row3,m.row4) do join values #(row.x,row.y,row.z)
        caICSV "nodes.csv" values
        caIRequire (caseId+" imports no cameras or lights") ((superClassOf node)!=Camera and (superClassOf node)!=Light)
        if (superClassOf node)==GeometryClass and not (isGroupHead node) do
        (
            geometries+=1
            local inventory=caIMesh caseId node
            vertices+=inventory[3];triangles+=inventory[4];if inventory[5] do uvNodes+=1
            if vertices>300000 or triangles>100000 do throw "Combined imported case exceeds mesh admission."
            if inventory[4]>0 then
            (
                triangleMeshes+=1
                for axis=1 to 3 do (minimum[axis]=amin #(minimum[axis],inventory[1][axis]);maximum[axis]=amax #(maximum[axis],inventory[2][axis]))
            )
            else vertexOnlyMeshes+=1
            caIMaterial caseId node
        )
    )
    caIRequire (caseId+" has nonempty triangle geometry and UV1") (triangleMeshes>0 and triangles>0 and uvNodes>0)
    local dimensions=maximum-minimum,within=true
    for axis=1 to 3 do
    (
        local tolerance=amax #(5.0,catalogue[axis]*0.02)
        if abs(dimensions[axis]-catalogue[axis])>tolerance do within=false
        caICSV "dimensions.csv" #(caseId,axis,minimum[axis],maximum[axis],dimensions[axis],catalogue[axis],tolerance,abs(dimensions[axis]-catalogue[axis])<=tolerance)
    )
    caINote ("IMPORTED "+caseId+" nodes="+(allNodes.count as string)+" geometryNodes="+(geometries as string)+" triangleSurfaceNodes="+(triangleMeshes as string)+" vertexOnlyNodes="+(vertexOnlyMeshes as string)+" triangles="+(triangles as string)+" catalogueTriangles="+(catalogueTriangles as string)+" triangleSurfaceDimensionsMM="+(dimensions as string)+" catalogueMM="+(catalogue as string))
    -- Save actual data even if catalogue measurement differs: never resize or repair it.
    local scene=CA_TEST_OUTPUT+caseId+"-imported.max"
    caIRequire (caseId+" private original imported scene saves") (saveMaxFile scene quiet:true useNewFile:false)
    caICSV "cases.csv" #(caseId,filename,scene,allNodes.count,geometries,vertices,triangles,catalogueTriangles,within,"unmodified imported materials; no appearance claim",triangleMeshes,vertexOnlyMeshes)
    caICheck (caseId+" approximate catalogue XYZ dimensions and Z-up height agree within max5mm/2percent") within
)
fn caISourceCheck copyInputs:false=
(
    local io=dotNetClass "System.IO.Path"
    local base=substituteString (io.GetFullPath CA_IMPORT_ASSET_ROOT) "\\" "/"
    if not (matchPattern base pattern:"*/") do base+="/"
    for row in CA_IMPORT_FILES do
    (
        local source=substituteString (io.GetFullPath (base+row[2])) "\\" "/",target=CA_TEST_OUTPUT+"inputs/"+row[2]
        caIRequire ("source stays within explicit read-only fixture root "+row[2]) ((findString (toLower source) (toLower base))==1)
        caIRequire ("source file exists "+row[2]) (doesFileExist source)
        caIRequire ("source SHA256 matches frozen provenance "+row[2]) ((caIHash source)==row[3])
        local info=dotNetObject "System.IO.FileInfo" source
        caIRequire ("source byte size matches frozen provenance "+row[2]) (info.Length==row[4])
        if copyInputs do
        (
            makeDir (getFilenamePath target) all:true
            if doesFileExist target do throw "Owned probe input destination already exists."
            caIRequire ("private input copy succeeds "+row[2]) (copyFile source target)
            caIRequire ("private input copy SHA256 matches "+row[2]) ((caIHash target)==row[3])
            caICSV "source-provenance.csv" #(row[1],row[2],source,target,row[3],row[4],row[5],"CC0-1.0",CA_IMPORT_SOURCE_MANIFEST_SHA256)
        )
    )
)
fn caIRunCase row=
(
    try (caIImport row) catch
    (
        caIFailures+=1;caINote ("EXCEPTION "+row[1]+": "+(getCurrentException() as string))
        caINote ("STACK "+(getCurrentExceptionStackTrace() as string))
    )
)
fn caIBootstrap=
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Owned runner root/output required before scene reset."
    if (maxVersion())[1]!=29000 do throw "Stage1 probe supports Max2027 only."
    CA_AUTO_SHOW_UI=false
    fileIn (CA_TEST_ROOT+"tests/data/imported_model_probe_fixture.ms")
    if CA_IMPORT_ASSET_ROOT==undefined or CA_IMPORT_FILES.count!=11 or CA_IMPORT_CASES.count!=5 do throw "Exact external read-only asset fixture required."
    caIRequire "exact pointer/integer CSV identities" ((caINumber 55224)=="55224" and (caINumber 4294967295P)=="4294967295" and (caINumber 4294967295L)=="4294967295")
    caISourceCheck copyInputs:true
    local candidates=for candidate in importerPlugin.classes where (findItem #("fbximp","fbximporter") (toLower (candidate as string)))>0 collect candidate
    caIRequire "exactly one FBX importer class resolves" (candidates.count==1)
    local importer=candidates[1]
    pluginManager.loadClass importer
    caIRequire "resolved FBX importer is actually loaded" importer.dllIsLoaded
    caIPaths=#(importer)
    caINote ("IMPORTER class="+(importer as string)+" classID="+(importer.classID as string)+" dll="+(importer.dllName as string)+" maxVersion="+((maxVersion()) as string))
    caICSV "importer.csv" #(importer,importer.classID[1],importer.classID[2],importer.dllName,(maxVersion()) as string,getMAXIniFile())
    -- Establish the same physical host-unit context before both observations.
    -- Do not repair a post-Pop unit mismatch with a hidden importer setter.
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;sliderTime=0f
    caIStage="initial mm-context importer settings"
    caIRequire "initial settings snapshot uses the same fresh mm context as restoration" (abs((units.decodeValue "1mm")-1)<1e-7 and objects.count==0)
    local original=caIReadSettings(),pushed=false,problem=undefined
    try
    (
        local result=FBXImporterSetParam "PushSettings"
        caINote ("FBX PushSettings returned="+(result as string))
        caIRequire "FBX PushSettings is supported" (result!=unsupplied)
        pushed=true
        for row in CA_IMPORT_CASES do caIRunCase row
    ) catch (problem=getCurrentException() as string)
    if pushed do try
    (
        caIStage="restore importer settings"
        local result=FBXImporterSetParam "PopSettings"
        caINote ("FBX PopSettings returned="+(result as string))
        caIRequire "FBX PopSettings is supported" (result!=unsupplied)
        local afterPop=caIReadSettings()
        for i=1 to original.count do caICSV "restoration-differences.csv" #("after PopSettings",original[i][1],original[i][2],classOf original[i][2],afterPop[i][2],classOf afterPop[i][2],original[i][2]==afterPop[i][2])
    ) catch
    (
        local cleanupError=getCurrentException() as string
        caINote ("RESTORE_ERROR "+cleanupError)
        caINote ("RESTORE_STACK "+(getCurrentExceptionStackTrace() as string))
        problem=if problem==undefined then cleanupError else problem+" | restore: "+cleanupError
    )
    if pushed do try
    (
        -- Actual2027.1 Pop leaves ConvertUnit changed. This is a named, always
        -- executed restoration step, not a conditional or hidden test fallback.
        caIStage="PopSettings plus explicit original ConvertUnit restoration"
        local savedUnit=undefined
        for row in original where row[1]=="ConvertUnit" do savedUnit=row[2]
        caIRequire "saved original ConvertUnit has a documented Name/String representation" ((classOf savedUnit)==Name or (classOf savedUnit)==String)
        caINote ("EXPLICIT_UNIT_RESTORE original="+(savedUnit as string)+" originalType="+((classOf savedUnit) as string)+" setterValue="+(caIEnum savedUnit))
        caISetting "ConvertUnit" (caIEnum savedUnit)
        local afterExplicit=caIReadSettings()
        for i=1 to original.count do caICSV "restoration-differences.csv" #("after PopSettings plus explicit ConvertUnit",original[i][1],original[i][2],classOf original[i][2],afterExplicit[i][2],classOf afterExplicit[i][2],original[i][2]==afterExplicit[i][2])
        caIRequire "PopSettings plus explicit original-unit restoration matches all17 observed settings exactly" (caISettingsEqual original afterExplicit)
    ) catch
    (
        local unitError=getCurrentException() as string
        caINote ("EXPLICIT_UNIT_RESTORE_ERROR "+unitError)
        caINote ("EXPLICIT_UNIT_RESTORE_STACK "+(getCurrentExceptionStackTrace() as string))
        problem=if problem==undefined then unitError else problem+" | explicit original-unit restore: "+unitError
    )
    -- Source preservation is verified even if Pop/its exact readback fails.
    try (caISourceCheck()) catch
    (
        local sourceError=getCurrentException() as string
        caINote ("SOURCE_CHECK_ERROR "+sourceError)
        problem=if problem==undefined then sourceError else problem+" | source check: "+sourceError
    )
    if problem!=undefined do throw problem
)
try (caIBootstrap()) catch
(
    caIFailures+=1;caINote ("EXCEPTION "+caIStage+": "+(getCurrentException() as string))
    caINote ("STACK "+(getCurrentExceptionStackTrace() as string))
)
caIFinished=true;caIWrite()
