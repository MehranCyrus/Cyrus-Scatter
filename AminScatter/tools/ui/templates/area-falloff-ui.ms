        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[8,378] width:146
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[8,434] width:146
        button fallRemove "Remove Analyzer" pos:[8,462] width:146
        label fallTargetName "" pos:[8,492] width:146 height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[8,534] width:146
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[8,560] width:146 fieldWidth:62
        checkbox fallScaleCheck "Scale ramp" pos:[8,592] width:146
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[8,618] width:146 fieldWidth:62
        button fallScaleEdit "Edit Scale Graph..." pos:[8,648] width:146
        checkbox fallDensityCheck "Density ramp" pos:[8,684] width:146
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[8,710] width:146 fieldWidth:62
        button fallDensityEdit "Edit Density Graph..." pos:[8,740] width:146
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[8,778] width:146 height:56
        fn fallNode = (
            if fallTarget.selection==1 then undefined else (
                local rows=areaList.selection as array
                if rows.count==1 and rows[1]<=obj.areaNodes.count then obj.areaNodes[rows[1]] else undefined
            )
        )
        fn syncFalloff = (
            loadingFall=true
            local n=fallNode(),valid=(fallTarget.selection==1 or isValidNode n)
            local cfg=if valid then obj.getFallConfig n else #(false,0,false,100,#(0,1),false,100,#(0,1))
            fallPick.enabled=fallTarget.selection==1;fallRemove.enabled=fallTarget.selection==1
            fallPick.text=if isValidNode obj.fallAnalyzer then obj.fallAnalyzer.name else "Pick Surface Analyzer"
            fallTargetName.text=if fallTarget.selection==1 then "Full Boundary / inward" else (if valid then n.name+" / "+(if obj.areaModes[findItem obj.areaNodes n]==2 then "outward" else "inward") else "Select exactly one Area line above."
            )
            for c in #(fallDeleteCheck,fallDeleteSpin,fallScaleCheck,fallScaleSpin,fallScaleEdit,fallDensityCheck,fallDensitySpin,fallDensityEdit) do c.enabled=valid
            fallDeleteCheck.checked=cfg[1];fallDeleteSpin.value=cfg[2];fallScaleCheck.checked=cfg[3];fallScaleSpin.value=cfg[4];fallDensityCheck.checked=cfg[6];fallDensitySpin.value=cfg[7]
            loadingFall=false
        )
        fn setFallValue index value = (
            if not loadingFall do (
                local n=fallNode()
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true
