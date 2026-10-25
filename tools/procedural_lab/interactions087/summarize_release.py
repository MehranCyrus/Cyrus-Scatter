"""Summarize retained final-package evidence without promoting CPU costs to FPS."""
from pathlib import Path
from argparse import ArgumentParser
import csv,hashlib,json,os,statistics
ROOT=Path(__file__).resolve().parents[3]
p=ArgumentParser();p.add_argument('--campaign',default='04');p.add_argument('--payload',default='04');p.add_argument('--isolated',action='store_true');a=p.parse_args()
run=ROOT/('build/interactions087-final-terraces-20261025-'+a.campaign)
rows=list(csv.DictReader((run/'moves.tsv').open(),delimiter='\t'))
summary=[]
for count in [0,10000,50000,250000]:
    initial=json.loads((run/f'phase-{count}.json').read_text())
    moves=[x for x in rows if int(x['tier'])==count]
    stats=[json.loads((run/f'{count}-move-{i}.json').read_text()) for i in range(1,9)]
    assert len(moves)==8 and all(not x['error'] for x in stats)
    assert [x['generation'] for x in stats]==list(range(2,10))
    assert len({x['epoch'] for x in moves})==len({x['builds'] for x in moves})==1
    summary.append({'tier':count,'plants':initial['statistics']['plants'],'update_seconds':initial['update_seconds'],
        'initial_fit_ms':initial['statistics']['fit_ms'],
        'command_median_ms':statistics.median(float(x['command_ms'].replace('d0','')) for x in moves),
        'command_worst_ms':max(float(x['command_ms'].replace('d0','')) for x in moves),
        'redraw_median_ms':statistics.median(float(x['redraw_ms'].replace('d0','')) for x in moves),
        'fit_median_ms':statistics.median(x['fit_ms'] for x in stats),
        'preview_median_ms':statistics.median(x['preview_ms'] for x in stats),
        'affected_min_max':[min(x['affected'] for x in stats),max(x['affected'] for x in stats)],
        'initial_private_bytes':initial['private_bytes'],'initial_peak_working_set_bytes':initial['peak_working_set_bytes']})
payload=ROOT/('build/interactions087-final-payload-20261025-'+a.payload)
for name in ['interactions087-final-terraces-20261025-'+a.campaign,'interactions087-final-render-20261025-'+a.campaign]:
    host=ROOT/'build'/name;receipt=json.loads((host/'receipt.json').read_text());identity=json.loads((host/'loaded-identity.json').read_text())
    assert receipt['status']=='pass' and receipt['artist_ini_unchanged'] and receipt['exit_code']==0
    for module in ['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']:
        assert identity['modules'][module]['sha256']==hashlib.sha256((payload/module).read_bytes()).hexdigest()
    assert receipt['payload_script_sha256']==hashlib.sha256((payload/'CyrusScatter.ms').read_bytes()).hexdigest()
audit=json.loads((ROOT/('build/interactions087-final-render-20261025-'+a.campaign)/'delivery-audit.json').read_text())['delivery_audit']
assert audit['penetrating_vertex_obstacle_pairs']==audit['touching_triangle_obstacle_pairs']==0
source=ROOT/'Test Scene/Terraces_Final.max';original=hashlib.sha256(source.read_bytes()).hexdigest()
assert original=='69ff41356a5312dba7841bc47bbe49b6ce77a8ca79168fd045c8c17c618a8378'
artist=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
assert hashlib.sha256(artist.read_bytes()).hexdigest()=='6579ecf2ecd5004b6d4bf955b73fcf91cf5392afda9425da9311d42720d87a2c'
scope=('The terrace campaign ran separately from our native builds, audits and other Max qualification hosts.' if a.isolated else 'Separate owned Max processes overlapped during this run; use isolated fixed-input measurements for performance comparisons.')
result={'status':'pass','scope':'Exact packaged payload, 32 native command moves. CPU timings and synchronous redraw; not presented FPS. '+scope+' Local densities differ between tiers; these are not an equal-density scaling benchmark.',
    'tiers':summary,'delivery_audit':audit,'original_scene_sha256':original,'artist_ini_unchanged':True}
(run/'statistics-summary.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
