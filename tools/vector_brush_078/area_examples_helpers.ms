-- Append-only helpers; never reset the artist's example scene.
global QA_NewCase,QA_Activate,QA_AddArea,QA_AddBand,QA_Metre,QA_Pump
QA_Metre=units.decodeValue "1m"
fn QA_Pump ms = (local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn QA_Activate c = (
 select c[1];max modify mode;modPanel.setCurrentObject c[1].baseObject
 local r=c[1].baseObject
 if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
 r
)
fn QA_NewCase title center number:1 sources:1 = (
 local bucket=LayerManager.newLayerFromName ("CSQA_"+formattedPrint number format:"02d"+" "+title)
 local ground=plane name:("CSQA_Receiver_"+number as string) width:(3*QA_Metre) length:(3*QA_Metre) widthsegs:1 lengthsegs:1 pos:center
 local node=AminScatterObject name:("CSQA_"+formattedPrint number format:"02d"+"_"+title)
 node.pos=center+[-1.42,-1.42,0]*QA_Metre;node.iconSize=.065*QA_Metre
 local r=node.baseObject
 r.updateMode=1;r.autoRender=false;r.newLayer();r.layerNames[1]=title
 local leaf=r.selectedLayer();leaf.amount=2400;leaf.procPopulation=1;r.setLayerSurfaces leaf #(ground)
 local c=#(node,leaf,ground,bucket);QA_Activate c
 local panel=r.modelsUI;panel.open=true;r.mainUI.bindSection panel;panel.advancedToggle.checked=true;panel.layout()
 for i=1 to sources do panel.sourceUI_addPoint.pressed()
 local colors=#((color 255 175 60),(color 90 205 255),(color 140 225 110))
 for i=1 to sources do (leaf.assignGroup #{i} colors[i];leaf.setSourceIDColor #{i} colors[i])
 r.setGroupDisplay 4
 ground.isHidden=true;bucket.addNode ground;bucket.addNode node
 local caption=text name:("CSQA_Label_"+number as string) text:(formattedPrint number format:"02d"+"  "+title) size:(.11*QA_Metre) pos:(center+[-1.4,1.35,0]*QA_Metre)
 caption.renderable=false;caption.wirecolor=color 215 215 215;bucket.addNode caption
 c
)
fn QA_AddArea c shape mode = (
 local r=QA_Activate c,p=r.areasUI
 p.open=true;r.mainUI.bindSection p
 p.areaUI_pickArea.picked shape
 local index=findItem c[2].areaNodes shape
 p.areaUI_areaList.selection=#{index};p.areaUI_areaList.selectionEnd()
 p.areaUI_areaMode.state=mode;p.areaUI_areaMode.changed mode
 if c[2].areaModes[index]!=mode do throw "Area mode handler did not save selected mode"
)
fn QA_AddBand c shape side width slot = (
 local r=QA_Activate c,p=r.layoutUI
 p.open=true;r.mainUI.bindSection p;p.diversityUI_diversityRadio.changed 3
 p.diversityUI_pickPath.picked shape
 if side==2 then p.diversityUI_addInside.pressed() else p.diversityUI_addOutside.pressed()
 p.diversityUI_strokeWidth.changed width
 local choice=findItem p.diversityUI_choiceValues (c[2].colorKey(c[2].sourceColor slot))
 p.diversityUI_strokeChoices.selection=#{choice};p.diversityUI_strokeChoices.selectionEnd()
 c[2].patternLines.count
)
