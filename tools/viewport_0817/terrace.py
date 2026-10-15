"""Reproduce the artist's zero-limit transitions through real rollout callbacks."""
from pathlib import Path
import ctypes,hashlib,json,os,shutil,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-viewport0817-')
data={'status':'started','checks':[],'cases':[]}
def save():(OUT/'terrace.json').write_text(json.dumps(data,indent=2)+'\n')
def stage(label):data['stage']=label;save()
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def fp():return [str(r.cyrusEditFingerprint(rows,'garden-final815')) for rows in root.groupSnapshotRows]
def redraw():
    r.CyrusPointSync()
    for _ in range(3):r.completeRedraw();r.windows.processPostedMessages()
def state(label):
    owner=r.CyrusPointOwner(node)
    value={'label':label,'policy':[int(x) for x in r.cyrusRetainedViewportStats(owner)],
           'resources':[int(x) for x in r.cyrusPreviewResourceStats()],
           'retained':[str(x) for x in r.cyrusRetainedStats(owner)],
           'mesh':[int(x) for x in r.cyrusRetainedMeshStats(owner)],
           'modes':[int(l.uiPreviewMode) for l in root.layerObjects],
           'cache_slots':[len(l.procPreviewModes) for l in root.layerObjects],
           'errors':[str(l.previewError) for l in root.layerObjects],
           'error':str(r.CyrusPointLastError),'detail':str(r.CyrusPointDetailStatus)}
    data['cases'].append(value);save();return value
def select_dropdown(control,value):
    # MAXScript's .selected string hides the event method. Send the native
    # ComboBox selection notification to this owned process's actual control.
    user=ctypes.WinDLL('user32',use_last_error=True)
    user.GetParent.argtypes=[ctypes.c_void_p];user.GetParent.restype=ctypes.c_void_p
    user.SendMessageW.argtypes=[ctypes.c_void_p,ctypes.c_uint,ctypes.c_size_t,ctypes.c_ssize_t]
    user.SendMessageW.restype=ctypes.c_ssize_t
    for handle in control.hwnd:
        hwnd=int(handle);name=ctypes.create_unicode_buffer(256)
        user.GetClassNameW(hwnd,name,256)
        if name.value!='ComboBox':continue
        pid=ctypes.c_ulong();user.GetWindowThreadProcessId(hwnd,ctypes.byref(pid))
        assert pid.value==os.getpid(),'Never send UI events to another process'
        assert user.SendMessageW(hwnd,0x14e,value-1,0)==value-1  # CB_SETCURSEL
        identifier=user.GetDlgCtrlID(hwnd)
        user.SendMessageW(user.GetParent(hwnd),0x111,identifier|(9<<16),hwnd)  # CBN_SELENDOK
        return
    raise AssertionError('Native dropdown not found')
def mode(value):
    select_dropdown(root.displayUI.flow_previewUI_displayModeDrop,value)
    redraw()
def shape(value):
    select_dropdown(root.displayUI.flow_previewUI_proxyShapeDrop,value)
    redraw()
def validate(value,expected):
    check(not value['error'] and not any(value['errors']),'No preview error: '+value['label'])
    check(all(m==expected for m in value['modes']),'Every layer displays requested mode: '+value['label'])
    check(value['retained'][11]=='1','GPU items ready: '+value['label'])
    check(int(root.procEpoch)==epoch and fp()==baseline,'Placement publication unchanged: '+value['label'])
