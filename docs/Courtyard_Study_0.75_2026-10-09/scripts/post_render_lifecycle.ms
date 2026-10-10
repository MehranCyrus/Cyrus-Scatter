CYRebind()
local fp=CYFP(),epoch=CYR.procEpoch
CyrusPointSync();completeRedraw();windows.processPostedMessages()
local owner=CyrusPointOwner CYNode,transient=for n in objects where getUserProp n "CyrusPFTransient"==true collect n
CYLog "post-render-lifecycle" #(#("point_owner_valid",isValidNode owner),#("retained",if isValidNode owner then cyrusRetainedStats owner else #()),#("pf_transient_nodes",transient.count),#("pf_busy",CyrusPFBusy),#("pf_production",CyrusPFProduction),#("point_error",CyrusPointLastError),#("placements_unchanged",(CYFP()) as string==fp as string),#("epoch_unchanged",CYR.procEpoch==epoch))
if not isValidNode owner or transient.count>0 or CyrusPFBusy or CyrusPFProduction or CyrusPointLastError!="" do throw "Post-render viewport/lifecycle recovery failed"
