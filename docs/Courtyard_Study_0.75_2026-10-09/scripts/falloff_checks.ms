-- Additional independent boundary falloff witnesses; owned disposable scene only.
if findString MCPFixtureDir "courtyard-study075"==undefined do throw "Owned study required"
P07Case="Courtyard falloff witnesses";P07New count:8000
local r=P07Root,l=P07Layer,s=rectangle width:600 length:600
l.areaNodes=#(s);l.areaModes=#(1)
local base=(r.evaluateGroups())[1],baseFP=P07Fingerprint r
l.setFallConfig s #(true,100.0,false,100.0,#(0.0,1.0),false,100.0,#(0.0,1.0))
local trimmed=(r.evaluateGroups())[1],bad=0
for row in trimmed do if abs row[1].row4.x>200.001 or abs row[1].row4.y>200.001 do bad+=1
P07Assert (trimmed.count>0 and trimmed.count<base.count and bad==0) "Delete band did not remove 100 cm inside margin"
l.setFallConfig s #(false,0.0,true,100.0,#(.5,.5),false,100.0,#(0.0,1.0))
local scaled=(r.evaluateGroups())[1],maxScaleError=0.0,maxPositionError=0.0
P07Assert (scaled.count==base.count) "Scale falloff changed count"
for i=1 to base.count do (
 maxScaleError=amax maxScaleError (abs((length scaled[i][1].row1)-.5*(length base[i][1].row1)))
 maxPositionError=amax maxPositionError (distance scaled[i][1].row4 base[i][1].row4)
)
P07Assert (maxScaleError<1e-5 and maxPositionError<1e-5) "Constant scale falloff did not preserve pivots and halve scale"
l.setFallConfig s #(false,0.0,false,100.0,#(0.0,1.0),true,100.0,#(0.0,0.0))
P07Assert ((r.evaluateGroups())[1].count==0) "Zero density falloff did not remove output"
l.setFallConfig s #(false,0.0,false,100.0,#(0.0,1.0),true,100.0,#(1.0,1.0))
P07Assert ((P07Fingerprint r) as string==baseFP as string) "Full density falloff did not restore exact baseline"
CYLog "falloff-witnesses" #(#("passed",true),#("base",base.count),#("trimmed",trimmed.count),#("trim_violations",bad),#("max_scale_error",maxScaleError),#("max_position_error",maxPositionError),#("density_zero",true),#("density_one_exact",true))
loadMaxFile (CYOut+"Courtyard_075.max") quiet:true useFileUnits:true
CYRebind()
