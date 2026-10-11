-- Point placeholders only: no model geometry, paint areas or brush sessions.
(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global SPChecks=#(),SPAssert,SPPump,SPRowsMatch,SPCounts
local originalInteractionHeld=CyrusInteractionHeld
fn CyrusInteractionHeld = false
fn SPPump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn SPAssert value message = (
 if not value do throw ("Spline points: "+message)
 append SPChecks message
 local f=createFile (MCPFixtureDir+"spline-points-checks.txt")
 for line in SPChecks do format "PASS %\n" line to:f
 close f;true
)
fn SPCounts rows = (for slot=1 to 3 collect (for row in rows where row[2]==slot collect row).count)
fn SPRowsMatch rows outsideWidth = (
 local counts=SPCounts rows,good=rows.count>0 and amin counts>0
 for row in rows while good do (
  local p=row[1].row4,x=abs p.x,y=abs p.y,inside=x<=80 and y<=80
  local inward=80-amax x y,outward=sqrt ((amax 0 (x-80))^2+(amax 0 (y-80))^2)
  case row[2] of (
   1: (good=inside and inward>= -0.001 and inward<=20.001)
   2: (good=inside and inward>=19.999 and inward<=40.001)
   3: (good=not inside and outward<=outsideWidth+.001)
   default: (good=false)
  )
 )
 good
)
try (
CyrusStopBrush();resetMaxFile #noPrompt
viewport.setLayout #layout_1;viewport.setType #view_top
local receiver=plane name:"Points_receiver" width:320 length:320 widthsegs:1 lengthsegs:1
local path=rectangle name:"Points_band_guide" width:160 length:160 cornerRadius:0
local node=AminScatterObject name:"Spline_points_only",root=node.baseObject
root.updateMode=1;root.autoRender=false;root.newLayer()
local leaf=root.selectedLayer();leaf.amount=10000;leaf.procPopulation=1
root.setLayerSurfaces leaf #(receiver)
select node;max modify mode;modPanel.setCurrentObject root
if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
local models=root.modelsUI;models.open=true;root.mainUI.bindSection models
models.advancedToggle.checked=true;models.layout()
for i=1 to 3 do models.sourceUI_addPoint.pressed()
SPAssert (leaf.sources.count==3 and (for i=1 to 3 where leaf.isPointSource i and leaf.isEmptySource i collect i).count==3) "Actual Add Point button creates three placeholders without scene models"
SPAssert ((for n in leaf.sources where isValidNode n collect n).count==0 and leaf.validSources() as string==#(-1,-2,-3) as string) "All sources use placeholder identities; no geometry source exists"
local colors=#((color 255 160 30),(color 60 210 100),(color 190 90 255))
for i=1 to 3 do (
 leaf.assignGroup #{i} colors[i];leaf.setSourceIDColor #{i} colors[i]
 leaf.setSourceLabel i (#("Inside edge points","Inner points","Outside points")[i])
)
local layout=root.layoutUI;layout.open=true;root.mainUI.bindSection layout
layout.diversityUI_diversityRadio.changed 3
layout.diversityUI_pickPath.picked path
for i=1 to 3 do (
 if i<3 then layout.diversityUI_addInside.pressed() else layout.diversityUI_addOutside.pressed()
 layout.diversityUI_strokeWidth.changed 20.0
 local key=leaf.colorKey colors[i],choice=findItem layout.diversityUI_choiceValues key
 SPAssert (choice>0) ("Point group available for band "+i as string)
 layout.diversityUI_strokeChoices.selection=#{choice};layout.diversityUI_strokeChoices.selectionEnd()
)
SPAssert (leaf.diversityMode==3 and leaf.patternLines.count==3 and leaf.strokeSides as string==#(2,2,1) as string) "Actual Layout handlers create two consecutive inside bands and one outside band"
root.setGroupDisplay 4
-- Drain receiver/guide creation notifications before measuring unchanged work.
SPPump 500
local started=timeStamp();root.refreshAll();local coldMS=timeStamp()-started
local rows=root.groupSnapshotRows[1],counts=SPCounts rows
SPAssert (leaf.previewError=="" and SPRowsMatch rows 20) "Every accepted point is inside its assigned geometric band and all three groups are present"
SPAssert (leaf.cachedPointCount==rows.count) "Centers preview contains exactly one visible point per accepted placeholder"
SPAssert (root.procPublishedFinalKeep[1] as string==#(false,false,false) as string and (root.groupPlacements leaf (leaf.validSources()) false).count==0) "Point placeholders produce no final model geometry"
CyrusPointSync();redrawViews();SPPump 150
local owner=CyrusPointOwner node
SPAssert (isValidNode owner and (cyrusRetainedStats owner)[1]==rows.count and (cyrusRetainedMeshStats owner)[1]==0) "Retained display contains points and zero mesh faces"
local state=cyrusRetainedStats owner,epoch=root.procEpoch,builds=leaf.receiverCacheStats(),fingerprint=cyrusEditFingerprint rows "points"
local keyLog=createFile (MCPFixtureDir+"spline-points-key-before.txt");format "%" root.groupSnapshotKey to:keyLog;close keyLog
keyLog=createFile (MCPFixtureDir+"spline-points-key-current.txt");format "%" (root.procInputKey()) to:keyLog;close keyLog
for i=1 to 10 do (root.evaluateGroups();CyrusPointSync();redrawViews())
local warm=cyrusRetainedStats owner
local cacheLog=createFile (MCPFixtureDir+"spline-points-cache.txt")
format "epoch: % -> %\nreceiver: % -> %\nretained: % -> %\n" epoch root.procEpoch builds (leaf.receiverCacheStats()) state warm to:cacheLog;close cacheLog
SPAssert (root.procEpoch==epoch and (leaf.receiverCacheStats())[1]==builds[1] and warm[3]==state[3] and warm[6]==state[6]) "Ten unchanged reads/redraws reuse placements and retained point uploads"
-- Explicitly record the unsupported direct-source route instead of passing it silently.
layout=root.layoutUI;root.mainUI.bindSection layout
layout.diversityUI_strokesList.selection=3;layout.diversityUI_showStroke()
layout.diversityUI_strokeMode.changed 2
local directChoices=layout.diversityUI_strokeChoices.items.count
local observations=createFile (MCPFixtureDir+"spline-points-observations.txt")
format "Source objects choice count with three Point sources: %\n" directChoices to:observations
format "Cold explicit Update milliseconds: %\nCounts by band: %\n" coldMS counts to:observations
close observations
layout.diversityUI_strokeMode.changed 1
root.refreshAll()
SPAssert ((cyrusEditFingerprint root.groupSnapshotRows[1] "points")==fingerprint) "Returning to color groups restores exactly the same point assignments"
epoch=root.procEpoch
layout.diversityUI_strokeWidth.changed 30.0;SPPump 250
SPAssert (root.procEpoch==epoch and (cyrusEditFingerprint root.groupSnapshotRows[1] "points")==fingerprint) "Manual band-width change preserves the completed points until Update"
root.refreshAll();rows=root.groupSnapshotRows[1]
SPAssert (SPRowsMatch rows 30 and (SPCounts rows)[3]>counts[3]) "Explicit Update expands only the outside band's accepted domain"
root.updateMode=2;root.markInputDirty();SPPump 250
layout.diversityUI_strokeWidth.changed 20.0;SPPump 2200
SPAssert (leaf.previewError=="" and (cyrusEditFingerprint root.groupSnapshotRows[1] "points")==fingerprint) "Live width change returns automatically to the original point layout"
root.updateMode=1
-- The source/receiver state and absence of paint are saved with the example.
SPAssert ((root.logicalLayers()).count==1 and root.layerObjects.count==1 and not leaf.paintEnabled and leaf.paintDocument==undefined) "Scene uses one layer with no Paint Area or brush data"
select receiver;max zoomext sel all;receiver.isHidden=true;select node
saveMaxFile (MCPFixtureDir+"spline-points-only.max") quiet:true
loadMaxFile (MCPFixtureDir+"spline-points-only.max") quiet:true
node=getNodeByName "Spline_points_only";root=node.baseObject;leaf=root.layerObjects[1]
root.refreshAll();CyrusPointSync();redrawViews();SPPump 250
SPAssert ((cyrusEditFingerprint root.groupSnapshotRows[1] "points")==fingerprint and (for i=1 to 3 where leaf.isPointSource i collect i).count==3) "Point types, band choices and exact placements survive save/reopen"
local image=gw.getViewportDib();image.filename=MCPFixtureDir+"spline-points-only.png";save image;close image
SPAssert true "Point-only scene and viewport artifact saved"
)catch(CyrusInteractionHeld=originalInteractionHeld;throw())
CyrusInteractionHeld=originalInteractionHeld
)
