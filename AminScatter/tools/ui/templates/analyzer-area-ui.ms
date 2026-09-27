        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[8,378] width:146
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[8,404] width:146
        button aaRemove "Remove Area Analyzer" pos:[8,432] width:146
        checkbox aaLine "Center Line" pos:[8,464] width:146
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[8,490] width:146 fieldWidth:62
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[8,518] width:146
        checkbox aaPoints "Points" pos:[8,572] width:146
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[8,598] width:146 fieldWidth:62
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[8,628] width:146 height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())
