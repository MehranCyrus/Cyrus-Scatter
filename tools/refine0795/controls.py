"""Native control inventory/bounds capture; does not claim physical gesture coverage."""
from pathlib import Path
import sys,json,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('controls')
try:
    node=r.getNodeByName('CYRUS | Terraced garden 0.79.5');root=node.baseObject
    r.select(node);mx('max modify mode');r.modPanel.setCurrentObject(root);pump(400)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    root.selectLayer(1);root.bindNativeUI();initial=fingerprint(root);epoch=int(root.procEpoch)
    manifest=json.loads((ROOT/'AminScatter/tools/ui/approved-layout-manifest.json').read_text());rows=[]
    for section in manifest['sections']:
        panel=getattr(root,section['name']);panel.open=True;root.mainUI.bindSection(panel)
        if r.isProperty(panel,r.Name('advancedToggle')):panel.advancedToggle.checked=True
        panel.layout()
        for spec in section['controls']:
            row=dict(section=section['title'],presentation=spec['presentation'],semantic=spec['component']+'.'+spec['control'])
            if not r.isProperty(panel,r.Name(spec['presentation'])):
                row['missing']=True
            else:
                control=getattr(panel,spec['presentation']);row['missing']=False
                for name in ('pos','width','height','visible','enabled','text'):
                    if r.isProperty(control,r.Name(name)):row[name]=str(getattr(control,name))
            rows.append(row)
        panel.open=False
    rec.data['controls']=rows;rec.write()
    rec.check(all(not row['missing'] for row in rows),'All current generated presentation controls bind in Max')
    rec.check(fingerprint(root)==initial and int(root.procEpoch)==epoch,'Opening all panels preserves placements and publication')
    rec.data['semantic_controls']=len(json.loads((ROOT/'CyrusMCP/cyrus_mcp/feature-catalog.json').read_text())['controls']);rec.write()
    root.managerUI.open=True;root.surfacesUI.open=True;root.modelsUI.open=True;root.coverageUI.open=True
except Exception:rec.error(traceback.format_exc())
