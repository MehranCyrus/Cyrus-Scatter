-- Whole-node transforms: never invoke the helper's sub-object callbacks.
global U73NodeMove
fn U73NodeMove = (
    P07Checks=#();P07Case="whole-node container Move transaction";P07New count:2000
    local r=P07Root,a=P07Layer,s=P07Source,c=a.containerCreate();c.pos=s.pos
    r.refreshAll();CyrusContainerRefreshAll()
    local p=s.transform,q=c.transform,signature=P07Fingerprint r,epoch=(r.groupCounters())[1]
    local stats=c.movementStats(),delta=[200,30,0],stages=#()
    undo "U73 native node Move" on move c delta
    P07Assert (distance c.pos (q.row4+delta)<.0001 and distance s.pos (p.row4+delta)<.0001) "Whole-node Move left its source behind"
    P07Assert ((c.movementStats())[1]==stats[1]+1 and (c.movementStats())[2]==stats[2]+1 and not (c.movementStats())[6]) "Whole-node Move did not complete once"
    append stages #("move",s.pos as string,c.pos as string,theHold.GetUndoNames(),theHold.GetRedoNames(),c.movementStats())
    max undo
    append stages #("undo",s.pos as string,c.pos as string,theHold.GetUndoNames(),theHold.GetRedoNames(),c.movementStats())
    P07Assert (distance c.pos q.row4<.0001 and distance s.pos p.row4<.0001) "Whole-node Move was not one Undo"
    max redo
    append stages #("redo",s.pos as string,c.pos as string,theHold.GetUndoNames(),theHold.GetRedoNames(),c.movementStats())
    P07Assert (distance c.pos (q.row4+delta)<.0001 and distance s.pos (p.row4+delta)<.0001) "Whole-node Redo lost the source"
    max undo
    append stages #("undo_again",s.pos as string,c.pos as string,theHold.GetUndoNames(),theHold.GetRedoNames(),c.movementStats())
    CSPWriteText (MCPFixtureDir+"node-second-undo-debug.json") (CSPObject #(#("stages",stages)))
    P07Assert (distance c.pos q.row4<.0001 and distance s.pos p.row4<.0001) "Repeated Move Undo differs"
    r.evaluateGroups();CyrusContainerRefreshAll()
    local during=#()
    undo "U73 node and model selection" on (
        append during #(theHold.GetBeginDepth(),s.pos as string,c.movementStats())
        move #(c,s) [60,0,0]
        append during #(theHold.GetBeginDepth(),s.pos as string,c.movementStats())
    )
    CSPWriteText (MCPFixtureDir+"node-combined-debug.json") (CSPObject #(#("source",s.pos as string),#("container",c.pos as string),#("initial",p.row4 as string),#("stats",c.movementStats()),#("during",during)))
    P07Assert (distance s.pos (p.row4+[60,0,0])<.0001) "Combined whole-node selection moved a source twice"
    max undo
    P07Assert (distance c.pos q.row4<.0001 and distance s.pos p.row4<.0001) "Combined whole-node Undo differs"
    CyrusContainerRefreshAll()
    theHold.Begin();move c [90,0,0];theHold.Cancel()
    P07Assert (distance c.pos q.row4<.0001 and distance s.pos p.row4<.0001 and not (c.movementStats())[6]) "Cancelled whole-node gesture changed source transforms"
    CyrusContainerRefreshAll()
    local failures=(c.movementStats())[4]
    undo "U73 independent source change" on (move c [50,0,0];move s [0,10,0])
    P07Assert ((c.movementStats())[4]==failures+1 and distance c.pos q.row4<.0001 and distance s.pos p.row4<.0001) "Independent source edit did not roll back the frozen gesture"
    max undo;CyrusContainerRefreshAll()
    -- Real group hierarchy, including its head, follows the same node event.
    local flower=box name:"U73_RealNodeFlower" width:8 length:8 height:20 pos:(s.pos+[20,0,0])
    local head=group #(s,flower) name:"U73_RealNodeGroup"
    a.containerScan=true;r.refreshAll();CyrusContainerRefreshAll()
    local fp=flower.pos,hp=head.pos
    undo "U73 whole-node group Move" on move c [100,20,0]
    P07Assert (distance s.pos (p.row4+[100,20,0])<.0001 and distance flower.pos (fp+[100,20,0])<.0001 and distance head.pos (hp+[100,20,0])<.0001) "Whole-node Move did not carry a complete group"
    max undo
    P07Assert (distance s.pos p.row4<.0001 and distance flower.pos fp<.0001 and distance head.pos hp<.0001) "Whole-node group Undo differs"
    P07Record "whole_node_movement" #(c.movementStats(),true,true,true,true)
    true
)
