module.exports=function(s){
 s=s.replace('version:32','version:33');
 s=s.replace('    parameters radiusDisplaySettings (',`    parameters viewportGeometrySettings (
        viewportMode type:#integer default:1
        proxyShape type:#integer default:1
        viewportInstances type:#integer default:2000
        viewportFaces type:#integer default:2000000
        on viewportMode set v do dirty=true
        on proxyShape set v do dirty=true
        on viewportInstances set v do dirty=true
        on viewportFaces set v do dirty=true
    )
    parameters radiusDisplaySettings (`);
 s=s.replace('    fn refreshAll = (',`    fn refreshDisplay = (
        for entry in (layerEntries()) do entry[2].refreshPreview()
        redrawViews()
    )
    fn refreshAll = (`);
 s=s.replace('#(#radiusDisplayLimit,#radiusDisplayAll,#updateMode','#(#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#radiusDisplayLimit,#radiusDisplayAll,#updateMode');
 s=s.replace('            cachedPoints=aminScatterBuildPreview data samples colors (if showCenters then 500000 else previewBudget)',`            cachedPoints=if viewportMode==1 then aminScatterBuildPreview data samples colors (if showCenters then 500000 else previewBudget) else cyrusBuildGeometryPreview data (if plants.count==0 then #(-1) else plants) colors (if viewportMode==2 then proxyShape else 4) viewportInstances viewportFaces`);
 // Mesh/proxy mode needs no point-cloud sampling of the source meshes.
 s=s.replace('local samples=if showCenters then','local samples=if viewportMode!=1 then #() else if showCenters then');
 s=s.replace('(cachedPointCount as string)+" points"','(cachedPointCount as string)+(if viewportMode==1 then " points" else " shown instances")');
 s=s.replace('(points as string)+" points"','(points as string)+(if viewportMode==1 then " points" else " shown instances (display limits apply)")');
 s=s.replace(/rollout previewUI "Viewport and Render"[^]*?\n    \)/,b=>{
  b=b.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>Number(y)>=34?`pos:[${x},${Number(y)+160}]`:m);
  b=b.replace('checkbox previewCheck "Point Cloud"','checkbox previewCheck "Show preview"');
  b=b.replace('radiobuttons pointColorRadio "Point Cloud color"','radiobuttons pointColorRadio "Preview color"');
  b=b.replace('button refreshButton "Refresh Point Cloud"','button refreshButton "Refresh preview"');
  b=b.replace('        radiobuttons pointColorRadio',`        dropdownlist displayModeDrop "Display mode" items:#("Point Cloud","Proxy","Mesh") pos:[6,34] width:138
        dropdownlist proxyShapeDrop "Proxy shape" items:#("Box","Sphere","Pyramid") pos:[6,82] width:138
        spinner instancesLimitSpin "Instances/layer:" range:[1,100000,2000] type:#integer fieldWidth:58 pos:[6,138] width:138
        spinner faceLimitSpin "Faces/layer:" range:[12,20000000,2000000] type:#integer fieldWidth:58 pos:[6,166] width:138
        radiobuttons pointColorRadio`);
  b=b.replace('        fn syncControls = (',`        fn syncDisplay = (
            displayModeDrop.selection=obj.viewportMode;proxyShapeDrop.selection=obj.proxyShape
            proxyShapeDrop.visible=obj.viewportMode==2
            instancesLimitSpin.visible=obj.viewportMode!=1;faceLimitSpin.visible=obj.viewportMode!=1
            instancesLimitSpin.value=obj.viewportInstances;faceLimitSpin.value=obj.viewportFaces
            budgetSpin.enabled=obj.viewportMode==1;pointsSpin.enabled=obj.viewportMode==1
        )
        fn syncControls = (syncDisplay();`);
  b=b.replace('        on previewCheck changed',`        on displayModeDrop selected v do (obj.viewportMode=v;obj.refreshAll();syncControls();status.text=obj.allStatus();redrawViews())
        on proxyShapeDrop selected v do (obj.proxyShape=v;obj.refreshAll();syncControls();status.text=obj.allStatus();redrawViews())
        on instancesLimitSpin changed v do (obj.viewportInstances=v;obj.refreshAll();syncControls();status.text=obj.allStatus();redrawViews())
        on faceLimitSpin changed v do (obj.viewportFaces=v;obj.refreshAll();syncControls();status.text=obj.allStatus();redrawViews())
        on previewCheck changed`);
  b=b.replace('on previewUI open do (','on previewUI open do (syncDisplay();');
  b=b.replace(/(on (?:displayModeDrop|proxyShapeDrop|instancesLimitSpin|faceLimitSpin)[^\n]*)/g,line=>line.replace('obj.refreshAll()','obj.refreshDisplay()'));
  return b;
 });
 return s;
};

