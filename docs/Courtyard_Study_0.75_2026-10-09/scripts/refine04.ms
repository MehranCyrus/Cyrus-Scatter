CYRebind()
-- Bring foreground flower drifts into the camera while retaining the central path.
for spec in #(#(1,[-770,-180,0],610,590),#(2,[850,-130,0],540,580)) do (
 local i=spec[1],s=CYBeds[i],pts=for a=0 to 350 by 10 collect spec[2]+[spec[3]*cos(a)*(1+.055*sin(3*a)),spec[4]*sin(a)*(1+.045*cos(5*a)),0]
 for k=1 to pts.count do setKnotPoint s 1 k (pts[k]*(inverse s.objectTransform))
 updateShape s
 local soil=getNodeByName ("Soil | bed "+i as string),mat=soil.material;delete soil
 RGFill ("Soil | bed "+i as string) pts mat z:.3
)
CYL[1].amount=3500;CYL[2].amount=18000;CYL[2].sourceScales=#(.65,.6);CYL[2].procSelfMultiplier=.65
CYL[3].amount=30000;CYL[3].sourceScales=#(.7,.6);CYL[3].procSelfMultiplier=.6
CYL[4].amount=20000;CYL[4].sourceScales=#(2.1,2.0,2.4,2.3)
CYL[6].plantsPerM2=75;CYL[6].sourceScales=#(1.35,1.0,1.3)
CYStroke CYPaint[1] (for i=0 to 27 collect [-1050+i*23,-370+95*sin(i*11),500]) 185 .4
CYStroke CYPaint[2] (for i=0 to 27 collect [620+i*17,-240+140*sin(i*9),500]) 180 .4
-- Fuller, less top-heavy crowns using the available shrub geometry.
for n in geometry where matchPattern n.name pattern:"TREE | secondary foliage*" do (n.scale=n.scale*1.5;n.pos.z-=75)
local sky=environmentMap
CYCam.pos=[30,-990,285];CYCam.target.pos=[-40,1220,185];CYCam.fov=72
CYMeasure "refine04-update"
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
local t=timestamp();renderWidth=1100;renderHeight=733;renderers.current.progressive_passLimit=5
local frame=render camera:CYCam vfb:false outputfile:(CYOut+"Draft_04.png")
close frame;CYLog "render-draft04" #(#("elapsed_ms",timestamp()-t),#("error",CyrusPFLastError))
