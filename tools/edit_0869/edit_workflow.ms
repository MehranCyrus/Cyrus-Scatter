-- Small owned-host acceptance cases for 0.86.9. Not included in packages.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/quality_validation/common.ms"
global EWRun,EWModels,EWOther,EWEdit,EWTop,EWRemoved,EWOriginal,EWBaseline,EWAbsent,EWBefore,EWPath
global EWInspect,EWVisible,EWState,EWNear,EWSetup,EWSelect,EWFind,EWRows,EWReadScene,EWAuthored,EWMount,EWReady

fn EWReady = (
    local suspended=CyrusPointSuspended
    CyrusPointSuspended=false;QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 400
    CyrusPointSuspended=suspended
)

fn EWMount pages = (
    CyrusPerfHeadless=false;select QNode;max modify mode
    modPanel.setCurrentObject QRoot
    -- QMount reselects the node; Max2024 then selects its top Edit modifier.
    -- Mount the base object's real rollout after the final selection instead.
    local deadline=timeStamp()+20000
    while not QRoot.mainUI.controlsReady and timeStamp()<deadline do QSettle 50
    QRequire QRoot.mainUI.controlsReady "Scatter base UI did not mount"
    for slot in QRoot.mainUI.slots do slot.open=(findItem pages slot.name)>0
    QRoot.mainUI.bindEditors();deadline=timeStamp()+20000
    while QRoot.mainUI.mountQueue.count>0 and timeStamp()<deadline do QSettle 50
    QRequire (QRoot.mainUI.mountQueue.count==0) "Edit fixture pages did not settle"
    QRoot.bindNativeUI();QSettle 200
)

