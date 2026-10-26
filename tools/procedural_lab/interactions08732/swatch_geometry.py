"""Measure native ColorSwatch extents in the actual Modify pages and owned widths."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={'checks':[],'rows':[]}
try:
    root=r.WFRoot;leaf=r.WFGrass;report['hwnd']=int(r.windows.getMAXHWND())
    r.execute('subObjectLevel=0;select WFOwner;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+3
    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
    root.mainUI.selectLayerView(leaf)
    try:r.destroyDialog(r.WFSwatchPage)
    except Exception:pass
    root.managerUI=root.mainUI.editors[0];root.modelsUI=root.mainUI.editors[2]
    r.execute('global WFSwatchPage,WFSwatchControl;fn WFSwatchRect page control = (for h in control.hwnd where (windows.getHWNDData h)[4]=="ColorSwatch" collect (local rect=windows.getWindowPos h removeUIScaling:true;local origin=windows.getWindowPos page.hwnd removeUIScaling:true;#(rect.x-origin.x,rect.y-origin.y,rect.w,rect.h,origin.w)))')
    r.execute('struct WFSwatchBodyProbe(height=0);struct WFSwatchHostProbe(width=0,height=0,headerInset=0,body=undefined,open=true)')
    def measure(page,name,kind):
        control=r.getProperty(page,r.Name(name));values=r.WFSwatchRect(page,control);assert len(values)==1
        x,y,w,h,width=map(float,values[0]);row={'scope':kind,'page_width':float(page.width),'native_rollout_width':width,'swatch':[x,y,w,h]};report['rows'].append(row)
        assert 0<=x and x+w<=width-2,(name,row)
        assert w<=23,(name,row)
        report['checks'].append(kind+' '+name+' stays inside its column')
    for index,name in [(0,'flow_layersUI_layerColor'),(2,'sourceUI_idColor')]:
        panel=root.mainUI;panel.slots[index].open=True;page=panel.editors[index];panel.bindSection(page);measure(page,name,'Modify')
    # Fresh disposable pages exercise the generated layout at narrow widths.
    # They use a self host solely for geometry; no authoring event is fired.
    for kind,fn,name in [('Layers',root.createmanagerUI,'flow_layersUI_layerColor'),('Models',root.createmodelsUI,'sourceUI_idColor')]:
        for width in [170,210,290]:
            page=fn();r.WFSwatchPage=page
            try:
                r.createDialog(page,width=width,height=650);page.hostPage=r.WFSwatchHostProbe(width=width+8,body=r.WFSwatchBodyProbe());page.root=root;page.owner=leaf;page.panel=r.undefined;page.bind(leaf);measure(page,name,kind+' '+str(width))
            finally:
                r.destroyDialog(page);root.managerUI=root.mainUI.editors[0];root.modelsUI=root.mainUI.editors[2]
    report['ui_scale']=float(r.GetUIScaleFactor());report['status']='pass'
except Exception:report['error']=traceback.format_exc()
(O/'swatch-geometry.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
