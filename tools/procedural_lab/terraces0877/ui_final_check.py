from pathlib import Path
import json
script=Path(__file__).with_name('ui_probe.py').read_text(encoding='utf-8')
prefix=script.split("    report['epoch_before_panels']")[0]
exec(prefix+"\nexcept Exception:\n    raise\n",globals())
assert report['point_label_current'],report
root=r.UIRoot;leaf=r.UILayer
root.mainUI.slots[2].open=False
leaf.sourceWeights[0]=2.;leaf.markInputDirty()
root.mainUI.slots[2].open=True;pump()
report['closed_page_current']='2.00' in str(root.modelsUI.sourceUI_plantList.items[0])
assert report['closed_page_current']
report['version']=str(r.CyrusLibraryVersion());report['status']='complete'
(out/'ui-final-check.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
