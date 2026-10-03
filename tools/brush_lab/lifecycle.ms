-- Disposable clones only; retain the two demonstration layers.
(
BLPanel.refresh.active=false
cyrusBrushLabStop()
local checks=#()
local originals=#(BLCurvedLayer,BLCurved)
local clones=#()
BLAssert (maxOps.cloneNodes originals cloneType:#copy newNodes:&clones) "Pair clone failed"
local layer=undefined
local surface=undefined
for node in clones do (
    if isProperty node #CyrusBrushLabData then layer=node else surface=node
)
BLAssert (isValidNode layer and isValidNode surface) "Pair clone did not return both nodes"
local d=layer.CyrusBrushLabData.paintDocument
cyrusBrushLabBind d
local before=cyrusBrushLabRows d
surface.pos+=[0,0,25]
cyrusBrushLabBind d
local moved=cyrusBrushLabRows d
BLAssert (before.count==moved.count) "Pair clone changed membership"
for i=1 to moved.count do BLAssert (distance moved[i][1].row4 (before[i][1].row4+[0,0,25])<.001) "Pair clone retained original target"
append checks #("pair_clone_remaps_target",true)
cyrusBrushLabBegin d
hide surface
local hidden=cyrusBrushLabStats d
BLAssert (hidden[4]==0 and hidden[5]==0) "Hidden target did not suspend session"
unhide surface;cyrusBrushLabBind d
append checks #("hidden_target_stops_session",true)
cyrusBrushLabBegin d
delete surface
local deleted=cyrusBrushLabStats d
BLAssert (deleted[4]==0 and deleted[5]==0) "Deleted target did not release session"
local rejected=false
try(cyrusBrushLabRows d)catch(rejected=true)
BLAssert rejected "Deleted target produced fresh placements"
append checks #("deleted_target_stops_and_rejects",true)
delete layer
clearUndoBuffer()
-- Explicitly canceled pending input cannot change committed paint.
local main=BLDocument()
local signature=cyrusEditFingerprint (cyrusBrushLabRows main) "brush"
cyrusBrushLabBegin main
cyrusBrushLabDab main [0,-400,0] [0,1,0] false
cyrusBrushLabStop()
BLAssert ((cyrusBrushLabStats main)[6]==0) "Stop retained a pending gesture"
BLAssert ((cyrusEditFingerprint (cyrusBrushLabRows main) "brush")==signature) "Stop committed canceled input"
append checks #("stop_cancels_pending_input",true)
BLPublish()
BLPanel.refresh.active=true
CSPWriteText (BLDir+"lifecycle.json") (CSPObject #(#("checks",checks)))
)
