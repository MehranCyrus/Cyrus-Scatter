(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
-- Continue acceptance.ms's saved fixture, restoring paint for extended checks.
cyrusBrushBind VD;cyrusBrushFill VD 1
local cfg=cyrusBrushFalloff VD;cfg[1]=20;cfg[2]=10;cfg[3]=true;cfg[4]=true;cfg[5]=0.5;cfg[6]=1;cyrusBrushSetFalloff VD cfg
VRoot.refreshAll()
local parent=VLayer,originalCount=VRoot.groupSnapshotRows[1].count
local copyLayer=VRoot.copyLogicalLayer parent
VAssert ((copyLayer.validSurfaces()).count==(parent.validSurfaces()).count) "Copy preserves independent receiving surfaces"
VAssert (copyLayer.paintAreas.count==parent.paintAreas.count and copyLayer.paintAreas[1].paintDocument!=parent.paintAreas[1].paintDocument) "Copy owns independent native vector documents"
cyrusBrushFill copyLayer.paintAreas[1].paintDocument 0
VAssert ((cyrusBrushStats VD)[2]>0 and (cyrusBrushStats copyLayer.paintAreas[1].paintDocument)[2]==0) "Editing copied region leaves original unchanged"
VRoot.removeLogicalLayer copyLayer;VRoot.selectLayer 1
-- Explicit Exclude constrains outward feather too.
cyrusBrushFill VD 0;cyrusBrushSettings VD 50 false;cyrusBrushDab VD [0,0,200] [0,0,-1] true
local exclusion=rectangle name:"V_Exclude" width:40 length:200 pos:[0,0,0]
VLayer.areaNodes=#(exclusion);VLayer.areaModes=#(2)
VRoot.refreshAll();local rows=VRoot.groupSnapshotRows[1]
VAssert (rows.count>0 and VLayer.previewError=="") "Vector feather and Exclude evaluate together"
for row in rows do VAssert (abs row[1].row4.x>=19.99) "Exclude wins inside feathered region"
VLayer.areaNodes=#();VLayer.areaModes=#();VRoot.refreshAll()
-- Target topology changes preserve the preceding completed publication.
local last=cyrusEditFingerprint VRoot.groupSnapshotRows[1] "invalid"
VPlane=getNodeByName "V_Plane";VPlane.widthsegs=6;VRoot.refreshAll()
VAssert (VLayer.previewError!="" and (cyrusEditFingerprint VRoot.groupSnapshotRows[1] "invalid")==last) "Changed topology retains complete output and reports error"
VPlane.widthsegs=4;VRoot.refreshAll()
VAssert (VLayer.previewError=="" and (cyrusEditFingerprint VRoot.groupSnapshotRows[1] "invalid")==last) "Restored topology restores exact vector eligibility"
-- Curve editor uses one selected native document, including popup view.
local graph=CyrusOpenFalloffGraph VArea undefined true
local c=graph.graph.curves[1];c.numPoints=3
for i=1 to 3 do (
 local p=c.points[i];p.value=[(i-1)*0.5,if i==2 then 10 else (i-1)*50];p.bezier=false;p.corner=true;p.lock_x=(i==1 or i==3);c.points[i]=p
)
graph.storeCurve();destroyDialog graph
local after=cyrusBrushFalloff VD
VAssert (after[7].count==257 and abs(after[7][129]-0.1)<0.001 and after[8] as string==cfg[8] as string) "Density curve editor updates density independently"
graph=CyrusOpenFalloffGraph VArea undefined false;c=graph.graph.curves[1]
local p=c.points[1];p.value=[0,30];c.points[1]=p;graph.storeCurve();destroyDialog graph
after=cyrusBrushFalloff VD
VAssert (abs(after[8][1]-.3)<.001 and abs(after[7][129]-.1)<.001) "Scale curve editor updates scale independently"
CyrusOpenLayerEditor VRoot VLayer
CyrusLayerEditor.showTopic 3 rebind:true
local pages=for r in CyrusLayerEditor.activeEditors() where isProperty r #brushUI_insideSpin collect r
VAssert (pages.count==1 and pages[1].brushUI_obj==VArea) "Popup binds the selected Paint Area"
local view=pages[1];view.brushUI_insideSpin.value=8;view.brushUI_outsideSpin.value=12;view.brushUI_saveFalloff()
after=cyrusBrushFalloff VD
VAssert (after[1]==8 and after[2]==12) "Popup feather controls update native settings"
CyrusCloseLayerEditor()
-- Begin/stop and SDK radius handoff; actual pointer/tablet gestures remain a gate.
cyrusBrushSettings VD 23 false;cyrusBrushBegin VD
VAssert (abs(painterInterface.maxSize-46)<.001 and abs(painterInterface.minSize-46)<.001) "Painter diameter is twice the authored UI radius"
cyrusBrushRefreshMask VD
local beforeStats=cyrusBrushStats VD
sliderTime=10f;cyrusBrushRefreshMask VD
local endStats=cyrusBrushStats VD
VAssert (endStats[8]==beforeStats[8] and endStats[9]==beforeStats[9]) "Unrelated timeline movement retains static target caches"
cyrusBrushStop();sliderTime=0
-- Points and borders leave placements intact.
VRoot.refreshAll();last=cyrusEditFingerprint VRoot.groupSnapshotRows[1] "display"
for mode in #(0,1,2) do (cyrusBrushDisplay VD mode (color 120 210 120);cyrusBrushRefreshMask VD)
VRoot.refreshAll()
VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "display")==last) "Feedback mode never changes accepted plants"
-- A nonuniform transformed receiver uses projected world radius and survives reopen.
local transformed=plane name:"V_Transformed" width:200 length:200 widthsegs:2 lengthsegs:2 pos:[0,500,0]
transformed.scale=[2,3,1]
local td=cyrusBrushCreate transformed;cyrusBrushSettings td 30 false;cyrusBrushDab td [0,0,200] [0,0,-1] true
local regionRows=#(#((transMatrix [48,500,0]),1,1L,1,[0.38,0.5,0.12]))
-- Native core separately checks metric ellipse extents; this verifies host admission.
VAssert ((cyrusBrushStats td)[2]==1) "Nonuniform receiver accepts a vector region"
saveMaxFile (MCPFixtureDir+"vector078-extended.max") quiet:true
VAssert true "Extended fixture saved"

