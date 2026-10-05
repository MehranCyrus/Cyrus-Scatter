if findString MCPFixtureDir "/procedural07-ui-"==undefined do throw "Private container fixture required"
P07Case="source containers: deletion, multiple pools and bounded refill"
P07New count:300
local r=P07Root,a=P07Layer,source=P07Source
source.pos=[1000,0,0]
local near=rectangle name:"SC Near" width:300 length:200 pos:[1000,0,0]
local far=rectangle name:"SC Far" width:200 length:200 pos:[2000,0,0]
local outside=box name:"SC Far Asset" width:4 length:4 height:4 pos:[2000,0,0]
a.containerMode=4;a.containerNodes=#(near,far)
r.evaluateGroups()
P07Assert (a.sources.count==2 and a.containerActive as string=="#(true, true)") "Multiple rectangles failed"
local rows=SCText r.groupSnapshotRows,ids=a.procSourceSlots as string
undo "Delete fixture container" on delete far
r.evaluateGroups()
P07Assert (a.sources.count==2 and a.containerActive as string=="#(true, false)") "Deleted container lost registration or remained active"
max undo
P07Assert (SCText (r.evaluateGroups())==rows and a.procSourceSlots as string==ids) "Container Undo did not restore rows/identity"
undo "Delete fixture asset" on delete outside
r.evaluateGroups();P07Assert (a.sources.count==2 and a.sourceWeights.count==2) "Source deletion removed stored settings rows"
max undo
P07Assert (SCText (r.evaluateGroups())==rows and a.procSourceSlots as string==ids) "Asset Undo did not restore rows/identity"
a.containerMode=1;r.evaluateGroups();a.containerMode=4
P07Assert (SCText (r.evaluateGroups())==rows) "Switching to manual and back lost membership"

-- All parked: accepted-target must terminate with a reported shortfall.
a.procPopulation=2;a.procAttemptFactor=3;a.procRounds=4
source.pos=[1500,0,0];outside.pos=[2500,0,0]
r.evaluateGroups()
P07Assert (r.groupSnapshotRows[1].count==0 and a.procLastStats[11]==300 and a.procLastRounds[1]<=4) "All-parked accepted target did not terminate correctly"
P07Assert (a.procLastStats[10]<=900) "Parked refill exceeded attempts"
source.pos=[1000,0,0];r.evaluateGroups()
P07Assert (r.groupSnapshotRows[1].count==300) "Active candidates did not refill target within limit"

-- Overlap is a union, not duplicate registration. Rounded/modified shapes fail.
local overlap=copy near
a.containerNodes=#(near,overlap);r.evaluateGroups()
P07Assert (a.sources.count==2) "Overlapping rectangles duplicated sources"
local epoch=r.procEpoch,completed=SCText r.groupSnapshotRows,rejected=false
near.cornerRadius=5
try(r.evaluateGroups())catch(rejected=true)
P07Assert (rejected and r.procEpoch==epoch and SCText r.groupSnapshotRows==completed) "Rounded rectangle failed to preserve publication"
near.cornerRadius=0

-- A mask beyond twenty entries must participate in keys without truncation.
P07New count:200
r=P07Root;a=P07Layer;source=P07Source;source.pos=[1000,0,0]
near=rectangle width:500 length:200 pos:[1000,0,0];a.containerNodes=#(near);a.containerMode=4
local nodes=for i=1 to 24 collect box name:("SC Many "+i as string) width:2 length:2 height:2 pos:[900+i*6,0,0]
r.evaluateGroups();local before=a.containerMembershipKey,builds=a.containerMembershipBuilds
nodes[24].pos=[1600,0,0];r.evaluateGroups()
P07Assert (a.containerMembershipKey!=before and a.containerMembershipBuilds==builds+1) "Late source mask was omitted from dependency key"
builds=a.containerMembershipBuilds
for i=1 to 30 do r.procInputKey()
P07Assert (a.containerMembershipBuilds==builds) "Read-only keys recomputed unchanged membership"
CSPWriteText (MCPFixtureDir+"source-container-edge-cases.json") (CSPObject #(#("passed",true),#("deletion_undo",true),#("source_undo",true),#("multiple_overlap",true),#("bounded_refill",true),#("shape_failure_atomic",true),#("late_mask_bit",true),#("membership_cache",true)))
