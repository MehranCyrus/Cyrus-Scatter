-- Definitions only. Own private scene, no pointer automation.
global U73GroupMove
fn U73GroupMove = (
    P07Checks=#();P07Case="whole groups and frozen container movement";P07New count:1200
    local r=P07Root,a=P07Layer,s=P07Source,c=a.containerCreate();c.pos=s.pos
    local flower=box name:"U73_GroupFlower" width:8 length:8 height:20 pos:(s.pos+[20,0,0])
    local head=group #(s,flower) name:"U73_SourceGroup"
    a.containerScan=true;r.refreshAll();CyrusContainerRefreshAll()
    P07Assert (findItem a.sources flower>0 and c.movementUnits.count==1 and c.movementUnits[1]==head) "Whole static group was not one movement unit"
    r.setGroupDisplay 3;r.refreshAll();CyrusPointSync();completeRedraw();windows.processPostedMessages()
    local owner=CyrusPointOwner P07Node,retained=cyrusRetainedStats owner,signature=P07Fingerprint r,builds=r.groupCounters()
    local p=s.pos,q=flower.pos,h=head.pos,containerPos=c.pos
    cyrusDiagnosticStart "unified_group_movement" 4096 4194304 600000
    c.movePalette [100,30,0];r.evaluateGroups();CyrusPointSync()
    P07Assert (distance s.pos (p+[100,30,0])<.0001 and distance flower.pos (q+[100,30,0])<.0001 and distance head.pos (h+[100,30,0])<.0001) "Group members did not follow uniformly"
    P07Assert ((P07Fingerprint r) as string==signature as string and (r.groupCounters())[1]==builds[1]) "Whole group movement regenerated placement"
    local after=cyrusRetainedStats owner
    CSPWriteText (MCPFixtureDir+"group-retained-comparison.json") (CSPObject #(#("before",retained),#("after",after)))
    -- Revision also counts enable/disable during Max's interaction hold.
    -- Assert actual preparation/publication/upload counters and data identity.
    for i in #(4,5,6,7,13) do P07Assert (after[i]==retained[i]) "Palette move rebuilt or uploaded unchanged retained data"
    max undo
    P07Assert (distance s.pos p<.0001 and distance flower.pos q<.0001 and distance head.pos h<.0001 and distance c.pos containerPos<.0001) "Group move was not one Undo"
    r.evaluateGroups();CyrusContainerRefreshAll()
    -- A child cannot change independently while the frozen group is carried.
    local errors=(c.movementStats())[4]
    undo "U73 frozen failure" on (
        cyrusContainerGesture c.delegate 0
        c.pos+= [100,0,0];flower.pos+= [0,10,0]
        cyrusContainerGesture c.delegate 1
    )
    P07Assert ((c.movementStats())[4]==errors+1 and distance c.pos containerPos<.0001 and distance s.pos p<.0001 and distance flower.pos q<.0001) "Failed group gesture did not restore every transform"
    r.evaluateGroups();CyrusContainerRefreshAll()
    -- Max restores its hold before invoking the SDK cancel notification.
    undo "U73 cancel hold" on (cyrusContainerGesture c.delegate 0;c.pos+= [70,0,0])
    max undo;cyrusContainerGesture c.delegate 2
    P07Assert (distance c.pos containerPos<.0001 and distance flower.pos q<.0001 and not (c.movementStats())[6]) "Cancel retained a frozen gesture or moved sources"
    -- Unrelated helpers in a hierarchy are excluded as well as geometry.
    local cameraChild=freeCamera name:"U73_UnmanagedCamera" pos:(s.pos+[0,0,100]);cameraChild.parent=s
    CyrusContainerRefreshAll()
    P07Assert (c.movementUnits.count==0) "Unmanaged camera child was admitted to source movement"
    cameraChild.parent=undefined;delete cameraChild;CyrusContainerRefreshAll()
    -- Instancing would give one delegate ambiguous physical ownership.
    local other=instance c,rejected=false
    try(c.movePalette [10,0,0])catch(rejected=true)
    P07Assert rejected "Instanced helper moved the wrong source palette"
    delete other;CyrusContainerRefreshAll()
    local log=cyrusDiagnosticSnapshot 0 100
    P07Assert (findString log "container.move.started"!=undefined and findString log "container.move.completed"!=undefined and findString log "container.move.failed"!=undefined and findString log "container.move.cancelled"!=undefined) "Container action summaries missing from diagnostics"
    cyrusDiagnosticStop();CSPWriteText (MCPFixtureDir+"group-move-diagnostics.json") log
    P07Record "group_movement" #(c.movementStats(),true,true,true)
    true
)
