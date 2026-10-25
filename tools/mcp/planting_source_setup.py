"""Owned fixture: existing library grass/flower nodes, explicitly supplied to MCP.

The measured unsafe .max merge happens only while constructing this disposable
test scene. It is not a proposed model-callable import or artist transaction.
"""
import json
from pathlib import Path
from pymxs import runtime as rt
import host_fixture as base

panel=base.PANEL
root=json.loads((base.OUTPUT/"planting-source-input.json").read_text())["library_root"]
rt.execute('dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")')
catalog=rt.execute('dotNetObject "CyrusScatter.UI.IndividualModelCatalog"')
catalog.Load(root,str(rt.CyrusLibraryVersion()),2027)
models={}
for key in ("A069","A062"):
    entry=next(catalog.MatchingAt("","",i) for i in range(int(catalog.Count)) if str(catalog.MatchingAt("","",i).Id)==key)
    models[key]=rt.CyrusModelMerge(catalog,entry)
    rt.hide(models[key]);models[key].renderable=False
patch=base.shape("Owned flower patch",[(-3,-3),(3,-3),(3,3),(-3,3)])
rt.select(rt.Array(panel.picked["site"][0],models["A069"],models["A062"],panel.picked["regions"][0],patch))
panel.inspect_scene_selected();panel.scene_task_dialog.hide()
ids={key:next(oid for oid,node in panel.host.scene_nodes.items() if node==model) for key,model in models.items()}
result=dict(status="prepared",model_object_ids=ids,scope_id=panel.service.scope["scope_id"],objects=panel.service.scope["snapshot"]["objects"],
            provenance="Explicit source nodes in an owned fixture; .max merging occurred before task enrollment, not through MCP.")
(base.OUTPUT/"planting-source-setup.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
