module.exports=function(s){
 s=s.replace('version:27','version:28');
 s=s.replace('    parameters radiusSettings (',`    parameters radiusDisplaySettings (
        radiusDisplayLimit type:#integer default:2000
        radiusDisplayAll type:#boolean default:false
        on radiusDisplayLimit set v do dirty=true
        on radiusDisplayAll set v do dirty=true
    )
    parameters radiusSettings (`);
 s=s.replace('#(#updateMode,#showPoints,#pointsPerPlant,#pointColorMode,#solidPointColor,#autoRender)','#(#radiusDisplayLimit,#radiusDisplayAll,#updateMode,#showPoints,#pointsPerPlant,#pointColorMode,#solidPointColor,#autoRender)');
 s=s.replace('            local step=amax 1 (ceil(rows.count/2000.0) as integer)\n            for j=1 to rows.count by step do (',`            local eligible=for j=1 to rows.count where (sourceShows (sourceRow plants[rows[j][2]])) and radii[j]>0 collect j
            local count=if radiusDisplayAll then eligible.count else amin (amax 0 radiusDisplayLimit) eligible.count
            for k=1 to count do (
                local j=eligible[1+(floor((k-1.0)*eligible.count/(amax 1 count)) as integer)]`);
 s=s.replace('    fn drawRadii =','    fn radiusDisplayCount = radiusPreview.count\n    fn drawRadii =');
 s=s.replace(/rollout previewUI "Viewport and Render"[^]*?\n    \)/,b=>{
  b=b.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>Number(y)>=184?`pos:[${x},${Number(y)+78}]`:m);
  b=b.replace('        spinner iconSpin',`        spinner radiusLimitSpin "Radii / layer:" range:[0,1000000,2000] type:#integer fieldWidth:58 width:138 pos:[6,184]
        checkbox radiusAllCheck "Show All Radii" pos:[6,210] width:138
        label radiusHint "Display only; 0 = hide radii" pos:[6,236] width:138
        spinner iconSpin`);
  b=b.replace('        fn syncControls = (','        fn syncControls = (radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;');
  b=b.replace('        on previewCheck changed',`        on radiusLimitSpin changed v do (obj.radiusDisplayLimit=v;obj.refreshAll();syncControls();redrawViews())
        on radiusAllCheck changed v do (obj.radiusDisplayAll=v;obj.refreshAll();syncControls();redrawViews())
        on previewCheck changed`);
  b=b.replace('on previewUI open do (','on previewUI open do (radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;');
  return b;
 });
 return s;
};

