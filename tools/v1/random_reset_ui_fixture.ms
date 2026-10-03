-- Prepare known values, then verify after each actual native button click.
-- Run brush_relax_reset_fixture.ms first in this private profile.
global CyrusPatchUIRoot,CyrusPatchUIFields,CyrusPatchUIGroups,CyrusPatchUIInitial,CyrusPatchUIOther,CyrusPatchUIHandle,CyrusPatchUICount,CyrusPatchUIBuild,CyrusPatchUIChecks,CyrusPatchUIArmed,CyrusPatchArmResetClick,CyrusPatchVerifyResetClick
(
    if not isValidNode CyrusPatchNode do throw "Run the focused patch fixture first"
    CyrusPatchUIRoot=CyrusPatchNode.baseObject
    local root=CyrusPatchUIRoot,plain=CyrusPatchPlain
    root.selectLayer 2;select CyrusPatchNode;max modify mode
    root.updateMode=1;root.refreshAll()
    CyrusPatchUIGroups=#(
        #(#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#tiltDegrees,#yawMinimum,#yawMaximum),
        #(#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#scaleMinimum,#scaleMaximum),
        #(#wholeScaleMin,#wholeScaleMax),
        #(#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#movementRange)
    )
    CyrusPatchUIFields=#();for fields in CyrusPatchUIGroups do join CyrusPatchUIFields fields
    undo off (
        plain.setLayerTransfer true
        for i=1 to CyrusPatchUIFields.count do setProperty plain CyrusPatchUIFields[i] (1.5+i*.1)
        plain.setLayerTransfer false
    )
    root.bindNativeUI()
    -- Expand Randomize XYZ through its actual native header before clicking.
    CyrusPatchUIInitial=for field in CyrusPatchUIFields collect getProperty plain field
    CyrusPatchUIOther=for field in CyrusPatchUIFields collect getProperty CyrusPatchLayer field
    CyrusPatchUIHandle=root.randomUI.hwnd
    CyrusPatchUICount=plain.generatedCount;CyrusPatchUIBuild=(plain.cacheSnapshot())[6]
    CyrusPatchUIChecks=#()
    CyrusPatchUIArmed=0
)
fn CyrusPatchArmResetClick group = (
    local root=CyrusPatchUIRoot,plain=CyrusPatchPlain
    if group<1 or group>4 or findItem CyrusPatchUIChecks group>0 do throw "Unexpected reset-click group"
    if root.updateMode!=1 or plain.updateMode!=1 do throw "Reset-click fixture left Manual mode"
    for i=1 to CyrusPatchUIFields.count where getProperty plain CyrusPatchUIFields[i]!=CyrusPatchUIInitial[i] do throw "Reset-click fixture values changed before input"
    -- Undo can restore/reinitialize transient local caches. Take a fresh
    -- publication baseline before each click, after that restoration settles.
    CyrusPatchUICount=plain.generatedCount;CyrusPatchUIBuild=(plain.cacheSnapshot())[6]
    CyrusPatchUIArmed=group
    true
)
fn CyrusPatchVerifyResetClick group = (
    if CyrusPatchUIArmed!=group do throw "Arm this group before the actual mouse click"
    local root=CyrusPatchUIRoot,plain=CyrusPatchPlain,neutral=if group==2 or group==3 then 1.0 else 0.0
    for i=1 to CyrusPatchUIFields.count do (
        local expected=if findItem CyrusPatchUIGroups[group] CyrusPatchUIFields[i]>0 then neutral else CyrusPatchUIInitial[i]
        if getProperty plain CyrusPatchUIFields[i]!=expected do throw "Actual button click did not reset exactly its group"
        if getProperty CyrusPatchLayer CyrusPatchUIFields[i]!=CyrusPatchUIOther[i] do throw "Button changed the other layer"
    )
    if root.randomUI.hwnd!=CyrusPatchUIHandle do throw "Button remounted the native editor"
    if root.updateMode!=1 or plain.updateMode!=1 or plain.generatedCount!=CyrusPatchUICount or (plain.cacheSnapshot())[6]!=CyrusPatchUIBuild do throw "Button published in Manual mode"
    max undo
    for i=1 to CyrusPatchUIFields.count where getProperty plain CyrusPatchUIFields[i]!=CyrusPatchUIInitial[i] do throw "One Undo did not restore actual click"
    append CyrusPatchUIChecks group
    CyrusPatchUIArmed=0
    root.bindNativeUI()
    CSPWriteText (BLDir+"native-reset-clicks.json") (CSPObject #(#("actual_mouse_click_groups",CyrusPatchUIChecks),#("single_undo",true),#("other_layer_and_groups_preserved",true),#("manual_publication_preserved",true),#("editor_handle_reused",true)))
    true
)
