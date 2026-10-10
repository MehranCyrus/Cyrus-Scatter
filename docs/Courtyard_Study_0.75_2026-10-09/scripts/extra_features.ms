global CYExtra
fn CYExtra = (
 P07Checks=#();P07Case="Current source-independent feature complements";P07New count:2500
 local r=P07Root,l=P07Layer,s=P07Source
 -- Independent Include shapes union and Exclude wins, including overlap.
 local a=rectangle width:500 length:600 pos:[-180,0,0],b=rectangle width:500 length:600 pos:[180,0,0],cut=rectangle width:120 length:900
 l.areaNodes=#(a,b,cut);l.areaModes=#(1,1,2)
 local rows=(r.evaluateGroups())[1],bad=0
 for row in rows do (local p=row[1].row4;if abs p.x<59.999 or abs p.x>430.001 or abs p.y>300.001 do bad+=1)
 P07Assert (rows.count>0 and bad==0) "Union/exclusion precedence failed"
 P07Record "include_union_exclude" #(rows.count,bad)
 -- Texture endpoints have an unambiguous oracle.
 l.areaNodes=#();l.areaModes=#();l.distributionMode=3
 l.densityMap=Noise color1:black color2:black
 P07Assert ((r.evaluateGroups())[1].count==0) "Black texture admitted candidates"
 l.densityMap.color1=white;l.densityMap.color2=white
 l.markInputDirty()
 P07Assert ((r.evaluateGroups())[1].count==2500) "White texture rejected candidates"
 P07Record "texture_endpoints" true
 -- Analyzer points and line masks have independent radii/width and union behavior.
 local node=CyrusSurfaceAnalyzer name:"EXTRA | Analyzer",an=node.baseObject
 an.surface=P07Surface;an.resolution=48;an.pointRadius=65;an.fitRadius=30;an.relaxIterations=0;an.updateMode=1;an.runAnalysis()
 l.distributionMode=1;l.areaAnalyzer=node;l.areaUseLine=false;l.areaUsePoints=true;l.areaPointRadius=65
 local points=(r.evaluateGroups())[1].count
 l.areaUsePoints=false;l.areaUseLine=true;l.areaLineWidth=140
 local line=(r.evaluateGroups())[1].count
 l.areaUsePoints=true;local united=(r.evaluateGroups())[1].count
 P07Assert (united>=points and united>=line) "Analyzer point/line union lost candidates"
 P07Record "analyzer_area_union" #(an.samplePoints.count,an.pathVertices.count,points,line,united)
 -- Compare XY/3D clearance on vertically separated receivers.
 P07New count:300;r=P07Root;l=P07Layer
 local high=copy P07Surface;high.pos.z=100
 r.setLayerSurfaces l #(P07Surface,high);l.sourceRadii=#(35.0);l.procSelfOverride=true;l.procSelfEnabled=true;l.procSelfMultiplier=1;l.procSelfGap=0
 l.procSelfPlanar=true;local flat=(r.evaluateGroups())[1].count
 l.procSelfPlanar=false;local spatial=(r.evaluateGroups())[1].count
 P07Record "xy_3d_counts" #(flat,spatial)
 P07Assert (flat>0 and spatial>0) "Spacing modes returned no candidates"
 local fp=P07Fingerprint r
 l.advancedAxes=true;l.sclXMin=.8;l.sclXMax=1.2;l.sclYMin=.9;l.sclYMax=1.1;l.sclZMin=1.3;l.sclZMax=1.6;l.rotXMin=-5;l.rotXMax=5;l.movXMin=-3;l.movXMax=3;l.projectMove=true
 rows=(r.evaluateGroups())[1]
 P07Assert (rows.count>0) "XYZ/projected transform produced no results"
 P07Record "xyz_projected_transforms" rows.count
 true
)
