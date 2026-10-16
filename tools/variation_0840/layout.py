"""Read actual control rectangles in the owned Max 2027 panel at a requested scale."""
from pathlib import Path
import ctypes as c
from ctypes import wintypes as w
import json
import traceback
import pymxs
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-variation0840-')
req=json.loads((OUT/'layout-command.json').read_text())
u=c.WinDLL('user32');u.IsWindowVisible.argtypes=[w.HWND];u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
u.GetWindowTextW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
def rect(hwnd):
    box=w.RECT();assert u.GetWindowRect(hwnd,c.byref(box));return [box.left,box.top,box.right,box.bottom]
result={'status':'running','pages':[],'scale_requested':req.get('scale',1.)}
target=OUT/('layout-'+req['label']+'.json')
try:
    with pymxs.undo(False):
        if 'scale' in req:
            # Scaling is fixed before first panel creation in launch.py. Changing
            # host-wide custom-control scaling with live controls is unsupported
            # by this qualification workflow.
            assert abs(float(r.GetUIScaleFactor())-req['scale'])<.01
        result['max_scale']=float(r.GetUIScaleFactor())
        result['custom_scale']=float(r.CustomControlsOptions.UIUserScaleFactor)
        # Native Undo/Redo qualification reloads the private scene; resolve its
        # current node instead of retaining a pre-reload Python fixture handle.
        r.OrientationNode=r.getNodeByName('Variation heavy setup')
        assert r.isValidNode(r.OrientationNode)
        r.OrientationRoot=r.OrientationNode.baseObject;r.OrientationLeaf=r.OrientationRoot.layerObjects[0]
        r.CyrusPerfHeadless=False;r.select(r.OrientationNode);r.execute('max modify mode');r.modPanel.setCurrentObject(r.OrientationRoot)
        if not r.OrientationRoot.mainUI.controlsReady:r.OrientationRoot.mainUI.mountTimer.tick()
        main=r.OrientationRoot.mainUI
        if 'owner_index' in req:main.selectLayerView(r.OrientationRoot.layerObjects[req['owner_index']])
        if not req.get('observe',False):
            for slot in main.slots:slot.open=False
        for index in req.get('pages',list(range(12))):
            slot=main.slots[index]
            if not req.get('observe',False):slot.open=True;slot.rolledUp(False)
            page=main.editors[index]
            if req.get('advanced',True) and not req.get('observe',False):
                page.advancedToggle.checked=True;page.layout()
            if req.get('prepare',False):continue
            bounds=rect(int(slot.hwnd))
            record={'name':str(page.name),'hwnd':int(page.hwnd),'body':bounds,'page_rect':rect(int(page.hwnd)),
                    'width':float(page.width),'slot_width':float(slot.width),'height':float(page.height),'slot_height':float(slot.height),
                    'layout_width':float(page.lastLayoutWidth),'header_inset':float(slot.headerInset),'controls':[],'clipped':[]}
            for control in page.controls:
                try:
                    if not control.visible:continue
                    handles=control.hwnd
                    if isinstance(handles,int):handles=[handles]
                    for handle in handles:
                        handle=int(handle)
                        if not handle:continue
                        box=rect(handle)
                        # Native compound controls retain empty caption HWNDs.
                        if box[2]<=box[0] or box[3]<=box[1]:continue
                        item={'name':str(control),'rect':box,'class':str(r.windows.getHWNDData(handle)[3])}
                        if str(control).startswith('dotNetControl'):
                            try:item['font']={'size':float(control.Font.Size),'height':float(control.Font.Height),'dpi':int(control.DeviceDpi),'row':int(control.ItemHeight)}
                            except AttributeError:pass
                        record['controls'].append(item)
                        if box[0]<bounds[0]-2 or box[2]>bounds[2]+2 or box[1]<bounds[1]-2 or box[3]>bounds[3]+2:record['clipped'].append(item)
                        if item['class']=='Static' or str(control).startswith('CheckBoxControl'):
                            text=c.create_unicode_buffer(4096);u.GetWindowTextW(handle,text,4096)
                            if text.value:
                                width=box[2]-box[0]-(round(26*result['max_scale']) if str(control).startswith('CheckBoxControl') else 0)
                                item['text_height']=int(r.cyrusMeasureWrappedText(handle,text.value,max(1,width)))
                                if item['text_height']>box[3]-box[1]+2:record['clipped'].append(item)
                except AttributeError:pass
            assert record['controls'],record['name']+': no measured controls'
            record['overlaps']=[]
            for i,first in enumerate(record['controls']):
                for second in record['controls'][i+1:]:
                    if first['name']==second['name']:continue
                    a,b=first['rect'],second['rect']
                    if min(a[2],b[2])-max(a[0],b[0])>3 and min(a[3],b[3])-max(a[1],b[1])>3:
                        record['overlaps'].append([first['name'],second['name']])
            if req.get('capture',False):
                snapshot=r.windows.snapshot(int(page.hwnd),captureScreenPixels=False,gammaCorrect=False)
                snapshot.filename=str(OUT/('page-'+req['label']+'-'+record['name']+'.png'))
                assert r.save(snapshot)
                r.close(snapshot)
            result['pages'].append(record)
            if req.get('close',True):slot.open=False;slot.rolledUp(True)
        result['clipped_count']=sum(len(p['clipped']) for p in result['pages'])
        result['overlap_count']=sum(len(p['overlaps']) for p in result['pages'])
        result['status']='prepared' if req.get('prepare',False) else 'passed' if result['clipped_count']==0 and result['overlap_count']==0 else 'failed'
except Exception:
    result['status']='failed';result['error']=traceback.format_exc();raise
finally:
    target.write_text(json.dumps(result,indent=2)+'\n')
