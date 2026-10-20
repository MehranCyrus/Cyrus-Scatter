"""Replay copied actual-scene births through the qualified native world; no Max UI."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'CyrusPhysicsLab/tools'))
import build
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--build',type=Path,required=True);p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
 a=p.parse_args();native=a.build.resolve();out=a.output.resolve()
 if not out.is_relative_to(ROOT/'build'):p.error('Use an owned build output')
 out.mkdir(exist_ok=False);env=build.compiler_environment();src=Path(__file__).with_name('contact_trace.cpp')
 cmd=[shutil.which('cl.exe',path=env['PATH']),'/nologo','/std:c++20','/O2','/MD','/EHsc','/DNOMINMAX','/I'+str(ROOT/'CyrusPhysicsLab/include'),'/I'+str(ROOT/'CyrusLicensing/third_party'),str(src),str(native/'cpl_core.lib'),str(native/'jolt/Jolt.lib'),'/Fe:'+str(out/'trace.exe'),'/Fo:'+str(out/'trace.obj')]
 with (out/'compile.log').open('w') as log:subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
 records=[]
 for result in sorted(a.input.glob('*-result.json')):
  case=result.stem.removesuffix('-result');dest=out/(case+'.json')
  with (out/(case+'.log')).open('w') as log:proc=subprocess.run([str(out/'trace.exe'),str(result.resolve()),str(dest)],stdout=log,stderr=subprocess.STDOUT)
  j=json.loads(dest.read_text());row={k:j[k] for k in ('bodies','ever_left','wholly_below','interior_tunnel','final_vertex_depth_m','final_normal_depth_m','sleeping_normal_depth_m','published_vertical_depth_m','published_normal_depth_m','sleeping','contact_distance_m')}
  row.update(case=case,input_sha256=sha(result),trace_sha256=sha(dest),returncode=proc.returncode)
  row['minimum_birth_gap_m']=min((b['minimum_vertex_gap_m'] for b in j['birth_support']),default=0)
  row['pass']=proc.returncode==0 and not j['interior_tunnel'] and j['final_normal_depth_m']<.01 and row['minimum_birth_gap_m']>=.001
  records.append(row);print(case,row,flush=True)
 report={'pass':len(records)==5 and all(r['pass'] for r in records),'source_sha256':sha(src),'core_library_sha256':sha(native/'cpl_core.lib'),'cases':records}
 (out/'receipt.json').write_text(json.dumps(report,indent=2)+'\n')
 if not report['pass']:raise SystemExit(1)
if __name__=='__main__':main()
