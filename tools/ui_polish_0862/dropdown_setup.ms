(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 CyrusClearMeshMaskPreview undefined
 for i=1 to DRoot.mainUI.slots.count do DRoot.mainUI.slots[i].open=(i==1 or i==6)
 DRoot.mainUI.bindEditors()
 local page=DRoot.mainUI.editors[6]
 page.advancedToggle.checked=false;page.layout()
 global DropProbePage=page,DropProbeRoot=DRoot,DropProbeLog=createFile (MCPFixtureDir+"dropdown-probe.txt"),DropProbeTimer=undefined,DropProbeLast=-1,DropProbeOpened=0,DropProbeExercised=false,DropProbeTicks=0
 for h in page.distributionUI_coordinatesList.hwnd do format "HANDLE %\n" (windows.getHWNDData h) to:DropProbeLog
 flush DropProbeLog
 fn DropProbeTick sender args = (
  DropProbeTicks+=1
  local open=false
  for h in DropProbePage.distributionUI_coordinatesList.hwnd where windows.sendMessage h 0x157 0 0 !=0 do open=true
  if open!=DropProbeLast do (format "OPEN % time=%\n" open (timestamp()) to:DropProbeLog;flush DropProbeLog;DropProbeLast=open;if open do DropProbeOpened=timestamp())
  if open and not DropProbeExercised and timestamp()-DropProbeOpened>1500 do (
   DropProbeExercised=true
   format "STATUS_REFRESH %\n" (timestamp()) to:DropProbeLog;flush DropProbeLog
   DropProbeRoot.mainUI.refreshStats()
  )
  if DropProbeTicks>1200 do (sender.Stop();close DropProbeLog)
 )
 DropProbeTimer=dotNetObject "System.Windows.Forms.Timer";DropProbeTimer.Interval=100
 dotNet.addEventHandler DropProbeTimer "Tick" DropProbeTick;DropProbeTimer.Start()
)
