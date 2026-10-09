-- Own private host; native bounds, no pointer automation.
(
P07Case="Caption bounds";P07New count:100
select P07Node;max modify mode;modPanel.setCurrentObject P07Root
if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick()
for page in #(P07Root.displayUI,P07Root.layoutUI) do (page.open=true;page.advancedToggle.checked=true;P07Root.mainUI.bindSection page)
local r=P07Root,a=P07Layer,checks=#()
fn checkCaption page radio caption previous:undefined = (
 page.layout()
 local box=windows.getWindowPos caption.hwnd[1],bottom=box.y+box.h
 if not caption.visible or caption.pos.y<6 do throw "Caption hidden or above rollout body"
 for handle in radio.hwnd where (windows.getHWNDData handle)[4]=="Button" do (
  if (windows.getWindowPos handle).y<bottom do throw "Radio options overlap caption"
 )
 if previous!=undefined and previous.visible do for handle in previous.hwnd do (
  local prev=windows.getWindowPos handle
  if prev.y+prev.h>box.y do throw "Caption overlaps preceding control"
 )
 true
)
for mode in #(1,2,3) do (
 r.setGroupDisplay mode;r.displayUI.bind a
 checkCaption r.displayUI r.displayUI.flow_previewUI_pointColorRadio r.displayUI.flow_previewUI_pointColorRadio_caption previous:r.displayUI.flow_previewUI_faceLimitSpin
 append checks ("Preview color native bounds pass in mode "+mode as string)
)
checkCaption r.layoutUI r.layoutUI.diversityUI_diversityRadio r.layoutUI.diversityUI_diversityRadio_caption
append checks "Main Layout heading and options separated"
local epoch=r.procEpoch,builds=a.procPreparedBuilds
CyrusOpenLayerEditor r a
for size in #([720,500],[920,650]) do (
 setDialogSize CyrusLayerEditor size;windows.processPostedMessages();CyrusLayerEditor.showTopic 1
 for page in CyrusLayerEditor.activeEditors() where isProperty page #diversityUI_diversityRadio do (
  checkCaption page page.diversityUI_diversityRadio page.diversityUI_diversityRadio_caption
  append checks ("Popup Layout caption passes at "+size as string)
 )
)
CyrusCloseLayerEditor()
if r.procEpoch!=epoch or a.procPreparedBuilds!=builds do throw "Caption layout rebuilt placements"
append checks "Caption reflow preserves placement publication and preparation"
local container=a.containerCreate()
select container;max modify mode;modPanel.setCurrentObject container.baseObject
if not container.mainUI.controlsReady do container.mainUI.mountTimer.tick()
container.layoutUI.open=true;container.mainUI.bindSection container.layoutUI
container.displayUI.open=true;container.displayUI.advancedToggle.checked=true;container.mainUI.bindSection container.displayUI
checkCaption container.layoutUI container.layoutUI.diversityUI_diversityRadio container.layoutUI.diversityUI_diversityRadio_caption
checkCaption container.displayUI container.displayUI.flow_previewUI_pointColorRadio container.displayUI.flow_previewUI_pointColorRadio_caption previous:container.displayUI.flow_previewUI_faceLimitSpin
append checks "Container Layout and Preview color captions separated"
local f=createFile (MCPFixtureDir+"caption-checks.txt")
for line in checks do format "%\n" line to:f
close f
)
