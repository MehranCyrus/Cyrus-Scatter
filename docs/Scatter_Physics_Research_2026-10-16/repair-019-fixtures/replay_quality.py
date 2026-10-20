"""Native 0.1.9 replay: nine model cases, two palettes and the retired-palette regression."""
from pathlib import Path
import argparse,sys,subprocess,shutil,json,hashlib
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'CyrusPhysicsLab/tools'))
import build

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 p=argparse.ArgumentParser();p.add_argument('--build',type=Path,required=True);p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 native=a.build.resolve();source=a.input.resolve();out=a.output.resolve()
 assert out.is_relative_to(ROOT/'build');out.mkdir(exist_ok=False)
 env=build.compiler_environment();compiler=shutil.which('cl.exe',path=env['PATH']);here=Path(__file__).parent.parent/'quality-fixtures'
 for name,src in [('fit',here/'fit_metrics.cpp'),('trace',here.parent/'mountain-fixtures/contact_trace.cpp')]:
  command=[compiler,'/nologo','/std:c++20','/O2','/MD','/EHsc','/DNDEBUG','/DNOMINMAX','/I'+str(ROOT/'CyrusPhysicsLab/include'),'/I'+str(ROOT/'CyrusLicensing/third_party'),'/I'+str(ROOT/'build/physics-lab-dependencies/jolt-1b2e77e3c6c09709e5edc79dc208459b8ff32051'),str(src),str(native/'cpl_core.lib'),str(native/'jolt/Jolt.lib'),'/Fe:'+str(out/(name+'.exe')),'/Fo:'+str(out/(name+'.obj'))]
  with (out/(name+'-compile.log')).open('w') as log:subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
 with (out/'fit.log').open('w') as log:subprocess.run([str(out/'fit.exe'),str(source),str(out/'fit.json')],stdout=log,stderr=subprocess.STDOUT,check=True)
 rows=[]
 for path in sorted([*source.glob('*_q*-result.json'),*source.glob('palette-*-result.json')]):
  target=out/(path.stem+'-trace.json')
  with (out/(path.stem+'-trace.log')).open('w') as log:proc=subprocess.run([str(out/'trace.exe'),str(path),str(target)],stdout=log,stderr=subprocess.STDOUT)
  result=json.loads(target.read_text());row={key:result[key] for key in ('bodies','ever_left','wholly_below','interior_tunnel','final_vertex_depth_m','final_normal_depth_m','published_vertical_depth_m','published_normal_depth_m','sleeping','contact_distance_m')};row['case']=path.stem;row['input_sha256']=sha(path);row['returncode']=proc.returncode;rows.append(row);print(row,flush=True)
 fit=json.loads((out/'fit.json').read_text());palette=json.loads((source/'palette-sphere-result.json').read_text());mixed=json.loads((source/'palette-mixed-result.json').read_text())
 assert set(r['source'] for r in palette['rows'])=={1},'Unchecked source emitted'
 assert set(r['source'] for r in mixed['rows'])=={0,1,2},'Mixed brush did not include all enabled sources'
 report={'source_hashes':{f.name:sha(f) for f in here.glob('*') if f.is_file()},'core_library_sha256':sha(native/'cpl_core.lib'),'fit':fit,'cases':rows,'palette_sphere_only':True,'palette_mixed_all_three':True,'no_interior_tunnels':len(rows)==12 and all(not r['interior_tunnel'] and r['returncode']==0 for r in rows)}
 (out/'receipt.json').write_text(json.dumps(report,indent=2)+'\n')
 assert report['no_interior_tunnels'],'Replay count or interior tunnel failure'
 extra=next(v for v in rows if v['case']=='palette-final-result')
 assert extra['final_normal_depth_m']<.01,'Valid compound dynamics regressed in the retired-palette replay'
if __name__=='__main__':main()