try:
    save();original=ROOT/'Test Scene/Terraces_0815/Terraces_0815_Final.max'
    before=hashlib.sha256(original.read_bytes()).hexdigest();copy=OUT/'Terrace_input.max';source=original
    check(before=='54b006f2cd40183bcdb048d3ab040eaee066ad67728d5e3b76b381685ab65801','Exact preserved terrace input')
    if json.loads((OUT/'launch.json').read_text())['max_year']==2026:
        compatibility=ROOT/'build/mcp-qualification/foundation-viewport0817-max2027-03/compatibility-copy.json'
        conversion=json.loads(compatibility.read_text());source=Path(conversion['output']).resolve()
        assert source.is_relative_to(compatibility.parent) and conversion['success'] and conversion['source_sha256']==before
        assert hashlib.sha256(source.read_bytes()).hexdigest()==conversion['output_sha256']
        data['compatibility_input']=conversion
    shutil.copy2(source,copy)
    stage('load copied scene');r.disableSceneRedraw();assert r.loadMaxFile(str(copy),quiet=True,useFileUnits=True),'Terrace input must load successfully'
    stage('initialize copied scene')
    node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject
    root.autoRender=False;r.CyrusPFTimer.Stop();r.clearSelection();r.execute('max create mode')
    stage('initial publication');root.refreshAll();r.CyrusPointSync();baseline=fp();epoch=int(root.procEpoch)
    assert epoch>0 and not any(str(l.previewError) for l in root.layerObjects),str(root.allStatus())+'; '+str([str(l.previewError) for l in root.layerObjects])
    r.viewport.setLayout(r.Name('layout_1'));r.viewport.setType(r.Name('view_persp_user'))
    camera=r.getNodeByName('PhysCamera002');r.viewport.setTM(r.inverse(camera.transform));r.viewport.setFOV(camera.fov)
    r.viewport.setRenderLevel(r.Name('smoothhighlights'))
    r.execute('(NitrousGraphicsManager.GetActiveViewportSetting()).AdaptiveDegradeNeverDegradeGeometry=true')
    stage('first redraw');r.enableSceneRedraw();redraw()
    stage('mount viewport controls')
    r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    panel=root.displayUI;panel.open=True;root.mainUI.bindSection(panel)
    check(bool(panel.controlsReady),'Actual viewport rollout is bound')
    # Exercise the user's exact zero settings and callback path.
    stage('set zero point limits');mode(1)
    for name in ['navigationPointsSpin','budgetSpin']:
        control=r.getProperty(panel,r.Name('flow_previewUI_'+name));control.value=0;control.changed(0)
    redraw();value=state('zero_points_first');validate(value,1)
    check(0<value['policy'][1]<=int(r.cyrusViewportPointCapacity())+len(root.layerObjects),'Unlimited cloud prepares a bounded visible sample')
    check('memory allowance' in value['detail'],'Memory-limited Point Cloud explains its reduction')
    mode(2)
    for name in ['navigationInstancesSpin','instancesLimitSpin']:
        control=r.getProperty(panel,r.Name('flow_previewUI_'+name));control.value=0;control.changed(0)
    root.viewportFaces=2000000;root.viewportNavigationFaces=500000
    leaf=root.layerObjects[0];old_amount=int(leaf.amount);leaf.amount=old_amount+1
    per_mode={}
    stage('repeat mode switches')
    for repeat in range(4):
        for proxy in [1,2,3]:
            mode(2);shape(proxy);value=state(f'pass_{repeat}_proxy_{proxy}');validate(value,2)
            check(value['policy'][3]==245664 and value['policy'][4]==245664,'Zero proxies preserve every placement')
            mode(1);value=state(f'pass_{repeat}_points_after_{proxy}');validate(value,1)
            check(value['policy'][1]>0 and value['policy'][3]==value['policy'][5]==0,'Points replace all prior proxy/mesh draw plans')
        mode(3);value=state(f'pass_{repeat}_mesh');validate(value,3)
        check(value['policy'][9]==0,'Finite Mesh avoids memory fallback after repeated switches')
        mode(1);value=state(f'pass_{repeat}_points_after_mesh');validate(value,1)
        check(all(n<=6 for n in value['cache_slots']),'Representation cache stays bounded')
        per_mode[repeat]=value['resources'][4]
    data['mesh_resource_bytes_after_pass']=per_mode
    check(max(per_mode.values())-min(per_mode.values())<1024*1024,'Warm mode switching does not accumulate Mesh snapshots')
    check(int(leaf.generatedCount)==old_amount,'Pending Manual amount was not applied by display callbacks')
    leaf.amount=old_amount
    b=r.gw.getViewportDib();b.filename=str(OUT/'points-zero.png');r.save(b);r.close(b)
    r.clearSelection();r.execute('max create mode');r.CyrusPerfHeadless=True
    stage('save and reopen');saved=OUT/'Terrace_0817_verified.max';r.saveMaxFile(str(saved),quiet=True)
    r.disableSceneRedraw();r.loadMaxFile(str(saved),quiet=True,useFileUnits=True)
    node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject;root.autoRender=False;r.CyrusPFTimer.Stop()
    root.refreshAll();r.CyrusPointSync();r.enableSceneRedraw();redraw()
    check(fp()==baseline and int(root.previewBudget)==0 and int(root.viewportNavigationPoints)==0,'Save/reopen preserves zero point settings and placements')
    check(all(int(l.uiPreviewMode)==1 and not str(l.previewError) for l in root.layerObjects),'Reopened zero-limit Point Cloud is valid')
    check(hashlib.sha256(original.read_bytes()).hexdigest()==before,'Original terrace scene remains unchanged')
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:
    try:r.enableSceneRedraw()
    except:pass
    save()
if data['status']!='complete':raise RuntimeError(data['error'])
