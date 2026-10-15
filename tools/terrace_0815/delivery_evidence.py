"""Record the final artifact hashes and preserved inputs after host completion."""
from pathlib import Path
import hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/terrace-0815-20261013-01'
HOST=ROOT/'build/mcp-qualification/foundation-terrace0815-candidate2027-04'
SCENES=ROOT/'Test Scene/Terraces_0815'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as stream:
        for block in iter(lambda:stream.read(8*1024*1024),b''):h.update(block)
    return h.hexdigest()
baseline=read(OUT/'baseline.json');original=Path(baseline['original_scene'])
assert sha(original)==baseline['original_sha256'],'Original scene changed'
acceptance=read(HOST/'garden-final-acceptance.json');render=read(HOST/'garden-final-render.json')
assert acceptance['status']==render['status']=='complete'
assert all(c['passed'] for c in acceptance['checks'])
assert render['reopen_fingerprints_match'] and render['fingerprints_unchanged_after_render'] and not render['render_error']
packages=[read(OUT/f'package-{year}.json') for year in [2026,2027]]
for p in packages:assert sha(Path(p['package']))==p['sha256']
for p in packages:
    launch=read(Path(p['host'])/'launch.json')
    assert sha(Path(launch['profile_template']))==launch['profile_template_sha256']
    assert sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==launch['script_sha256']
artifacts={}
for name in ['Terraces_0815_Final.max','Terraces_0815_Final.png','OPEN_THIS_SCENE.txt']:
    path=SCENES/name;assert path.is_file()
    artifacts[name]={'path':str(path),'bytes':path.stat().st_size,'sha256':sha(path)}
data={'original_scene_unchanged':True,'original_scene_sha256':baseline['original_sha256'],'normal_profiles_unchanged':True,'artifacts':artifacts,'packages':[{'path':p['package'],'sha256':p['sha256'],'installed':False} for p in packages],'accepted_placements':acceptance['total_accepted'],'camera':render['camera'],'render_seconds':render['render_seconds'],'render_receipt':str(HOST/'garden-final-render.json'),'acceptance_receipt':str(HOST/'garden-final-acceptance.json'),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'tracked_diff':subprocess.check_output(['git','diff','--name-only'],cwd=ROOT,text=True).splitlines(),'untracked':subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines(),'website_published':False,'committed_or_pushed':False}
(OUT/'delivery.json').write_text(json.dumps(data,indent=2)+'\n')
print(json.dumps({k:data[k] for k in ['original_scene_unchanged','normal_profiles_unchanged','accepted_placements','render_seconds','artifacts']},indent=2))
