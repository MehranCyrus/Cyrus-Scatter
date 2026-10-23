-- Definition-only older-host supplement. Root owns the small Edit EWRun cases.
-- The Python harness supplies Q protocol, EWHostYear and exact staged identities.
fileIn ((getFilenamePath(getSourceFileName()))+"../quality_validation/common.ms")
global ECSRun,ECSLibrary,ECSGallery,ECSResolveMaps,ECSMemoryDraw

fn ECSLibrary = (
    local lines=(dotNetClass "System.IO.File").ReadAllLines (MCPFixtureDir+"library-state.txt")
    QRequire (lines.count==8 and lines[1]=="CyrusLibrary1") "Owned library registration is missing"
    QRequire ((lines[6] as integer)<=EWHostYear) "Existing library is newer than this host"
    lines[2]
)
fn ECSGallery = (
    local deadline=timeStamp()+10000
    while timeStamp()<deadline do (
        if CyrusRecipeBrowser!=undefined and CyrusRecipeBrowser.hwnd!=0 do (
            if matchPattern CyrusRecipeBrowser.panel.StatusText pattern:"Ready:*" do return CyrusRecipeBrowser
        )
        QSettle 50
    )
    throw "Owned Gallery did not finish loading its existing catalog"
)
fn ECSResolveMaps sources catalog = (
    for source in sources do (
        QRequire (source.material!=undefined) "Measured Maple has no material"
        local original=source.material,detached=copy original
        local maps=getClassInstances Bitmaptexture target:detached
        if (try(CoronaBitmap!=undefined)catch(false)) do join maps (getClassInstances CoronaBitmap target:detached)
        QRequire (maps.count>0 and maps.count<=4096) "Unexpected measured texture population"
        for map in maps do (
            local resolved=catalog.MapPath map.filename
            QRequire (doesFileExist resolved) "Existing Maple image is unavailable"
            map.filename=resolved
        )
        source.material=detached
    )
)
fn ECSMemoryDraw = (
    CyrusPointSuspended=false;QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 1200
    local owner=CyrusPointOwner QNode
    QRequire (isValidNode owner) "No retained display owner"
    #(owner,cyrusRetainedStats owner,cyrusRetainedViewportStats owner,cyrusViewportMemoryStats())
)
fn ECSRun phase = (
    QRequire (matchPattern MCPFixtureDir pattern:"*/build/*") "Owned profile required"
    QRequire (findItem #(2024,2026,2027) EWHostYear>0 and (maxVersion())[1]==(EWHostYear-1998)*1000) "Host year differs from the bound payload"
    case phase of (
        "EC-A": (
            QSetup analyzer:true
            QLayer.areaAnalyzer=QGuide;QLayer.areaUseLine=true;QLayer.areaLineWidth=80;QCalculate()
            local runs=QAnalyzer.getAnalysisRuns()
            QAnalyzer.fitRadius=30
            QAssert (not QAnalyzer.analysisCurrent()) "EC-A-01" "A relevant Analyzer change becomes pending before explicit Analyze"
            QAnalyzer.runAnalysis();QCalculate()
            QAssert (QAnalyzer.getAnalysisRuns()==runs+1 and QAnalyzer.analysisCurrent() and QRoot.groupSnapshotRows[1].count>0) "EC-A-02" "The matched Analyzer completes a fresh result consumed by Manual Scatter Update"
            local fingerprint=QFingerprint(),epoch=QRoot.procEpoch,builds=QRoot.groupBuilds,rows=QRows() as string
            QLayer.amount=401
            local problem=undefined
            try (
                QMount pages:#("managerUISlot")
                QClick QRoot.layersUI.flow_layersUI_recipesButton
                local window=ECSGallery(),panel=window.panel,assembly=(panel.GetType()).Assembly
                local expected=pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll"
                QAssert (QRoot.uiVersion()=="0.86.9" and (assembly.GetName()).Version.ToString()=="0.86.9.0" and toLower assembly.Location==toLower expected and panel.IndividualModels and panel.Gallery.ItemCount==96) "EC-A-03" "Actual Recipes opens 96 existing models with the matching host-specific 0.86.9.0 Gallery"
                destroyDialog window;QSettle 100
                QAssert (CyrusRecipeBrowser==undefined and QRoot.updateMode==1 and QLayer.amount==401 and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and (QRows() as string)==rows) "EC-A-04" "Opening and closing the existing library preserves exact publication and pending Manual Count"
            )catch(problem=getCurrentException())
            if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
            if problem!=undefined do throw problem
        )
        "EC-M": (
            resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1
            CyrusPerfHeadless=true;CyrusPointSuspended=true;cyrusSetViewportMemoryLimit 0
            local library=ECSLibrary(),assembly=dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")
            QRequire ((assembly.GetName()).Version.ToString()=="0.86.9.0") "Measured source lookup uses the wrong managed pair"
            local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
            catalog.Load library "0.86.9" EWHostYear
            local models=#(),specs=#(#("A097","Models/Trees/A097 - Maple - Green Foliage/model.max","CyrusModel_A097",1640630),#("A098","Models/Trees/A098 - Norway Maple - Red Foliage/model.max","CyrusModel_A098",215272))
            for spec in specs do (
                catalog.VerifyScene (catalog.MatchingAt spec[1] "" 0)
                local path=pathConfig.appendPath library spec[2]
                QRequire (mergeMAXFile path #(spec[3]) #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg) "Version-compatible measured model did not merge"
                local model=getNodeByName spec[3] exact:true
                QRequire (isValidNode model and model.numfaces==spec[4]) "Measured model geometry differs"
                append models model;hide model
            )
            ECSResolveMaps models catalog
            QSurface=plane name:"Compatibility tree receiver" width:3000 length:3000 widthsegs:4 lengthsegs:4
            QNode=AminScatterObject name:"Compatibility Tree Scatter";QRoot=QNode.baseObject;QRoot.updateMode=1;QRoot.autoRender=false
            QRoot.newLayer();QLayer=QRoot.selectedLayer();QRoot.setLayerSurfaces QLayer #(QSurface)
            for model in models do QLayer.addModelSource model
            QLayer.amount=2;QLayer.randomSeed=446;QLayer.procSelfOverride=true;QLayer.procSelfEnabled=false;QLayer.procLayerSelfEnabled=false
            QLayer.sourceWeights=#(1.0,0.0)
            QLayer.sourceScales=#(0.02,0.02);QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000
            QCalculate();QRoot.identificationMode=4;QRoot.setGroupDisplay 3
            local state=ECSMemoryDraw(),owner=state[1],old=state[2],plan=state[3],fingerprint=QFingerprint(),epoch=QRoot.procEpoch
            local cache=QLayer.cachedPoints,log=createFile (MCPFixtureDir+"compatibility-memory.txt")
            format "Host:%\nFingerprint:%\nRows:%\nMemory:%\nRetained:%\nPlan:%\n" EWHostYear fingerprint (QRows() as string) state[4] old plan to:log;flush log
            QAssert (QLayer.previewError=="" and old[12]==1 and plan[6]>3000000 and plan[8]==0 and plan[10]==0) "EC-M-01" "The carried-forward real Maple witness uploads and draws as complete Mesh beyond three million placement triangles"
            local row=(QRows())[1],center=row[1].row4
            local camera=targetCamera name:"Compatibility tree camera" pos:(center+[30,-45,24]) target:(targetObject pos:(center+[0,0,8]))
            viewport.setCamera camera;completeRedraw();QSettle 400
            local bitmap=gw.getViewportDib();bitmap.filename=MCPFixtureDir+"compatibility-maple.png";save bitmap;close bitmap
            select QNode;clearSelection();select QNode;QSettle 300
            local reused=cyrusRetainedStats owner
            QAssert (QFingerprint()==fingerprint and QRoot.procEpoch==epoch and reused[4]==old[4] and reused[6]==old[6] and reused[7]==old[7]) "EC-M-02" "Selection reuses complete high-poly publication, preparation and uploads"
            QRequire (state[4][4]>268435456L) "Measured resources do not exceed the selected low display allowance"
            QLayer.amount=3
            cyrusSetViewportMemoryLimit 256
            local lowered=cyrusRetainedStats owner
            QAssert (lowered[3]==old[3] and lowered[6]==old[6] and QRoot.procEpoch==epoch) "EC-M-03" "Lowering display allowance retains existing resources without eviction"
            QLayer.sources[1].material=standardMaterial diffuse:(color 90 180 60)
            QRoot.refreshDisplay();CyrusViewportRedraw();QSettle 500
            local failed=cyrusRetainedStats owner,failedPlan=cyrusRetainedViewportStats owner
            format "Failed memory:%\nFailed retained:%\nFailed plan:%\nStatus:% / %\n" (cyrusViewportMemoryStats()) failed failedPlan QLayer.previewError CyrusPointLastError to:log;flush log
            QAssert (failed[3]==old[3] and failed[12]==1 and failed[13]==old[13] and QLayer.cachedPoints==cache and failedPlan[6]==plan[6] and failedPlan[8]==0 and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QLayer.amount==3) "EC-M-04" "Refused appearance successor retains complete display and publication while Count stays pending"
            QAssert (QLayer.previewError!="" or CyrusPointLastError!="") "EC-M-05" "Budget refusal is visible in the current display or layer status"
            cyrusSetViewportMemoryLimit 0
            local recovered=ECSMemoryDraw()
            format "Recovered memory:%\nRecovered retained:%\nRecovered plan:%\n" recovered[4] recovered[2] recovered[3] to:log;close log
            QAssert (QLayer.previewError=="" and recovered[2][12]==1 and recovered[3][8]==0 and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QLayer.amount==3) "EC-M-06" "Restoring allowance recovers Mesh without publishing the pending Manual Count"
        )
        default: throw "Unknown compatibility smoke case"
    )
    true
)
