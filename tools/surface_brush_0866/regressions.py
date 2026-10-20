from pathlib import Path
import argparse,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--group',choices=['maps','variants'],required=True);a=p.parse_args()
assert a.host.startswith('density0862-reliability-surface0866-')
host=ROOT/'build/mcp-qualification'/a.host
steps=[('receiver_maps',[]),('elevation',[]),('edges',['--library',str(ROOT/'AminScatter/library')])] if a.group=='maps' else [
 ('presets',['--ids','formal','valley','--units','feet','--variant','transformed']),
 ('presets',['--ids','formal','--units','centimeters','--variant','folded']),
 ('presets',['--ids','valley','--units','meters','--variant','heightfield'])]
for i,(name,extra) in enumerate(steps):
 print('Starting',name,*extra,flush=True)
 r=subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools/reliability_0870'/('run_'+name+'.py')),a.host,*extra],capture_output=True,text=True)
 (host/('regression-driver-'+a.group+'-'+str(i)+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8')
 print((r.stdout+r.stderr)[-2000:] if r.returncode else name+' passed',flush=True)
 if r.returncode:sys.exit(r.returncode)
