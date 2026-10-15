"""Inspect the copied project in the explicitly owned terrace host."""
from pathlib import Path
import hashlib,json,time,traceback
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-')
SCENE=ROOT/'Test Scene/Terraces_0815/Terraces_0815_Baseline.max'
REPORT=OUT/'scene-inventory.json'
data={'scene':str(SCENE),'status':'loading','nodes':[],'scatter':[],'maps':[],'errors':[]}
def save():REPORT.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def val(obj,key,default=None):
    try:
        value=getattr(obj,key)
        if value==r.undefined:return None
        if isinstance(value,(str,int,float,bool)):return value
        return str(value)
    except Exception:return default
def xyz(v):return [float(v.x),float(v.y),float(v.z)]
def props(obj,keys):return {k:val(obj,k) for k in keys}
save()
try:
    started=time.perf_counter()
    r.CyrusPerfHeadless=True
    if not r.loadMaxFile(str(SCENE),quiet=True,useFileUnits=True):raise RuntimeError('Scene failed to load')
    data['load_seconds']=time.perf_counter()-started
    data['units']=props(r.units,['SystemType','SystemScale','DisplayType'])
    data['renderer']=str(r.classOf(r.renderers.current))
    data['render']=props(r,['renderWidth','renderHeight','renderPixelAspect','rendTimeType','rendStart','rendEnd','environmentMap'])
    data['renderer_settings']=props(r.renderers.current,['progressive_passLimit','progressive_timeLimit','progressive_noiseLevelLimit','denoise_filterType','bg_source'])
    data['status']='inventory';save()
    controllers=[n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject']
    for node in controllers:
        root=node.baseObject
        entry={'name':str(node.name),'properties':props(root,['uiVersion','procSchemaVersion','procSchemaValid','updateMode','autoRender','cyrusEnabled','previewError','activeLayer','procEpoch','groupDirty']), 'layers':[]}
        entry['properties']['version']=str(root.uiVersion())
        entry['global_containers']=[str(n.name) for n in root.containerGlobalNodes if r.isValidNode(n)]
        for index,leaf in enumerate(root.layerObjects):
            row={'index':index+1,'name':str(root.layerCaption(leaf)),
                 'settings':props(leaf,['layerID','amount','populationMode','plantsPerM2','distributionMode','diversityMode','densityMap','invertDensity','containerMode','dirty','previewError','generatedCount','requestedCount','cachedPointCount','viewportMode','viewportInstances','viewportFaces','pointsPerPlant','previewBudget','paintEnabled','procPopulation','procAttemptFactor','procRounds','procSelfEnabled','procLayerSelfEnabled','procSiblingEnabled','procSchemaValid','randomSeed','layerEnabled','layerVisible']),
                 'surfaces':[str(x.name) for x in leaf.validSurfaces()],
                 'sources':[str(x.name) if r.isValidNode(x) else str(x) for x in leaf.sources],
                 'containers':[str(x.name) for x in leaf.containerNodes if r.isValidNode(x)],
                 'source_weights':[float(x) for x in leaf.sourceWeights],
                 'source_scales':[float(x) for x in leaf.sourceScales],
                 'area_nodes':[str(x.name) for x in leaf.areaNodes if r.isValidNode(x)]}
            entry['layers'].append(row)
        data['scatter'].append(entry)
        root.updateMode=1;root.autoRender=False
    for node in r.objects:
        row={'name':str(node.name),'handle':int(r.getHandleByAnim(node)), 'class':str(r.classOf(node.baseObject)),
             'superclass':str(r.superClassOf(node)), 'position':xyz(node.position),
             'hidden':bool(node.isHidden),'renderable':bool(node.renderable), 'material':val(node,'material'),
             'parent':str(node.parent.name) if r.isValidNode(node.parent) else None,
             'group_head':bool(r.isGroupHead(node)),'group_member':bool(r.isGroupMember(node))}
        if row['superclass'] in ('GeometryClass','shape','Shape','camera','Camera') or row['name'].startswith(('surf_','grass','leaf','plant','tree')):
            try:
                bounds=r.nodeGetBoundingBox(node,r.matrix3(1));row['bounds']=[xyz(bounds[0]),xyz(bounds[1])]
            except Exception as error:row['bounds_error']=str(error)
        if 'Camera' in row['class'] or row['name']=='PhysCamera002':
            row['camera']=props(node,['fov','targeted','target','focal_length_mm','film_width_mm','specify_fov','exposure_value','shutter_speed','f_number','ISO'])
            row['transform']=str(node.transform)
        if row['class']=='CyrusSourceContainer':row['container']=props(node,['collectEnabled','width','length','cachedLabel','cachedActiveCount','cachedSavedCount','contextRootID','contextSetID'])
        data['nodes'].append(row)
    for kind,fields in [('Bitmaptexture',['filename']),('CoronaBitmap',['filename']),('VRayBitmap',['HDRIMapName'])]:
        try:
            cls=getattr(r,kind)
            for item in r.getClassInstances(cls):
                row={'class':kind,'name':str(item.name),**props(item,fields)}
                for field in fields:
                    if row[field]:row[field+'_exists']=Path(row[field]).is_file()
                data['maps'].append(row)
        except Exception as error:data['errors'].append('Map enumeration '+kind+': '+str(error))
    camera=r.getNodeByName('PhysCamera002')
    if not r.isValidNode(camera):raise RuntimeError('PhysCamera002 is missing')
    r.viewport.setCamera(camera);r.clearSelection()
    r.CyrusPerfHeadless=False;r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages()
    bitmap=r.gw.getViewportDib();bitmap.filename=str(OUT/'baseline-camera-viewport.png');r.save(bitmap);r.close(bitmap)
    data['viewport']=str(OUT/'baseline-camera-viewport.png')
    data['post_inspection_errors']=[{'name':str(n.name),'errors':[str(l.previewError) for l in n.baseObject.layerObjects]} for n in controllers]
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])
