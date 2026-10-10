global RGLayer,RGMat,RGBox,RGCurve,RGEllipse,RGFill,RGStem,RGRock
fn RGLayer label=(local l=LayerManager.getLayerFromName label;if l==undefined do l=LayerManager.newLayerFromName label;l)
fn RGMat label rgb rough:0.45=(CoronaLegacyMtl name:label colorDiffuse:rgb levelReflect:0.2 reflectGlossiness:rough)
fn RGBox label p w d h mat rounded:0 group:"02 Seating and water" = (
 local n=if rounded>0 then chamferbox name:label width:w length:d height:h fillet:rounded filletSegments:3 pos:p material:mat else box name:label width:w length:d height:h pos:p material:mat
 (RGLayer group).addNode n;n
)
fn RGCurve label pts = (
 local s=splineShape name:label;addNewSpline s
 for p in pts do addKnot s 1 #corner #line p
 close s 1;updateShape s;s.renderable=false;s.wirecolor=color 239 173 80;(RGLayer "04 Editable area guides").addNode s;s
)
fn RGEllipse label p rx ry = (local pts=for a=0 to 350 by 10 collect (p+[rx*cos(a),ry*sin(a),0]);RGCurve label pts)
fn RGFill label pts mat z:0 = (
 local v=#(),f=#(),c=[0,0,z];for p in pts do c+=([p.x,p.y,0]/pts.count)
 append v c;for p in pts do append v [p.x,p.y,z]
 for i=1 to pts.count do append f [1,i+1,if i==pts.count then 2 else i+2]
 local n=mesh name:label vertices:v faces:f material:mat;(RGLayer "01 Ground and path").addNode n;n
)
fn RGStem p q r1 r2 mat = (local n=cone name:"Tree | branching trunk" radius1:r1 radius2:r2 height:(distance p q) sides:9 heightsegs:3 pos:p dir:(normalize(q-p)) material:mat;(RGLayer "03 Canopy and boulders").addNode n;n)
fn RGRock label p scl mat seedval = (
 seed seedval;local n=geosphere name:label radius:60 segs:3 pos:[0,0,0] material:mat;convertToMesh n
 for i=1 to n.numverts do (local v=getVert n i;setVert n i (v*(random .83 1.14)))
 update n;n.scale=scl;n.rotation=eulerangles 8 17 (random 0 360);n.pos=p;(RGLayer "03 Canopy and boulders").addNode n;n
)
