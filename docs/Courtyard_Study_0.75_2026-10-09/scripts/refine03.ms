CYRebind()
local l=CYL[5]
for key in #(#patternPaths,#patternLines,#patternWidths,#patternGroups,#strokeSides,#strokeModes,#strokeMin,#strokeMax,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceNodes,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsets,#edgeAlong,#edgeAcross) do setProperty l key #()
for path in CYPaths do (
 l.addStroke path side:1;local k=l.patternLines.count;l.patternWidths[k]=25;l.strokeModes[k]=2;l.setStrokeSelection k 2 #(getNodeByName "clover_pack_004")
 l.addStroke path side:1;k=l.patternLines.count;l.patternWidths[k]=45;l.strokeModes[k]=2;l.setStrokeSelection k 2 #(getNodeByName "MT_PM_V41_Lamium_maculatum_01_04")
)
CYCam.pos=[30,-1060,340];CYCam.target.pos=[-40,1180,130];CYCam.fov=69
-- A shrub perimeter replaces the omitted buildings without obscuring the garden.
local myrtle=getNodeByName "crp_MT_PM_V33_Myrtle_01_003",elder=getNodeByName "crp_MT_PM_Sambucus_nigra_02_01"
seed 75133
for i=0 to 28 do (
 local n=instance (if mod i 4==0 then elder else myrtle);n.name="PERIMETER | shelter planting";n.renderable=true
 local s=random 1.2 2.0;n.scale=[s,s,s*1.1];n.rotation=eulerangles 0 0 (random 0 360);n.pos=[-1640+i*118,2910+random -35 35,0]
 (RGLayer "03 Canopy and boulders").addNode n
)
-- Broader, lower crowns around the existing branching structure.
for tree in #(#([-830,1220,0],620),#([-400,2330,0],690),#([1430,1950,0],650),#([-1420,1850,0],560),#([380,2660,0],650)) do (
 for j=0 to 7 do (
  local n=instance myrtle;n.name="TREE | secondary foliage";n.renderable=true
  local s=random 1.15 1.6;n.scale=[s,s,s*.9];n.rotation=eulerangles (random -12 12) (random -12 12) (j*45)
  n.pos=tree[1]+[125*cos(j*45),110*sin(j*45),tree[2]*.68+random -30 35]
  (RGLayer "03 Canopy and boulders").addNode n
 )
)
CYMeasure "corrected-bands-update"
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
local t=timestamp();renderWidth=1100;renderHeight=733;renderers.current.progressive_passLimit=4
local frame=render camera:CYCam vfb:false outputfile:(CYOut+"Draft_03.png")
close frame;CYLog "render-draft03" #(#("elapsed_ms",timestamp()-t),#("error",CyrusPFLastError))
