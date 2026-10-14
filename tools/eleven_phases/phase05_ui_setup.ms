(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 global P05UINode,P05UIRoot,P05UILeaf,P05UIArea,P05UICurve,P05UIEpoch,P05UIRevision,P05UIRows
 CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
 P05UINode=AminScatterObject name:"P05 owned UI test";P05UIRoot=P05UINode.baseObject
 P05UIRoot.updateMode=1;P05UIRoot.autoRender=false
 local receiver=plane name:"P05 UI receiver" length:60 width:60 lengthsegs:1 widthsegs:1
 P05UIRoot.newLayer();P05UILeaf=P05UIRoot.selectedLayer();P05UIRoot.setLayerSurfaces P05UILeaf #(receiver)
 P05UILeaf.addPointSource();P05UILeaf.amount=1500;P05UILeaf.procSelfOverride=true;P05UILeaf.procSelfEnabled=false
 P05UIArea=P05UIRoot.addPaintArea P05UILeaf target:receiver
 P05UICurve=circle name:"P05 pick this closed circle" radius:10 wirecolor:yellow
 cyrusBrushFill P05UIArea.paintDocument 1;P05UIArea.publishPaint();P05UIRoot.refreshAll();CyrusPointSync()
 P05UIEpoch=P05UIRoot.procEpoch;P05UIRevision=(cyrusBrushStats P05UIArea.paintDocument)[1]
 P05UIRows=with printAllElements on (P05UIRoot.groupSnapshotRows as string)
 hide receiver;hide P05UINode
 viewport.setType #view_top;select P05UICurve;max zoomext sel
 select P05UINode;max modify mode;modPanel.setCurrentObject P05UIRoot
 CyrusPerfHeadless=false
 if not P05UIRoot.mainUI.controlsReady do P05UIRoot.mainUI.mountTimer.tick()
 for editor in P05UIRoot.mainUI.editors do editor.open=false
 P05UIRoot.coverageUI.open=true;P05UIRoot.mainUI.bindSection P05UIRoot.coverageUI
 saveMaxFile (MCPFixtureDir+"P05_owned_UI.max") quiet:true
)
