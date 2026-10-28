"""Exercise two actual tree proxies and Edit history on an owned trial copy."""
from pathlib import Path
import hashlib
import json
import struct
import time
import traceback
from pymxs import runtime as r

root_path = Path(__file__).resolve().parents[3]
host = Path(str(r.GardenRun))
phase = int(r.CVCaptureDirection)
path = host / 'small-tree-scenarios.json'
report = {'status': 'running', 'checks': []} if phase == 1 else json.loads(path.read_text(encoding='utf-8'))


def position(root, edit, trees, row):
    p = r.cyrusEditHandleMatrix(edit, int(trees.editLayerKey), row).translation
    return [float(p.x), float(p.y), float(p.z)]


def statistics(root):
    return json.loads(str(root.interactionsStatistics())) if root.interactionState != r.undefined else None


def near(a, b, epsilon=.001):
    return sum((a[i]-b[i])**2 for i in range(3))**.5 <= epsilon


try:
    if phase == 1:
        scene = root_path / 'build/interactions08741-20261027-01/fixtures/small-tree/Small_Test_Interaction_0.87.2.max'
        assert scene.is_file()
        report['source_sha256'] = hashlib.sha256(scene.read_bytes()).hexdigest()
        assert r.loadMaxFile(str(scene), quiet=True, useFileUnits=True, missingDLLsAction=r.Name('logmsg'))
        owner = next(n for n in r.objects if str(r.classOf(n.baseObject)) == 'AminScatterObject' and n.baseObject.overlapOwner == r.undefined)
        root = owner.baseObject
        layers = list(root.layerObjects)
        trees, edit = layers[4], owner.modifiers[0]
        assert not any(bool(x.interactionUnitsPending) for x in [root, *layers]), 'Saved SI settings require repair'
        root.updateMode = 1
        r.CyrusPointSync()
        r.completeRedraw()
        r.windows.processPostedMessages()
        root.interactionsEnsure()
        assert not str(root.interactionError), str(root.interactionError)
        assert len(trees.validSources()) == 2 and len(trees.interactionProxyNodes) == 2
        proxies = []
        for i, node in enumerate(trees.validSources()):
            proxy = trees.interactionsProxy(node)
            assert r.isValidNode(proxy) and not bool(proxy.renderable)
            value = r.cyrusInteractionColliderSource(node, proxy, 3)
            snapshot = host / ('tree-proxy-'+str(i)+'.bin')
            r.cyrusInteractionSourceSnapshot(value, str(snapshot))
            header = struct.unpack('<4I', snapshot.read_bytes()[:16])
            proxies.append({'source': str(node.name), 'proxy': str(proxy.name), 'vertices': header[1], 'triangles': header[2],
                            'visual_polygon_count': [int(x) for x in r.getPolygonCount(node)]})
            assert header[2] <= 1000, 'The trial tree is not using its lightweight proxy'
        r.execute('global TSOwner,TSRoot,TSTrees,TSEdit')
        r.TSOwner, r.TSRoot, r.TSTrees, r.TSEdit = owner, root, trees, edit
        r.execute('select TSOwner;max modify mode;modPanel.setCurrentObject TSEdit;subObjectLevel=1;max move')
        r.cyrusEditActiveLayers(edit, r.Array(int(trees.editLayerKey)))
        r.cyrusEditSelect(edit, r.Array(1))
        report['proxies'] = proxies
        report['baseline'] = {'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds),
                              'first': position(root, edit, trees, 1), 'second': position(root, edit, trees, 2),
                              'statistics': statistics(root), 'update_mode': int(root.updateMode)}
        assert report['baseline']['statistics']['obstacles'] == 2
        report['status'] = 'ready'
    elif phase in (2, 4):
        root, trees, edit = r.TSRoot, r.TSTrees, r.TSEdit
        row = 1 if phase == 2 else 2
        if phase == 4:
            restored = {'first': position(root, edit, trees, 1), 'second': position(root, edit, trees, 2)}
            assert near(restored['first'], report['baseline']['first']) and near(restored['second'], report['baseline']['second']), restored
            report['checks'].append('Undo restores both independent tree positions')
        r.cyrusEditActiveLayers(edit, r.Array(int(trees.editLayerKey)))
        r.cyrusEditSelect(edit, r.Array(row))
        start = time.perf_counter()
        r.execute('undo "0.87.4.1 tree collider move" on cyrusEditTransform TSEdit 0 [0.5,0,0] (matrix3 1) false')
        root.interactionsEnsure()
        r.CyrusPointSync()
        r.completeRedraw()
        item = {'elapsed_ms': (time.perf_counter()-start)*1000., 'first': position(root, edit, trees, 1),
                'second': position(root, edit, trees, 2), 'epoch': int(root.procEpoch), 'builds': int(root.groupBuilds),
                'error': str(root.interactionError), 'statistics': statistics(root)}
        name = 'first_move' if phase == 2 else 'second_move'
        report[name] = item
        assert item['epoch'] == report['baseline']['epoch'] and item['builds'] == report['baseline']['builds'] and not item['error'], item
        assert item['statistics']['generation'] > report['baseline']['statistics']['generation'] and item['statistics']['affected'] > 0, item
        # A completed numerical contact can precede viewport publication in
        # this callback. Read the committed position on the next host event.
        report['status'] = name+'_requested'
    elif phase in (3, 5):
        root, trees, edit = r.TSRoot, r.TSTrees, r.TSEdit
        moved = {'first': position(root, edit, trees, 1), 'second': position(root, edit, trees, 2)}
        key = 'first' if phase == 3 else 'second';other = 'second' if phase == 3 else 'first'
        wanted = list(report['baseline'][key]);wanted[0] += .5
        assert near(moved[key],wanted) and near(moved[other],report['baseline'][other]),moved
        report['checks'].append('Tree '+('1' if phase == 3 else '2')+' moves independently and updates nearby plant contacts')
        r.execute('max undo')
        root.interactionsEnsure()
        r.CyrusPointSync()
        r.completeRedraw()
        item = {'first': position(root, edit, trees, 1), 'second': position(root, edit, trees, 2),
                'error': str(root.interactionError), 'statistics': statistics(root)}
        assert not item['error'], item
        report['undo_'+str(phase)] = item
        report['status'] = 'undo_'+str(phase)+'_requested'
    elif phase == 6:
        root,trees,edit = r.TSRoot,r.TSTrees,r.TSEdit
        restored = {'first': position(root, edit, trees, 1), 'second': position(root, edit, trees, 2)}
        assert near(restored['first'],report['baseline']['first']) and near(restored['second'],report['baseline']['second']),restored
        report['checks'].append('Undo restores both independent tree positions')
        audit = json.loads(str(r.cyrusInteractionValidate(root.interactionState, 20000000)[2]))
        report['full_mesh_audit'] = audit
        assert all(x.get('penetrating_vertex_obstacle_pairs',0)==0 and x.get('touching_triangle_obstacle_pairs',0)==0 and x.get('root_anchor_error_m',0)<=1e-5 for x in audit['results']), 'Visible-mesh contact or root anchors failed'
        trial = host / 'Small_Tree_Interaction_0.87.4.1.max'
        assert r.saveMaxFile(str(trial), quiet=True)
        report['saved_scene'] = str(trial)
        report['checks'].append('Full visible contact mesh has no reported penetration or root movement and an owned trial copy is saved')
        report['status'] = 'pass' if audit['passed'] else 'needs_review'
    else:
        raise ValueError('Use phases 1 through 6')
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
else:
    report.pop('error',None)
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
