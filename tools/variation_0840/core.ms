-- Full-row and native Undo witnesses in an owned, disposable Max 2027 profile.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned variation host required."
    if (maxVersion())[1]!=29000 or cyrusRecipeVersion()!=3 do throw "Matched Max 2027 variation pair required."
    local log=createFile (MCPFixtureDir+"variation-core-"+(timeStamp() as string)+".txt")
    fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    fn equalRows a b = (
        if a.count!=b.count do return false
        for i=1 to a.count do (
            if a[i].count!=8 or b[i].count!=8 do return false
            for j=1 to 8 where a[i][j]!=b[i][j] do return false
        );true
    )
    fn differentIDs a b = (
        if a.count!=b.count do return false
        for i=1 to a.count where a[i]==b[i] do return false
        true
    )
    fn stringsEqual a b = (if a.count!=b.count then false else (for i=1 to a.count where a[i]!=b[i] collect i).count==0)
    fn counters root leaf = #((leaf.receiverCacheStats())[1],leaf.procPreparedBuilds,leaf.procDensityBakes,root.procEpoch,(cyrusOrientationStats())[1])
    try (
        if theHold.Holding() do (format "FIXTURE: cancel previous owned preparation hold\n" to:log;theHold.Cancel())
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node,root,leaf,a,b,source1,source2,area
        undo off (
            units.SystemType=#meters;units.SystemScale=1
            a=plane name:"Variation terrain A" width:100 length:100 widthsegs:4 lengthsegs:4
            b=plane name:"Variation terrain B" width:100 length:100 widthsegs:4 lengthsegs:4 pos:[130,0,0]
            rotate b (eulerAngles 25 0 0)
            source1=pyramid name:"Variation pyramid" width:1 depth:2 height:4 pos:[-100,0,0]
            source2=box name:"Variation box" width:2 length:3 height:2 pos:[-100,10,0]
            node=AminScatterObject name:"Variation qualification";root=node.baseObject
            root.updateMode=1;root.autoRender=false;root.newLayer();leaf=root.selectedLayer()
            root.setLayerSurfaces leaf #(a,b);leaf.sources=#(source1,source2);leaf.ensureSourceRows()
            leaf.amount=1200;leaf.procPopulation=1;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
            leaf.sourceWeights=#(0.4,0.6);leaf.wholeScaleMin=0.6;leaf.wholeScaleMax=1.8
            leaf.orientationBlend=50;leaf.slopeEnabled=true;leaf.slopeMinimum=0;leaf.slopeMaximum=35;leaf.slopeUpperFade=20
            area=root.addPaintArea leaf target:a;area.paintView=0;area.paintDensity=0.65;area.paintSetName="Complete copied Paint"
            area.paintSetVisible=false;area.fallDensity=true;area.fallScale=false;area.fallScaleWidth=2.5;area.fallDensityWidth=1.5
            cyrusBrushFill area.paintDocument 1.0
            root.refreshAll()
        )
        check (root.groupSnapshotRows[1].count>0 and root.groupSnapshotRows[1].count<1200) "Masked baseline publishes a nonempty subset" log
        local baseline=deepCopy root.groupSnapshotRows[1],before=counters root leaf
        local document=CyrusRecipeCapture root #(leaf) "Variation recipe"
        check (CyrusRecipeGet document "formatVersion"==3) "Recipe uses complete format 3" log
        check (stringsEqual before (counters root leaf)) "Recipe capture performs no placement, normal extraction or preview preparation" log
        local settings=CyrusRecipeGet (CyrusRecipeGet document "layers")[1] "settings"
        check (stringsEqual (CyrusRecipeGet settings "procReceiverVariationIDs") (CyrusReceiverVariationDomains leaf)) "Recipe stores effective receiver variation domains" log
        local oldPaint=(cyrusBrushRecipeExport area.paintDocument)[1]
        local copied=root.copyLogicalLayer leaf variation:#same
        check (root.layerObjects.count==2 and copied.layerID!=leaf.layerID and copied.editLayerKey!=leaf.editLayerKey) "Named copy has fresh owner and Edit identity" log
        check (differentIDs (leaf.procReceiverIDs as array) (copied.procReceiverIDs as array)) "Named copy remaps receiver correspondence" log
        check (differentIDs (leaf.sourceRowIDs as array) (copied.sourceRowIDs as array)) "Named copy remaps source rows" log
        check (differentIDs (leaf.procSourceIDs as array) (copied.procSourceIDs as array)) "Named copy remaps native source correspondence" log
        check (stringsEqual (CyrusReceiverVariationDomains leaf) (CyrusReceiverVariationDomains copied)) "Same variation retains original domains" log
        check (equalRows baseline root.groupSnapshotRows[1] and root.groupSnapshotRows.count==1) "Manual copy does not publish pending changes" log
        local copyIDs=copied.procReceiverIDs as array,copyDomains=CyrusReceiverVariationDomains copied
        root.refreshAll()
        check (equalRows baseline root.groupSnapshotRows[1] and equalRows baseline root.groupSnapshotRows[2]) "Same copy preserves all eight fields of every row and original output" log
        check (copied.paintAreas.count==1 and copied.paintAreas[1]!=area and copied.paintAreas[1].paintDocument!=area.paintDocument) "Copied Paint has independent objects and native data" log
        check ((cyrusBrushRecipeExport copied.paintAreas[1].paintDocument)[1]==oldPaint and copied.paintAreas[1].fallDensityWidth==1.5 and copied.paintAreas[1].fallScaleWidth==2.5 and not copied.paintAreas[1].paintSetVisible) "Copy preserves Paint bytes and formerly omitted Area settings" log
        max undo
        check (root.layerObjects.count==1) "One Undo removes the named copy and its Areas" log
        max redo
        copied=root.layerObjects[2]
        check (stringsEqual copyIDs (copied.procReceiverIDs as array) and stringsEqual copyDomains (CyrusReceiverVariationDomains copied)) "Redo restores identities and variation without rerolling" log
        root.refreshAll();check (equalRows baseline root.groupSnapshotRows[2]) "Redo restores the complete copied arrangement" log
        local fresh=root.copyLogicalLayer leaf variation:#new
        root.refreshAll()
        check (differentIDs (CyrusReceiverVariationDomains leaf) (CyrusReceiverVariationDomains fresh)) "New copy selects fresh variation domains" log
        check (not equalRows baseline root.groupSnapshotRows[3] and equalRows baseline root.groupSnapshotRows[1]) "New copy changes the arrangement while preserving original rows" log
        local freshRows=deepCopy root.groupSnapshotRows[3],freshDomains=CyrusReceiverVariationDomains fresh
        max undo;check (root.layerObjects.count==2) "One Undo removes New variation copy" log
        max redo;fresh=root.layerObjects[3];root.refreshAll()
        check (stringsEqual freshDomains (CyrusReceiverVariationDomains fresh) and equalRows freshRows root.groupSnapshotRows[3]) "Redo never rerolls New variation" log

        local bindings=CyrusRecipeSuggestBindings root document,result=CyrusRecipeImport root document bindings variation:#same
        root.refreshAll()
        check (root.layerObjects.count==4 and equalRows baseline root.groupSnapshotRows[4]) "Saved variation Add reproduces complete rows" log
        check (differentIDs (leaf.procReceiverIDs as array) (result[2][1].procReceiverIDs as array)) "Saved variation import still remaps receiver ownership" log
        result=CyrusRecipeImport root document bindings newSetup:true variation:#same
        result[1].refreshAll()
        check (equalRows baseline result[1].groupSnapshotRows[1]) "Saved variation New setup reproduces complete rows" log
        check ((cyrusBrushRecipeExport result[2][1].paintAreas[1].paintDocument)[1]==oldPaint) "Recipe import preserves complete Paint" log
        local newNode=result[3],savedRows=deepCopy result[1].groupSnapshotRows[1],savedDomains=CyrusReceiverVariationDomains result[2][1]
        max undo;check (not isValidNode newNode) "One Undo removes New setup" log
        max redo;newNode=getNodeByName "Variation recipe"
        check (isValidNode newNode) "One Redo restores New setup" log
        newNode.baseObject.refreshAll()
        check (stringsEqual savedDomains (CyrusReceiverVariationDomains newNode.baseObject.layerObjects[1]) and equalRows savedRows newNode.baseObject.groupSnapshotRows[1]) "Recipe Redo restores domains and every row" log
        result=CyrusRecipeImport root document bindings variation:#new;root.refreshAll()
        check (not equalRows baseline root.groupSnapshotRows[5] and equalRows baseline root.groupSnapshotRows[1]) "New variation import changes new layer only" log

        local target=CyrusPresetMakeBinding root leaf "population",preset=#("population","Seed policy",CyrusPresetCapture (CyrusPresetMakeBinding root leaf "population")),savedSeed=leaf.randomSeed
        leaf.randomSeed=731
        CyrusPresetApply target preset seedPolicy:#current;check (leaf.randomSeed==731) "Keep current seed ignores saved numeric seed" log
        CyrusPresetApply target preset seedPolicy:#saved;check (leaf.randomSeed==savedSeed) "Saved seed applies numeric seed" log
        CyrusPresetApply target preset seedPolicy:#new;local newSeed=leaf.randomSeed
        check (newSeed!=savedSeed) "New seed creates a different bounded value" log
        max undo;check (leaf.randomSeed==savedSeed) "One Undo restores prior seed" log
        max redo;check (leaf.randomSeed==newSeed) "Seed Redo restores the chosen value without rerolling" log
        leaf.randomSeed=savedSeed;root.refreshAll()

        local previous=deepCopy root.groupSnapshotRows[1],epoch=root.procEpoch,domains=leaf.procReceiverVariationIDs as array
        leaf.procReceiverVariationIDs=#("incomplete")
        local failed=false;try(root.refreshAll())catch(failed=true)
        check ((failed or (leaf.cacheSnapshot())[3]!="OK") and root.procEpoch==epoch and equalRows previous root.groupSnapshotRows[1]) "Malformed variation history retains previous complete publication" log
        leaf.procReceiverVariationIDs=domains;root.refreshAll()
        check (equalRows previous root.groupSnapshotRows[1]) "Valid history recovers exact rows" log
        local path=MCPFixtureDir+"variation-core.max"
        check (saveMaxFile path quiet:true) "Variation scene saves" log
        check (loadMaxFile path quiet:true useFileUnits:true) "Variation scene reopens" log
        root=(getNodeByName "Variation qualification").baseObject;root.refreshAll()
        check (equalRows baseline root.groupSnapshotRows[1] and equalRows freshRows root.groupSnapshotRows[3]) "Save/reopen preserves original and new variation rows" log
        check (not theHold.Holding()) "No stranded transaction" log
        CyrusPerfHeadless=false;CyrusPointSync();completeRedraw()
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
