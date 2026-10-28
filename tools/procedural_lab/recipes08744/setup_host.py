from pathlib import Path
import json,traceback,time
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun))
def pump():
 for _ in range(12):r.windows.processPostedMessages();time.sleep(.025);r.completeRedraw()
try:
 r.execute('CyrusPointSuspended=true;CyrusPerfHeadless=true')
 source=ROOT/'build/interactions08743-20261027-01/host-03/Grass_Hide_Margin_0.87.4.3.max'
 assert r.loadMaxFile(str(source),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
 r.ColorPipelineMgr.Mode=r.Name('OCIO_Default')
 owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
 root=owner.baseObject;leaf=root.layerObjects[0];collider=root.layerObjects[1]
 root.updateMode=1;leaf.interactionCoverRoots=False
 for layer in root.layerObjects:
  for node in layer.validSources():node.material=r.StandardMaterial(name='Recipe08744Opaque')
 owner.name='Recipe08744_Owned_Setup'
 r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFEdit,CVBindings,CVDocument,CVImported,CVJob,CVPackage,CVPlan')
 r.WFOwner=owner;r.WFRoot=root;r.WFGrass=leaf;r.WFCollider=collider;r.WFSphere=collider.validSources()[0]
 r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
 r.execute('CyrusPointSuspended=false;CyrusPerfHeadless=false;WFRoot.refreshAll();select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;cyrusEditActiveLayers WFEdit #(WFGrass.editLayerKey)')
 r.execute('WFRoot.interactionsEnsure();CyrusPointSync()');pump()
 r.execute('cyrusEditSelect WFEdit #(1);global CVRecord=(for item in (cyrusEditInspect WFEdit 0 500)[4] where item[1]==WFGrass.editLayerKey and item[6] and item[7] collect item)[1];global CVFrame=cyrusEditHandleMatrix WFEdit WFGrass.editLayerKey CVRecord[2];global CVGesture=(scaleMatrix [1.2,1.2,1.2])*(rotateZMatrix 17);CVGesture.row4=CVFrame.row4-CVFrame.row4*CVGesture+[1.25,2.5,0.3];undo "Recipe test affine edit" on cyrusEditCommand WFEdit 4 CVGesture')
 r.execute('WFRoot.interactionsEnsure();CyrusPointSync()');pump()
 r.execute('cyrusEditActiveLayers WFEdit #(WFGrass.editLayerKey);cyrusEditSelect WFEdit #(2);cyrusEditCommand WFEdit 3 (matrix3 1)')
 r.execute('WFRoot.interactionsEnsure();CyrusPointSync()');pump()
 r.execute('cyrusEditActiveLayers WFEdit #(WFGrass.editLayerKey);cyrusEditSelect WFEdit #(3);cyrusEditCommand WFEdit 2 (matrix3 1)')
 r.execute('WFRoot.interactionsEnsure();CyrusPointSync()');pump()
 # A separate closed proxy must travel as a normal asset role.
 proxy=r.copy(r.WFSphere);proxy.name='Recipe08744_Custom_Proxy';r.CVProxy=proxy
 r.execute('WFCollider.interactionProxySourceIDs=#(WFCollider.sourceRowIDs[1]);WFCollider.interactionProxyNodes=#(CVProxy);WFCollider.interactionColliderMode=3;WFRoot.refreshAll();subObjectLevel=0;modPanel.setCurrentObject WFRoot;CyrusPointSync();completeRedraw()')
 r.CyrusSharedLibraryRootOverride=str(ROOT/'build/r8744-lib05')
 assert not str(root.interactionError),str(root.interactionError)
 before=str(r.cyrusEditInspect(r.WFEdit,0,500))
 r.execute('CVBindings=#();CVDocument=CyrusRecipeCapture WFRoot (WFRoot.logicalLayers()) "Edited grass and collider" bindingResult:CVBindings')
 assert before==str(r.cyrusEditInspect(r.WFEdit,0,500)), 'Read-only capture mutated edits'
 r.execute('cyrusRecipeEntryWrite (GardenRun+"captured.csrecipe.json") CVDocument (CyrusRecipeObject #(#("category","Qualification"),#("tags",#()),#("description","Owned fixture"))) "" undefined "" false')
 r.execute('CyrusOpenRecipeSave WFRoot (GardenRun+"shared-library/");CyrusRecipeSaveEditor.recipeName.text="Edited grass 08744"')
 def matrix(m):return [[float(m[i][j]) for j in range(3)] for i in range(4)]
 rows=r.cyrusEditInspect(r.WFEdit,0,500)[3]
 report={'status':'passed','version':str(root.uiVersion()),'schema':int(root.version),'rows':[{'key':int(x[0]),'id':str(x[3]),'output':str(x[4]),'deleted':bool(x[8]),'order':int(x[9]),'delta':matrix(x[10]),'base':None if x[11]==r.undefined else matrix(x[11]),'final':None if x[12]==r.undefined else matrix(x[12])} for x in rows],'definitions':[len(str(x)) for x in leaf.interactionDefinitions],'contact':json.loads(str(root.interactionsStatistics()))}
 (O/'source-state.json').write_text(json.dumps(report,indent=2))
 r.saveMaxFile(str(O/'Edited_Source_08744.max'),quiet=True)
except Exception:
 (O/'setup-error.txt').write_text(traceback.format_exc());raise
