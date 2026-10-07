global U73EditPersistence
fn U73EditPersistence = (
    P07Checks=#();P07Case="stable Edit and radius persistence";P07New count:140
    local r=P07Root,a=P07Layer,node=P07Node,edit=CyrusScatterEdit()
    addModifier node edit;r.evaluateGroups()
    cyrusEditCommand edit 1 (matrix3 1);cyrusEditCommand edit 4 (transMatrix [0,0,3]);cyrusEditCommand edit 3 (matrix3 1)
    r.evaluateGroups();a.procSelectedRadius 1 7.0;r.evaluateGroups()
    a.amount=0;r.refreshAll()
    local fingerprint=P07Fingerprint r,ids=a.procRadiusIDs as array,radii=a.procRadiusValues as array,statistics=a.procStatistics()
    P07Assert (ids.count>0 and statistics[1][3]>0) "Persistence fixture has no protected edits or radius overrides"
    local scene=MCPFixtureDir+"Unified073-Edit-Radius.max"
    P07Assert (saveMaxFile scene quiet:true) "Edit fixture could not save"
    P07Assert (loadMaxFile scene quiet:true) "Edit fixture could not reopen"
    node=getNodeByName "P07_Controller";r=node.baseObject;a=r.layerObjects[1]
    P07Assert ((P07Fingerprint r) as string==fingerprint as string) "Stable Edit positions/clone identities changed on reopen"
    P07Assert ((a.procRadiusIDs as array) as string==ids as string and (a.procRadiusValues as array) as string==radii as string) "Radius overrides changed on reopen"
    P07Assert ((a.procStatistics())[1][3]==statistics[1][3]) "Protected zero-quota inputs disappeared on reopen"
    P07Record "edit_radius_persistence" #(ids.count,statistics[1][3],scene)
    true
)
