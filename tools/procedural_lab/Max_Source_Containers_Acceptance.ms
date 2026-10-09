-- Run through runtime_driver in a disposable Max profile, matching script/DLL.
(
if findString MCPFixtureDir "/procedural07-ui-"==undefined do throw "Private container fixture required"
global P07New,P07Root,P07Layer,P07Source,P07Surface,P07Assert,P07Case,CSPWriteText,CSPObject
global SCResults=#()
global SCText,SCRecord,SCDrain
fn SCText value = (local s=stringStream "";with printAllElements on format "%" value to:s;s as string)
fn SCRecord name value = (append SCResults #(name,value);CSPWriteText (MCPFixtureDir+"source-containers.json") (CSPObject SCResults))
fn SCDrain = (windows.processPostedMessages();completeRedraw();windows.processPostedMessages())

P07Case="source containers: identity, transforms and settings"
P07New count:400
local r=P07Root,a=P07Layer,first=P07Source
first.pos=[1000,0,50]
local second=box name:"SC Shrub" width:4 length:4 height:6 pos:[1050,0,0]
local rect=CyrusSourceContainer name:"SC Layer Plants" width:300 length:200 pos:[1000,0,0]
a.containerNodes=#(rect);a.containerMode=4
r.refreshAll()
P07Assert (a.sources.count==2 and findItem a.sources second>0) "Inside asset was not automatically registered"
P07Assert (findItem a.sources P07Surface==0) "Receiver was registered as a source"
a.sourceWeights=#(1.0,0.5);a.sourceRadii=#(5.0,3.0);a.sourceScales=#(1.2,0.7);a.sourceZOffsets=#(1.0,2.0);a.sourceColors=#(red,green);a.sourceFollowScale=#(true,false)
r.refreshAll()
local baseline=SCText (r.evaluateGroups()),prepared=a.procPreparedBuilds,baseBuilds=a.paintBaseBuilds,ids=a.procSourceSlots as string
local settings=SCText #(a.sourceWeights,a.sourceRadii,a.sourceScales,a.sourceZOffsets,a.sourceColors,a.sourceFollowScale)
local survivors=SCText (for row in r.groupSnapshotRows[1] where row[2]==2 collect row)
first.pos=[1300,0,0]
local pendingEpoch=r.procEpoch
P07Assert ((a.placements (a.outputSources())).count==400 and r.procEpoch==pendingEpoch) "Manual published a staging move"
local parked=r.evaluateGroups()
P07Assert (SCText parked[1]==survivors) "Parking changed another source's full placement rows"
P07Assert (a.procPreparedBuilds==prepared and a.paintBaseBuilds==baseBuilds) "Staging move regenerated candidates"
P07Assert (a.sources.count==2 and a.procSourceSlots as string==ids) "Parking changed source registration/identity"
first.pos=[1000,0,250]
P07Assert (SCText (r.evaluateGroups())==baseline) "Reentry or height changed full placement rows"
P07Assert (SCText #(a.sourceWeights,a.sourceRadii,a.sourceScales,a.sourceZOffsets,a.sourceColors,a.sourceFollowScale)==settings) "Parking reset source settings"
SCRecord P07Case #("passed",400,parked[1].count,prepared,a.procPreparedBuilds)

P07Case="source containers: transformed rectangle and bounds"
local frame=(scaleMatrix [-2,0.5,1])*(rotateZMatrix 37)*(transMatrix [1000,100,50])
rect.transform=frame
first.pos=[150,0,300]*(rect.objectTransform)
r.evaluateGroups();P07Assert a.containerActive[1] "Inclusive boundary or projected height failed"
first.pos=[150.2,0,0]*rect.objectTransform
r.evaluateGroups();P07Assert (not a.containerActive[1]) "Outside pivot was admitted"
local holder=dummy pos:[50,20,0];rect.parent=holder
first.pos=rect.transform.row4
r.evaluateGroups();P07Assert a.containerActive[1] "Parented rectangle failed"
local old=r.procEpoch,oldRows=SCText r.groupSnapshotRows,saved=rect.transform,rejected=false
rect.scale=[0,1,1]
try(r.evaluateGroups())catch(rejected=true)
P07Assert (rejected and r.procEpoch==old and SCText r.groupSnapshotRows==oldRows) "Singular rectangle did not fail atomically"
rect.transform=saved
SCRecord P07Case true

P07Case="source containers: ownership and persistent registration"
rect.parent=undefined;rect.transform=transMatrix [1000,0,0];first.pos=[1000,0,0];second.pos=[1050,0,0]
r.containerGlobalNodes=#(rect)
local b=r.addPaintSet a label:"Inherited",c=r.addPaintSet a label:"Global"
b.paintEnabled=false;c.paintEnabled=false;b.containerMode=2;c.containerMode=3
r.evaluateGroups()
P07Assert (b.sources.count==2 and c.sources.count==2) "Layer/global inheritance failed"
b.sourceRadii=#(90.0,80.0)
r.evaluateGroups();P07Assert (a.sourceRadii[1]==5 and b.sourceRadii[1]==90) "Owner source settings leaked"
local solo=CyrusSourceContainer name:"SC Own Pool" width:20 length:20 pos:[1050,0,0]
c.containerMode=4;c.containerNodes=#(solo);r.evaluateGroups()
P07Assert (not c.containerActive[1] and c.containerActive[2]) "Set override did not own its membership"
local copied=r.copyLogicalLayer a;r.evaluateGroups()
P07Assert (copied.containerMode==4 and copied.containerNodes[1]==rect) "Copy lost container references"
local path=MCPFixtureDir+"SC-Persistence.max"
saveMaxFile path quiet:true
loadMaxFile path quiet:true
r=(getNodeByName "P07_Controller").baseObject;a=r.layerObjects[1];first=getNodeByName "P07_Asset"
r.evaluateGroups()
P07Assert (a.sources.count==2 and a.sourceRadii[1]==5 and a.procSourceSlots as string==ids) "Reopen lost source settings/identity"
P07Root=r;P07Layer=a;P07Source=first
SCRecord P07Case true

P07Case="source containers: edited rows park without losing edits"
P07New count:100
r=P07Root;a=P07Layer;first=P07Source;first.pos=[1000,0,0]
rect=CyrusSourceContainer width:300 length:200 pos:[1000,0,0]
a.containerNodes=#(rect);a.containerMode=4
local edit=CyrusScatterEdit();addModifier P07Node edit
r.evaluateGroups();cyrusEditSelect edit #(1);cyrusEditCommand edit 4 (transMatrix [5,7,0]);r.evaluateGroups()
local edited=SCText r.groupSnapshotRows,binding=a.procBindingKey
undo "Park test source" on first.pos=[1400,0,0]
r.evaluateGroups();P07Assert (r.groupSnapshotRows[1].count==0 and a.procBindingKey==binding) "Parked edit remained a collision blocker"
max undo
P07Assert (SCText (r.evaluateGroups())==edited) "Undo/reentry lost stored CS Edit"
max redo;r.evaluateGroups();P07Assert (r.groupSnapshotRows[1].count==0) "Redo failed to park source"
first.pos=[1000,0,0];r.evaluateGroups()
local next=box width:3 length:3 height:4 pos:[1050,0,0]
a.containerPending=#(next);rejected=false
try(r.evaluateGroups())catch(rejected=true)
P07Assert rejected "New enrollment silently rebound CS Edit"
SCRecord P07Case true

P07Case="source containers: navigation has no scene scan"
P07New count:20000
r=P07Root;a=P07Layer;first=P07Source;first.pos=[1000,0,0]
rect=CyrusSourceContainer width:300 length:200 pos:[1000,0,0];a.containerNodes=#(rect);a.containerMode=4
r.refreshAll();SCDrain();r.procInputKey()
local scans=a.containerScans,tests=a.containerTests,builds=a.paintBaseBuilds,epoch=r.procEpoch
for i=1 to 50 do r.procInputKey()
SCRecord "navigation counters" #(scans,a.containerScans,tests,a.containerTests,builds,a.paintBaseBuilds,epoch,r.procEpoch)
P07Assert (a.containerScans==scans and a.containerTests==tests and a.paintBaseBuilds==builds and r.procEpoch==epoch) "Read/navigation scanned scene or rebuilt data"
SCRecord P07Case #(true,scans,tests,builds)
SCRecord "complete" true
)
