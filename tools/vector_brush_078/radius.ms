(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global RChecks=#(),RAssert
fn RAssert value message = (
 if not value do throw ("Radius qualification: "+message)
 append RChecks message
 local f=createFile (MCPFixtureDir+"radius-checks.txt")
 for line in RChecks do format "PASS %\n" line to:f
 close f;true
)
CyrusStopBrush();resetMaxFile #noPrompt
viewport.setLayout #layout_1;viewport.setType #view_top
local receiver=plane name:"Radius_receiver" width:500 length:500 widthsegs:1 lengthsegs:1
convertToMesh receiver
select receiver;max zoomext sel all
local document=cyrusBrushCreate receiver,oldMin=painterInterface.minSize,oldMax=painterInterface.maxSize
-- The native Painter sample uses the same halving as its cursor-ring drawing.
cyrusBrushSettings document 100 false;cyrusBrushBegin document
local sample=cyrusPrivatePainterSample document [0,0,0]
RAssert (sample[1]==200 and sample[2]==200 and sample[3]==100) "100-unit UI radius produces a 100-unit Painter radius on start"
cyrusBrushSettings document 25 false
sample=cyrusPrivatePainterSample document [0,0,0]
RAssert (sample[1]==50 and sample[2]==50 and sample[3]==25) "Changing radius during the session updates the Painter footprint"
cyrusBrushStop()
RAssert (painterInterface.minSize==oldMin and painterInterface.maxSize==oldMax) "Stop restores the previous Max Painter settings"
local metrics=createFile (MCPFixtureDir+"radius-metrics.txt")
-- World-sized footprints under identity, uniform and nonuniform object scale.
for objectScale in #([1,1,1],[2,2,2],[2,3,1]) do (
 receiver.scale=objectScale;cyrusBrushBind document;cyrusBrushFill document 0
 cyrusBrushSettings document 100 false;cyrusBrushDab document [0,0,1000] [0,0,-1] true
 local rows=#(),index=0
 for direction in #([1,0,0],[-1,0,0],[0,1,0],[0,-1,0]) do for distance in #(99.0,101.0) do (
  local point=direction*distance,hit=intersectRayEx receiver (ray (point+[0,0,1000]) [0,0,-1])
  if hit==undefined do throw "Radius fixture ray missed receiver"
  index+=1;append rows #((transMatrix point),1,(index as integer64),hit[2],hit[3])
 )
 local accepted=cyrusBrushRegionFilter rows #(document) #(1.0) #(receiver) #(2) "radius-test"
 RAssert (accepted.count==4 and (for row in accepted where mod row[3] 2==1 collect row).count==4) ("Vector accepts 99 and rejects 101 world units, scale "+objectScale as string)
 cyrusBrushBegin document
 sample=cyrusPrivatePainterSample document [0,0,0]
 RAssert (sample[3]==100) ("Painter world radius stays 100 under scale "+objectScale as string)
 cyrusBrushStop()
 format "Scale %: vector inside 99/outside 101; Painter radius %; size %\n" objectScale sample[3] sample[2] to:metrics
)
local oldDisplay=units.displayType,oldMetric=units.metricType
units.displayType=#metric;units.metricType=#millimeters
local millimeters=units.decodeValue "100mm"
cyrusBrushSettings document millimeters false;cyrusBrushBegin document
sample=cyrusPrivatePainterSample document [0,0,0]
RAssert (abs(sample[3]-millimeters)<1e-5) "100 mm respects system-unit conversion in Painter"
format "100 mm decoded system units %; Painter radius %\n" millimeters sample[3] to:metrics
cyrusBrushStop();units.displayType=oldDisplay;units.metricType=oldMetric
close metrics
)
