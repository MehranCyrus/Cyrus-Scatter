"""Collect immutable product identities and observed lifecycle receipts."""
from pathlib import Path
import hashlib,json,shutil

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'docs/Point_Workflow_0.79.1_2026-10-11'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

evidence=dict(product_modified=False,baseline_commit='15957a66de0480679dea6c533c7c5d09d9598d54',
              hosts={},fixture_errors=[],qualification='Investigation: confirmed Manual cache defect; Live picker report remains open.')
for year in (2026,2027):
    folder=ROOT/f'build/mcp-qualification/refine0791-layer{year}-01'
    host=dict(launch=read(folder/'launch.json'),loaded_modules=(folder/'loaded.tsv').read_text(encoding='utf-8'),
              lifecycle=read(folder/'layer-lifecycle.json'),cache=read(folder/'layer-cache-probe.json'),
              point_model=read(folder/'point-model-probe.json'),
              undo=[read(folder/f'layer-undo-{phase}.json') for phase in ('prepare','delete','undo','redo')])
    if any(host[k]['errors'] for k in ('lifecycle','cache','point_model')):raise RuntimeError('Unresolved fixture failure')
    if not all(phase['passed'] for phase in host['undo']):raise RuntimeError('Undo/Redo assertion failed')
    host['manual_add_errors']=[dict(case=c['name'],stage=s['label'],errors=[l['error'] for l in s['layers']])
                               for c in host['lifecycle']['cases'] for s in c['snapshots'] if any(l['error'] for l in s['layers'])]
    host['warm_reuse']=[dict(stage=s['label'],epoch=s['epoch'],preview_builds=[l['builds'] for l in s['layers']],
                              publication_revision=s['retained'][2],prepares=s['retained'][3],uploads=s['retained'][5])
                        for s in host['cache']['cases'][-1]['snapshots'][-4:]]
    installed=Path(f'C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/{year} - 64bit/ENU/scripts/CyrusScatter/CyrusScatter.ms')
    host['installed_script_sha256']=sha(installed)
    evidence['hosts'][str(year)]=host
    evidence['fixture_errors'].append(dict(host=year,kind='listbox selected property shadows event',
                                           original=read(folder/'layer-lifecycle-fixture-error.json')['errors']))
folder=ROOT/'build/mcp-qualification/refine0791-layer2027-01'
evidence['artist']=read(folder/'artist-layer-probe.json')
evidence['artist_input']=read(folder/'artist-layering-input.json')
evidence['artist_input']['sha256_after']=sha(Path(evidence['artist_input']['path']))
if evidence['artist']['errors']:raise RuntimeError('Artist fixture error')
if evidence['artist_input']['sha256']!=evidence['artist_input']['sha256_after']:raise RuntimeError('Original scene changed')
evidence['fixture_errors'].append(dict(kind='pymxs function wrapper did not preserve the replaced global function',
    symptom='Synthetic held-input gate remained true after attempted restoration; this was fixture behavior, not a product defect.',
    corrected='Stored/restored the function value inside MAXScript; repeated artist probe passed release scheduling.',
    raw_receipt=str(folder/'artist-layer-held-fixture-error.json')))
evidence['source_sha256']=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
evidence['fixtures']={p.name:sha(p) for p in Path(__file__).parent.glob('*probe*') if p.is_file()}
evidence['fixtures']['layer_lifecycle.py']=sha(Path(__file__).with_name('layer_lifecycle.py'))
watcher=Path(__file__).with_name('watch_layer_sources.ms')
watcher_log=Path((folder/'watcher-test.txt').read_text(encoding='utf-8').strip())
watcher_text=watcher_log.read_text(encoding='utf-8')
if 'RECORDER ERROR' in watcher_text:raise RuntimeError('Passive recorder failed')
evidence['fixtures'][watcher.name]=sha(watcher)
evidence['passive_recorder']=dict(private_test=True,artist_session_started=False,
    log_path=str(watcher_log),log_sha256=sha(watcher_log),log=watcher_text,
    limit='State sampling may miss intermediate states inside blocking modal interactions.')
(DEST/'layer-investigation-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
images=DEST/'layer-investigation-images';images.mkdir(exist_ok=True)
for name in ('02-point-second-receiver.png','03-add-model-to-point.png','artist-04-second-point-added.png'):
    shutil.copy2(folder/name,images/name)
print(json.dumps(dict(hosts=list(evidence['hosts']),original_preserved=True,
                      endpoint_assertions={y:len(h['lifecycle']['assertions']) for y,h in evidence['hosts'].items()},
                      manual_error_stages={y:len(h['manual_add_errors']) for y,h in evidence['hosts'].items()})))
