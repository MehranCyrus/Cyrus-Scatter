"""Render the verified saved garden through the requested physical camera."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve();SCENES=ROOT/'Test Scene/Terraces_0815'
assert OUT.name=='foundation-terrace0815-candidate2027-04'
assert json.loads((OUT/'garden-final-acceptance.json').read_text())['status']=='complete'
data={'status':'started','camera':'PhysCamera002','width':1920,'height':1080,'pass_limit':12,'denoiser':2,'denoise_blend':.65}
def save():(OUT/'garden-final-render.json').write_text(json.dumps(data,indent=2)+'\n')
def fingerprints(root):return [str(r.cyrusEditFingerprint(rows,'garden-final815')) for rows in root.groupSnapshotRows]
try:
    root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject
    expected=fingerprints(root);root.autoRender=True
    r.renderWidth=1920;r.renderHeight=1080;r.renderers.current.progressive_passLimit=12
    r.renderers.current.denoise_filterType=2;r.renderers.current.denoise_blendAmount=.65
    r.renderers.current.denoise_blendEnabled=True
    r.saveMaxFile(str(SCENES/'Terraces_0815_Final.max'),quiet=True)
    data['status']='reopening';save()
    r.loadMaxFile(str(SCENES/'Terraces_0815_Final.max'),quiet=True,useFileUnits=True)
    root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject;root.refreshAll()
    assert fingerprints(root)==expected,'Final render settings save/reopen changed placements'
    assert all(not str(l.previewError) for l in root.layerObjects)
    data['reopen_fingerprints_match']=True
    data['counts']=[int(l.generatedCount) for l in root.layerObjects];data['render_builds_before']=int(r.CyrusPFBuilds)
    camera=r.getNodeByName('PhysCamera002');data['camera_transform']=str(camera.transform)
    data['status']='rendering';save();start=time.perf_counter()
    frame=r.render(camera=camera,vfb=False,outputfile=str(SCENES/'Terraces_0815_Final.png'))
    r.close(frame);data['render_seconds']=time.perf_counter()-start
    data['render_error']=str(r.CyrusPFLastError);data['render_builds_after']=int(r.CyrusPFBuilds)
    data['fingerprints_unchanged_after_render']=fingerprints(root)==expected
    data['temporary_render_nodes_remaining']=len(r.CyrusPFNodes)
    assert not data['render_error']
    assert data['fingerprints_unchanged_after_render']
    # postRender schedules cleanup on the existing timer. The transport callback
    # must return to the event loop before verify_render_idle.py observes it.
    data['image']=str(SCENES/'Terraces_0815_Final.png');data['status']='rendered_awaiting_idle'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='rendered_awaiting_idle':raise RuntimeError(data['error'])
