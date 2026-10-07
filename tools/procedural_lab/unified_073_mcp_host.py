"""Execute only with python.ExecuteFile in the owned qualification Max process."""
from pathlib import Path
import json,sys,math
ROOT=Path('F:/Cursor/_Cyrus_Apps/CyrusScatter')
sys.path.insert(0,str(ROOT/'CyrusMCP'))
from pymxs import runtime as rt
from cyrus_mcp.max_host import MaxHost
from cyrus_mcp.service import Service,Journal
from cyrus_mcp.contracts import Fault
from cyrus_mcp.publication import manifest

folder=Path(str(rt.MCPFixtureDir));evidence=[]
if not folder.resolve().is_relative_to(ROOT/'build/mcp-qualification'):raise RuntimeError('Private process required')
def run():
    try:
        for mode in ('point_cloud','proxy','mesh','centres'):
            rt.resetMaxFile(rt.Name('noPrompt'))
            rt.units.SystemType=rt.Name('Centimeters');rt.units.SystemScale=1
            site=rt.plane(name='U73MCP_Site',width=3000,length=3000,widthsegs=4,lengthsegs=4)
            source=rt.box(name='U73MCP_Source',width=10,length=10,height=50,pos=rt.Point3(2000,0,0))
            def boundary(name,half):
                node=rt.splineShape(name=name);rt.addNewSpline(node)
                for x,y in ((-half,-half),(half,-half),(half,half),(-half,half)):
                    rt.addKnot(node,1,rt.Name('corner'),rt.Name('line'),rt.Point3(x,y,0))
                rt.close(node,1);rt.updateShape(node);node.renderable=False
                return node
            region=boundary('U73MCP_Region',1250)
            hole=boundary('U73MCP_Protected',100)
            host=MaxHost();service=Service(host,Journal(folder/('journal-'+mode+'.json')))
            scope=service.enroll(site,[source],[region],[hole]);context=service.context(scope['scope_id'])
            plan={'schema_version':'0.73','context_id':context['context_id'],'name':'Qualified unified MCP',
                  'display':{'mode':mode,'points_per_plant':30,'instances_per_population':2000},
                  'pair_rules':[{'a':0,'b':1,'enabled':True,'radius_factor':1,'gap_m':.5,'planar':True}],
                  'layers':[{'name':'Plants '+str(i),'region_id':scope['regions'][0]['region_id'],'count':180,'seed':42+i,
                             'sources':[{'source_id':scope['sources'][0]['source_id'],'weight':1,'settings':{'scale':.8,'radius_m':.15,'z_offset_m':.02}}],
                             'scale':[.8,1.2],'yaw_degrees':[0,360],'underfill':'allow',
                             'settings':{'self_spacing_enabled':True,'self_radius_factor':1,'self_gap_m':.1,'movement_x_m':[-.1,.1],
                                         'scale_x':[.8,1.2],'rotation_x_degrees':[-4,4]}} for i in range(2)]}
            before=host.fingerprint();validation=service.validate(plan);assert host.fingerprint()==before
            args={key:validation[key] for key in ('validation_id','digest','scene_epoch','scene_revision')};args['idempotency_key']='u73_'+mode
            try:service.apply(**args)
            except Fault as exc:assert exc.code=='APPROVAL_REQUIRED'
            else:raise AssertionError('Remote apply bypassed local approval')
            service.approve(validation['validation_id']);queued=service.apply(**args);service.step()
            operation=service.journal.records[queued['operation']['operation_id']]
            assert operation['state']=='succeeded',operation
            result=operation['result'];controller=host.controllers[result['controller_id']]
            assert result['calculation_model']=='CyrusUnified1' and result['plan_schema']=='0.73'
            assert not rt.isProperty(controller,rt.Name('groupPolicy')) and result['emitted']>0
            cfg=host.configuration(result['controller_id']);assert cfg['calculation_model']=='CyrusUnified1'
            assert cfg['layers'][0]['settings']['self_spacing_enabled'] and abs(cfg['layers'][0]['settings']['self_gap_m']-.1)<1e-6
            assert abs(cfg['layers'][0]['assets'][0]['settings']['radius_m']-.15)<1e-6
            builds=[int(leaf.procPreparedBuilds) for leaf in controller.layerObjects];epoch=int(controller.procEpoch)
            public=host.publication_manifest(result['controller_id']);page=host.publication_page(result['controller_id'],public['publication_id'],0,100)
            assert page and [int(leaf.procPreparedBuilds) for leaf in controller.layerObjects]==builds and int(controller.procEpoch)==epoch
            actual=host.layouts[result['controller_id']]['instances'];groups={str(leaf.layerID):[] for leaf in controller.layerObjects}
            for row in actual:
                p=[row['transform'][0][3],row['transform'][1][3]];groups[row['layer_id']].append(p)
                assert not (-1<=p[0]<=1 and -1<=p[1]<=1),'Protected area planted'
            a,b=groups.values()
            for x in a:
                for y in b:assert math.dist(x,y)>=.49999,'Ordered layer gap leaked'
            assert not rt.isSceneRedrawDisabled()
            # A refined generation can fail; verify rollback retains the entire old
            # controller, meshes, selection, configuration and publication.
            next_context=service.context(scope['scope_id']);refined=dict(plan,context_id=next_context['context_id'],controller_id=result['controller_id'],generation_id=result['generation_id'])
            check=service.validate(refined);approved=service.validations[check['validation_id']]
            snapshot=host.fingerprint();host.fail_phase='preview'
            try:host.generate(approved['plan'],approved['compiled'])
            except Fault as exc:assert exc.details.get('rollback')=='verified',exc.result()
            else:raise AssertionError('Injected failure did not fail')
            host.fail_phase=None;assert host.fingerprint()==snapshot and not rt.isSceneRedrawDisabled()
            evidence.append({'mode':mode,'emitted':result['emitted'],'explicit_model':True,'approval_guard':True,'passive_publication':True,'rollback_verified':True})
        (folder/'mcp073.json').write_text(json.dumps({'passed':True,'cases':evidence},indent=2))
    except Exception as exc:
        import traceback
        (folder/'mcp073-error.txt').write_text(traceback.format_exc())
        (folder/'mcp073.json').write_text(json.dumps({'passed':False,'cases':evidence,'error':str(exc)},indent=2))

# Execute after python.ExecuteFile releases Max's busy script evaluation.
# This is the same Qt host thread as the product panel; approval remains local.
from PySide6.QtCore import QTimer
QTimer.singleShot(100, run)