fn EWNear a b epsilon:0.0001 = (
    if classof a==Matrix3 then (for i=1 to 4 where distance a[i] b[i]>epsilon do return false;true)
    else if classof a==Point3 then distance a b<=epsilon
    else if classof a==Array then (
        if classof b!=Array or a.count!=b.count do return false
        for i=1 to a.count where not (EWNear a[i] b[i] epsilon:epsilon) do return false
        true
    ) else a==b
)
fn EWInspect modifier = (
    local page=cyrusEditInspect modifier 0 500
    QRequire (page[1]==2 and page[2]<=500) "Bounded Edit fixture exceeded"
    page[4]
)
fn EWVisible modifier = (
    local rows=for r in EWInspect modifier where r[7] collect r
    fn ordered a b = (if a[1]<b[1] then -1 else if a[1]>b[1] then 1 else if a[10]<b[10] then -1 else if a[10]>b[10] then 1 else 0)
    qsort rows ordered;rows
)
fn EWState modifier = (for r in EWInspect modifier collect #(r[1],r[3],r[4],r[5],r[8],r[9],r[10],r[11]))
fn EWAuthored modifier = (for r in EWInspect modifier where r[9] or r[4]!=r[5] or not (EWNear r[11] (matrix3 1)) collect #(r[1],r[3],r[4],r[5],r[9],r[10],r[11]))
fn EWFind modifier source id = (
    for r in EWInspect modifier where r[3]==source and r[5]==id do return r
    undefined
)
fn EWSelect modifier source owner nth:1 = (
    local rows=EWVisible modifier,found=0
    for i=1 to rows.count where rows[i][1]==owner and rows[i][3]==source and rows[i][4]==rows[i][5] do (
        found+=1
        if found==nth do (cyrusEditSelect modifier #(i);return rows[i])
    )
    throw "Fixture requires another visible instance of this source"
)
fn EWRows leaf = (
    local i=findItem QRoot.layerObjects leaf,data=QRoot.groupSnapshotRows[i]
    QRequire (data.count<=500) "Bounded row witness exceeded"
    if data.count==0 then #() else cyrusPlacementPage data (cyrusPlacementToken data) 0 data.count
)
fn EWReadScene path = (
    loadMaxFile path quiet:true useFileUnits:true
    QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.layerObjects[1]
    QSurface=(QLayer.validSurfaces())[1];EWModels=for n in QLayer.procSourceNodes where isValidNode n collect n
    EWOther=if QRoot.layerObjects.count>1 then QRoot.layerObjects[2] else undefined
    EWEdit=QNode.modifiers[QNode.modifiers.count];QRoot.updateMode=1;CyrusPointSuspended=true;QCalculate();EWReady()
)
fn EWSetup twoLayers:true = (
    QSetup();QLayer.amount=36;QModel.name="EW source one"
    EWModels=#(QModel,box name:"EW source two" width:6 length:9 height:12 pos:[1100,0,0],box name:"EW source three" width:8 length:4 height:15 pos:[1200,0,0])
    -- Asymmetric, rotated and mirrored sources expose object-offset mistakes.
    EWModels[2].objectOffsetPos=[13,-7,3];EWModels[2].rotation=angleAxis 27 [0,0,1];EWModels[2].scale=[-1,2,0.75]
    QLayer.addModelSource EWModels[2];QLayer.addModelSource EWModels[3]
    QLayer.setSourceIDColor #{1} (color 230 40 50);QLayer.setSourceIDColor #{2} (color 30 210 80);QLayer.setSourceIDColor #{3} (color 40 100 240)
    QLayer.layerIDColor=color 200 70 220
    local first=QLayer
    EWOther=undefined
    if twoLayers do (
        QRoot.newLayer();EWOther=QRoot.selectedLayer();QRoot.setLayerSurfaces EWOther #(QSurface)
        EWOther.addModelSource EWModels[3];EWOther.amount=8
        EWOther.procSelfOverride=true;EWOther.procSelfEnabled=false;EWOther.procLayerSelfEnabled=false
        EWOther.layerIDColor=color 230 180 30
    )
    QLayer=first;QRoot.selectLayer 1
    EWEdit=CyrusScatterEdit();addModifier QNode EWEdit
    QCalculate();clearUndoBuffer();true
)

fn EWRun scenario = (
    case scenario of (
        "feedback": (
            EWSetup();local fingerprint=QFingerprint(),epoch=QRoot.procEpoch,builds=QRoot.groupBuilds
            local rows=EWVisible EWEdit,good=rows.count==44
            for r in rows do (
                local leaf=if r[1]==QLayer.editLayerKey then QLayer else EWOther
                local model=findItem leaf.procSourceSlots r[3]
                good=good and model>0 and EWNear r[14] ((leaf.sourceIDColor model) as point3)
                local actual=undefined
                for row in EWRows leaf where row[3]==r[5] do actual=row[1]
                good=good and actual!=undefined and EWNear actual r[13]
            )
            QAssert good "E1_model_and_final_matrix" "Every handle resolves the published model colour and exact final matrix, including offset/mirrored source transforms."
            QLayer.amount=43;QRoot.identificationMode=2;QRoot.refreshIdentification()
            good=true
            for r in EWVisible EWEdit do good=good and EWNear r[14] ((if r[1]==QLayer.editLayerKey then QLayer.layerIDColor else EWOther.layerIDColor) as point3)
            QAssert good "E1_layer_palette" "Layer identification colours reach native Edit presentation."
            QRoot.identificationMode=3;QRoot.refreshIdentification()
            QRoot.identificationMode=1;QRoot.refreshIdentification()
            local picked=EWSelect EWEdit QLayer.procSourceSlots[2] QLayer.editLayerKey
            EWMount #("modelsUISlot","displayUISlot");clearSelection();select QNode;QSettle 200
            QAssert (QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and QLayer.amount==43) "E1_manual_display_only" "Colour mode, selection and reselection preserve pending Count and the complete publication without solving."
            QLayer.amount=36;QCalculate()
            local before=(EWFind EWEdit picked[3] picked[5])[13]
            theHold.Begin();cyrusEditTransform EWEdit 0 [7,11,3] (matrix3 1) false;theHold.Accept "EW move"
            QCalculate();local moved=(EWFind EWEdit picked[3] picked[5])[13]
            QAssert (EWNear moved.translation (before.translation+[7,11,3])) "E1_sdk_move" "The actual modifier Move callback displaces the final published marker by the requested world vector."
            local after=QFingerprint();max undo;QCalculate();local restored=EWNear (EWFind EWEdit picked[3] picked[5])[13] before
            max redo;QCalculate()
            QAssert (restored and QFingerprint()==after) "E1_move_undo_redo" "Undo and Redo recover the same matrices and complete output."
            before=QFingerprint();local authored=EWState EWEdit
            theHold.Begin();cyrusEditTransform EWEdit 0 [8,0,0] (matrix3 1) false;QCalculate();theHold.Cancel();QCalculate()
            QAssert (QFingerprint()==before and EWNear (EWState EWEdit) authored) "E1_cancel" "Cancelling a real Hold gesture preserves transforms and selection."
            QRoot.viewportMode=1;QRoot.refreshIdentification();select QNode;max modify mode
            modPanel.setCurrentObject EWEdit;subObjectLevel=1;max zoomext sel all;redrawViews()
            local shot=gw.getViewportDib();shot.filename=MCPFixtureDir+"edit-feedback.png";save shot;close shot
            QAssert (doesFileExist (MCPFixtureDir+"edit-feedback.png")) "E1_visual_capture" "Native Edit handles captured for visual inspection; scripted SDK calls are not physical mouse input."
        )
        "stack": (
            EWSetup twoLayers:false;local source=QLayer.procSourceSlots[1],picked=EWSelect EWEdit source QLayer.editLayerKey
            undo "EW lower move" on cyrusEditTransform EWEdit 0 [4,3,0] (matrix3 1) false
            QCalculate();EWTop=CyrusScatterEdit();addModifier QNode EWTop;QCalculate()
            EWSelect EWTop source QLayer.editLayerKey
            undo "EW upper rotate" on cyrusEditTransform EWTop 1 (quat 31 [0,0,1]) (matrix3 1) false
            QCalculate();local low=EWFind EWEdit source picked[5],high=EWFind EWTop source picked[5]
            QAssert (EWNear low[13] high[13]) "E1_stack_final" "Lower and upper Edit modifiers show the same final accepted matrix."
            EWSelect EWEdit source QLayer.editLayerKey
            local p=low[13].translation
            undo "EW lower world move" on cyrusEditTransform EWEdit 0 [6,-9,2] (matrix3 1) false
            QCalculate()
            QAssert (EWNear (EWFind EWEdit source picked[5])[13].translation (p+[6,-9,2])) "E1_stack_world_move" "Lower-stack Move is conjugated through the downstream transform."
            local expected=QFingerprint();max undo;QCalculate();max redo;QCalculate()
            QAssert (QFingerprint()==expected) "E1_stack_history" "Stacked Edit Undo and Redo retain exact final output."
        )
        "bands": (
            QSetup();QLayer.amount=30;QLayer.diversityMode=3
            local path=splineShape name:"EW Band path";addNewSpline path
            for p in #([-200,-400,0],[200,-400,0],[200,400,0],[-200,400,0]) do addKnot path 1 #corner #line p
            close path 1;updateShape path
            local band=QLayer.addStroke path side:2
            QLayer.patternWidths[band]=150;QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1]);QLayer.strokeDisplayColors[band]=color 190 45 200
            EWEdit=CyrusScatterEdit();addModifier QNode EWEdit;QRoot.identificationMode=3;QCalculate()
            local rows=EWVisible EWEdit,good=rows.count>0,before=QFingerprint(),epoch=QRoot.procEpoch
            for r in rows do good=good and EWNear r[14] [190,45,200]
            QAssert good "E1_band_palette" "Real Band membership resolves the existing Band identification colour."
            QLayer.strokeDisplayColors[band]=color 40 200 210;QRoot.refreshIdentification();good=true
            for r in EWVisible EWEdit do good=good and EWNear r[14] [40,200,210]
            QAssert (good and QFingerprint()==before and QRoot.procEpoch==epoch) "E1_band_recolor" "Band colour changes refresh handles without recalculating placements."
        )
        "removal": (
            EWSetup();local sources=QLayer.procSourceSlots as array
            -- Both removed and surviving models own a moved base, clone and deletion.
            for source in #(sources[1],sources[2]) do (
                EWSelect EWEdit source QLayer.editLayerKey
                undo "EW authored move" on cyrusEditTransform EWEdit 0 [5,8,0] (matrix3 1) false
                QCalculate();cyrusEditCommand EWEdit 3 undefined;QCalculate()
                undo "EW clone move" on cyrusEditTransform EWEdit 0 [12,0,0] (matrix3 1) false
                QCalculate();EWSelect EWEdit source QLayer.editLayerKey nth:2
                cyrusEditCommand EWEdit 2 undefined;QCalculate()
            )
            EWSelect EWEdit sources[2] QLayer.editLayerKey
            QLayer.procSelectedRadius 1 2.5;QCalculate()
            EWOriginal=EWAuthored EWEdit;EWBaseline=QFingerprint();local other=EWRows EWOther,originalRadius=QLayer.procRadiusBinding
            EWMount #("modelsUISlot");QRoot.modelsUI.sourceUI_plantList.selection=#{2};QRoot.modelsUI.sourceUI_showSelectedColor()
            QClick QRoot.modelsUI.sourceUI_removePlant
            QAssert (QLayer.sources.count==2 and QFingerprint()==EWBaseline) "E2_remove_manual" "The real Remove button changes the source list without consuming pending Manual publication."
            QCalculate();EWAbsent=QFingerprint()
            local good=true,dormant=0
            for old in EWOriginal do (
                local row=EWFind EWEdit old[2] old[4]
                good=good and row!=undefined and EWNear row[11] old[7] and row[9]==old[5]
                if old[2]==sources[2] do (dormant+=1;good=good and not row[6] and not row[7])
            )
            QAssert (good and dormant>=3 and EWNear (EWRows EWOther) other) "E2_dormant_no_transfer" "Removed-source move/delete/clone histories remain inactive; surviving histories and the independent layer are preserved."
            QAssert (QLayer.procRadiusIDs.count==1 and QLayer.procRadiusBinding!="") "E2_radius_history" "The removed model's radius override remains saved with source ownership."
            max undo;QCalculate()
            QAssert (QFingerprint()==EWBaseline and EWNear (EWAuthored EWEdit) EWOriginal and QLayer.sources.count==3) "E2_remove_undo" "Undo source removal recovers exact output and authored history."
            max redo;QCalculate()
            QAssert (QFingerprint()==EWAbsent and QLayer.sources.count==2) "E2_remove_redo" "Redo restores the same source-aware successor."
            EWPath=MCPFixtureDir+"absent-source.max";setUserProp QNode "EWAbsentFingerprint" EWAbsent;saveMaxFile EWPath quiet:true
            QAssert (doesFileExist EWPath) "E2_absent_saved" "Saved a disposable scene with dormant edits and a dormant radius override."
            QLayer.removeModelSources #(1,2);QCalculate()
            QAssert ((EWRows QLayer).count==0 and EWNear (EWAuthored EWEdit) EWOriginal and EWNear (EWRows EWOther) other) "E2_last_source" "Removing the final sources publishes empty output while preserving dormant history and the other layer."
            max undo;QCalculate()
            QAssert (QFingerprint()==EWAbsent) "E2_empty_undo" "Undo last-source removal restores the prior compatible result."
            local liveEpoch=QRoot.procEpoch
            QRoot.updateMode=2;CyrusPointSuspended=false;QLayer.removeModelSources #(2)
            local deadline=timeStamp()+10000
            while QRoot.procEpoch==liveEpoch and timeStamp()<deadline do QSettle 50
            QAssert (QRoot.procEpoch>liveEpoch and QLayer.previewError=="") "E2_live_remove" "Live mode publishes the source removal through its normal scheduled update."
            CyrusPointSuspended=true;QRoot.updateMode=1
        )
        "saved": (
            QRequire (EWPath!=undefined and doesFileExist EWPath) "Run removal first"
            EWReadScene EWPath
            QAssert (QFingerprint()==EWAbsent and EWNear (EWAuthored EWEdit) EWOriginal) "E3_dormant_reopen" "New-format save/reopen retains inactive move/delete/clone lineage and output."
            local original=getNodeByName "EW source two",originalID=undefined
            for row in EWOriginal where row[2]!=QLayer.procSourceSlots[1] and row[2]!=QLayer.procSourceSlots[2] do originalID=row[2]
            local impostor=copy original;impostor.name=original.name
            QLayer.addModelSource impostor;QCalculate()
            local safe=true
            for row in EWInspect EWEdit where row[3]==originalID do safe=safe and not row[6]
            QAssert safe "E3_same_name_isolation" "A different scene node with the same name does not acquire the removed model's edits."
            QLayer.removeModelSources #(3);QCalculate();QLayer.addModelSource original tint:(color 240 190 70)
            -- Restore the original authored order and settings for an exact recovery.
            for key in #(#sources,#sourceRowIDs,#sourceColors,#sourceWeights,#sourceScales,#sourceZOffsetsWU,#sourceForwardAxes,#sourceRadiiWU,#sourceAutoRadius,#sourceFollowScale,#sourceShowRadius,#sourcePoint,#sourceEmpty) do (
                local values=(getProperty QLayer key) as array
                if values.count==3 do setProperty QLayer key #(values[1],values[3],values[2])
            )
            QCalculate()
            local recovered=0
            for old in EWOriginal where old[2]==originalID do (
                local row=EWFind EWEdit old[2] old[4]
                if row!=undefined and row[6] and EWNear row[11] old[7] and row[9]==old[5] do recovered+=1
            )
            QAssert (recovered>=3 and QLayer.procRadiusIDs.count==1) "E3_source_readd" "Re-enrolling the original registered source recovers its compatible histories after save/reopen."
            local saved=EWAuthored EWEdit,path=MCPFixtureDir+"recovered-source.max"
            saveMaxFile path quiet:true;EWReadScene path
            QAssert (EWNear (EWAuthored EWEdit) saved) "E3_recovered_roundtrip" "Recovered source-aware histories survive another save/reopen."
            -- Evaluate the copy: new clone IDs alone cannot prove edit preservation.
            local copyNode=copy QNode,copyMod=copyNode.modifiers[copyNode.modifiers.count],unique=true
            local originalClones=for r in EWInspect EWEdit where r[4]!=r[5] collect r[5]
            for r in EWInspect copyMod where r[4]!=r[5] do unique=unique and findItem originalClones r[5]==0
            local copiedRoot=copyNode.baseObject,oldVisible=EWVisible EWEdit
            copiedRoot.updateMode=1;copiedRoot.evaluateProcedural()
            for leaf in copiedRoot.layerObjects do QRequire (leaf.previewError=="") leaf.previewError
            local suspended=CyrusPointSuspended;CyrusPointSuspended=false;copiedRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 400;CyrusPointSuspended=suspended
            local copiedVisible=EWVisible copyMod,matching=copiedVisible.count==oldVisible.count
            if matching do for i=1 to oldVisible.count do matching=matching and EWNear copiedVisible[i][13] oldVisible[i][13]
            local report=createFile (MCPFixtureDir+"copy-comparison.txt")
            with printAllElements on format "Original visible: %\nCopied visible: %\nOriginal saved: %\nCopied saved: %\nOriginal owners: %\nCopied owners: %\nUnique: % Matching: %\n" oldVisible copiedVisible (EWInspect EWEdit) (EWInspect copyMod) (for leaf in QRoot.layerObjects collect #(leaf.layerID,leaf.editLayerKey,leaf.procSourceSlots)) (for leaf in copiedRoot.layerObjects collect #(leaf.layerID,leaf.editLayerKey,leaf.procSourceSlots)) unique matching to:report
            close report
            QAssert (unique and matching) "E3_copy_clone_ids" "An evaluated controller copy retains final edited matrices and independent cloned-instance identities."
        )
        "point_identity": (
            QSetup();QLayer.amount=30;QLayer.addPointSource()
            EWEdit=CyrusScatterEdit();addModifier QNode EWEdit;QCalculate();EWReady()
            local pointID=QLayer.procSourceSlots[2],picked=EWSelect EWEdit pointID QLayer.editLayerKey
            undo "EW Point move" on cyrusEditTransform EWEdit 0 [9,2,0] (matrix3 1) false
            QCalculate();EWReady();QLayer.procSelectedRadius 1 1.5;QCalculate();EWReady()
            local authored=EWAuthored EWEdit,before=QFingerprint()
            QLayer.removeModelSources #(1);QCalculate();EWReady()
            local matched=EWFind EWEdit pointID picked[5]
            QAssert (QLayer.procSourceSlots[1]==pointID and matched!=undefined and matched[6] and EWNear matched[11].translation [9,2,0]) "E2_point_compaction" "Removing an earlier model preserves the surviving Point's persistent role and moved instance."
            local after=QFingerprint();max undo;QCalculate();EWReady();local recovered=QFingerprint()==before
            max redo;QCalculate();EWReady()
            QAssert (recovered and QFingerprint()==after and EWNear (EWAuthored EWEdit) authored) "E2_point_undo" "Point lineage and its radius override recover through source-removal Undo/Redo."
            QLayer.removeModelSources #(1);QCalculate();QLayer.addPointSource();QCalculate();EWReady()
            matched=EWFind EWEdit pointID picked[5]
            QAssert (QLayer.procSourceSlots[1]!=pointID and matched!=undefined and not matched[6] and QLayer.procRadiusIDs.count==1) "E2_point_new_role" "A newly added Point at the old list position cannot inherit a removed Point's edit or radius history."
        )
        "disabled_radius": (
            EWSetup();EWReady();EWSelect EWEdit QLayer.procSourceSlots[1] QLayer.editLayerKey
            QLayer.procSelectedRadius 1 2.0;QCalculate();EWReady()
            local before=QFingerprint(),binding=QLayer.procRadiusBinding,ids=QLayer.procRadiusIDs as array,path=MCPFixtureDir+"disabled-radius.max"
            QRoot.layerEnabled[1]=false;QCalculate();saveMaxFile path quiet:true;EWReadScene path
            QAssert ((EWRows QLayer).count==0 and (EWRows EWOther).count==8 and QLayer.procRadiusBinding==binding and EWNear (QLayer.procRadiusIDs as array) ids) "E3_disabled_radius_reopen" "A reopened disabled population retains its saved radius history without blocking the active layer."
            undo "EW enable radius layer" on QRoot.layerEnabled[1]=true;QCalculate();EWReady()
            QAssert (QFingerprint()==before) "E3_disabled_radius_recover" "Enabling the original population recovers its exact accepted output and radius values."
            max undo;QCalculate();max redo;QCalculate();EWReady()
            QAssert (QFingerprint()==before) "E3_disabled_radius_undo" "Enabled-state Undo/Redo retains the same saved override ownership."
        )
        "guards": (
            EWSetup();local source=QLayer.procSourceSlots[1],picked=EWSelect EWEdit source QLayer.editLayerKey
            undo "EW guard move" on cyrusEditTransform EWEdit 0 [5,0,0] (matrix3 1) false
            QCalculate();local before=QFingerprint(),state=EWState EWEdit,epoch=QRoot.procEpoch,failed=false,seed=QLayer.randomSeed
            QLayer.randomSeed+=1;try(QCalculate())catch(failed=true)
            QAssert (failed and QFingerprint()==before and EWNear (EWState EWEdit) state and QRoot.procEpoch==epoch) "E4_seed_guard" "Incompatible seed changes retain the complete publication and authored state."
            QLayer.randomSeed=seed;QCalculate();local width=QSurface.width
            CyrusPointSuspended=false;QSurface.width+=10;QSettle 300;failed=false;try(QCalculate())catch(failed=true)
            local report=createFile (MCPFixtureDir+"receiver-guard.txt")
            format "Failed: %\nPublication same: %\nState same: %\nError: %\nBefore: %\nAfter: %\n" failed (QFingerprint()==before) (EWNear (EWState EWEdit) state) QLayer.previewError state (EWState EWEdit) to:report;close report
            QAssert (failed and QFingerprint()==before and EWNear (EWState EWEdit) state) "E4_receiver_guard" "Changed receiver geometry does not silently rebind edits."
            QSurface.width=width;QSettle 300;QCalculate();CyrusPointSuspended=true
            before=QFingerprint();state=EWState EWEdit;epoch=QRoot.procEpoch
            local binding=QLayer.procBindingKey,prepared=QLayer.procPreparedRows,colorBefore=QLayer.layerIDColor
            QLayer.amount+=1;QLayer.layerIDColor=color 3000 10 10;QRoot.identificationMode=2
            failed=false;try(QCalculate())catch(failed=true)
            report=createFile (MCPFixtureDir+"publication-rollback.txt")
            format "Failed: %\nRows same: %\nState same: %\nEpoch same: %\nBinding same: %\nPrepared same: %\nError: %\n" failed (QFingerprint()==before) (EWNear (EWState EWEdit) state) (QRoot.procEpoch==epoch) (QLayer.procBindingKey==binding) (QLayer.procPreparedRows==prepared) QLayer.previewError to:report;close report
            QAssert (failed and QFingerprint()==before and EWNear (EWState EWEdit) state and QRoot.procEpoch==epoch and QLayer.procBindingKey==binding and QLayer.procPreparedRows==prepared) "E4_successor_rollback" "A late invalid-palette failure rolls back Edit reconciliation, prepared view, selection and complete publication."
            QLayer.layerIDColor=colorBefore;QCalculate()
            QAssert (QRoot.procEpoch==epoch+1 and QLayer.previewError=="") "E4_retry" "A corrected successor succeeds after the failed transaction."
            local palette=QLayer.procPreviewPalette QRoot.procPublishedMetadata[1],old=EWInspect EWEdit,mods=QRoot.procModifiers()
            failed=false;cyrusEditTransaction mods 0
            try (
                cyrusEditRecolor mods QLayer.editLayerKey #(1,2,for c in palette[3] collect (color 15 25 35),palette[4],palette[5])
                cyrusEditRecolor mods EWOther.editLayerKey #(1,2,#([999,0,0]),#(),false)
            )catch(failed=true)
            cyrusEditTransaction mods 2
            QAssert (failed and EWNear (EWInspect EWEdit) old) "E4_palette_rollback" "A failure during multi-layer presentation refresh retains every previously published palette and matrix."
            EWReady()
            EWSelect EWEdit source QLayer.editLayerKey
            QLayer.procSelectedRadius 1 3;QCalculate()
            QAssert (QLayer.procRadiusIDs.count==1) "E4_author_after_failure" "Radius authoring remains possible after failure recovery using the matching prepared receipt."
        )
        default: throw ("Unknown Edit acceptance case: "+scenario)
    )
    true
)
