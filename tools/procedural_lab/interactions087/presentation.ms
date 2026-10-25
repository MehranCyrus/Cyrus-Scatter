global TOwner,TRoot,TEdit,TRocks,PSettle
TRoot.identificationMode=1;TRoot.refreshIdentification();CyrusPointSync();completeRedraw();PSettle 400
local target=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation,eye=target+[230,-350,180]
local look=normalize(target-eye),right=normalize(cross look [0,0,1]),up=normalize(cross right look)
viewport.setType #view_persp_user;viewport.setTM (inverse(matrix3 right up (-look) eye));viewport.setRenderLevel #smoothhighlights
completeRedraw();PSettle 500
local image=gw.getViewportDib();image.filename=GardenRun+"plain-preview.png";save image;close image
