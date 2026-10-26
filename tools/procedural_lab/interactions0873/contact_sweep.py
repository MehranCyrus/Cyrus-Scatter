"""Replay captured artist geometry through the numeric kernel, keeping every outcome."""
from pathlib import Path
import argparse,json,subprocess,time,hashlib
p=argparse.ArgumentParser();p.add_argument('--exe',required=True,type=Path);p.add_argument('--fixture',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
a.output.mkdir(parents=True,exist_ok=False);base=json.loads(a.fixture.read_text());base['audit']=False
identity=[1,0,0,0,1,0,0,0,1,0,0,0]
base['instances']=[{'layer':0,'source':0,'identity':'c:1','transform':identity[:]}, {'layer':1,'source':0,'identity':'c:1','transform':identity[:]}]
report={'exe':str(a.exe.resolve()),'exe_sha256':hashlib.sha256(a.exe.read_bytes()).hexdigest(),'cases':[]}
for x,z in [(x,z) for x in [12,18,22,26] for z in [0,4,8,12,18,24]]:
    base['instances'][1]['transform'][-3:]=[x,0,z];path=a.output/f'case-{x}-{z}.json';path.write_text(json.dumps(base));start=time.perf_counter()
    try:
        run=subprocess.run([str(a.exe.resolve()),'--fixture',str(path.resolve()),'0'],capture_output=True,text=True,timeout=45)
        (a.output/f'case-{x}-{z}.log').write_text(run.stdout+run.stderr)
        item={'x_cm':x,'z_cm':z,'exit':run.returncode,'seconds':time.perf_counter()-start,'fixture':str(path.resolve())}
        if run.returncode:item['error']=run.stderr.strip();print(json.dumps(item),flush=True)
        else:item['result']=json.loads(run.stdout)
    except subprocess.TimeoutExpired:item={'x_cm':x,'z_cm':z,'timeout':True}
    report['cases'].append(item);(a.output/'report.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'cases':len(report['cases']),'failures':sum(bool(x.get('exit',1)) for x in report['cases'])}))