-- A brush larger than the entire receiver still draws its clipped boundary.
cyrusBrushBind VD;cyrusBrushFill VD 0;cyrusBrushSettings VD 1000 false
cyrusBrushBegin VD;cyrusBrushDab VD [0,0,200] [0,0,-1] true;cyrusBrushDisplay VD 2 (color 120 210 120);cyrusBrushRefreshMask VD
VAssert ((cyrusBrushStats VD)[19]>0) "Oversized brush retains receiver-edge border feedback"
cyrusBrushStop()
-- The native curve and its editable graph metadata belong to one Undo action.
local beforeCfg=cyrusBrushFalloff VD,beforeGraph=VArea.fallDensityGraph
local editCfg=VArea.getFallConfig undefined;editCfg[8]=#(0.0,0.4,1.0)
undo "Vector curve atomic test" on (
 VArea.setFallConfig undefined editCfg
 VArea.setFallGraph undefined true "0,0,0,0,0,0,0,1,1,100,0,0,0,0,0,1"
)
max undo
VAssert ((cyrusBrushFalloff VD)[7] as string==beforeCfg[7] as string and VArea.fallDensityGraph==beforeGraph) "Curve Undo restores native samples and graph metadata together"
max redo
VAssert ((cyrusBrushFalloff VD)[7] as string==editCfg[8] as string) "Curve Redo restores native samples"
local sameCfg=cyrusBrushFalloff VD,revision=(cyrusBrushStats VD)[1]
cyrusBrushSetFalloff VD sameCfg
VAssert ((cyrusBrushStats VD)[1]==revision) "Unchanged feather settings do not invalidate caches or create edits"


)
