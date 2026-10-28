global ADNativeJSON,ADNativeObject,ADInitialTransform,ADColorSource,ADColorPoly,ADInitialVertex,ADNativeTreeSource,ADNativeSourceInfo,ADPresentTrial
fn ADPresentTrial = (
    for node in objects where node!=WFOwner and node!=ADWall and node!=(CyrusPointOwner WFOwner) and node.name!="Plane001" do hide node
    unhide ADWall
    select ADWall;max move
    local centre=ADWall.pos+[0,0,units.decodeValue "50cm"],extent=units.decodeValue "4m",eye=centre+[extent,-extent,extent*.7]
    local back=normalize(eye-centre),right=normalize(cross [0,0,1] back),up=cross back right
    viewport.setType #view_persp_user;viewport.setFOV 45;viewport.setTM(inverse(matrix3 right up back eye));redrawViews()
)
fn ADNativeObject pairs = #(#adaptationObject,pairs)
fn ADNativeJSON value = (
    if classof value==Array then (
        if value.count==2 and value[1]==#adaptationObject then (
            local text="{",first=true
            for pair in value[2] do (if not first do text+=",";first=false;text+=(ADNativeJSON pair[1])+":"+(ADNativeJSON pair[2]))
            text+"}"
        ) else (local text="[",first=true;for item in value do (if not first do text+=",";first=false;text+=ADNativeJSON item);text+"]")
    ) else if classof value==Point3 then ADNativeJSON #(value.x,value.y,value.z)
    else if classof value==String then (local text=substituteString value "\\" "\\\\";text=substituteString text "\"" "\\\"";text=substituteString text "\r" "\\r";text=substituteString text "\n" "\\n";"\""+text+"\"")
    else if value==undefined then "null"
    else if classof value==BooleanClass then (if value then "true" else "false")
    else value as string
)
(
    if not matchPattern GardenRun pattern:"*/build/adaptation08754-20261028-01/host-*/" do throw "Owned adaptation host required."
    if theHold.Holding() or theHold.IsSuspended() do throw "Unexpected authored hold before native scenario."
    local result=#(#("phase",CVProfileCase)),failure="",project=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\"
    try (
        case CVProfileCase of (
            "recipe-guard":(
                local message=""
                try(CyrusRecipeCaptureAuthored (CyrusRecipeCaptureContext root:WFRoot owners:#(WFGrass)))catch(message=getCurrentException())
                if not matchPattern message pattern:"*Scene preset*" do throw "Portable capture did not explain the required Scene preset."
                append result #("message",message)
            )
            "present-trial":(ADPresentTrial();append result #("statistics",WFRoot.interactionsStatistics()))
            "neighbor-restore":(
                local original=ADWall.transform,before=WFRoot.interactionsStatistics()
                ADWall.pos+= [0,0,units.decodeValue "10m"]
                if not cyrusInteractionSceneUpdate WFRoot.interactionState do throw "Moved wall did not publish."
                append result #("away",WFRoot.interactionsStatistics())
                ADWall.transform=original
                if not cyrusInteractionSceneUpdate WFRoot.interactionState do throw "Returning wall did not publish."
                append result #("before",before);append result #("returned",WFRoot.interactionsStatistics())
            )
            "neighbor-grove":(
                ADWall.pos.z+=units.decodeValue "20m"
                WFGrass.amount=60;WFGrass.interactionNeighbors=false
                WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
                append result #("neighbors_off",WFRoot.interactionsStatistics())
                WFGrass.interactionNeighbors=true;WFRoot.interactionsChanged();WFRoot.interactionsEnsure();CyrusPointSync()
                append result #("neighbors_on",WFRoot.interactionsStatistics())
                WFRoot.interactionsEnsure();CyrusPointSync()
                append result #("repeated",WFRoot.interactionsStatistics())
            )
            "save-load":(
                local path=GardenRun+"roundtrip.max",before=WFRoot.interactionsStatistics()
                local saved=#(WFGrass.interactionResponse,WFGrass.interactionBendStrength,WFGrass.interactionPruneAmount,WFGrass.interactionPruneThresholdWU,WFGrass.interactionNeighbors,WFRoot.interactionSceneColliders[1].name,WFRoot.interactionSceneColliders[1].transform,WFGrass.interactionDefinitions[1])
                if not saveMaxFile path quiet:true do throw "Owned round-trip save failed."
                if not loadMaxFile path quiet:true useFileUnits:true missingDLLsAction:#logmsg do throw "Owned round-trip load failed."
                WFOwner=undefined
                for node in objects where classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined do WFOwner=node
                if not isValidNode WFOwner do throw "Scatter root was not saved."
                WFRoot=WFOwner.baseObject;WFGrass=WFRoot.layerObjects[1];ADWall=WFRoot.interactionSceneColliders[1]
                if not isValidNode ADWall or ADWall.name!=saved[6] or ADWall.transform!=saved[7] do throw "Ordinary scene collider reference/transform did not round trip."
                local restored=#(WFGrass.interactionResponse,WFGrass.interactionBendStrength,WFGrass.interactionPruneAmount,WFGrass.interactionPruneThresholdWU,WFGrass.interactionNeighbors,ADWall.name,ADWall.transform,WFGrass.interactionDefinitions[1])
                for i=1 to saved.count where saved[i]!=restored[i] do throw ("Round-trip field differs: "+i as string)
                WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
                if WFRoot.interactionError!="" do throw WFRoot.interactionError
                append result #("before",before);append result #("after",WFRoot.interactionsStatistics());append result #("restored_fields",7)
            )
            "scaled-boxes-native":(
                local original=ADWall.transform,error=""
                ADWall.scale=[2,.04,1.2]
                if not cyrusInteractionSceneUpdate WFRoot.interactionState do throw "Positive scaled wall did not publish."
                append result #("positive",WFRoot.interactionsStatistics())
                ADWall.scale=[-2,.04,1.2]
                if not cyrusInteractionSceneUpdate WFRoot.interactionState do throw "Mirrored wall did not publish."
                append result #("mirrored",WFRoot.interactionsStatistics())
                ADWall.scale=[0,.04,1.2]
                append result #("evaluated_zero_scale",ADWall.scale)
                try(cyrusInteractionSceneUpdate WFRoot.interactionState)catch(error=getCurrentException())
                append result #("zero_scale_result",error)
                ADWall.transform=original;cyrusInteractionSceneUpdate WFRoot.interactionState
            )
            "collapsed-atomic":(
                local original=ADWall.transform,error="",accepted=undefined,before=WFRoot.interactionsStatistics()
                ADWall.scale=[0,.04,1.2]
                local evaluated=ADWall.transform,determinant=dot (cross evaluated.row1 evaluated.row2) evaluated.row3
                append result #("evaluated_axes",#(evaluated.row1,evaluated.row2,evaluated.row3));append result #("evaluated_determinant",determinant)
                try(accepted=cyrusInteractionSceneUpdate WFRoot.interactionState)catch(error=getCurrentException())
                append result #("fast_accepted",accepted);append result #("fast_error",error)
                append result #("before",before);append result #("retained",WFRoot.interactionsStatistics())
                error=""
                try(WFRoot.interactionsEnsure())catch(error=getCurrentException())
                append result #("stage_error",error)
                ADWall.transform=original;WFRoot.interactionsEnsure();CyrusPointSync()
                -- Max's scale controller can replace typed zero by a tiny
                -- nonzero evaluated axis. Only a truly singular matrix is a
                -- rejection oracle; the numeric suite tests that boundary.
                if accepted==true and determinant==0 do throw "A truly singular evaluated wall was accepted."
                append result #("host_clamped_zero",accepted==true and determinant!=0)
            )
            "equivalent-boxes":(
                local original=ADWall,reference=WFRoot.interactionsStatistics(),metre=units.decodeValue "1m"
                ADBox=box name:"AD_Parameter_Wall" width:(1.5*metre) length:(.15*metre) height:(.65*metre) pos:ADWall.pos
                WFRoot.interactionsSceneCommand #(ADBox)
                WFRoot.interactionsSceneCommand #() removeIndex:1
                WFRoot.interactionsEnsure();CyrusPointSync()
                append result #("scaled",reference);append result #("parameter",WFRoot.interactionsStatistics())
                WFRoot.interactionsSceneCommand #(original);WFRoot.interactionsSceneCommand #() removeIndex:1
                ADWall=original;WFRoot.interactionsEnsure();CyrusPointSync()
            )
            "geometry-edit":(
                local before=WFRoot.interactionsStatistics(),original=ADWall.width
                ADWall.width=original*1.2
                WFRoot.interactionsEnsure();CyrusPointSync()
                append result #("before",before);append result #("changed",WFRoot.interactionsStatistics())
                ADWall.width=original;WFRoot.interactionsEnsure();CyrusPointSync()
            )
            "color-after-failure":(
                ADColorSource=(WFGrass.validSources())[1]
                ADColorPoly=classof ADColorSource.baseObject==Editable_Poly
                if not ADColorPoly and classof ADColorSource.baseObject!=Editable_Mesh do throw "Color regression fixture requires an editable source."
                ADInitialVertex=if ADColorPoly then polyOp.getVert ADColorSource 1 else getVert ADColorSource 1
                undo "AD change source geometry" on (if ADColorPoly then polyOp.setVert ADColorSource #{1} (ADInitialVertex+[1,0,0]) else setVert ADColorSource 1 (ADInitialVertex+[1,0,0]);update ADColorSource)
                local message=""
                try(WFRoot.interactionsEnsure())catch(message=getCurrentException();WFRoot.interactionError=message)
                if message=="" do throw "Expected a pending source-geometry rejection."
                local before=WFRoot.interactionsStatistics()
                WFGrass.setSourceIDColor #{1} (color 40 140 230)
                local colorIndex=WFGrass.sourceVisualIndex 1
                if colorIndex<1 or not WFGrass.visualSourceColorSet[colorIndex] do throw "Source color was not authored."
                local chosen=WFGrass.visualSourceColors[colorIndex]
                if abs(chosen.r-40)>.1 or abs(chosen.g-140)>.1 or abs(chosen.b-230)>.1 do throw "Source color differs."
                if CyrusPointLastError!="" do throw CyrusPointLastError
                append result #("retained_error",message);append result #("before",before);append result #("after",WFRoot.interactionsStatistics())
            )
            "restore-source":(
                undo "AD restore source geometry" on (if ADColorPoly then polyOp.setVert ADColorSource #{1} ADInitialVertex else setVert ADColorSource 1 ADInitialVertex;update ADColorSource)
                WFGrass.interactionsPrepare #(ADColorSource) rebuild:true
                WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
            )
            "dense":(
                local before=WFRoot.interactionsStatistics(),times=#(),origin=ADWall.pos
                WFGrass.amount=1000;WFRoot.viewportNavigationFaces=500000;WFRoot.viewportFaces=2000000
                WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
                for dx in #(0,20,40,60,80,100,80,60,40,20,0) do (
                    ADWall.pos=origin+[dx,0,0]
                    local start=timeStamp()
                    if not cyrusInteractionSceneUpdate WFRoot.interactionState do throw "Dense scene update could not publish."
                    append times (timeStamp()-start)
                )
                append result #("before",before);append result #("times_ms",times);append result #("after",WFRoot.interactionsStatistics())
            )
            "render-bake-native":(
                local oldAmount=WFGrass.amount
                WFGrass.amount=10;WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
                append result #("statistics",WFRoot.interactionsStatistics())
                append result #("render",cyrusInteractionRenderInfo WFRoot.interactionState 2)
                local baked=cyrusInteractionBake WFRoot.interactionState 1,faces=0
                for node in baked do faces+=getNumFaces node.mesh
                append result #("baked_faces",faces);append result #("baked_nodes",baked.count)
                undo off for node in baked do delete node
            )
            "prepare-fern":(
                local source=getNodeByName "Outdoor_Plants_01_Neottopteris_Nidus_Bush_Decorative05_001" exact:true
                if not isValidNode source do throw "Real fern fixture is missing."
                WFGrass.removeModelSources (for i=1 to WFGrass.sources.count collect i)
                WFGrass.addModelSource source
                WFGrass.interactionMinimumM=.005;WFGrass.interactionConnectionM=.15
                WFGrass.interactionsPrepare #(source) rebuild:true
                WFGrass.amount=12;WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
                local centre=(cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[1])[1][1].row4
                ADWall.pos=centre
                cyrusInteractionSceneUpdate WFRoot.interactionState
                append result #("source",source.name);append result #("statistics",WFRoot.interactionsStatistics());append result #("definition_count",WFGrass.interactionDefinitions.count)
            )
            "prepare-branch-tree":(
                fileIn (project+@"tools\procedural_lab\adaptation08754\tree_generated.ms")
                WFGrass.removeModelSources (for i=1 to WFGrass.sources.count collect i)
                WFGrass.addModelSource ADTree
                WFGrass.interactionMinimumM=.005;WFGrass.interactionConnectionM=.15;WFGrass.interactionFoliage=1
                WFGrass.interactionsPrepare #(ADTree) rebuild:true
                WFGrass.amount=6;WFGrass.interactionResponse=3;WFGrass.interactionNeighbors=true
                WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
                local centre=(cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[1])[1][1].row4
                ADWall.pos=centre+[0,0,(units.decodeValue "60cm")]
                cyrusInteractionSceneUpdate WFRoot.interactionState
                append result #("statistics",WFRoot.interactionsStatistics());append result #("definition_count",WFGrass.interactionDefinitions.count)
                append result #("preparation",cyrusInteractionSourceInfo (WFGrass.interactionSourceCache[1][2]))
            )
            "delete-collider":(
                undo "AD delete ordinary collider" on delete ADWall
                WFRoot.interactionsEnsure();CyrusPointSync()
                if WFRoot.interactionSceneColliders.count!=1 or isValidNode WFRoot.interactionSceneColliders[1] do throw "Deleted collider reference was not retained as a missing row."
                append result #("statistics",WFRoot.interactionsStatistics())
            )
            "verify-delete-undo":(
                if not isValidNode WFRoot.interactionSceneColliders[1] do throw "Collider deletion Undo did not restore its reference."
                ADWall=WFRoot.interactionSceneColliders[1];WFRoot.interactionsEnsure();CyrusPointSync()
                append result #("statistics",WFRoot.interactionsStatistics())
            )
            "save-grass":(
                WFGrass.amount=1000;WFRoot.viewportNavigationFaces=500000;WFRoot.viewportFaces=2000000
                WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
                for node in objects where node!=WFOwner and node!=ADWall and node!=(CyrusPointOwner WFOwner) and node.name!="Plane001" do hide node
                select ADWall;max move
                local centre=ADWall.pos,extent=units.decodeValue "5m",eye=centre+[extent,-extent,extent*.8]
                local back=normalize(eye-centre),right=normalize(cross [0,0,1] back),up=cross back right
                viewport.setType #view_persp_user;viewport.setFOV 45;viewport.setTM(inverse(matrix3 right up back eye));redrawViews()
                local folder=project+@"Test Scene\Interaction 0.87.5.4\"
                makeDir folder
                local file=folder+"Scene_Collider_Grass_0.87.5.4.max"
                if not saveMaxFile file quiet:true do throw "Could not save grass trial copy."
                append result #("scene",file);append result #("statistics",WFRoot.interactionsStatistics())
            )
            "save-fern":(
                -- The supplied scene references optional renderer shaders. The
                -- interaction trial uses Mesh display without altering them.
                WFRoot.setGroupDisplay 2
                ADPresentTrial()
                local folder=project+@"Test Scene\Interaction 0.87.5.4\"
                makeDir folder
                local file=folder+"Scene_Collider_Fern_0.87.5.4.max"
                if not saveMaxFile file quiet:true do throw "Could not save fern trial copy."
                append result #("scene",file);append result #("statistics",WFRoot.interactionsStatistics())
            )
            "save-trees":(
                ADPresentTrial()
                local folder=project+@"Test Scene\Interaction 0.87.5.4\"
                makeDir folder
                local file=folder+"Branch_Tree_Neighbors_0.87.5.4.max"
                if not saveMaxFile file quiet:true do throw "Could not save tree trial copy."
                append result #("scene",file);append result #("statistics",WFRoot.interactionsStatistics())
            )
            default:throw ("Unknown native scenario "+CVProfileCase)
        )
        if theHold.Holding() or theHold.IsSuspended() do throw "Native scenario leaked an authored hold."
        append result #("status","pass")
    )catch(failure=getCurrentException();append result #("status","failed");append result #("error",failure);append result #("stack",getCurrentExceptionStackTrace()))
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+CVProfileCase+".json") (ADNativeJSON (ADNativeObject result))
    if failure!="" do throw failure
)
