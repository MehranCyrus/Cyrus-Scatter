(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test*-2027/" do throw "Owned leaf host required"
 global LRoot,LLayer,LSource,LNode,LCatalog,LMaterial,LForest,LBase,LCC
 local output=createFile (MCPFixtureDir+"leaf-probe.txt")
 try(
  resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
  units.SystemType=#centimeters;units.SystemScale=1.
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  LCatalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  LCatalog.Load @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library" "0.86.7" 2027
  local entry=LCatalog.MatchingAt "A027" "" 0
  LNode=AminScatterObject name:"Real library leaf test";LRoot=LNode.baseObject;LRoot.updateMode=1;LRoot.autoRender=false
  LRoot.newLayer();LLayer=LRoot.selectedLayer()
  LSource=CyrusModelMerge LCatalog entry owner:LLayer
  LMaterial=LSource.material;LForest=LMaterial.texmapDiffuse;LBase=LForest.mapbase
  format "MODEL % bounds % % faces % verts %\nMATERIAL %\nDIFFUSE %\nBASE %\nOPACITY %\n" entry.Name LSource.min LSource.max LSource.numfaces LSource.numverts (classof LMaterial) (classof LForest) (classof LBase) (classof LMaterial.texmapOpacity) to:output
  LCC=ColorCorrection();showProperties LCC to:output
  local receiver=plane name:"Leaf receiver" width:60 length:60 widthsegs:1 lengthsegs:1 wirecolor:(color 90 90 90)
  LLayer.amount=16;LLayer.procSelfOverride=true;LLayer.procSelfEnabled=false;LLayer.procLayerSelfEnabled=false
  LRoot.setLayerSurfaces LLayer #(receiver);LRoot.identificationMode=4;LRoot.setGroupDisplay 3
  LRoot.refreshAll();LRoot.evaluateProcedural()
  viewport.setLayout #layout_1;viewport.setType #view_top;viewport.SetRenderLevel #smoothhighlights
  select receiver;max zoomext sel all;select LNode;max modify mode
  CyrusPointSuspended=false;redrawViews();completeRedraw()
  format "PREVIEW % ERROR % COUNT %\n" LLayer.previewError CyrusPointLastError LRoot.groupSnapshotRows[1].count to:output
  local image=gw.getViewportDib();image.filename=MCPFixtureDir+"real-leaves-original.png";save image;close image
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
