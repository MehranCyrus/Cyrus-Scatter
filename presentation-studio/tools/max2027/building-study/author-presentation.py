"""Author the owned building presentation through the studio and its import UI."""
from pathlib import Path
import importlib.util
import hashlib
import json
import base64

spec=importlib.util.spec_from_file_location('building_browser',Path(__file__).with_name('building-browser.py'))
api=importlib.util.module_from_spec(spec);spec.loader.exec_module(api)
browser,evaluate=api.browser,api.evaluate
out=api.ASSETS/'presentation-views';out.mkdir(exist_ok=True)
asset_hash=hashlib.sha256((api.ASSETS/'building-support-creases-e0003-context-v5.glb').read_bytes()).hexdigest()
state=evaluate('JSON.stringify({hash:window.__cyrusStudio.controller.project.assets[0]?.hash})')
if state.get('hash')!=asset_hash:raise RuntimeError('Expected candidate is not active; import and inspect it first.')
names={
    '020_ Exterior ':'Site and streets','030_ Landscape':'Landscape geometry','034-1 - Pavement Curb':'Pavement and kerbs','036-Neighbors':'Neighbouring massing',
    '065_shop':'Retail frontage','100-Win':'Windows and doors','200-Glass':'Glazing','300-Walls':'Building structure','400-Green':'Landscape edges',
    '500-Fance':'Balconies and bridges','600-objects':'Interior fixtures','700-Light Box':'Light boxes','AC_3D MODEL':'Mechanical details','Fance-Peoxy':'Fine metal screens',
    'Objects Street':'Street furniture','scatterobjects':'Secondary details',
}
script="""const c=window.__cyrusStudio.controller,names=NAMES;
await c.act('updateProject',{title:'BAILEY · Architecture in motion',opening:0,revealDuration:2,lighting:{exposure:.8,shadows:true,style:'architectural'}});
for(const layer of [...c.project.layers])await c.act('updateLayer',{id:layer.id,patch:{name:names[layer.name]??layer.name,reveal:.12,viewerToggle:['036-Neighbors','600-objects','Objects Street','030_ Landscape'].includes(layer.name),defaultVisible:!['036-Neighbors','600-objects'].includes(layer.name)}});
JSON.stringify({project:c.project.id,layers:c.project.layers.length});
""".replace('NAMES',json.dumps(names))
evaluate(script)
browser('upload','#file-camera',str(api.ASSETS/'building-hero.camera.json'))
browser('wait','--fn','Boolean(window.__cyrusStudio.controller.cameraImport)')
browser('click','[data-testid="confirm-camera-animation"]')
browser('wait','--fn','window.__cyrusStudio.controller.cameraImport === null && Boolean(window.__cyrusStudio.controller.project.segments[0]?.cameraClip)')
evaluate("const c=window.__cyrusStudio.controller; await c.act('updateStop',{id:c.project.stops[0].id,patch:{name:'Architecture in motion'}}); await c.act('updateStop',{id:c.project.stops[1].id,patch:{name:'The final composition'}}); await c.act('mode','playback'); JSON.stringify({ready:true})")
rows=[]
for seconds in [0,5,10,14,18,23,27,31,36]:
    data=evaluate('const c=window.__cyrusStudio.controller; await c.act("time",'+str(seconds+2)+');c.host.draw(); JSON.stringify({image:c.host.canvas.toDataURL("image/png"),pose:c.host.capture(),stats:{...c.host.stats}})')
    (out/f'camera-{seconds:02d}s.png').write_bytes(base64.b64decode(data.pop('image').split(',')[1]));rows.append(dict(sourceSeconds=seconds,presentationSeconds=seconds+2,**data))
evaluate('const c=window.__cyrusStudio.controller;await c.act("time",2); JSON.stringify({project:c.project,stats:{...c.host.stats}})')
(out/'capture-receipt.json').write_text(json.dumps(rows,indent=2)+'\n')
browser('screenshot',str(out/'studio-camera-imported.png'))
print(json.dumps(dict(cameraDuration=36,introSeconds=2,framesCaptured=len(rows),assetSha256=asset_hash)))
