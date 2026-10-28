"""Author a reproducible small branching mesh; preparation still runs in Max."""
from pathlib import Path
import math
root=Path(__file__).resolve().parents[3]
vertices=[];faces=[]
def tube(start,end,radius):
    delta=[end[i]-start[i] for i in range(3)];length=math.sqrt(sum(v*v for v in delta));axis=[v/length for v in delta]
    helper=[0,1,0] if abs(axis[1])<.8 else [1,0,0]
    side=[axis[1]*helper[2]-axis[2]*helper[1],axis[2]*helper[0]-axis[0]*helper[2],axis[0]*helper[1]-axis[1]*helper[0]]
    n=math.sqrt(sum(v*v for v in side));side=[v/n for v in side];up=[axis[1]*side[2]-axis[2]*side[1],axis[2]*side[0]-axis[0]*side[2],axis[0]*side[1]-axis[1]*side[0]]
    base=len(vertices);rings=7;sides=6
    for ring in range(rings):
        t=ring/(rings-1)
        for j in range(sides):
            angle=j*2*math.pi/sides
            vertices.append([start[i]+delta[i]*t+radius*(math.cos(angle)*side[i]+math.sin(angle)*up[i]) for i in range(3)])
    for ring in range(rings-1):
        for j in range(sides):
            a=base+ring*sides+j;b=base+ring*sides+(j+1)%sides;faces.extend([[a+1,b+1,b+sides+1],[a+1,b+sides+1,a+sides+1]])
    for j in range(1,sides-1):faces.extend([[base+1,base+j+2,base+j+1],[base+(rings-1)*sides+1,base+(rings-1)*sides+j+1,base+(rings-1)*sides+j+2]])
tube((0,0,0),(0,0,2),.05)
for i,z in enumerate((.45,.8,1.15,1.5)):
    angle=i*1.7
    tube((0,0,z),(math.cos(angle)*.8,math.sin(angle)*.8,z+.45),.018)
def arr(values):return '#('+','.join('['+','.join(str(round(v,7)) for v in row)+']' for row in values)+')'
script='''-- Generated metre-authored branch tree, converted to current system units.
global ADTree
(
 local metre=units.decodeValue "1m"
 local vertices=VERTICES
 vertices=for p in vertices collect p*metre
 ADTree=mesh name:"AD_Branch_Tree" vertices:vertices faces:FACES
 ADTree.wirecolor=(color 85 145 65)
 ADTree
)
'''.replace('VERTICES',arr(vertices)).replace('FACES',arr(faces))
path=root/'tools/procedural_lab/adaptation08754/tree_generated.ms';path.write_text(script,encoding='utf-8')
print(f'{len(vertices)} vertices / {len(faces)} faces: {path}')
