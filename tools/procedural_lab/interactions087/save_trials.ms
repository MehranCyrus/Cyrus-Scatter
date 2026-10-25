-- Final matched-payload saved copies. No writes to Test Scene or artist profiles.
global TOwner,TRoot,TEdit,TRocks,PSettle
local folder=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.87.0-20261025-r4/Trials/"
makeDir folder all:true
local fast=folder+"Terraces_087_Responsive.max",detail=folder+"Terraces_087_Detailed.max"
if doesFileExist fast or doesFileExist detail do throw "Final trial scene paths already exist; choose a fresh delivery folder."
TRoot.layerObjects[1].amount=10000
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 400
local pos=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation,target=[-8000,-3100,-988.8409]
if distance pos target>0.001 do undo "Restore trial hero stone" on cyrusEditTransform TEdit 0 (target-pos) (matrix3 1) false
PSettle 400
TRoot.selectLayer 6;TRoot.refreshAll();CyrusPointSync();completeRedraw();PSettle 500
if TRoot.interactionError!="" do throw TRoot.interactionError
local eye=[-7700,-3550,-730],lookAt=[-8020,-3120,-930],look=normalize(lookAt-eye)
local right=normalize(cross look [0,0,1]),up=normalize(cross right look)
viewport.setType #view_persp_user;viewport.setTM (inverse(matrix3 right up (-look) eye));viewport.setRenderLevel #smoothhighlights
TRoot.identificationMode=4;TRoot.viewportFaces=20000000;TRoot.viewportNavigationFaces=10000000
TRoot.refreshDisplay();CyrusPointSync();completeRedraw();PSettle 700
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 300
saveMaxFile detail quiet:true;PSettle 600
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"saved-detailed-statistics.json") (TRoot.interactionsStatistics())
local epoch=TRoot.procEpoch
TRoot.viewportFaces=8000000;TRoot.viewportNavigationFaces=5000000
TRoot.refreshDisplay();CyrusPointSync();completeRedraw();PSettle 700
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 300
if TRoot.procEpoch!=epoch do throw "Changing trial display quality rebuilt placements."
saveMaxFile fast quiet:true;PSettle 600
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"saved-responsive-statistics.json") (TRoot.interactionsStatistics())
local image=gw.getViewportDib();image.filename=GardenRun+"final-responsive-preview.png";save image;close image
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"saved-trials.json") "{\"status\":\"pass\",\"plants\":12416,\"rigid_trees\":10,\"colliders\":3,\"responsive_faces\":[8000000,5000000],\"detailed_faces\":[20000000,10000000],\"scope\":\"Derived scene copies with diagnostic materials, source-local prepared definitions, one Cyrus Edit, original architecture and rigid tree source. Display quality changes preserved placements.\"}"
