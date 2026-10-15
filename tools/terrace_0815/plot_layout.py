"""Plot measured terrace footprints and the unchanged hero camera."""
from pathlib import Path
import json
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/mcp-qualification/foundation-terrace0815-candidate2027-03'
data=json.loads((OUT/'scene-layout-data.json').read_text())
fig,(ax,cam)=plt.subplots(1,2,figsize=(18,9))
pos=np.array([-8947.1914,-4304.0986,-661.7103]);right=np.array([.566406,-.824127,-1.37836e-7]);up=np.array([-.00719181,-.00494293,.999962]);forward=np.array([.824095,.566385,.00872675])
for i,item in enumerate(data['receivers']):
    v=np.array(item['vertices']);f=np.array(item['faces'],dtype=int)-1
    color=plt.cm.tab20(i)
    ax.add_collection(PolyCollection(v[f,:2]/100,facecolors=[color],edgecolors='none',alpha=.6))
    p=v.mean(axis=0);ax.text(p[0]/100,p[1]/100,item['name'].replace('surf_terrace_','T').replace('surf_',''))
    d=v-pos;depth=d@forward;ok=(depth[f]>100).all(axis=1)
    xy=np.stack((d@right/depth/np.tan(np.pi/8),d@up/depth/np.tan(np.pi/8)*16/9),axis=1)
    cam.add_collection(PolyCollection(xy[f[ok]],facecolors=[color],edgecolors='none',alpha=.6))
for g in data['guides']:
    if g['name']=='spl-path':
        p=np.array(g['curves'][0]['knots']);ax.plot(p[:,0]/100,p[:,1]/100,'k.-',linewidth=2,label='Existing path')
        d=p-pos;depth=d@forward;cam.plot(d@right/depth/np.tan(np.pi/8),d@up/depth/np.tan(np.pi/8)*16/9,'k.-')
ax.scatter(pos[0]/100,pos[1]/100,c='red',marker='^',s=80,label='PhysCamera002')
for sign in [-1,1]:
    v=forward[:2]+sign*np.tan(np.pi/8)*right[:2];p=pos[:2]+v*18000;ax.plot([pos[0]/100,p[0]/100],[pos[1]/100,p[1]/100],'r--')
ax.autoscale();ax.set_aspect('equal');ax.legend();ax.set_xlabel('World X (m)');ax.set_ylabel('World Y (m)');ax.set_title('Real receiver footprints')
cam.set_xlim(-1,1);cam.set_ylim(-1,1);cam.set_aspect(9/16);cam.set_title('PhysCamera002 — terrace regions');cam.grid(alpha=.2)
fig.tight_layout();fig.savefig(OUT/'scene-layout.png',dpi=140)
