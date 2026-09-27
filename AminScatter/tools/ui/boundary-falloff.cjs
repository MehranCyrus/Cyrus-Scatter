module.exports=function(s){
 const fields=['fallAnalyzer','fallDelete','fallDeleteWidth','fallScale','fallScaleWidth','fallScaleCurve','fallDensity','fallDensityWidth','fallDensityCurve'];
 s=s.replace('version:35','version:36');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#('+fields.map(k=>'#'+k).join(',')+',');
 s=s.replace('AminScatterLayerTabs=#(','AminScatterLayerTabs=#(#fallScaleCurve,#fallDensityCurve,');
 s=s.replace('    parameters edgeRowSettings (',`    local cachedFallRun=-1
    parameters falloffSettings (
        fallAnalyzer type:#node useNodeTmValidity:true useNodeOsValidity:true
        fallDelete type:#boolean default:false
        fallDeleteWidth type:#worldunits default:0
        fallScale type:#boolean default:false
        fallScaleWidth type:#worldunits default:100
        fallScaleCurve type:#floatTab tabSize:0 tabSizeVariable:true
        fallDensity type:#boolean default:false
        fallDensityWidth type:#worldunits default:100
        fallDensityCurve type:#floatTab tabSize:0 tabSizeVariable:true
${fields.map(k=>`        on ${k} set v${k.endsWith('Curve')?' i':''} do dirty=true`).join('\n')}
    )
    fn ensureFallCurves = (
        while fallScaleCurve.count<5 do append fallScaleCurve (fallScaleCurve.count/4.0)
        while fallDensityCurve.count<5 do append fallDensityCurve (fallDensityCurve.count/4.0)
    )
    fn applyFalloff rows = (
        if not (fallDelete or fallScale or fallDensity) then rows else (
            if not (CyrusAnalyzerFilter fallAnalyzer) do throw "Area Edge Falloff: pick a Surface Analyzer."
            ensureFallCurves()
            local paths=fallAnalyzer.packedLines fallAnalyzer.boundaryVertices fallAnalyzer.boundaryCounts
            if paths.count==0 do throw "Area Edge Falloff: Analyzer has no Boundary. Run Analyze first."
            cyrusBoundaryFalloff rows paths #(fallDelete,fallDeleteWidth,fallScale,fallScaleWidth,fallScaleCurve as array,fallDensity,fallDensityWidth,fallDensityCurve as array) randomSeed
        )
    )
    parameters edgeRowSettings (`);
 s=s.replace('        if plants.count>0 and sourceEmpty.count>0 do result=', '        result=applyFalloff result\n        if plants.count>0 and sourceEmpty.count>0 do result=');
 s=s.replace('            join inputs (areaNodes as array)','            join inputs (areaNodes as array)\n            if isValidNode fallAnalyzer do append inputs fallAnalyzer');
 s=s.replace('        cachedAnalyzerRun=if diversityMode', '        cachedFallRun=if isValidNode fallAnalyzer then fallAnalyzer.getAnalysisRuns() else -1\n        cachedAnalyzerRun=if diversityMode');
 s=s.replace('    fn previewCache = (','    fn previewCache = (\n        if updateMode==2 and isValidNode fallAnalyzer and (fallDelete or fallScale or fallDensity) do if cachedFallRun!=fallAnalyzer.getAnalysisRuns() do dirty=true');
 s=s.replace('     if obj.diversityMode==4 and isValidNode obj.analyzerNode do format','     if isValidNode obj.fallAnalyzer and (obj.fallDelete or obj.fallScale or obj.fallDensity) do format "|Falloff:%|" (obj.fallAnalyzer.getAnalysisRuns()) to:s\n     if obj.diversityMode==4 and isValidNode obj.analyzerNode do format');
 s=s.replace(/rollout (areaUI(?:_\d+)?) "[^]*?\n    \)/g,b=>{
  b=b.replace('        fn updateAreas = (',`        local loadingFall=false
        label fallHeading "Boundary Edge Falloff" pos:[8,378] width:146
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[8,404] width:146
        button fallRemove "Remove Analyzer" pos:[8,432] width:146
        checkbox fallDeleteCheck "Delete edge band" pos:[8,464] width:146
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[8,490] width:146 fieldWidth:62
        checkbox fallScaleCheck "Scale ramp" pos:[8,522] width:146
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[8,548] width:146 fieldWidth:62
        checkbox fallDensityCheck "Density ramp" pos:[8,580] width:146
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[8,606] width:146 fieldWidth:62
        dropdownlist fallCurveChoice "Edit curve" items:#("Scale multiplier","Density fraction") selection:1 pos:[8,642] width:146
        dotNetControl fallGraph "System.Windows.Forms.PictureBox" pos:[8,686] width:146 height:90
        dropdownlist fallKnot "Distance along ramp" items:#("0%","25%","50%","75%","100%") selection:1 pos:[8,786] width:146
        spinner fallValue "Value:" range:[0,1000,0] type:#float pos:[8,836] width:146 fieldWidth:62
        label fallHelp "Click graph to edit. Density: 0 to 1. Ramps start after delete band." pos:[8,866] width:146 height:56
        fn drawFallCurve = (
            local values=if fallCurveChoice.selection==2 then obj.fallDensityCurve else obj.fallScaleCurve
            local ceiling=if fallCurveChoice.selection==2 then 1.0 else amax 1.0 (amax (values as array))
            local bitmap=dotNetObject "System.Drawing.Bitmap" 240 120
            local g=(dotNetClass "System.Drawing.Graphics").FromImage bitmap
            g.Clear ((dotNetClass "System.Drawing.Color").FromArgb 42 42 42)
            local pen=dotNetObject "System.Drawing.Pen" ((dotNetClass "System.Drawing.Color").LimeGreen) 2.0
            for i=1 to 4 do g.DrawLine pen (dotNetObject "System.Drawing.Point" ((i-1)*59+2) (116-(values[i]/ceiling*112) as integer)) (dotNetObject "System.Drawing.Point" (i*59+2) (116-(values[i+1]/ceiling*112) as integer))
            g.Dispose();pen.Dispose()
            local previous=fallGraph.Image;fallGraph.SizeMode=(dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage;fallGraph.Image=bitmap
            if previous!=undefined do previous.Dispose()
        )
        fn syncFalloff = (
            loadingFall=true;obj.ensureFallCurves()
            fallPick.text=if isValidNode obj.fallAnalyzer then obj.fallAnalyzer.name else "Pick Surface Analyzer"
            fallDeleteCheck.checked=obj.fallDelete;fallDeleteSpin.value=obj.fallDeleteWidth
            fallScaleCheck.checked=obj.fallScale;fallScaleSpin.value=obj.fallScaleWidth
            fallDensityCheck.checked=obj.fallDensity;fallDensitySpin.value=obj.fallDensityWidth
            local values=if fallCurveChoice.selection==2 then obj.fallDensityCurve else obj.fallScaleCurve
            fallValue.value=values[amax 1 fallKnot.selection]
            drawFallCurve();loadingFall=false
        )
        fn setFallValue value = (
            local k=amax 1 fallKnot.selection
            if fallCurveChoice.selection==2 then obj.fallDensityCurve[k]=amin 1.0 (amax 0.0 value) else obj.fallScaleCurve[k]=amax 0.0 value
            syncFalloff();redrawViews()
        )
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do if not loadingFall do (obj.fallDelete=v;redrawViews())
        on fallScaleCheck changed v do if not loadingFall do (obj.fallScale=v;redrawViews())
        on fallDensityCheck changed v do if not loadingFall do (obj.fallDensity=v;redrawViews())
        on fallDeleteSpin changed v do if not loadingFall do (obj.fallDeleteWidth=v;redrawViews())
        on fallScaleSpin changed v do if not loadingFall do (obj.fallScaleWidth=v;redrawViews())
        on fallDensitySpin changed v do if not loadingFall do (obj.fallDensityWidth=v;redrawViews())
        on fallCurveChoice selected v do syncFalloff()
        on fallKnot selected v do syncFalloff()
        on fallValue changed v do if not loadingFall do setFallValue v
        on fallGraph MouseDown sender e do (
            local values=if fallCurveChoice.selection==2 then obj.fallDensityCurve else obj.fallScaleCurve
            local ceiling=if fallCurveChoice.selection==2 then 1.0 else amax 1.0 (amax (values as array))
            fallKnot.selection=amin 5 (amax 1 (1+(floor(4.0*e.X/(amax 1 sender.Width)+0.5) as integer)))
            setFallValue ((1.0-e.Y/(amax 1 (sender.Height as float)))*ceiling)
        )
        fn updateAreas = (`);
  b=b.replace(/on (areaUI(?:_\d+)?) open do \(/,'on $1 open do (syncFalloff();');return b;
 });return s;
};
