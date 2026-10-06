-- DEFINITIONS ONLY. Not executed during the offline implementation campaign.
-- Call explicitly in an EMPTY DISPOSABLE Max host with a pinned matching build.
-- Never loads/saves/resets a scene, launches a renderer or installs a plugin.
global CyrusOfflineImplementationFixture,CyrusOfflineFixtureNode
fn CyrusOfflineImplementationFixture expectedPayloadSHA = (
    if objects.count!=0 do throw "Use an empty disposable scene; this fixture will create test objects."
    if CyrusLoadedScriptFingerprint!=expectedPayloadSHA do throw "Loaded script fingerprint mismatch."
    if cyrusProceduralPublicationVersion==undefined or cyrusProceduralPublicationVersion()!=1 do throw "Matching publication native API required."
    fn check condition message = (if not condition do throw ("Offline handoff fixture: "+message);true)
    local surface=plane length:1000 width:1000 lengthsegs:1 widthsegs:1 name:"CS_Offline_Surface"
    local source=box length:8 width:8 height:20 pos:[1200,0,0] name:"CS_Offline_Source"
    local node=AminScatterObject name:"CS_Offline_Controller",root=node.baseObject
    CyrusOfflineFixtureNode=node
    root.setLayerTransfer true
    root.updateMode=1;root.surfaceNodes=#(surface);root.newLayer()
    local leaf=root.selectedLayer()
    leaf.amount=100;leaf.sources=#(source);leaf.sourceWeights=#(1.0);leaf.paintEnabled=false
    leaf.randomSeed=42;leaf.collisionEnabled=false;leaf.sourceRadii=#(3.0);leaf.sourceFollowScale=#(false)
    root.setLayerTransfer false;root.procUpgrade()
    cyrusDiagnosticStart "offline_handoff_fixture" 4096 4194304 600000
    try (
        local rows=root.evaluateGroups(),info=root.procPublicationInfo(),before=root.procEpoch,builds=leaf.procPreparedBuilds
        check (info[5]==100) "Publication count"
        local seen=#()
        for offset=0 to 75 by 25 do (
            local page=root.procPublicationPage info[1] offset 25
            check (page[2]==100 and page[3]==offset+25 and page[4].count==25) "Page extent"
            for i=1 to page[4].count do (
                local row=page[4][i],original=rows[1][offset+i]
                check (row[1]==1 and row[3]==original[2] and row[6]==3.0) "Owner/source/actual radius"
                for axis=1 to 4 do check (distance row[2][axis] original[1][axis]<1e-5) "Actual transform"
                check (findItem seen row[4]==0) "Duplicate instance identity"
                append seen row[4]
            )
        )
        check (root.procEpoch==before and leaf.procPreparedBuilds==builds) "Reading caused evaluation"
        -- Manual pending settings must not rewrite the published radii.
        leaf.sourceRadii=#(9.0)
        local old=root.procPublicationPage info[1] 0 1
        check (old[4][1][6]==3.0 and (root.procPublicationInfo())[1]==info[1]) "Pending radius leaked into publication"
        root.evaluateGroups()
        local stale=false
        try(root.procPublicationPage info[1] 0 1)catch(stale=true)
        check stale "Old publication handle remained valid"
        info=root.procPublicationInfo()
        check ((root.procPublicationPage info[1] 0 1)[4][1][6]==9.0) "New published radius"
        leaf.sourceRadii=#(-1.0)
        local failed=false
        try(root.evaluateGroups())catch(failed=true)
        check (failed and (root.procPublicationInfo())[1]==info[1]) "Failed successor replaced publication"
        leaf.sourceRadii=#(9.0)
        -- Direct callback classification tests. Actual NodeEvent delivery,
        -- renderer idle soak and lifecycle are separate acceptance stages.
        local poolRect=rectangle width:200 length:200 pos:[1200,0,0] name:"CS_Offline_Container"
        leaf.containerMode=4;leaf.containerNodes=#(poolRect);root.evaluateGroups()
        local helper=dummy name:"CS_Offline_UnrelatedHelper",outside=box pos:[2000,0,0] name:"CS_Offline_Outside"
        leaf.dirty=false
        check (not (root.containerNote #added #(helper,outside))) "Unrelated notification dirtied container population"
        check (not leaf.dirty) "Unrelated dirty flag"
        local entryID=leaf.procSourceSlots[1]
        source.pos=[1500,0,0]
        check (root.containerNote #controllerOtherEvent #(source)) "Source movement was ignored"
        root.evaluateGroups()
        check ((root.procPublicationInfo())[5]==0 and leaf.sources.count==1) "Parking removed source registration"
        source.pos=[1200,0,0];root.containerNote #controllerOtherEvent #(source);root.evaluateGroups()
        check ((root.procPublicationInfo())[5]==100 and leaf.procSourceSlots[1]==entryID and leaf.sourceRadii[1]==9.0) "Reentry lost identity/settings"
        cyrusDiagnosticStop()
        format "PASS: cached publication paging, Manual radius, stale handle, failed successor and direct container notification classification.\n"
        #(node,root.procPublicationInfo(),cyrusDiagnosticSnapshot 0 500)
    ) catch (
        cyrusDiagnosticStop()
        throw()
    )
)
