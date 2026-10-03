-- Run after at least one real mouse stroke on each fixture surface.
(
global BLFlatExpected,BLCurvedExpected,BLVerifyResults
BLPanel.refresh.active=false
cyrusBrushStop()
local flatDoc=BLFlatLayer.CyrusBrushLabData.paintDocument
local curvedDoc=BLCurvedLayer.CyrusBrushLabData.paintDocument
local checks=#()
fn sameRows a b = (
    if a.count!=b.count then false else (
        local same=true
        for i=1 to a.count while same do same=(a[i][1]==b[i][1] and a[i][2]==b[i][2])
        same
    )
)
BLFlatExpected=cyrusBrushRows flatDoc
BLCurvedExpected=cyrusBrushRows curvedDoc
BLAssert (BLFlatExpected.count>0 and BLCurvedExpected.count>0) "Paint both surfaces before verification"
local originalStats=cyrusBrushStats curvedDoc
-- Native hold has one entry for one mouse gesture, regardless of dab count.
max undo
BLAssert ((cyrusBrushRows curvedDoc).count==0) "Mouse gesture Undo failed"
max redo
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows curvedDoc)) "Mouse gesture Redo changed candidates"
append checks #("gesture_undo_redo",true)
-- Existing stroke radius edits replay the saved screen rays.
cyrusBrushStroke curvedDoc 1 true 1 8
local smaller=cyrusBrushRows curvedDoc
BLAssert (smaller.count>0 and smaller.count<BLCurvedExpected.count) "Radius edit did not shrink paint"
max undo
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows curvedDoc)) "Stroke edit Undo failed"
append checks #("radius_replay_undo",smaller.count)
cyrusBrushStroke curvedDoc 1 false 1 24
BLAssert ((cyrusBrushRows curvedDoc).count==0) "Disable stroke did not clear mask"
max undo
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows curvedDoc)) "Disable Undo failed"
append checks #("disable_stroke_undo",true)
-- Density is deterministic thinning, restoring it gives exactly the same rows.
cyrusBrushSettings curvedDoc 24 1 .5 false .5
local fewer=cyrusBrushRows curvedDoc
BLAssert (fewer.count>0 and fewer.count<BLCurvedExpected.count) "Density failed"
for row in fewer do (
    local found=false
    for original in BLCurvedExpected while not found do found=(row[1]==original[1])
    BLAssert found "Density moved a surviving candidate"
)
cyrusBrushSettings curvedDoc 24 1 .5 false 1
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows curvedDoc)) "Density restore failed"
append checks #("density_subset",fewer.count)
-- Canceled strokes must not be added to the document.
cyrusBrushDab curvedDoc [0,-400,0] [0,1,0] false
cyrusBrushCancel curvedDoc
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows curvedDoc)) "Cancel changed committed paint"
append checks #("cancel",true)
-- Paint-only editing never regenerates the stable base candidates.
BLAssert ((cyrusBrushStats curvedDoc)[8]==originalStats[8]) "Paint edit rebuilt base candidates"
append checks #("stable_base",true)
-- Inactive orbit must not evaluate the field or publish preview buffers.
BLUse BLCurvedLayer
completeRedraw();windows.processPostedMessages();completeRedraw()
local before=cyrusBrushStats curvedDoc
local retainedBefore=cyrusRetainedMeshStats BLPreviewOwner
local countersBefore=cyrusRetainedStats BLPreviewOwner
local tm=viewport.getTM()
for i=1 to 20 do (viewport.setTM (rotateZMatrix (i*.15)*tm);completeRedraw())
viewport.setTM tm;completeRedraw()
local after=cyrusBrushStats curvedDoc
BLAssert (before[9]==after[9] and before[10]==after[10]) "Orbit evaluated Brush field"
local countersAfter=cyrusRetainedStats BLPreviewOwner
BLAssert (countersBefore[3]==countersAfter[3] and countersBefore[6]==countersAfter[6] and countersBefore[7]==countersAfter[7]) "Orbit republished or uploaded Brush preview"
append checks #("inactive_field_builds",after[9]-before[9])
append checks #("inactive_uploads",countersAfter[6]-countersBefore[6])
append checks #("retained_before",retainedBefore)
append checks #("retained_after",cyrusRetainedMeshStats BLPreviewOwner)
-- Native document is scene-owned and deep cloned.
local duplicate=copy BLCurvedLayer
local duplicateDoc=duplicate.CyrusBrushLabData.paintDocument
cyrusBrushBind duplicateDoc
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows duplicateDoc)) "Clone lost paint"
cyrusBrushStroke duplicateDoc 1 false 1 24
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows curvedDoc)) "Clone aliases original stroke history"
append checks #("clone_isolation",true)
delete duplicate
clearUndoBuffer()
-- A transform keeps local anchors, but requires explicit validation in this lab.
local oldTM=BLFlat.transform
BLFlat.pos+=[0,0,20]
BLAssert ((cyrusBrushStats flatDoc)[4]==0) "Target transform was not invalidated"
cyrusBrushBind flatDoc
local moved=cyrusBrushRows flatDoc
BLAssert (moved.count==BLFlatExpected.count) "Transform changed membership"
for i=1 to moved.count do BLAssert (distance moved[i][1].row4 (BLFlatExpected[i][1].row4+[0,0,20])<.001) "Paint did not follow transform"
BLFlat.transform=oldTM;cyrusBrushBind flatDoc
append checks #("transform_follow",true)
-- Topology changes suspend the document and preserve the previous preview.
BLCurved.segs=24
BLAssert ((cyrusBrushStats curvedDoc)[4]==0) "Topology edit was not detected"
local rejected=false
try(cyrusBrushBind curvedDoc)catch(rejected=true)
BLAssert rejected "Changed topology silently rebound"
BLCurved.segs=48;cyrusBrushBind curvedDoc
BLAssert (sameRows BLCurvedExpected (cyrusBrushRows curvedDoc)) "Topology recovery changed paint"
append checks #("topology_suspend_recover",true)
BLVerifyResults=checks
-- Save only fixture/controller/source data; retained owners are derived.
if isValidNode BLPreviewOwner do delete BLPreviewOwner
BLPreviewOwner=undefined;BLPublished=0;BLCache=undefined
BLAssert (saveMaxFile (BLDir+"BrushLab.max") quiet:true) "Fixture save failed"
CSPWriteText (BLDir+"verification.json") (CSPObject #(#("checks",checks),#("flat_rows",BLFlatExpected.count),#("curved_rows",BLCurvedExpected.count),#("flat_signature",cyrusEditFingerprint BLFlatExpected "brush"),#("curved_signature",cyrusEditFingerprint BLCurvedExpected "brush"),#("curved_stats",cyrusBrushStats curvedDoc)))
BLPublish()
BLPanel.refresh.active=true
BLCapture "verified"
)
