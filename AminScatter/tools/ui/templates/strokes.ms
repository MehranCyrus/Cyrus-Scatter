    parameters strokeSettings (
        streetStraight type:#boolean default:false
        on streetStraight set v do dirty=true
        strokeSides type:#intTab tabSize:0 tabSizeVariable:true
        patternPaths type:#nodeTab tabSize:0 tabSizeVariable:true
        strokeModes type:#intTab tabSize:0 tabSizeVariable:true
        strokeColorRows type:#intTab tabSize:0 tabSizeVariable:true
        strokeColorKeys type:#intTab tabSize:0 tabSizeVariable:true
        strokeSourceRows type:#intTab tabSize:0 tabSizeVariable:true
        strokeSourceNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        strokeMin type:#floatTab tabSize:0 tabSizeVariable:true
        strokeMax type:#floatTab tabSize:0 tabSizeVariable:true
        analyzerNode type:#node useNodeTmValidity:true useNodeOsValidity:true
        on analyzerNode set v do dirty=true
    )
    fn syncStrokes = (
        while strokeSides.count<patternLines.count do append strokeSides 1
        for n in patternLines where isValidNode n and findItem patternPaths n==0 do append patternPaths n
        while strokeModes.count<patternLines.count do append strokeModes 1
        while strokeMin.count<patternLines.count do append strokeMin 1.0
        while strokeMax.count<patternLines.count do append strokeMax 1.0
    )
    fn addStroke path side:1 = (
        syncStrokes()
        append patternLines path;append patternWidths (units.decodeValue "1m")
        local key=if sources.count>0 then colorKey(sourceColor 1) else 0
        append strokeSides side;append patternGroups key;append strokeModes 1;append strokeMin 1.0;append strokeMax 1.0
        dirty=true;patternLines.count
    )
    fn removeStroke row = (
        for pair in #(#strokeColorRows,#strokeSourceRows) do (
            local rows=getProperty this pair
            local values=getProperty this (if pair==#strokeColorRows then #strokeColorKeys else #strokeSourceNodes)
            for i=rows.count to 1 by -1 do (
                if rows[i]==row then (deleteItem rows i;deleteItem values i)
                else if rows[i]>row do rows[i]-=1
            )
        )
        for key in #(#strokeSides,#patternLines,#patternWidths,#patternGroups,#strokeModes,#strokeMin,#strokeMax) do deleteItem (getProperty this key) row
        dirty=true
    )
    fn setStrokeSelection row mode values = (
        local rows=if mode==1 then strokeColorRows else strokeSourceRows
        local targets=if mode==1 then strokeColorKeys else strokeSourceNodes
        for i=rows.count to 1 by -1 where rows[i]==row do (deleteItem rows i;deleteItem targets i)
        for value in values do (append rows row;append targets value)
        if mode==1 do patternGroups[row]=if values.count>0 then values[1] else -1
        dirty=true
    )
    fn streetEdgeMask path = (
        if not isProperty path #streetVertices do throw "Update Surface Analyzer to use Street Side."
        local edges=path.packedLines path.streetVertices path.streetCounts,flags=#()
        for loop in (path.packedLines path.boundaryVertices path.boundaryCounts) do for i=1 to loop.count do (
            local a=loop[i],b=loop[if i==loop.count then 1 else i+1],keep=false
            for edge in edges where edge.count==2 do (
                if ((distance a edge[1]<.00001 and distance b edge[2]<.00001) or (distance a edge[2]<.00001 and distance b edge[1]<.00001)) do keep=true
            )
            append flags keep
        )
        flags
    )
    fn lineInputs plants = (
        if diversityMode!=3 and diversityMode!=4 then #(false,0,#()) else (
            syncStrokes()
            if diversityMode==4 and not isValidNode analyzerNode do throw "Pick a Surface Analyzer."
            local keys=for n in plants collect colorKey(sourceColor(findItem sources n))
            local rest=0 -- retained wire format; outside strokes is always empty
            local bands=#();local paths=#();local totals=#()
            for i=1 to patternLines.count where isValidNode patternLines[i] and (if diversityMode==4 then patternLines[i]==analyzerNode else not isProperty patternLines[i] #samplePoints) do (
                local path=patternLines[i];local pathIndex=findItem paths path
                if pathIndex==0 do (append paths path;append totals #(0.0,0.0,0.0,0.0,0.0,0.0);pathIndex=paths.count)
                local side=strokeSides[i]
                local start=totals[pathIndex][side]
                totals[pathIndex][side]+=patternWidths[i]
                local choices=#()
                if strokeModes[i]==1 then (
                    local groups=for j=1 to strokeColorRows.count where strokeColorRows[j]==i collect strokeColorKeys[j]
                    if groups.count==0 do groups=#(patternGroups[i])
                    choices=for j=1 to plants.count where findItem groups keys[j]>0 collect j
                ) else (
                    for j=1 to strokeSourceRows.count where strokeSourceRows[j]==i do (
                        local k=findItem plants strokeSourceNodes[j]
                        if k>0 and findItem choices k==0 do append choices k
                    )
                )
                if choices.count==0 do throw ("Stroke "+(i as string)+": select a color group or Source Object.")
                if diversityMode==4 then (
                    local data=case side of (
                        1: (path.packedLines path.boundaryVertices path.boundaryCounts)
                        2: (path.packedLines path.boundaryVertices path.boundaryCounts)
                        6: (path.packedLines path.boundaryVertices path.boundaryCounts)
                        3: (path.packedLines path.pathVertices path.pathCounts)
                        default: (#(path.samplePoints as array))
                    )
                    local mask=if side==6 then streetEdgeMask path else if side<=2 and isProperty path #includeStreetBoundary then path.boundaryEdgeMask() else #()
                    append bands #(data,totals[pathIndex][side],rest,choices,strokeMin[i],strokeMax[i],(side==2 or side==6),(if side==6 then 2 else side),start,mask,(side==6 and streetStraight))
                ) else append bands #(path,totals[pathIndex][side],rest,choices,strokeMin[i],strokeMax[i],side==2)
            )
            #(true,rest,bands)
        )
    )

