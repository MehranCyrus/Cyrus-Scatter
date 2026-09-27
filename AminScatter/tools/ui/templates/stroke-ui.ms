    rollout lineUI "Line Pattern" width:#cmdPanel (
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[8,8] width:146
        dropdownlist pathsDrop "Paths" items:#() pos:[8,32] width:146
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side") pos:[8,32] width:146
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[8,82] width:146
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[8,82] width:146
        button removePath "Remove path" pos:[8,108] width:146
        listbox strokesList "Consecutive strokes" items:#() pos:[8,140] width:146 height:4
        button addOutside "Add Outside" pos:[8,236] width:70
        button addInside "Add Inside" pos:[84,236] width:70
        button removeStrokeButton "Remove Stroke" pos:[8,262] width:146
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[8,296] width:146 fieldWidth:64
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[8,324] width:146
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[8,396] width:146 height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[8,508] width:146 fieldWidth:58
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[8,534] width:146 fieldWidth:58
        button refreshGroups "Refresh sources / groups" pos:[8,566] width:146
        label strokeHelp "Outside strokes: empty." pos:[8,594] width:146
        checkbox straightStreet "Straight ends (Street Side)" pos:[8,620] width:146
        on straightStreet changed v do (streetStraight=v;dirty=true;redrawViews())
        fn selectedStroke = (if strokesList.selection>0 and strokesList.selection<=strokeRows.count then strokeRows[strokesList.selection] else 0)
        fn showStroke = (
            loadingStroke=true
            local row=selectedStroke();local active=row>0
            for c in #(strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,removeStrokeButton) do c.enabled=active
            choiceValues=#();strokeChoices.items=#()
            if active do (
                strokeWidth.value=patternWidths[row];strokeMode.state=strokeModes[row]
                strokeWidth.enabled=strokeSides[row]!=5
                strokeScaleMin.value=strokeMin[row];strokeScaleMax.value=strokeMax[row]
                local labels=#();local selectedRows=#{}
                if strokeModes[row]==1 then (
                    for i=1 to sources.count do (
                        local key=colorKey(sourceColor i)
                        if findItem choiceValues key==0 do (append choiceValues key;append labels ("#"+(formattedPrint key format:"06X")))
                    )
                    local keys=for i=1 to strokeColorRows.count where strokeColorRows[i]==row collect strokeColorKeys[i]
                    if keys.count==0 do keys=#(patternGroups[row])
                    for i=1 to choiceValues.count where findItem keys choiceValues[i]>0 do selectedRows[i]=true
                ) else (
                    for n in sources where isValidNode n do (append choiceValues n;append labels n.name)
                    for i=1 to strokeSourceRows.count where strokeSourceRows[i]==row do (
                        local k=findItem choiceValues strokeSourceNodes[i];if k>0 do selectedRows[k]=true
                    )
                )
                strokeChoices.items=labels;strokeChoices.selection=selectedRows
            )
            loadingStroke=false
        )
        fn showPath = (
            loadingStroke=true
            local old=strokesList.selection;strokeRows=#();local labels=#();local total=#(0.0,0.0,0.0,0.0,0.0,0.0)
            local analyzed=diversityMode==4
            local path=if analyzed then analyzerNode else (if pathsDrop.selection>0 then pathRows[pathsDrop.selection] else undefined)
            if isValidNode path do (
                for i=1 to patternLines.count where patternLines[i]==path and (not analyzed or (analyzerChannel.selection==1 and strokeSides[i]<=2) or (analyzerChannel.selection==2 and strokeSides[i]==3) or (analyzerChannel.selection==3 and (strokeSides[i]==4 or strokeSides[i]==5)) or (analyzerChannel.selection==4 and strokeSides[i]==6)) do (
                    append strokeRows i
                    local side=strokeSides[i];local start=total[side];total[side]+=patternWidths[i]
                    local prefixes=#("Out ","In ","Both ","Radius ","Single ","Street ")
                    append labels (prefixes[side]+(strokeRows.count as string)+": "+units.formatValue start+" - "+units.formatValue total[side])
                )
            )
            strokesList.items=labels;strokesList.selection=amin (amax 1 old) labels.count
            addOutside.enabled=isValidNode path;addInside.enabled=isValidNode path and (not analyzed or analyzerChannel.selection!=2);removePath.enabled=isValidNode path
            loadingStroke=false;showStroke()
        )
        fn updatePattern = (
            straightStreet.checked=streetStraight;straightStreet.visible=diversityMode==4 and analyzerChannel.selection==4
            syncStrokes();local old=pathsDrop.selection
            local analyzed=diversityMode==4
            pathRows=for n in patternPaths where isValidNode n and not isProperty n #samplePoints collect n
            pathsDrop.items=for n in pathRows collect n.name
            pathsDrop.selection=amin (amax 1 old) pathRows.count
            pathsDrop.visible=diversityMode==3;pickPath.visible=diversityMode==3
            analyzerChannel.visible=analyzed;pickAnalyzer.visible=analyzed
            pickAnalyzer.text=if isValidNode analyzerNode then analyzerNode.name else "Pick Surface Analyzer"
            removePath.text=if analyzed then "Remove Analyzer" else "Remove path"
            strokeTitle.text=if analyzed then "Analyze Surface / Strokes" else "Line Pattern / Strokes"
            addOutside.text=if not analyzed or analyzerChannel.selection==1 then "Add Outside" else (if analyzerChannel.selection==2 then "Add Stroke" else "Add Radius")
            addInside.text=if analyzed and analyzerChannel.selection==3 then "Add Single" else "Add Inside"
            local boundaryOnly=analyzed and (analyzerChannel.selection==1 or analyzerChannel.selection==4)
            addOutside.visible=(diversityMode==3 or analyzed) and not boundaryOnly
            addInside.pos=[if boundaryOnly then 8 else 84,addOutside.pos.y]
            addInside.width=if boundaryOnly then 146 else 70
            if boundaryOnly do addInside.text="Add Stroke Inside"
            strokeHelp.text=if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to sources.count do (local key=colorKey(sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )
        on lineUI open do updatePattern()
        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (analyzerNode=n;dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem patternPaths n==0 do append patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if diversityMode==4 then analyzerNode else pathRows[pathsDrop.selection]
            for i=patternLines.count to 1 by -1 where patternLines[i]==path do removeStroke i
            local k=findItem patternPaths path;if k>0 do deleteItem patternPaths k
            if diversityMode==4 do analyzerNode=undefined
            updatePattern();dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4) do return false
            local path=if diversityMode==4 then analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if diversityMode==4 then types[analyzerChannel.selection] else 1
            addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if diversityMode==4 then analyzerNode else pathRows[pathsDrop.selection]
            local side=if diversityMode==4 and analyzerChannel.selection==4 then 6 else if diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do removeStroke row;showPath();redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do patternWidths[row]=v;dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do strokeModes[row]=v;showStroke();dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do setStrokeSelection row strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();strokeMin[row]=v;if v>strokeMax[row] do strokeMax[row]=v;showStroke();dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();strokeMax[row]=v;if v<strokeMin[row] do strokeMin[row]=v;showStroke();dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()
    )

