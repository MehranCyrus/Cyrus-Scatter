"""Read-only whole preview fingerprint; all authored commands live in MAXScript."""
from pymxs import runtime as r
import hashlib,struct
m=r.snapshotAsMesh(r.CPLMountainLab);h=hashlib.sha256();h.update(struct.pack('<II',int(m.numverts),int(m.numfaces)))
for i in range(1,int(m.numverts)+1):h.update(struct.pack('<fff',*list(r.getVert(m,i))))
for i in range(1,int(m.numfaces)+1):h.update(struct.pack('<III',*(int(x) for x in r.getFace(m,i))))
r.CPLMountainMeshFingerprint=h.hexdigest()
