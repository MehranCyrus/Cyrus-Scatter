-- Own-panel geometry inspection through Max's documented rollout API.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local path=MCPFixtureDir+"layout-"+(timeStamp() as string)+".txt"
 local log=createFile path,main=DRoot.mainUI,clipped=#(),checked=0
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"layout-latest.txt") path
 format "scale=% ready=% sections=%\n" (GetUIScaleFactor()) main.controlsReady main.editors.count to:log;flush log
 if not main.controlsReady or main.editors.count!=12 do (close log;throw "Wait for actual Modify panel mount before measuring")
 for i=1 to main.editors.count do (
  local page=main.editors[i]
  if page.isDisplayed do (
   local bounds=windows.getWindowPos page.hwnd,outer=windows.getWindowPos main.slots[i].hwnd
   local left=amax bounds.x outer.x,right=amin (bounds.x+bounds.w) (outer.x+outer.w)
   bounds=Box2 left bounds.y (right-left) bounds.h
   format "PAGE % width=% bounds=%\n" page.name page.width bounds to:log
   for control in page.controls where control.visible do (
    local handles=try(control.hwnd)catch(#())
    for handle in handles where handle!=0 do (
     local box=windows.getWindowPos handle
     checked+=1
     local data=windows.getHWNDData handle
     if (box.x<bounds.x-3 or box.x+box.w>bounds.x+bounds.w+3) and not (data[4]=="Static" and data[5]=="") do append clipped #(page.name,control.name,box,bounds,data)
    )
   )
  )
 )
 format "CONTROLS=% CLIPPED=%\n" checked clipped to:log;flush log
 local nameField=main.editors[1].flow_layersUI_nameEdit
 format "NAME width=% available=% slot=% physical=%\n" nameField.width (main.editors[1].lastLayoutWidth-12) main.slots[1].width (windows.getWindowPos main.slots[1].hwnd) to:log
 if nameField.width<main.editors[1].lastLayoutWidth-13 do (close log;throw "Name field does not use the full row")
 if checked<150 or clipped.count>0 do (close log;throw "Panel horizontal clipping audit failed")
 main.slots[1].open=true
 for i=2 to main.editors.count do main.slots[i].open=(i==6)
 main.bindEditors()
 format "PASS: all mounted visible control HWNDs fit their page horizontally\n" to:log;close log
)
