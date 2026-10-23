-- Written by the preserved 0.86.8.7 package, then read by 0.86.9.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/edit_0869/edit_workflow.ms"
global EWLegacyRun,EWLegacyPath
fn EWLegacyRun scenario = (
    case scenario of (
        "produce": (
            QSetup();QLayer.amount=30
            local second=box name:"Legacy second source" width:4 length:8 height:12 pos:[1200,0,0]
            QLayer.addModelSource second
            local edit=CyrusScatterEdit();addModifier QNode edit;QCalculate()
            cyrusEditSelect edit #(1,3)
            undo "Legacy real move" on cyrusEditTransform edit 0 [3,5,2] (matrix3 1) false
            QCalculate();cyrusEditCommand edit 3 undefined;QCalculate()
            cyrusEditSelect edit #(2);cyrusEditCommand edit 2 undefined;QCalculate()
            cyrusEditSelect edit #(1);QLayer.procSelectedRadius 1 1.25;QCalculate()
            local fingerprint=QFingerprint()
            setUserProp QNode "EWLegacyFingerprint" fingerprint
            setUserProp QNode "EWLegacySelected" ((cyrusEditSelectedIDs #(edit) QLayer.editLayerKey) as string)
            EWLegacyPath=MCPFixtureDir+"legacy-08687.max";saveMaxFile EWLegacyPath quiet:true
            QAssert (doesFileExist EWLegacyPath and cyrusEditRecipeHasData edit) "E3_old_fixture_created" "Preserved 0.86.8.7 wrote actual legacy Edit move, clone, deletion and radius state."
            QLayer.randomSeed+=1;saveMaxFile (MCPFixtureDir+"legacy-incompatible.max") quiet:true
            QAssert (doesFileExist (MCPFixtureDir+"legacy-incompatible.max")) "E3_old_incompatible_created" "Preserved old code also saved an incompatible pending seed for refusal testing."
        )
        "migrate": (
            QRequire (EWLegacyPath!=undefined and doesFileExist EWLegacyPath) "Frozen legacy scene path required"
            loadMaxFile EWLegacyPath quiet:true useFileUnits:true
            QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.layerObjects[1]
            local edit=QNode.modifiers[1],expected=getUserProp QNode "EWLegacyFingerprint",selected=getUserProp QNode "EWLegacySelected"
            QRoot.updateMode=1;CyrusPointSuspended=true;QCalculate();EWReady()
            local report=createFile (MCPFixtureDir+"legacy-migration.txt")
            format "Fingerprint expected: %\nActual: %\nSelection expected: %\nActual: %\n" expected (QFingerprint()) selected ((cyrusEditSelectedIDs #(edit) QLayer.editLayerKey) as string) to:report;close report
            QAssert (QFingerprint()==expected and ((cyrusEditSelectedIDs #(edit) QLayer.editLayerKey) as string)==selected) "E3_old_exact_migration" "New code reads the genuine legacy chunk and preserves exact placement fields and selected clone/base IDs."
            local before=QFingerprint(),path=MCPFixtureDir+"legacy-upgraded.max"
            saveMaxFile path quiet:true;loadMaxFile path quiet:true useFileUnits:true
            QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.layerObjects[1];QCalculate()
            QAssert (QFingerprint()==before) "E3_old_upgraded_roundtrip" "The upgraded copy reopens without changing the original old-format file."
            local oldPath=substituteString EWLegacyPath "legacy-08687.max" "legacy-incompatible.max"
            loadMaxFile oldPath quiet:true useFileUnits:true
            QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.layerObjects[1];edit=QNode.modifiers[1]
            local failed=false
            try(QCalculate())catch(failed=true)
            QAssert (failed and cyrusEditRecipeHasData edit) "E3_old_incompatible_preserved" "An incompatible legacy scene is refused while its original authored payload remains intact."
            QLayer.randomSeed-=1;QCalculate()
            QAssert (QFingerprint()==getUserProp QNode "EWLegacyFingerprint") "E3_old_recovery" "Restoring the exact original seed recovers legacy edits without a reset."
        )
        "old_reader": (
            QRequire (EWLegacyPath!=undefined and doesFileExist EWLegacyPath) "New-format scene path required"
            local failed=false
            try (
                if not (loadMaxFile EWLegacyPath quiet:true useFileUnits:true) do failed=true
                QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.layerObjects[1];QCalculate()
            )catch(failed=true)
            QAssert failed "E3_old_reader_refusal" "The preserved old module rejects source-aware saved edits instead of silently using incomplete history."
        )
        default:throw "Unknown legacy Edit fixture action"
    )
)
