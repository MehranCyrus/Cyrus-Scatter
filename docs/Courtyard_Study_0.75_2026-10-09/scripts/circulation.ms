CYRebind()
local delta=[-360,50,0],poles=for n in geometry where matchPattern n.name pattern:"Tree | branching trunk*" and n.pos.z<1 and distance [n.pos.x,n.pos.y,0] [260,650,0]<155 collect n
if poles.count!=6 do throw "Tent pole selection is ambiguous"
for n in poles do (n.name="PLAY | tent pole";n.pos+=delta)
for n in geometry where matchPattern n.name pattern:"PLAY | canvas tent panel*" do n.pos+=delta
local mask=getNodeByName "EXCLUDE | tent footprint";mask.pos+=delta
local m=CYPathMeshes[1].material
m.baseTexmap=Noise size:.8 color1:(color 38 33 26) color2:(color 80 68 52);m.baseTexmapOn=true;m.baseBumpMapAmount=1.1
for n in geometry where matchPattern n.name pattern:"PLAY | sandstone boulder*" do (
 n.material.baseColor=color 45 39 31;n.material.baseTexmap=Noise size:18 color1:(color 33 30 26) color2:(color 81 73 60);n.material.baseTexmapOn=true
 n.material.baseBumpTexmap=Noise size:5 color1:black color2:white;n.material.baseBumpTexmapOn=true;n.material.baseBumpMapAmount=3
)
CYStroke CYPaint[3] (for i=0 to 20 collect [700+i*18,1740+60*sin(i*9),700]) 145 .35
CYL[7].amount=5000
CYBench "final-circulation-update" (fn action=(CYR.refreshAll()))
CYBench "final-circulation-warm" (fn action=(CYR.evaluateGroups()))
CYLog "tent-correction" #(#("poles_moved",poles.count),#("delta",#(delta.x,delta.y,delta.z)),#("new_center",#(-100,700,0)),#("curved_paint_stats",cyrusBrushStats CYPaint[3].paintDocument))
renderWidth=1400;renderHeight=875;renderers.current.progressive_passLimit=8
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
