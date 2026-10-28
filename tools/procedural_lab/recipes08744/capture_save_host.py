from pathlib import Path
import json
from pymxs import runtime as r
O=Path(str(r.GardenRun));r.execute('subObjectLevel=0;modPanel.setCurrentObject WFRoot;WFRoot.identificationMode=3;WFRoot.procEnsureDisplay();CyrusPointSync()')
before=str(r.cyrusEditInspect(r.WFEdit,0,500))
r.execute('CVBindings=#();CVDocument=CyrusRecipeCapture WFRoot (WFRoot.logicalLayers()) "Edited grass and collider" bindingResult:CVBindings')
assert before==str(r.cyrusEditInspect(r.WFEdit,0,500))
r.execute('cyrusRecipeEntryWrite (GardenRun+"captured.csrecipe.json") CVDocument (CyrusRecipeObject #(#("category","Qualification"),#("tags",#()),#("description","Owned fixture"))) "" undefined "" false;CyrusOpenRecipeSave WFRoot (GardenRun+"shared-library/");CyrusRecipeSaveEditor.recipeName.text="Edited grass 08744"')
