// Retained display implements the existing Point Cloud and Mesh modes.
// The helper nodes are disposable, like the existing render transport nodes.
module.exports=function(s){
 const replace=(a,b)=>{if(s.split(a).length!==2)throw Error('Retained preview anchor must be unique: '+a.slice(0,90));s=s.replace(a,b);};
 replace('version:47','version:48');
 replace('aminScatterSourcePoints n pointsPerPlant randomSeed','pointSourceSamples n');
 replace('    fn refreshPreview = (',`    fn pointSourceSamples n = (
        local result=undefined,reason=""
        try(result=aminScatterSourcePoints n pointsPerPlant randomSeed)catch(reason=getCurrentException())
        if reason!="" do throw ("Point Cloud source "+n.name+": "+reason)
        result
    )
    fn refreshPreview = (`);
 replace('        local plants=0;local points=0','        local plants=0;local points=0;local errors=0');
 replace('            plants+=state[5];points+=state[2]', '            plants+=state[5];points+=state[2];if state[4]!="" do errors+=1');
 replace('(if viewportMode==1 then " points" else " shown instances (display limits apply)")',
     '(if viewportMode==1 then " points" else " shown instances (display limits apply)")+(if errors>0 then "; "+(errors as string)+" layer(s) have a preview error" else "")+(if CyrusPointLastError!="" then "; native preview fallback" else "")');
 replace('    local cachedDisabledInput=false','    local cachedDisabledInput=false,cachedDisabledPreview=undefined');
 replace('        if inputOff do return (aminScatterBuildPreview #() #() #() 1)',`        if inputOff do (
            if cachedDisabledPreview==undefined do cachedDisabledPreview=aminScatterBuildPreview #() #() #() 1
            return cachedDisabledPreview
        )`);
 const start=s.indexOf('fn AminScatterObjectDraw = (');
 const end=s.indexOf('registerRedrawViewsCallback AminScatterObjectDraw',start);
 if(start<0||end<0)throw Error('Missing viewport callback');
 s=s.slice(0,start)+`fn AminScatterObjectDraw = (
    local held=CyrusInteractionHeld()
    gw.setTransform (matrix3 1)
    for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
        gw.setTransform n.objectTransform;gw.setColor #line red
        for path in n.baseObject.iconLines() do gw.polyline path false
        gw.setTransform (matrix3 1)
        local caches=#(),styles=#()
        for entry in n.baseObject.viewportLayerEntries held do (
            local obj=entry[2]
            local cache=obj.previewCache interactionHeld:held
            obj.drawRadii()
            if (obj.showPoints or obj.showCenters) and cache!=undefined do (
                if (obj.viewportMode==1 and CyrusPointEnabled) or (obj.viewportMode==3 and CyrusMeshEnabled) then (append caches cache;append styles #(obj.pointColorMode==1,obj.solidPointColor))
                else aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
            )
        )
        local ready=false,owner=CyrusPointOwner n
        if (CyrusPointEnabled or CyrusMeshEnabled) and isValidNode owner do try(ready=cyrusRetainedMatches owner caches styles)catch(CyrusPointLastError=getCurrentException())
        if not ready do (
            for i=1 to caches.count do aminScatterDrawPreview caches[i] styles[i][1] styles[i][2]
            if caches.count>0 and CyrusPointAvailable and not CyrusPointSuspended do (
                local failed=false
                if isValidNode owner do try(failed=(cyrusRetainedStats owner)[12]==2)catch()
                if failed do CyrusPointLastError="Retained preview unavailable; using legacy preview. Refresh preview to retry."
                if not failed do CyrusPointPending=true
            )
        )
    )
    gw.enlargeUpdateRect #whole
)
`+s.slice(end);
 // Resolve these globals when the script is loaded, before any callbacks fire.
 s=`global CyrusPointOwner,CyrusPointSync,CyrusViewportRedraw,CyrusPointClear,CyrusPointAfterSave
global CyrusPointOwners,CyrusPointEnabled=true,CyrusMeshEnabled=true,CyrusPointAvailable=false,CyrusPointBusy=false,CyrusPointPending=false,CyrusPointSuspended=false,CyrusPointLastError="",CyrusPointDeletedHandles=#()
try(CyrusPointClear())catch()
CyrusPointOwners=#()
`+s;
 // Owned UI, source events and undo publish completed caches before requesting
 // redraw. A direct external property edit is caught by the fallback callback
 // and the existing release timer; no node creation happens inside drawing.
 s=s.replace(/\bredrawViews\(\)/g,'CyrusViewportRedraw()');
 replace(' else if CyrusWasDragging do (CyrusWasDragging=false;CyrusViewportRedraw())',
 ` else if CyrusWasDragging or CyrusPointPending do (CyrusWasDragging=false;CyrusPointPending=false;CyrusViewportRedraw())`);
 replace('    if event==#deleted do (handles=for h in handles where findItem CyrusPFDeletedHandles h==0 collect h;',
 '    if event==#deleted do (handles=for h in handles where findItem CyrusPFDeletedHandles h==0 and findItem CyrusPointDeletedHandles h==0 collect h;');
 // Functions are appended before timers can receive their first UI tick.
 s+=`
fn CyrusPointOwner controller = (
    for pair in CyrusPointOwners where pair[1]==controller and isValidNode pair[2] do return pair[2]
    undefined
)
fn CyrusPointDelete nodes = (
    local live=for n in nodes where isValidNode n collect n
    for n in live do appendIfUnique CyrusPointDeletedHandles (getHandleByAnim n)
    if live.count>0 do (
        local wasDirty=getSaveRequired()
        undo off delete live
        if not wasDirty do setSaveRequired false
    )
)
fn CyrusPointClear = (
    CyrusPointPending=false
    local old=CyrusPointOwners;CyrusPointOwners=#()
    if old!=undefined do CyrusPointDelete (for pair in old collect pair[2])
)
fn CyrusPointSync = (
    if CyrusPointBusy or CyrusPointSuspended or AminScatterRenderRedrawHeld==true or CyrusInteractionHeld() do return false
    CyrusPointBusy=true
    try (
        local publishError=""
        local surviving=#()
        for pair in CyrusPointOwners do (
            if isValidNode pair[1] and classof pair[1].baseObject==AminScatterObject and isValidNode pair[2] then append surviving pair
            else CyrusPointDelete #(pair[2])
        )
        CyrusPointOwners=surviving
        for n in (for node in objects where classof node.baseObject==AminScatterObject collect node) do (
            local caches=#(),styles=#()
            if CyrusPointAvailable and not n.isHidden do for entry in n.baseObject.layerEntries() do (
                local obj=entry[2],cache=obj.previewCache interactionHeld:false
                if ((obj.viewportMode==1 and CyrusPointEnabled) or (obj.viewportMode==3 and CyrusMeshEnabled)) and (obj.showPoints or obj.showCenters) and cache!=undefined do (
                    append caches cache;append styles #(obj.pointColorMode==1,obj.solidPointColor)
                )
            )
            local owner=CyrusPointOwner n
            if caches.count>0 and not isValidNode owner and cyrusRetainedCreate!=undefined do (
                local wasDirty=getSaveRequired()
                undo off owner=cyrusRetainedCreate()
                if isValidNode owner do (setTransformLockFlags owner #all;append CyrusPointOwners #(n,owner))
                if not wasDirty do setSaveRequired false
            )
            if isValidNode owner do (
                if not cyrusRetainedPublish owner n caches styles do publishError="Retained preview unavailable; using legacy preview. Refresh preview to retry."
            )
        )
        CyrusPointLastError=publishError
    )catch(CyrusPointLastError=getCurrentException())
    CyrusPointBusy=false
    true
)
fn CyrusViewportRedraw = (
    if not CyrusPointBusy do CyrusPointSync()
    redrawViews()
)
fn CyrusPointBeforeSave = (CyrusPointSuspended=true;CyrusPointClear())
fn CyrusPointAfterSave = (CyrusPointSuspended=false;CyrusPointPending=true)
fn CyrusPointBeforeScene = (CyrusPointSuspended=true;CyrusPointClear())
fn CyrusPointAfterScene = (CyrusPointSuspended=false;CyrusPointDeletedHandles=#();CyrusPointPending=true)
-- Session-only A/B switch. Scene data and placement caches are unchanged.
fn CyrusRetainedPointDrawing enabled = (
    CyrusPointEnabled=enabled;CyrusPointLastError=""
    CyrusPointAvailable=try(cyrusRetainedAvailable())catch(false)
    CyrusViewportRedraw()
    CyrusPointEnabled
)
fn CyrusRetainedMeshDrawing enabled = (
    CyrusMeshEnabled=enabled;CyrusPointLastError=""
    CyrusPointAvailable=try(cyrusRetainedAvailable())catch(false)
    CyrusViewportRedraw()
    CyrusMeshEnabled
)
callbacks.removeScripts id:#CyrusRetainedPoints
callbacks.addScript #filePreSaveProcess "CyrusPointBeforeSave()" id:#CyrusRetainedPoints
callbacks.addScript #filePostSaveProcess "CyrusPointAfterSave()" id:#CyrusRetainedPoints
callbacks.addScript #filePreOpenProcess "CyrusPointBeforeScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPreReset "CyrusPointBeforeScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPreNew "CyrusPointBeforeScene()" id:#CyrusRetainedPoints
callbacks.addScript #filePostOpenProcess "CyrusPointAfterScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPostReset "CyrusPointAfterScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPostNew "CyrusPointAfterScene()" id:#CyrusRetainedPoints
CyrusPointAvailable=try(cyrusRetainedAvailable())catch(false)
CyrusPointPending=true
`;
 return s;
};
