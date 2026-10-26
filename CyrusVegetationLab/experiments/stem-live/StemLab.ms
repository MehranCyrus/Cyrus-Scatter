-- Bounded artist controls for the independent native Max 2027 stem test.
if (maxVersion())[1]!=29000 do throw "Vegetation Stem Lab 0.2.0 requires Max 2027."
if findString (cvsVersion()) "\"version\":\"0.2.0\""==undefined do throw "Stem Lab script/native version differs."
global CVSPanel,CVSOpen,CVSFind
fn CVSFind = (getNodeByName "CVS_Stem_Lavender")
try(destroyDialog CVSPanel)catch()
rollout CVSPanel "Vegetation Stem Lab 0.2.0"
(
    label intro "Move CVS_Collider_Sphere with the Move gizmo.\nLive preview follows the native scene dependency." width:340 height:38 align:#left
    button sphereButton "Select sphere to drag" width:335 height:34 align:#left
    checkbox liveCheck "Live stem interaction" checked:true align:#left
    checkbox fullCheck "Full geometry in viewport (slower)" checked:false align:#left
    button awayButton "Move sphere away / restore plant" width:335 align:#left
    button inspectButton "Validate full mesh and print results" width:335 align:#left
    button statsButton "Print live timing and drag evidence" width:335 align:#left
    label detail "Preview: 90,640 triangles  |  Render: 832,240\nActual stem paths; foliage pieces retain their shape.\nOnly the sphere is a collider in this test." width:340 height:55 align:#left
    label status "Prepared lavender test. Scene stores its bindings." width:340 height:46 align:#left
    timer statusTick interval:250 active:true
    on statusTick tick do (local n=CVSFind();if isValidNode n do status.text=cvsStatus n)
    on sphereButton pressed do (local s=getNodeByName "CVS_Collider_Sphere";if isValidNode s do (select s;max move))
    on liveCheck changed state do (local n=CVSFind();if isValidNode n do (cvsLive n state;redrawViews()))
    on fullCheck changed state do (local n=CVSFind();if isValidNode n do (cvsMode n (if state then 1 else 0);redrawViews()))
    on awayButton pressed do
    (
        local s=getNodeByName "CVS_Collider_Sphere"
        if isValidNode s do undo "Move collider away" on (s.pos=[1.1*(units.decodeValue "1m"),.096*(units.decodeValue "1m"),.78*(units.decodeValue "1m")])
    )
    on inspectButton pressed do (local n=CVSFind();if isValidNode n do try(local result=cvsAudit n;format "%\n" result;status.text="Full-resolution audit printed in the MAXScript Listener.")catch(status.text=getCurrentException()))
    on statsButton pressed do (local n=CVSFind();if isValidNode n do format "%\n" (cvsStats n))
)
fn CVSOpen = (try(destroyDialog CVSPanel)catch();createDialog CVSPanel 365 360)
