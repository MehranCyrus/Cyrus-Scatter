/* Owned normal Max2027: complete modeled appliance, actual imported furniture,
   original appearance, actual Modify handlers. No computer use/artist install. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global CyrusArrange,caModifierUI,caModifierViewOwner,CoronaShadows
global caDIMakeAppliance,caDIMakeCabinet,caDIBox
global caDILog=#(),caDIPasses=0,caDIFailures=0,caDIFinished=false
fn caDIWrite=(local f=createFile(CA_TEST_OUTPUT+"result.txt");format "% passes=% failures=%\n"(if caDIFinished then(if caDIFailures==0 then "SUCCESS" else "ERROR")else "RUNNING")caDIPasses caDIFailures to:f;for line in caDILog do format "%\n"line to:f;close f)
fn caDICheck label value=(if value then caDIPasses+=1 else caDIFailures+=1;append caDILog((if value then "PASS " else "FAIL ")+label);caDIWrite();if not value do throw("Device/import: "+label);value)
fn caDIEqual a b=deepEqual a b strictCompare:true
fn caDIPose owner=for r in(caOutputRows owner)collect #(r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8])
fn caDIGenerate owner=
(
    local result=caModifierUI.generateButton.pressed()
    append caDILog("GENERATE "+owner.name+" accepted="+(result as string)+" status="+caModifierUI.statusText.text+" settings="+((caPlacementSettings owner)as string)+" poses="+((caDIPose owner)as string))
    append caDILog("CACHE "+((caGeometryCacheInfo owner)as string));caDIWrite();result
)
fn caDIMesh node=(local m=undefined;in coordsys world(m=snapshotAsMesh node renderMesh:false);if m==undefined or m.numverts>20000 or m.numfaces>40000 do throw "Device mesh admission";m)
fn caDIBounds m=(local low=[1e30,1e30,1e30],high=[-1e30,-1e30,-1e30];for i=1 to m.numverts do(local p=getVert m i;for k=1 to 3 do(low[k]=amin low[k]p[k];high[k]=amax high[k]p[k]));#(low,high))
fn caDIHash path=
(
    local stream=(dotNetClass "System.IO.File").OpenRead path,algorithm=(dotNetClass "System.Security.Cryptography.SHA256").Create(),answer=undefined
    try(answer=toLower(substituteString((dotNetClass "System.BitConverter").ToString(algorithm.ComputeHash stream))"-"""))catch(stream.Close();algorithm.Dispose();throw())
    stream.Close();algorithm.Dispose();answer
)
fn caDISignature node=
(
    local m=caDIMesh node,result=#(node.transform as string,node.material,for i=1 to m.numverts collect(getVert m i),for i=1 to m.numfaces collect #((getFace m i),(getFaceMatID m i),(getFaceSmoothGroup m i)))
    if meshop.getMapSupport m 1 do append result #((for i=1 to meshop.getNumMapVerts m 1 collect meshop.getMapVert m 1 i),(for i=1 to meshop.getNumMapFaces m 1 collect meshop.getMapFace m 1 i))
    delete m;result
)
fn caDIPlace node center=(local m=caDIMesh node,b=caDIBounds m;delete m;node.pos+=center-[(b[1].x+b[2].x)*.5,(b[1].y+b[2].y)*.5,b[1].z];node)
fn caDIOpen owner=
(
    max modify mode;modPanel.setPinStack false;select owner
    local modifier=undefined;for m in owner.modifiers where classOf m==CyrusArrange do modifier=m
    if modifier==undefined do throw "Missing actual Arrange modifier"
    modPanel.setCurrentObject modifier node:owner ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caModifierUI!=undefined and caModifierUI.currentSetup()==owner and caModifierUI.hwnd!=0
)
fn caDIVisual source owner=
(
    local original=caDIMesh source,valid=true,corners=0
    for row in(caOutputRows owner)do
    (
        local m=caDIMesh row[9]
        if m.numverts!=original.numverts or m.numfaces!=original.numfaces or row[9].material!=source.material or not(meshop.getMapSupport m 1)do valid=false
        if valid do for i=1 to original.numfaces do
        (
            if(getFace original i)!=(getFace m i)or(getFaceMatID original i)!=(getFaceMatID m i)or(getFaceSmoothGroup original i)!=(getFaceSmoothGroup m i)do valid=false
            local a=meshop.getMapFace original 1 i,b=meshop.getMapFace m 1 i
            for k=1 to 3 do(if(meshop.getMapVert original 1 a[k])!=(meshop.getMapVert m 1 b[k])do valid=false;corners+=1)
        )
        delete m
    );delete original;valid and corners>0
)
fn caDIConfigure owner copies fit minimum=
(
    local view=caModifierViewOwner
    caModifierUI.amountMode.selection=1;view.amountChanged 1;caModifierUI.quantity.value=copies;caModifierUI.spacing.value=15
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true;caModifierUI.seedText.text="7712033"
    view.protectionControls.edgeGap.value=5;view.protectionControls.edgeGap.changed 5
    view.scaleControls.randomScale.checked=false;view.scaleControls.randomScale.changed false
    view.scaleControls.fitScale.checked=fit;view.scaleControls.fitScale.changed fit
    view.scaleControls.minimumScale.value=minimum;view.scaleControls.maximumScale.value=110
    true
)
fn caDIExport label receivers obstacles source owner=
(
    local f=createFile(CA_TEST_OUTPUT+label+"-meshes.txt"),rows=caOutputRows owner,assets=caAssetRows owner
    for kind in #("receiver","source","output")do
    (
        local nodes=case kind of("receiver":receivers+obstacles;"source":#(source);"output":for r in rows collect r[9])
        for i=1 to nodes.count do
        (
            local m=caDIMesh nodes[i]
            format "mesh % % % %\n"kind i m.numverts m.numfaces to:f
            for j=1 to m.numverts do(local p=getVert m j;format "v % % %\n"(formattedPrint(p.x as double)format:".17g")(formattedPrint(p.y as double)format:".17g")(formattedPrint(p.z as double)format:".17g")to:f)
            for j=1 to m.numfaces do(local t=getFace m j;format "f % % % % %\n"(t.x as integer)(t.y as integer)(t.z as integer)(getFaceMatID m j)(getFaceSmoothGroup m j)to:f)
            if kind=="source"do(local b=caDIBounds m,a=(caAssetSupport owner assets[1][1])[1]+[(b[1].x+b[2].x)*.5,(b[1].y+b[2].y)*.5,b[1].z];format "anchor % % %\n"(formattedPrint(a.x as double)format:".17g")(formattedPrint(a.y as double)format:".17g")(formattedPrint(a.z as double)format:".17g")to:f)
            if kind=="output"do(local r=rows[i];format "pose 1 % % % % % % %\n"r[1](formattedPrint(r[4].x as double)format:".17g")(formattedPrint(r[4].y as double)format:".17g")(formattedPrint(r[4].z as double)format:".17g")(formattedPrint r[5]format:".17g")(formattedPrint r[6]format:".17g")r[8]to:f)
            format "end\n"to:f;delete m
        )
    );close f
    f=createFile(CA_TEST_OUTPUT+label+"-settings.txt")
    local a=caPlacementSettings owner
    format "receivers %\nobstacles %\nrequested %\nseed %\nscale % %\nfit %\nrandom %\ngap %\nedge %\n"receivers.count obstacles.count a[3]a[1](formattedPrint a[9]format:".17g")(formattedPrint a[10]format:".17g")a[8]a[7](formattedPrint a[5]format:".17g")(formattedPrint a[6]format:".17g")to:f;close f
    true
)
fn caDIImport name maxHash metadataHash center=
(
    local folder=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Organized Models\Furniture\Coffee_Tables\"+name+"/",path=folder+name+"_Corona.max",metadata=folder+"asset.json",copyPath=CA_TEST_OUTPUT+name+"-Input.max"
    caDICheck(name+" immutable Max and metadata match prepared identities")(caDIHash path==maxHash and caDIHash metadata==metadataHash)
    caDICheck(name+" disposable Max copy is byte-identical")(copyFile path copyPath and caDIHash copyPath==maxHash)
    local merged=#()
    caDICheck(name+" imports its complete evaluated model with unit conversion")(mergeMAXFile copyPath #select #autoRenameDups #renameMtlDups #neverReparent quiet:true mergedNodes:&merged includeFullGroup:true ignoreFileUnits:false)
    local geometry=for n in merged where isValidNode n and superClassOf n==GeometryClass collect n
    caDICheck(name+" retains its single complete original prepared geometry")(geometry.count==1 and merged.count==1)
    local node=geometry[1];node.name="DEVICE_"+name;caDIPlace node center
    #(node,path,maxHash,metadata,metadataHash)
)
fn caDIRender=
(
    max create mode
    local floor=box name:"DEVICE_Studio_Floor"width:10000 length:6000 height:20 pos:[400,0,-20]
    floor.material=standardMaterial name:"DEVICE_Studio_Only"diffuse:(color 170 165 155)
    local aim=targetObject name:"DEVICE_Overview_Target"pos:[250,0,450],camera=targetCamera name:"DEVICE_Overview"pos:[1800,-6500,3300]target:aim lens:40
    local key=omniLight name:"DEVICE_Key"pos:[-1000,-1800,3500]multiplier:.7
    key.baseObject.castShadows=true;key.shadowGenerator=CoronaShadows()
    omniLight name:"DEVICE_Fill"pos:[3000,1200,2500]multiplier:.25
    renderers.current=CoronaRenderer()
    caDICheck "Actual installed Corona renderer offers a bounded preview"(matchPattern((classOf renderers.current)as string)pattern:"*Corona*"and isProperty renderers.current #progressive_passLimit)
    renderers.current.progressive_passLimit=8;renderers.current.progressive_timeLimit=0
    backgroundColor=color 145 145 145;useEnvironmentMap=false;environmentMap=undefined
    local start=timeStamp(),b=render camera:camera outputSize:[1600,1000]outputfile:(CA_TEST_OUTPUT+"CyrusArrange-Device-Imported.png")vfb:false
    caDICheck "Actual original-material device and imported-receiver overview renders"(b.width==1600 and b.height==1000);close b
    append caDILog("MEASURE preview_render_ms="+((timeStamp()-start)as string));caDIWrite();true
)
