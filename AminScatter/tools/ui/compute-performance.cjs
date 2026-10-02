// Each source policy is evaluated once, then stable filtering runs natively.
// Stage ordering is unchanged: falloff hashes still see the original row indices.
module.exports=function(s){
 const replace=(a,b)=>{if(!s.includes(a))throw Error('Compute performance anchor missing: '+a.slice(0,90));s=s.replace(a,b);};
 replace('version:44','version:45');
 s='global cyrusFilterSourceRows,cyrusApplySourceTransforms\n'+s;
 replace('    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (',`    fn filterSourceRowsByPolicy rows keep = (
        if cyrusFilterSourceRows!=undefined then cyrusFilterSourceRows rows keep
        else (for row in rows where keep[row[2]] collect row)
    )
    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (`);
 replace('if plants.count>0 and sourceEmpty.count>0 do result=for row in result where (not (isEmptySource (sourceRow plants[row[2]])) or (isPointSource (sourceRow plants[row[2]]))) collect row',
 `if plants.count>0 and sourceEmpty.count>0 do (
            local keep=for n in plants collect (not (isEmptySource (sourceRow n)) or isPointSource (sourceRow n))
            result=filterSourceRowsByPolicy result keep
        )`);
 replace('if not previewOnly and not rawOnly and plants.count>0 do result=for row in result where not (isPointSource (sourceRow plants[row[2]])) collect row',
 `if not previewOnly and not rawOnly and plants.count>0 do (
            local keep=for n in plants collect (not (isPointSource (sourceRow n)))
            result=filterSourceRowsByPolicy result keep
        )`);
 const transform=`            for row in result do (
                local tm=row[1], k=row[2], factor=scales[k]
                tm.row1=tm.row1*factor;tm.row2=tm.row2*factor;tm.row3=tm.row3*factor
                tm.row4=tm.row4+[0,0,offsets[k]]
                row[1]=tm
            )`;
 replace(transform,`            if cyrusApplySourceTransforms!=undefined then result=cyrusApplySourceTransforms result offsets scales
            else (
${transform}
            )`);
 // Autodesk delivers all queued node notifications in one callback batch. Apply
 // every invalidation, then request one redraw at its end instead of rebuilding
 // the same controller between geometry/topology/controller notifications.
 replace('fn AminScatterLiveChanged event handles = (',`global CyrusLiveBatchDepth=0,CyrusLiveBatchRedraw=false,CyrusLiveBatchCount=0,CyrusLiveRedrawRequests=0,CyrusLiveChangeCalls=0
fn CyrusScatterLiveBatchStats = (#(CyrusLiveBatchCount,CyrusLiveRedrawRequests,CyrusLiveBatchDepth,CyrusLiveBatchRedraw,CyrusLiveChangeCalls))
fn CyrusScatterLiveBatchBegin event handles = (
    if CyrusLiveBatchDepth==0 do CyrusLiveBatchRedraw=false
    CyrusLiveBatchDepth+=1
)
fn CyrusScatterLiveBatchEnd event handles = (
    CyrusLiveBatchDepth=amax 0 (CyrusLiveBatchDepth-1)
    if CyrusLiveBatchDepth==0 do (
        CyrusLiveBatchCount+=1
        local wanted=CyrusLiveBatchRedraw
        CyrusLiveBatchRedraw=false
        if wanted and AminScatterRenderRedrawHeld!=true do (CyrusLiveRedrawRequests+=1;redrawViews())
    )
)
fn AminScatterLiveChanged event handles = (
    CyrusLiveChangeCalls+=1`);
 replace('        if redraw do redrawViews()',`        if redraw do (
            if CyrusLiveBatchDepth>0 then CyrusLiveBatchRedraw=true
            else (CyrusLiveRedrawRequests+=1;redrawViews())
        )`);
 replace('AminScatterNodeEvents=NodeEventCallback mouseUp:true delay:150',
 'AminScatterNodeEvents=NodeEventCallback mouseUp:true delay:150 callbackBegin:CyrusScatterLiveBatchBegin callbackEnd:CyrusScatterLiveBatchEnd');
 return s;
};
