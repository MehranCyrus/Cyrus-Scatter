"""Serial owned-host acceptance; each product fixture retains its own detailed log."""
from pathlib import Path
import argparse,hashlib,json,subprocess,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('--after-capture',action='store_true');a=p.parse_args();folder=a.profile.resolve()
assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-gallery0851-')
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
out=folder/('acceptance-suite-'+uuid.uuid4().hex+'.json')
result={'status':'running','launch':json.loads((folder/'launch.json').read_text(encoding='utf-8')),'steps':[]}
def save():out.write_text(json.dumps(result,indent=2),encoding='utf-8')
def run(name):
 fixture=ROOT/'tools/gallery_0851'/name;start=time.monotonic();prior={x.name for x in folder.iterdir()};print('Testing',name,flush=True)
 done=subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(fixture),'--timeout','180'],capture_output=True,text=True)
 result['steps'].append({'fixture':name,'fixture_sha256':sha(fixture),'seconds':time.monotonic()-start,'exit_code':done.returncode,'transport':done.stdout+done.stderr,'new_evidence':[x.name for x in folder.iterdir() if x.name not in prior]});save()
 if done.returncode:raise RuntimeError(done.stdout+done.stderr)
def package():
 run('package_bitmap_export.ms');time.sleep(.5);run('package_export_verify.ms')
try:
 if not a.after_capture:
  for name in ['preset_noop.ms','curve_presets.ms','style.ms','style_boundaries.ms','package_mesh_fidelity.ms','persistence.py','capture_lifecycle.ms']:run(name)
 for name in ['capture_boundaries.py','capture_import.ms']:run(name)
 package();run('package_bitmap_import.ms');run('package_bitmap_render.ms')
 package();run('package_bitmap_boundaries.ms')
 package();run('package_share.ms')
 package();run('package_preparation.ms')
 run('recipe_pressure.ms')
 result['status']='passed';save();print('PASS',out,flush=True)
except Exception as error:
 result['status']='failed';result['error']=str(error);save();raise
