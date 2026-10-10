(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
CyrusStopBrush();resetMaxFile #noPrompt
viewport.setLayout #layout_1;viewport.setType #view_top
local receiver=plane width:500 length:500 widthsegs:1 lengthsegs:1
select receiver;max zoomext sel all
local document=cyrusBrushCreate receiver
cyrusBrushSettings document 100 false;cyrusBrushBegin document
local sample=cyrusPrivatePainterSample document [0,0,0]
local f=createFile (MCPFixtureDir+"radius-baseline.txt")
format "Authored radius: 100; Painter min/max size: %/%; Painter actual stored radius: %\n" sample[1] sample[2] sample[3] to:f
close f;cyrusBrushStop()
)
