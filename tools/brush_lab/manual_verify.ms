-- After manual_begin.ms, paint one erase gesture and press Stop / navigate.
(
BLPanel.refresh.active=false
local d=BLDocument()
local stats=cyrusBrushStats d
BLAssert (stats[2]==BLManualHistory+1) "Expected one real erase stroke"
BLAssert ((cyrusBrushHistory d)[stats[2] as integer][2]) "Last stroke is not Erase"
BLAssert (stats[5]==0) "Stop did not leave painting mode"
BLAssert (stats[9]>BLManualStats[9]) "Manual stroke did not evaluate the mask overlay"
local counters=cyrusRetainedStats BLPreviewOwner
BLAssert (BLPublished==BLManualRevision) "Manual stop published plants"
BLAssert (counters[3]==BLManualCounters[3] and counters[6]==BLManualCounters[6] and counters[7]==BLManualCounters[7]) "Manual stroke uploaded plants"
local erased=cyrusBrushRows d
BLAssert (erased.count<BLManualRows.count) "Erase did not remove coverage"
for row in erased do (
    local found=false
    for original in BLManualRows while not found do found=(row[1]==original[1])
    BLAssert found "Erase moved a survivor"
)
BLPublish()
BLAssert (BLPublished==stats[1]) "Explicit Update did not publish committed paint"
max undo
BLAssert ((cyrusEditFingerprint (cyrusBrushRows d) "brush")== (cyrusEditFingerprint BLManualRows "brush")) "Erase Undo changed original plants"
max redo
BLAssert ((cyrusEditFingerprint (cyrusBrushRows d) "brush")== (cyrusEditFingerprint erased "brush")) "Erase Redo differed"
max undo
BLPanel.live.checked=true;BLPanel.mode.state=1;BLApplySettings();BLPublish()
CSPWriteText (BLDir+"manual-erase.json") (CSPObject #(#("before",BLManualRows.count),#("erased",erased.count),#("manual_field_builds",stats[9]-BLManualStats[9]),#("manual_uploads",counters[6]-BLManualCounters[6]),#("manual_stop_preserved_preview",true),#("explicit_update",true),#("erase_survivors_stable",true),#("undo_redo",true)))
BLPanel.refresh.active=true
)
