CYRebind()
local before=CYFP(),counts=for l in CYL collect l.generatedCount,epoch=CYR.procEpoch
local t=dotNetObject "System.Diagnostics.Stopwatch";t.Start();renderWidth=1400;renderHeight=875;renderers.current.progressive_passLimit=8
local frame=render camera:CYCam vfb:false outputfile:(CYOut+"Courtyard_Hero.png")
if frame==undefined do throw "Hero render missing"
close frame
CYLog "render-hero" #(#("elapsed_ms",t.Elapsed.TotalMilliseconds),#("resolution",#(1400,875)),#("pass_limit",8),#("renderer",CoronaRenderer.getVersionString()),#("error",CyrusPFLastError),#("placements_preserved",(CYFP()) as string==before as string),#("epoch_preserved",CYR.procEpoch==epoch),#("counts",counts))
if CyrusPFLastError!="" do throw CyrusPFLastError
local overview=getNodeByName "02 OVERVIEW | courtyard zoning"
if not isValidNode overview do (
 for n in cameras where matchPattern n.name pattern:"02 OVERVIEW*" do overview=n
)
if not isValidNode overview do throw "Overview camera missing"
t.Restart();renderWidth=1200;renderHeight=900;renderers.current.progressive_passLimit=6
frame=render camera:overview vfb:false outputfile:(CYOut+"Courtyard_Overview.png")
if frame==undefined do throw "Overview render missing"
close frame
CYLog "render-overview" #(#("elapsed_ms",t.Elapsed.TotalMilliseconds),#("resolution",#(1200,900)),#("pass_limit",6),#("error",CyrusPFLastError),#("placements_preserved",(CYFP()) as string==before as string),#("epoch_preserved",CYR.procEpoch==epoch))
if CyrusPFLastError!="" do throw CyrusPFLastError
renderWidth=1400;renderHeight=875;renderers.current.progressive_passLimit=8
viewport.setCamera CYCam
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
CYSample "post-final-renders" 0
