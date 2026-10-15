"""Inspect only the hash-verified owned copy of the artist's mountain scene."""
from pathlib import Path
import hashlib,json,traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-meshmask-')
receipt=json.loads((ROOT/'build/mesh-mask-0824-20261015-01/mountain/source.json').read_text())
owned=Path(receipt['owned_copy']).resolve()
assert owned.is_relative_to(ROOT/'build/mesh-mask-0824-20261015-01/mountain')
assert hashlib.sha256(owned.read_bytes()).hexdigest()==receipt['sha256']
data={'status':'started','source':receipt,'nodes':[],'scatter':[]}
def save(): (OUT/'mesh-mask-mountain-inventory.json').write_text(json.dumps(data,indent=2)+'\n')
try:
    r.CyrusPerfHeadless=True
    assert r.loadMaxFile(str(owned),quiet=True,useFileUnits=True)
    data['units']={'type':str(r.units.SystemType),'scale':float(r.units.SystemScale)}
    for node in r.objects:
        item={'name':str(node.name),'class':str(r.classOf(node.baseObject)),'modifiers':[]}
        for modifier in node.modifiers:
            info={'class':str(r.classOf(modifier)),'name':str(modifier.name)}
            if str(r.classOf(modifier))=='DataChannelModifier':
                info['operators']=[]
                for op in modifier.operators:
                    props={}
                    for key in r.getPropNames(op):
                        try: props[str(key)]=str(r.getProperty(op,key))
                        except Exception: pass
                    info['operators'].append({'class':str(r.classOf(op)),'properties':props})
            item['modifiers'].append(info)
        data['nodes'].append(item)
        if str(r.classOf(node.baseObject))=='AminScatterObject':
            root=node.baseObject;root.updateMode=1;root.autoRender=False
            group={'name':str(node.name),'layers':[]}
            for leaf in root.layerObjects:
                group['layers'].append({'id':str(leaf.layerID),'caption':str(root.layerCaption(leaf)),
                    'surfaces':[str(n.name) for n in leaf.validSurfaces()],
                    'sources':[str(n.name) if r.isValidNode(n) else str(n) for n in leaf.sources],
                    'amount':int(leaf.amount),'generated':int(leaf.generatedCount),
                    'layout':int(leaf.diversityMode),'mask':str(leaf.meshMaskPayload())})
            data['scatter'].append(group)
    receivers={str(n.name):n for node in r.objects if str(r.classOf(node.baseObject))=='AminScatterObject'
        for leaf in node.baseObject.layerObjects for n in leaf.validSurfaces()}
    if not receivers:
        receivers={str(n.name):n for n in r.objects if str(n.name).lower().startswith('plane')}
    data['receiver_channels']={}
    for name,node in receivers.items():
        mesh=r.snapshotAsMesh(node)
        details={'faces':int(mesh.numfaces),'vertices':int(mesh.numverts),'channels':[]}
        for channel in range(min(100,int(r.meshop.getNumMaps(mesh)))):
            if r.meshop.getMapSupport(mesh,channel):
                count=int(r.meshop.getNumMapVerts(mesh,channel))
                samples=[r.meshop.getMapVert(mesh,channel,i) for i in range(1,count+1)]
                details['channels'].append({'channel':channel,'vertices':count,
                    'minimum':[min(float(v[k]) for v in samples) for k in range(3)] if count else [],
                    'maximum':[max(float(v[k]) for v in samples) for k in range(3)] if count else []})
        data['receiver_channels'][name]=details
    data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise
