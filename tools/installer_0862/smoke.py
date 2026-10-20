"""Check final installed assets and selected-terrain workflows after restart."""
from pathlib import Path
import argparse,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import ready,send
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--resume-panels',action='store_true');a=p.parse_args();assert a.host.startswith('density0862-installer-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host);meta=json.loads((host/'launch.json').read_text());assert not meta['startup_filein_product']
if not a.resume_panels:
 send(host,ROOT/'tools/density_0862/initial.ms','Final installed density smoke')
 r=subprocess.run([sys.executable,'tools/density_0862/run_campaign.py',a.host,'workflow','--year',str(meta['max_year']),'--library',str(Path(meta['installed_release'])/'Library-0.86.2')],cwd=ROOT,capture_output=True,text=True)
 (host/'final-workflow.log').write_text(r.stdout+r.stderr);assert r.returncode==0,(r.stdout+r.stderr)[-2500:]
else:assert 'PASS campaign workflow' in (host/'final-workflow.log').read_text()
# Workflow tests switch owners/scenes. Mount the panel fixture's current DRoot
# before inspecting its controls rather than retaining a destroyed prior owner.
r=subprocess.run([sys.executable,'tools/density_0862/run_layout.py',a.host],cwd=ROOT,capture_output=True,text=True)
(host/'final-layout.log').write_text(r.stdout+r.stderr);assert r.returncode==0,(r.stdout+r.stderr)[-2500:]
send(host,ROOT/'tools/ui_polish_0862/panel_contract.ms','Final installed panel contract')
script=host/'verify-runtime.ms';script.write_text('python.executeFile @"'+(ROOT/'tools/installer_0862/verify_runtime.py').as_posix()+'"',encoding='utf-8-sig');send(host,script,'Final installed asset identities')
(host/'final-smoke.json').write_text(json.dumps({'status':'passed','initial_density':True,'selected_terrain_workflow':True,'panel_contract':True,'installed_assets':True},indent=2)+'\n');print('PASS: final installed smoke',flush=True)
