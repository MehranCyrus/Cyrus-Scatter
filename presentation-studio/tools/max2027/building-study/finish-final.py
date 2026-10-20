import importlib.util,json,base64,hashlib,shutil,time
from pathlib import Path
s=importlib.util.spec_from_file_location('a',Path(__file__).with_name('grille-browser.py'));a=importlib.util.module_from_spec(s);s.loader.exec_module(a)
out=a.ASSETS/'final-browser-v2';out.mkdir()
before=json.loads((a.ASSETS/'final-browser-v1/before.json').read_text());old=before['project'];asset=old['assets'][0];instance=old['instances'][0]
review=a.evaluate('const r=window.__cyrusStudio.controller.replacement; JSON.stringify({asset:r.asset,suggestions:r.suggestions})');new=review['asset']
assert asset['hash']=='e006b8463f6ed02f537c4584a7749b49af5f1217aba7d01e3a79172a3efb2caa'
assert new['hash']=='d8e30599ddc541a5c6170ec1fc27fd4c52423c02e2c0c5f218624a164056727e'
byid={n.get('externalId'):n for n in asset['nodes'] if n.get('externalId')};groups={}
for n in new['nodes']:
 if not n['renderable']:
  source=byid['max-layer:'+n['name']];groups[n['key']]=instance['membership'][source['key']]
for n in new['nodes']:
 if n['renderable']:
  handle=n['externalId'].split(':')[-1];prior=byid['max-node:'+handle]
  assert prior['name']==n['name'] and prior['externalLayer']==n['externalLayer']
  assert groups[n['parent']]==instance['membership'][prior['key']]
# The new static export flattens empty wrappers and namespaces IDs. Assign its
# 16 explicit layer groups through the actual revision review controls; all
# 295 placements inherit exactly their previous resolved layer.
assigned=set()
while True:
 keys=a.evaluate('JSON.stringify([...document.querySelectorAll("[data-replacement-layer]")].map(e=>e.dataset.replacementLayer))')
 for key in keys:
  if key in groups:
   selector='[data-replacement-layer="'+key+'"]';a.browser('scrollintoview',selector);a.browser('select',selector,groups[key]);assigned.add(key)
 next=a.evaluate('const e=[...document.querySelectorAll("[data-action=uiReplacementPage]")].find(e=>e.textContent==="Next"); JSON.stringify({disabled:e.disabled,payload:e.dataset.payload})')
 if next['disabled']:break
 selector='[data-action=uiReplacementPage][data-payload="'+next['payload']+'"]';a.browser('scrollintoview',selector);a.browser('click',selector)
assert assigned==set(groups)
a.browser('scrollintoview','[data-action=uiAcceptReplacement]');a.browser('click','[data-action=uiAcceptReplacement]');a.browser('wait','--fn','window.__cyrusStudio.controller.replacement===null && !window.__cyrusStudio.controller.pending')
after=a.evaluate('const c=window.__cyrusStudio.controller; JSON.stringify({project:c.project,stats:{...c.host.stats},error:c.error})')
assert not after['error']
for field in ['id','title','layers','stops','segments','opening','revealDuration','lighting']:assert old[field]==after['project'][field],field
assert after['project']['instances'][0]['membership']==groups
assert after['project']['instances'][0]['transform']==instance['transform']
# Undo and redo the complete revision, then verify the chosen source hash.
assert a.evaluate('const c=window.__cyrusStudio.controller; await c.act("undo"); JSON.stringify({hash:c.project.assets[0].hash})')=={'hash':asset['hash']}
redo=a.evaluate('const c=window.__cyrusStudio.controller; await c.act("redo"); JSON.stringify({hash:c.project.assets[0].hash})');assert redo['hash']==new['hash']
views=[]
for seconds in [2,7,16,29,38]:
 d=a.evaluate('const c=window.__cyrusStudio.controller; await c.act("mode","playback"); await c.act("time",'+str(seconds)+');c.host.draw(); JSON.stringify({image:c.host.canvas.toDataURL("image/png"),pose:c.host.capture(),stats:{...c.host.stats}})')
 (out/f'final-{seconds:02d}.png').write_bytes(base64.b64decode(d.pop('image').split(',')[1]));views.append(dict(seconds=seconds,**d));shutil.copyfile(a.ASSETS/f'final-browser-v1/source-{seconds:02d}.png',out/f'source-{seconds:02d}.png')
a.evaluate('const c=window.__cyrusStudio.controller; await c.act("updateInstance",{id:c.project.instances[0].id,patch:{name:"BAILEY · Optimized building"}}); await c.act("time",2); JSON.stringify({ready:true})')
state=a.evaluate('const c=window.__cyrusStudio.controller; JSON.stringify({project:c.project,stats:{...c.host.stats}})');assert state['project']['instances'][0]['name']=='BAILEY · Optimized building'
(a.ASSETS/'final-presentation-v1/authoring-state.json').write_text(json.dumps(state,indent=2),encoding='utf-8')
report=dict(source=asset['hash'],final=new['hash'],matchedPlacements=295,assignedGroups=groups,presentationPreserved=True,undoRedo=True,views=views,after=after)
(out/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps({k:v for k,v in report.items() if k not in ['views','after','assignedGroups']}))
