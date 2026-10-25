"""Capture exact pivot-local SI mesh bytes and base rows for kernel replay."""
from pathlib import Path
import importlib.util,json,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(str(r.GardenRun))
try:
    with pymxs.undo(False):
        r.loadMaxFile(str(ROOT/'build/interactions087-terraces-host-20261025-04/Terraces_Interactions_087_Foreground.max'),quiet=True,useFileUnits=True)
        r.CyrusPointSuspended=True;r.CyrusPFResume=False
        node=r.getNodeByName('CyrusScatter 0.87 - Terrace contact study');root=node.baseObject
        root.refreshAll()
        # Import helpers without executing the scene-construction footer.
        namespace={'__file__':str(ROOT/'tools/procedural_lab/interactions087/terraces.py')}
        source=Path(namespace['__file__']).read_text();exec(source[:source.rindex('try:\n')],namespace)
        keys=['grass','bushy','lavender','geranium','tree','rock'];layers=dict(zip(keys,root.layerObjects));assets={key:leaf.sources[0] for key,leaf in layers.items()}
        namespace['capture_fixture'](root,layers,assets,'foreground')
        (OUT/'completed.json').write_text(json.dumps({'status':'captured','source':'Saved terrace foreground, same UUIDs and actors as run 04','scope':'Numeric replay capture only'}))
except Exception:(OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
