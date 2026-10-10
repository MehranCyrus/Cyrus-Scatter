-- Refine composition in the owned design scene; preserve previous drafts.
for n in CYReceivers do (n.material.baseTexmapOn=false;n.material.baseColor=color 32 62 14)
for n in CYPathMeshes do (n.material.baseTexmapOn=false;n.material.baseColor=color 125 98 62)
local ground=plane name:"LANDSCAPE | surrounding meadow" width:30000 length:30000 widthsegs:1 lengthsegs:1 pos:[0,0,-3] material:(RGMat "Surround | muted green" (color 48 68 30))
(RGLayer "01 Ground and path").addNode ground
CYL[6].sourceWeights=#(1.0,.15,0.0);CYL[6].sourceScales=#(2.1,1.5,1.3);CYL[6].procSelfEnabled=false
CYR.procSetPair 2 CYL[1] CYL[3] true .35 0 true
CYR.procSetPair 2 CYL[2] CYL[3] true .35 0 true
CYL[10].distributionMode=3;CYL[10].densityMap=Noise name:"MASK | accent islands" size:180 color1:black color2:white
CYCam.pos=[-950,-1050,470];CYCam.target.pos=[170,1070,100];CYCam.fov=62
CYMeasure "refine02-update"
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
local t=timestamp();renderWidth=1000;renderHeight=667;renderers.current.progressive_passLimit=3
local frame=render camera:CYCam vfb:false outputfile:(CYOut+"Draft_02.png")
close frame
CYLog "render-draft02" #(#("elapsed_ms",timestamp()-t),#("error",CyrusPFLastError))
