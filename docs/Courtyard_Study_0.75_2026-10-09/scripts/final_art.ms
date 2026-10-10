CYRebind()
-- Final composition and material polish; Scatter placement settings are unchanged.
CYCam.pos=[70,-820,265];CYCam.target.pos=[0,1210,-30];CYCam.fov=70
for n in CYReceivers do n.material.baseColor=color 10 18 6
local m=CYPathMeshes[1].material
m.baseColor=color 119 100 73;m.baseRoughness=.9;m.baseBumpTexmap=Noise size:.45 color1:black color2:white;m.baseBumpTexmapOn=true;m.baseBumpMapAmount=.5
for n in geometry where matchPattern n.name pattern:"BOULDER*" do (
 if isProperty n.material #baseColor do (n.material.baseColor=color 63 57 46;n.material.baseBumpTexmap=Noise size:8 color1:black color2:white;n.material.baseBumpTexmapOn=true;n.material.baseBumpMapAmount=2)
)
seed 75134
for n in geometry where matchPattern n.name pattern:"PERIMETER | shelter planting*" do (
 local s=random 2.7 4.3;n.scale=[s,s,s*1.3]
)
viewport.setCamera CYCam
for spec in #(#("nav-box-10k",2,1),#("nav-sphere-10k",2,2),#("nav-mesh-10k",3,1)) do CYNavigate spec[1] spec[2] spec[3] 10000
CYR.setGroupDisplay 1;CYR.refreshDisplay();CYR.updateMode=1
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
