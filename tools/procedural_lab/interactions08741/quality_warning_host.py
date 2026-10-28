"""Verify the detected-deformation warning in the real Interactions panel."""
from pathlib import Path
import json, time, traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));root_dir=Path(__file__).resolve().parents[3]
phase=int(r.CVCaptureDirection);path=host/'quality-warning.json'
report={'status':'running'} if phase==1 else json.loads(path.read_text(encoding='utf-8'))
try:
    if phase==1:
        trial=root_dir/'build/interactions08741-20261027-01/candidate-host-08/Small_Tree_Interaction_0.87.4.1.max'
        assert trial.is_file() and r.loadMaxFile(str(trial),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
        root=owner.baseObject;r.CyrusPointSync();r.completeRedraw();root.interactionsEnsure()
        statistics=json.loads(str(root.interactionsStatistics()));summary=str(root.interactionsStatus())
        assert not str(root.interactionError) and not statistics.get('error'),statistics
        assert statistics['quality_checked_guides']>0 and statistics['quality_warning_guides']>0,statistics
        assert statistics['maximum_checked_stem_edge_change']>.25 and 'shape review' in summary,summary
        r.select(owner);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
        end=time.monotonic()+10
        while time.monotonic()<end and (root.mainUI==r.undefined or not bool(root.mainUI.controlsReady)):
            r.windows.processPostedMessages();time.sleep(.02)
        assert root.mainUI!=r.undefined and root.mainUI.controlsReady
        panel=root.mainUI;panel.selectLayerView(root.layerObjects[0]);panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12])
        info=str(panel.editors[12].interactionsUI_info.text)
        assert 'shape review' in info and 'Check full visible mesh' in info,info
        r.execute('global TQRoot,TQTree');r.TQRoot=root;r.TQTree=root.layerObjects[4]
        report={'status':'warning_shown','statistics':statistics,'summary':summary,'panel_message':info,
                'scope':'Known deformed tree-scene flower on the exact packaged native/script pair; a warning is not a complete mesh audit'}
    elif phase==2:
        root=r.TQRoot
        r.execute('undo "disable test colliders" on TQTree.interactionCollider=false')
        root.interactionsEnsure();statistics=json.loads(str(root.interactionsStatistics()));summary=str(root.interactionsStatus())
        assert statistics['quality_warning_guides']==0 and 'shape review' not in summary,statistics
        report.update(status='warning_cleared',after_disable=statistics)
    elif phase==3:
        root=r.TQRoot;r.execute('max undo');root.interactionsEnsure()
        statistics=json.loads(str(root.interactionsStatistics()));summary=str(root.interactionsStatus())
        assert statistics['quality_warning_guides']>0 and 'shape review' in summary,statistics
        report.update(status='pass',after_undo=statistics,undo_summary=summary)
    else:raise ValueError('Use phases 1 through 3')
except Exception:
    report.update(status='failed',error=traceback.format_exc())
else:
    report.pop('error',None)
path.write_text(json.dumps(report,indent=2),encoding='utf-8')
