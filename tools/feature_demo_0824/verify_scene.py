"""Exercise the actual editable demonstration, restoring its authored settings."""
from pathlib import Path
import hashlib,json,math,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-feature-demo0824-')
NODE='CYRUS 0.82.4 | SELECT ME - five feature layers'
data={'status':'started','checks':[],'experiments':{},'timings_ms':{}}
def save(): (OUT/'demo-verification.json').write_text(json.dumps(data,indent=2)+'\n')
def check(value,label):
    data['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def vector(v):return tuple(float(v[k]) for k in range(3))
def rows(index):
    return {str(row[2]):(tuple(vector(getattr(row[0],'row'+str(i))) for i in range(1,5)),
        int(row[1]),str(row[2]),int(row[3]),vector(row[4]),int(row[5]),bool(row[6]),int(row[7]))
        for row in root.groupSnapshotRows[index]}
def dot(a,b):return sum(a[i]*b[i] for i in range(3))
def minus(a,b):return tuple(a[i]-b[i] for i in range(3))
def norm(a):return math.sqrt(dot(a,a))
def unit(a):return tuple(v/norm(a) for v in a)
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def size(row):return norm(row[0][0])
def pos(row):return row[0][3]
def solve(label):
    start=time.perf_counter();root.refreshAll();r.CyrusPointSync()
    data['timings_ms'][label]=(time.perf_counter()-start)*1000;save()
def unchanged(index,label):check(rows(index)==baseline[index],label)
def survives(before,after):return all(key in after and after[key]==row for key,row in before.items())
def signature(all_rows):return hashlib.sha256(json.dumps(all_rows,sort_keys=True,separators=(',',':')).encode()).hexdigest()
try:
    node=r.getNodeByName(NODE);root=node.baseObject;root.updateMode=1
    plane=r.getNodeByName('01 FLAT PLANE | Channel 2 = left-to-right ramp')
    mountain=r.getNodeByName('02 MOUNTAIN | Data Channel Curvature to Channel 3')
    check(str(root.uiVersion())=='0.82.4' and int(r.cyrusMeshDensityVersion())==1,'Uses the qualified 0.82.4 script and native capability')
    check(str(r.units.SystemType)=='meters' and float(r.units.SystemScale)==1,'Scene system units are metres')
    check(len(root.layerObjects)==5,'One editable Scatter controller owns five demonstration layers')
    check(len([n for n in r.objects if str(r.classOf(n))=='Pyramid'])==6,'All six source models are actual editable Max pyramids')
    solve('baseline');baseline=[rows(i) for i in range(5)]
    check(all(len(x)>100 for x in baseline) and not str(root.previewError),'Every layer publishes a substantial successful planting')
    data['counts']={str(root.layerNames[i]):len(baseline[i]) for i in range(5)}
    density,paint,bands,on,off=list(root.layerObjects)
    check(all(-31.001<=pos(row)[0]<=-6.999 and 5.499<=pos(row)[1]<=12.501 for row in baseline[0].values()),'Mesh density placements obey their Include rectangle')
    left=sum(pos(row)[0]<-25 for row in baseline[0].values());right=sum(pos(row)[0]>-13 for row in baseline[0].values())
    check(right>left*3 and left>0,'The orange strip visibly thins from right to left')
    check(min(size(row) for row in baseline[0].values())>=.799 and max(size(row) for row in baseline[0].values())<=1.201,'Layer uniform scale stays within its authored 0.8..1.2 range')
    density.meshMaskEnabled=False;solve('mesh_mask_disabled');unmasked=rows(0)
    check(len(unmasked)>len(baseline[0]) and survives(baseline[0],unmasked),'Disabling the mesh mask adds plants without moving or rescaling surviving pyramids')
    density.meshMaskEnabled=True;density.meshMaskInvert=True;solve('mesh_mask_invert');inverted=rows(0)
    check(sum(pos(row)[0]<-25 for row in inverted.values())>sum(pos(row)[0]>-13 for row in inverted.values())*3,'Invert reverses the spatial mesh density gradient')
    density.meshMaskInvert=False;solve('mesh_restore');unchanged(0,'Restoring mesh settings restores exact matrices, anchors, source and IDs')
    samples=list(density.meshMaskSamples);density.meshMaskSamples=r.Array(0.,0.);solve('mesh_curve_zero')
    check(len(rows(0))==0 and rows(1)==baseline[1] and rows(2)==baseline[2] and rows(3)==baseline[3] and rows(4)==baseline[4],'Zero mesh response curve empties only its owning layer')
    density.meshMaskSamples=r.Array(*samples);solve('mesh_curve_restore');unchanged(0,'Mesh response samples restore the exact orange strip')

    area=paint.paintAreas[0];cfg=r.cyrusBrushFalloff(area.paintDocument)
    check(bool(cfg[2]) and bool(cfg[3]) and abs(float(cfg[0])-1.2)<.001 and abs(float(cfg[1])-.6)<.001,'Paint owns enabled density and scale fades with independent widths')
    check(min(size(row) for row in baseline[1].values())<.6 and max(size(row) for row in baseline[1].values())>1.35,'Cyan Paint contains visibly small edge plants and larger interior plants')
    cfg[2]=False;r.cyrusBrushSetFalloff(area.paintDocument,cfg);solve('paint_density_fade_off');paint_dense=rows(1)
    check(len(paint_dense)>len(baseline[1]) and survives(baseline[1],paint_dense),'Disabling Paint density fading adds plants while preserving surviving size and transform')
    cfg[2]=True;cfg[3]=False;r.cyrusBrushSetFalloff(area.paintDocument,cfg);solve('paint_scale_fade_off');paint_uniform=rows(1)
    check(set(paint_uniform)==set(baseline[1]) and all(pos(row)==pos(baseline[1][key]) for key,row in paint_uniform.items()),'Disabling Paint scale fading preserves placement IDs and positions')
    check(all(abs(size(row)-1)<.0001 for row in paint_uniform.values()),'Paint scale fade off restores unchanged source size')
    cfg[3]=True;r.cyrusBrushSetFalloff(area.paintDocument,cfg);solve('paint_restore');unchanged(1,'Restoring both Paint fades restores the exact cyan planting')
    check(r.isValidNode(r.getNodeByName('PAINT IMPORT SNAPSHOT | 02 cyan strip')),'Paint import source remains an independent editable scene shape')

    check(int(bands.diversityMode)==3 and len(bands.strokeIDs)==2 and list(bands.strokeScaleModes)==[3,3],'One spline Band layer contains two Custom scale profiles and explicit model assignments')
    for source in [1,2]:
        group=[row for row in baseline[2].values() if row[1]==source]
        check(len(group)>100 and min(size(row) for row in group)<.7 and max(size(row) for row in group)>1.2,'Band '+str(source)+' contains visible independent size variation')
    band_curves=list(bands.strokeCurveSamples);bands.strokeCurveSamples=r.Array('1,1','1,1');solve('band_density_constant');band_dense=rows(2)
    check(len(band_dense)>len(baseline[2]) and survives(baseline[2],band_dense),'White Band density curves add plants without changing survivors or Custom size profiles')
    def band_t(row):
        x,y,_=pos(row);distance=min(x+31,-7-x,y+12.5,-5.5-y)
        return distance/1.4 if row[1]==1 else (distance-1.4)/1.3
    fractions=[]
    for source in [1,2]:
        for interval in [(0,.3),(.7,1.001)]:
            eligible=[key for key,row in band_dense.items() if row[1]==source and interval[0]<=band_t(row)<interval[1]]
            fractions.append(sum(key in baseline[2] for key in eligible)/max(1,len(eligible)))
    data['experiments']['band_density_near_far']=fractions
    check(fractions[0]>fractions[1]*2 and fractions[3]>fractions[2]*2,'The two Band density curves produce opposite near-to-far thinning')
    bands.strokeCurveSamples=r.Array(*band_curves);solve('band_density_restore');unchanged(2,'Band density curves restore the exact authored planting')
    scale_curves=list(bands.strokeScaleSamples);bands.strokeScaleSamples=r.Array('1,1','1,1');solve('band_scale_constant');band_uniform=rows(2)
    check(set(band_uniform)==set(baseline[2]) and all(pos(row)==pos(baseline[2][key]) for key,row in band_uniform.items()),'Band scale curves change size independently of eligibility and placement')
    check(all(abs(size(row)-1)<.0001 for row in band_uniform.values()),'Constant-one Band scale profiles preserve source size')
    bands.strokeScaleSamples=r.Array(*scale_curves);solve('band_scale_restore');unchanged(2,'Band scale profiles restore exact matrices and ownership')

    mesh=r.snapshotAsMesh(mountain);vertices=[vector(r.getVert(mesh,i)) for i in range(1,int(mesh.numverts)+1)]
    faces=[tuple(int(r.getFace(mesh,i)[k])-1 for k in range(3)) for i in range(1,int(mesh.numfaces)+1)]
    normals=[unit(cross(minus(vertices[b],vertices[a]),minus(vertices[c],vertices[a]))) for a,b,c in faces]
    values=[float(r.meshop.getMapVert(mesh,3,i).x) for i in range(1,int(r.meshop.getNumMapVerts(mesh,3))+1)]
    data['curvature_range']=[min(values),max(values)]
    check(int(mesh.numfaces)==12800 and min(values)<0<max(values),'Mountain has real varied Curvature values in channel 3 on 12800 evaluated faces')
    for index,label,xlow,xhigh in [(3,'Normals ON',3.4,16.8),(4,'Normals OFF',17.2,30.6)]:
        group=baseline[index]
        slopes=[math.degrees(math.acos(max(-1,min(1,normals[row[3]-1][2])))) for row in group.values()]
        check(all(slope<=45.001 for slope in slopes),'Mountain '+label+' respects the 45 degree slope ceiling')
        check(all(-.001<=pos(row)[2]<=5.501 for row in group.values()),'Mountain '+label+' respects the altitude bounds')
        check(all(xlow-.001<=pos(row)[0]<=xhigh+.001 and abs(pos(row)[1])<=13.001 for row in group.values()),'Mountain '+label+' remains inside its own Include shape')
        check(all(math.hypot(pos(row)[0]-17,pos(row)[1]+9)>=2.196 for row in group.values()),'Mountain '+label+' leaves the red clearing empty')
    check(all(dot(unit(row[0][2]),normals[row[3]-1])>.9999 for row in baseline[3].values()),'Green pyramids align their up axis to the actual geometric surface normal')
    check(all(dot(unit(row[0][2]),(0,0,1))>.9999 for row in baseline[4].values()),'Blue pyramids remain world upright when normal alignment is off')
    check(sum(normals[row[3]-1][2]<.95 for row in baseline[3].values())>50,'Normals comparison includes substantial nonflat terrain')
    on.alignNormal=False;solve('normal_alignment_off');upright=rows(3)
    check(set(upright)==set(baseline[3]) and all(pos(row)==pos(baseline[3][key]) for key,row in upright.items()),'Normal alignment changes orientation without changing positions or eligibility')
    check(all(dot(unit(row[0][2]),(0,0,1))>.9999 for row in upright.values()),'Turning green alignment off makes those pyramids upright too')
    on.alignNormal=True;solve('normal_alignment_restore');unchanged(3,'Normal alignment restores exact green transforms')
    on.slopeEnabled=False;solve('slope_filter_off');no_slope=rows(3)
    check(len(no_slope)>len(baseline[3]) and any(normals[row[3]-1][2]<math.cos(math.radians(45.01)) for row in no_slope.values()),'Disabling slope filtering admits plants onto previously excluded steep faces')
    data['experiments']['green_without_slope']=len(no_slope)
    on.slopeEnabled=True;on.altitudeMaximum=2;on.altitudeUpperFade=.5;solve('altitude_ceiling_lowered')
    check(0<len(rows(3))<len(baseline[3]) and all(pos(row)[2]<=2.001 for row in rows(3).values()),'Lowering altitude to two metres removes higher plants')
    on.altitudeMaximum=5.5;on.altitudeUpperFade=1;solve('filters_restore');unchanged(3,'Restoring slope and altitude restores exact green planting')
    on.meshMaskEnabled=False;solve('curvature_mask_off');no_curvature=rows(3)
    check(len(no_curvature)>len(baseline[3]) and survives(baseline[3],no_curvature),'Curvature mask independently thins mountain candidates')
    data['experiments']['green_without_curvature']=len(no_curvature)
    on.meshMaskEnabled=True;include=list(on.areaNodes);modes=list(on.areaModes)
    on.areaNodes=r.Array(include[0]);on.areaModes=r.Array(1);solve('exclude_removed');without_hole=rows(3)
    check(any(math.hypot(pos(row)[0]-17,pos(row)[1]+9)<2.15 for row in without_hole.values()),'Removing the Exclude shape allows plants back inside the red clearing')
    on.areaNodes=r.Array(*include);on.areaModes=r.Array(*modes);solve('exclude_restore');unchanged(3,'Restoring the Exclude shape restores exact green planting')
    check(all(rows(i)==baseline[i] for i in range(5)),'Every temporary experiment restores the original combined scene')
    before=signature([rows(i) for i in range(5)])
    final=OUT/'CyrusScatter 0.82.4 Feature Demo.max'
    r.saveMaxFile(str(final),quiet=True);r.loadMaxFile(str(final),quiet=True,useFileUnits=True)
    node=r.getNodeByName(NODE);root=node.baseObject;solve('save_reopen')
    check(signature([rows(i) for i in range(5)])==before,'Current-schema save/reopen preserves all five full row publications exactly')
    check(all(not bool(leaf.dirty) and not str(leaf.previewError) for leaf in root.layerObjects),'Reopened scene has complete results with no pending edits or layer errors')
    root.updateMode=1;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    root.selectLayer(1);root.populationUI.open=True;root.mainUI.bindSection(root.populationUI)
    r.viewport.setCamera(r.getNodeByName('CAM 01 | Overview'));r.CyrusPointSync();r.completeRedraw()
    r.saveMaxFile(str(final),quiet=True)
    data['scene']=str(final);data['scene_sha256']=hashlib.sha256(final.read_bytes()).hexdigest()
    data['total_accepted']=sum(data['counts'].values());data['final_publication_sha256']=before
    data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise
