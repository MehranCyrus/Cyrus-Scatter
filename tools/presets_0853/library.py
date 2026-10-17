"""Build ready packages from owned copies of all eight original example scenes.

Runs inside the owned Max process. Opening and capture are separate requests so
Max can finish file-open before entering the recipe/package command.
"""
from pathlib import Path
import json, time, traceback, hashlib
import pymxs
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-presets0853-')
BASE = ROOT / 'build/presets-0853-20261016-01'
library = BASE / 'library'
command = json.loads((OUT / 'command.json').read_text(encoding='utf-8'))
index = json.loads((library / 'inventory.json').read_text(encoding='utf-8'))
entry = next(e for e in index['entries'] if e['id'] == command['id'])
log = {'id': entry['id'], 'phase': command['phase'], 'status': 'running'}
receipt = OUT / ('library-' + entry['id'] + '-' + command['phase'] + '.json')

def save():
    receipt.write_text(json.dumps(log, indent=2), encoding='utf-8')

try:
    with pymxs.undo(False):
        r.CyrusPerfHeadless = True
        if command['phase'] == 'open':
            assert r.loadMaxFile(str(library / entry['scene']), quiet=True, useFileUnits=True)
        else:
            assert not r.theHold.Holding()
            root = next(n.baseObject for n in r.objects if str(r.classOf(n.baseObject)) == 'AminScatterObject')
            original = library / entry['recipe']
            info = r.cyrusRecipeInfo(str(original))
            document = r.cyrusRecipeRead(str(original))
            bindings = r.CyrusRecipeSuggestBindings(root, document)
            assert all(pair[1] is not None for pair in bindings), 'Unresolved original example role'
            r.CyrusRecipeValidateBindings(root, document, bindings)
            before = str(r.cyrusRecipeContentFingerprint(document))
            metadata = r.CyrusRecipeObject(r.Array(r.Array('category', info[4]), r.Array('tags', info[5]), r.Array('description', info[6])))
            digest = str(r.cyrusRecipeEntryWrite(str(original), document, metadata, str(r.cyrusRecipeThumbnail(str(original))), None, str(info[10]), False))
            assert str(r.cyrusRecipeContentFingerprint(r.cyrusRecipeRead(str(original)))) == before
            stage = r.CyrusAssetOwnStage()
            graph, files = r.CyrusAssetCapture(root, str(original), digest, bindings, stage[0], includeContext=True)
            assert len(r.CyrusRecipeGet(graph, 'externalRoles')) == 0
            directory = Path(str(r.CyrusPresetPackageDirectory(str(original), digest)))
            directory.parent.mkdir(parents=True, exist_ok=True)
            job = r.cyrusAssetPackageStart(str(directory), str(original), digest, graph, files,
                                           'Original Cyrus procedural demonstration assets; redistribution permitted.', 1)
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                state = r.cyrusAssetPackagePoll(job)
                if str(state[0]) != 'exporting':
                    break
                time.sleep(.05)
            assert str(state[0]) == 'complete', str(state)
            r.CyrusAssetRemoveStage(stage)
            package = r.cyrusAssetPackageRead(str(directory))
            log.update(package=str(directory), recipe_sha256=digest, authored_fingerprint=before,
                       nodes=len(r.CyrusRecipeGet(graph, 'nodes')), splines=len(r.CyrusRecipeGet(graph, 'splines')),
                       files=len(r.CyrusRecipeGet(graph, 'files')), saved_units=float(r.CyrusRecipeGet(document, 'unitsPerMetre')),
                       original_scene_sha256=hashlib.sha256((library / entry['scene']).read_bytes()).hexdigest())
        log['status'] = 'passed'
        save()
except Exception:
    log['status'] = 'failed'
    log['error'] = traceback.format_exc()
    save()
    raise
