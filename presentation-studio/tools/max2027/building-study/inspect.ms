-- Read-only scene inspection, used only in an owned host/profile on a working copy.
global CyrusBuildingJsonString,CyrusBuildingJsonNumber,CyrusBuildingJsonVector
fn CyrusBuildingJsonString value = (
    local s=dotNetObject "System.Text.StringBuilder"
    s.Append "\""
    for i=1 to value.count do (
        local ch=value[i],code=bit.charAsInt value[i]
        case ch of (
            "\"":s.Append "\\\""
            "\\":s.Append "\\\\"
            default:if code<32 then s.Append ("\\u"+(formattedPrint code format:"04x")) else s.Append ch
        )
    )
    s.Append "\"";s.ToString()
)
fn CyrusBuildingJsonNumber value = ((dotNetObject "System.Double" value).ToString "R" (dotNetClass "System.Globalization.CultureInfo").InvariantCulture)
fn CyrusBuildingJsonVector value = "["+(CyrusBuildingJsonNumber value.x)+","+(CyrusBuildingJsonNumber value.y)+","+(CyrusBuildingJsonNumber value.z)+"]"
(
    if MCPFixtureDir==undefined or not matchPattern MCPFixtureDir pattern:"*max-camera-2027-*" do throw "Owned host required."
    local file=createFile (MCPFixtureDir+"inspection.json") encoding:#utf8 writeBOM:false, nodes=geometry as array, uniqueBases=#(), cyrusMaterials=#(), modifierNames=#()
    local totalFaces=0,totalVertices=0, minBound=[1e30,1e30,1e30],maxBound=[-1e30,-1e30,-1e30]
    format "{\"maxVersion\":%,\"systemType\":%,\"systemScale\":%,\"unitsPerMetre\":%,\"objects\":%,\"geometry\":[" (CyrusBuildingJsonString ((maxVersion()) as string)) (CyrusBuildingJsonString (units.SystemType as string)) (CyrusBuildingJsonNumber units.SystemScale) (CyrusBuildingJsonNumber (units.decodeValue "1m")) objects.count to:file
    for index=1 to nodes.count do (
        local n=nodes[index],counts=getPolygonCount n,bb=nodeGetBoundingBox n (matrix3 1),mods=#()
        totalFaces+=counts[1];totalVertices+=counts[2]
        appendIfUnique uniqueBases n.baseObject
        if n.material!=undefined do appendIfUnique cyrusMaterials n.material
        for modifier in n.modifiers do append mods ((classOf modifier) as string)
        for k=1 to 3 do (minBound[k]=amin minBound[k] bb[1][k];maxBound[k]=amax maxBound[k] bb[2][k])
        if index>1 do format "," to:file
        format "{\"handle\":%,\"name\":%,\"class\":%,\"baseClass\":%,\"layer\":%,\"hidden\":%,\"renderable\":%,\"facesReported\":%,\"verticesReported\":%,\"min\":%,\"max\":%,\"material\":%,\"materialClass\":%,\"modifiers\":[" (CyrusBuildingJsonNumber n.handle) (CyrusBuildingJsonString n.name) (CyrusBuildingJsonString ((classOf n) as string)) (CyrusBuildingJsonString ((classOf n.baseObject) as string)) (CyrusBuildingJsonString n.layer.name) (if n.isHidden then "true" else "false") (if n.renderable then "true" else "false") counts[1] counts[2] (CyrusBuildingJsonVector bb[1]) (CyrusBuildingJsonVector bb[2]) (CyrusBuildingJsonString (if n.material==undefined then "" else n.material.name)) (CyrusBuildingJsonString (if n.material==undefined then "" else (classOf n.material) as string)) to:file
        for k=1 to mods.count do (if k>1 do format "," to:file;format "%" (CyrusBuildingJsonString mods[k]) to:file)
        format "]}" to:file
    )
    format "],\"facesReported\":%,\"verticesReported\":%,\"uniqueBaseObjects\":%,\"bounds\":{\"min\":%,\"max\":%},\"materials\":[" totalFaces totalVertices uniqueBases.count (CyrusBuildingJsonVector minBound) (CyrusBuildingJsonVector maxBound) to:file
    local stack=(for materialEntry in cyrusMaterials collect materialEntry),seen=#(),first=true
    while stack.count>0 do (
        local m=stack[stack.count];deleteItem stack stack.count
        if findItem seen m==0 do (
            append seen m
            if not first do format "," to:file;first=false
            format "{\"name\":%,\"class\":%,\"subMaterials\":%}" (CyrusBuildingJsonString m.name) (CyrusBuildingJsonString ((classOf m) as string)) (getNumSubMtls m) to:file
            for k=1 to getNumSubMtls m where getSubMtl m k!=undefined do append stack (getSubMtl m k)
        )
    )
    format "],\"bitmaps\":[" to:file
    local maps=getClassInstances BitmapTexture
    for i=1 to maps.count do (
        if i>1 do format "," to:file
        format "{\"name\":%,\"filename\":%,\"exists\":%}" (CyrusBuildingJsonString maps[i].name) (CyrusBuildingJsonString maps[i].filename) (if doesFileExist maps[i].filename then "true" else "false") to:file
    )
    format "]}" to:file;close file
    local details=createFile (MCPFixtureDir+"material-properties.txt")
    for i=1 to amin 24 seen.count do (format "\nMATERIAL % class %\n" seen[i].name (classOf seen[i]) to:details;showProperties seen[i] to:details)
    showInterfaces GLTF_Export to:details
    format "\nGLTF OPTIONS %\n" (GLTF_Export.toJsonStr()) to:details
    close details
)
