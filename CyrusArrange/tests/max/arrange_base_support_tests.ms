/* Owned Max2027: actual original-size overhang, base-centered paths and a
   complete prepared plant. No computer use, installation or renderer claim. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI,caRWInputSpecs
global caBSLog=#(),caBSPasses=0,caBSFailures=0,caBSFinished=false
fn caBSWrite=(local f=createFile(CA_TEST_OUTPUT+"result.txt");format "% passes=% failures=%\n"(if caBSFinished then(if caBSFailures==0 then "SUCCESS" else "ERROR")else "RUNNING")caBSPasses caBSFailures to:f;for line in caBSLog do format "%\n"line to:f;close f)
fn caBSCheck label value=(if value then caBSPasses+=1 else caBSFailures+=1;append caBSLog((if value then "PASS " else "FAIL ")+label);caBSWrite();if not value do throw label;value)
fn caBSOrder a b=(if a.handle<b.handle then -1 else if a.handle>b.handle then 1 else 0)
fn caBSLeaves node=(local result=#();if isGroupHead node then(for child in node.children do join result(caBSLeaves child))else append result node;qsort result caBSOrder;result)
fn caBSMesh node=
(
    local value=undefined
    if isGroupHead node then undo off
    (
        local points=#(),faces=#()
        for part in(caBSLeaves node)do
        (
            local m=caBSMesh part,offset=points.count
            if points.count+m.numverts>250000 or faces.count+m.numfaces>250000 do throw "Group mesh admission"
            for i=1 to m.numverts do append points(getVert m i)
            for i=1 to m.numfaces do append faces((getFace m i)+[offset,offset,offset])
            delete m
        )
        local temporary=mesh vertices:points faces:faces
        value=snapshotAsMesh temporary;delete temporary
    )
    else in coordsys world(value=snapshotAsMesh node renderMesh:false)
    if value==undefined or value.numverts>250000 or value.numfaces>250000 do throw "Mesh admission"
    value
)
fn caBSBounds m=(local low=[1e30,1e30,1e30],high=[-1e30,-1e30,-1e30];for i=1 to m.numverts do(local p=getVert m i;for k=1 to 3 do(low[k]=amin low[k]p[k];high[k]=amax high[k]p[k]));#(low,high))
fn caBSPose owner=for r in(caOutputRows owner)collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
fn caBSValues owner count=(local v=caPlacementSettings owner;v[1]=932032L;v[2]=2;v[3]=count;v[5]=0;v[6]=0;v[7]=false;v[8]=false;v)
fn caBSHash path=(local stream=(dotNetClass "System.IO.File").OpenRead path,algorithm=(dotNetClass "System.Security.Cryptography.SHA256").Create(),answer=undefined;try(answer=toLower(substituteString((dotNetClass "System.BitConverter").ToString(algorithm.ComputeHash stream))"-"""))catch(stream.Close();algorithm.Dispose();throw());stream.Close();algorithm.Dispose();answer)
fn caBSExport label receivers sources owner=
(
    local f=createFile(CA_TEST_OUTPUT+label+"-meshes.txt"),rows=caOutputRows owner,assets=caAssetRows owner
    for kind in #("receiver","source","output")do
    (
        local nodes=case kind of("receiver":receivers;"source":sources;"output":for r in rows collect r[9])
        for i=1 to nodes.count do
        (
            local m=caBSMesh nodes[i]
            format "mesh % % % %\n"kind i m.numverts m.numfaces to:f
            for j=1 to m.numverts do(local p=getVert m j;format "v % % %\n"(formattedPrint(p.x as double)format:".17g")(formattedPrint(p.y as double)format:".17g")(formattedPrint(p.z as double)format:".17g")to:f)
            for j=1 to m.numfaces do(local t=getFace m j;format "f % % % % %\n"(t.x as integer)(t.y as integer)(t.z as integer)(getFaceMatID m j)(getFaceSmoothGroup m j)to:f)
            if kind=="source"do(local b=caBSBounds m,a=(caAssetSupport owner assets[i][1])[1]+[(b[1].x+b[2].x)*.5,(b[1].y+b[2].y)*.5,b[1].z];format "anchor % % %\n"(formattedPrint(a.x as double)format:".17g")(formattedPrint(a.y as double)format:".17g")(formattedPrint(a.z as double)format:".17g")to:f)
            if kind=="output"do(local r=rows[i],index=0;for j=1 to assets.count where assets[j][1]==r[2]do index=j;format "pose % % % % % % % %\n"index r[1](formattedPrint(r[4].x as double)format:".17g")(formattedPrint(r[4].y as double)format:".17g")(formattedPrint(r[4].z as double)format:".17g")(formattedPrint r[5]format:".17g")(formattedPrint r[6]format:".17g")r[8]to:f)
            format "end\n"to:f;delete m
        )
    );close f;true
)
fn caBSProp=
(
    local points=#(),faces=#(),sides=128
    for z in #(0,100)do for i=0 to sides-1 do append points [40*cos(360.0*i/sides),40*sin(360.0*i/sides),z]
    append points [0,0,0];append points [0,0,100]
    for i=1 to sides do(local j=if i==sides then 1 else i+1;join faces #([2*sides+1,j,i],[2*sides+2,i+sides,j+sides],[i,j,j+sides],[i,j+sides,i+sides]))
    local offset=points.count
    join points #([-200,-200,100],[400,-200,100],[400,200,100],[-200,200,100],[-200,-200,120],[400,-200,120],[400,200,120],[-200,200,120])
    for f in #([1,3,2],[1,4,3],[5,6,7],[5,7,8],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,4,8],[3,8,7],[4,1,5],[4,5,8])do append faces(f+[offset,offset,offset])
    local node=mesh name:"BS_Original_Overhang" vertices:points faces:faces
    node.pos=[10000,0,0];node.material=multiMaterial numsubs:2 name:"BS_Original_Materials"
    node.material[1]=standardMaterial name:"BS_Base" diffuse:(color 90 40 20);node.material[2]=standardMaterial name:"BS_Upper" diffuse:(color 20 100 40)
    for i=1 to faces.count do setFaceMatID node i(if i<=sides*4 then 1 else 2)
    meshop.setMapSupport node 1 true;meshop.setNumMapVerts node 1 points.count;meshop.setNumMapFaces node 1 faces.count
    for i=1 to points.count do meshop.setMapVert node 1 i(points[i]/600)
    for i=1 to faces.count do meshop.setMapFace node 1 i faces[i]
    node
)
fn caBSVisual source output=
(
    local a=caBSMesh source,b=caBSMesh output,valid=a.numverts==b.numverts and a.numfaces==b.numfaces and source.material==output.material
    for i=1 to a.numfaces do if(getFace a i)!=(getFace b i)or(getFaceMatID a i)!=(getFaceMatID b i)or(getFaceSmoothGroup a i)!=(getFaceSmoothGroup b i)do valid=false
    if not(meshop.getMapSupport b 1)or(meshop.getNumMapVerts a 1)!=(meshop.getNumMapVerts b 1)or(meshop.getNumMapFaces a 1)!=(meshop.getNumMapFaces b 1)then valid=false
    else(for i=1 to(meshop.getNumMapVerts a 1)do if(meshop.getMapVert a 1 i)!=(meshop.getMapVert b 1 i)do valid=false;for i=1 to(meshop.getNumMapFaces a 1)do if(meshop.getMapFace a 1 i)!=(meshop.getMapFace b 1 i)do valid=false)
    delete a;delete b;valid
)
fn caBSLeaf materialValue id=(if materialValue==undefined then undefined else if isProperty materialValue #materialIDList then(local found=undefined;for i=1 to materialValue.materialIDList.count where materialValue.materialIDList[i]==id do found=materialValue.materialList[i];found)else materialValue)
fn caBSPlantVisual leaves output=
(
    local result=true,m=caBSMesh output,offset=0,uvCorners=0
    for part in leaves do
    (
        local original=caBSMesh part
        for i=1 to original.numfaces do
        (
            if(caBSLeaf part.material(getFaceMatID original i))!=(caBSLeaf output.material(getFaceMatID m(offset+i)))do result=false
            if meshop.getMapSupport original 1 do
            (
                if not(meshop.getMapSupport m 1)then result=false
                else(local wanted=meshop.getMapFace original 1 i,actual=meshop.getMapFace m 1(offset+i);for corner=1 to 3 do(if distance(meshop.getMapVert original 1 wanted[corner])(meshop.getMapVert m 1 actual[corner])>1e-6 do result=false;uvCorners+=1))
            )
        )
        offset+=original.numfaces;delete original
    )
    result=result and offset==m.numfaces and uvCorners>0;delete m;result
)
fn caBSRun=
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    caBSCheck "Exact native in an owned Max2027 host"(caVersion()=="0.3.2"and(maxVersion())[1]==29000)
    local source=caBSProp(),sourceTM=source.transform as string,sourceSnapshot=caBSMesh source
    local floor=cylinder name:"BS_Narrow_Round_Support" radius:42 height:20 sides:128 heightsegs:1 capsegs:1 pos:[0,0,0]
    local owner=caCreateArrangement();owner.name="BS_Arrangement";caBindReceivers owner #(floor)
    local captureStart=timeStamp();caRegisterAssets owner #(source) 7
    append caBSLog("MEASURE synthetic_capture_ms="+((timeStamp()-captureStart)as string))
    local id=(caAssetRows owner)[1][1],support=caAssetSupport owner id
    caBSCheck "Automatic base follows the 80mm foot independently of the 600mm upper body"(support[2].count>4 and support[2].count<=64 and abs(support[1].x+100)<.01 and support[8].x== -300 and support[9].x==300)
    caBSCheck "New arrangement has zero edge gap and capture does not solve"((caPlacementSettings owner)[6]==0 and(caOutputRows owner).count==0 and(caGeometryCacheInfo owner)[3]==undefined)
    local values=caBSValues owner 1,generateStart=timeStamp(),result=caGeneratePlacement owner values false,rows=caOutputRows owner
    append caBSLog("MEASURE synthetic_original_generate_ms="+((timeStamp()-generateStart)as string))
    caBSCheck "Generate finds the complete original prop on narrow circular support"(result[2]==1 and rows.count==1 and rows[1][6]==1 and distance(rows[1][4]) [0,0,20]<.03)
    caBSCheck "Actual output preserves every face material and authored UV"(caBSVisual source rows[1][9])
    caBSExport "round-original" #(floor) #(source) owner
    local pose=caBSPose owner;caGeneratePlacement owner values false
    caBSCheck "Same seed repeats base anchor and complete native poses"(deepEqual pose(caBSPose owner))
    caGeneratePlacement owner values true;max undo
    caBSCheck "One Undo restores source footprint seed and complete original result"(deepEqual pose(caBSPose owner) and deepEqual support(caAssetSupport owner id) and(caPlacementSettings owner)[1]==values[1])
    caBSCheck "Save computed contact footprint in the existing native scene schema"(saveMaxFile(CA_TEST_OUTPUT+"base-support.max")quiet:true)
    loadMaxFile(CA_TEST_OUTPUT+"base-support.max")quiet:true useFileUnits:true
    owner=getNodeByName "BS_Arrangement";source=getNodeByName "BS_Original_Overhang";floor=getNodeByName "BS_Narrow_Round_Support"
    caBSCheck "Reopen preserves computed anchor footprint and complete output"(deepEqual support(caAssetSupport owner id) and deepEqual pose(caBSPose owner))
    caGeneratePlacement owner values false
    caBSCheck "Reopened Generate reconstructs the same physically checked result"(deepEqual pose(caBSPose owner) and caBSVisual source(caOutputRows owner)[1][9])
    local roof=box name:"BS_Actual_Roof" width:1000 length:1000 height:20 pos:[0,0,130]
    caAddObstacles owner #(roof);caGeneratePlacement owner values false
    caBSCheck "Full upper geometry still collides with a real overhead obstruction"((caOutputRows owner).count==0 and(caFitFeedback owner id)[1])
    caRemoveObstacle owner 1(caSetupSummary owner)[3];delete roof
    local small=cylinder name:"BS_Smaller_Support" radius:30 height:20 sides:128 heightsegs:1 capsegs:1 pos:[2000,0,0]
    caBindReceivers owner #(small);caGeneratePlacement owner values false
    caBSCheck "Original-size prop is honestly unfilled on an insufficient support"((caOutputRows owner).count==0)
    values[8]=true;values[9]=.5;caGeneratePlacement owner values false;rows=caOutputRows owner
    caBSCheck "Shrink to fit checks a smaller uniform complete prop within permitted bounds"(rows.count==1 and rows[1][6]>=.5 and rows[1][6]<.751 and caBSVisual source rows[1][9])
    caBSExport "round-fit" #(small) #(source) owner
    local broad=box name:"BS_Broad_Support" width:1500 length:1500 height:20 pos:[4000,0,0]
    caBindReceivers owner #(broad);values=caBSValues owner 3;values[7]=true;values[9]=.8;values[10]=1.1;values[5]=10;caGeneratePlacement owner values false;rows=caOutputRows owner
    caBSCheck "Random scaling repeats complete props without changing the original"(rows.count==3 and rows[1][6]>=.8 and rows[1][6]<=1.1 and abs(rows[1][6]-rows[2][6])>.001 and(source.transform as string)==sourceTM)
    caBSExport "random-three" #(broad) #(source) owner
    local path=splineShape name:"BS_Base_Path";addNewSpline path;addKnot path 1 #corner #line [0,3000,0];addKnot path 1 #corner #line [6000,3000,0];updateShape path
    local along=caCreateArrangement();caBindPath along path 1;caRegisterAssets along #(source) 7
    values=caBSValues along 1;local pathValues=(caPathSettings along)[2];pathValues[2]=1;pathValues[3]=true;pathValues[4]=0;pathValues[6]=0;pathValues[7]=1000;pathValues[9]=true
    caGenerateAlongPath along values pathValues false;rows=caOutputRows along
    caBSCheck "Spline follows actual foot center rather than offset upper-body center"(rows.count==1 and distance(rows[1][4]) [3000,3000,0]<.03 and rows[1][6]==1)
    caBSExport "path-base" #() #(source) along
    pathValues[7]=300;values[8]=true;values[9]=.5;caGenerateAlongPath along values pathValues false;rows=caOutputRows along
    caBSCheck "Path fit preserves foot center while the full body stays inside lane width"(rows.count==1 and rows[1][6]>=.5 and rows[1][6]<.751 and distance(rows[1][4]) [3000,3000,0]<.03)
    caBSExport "path-fit" #() #(source) along
    local after=caBSMesh source,unchanged=(source.transform as string)==sourceTM and after.numverts==sourceSnapshot.numverts and after.numfaces==sourceSnapshot.numfaces
    for i=1 to after.numverts do if(getVert after i)!=(getVert sourceSnapshot i)do unchanged=false
    caBSCheck "All source vertices and original transform stay byte-equivalent through capture fit and paths"unchanged
    delete after;delete sourceSnapshot
    fileIn(CA_TEST_ROOT+"tests/max/real_world_models_data.ms")
    local input=caRWInputSpecs[4],original=CA_TEST_OUTPUT+"Prepared-Plant-Input.max",mapFolder=CA_TEST_OUTPUT+"maps/"
    caBSCheck "Prepared plant source and metadata match their immutable hashes"(caBSHash input[2]==input[3] and caBSHash input[4]==input[5] and copyFile input[2]original and caBSHash original==input[3])
    makeDir mapFolder all:true;local maps=true
    for row in input[8]do if caBSHash row[1]!=row[3]or not(copyFile row[1](mapFolder+row[2]))or caBSHash(mapFolder+row[2])!=row[3]do maps=false
    caBSCheck "All declared plant maps are byte-identical private copies"maps
    local merged=#()
    caBSCheck "Actual prepared scene merges only into this owned process"(mergeMAXFile original #select #autoRenameDups #renameMtlDups #neverReparent quiet:true mergedNodes:&merged includeFullGroup:true ignoreFileUnits:false)
    local heads=for n in merged where isValidNode n and isGroupHead n collect n
    while heads.count>0 do(ungroup heads[1];heads=for n in merged where isValidNode n and isGroupHead n collect n)
    local parts=#()
    for spec in input[7]do(local matches=for n in merged where isValidNode n and n.name==spec[1]collect n;if matches.count!=1 do throw "Complete plant part missing";append parts matches[1])
    caBSCheck "Complete plant retains all three verified pot and foliage parts"(parts.count==3)
    delete(for n in merged where isValidNode n and findItem parts n==0 collect n)
    local pending=for n in parts collect n.material,seen=#()
    while pending.count>0 do
    (
        local item=pending[pending.count];deleteItem pending pending.count
        if item!=undefined and findItem seen item==0 do
        (
            if seen.count>=2048 do throw "Plant material graph admission"
            append seen item
            if isProperty item #filename and item.filename!=""do(local name=(getFilenameFile item.filename)+(getFilenameType item.filename),found=false;for row in input[8]where toLower row[2]==toLower name do found=true;if not found do throw "Unmanifested plant map";item.filename=mapFolder+name)
            if(superClassOf item)==material do for i=1 to getNumSubMtls item do append pending(getSubMtl item i)
            for i=1 to getNumSubTexmaps item do append pending(getSubTexmap item i)
        )
    )
    local plant=group parts name:"BS_Prepared_Complete_Plant"select:false,leaves=caBSLeaves plant
    local originals=for n in leaves collect #(n,n.transform as string,n.material,caBSMesh n)
    local plate=box name:"BS_Plant_Support"width:300 length:300 height:20 pos:[8000,0,0],plantOwner=caCreateArrangement()
    caBindReceivers plantOwner #(plate);captureStart=timeStamp();caRegisterAssets plantOwner #(plant) 3
    append caBSLog("MEASURE prepared_plant_capture_ms="+((timeStamp()-captureStart)as string))
    local plantSupport=caAssetSupport plantOwner(caAssetRows plantOwner)[1][1],plantWidth=plantSupport[9].x-plantSupport[8].x,plantDepth=plantSupport[9].y-plantSupport[8].y
    caBSCheck "Imported complete plant has literal full-size foliage larger than the receiving plate"(abs(plantWidth-488.4006)<.05 and abs(plantDepth-499.9382)<.05)
    generateStart=timeStamp();caGeneratePlacement plantOwner(caBSValues plantOwner 1)false;rows=caOutputRows plantOwner
    append caBSLog("MEASURE prepared_plant_generate_ms="+((timeStamp()-generateStart)as string))
    caBSCheck "Automatic geometric base places the complete prepared plant at original size"(rows.count==1 and rows[1][6]==1)
    caBSCheck "Combined plant output preserves every effective face material and authored UV corner"(caBSPlantVisual leaves rows[1][9])
    caBSExport "prepared-plant" #(plate) #(plant) plantOwner
    unchanged=true
    for state in originals do(local m=caBSMesh state[1];if(state[1].transform as string)!=state[2]or state[1].material!=state[3]or m.numverts!=state[4].numverts or m.numfaces!=state[4].numfaces do unchanged=false;for i=1 to m.numverts do if(getVert m i)!=(getVert state[4]i)do unchanged=false;delete m;delete state[4])
    caBSCheck "Prepared model parts retain their original evaluated vertices transforms and material roots"unchanged
    for row in input[8]do if caBSHash row[1]!=row[3]or caBSHash(mapFolder+row[2])!=row[3]do maps=false
    caBSCheck "Original prepared Max metadata and all maps remain byte-identical"(caBSHash input[2]==input[3]and caBSHash input[4]==input[5]and maps)
    true
)
try(caBSRun())catch(caBSFailures+=1;append caBSLog("EXCEPTION "+(getCurrentException()as string));append caBSLog("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caBSLog("STACK "+(getCurrentExceptionStackTrace()as string)))
caBSFinished=true;caBSWrite()
