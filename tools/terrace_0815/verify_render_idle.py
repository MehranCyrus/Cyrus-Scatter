"""Observe scheduled production-render cleanup after the render callback returns."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir)).resolve();assert OUT.name=='foundation-terrace0815-candidate2027-04'
report=OUT/'garden-final-render.json';data=json.loads(report.read_text())
assert data['fingerprints_unchanged_after_render'] and not data['render_error']
prior=OUT/'garden-final-render-before-idle.json'
assert not prior.exists();prior.write_text(report.read_text())
try:
    data['immediate_transient_count']=data['temporary_render_nodes_remaining']
    data['idle_transient_count']=len(r.CyrusPFNodes)
    data['idle_transient_valid_count']=sum(bool(r.isValidNode(n)) for n in r.CyrusPFNodes)
    data['idle_error']=str(r.CyrusPFLastError)
    data['idle_production']=bool(r.CyrusPFProduction)
    data['idle_redraw_held']=bool(r.AminScatterRenderRedrawHeld)
    root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject
    expected=json.loads((OUT/'garden-final-acceptance.json').read_text())['baseline']['fingerprints']
    data['idle_fingerprints_match']=[str(r.cyrusEditFingerprint(rows,'garden-final815')) for rows in root.groupSnapshotRows]==expected
    assert data['idle_transient_count']==0 and not data['idle_error'] and not data['idle_production'] and not data['idle_redraw_held']
    assert data['idle_fingerprints_match']
    data['status']='complete';data.pop('error',None)
    data['image']=str(Path(__file__).resolve().parents[2]/'Test Scene/Terraces_0815/Terraces_0815_Final.png')
    data['cleanup_note']='Production postRender schedules the existing idle cleanup; checked after returning to the event loop, without manually deleting render nodes.'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:report.write_text(json.dumps(data,indent=2)+'\n')
if data['status']!='complete':raise RuntimeError(data['error'])
