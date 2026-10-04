-- Max/Qt settles native geometry after a MAXScript event returns. Check
-- physical positions on later ticks, rather than stale HWNDs in a tight loop.
if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
global CFLayoutTimer,CFLayoutCampaign,CFLayoutTick,CFLayoutRun
if CFLayoutTimer!=undefined do CFLayoutTimer.Stop()
struct CFLayoutCampaign (
    root,node,targets=#(),index=0,phase=0,records=#(),baseline=0,baseNext=0,settleTicks=0,
    fn nextOffset = ((windows.getWindowPos root.layerPanels[2].hwnd).y-(windows.getWindowPos root.layerPanels[1].hwnd).y),
    fn tick = (
        CFLayoutTimer.Stop()
        try (
            if phase==0 then (
                index+=1
                if index>targets.count then (
                    CSPWriteText (BLDir+"classic-native-flow.json") (CSPObject #(#("passed",true),#("sections",records)))
                    return true
                )
                baseline=root.mainUI.height;baseNext=nextOffset()
                targets[index].open=true;phase=1;settleTicks=0
            ) else if phase==1 then (
                local r=targets[index],delta=nextOffset()-baseNext
                if abs(delta-r.height)>2 then (
                    settleTicks+=1
                    if settleTicks>20 do throw ("Native layer displacement does not match content: "+r.title+" | delta="+(delta as string)+" height="+(r.height as string))
                ) else (
                    append records #(r.title,r.height,delta,root.mainUI.height,settleTicks)
                    r.open=false;phase=2;settleTicks=0
                )
            ) else (
                if root.mainUI.height!=baseline or abs(nextOffset()-baseNext)>2 then (
                    settleTicks+=1
                    if settleTicks>20 do throw ("Collapsing content left a native gap: "+(nextOffset() as string)+" expected="+(baseNext as string))
                ) else phase=0
            )
            CFLayoutTimer.Start()
        )catch(CSPWriteText (BLDir+"classic-native-flow.json") (CSPObject #(#("passed",false),#("error",getCurrentException()),#("sections",records))))
    )
)
for r in CFRoot.nativeEditors() do r.open=false
for p in CFRoot.layerPanels do (p.open=true;p.mount();for r in p.editors do r.open=false)
CFLayoutRun=CFLayoutCampaign root:CFRoot node:CFNode targets:CFRoot.layerPanels[1].editors
fn CFLayoutTick sender args = CFLayoutRun.tick()
CFLayoutTimer=dotNetObject "System.Windows.Forms.Timer"
CFLayoutTimer.Interval=250
dotNet.addEventHandler CFLayoutTimer "Tick" CFLayoutTick
CFLayoutTimer.Start()
