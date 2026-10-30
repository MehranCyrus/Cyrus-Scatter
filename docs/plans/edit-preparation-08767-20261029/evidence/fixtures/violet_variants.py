from pathlib import Path
import json,subprocess
r=Path.cwd()/'build/edit-size-review-20261029-01';p=r/'violet-native';b=json.loads((p/'baseline.json').read_text());stem=[g['component'] for g in b['definition']['metadata']['guides']];leaves=[x['part'] for x in b['parts'] if x['material'] in (1,2,3)];flowers=[x['part'] for x in b['parts'] if x['material'] in (4,5,6,7)]
for name,rows in [('stem-detail',[{'part':i,'role':1,'profile':1,'points':16} for i in stem]),('leaf-detail',[{'part':i,'role':1,'profile':2,'points':9,'parent':-1} for i in leaves]),('combined',[*[{'part':i,'role':1,'profile':1,'points':16} for i in stem],*[{'part':i,'role':1,'profile':2,'points':9,'parent':-1} for i in leaves],*[{'part':i,'role':2,'profile':3} for i in flowers]])]:
 intent=p/(name+'-intent.json');intent.write_text(json.dumps({'version':2,'fingerprint':b['fingerprint'],'parts':rows}))
 subprocess.run([str(p/'violet_inspect.exe'),str(r/'violet-baseline/violet-0.bin'),str(p/(name+'.json')),str(intent)],check=True)
 x=json.loads((p/(name+'.json')).read_text());d=x.get('definition',{});print(name,{'status':x.get('status'),'error':x.get('error'),'bytes':x.get('bytes'),'report':d.get('report',x.get('report')),'guide_points':[(g['component'],len(g['nodes'])) for g in d.get('metadata',{}).get('guides',[])]})
print('pieces',len(stem),len(leaves),len(flowers))
