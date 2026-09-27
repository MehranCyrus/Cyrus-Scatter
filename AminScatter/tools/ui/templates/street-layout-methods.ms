    parameters streetLayoutSettings (
        streetTrimStart type:#worldunits default:0
        streetTrimEnd type:#worldunits default:0
        centerStreetOffset type:#worldunits default:0
        on streetTrimStart set v do dirty=true
        on streetTrimEnd set v do dirty=true
        on centerStreetOffset set v do dirty=true
    )
    fn centerStreetPaths analyzer = (
        local paths=analyzer.packedLines analyzer.pathVertices analyzer.pathCounts
        if centerStreetOffset==0 then paths else (
            local streets=analyzer.packedLines analyzer.streetVertices analyzer.streetCounts
            if streets.count==0 do throw "Center Line offset: Analyzer has no Street Side."
            for path in paths collect (for p in path collect (
                local nearest=undefined,best=1e30
                for edge in streets do for j=1 to edge.count-1 do (
                    local a=edge[j],b=edge[j+1],v=[b.x-a.x,b.y-a.y,0],d=dot v v
                    if d>0 do (
                        local q=a+v*(amax 0.0 (amin 1.0 (dot ([p.x-a.x,p.y-a.y,0]) v/d)))
                        local delta=[p.x-q.x,p.y-q.y,0],ds=dot delta delta
                        if ds<best do (best=ds;nearest=delta)
                    )
                )
                if nearest==undefined or best<1e-12 then p else p+(normalize nearest)*centerStreetOffset
            ))
        )
    )
    fn trimmedStreetData analyzer = (
        local loops=analyzer.packedLines analyzer.boundaryVertices analyzer.boundaryCounts
        local flags=streetEdgeMask analyzer
        if streetTrimStart==0 and streetTrimEnd==0 then #(loops,flags) else (
            local output=#(),mask=#(),offset=0
            for loop in loops do (
                local n=loop.count,lens=#(),selected=#(),verts=#()
                for i=1 to n do (append lens (distance loop[i] loop[if i==n then 1 else i+1]);append selected flags[offset+i])
                local allSelected=(findItem selected false)==0
                for i=1 to n do (
                    local a=loop[i],b=loop[if i==n then 1 else i+1],len=lens[i],cuts=#(0.0,1.0),before=0.0,total=len
                    if selected[i] and not allSelected and len>1e-9 do (
                        local j=if i==1 then n else i-1
                        while selected[j] and j!=i do (before+=lens[j];j=if j==1 then n else j-1)
                        total+=before;j=if i==n then 1 else i+1
                        while selected[j] and j!=i do (total+=lens[j];j=if j==n then 1 else j+1)
                        for d in #(streetTrimStart,total-streetTrimEnd) do (
                            local t=(d-before)/len
                            if t>0.000001 and t<0.999999 and findItem cuts t==0 do append cuts t
                        )
                        sort cuts
                    )
                    for k=1 to cuts.count-1 do (
                        append verts (a+(b-a)*cuts[k])
                        local along=before+len*(cuts[k]+cuts[k+1])*0.5
                        append mask (selected[i] and (allSelected or (along>=streetTrimStart and along<=total-streetTrimEnd)))
                    )
                )
                append output verts;offset+=n
            )
            #(output,mask)
        )
    )
