-- Native MAXScript fixture; private scene only, no artist files/profile changes.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-grid0850-*/" do throw "Owned grid host required."
    if (maxVersion())[1]!=29000 or cyrusGridVersion()!=1 or cyrusRecipeVersion()!=4 or cyrusPresetVersion()!=3 do throw "Matched Max 2027 grid pair required."
    local log=createFile (MCPFixtureDir+"grid-core-"+(timeStamp() as string)+".txt")
    fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    fn equalRows a b = (
        if a.count!=b.count do return false
        for i=1 to a.count do (if a[i].count!=8 or b[i].count!=8 do return false;for j=1 to 8 where a[i][j]!=b[i][j] do return false)
        true
    )
    fn near a b = (abs(a-b)<0.0001)
    fn gridUpdate root = (root.refreshAll();for leaf in root.layerObjects where leaf.previewError!="" do throw leaf.previewError)
    fn rowsCommon base changed = (
        local common=0
        for row in base do for other in changed where row[3]==other[3] do (
            -- Enlarging terrain may change face index/barycentrics; compare
            -- identity, complete transform, source, Band and protection fields.
            for index in #(1,2,3,6,7,8) where row[index]!=other[index] do throw "Surviving cell changed placement attributes"
            common+=1
        )
        common
    )
    try (
        if theHold.Holding() do (format "FIXTURE: cancel previous owned preparation hold\n" to:log;theHold.Cancel())
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node,root,leaf,terrain,source
        undo off (
            units.SystemType=#meters;units.SystemScale=1
            terrain=plane name:"Grid terrain" width:20 length:20 widthsegs:4 lengthsegs:4
            source=pyramid name:"Grid pyramid" width:0.7 depth:0.7 height:2 pos:[-30,0,0];convertToMesh source
            node=AminScatterObject name:"Grid qualification";root=node.baseObject
            root.updateMode=1;root.autoRender=false;root.newLayer();leaf=root.selectedLayer()
            root.setLayerSurfaces leaf #(terrain);leaf.sources=#(source);leaf.ensureSourceRows()
            leaf.placementMode=2;leaf.gridColumnWU=5;leaf.gridRowWU=5
            leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
            leaf.scaleMinimum=1;leaf.scaleMaximum=1;leaf.tiltDegrees=0;leaf.movementRange=0;leaf.yawMinimum=0;leaf.yawMaximum=0
            gridUpdate root
        )
        local baseline=deepCopy root.groupSnapshotRows[1]
        check (baseline.count==25) "Rectangular 20x20 terrain / five-unit pitch gives 25 inclusive lattice cells" log
        for row in baseline do (
            local pos=row[1].row4
            check (near (mod (pos.x+10) 5) 0 and near (mod (pos.y+10) 5) 0 and near pos.z 0) "Analytic world lattice position" log
        )
        for row in leaf.paintBaseRows do check (classof row[3]==Integer64) "Raw cell identity stays Integer64 across MAXScript" log
        local gridBefore=cyrusGridStats()
        root.bindNativeUI();root.bindNativeUI()
        check ((cyrusGridStats())[1]==gridBefore[1] and equalRows baseline root.groupSnapshotRows[1]) "Binding UI does not project grids or change rows" log
        undo "Grid heading test" on leaf.gridHeading=30
        check (equalRows baseline root.groupSnapshotRows[1]) "Manual grid edit retains previous complete publication" log
        gridUpdate root
        check (not equalRows baseline root.groupSnapshotRows[1]) "Explicit Update applies grid heading" log
        max undo;gridUpdate root
        check (leaf.gridHeading==0 and equalRows baseline root.groupSnapshotRows[1]) "Undo restores full rectangular result" log
        max redo;gridUpdate root
        check (leaf.gridHeading==30) "Redo restores authored heading" log
        undo off (leaf.gridHeading=0;leaf.placementMode=3;gridUpdate root)
        check (root.groupSnapshotRows[1].count==23) "Staggered layout offsets negative and positive odd rows" log
        undo off (leaf.placementMode=4;gridUpdate root)
        local hexRows=root.groupSnapshotRows[1]
        for row in hexRows do (
            local closest=1e20
            for other in hexRows where row[3]!=other[3] do closest=amin closest (distance row[1].row4 other[1].row4)
            check (near closest 5) "Hexagonal nearest-neighbor spacing equals authored pitch" log
        )
        undo off (leaf.placementMode=2;leaf.gridJitter=25;leaf.yawMaximum=360;leaf.scaleMinimum=0.5;leaf.scaleMaximum=1.5;gridUpdate root)
        baseline=deepCopy root.groupSnapshotRows[1]
        undo off (terrain.width=30;terrain.length=30;gridUpdate root)
        check ((rowsCommon baseline root.groupSnapshotRows[1])==baseline.count) "Growing receiver preserves every common jittered cell transform and source" log
        local builds=(cyrusGridStats())[1]
        undo off (leaf.orientationBlend=50;gridUpdate root)
        check ((cyrusGridStats())[1]==builds) "Orientation-only edit reuses projected grid snapshot" log
        local document=CyrusRecipeCapture root #(leaf) "Grid fixture",settings=CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeCapture root #(leaf) "Grid fixture") "layers")[1] "settings"
        check (CyrusRecipeGet document "formatVersion"==4 and CyrusRecipeGet settings "placementMode"==2 and CyrusRecipeGet settings "gridColumnWU"==5) "Complete recipe captures grid mode and distances" log
        check ((cyrusGridStats())[1]==builds) "Recipe capture does not project grids" log
        local copied=root.copyLogicalLayer leaf variation:#same
        gridUpdate root
        check (equalRows root.groupSnapshotRows[1] root.groupSnapshotRows[2]) "Same variation copy preserves all eight grid placement fields" log
        local bindings=CyrusRecipeSuggestBindings root document,result=CyrusRecipeImport root document bindings variation:#same
        gridUpdate root
        check (equalRows root.groupSnapshotRows[1] root.groupSnapshotRows[3]) "Saved variation recipe import preserves full grid rows" log
        local held=for rows in root.groupSnapshotRows collect deepCopy rows,epoch=root.procEpoch
        undo off leaf.gridColumnWU=0.0001
        root.refreshAll()
        check (leaf.previewError!="" and root.procEpoch==epoch and equalRows held[1] root.groupSnapshotRows[1] and equalRows held[2] root.groupSnapshotRows[2] and equalRows held[3] root.groupSnapshotRows[3]) "Excessive grid admission retains every previous layer publication" log
        undo off leaf.gridColumnWU=5
        gridUpdate root
        check (equalRows held[1] root.groupSnapshotRows[1]) "Correcting grid spacing recovers the complete previous result" log
        local path=MCPFixtureDir+"grid-core.max",before=for rows in root.groupSnapshotRows collect deepCopy rows
        saveMaxFile path quiet:true;loadMaxFile path quiet:true useFileUnits:true
        root=(getNodeByName "Grid qualification").baseObject;gridUpdate root
        check (root.layerObjects.count==3) "Save/reopen retains grid layer graph" log
        for i=1 to before.count do check (equalRows before[i] root.groupSnapshotRows[i]) "Save/reopen preserves every grid placement field" log
        format "PASS COMPLETE GRID CORE\n" to:log;flush log
    )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;flush log;close log;throw())
    close log
)
