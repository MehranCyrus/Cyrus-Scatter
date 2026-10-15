"""Exercise expanded population through the real model, UI and publication path."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-candidate')
data={'steps':[],'checks':[],'status':'started'}
run=1
while (OUT/('capacity-host-%02d.json'%run)).exists():run+=1
REPORT=OUT/('capacity-host-%02d.json'%run)
def write(): REPORT.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def arr(items):return r.Array(*items)
def pt(x,y,z=0):return r.Point3(float(x),float(y),float(z))
def check(test,label,**details):
    data['checks'].append({'passed':bool(test),'label':label,**details});write()
    if not test:raise AssertionError(label)
def fingerprint(root):return [str(r.cyrusEditFingerprint(rows,'capacity0815')) for rows in root.groupSnapshotRows]
def state(root):return {'epoch':int(root.procEpoch),'fingerprints':fingerprint(root),'accepted':[int(l.generatedCount) for l in root.layerObjects],
    'prepared':[int(l.procPreparedBuilds) for l in root.layerObjects],'errors':[str(l.previewError) for l in root.layerObjects]}
def update(root,label):
    start=time.perf_counter();root.refreshAll()
    data['steps'].append({'label':label,'seconds':time.perf_counter()-start,**state(root)});write()
try:
    r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
    node=r.AminScatterObject(name='Capacity 0.81.5');root=node.baseObject;root.updateMode=1;root.autoRender=False
    check(str(root.uiVersion())=='0.81.5' and int(r.cyrusSplineBandVersion())==10,'Matched capacity script/native interface')
    receiver=r.mesh(name='Receiver UV witness',vertices=arr([pt(0,0),pt(10000,0),pt(10000,10000),pt(0,10000)]),faces=arr([pt(1,2,3),pt(1,3,4)]))
    source=r.box(name='Capacity source',length=3,width=3,height=10,pos=pt(-1000,-1000));source.renderable=False
    root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,arr([receiver]));leaf.sources=arr([source]);leaf.containerMode=1
    leaf.amount=100000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.distributionMode=1
    root.setGroupDisplay(4);root.previewBudget=10000
    update(root,'Original capacity');check(int(leaf.generatedCount)==100000 and not str(leaf.previewError),'100000 published')
    old=str(r.cyrusEditFingerprint(root.groupSnapshotRows[0],'prefix'))
    leaf.amount=150001;update(root,'Cross the old cap and receiver identity stride')
    check(int(leaf.generatedCount)==150001 and not str(leaf.previewError),'150001 published')
    r.execute('global TerraceCapacityRoot');r.TerraceCapacityRoot=root
    prefix=r.execute('(cyrusEditFingerprint (for i=1 to 100000 collect TerraceCapacityRoot.groupSnapshotRows[1][i]) "prefix")')
    check(str(prefix)==old,'Existing IDs and full transforms unchanged across growth')
    r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
    if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
    panel=root.populationUI;panel.open=True;root.mainUI.bindSection(panel)
    # Presentation aliases are generated from the maintained control map.
    check(bool(panel.controlsReady),'Amount page bound to the intended layer')
    panel.distributionUI_countSpin.value=1000000;panel.distributionUI_countSpin.changed(1000000)
    check(int(leaf.amount)==1000000 and int(panel.distributionUI_countSpin.value)==1000000,'Amount control accepts one million')
    r.CyrusPerfHeadless=True
    leaf.amount=1000000;update(root,'Full one-million population')
    check(int(leaf.generatedCount)==1000000 and not str(leaf.previewError),'One million published without truncation')
    complete=state(root);root.newLayer();second=root.selectedLayer();root.setLayerSurfaces(second,arr([receiver]));second.sources=arr([source]);second.amount=1
    update(root,'Reject root admission overflow')
    check(int(root.procEpoch)==complete['epoch'] and fingerprint(root)==complete['fingerprints'],'Admission overflow retains complete publication')
    check('1,000,000' in str(leaf.previewError),'Admission error explains shared root limit')
    # Return to one layer and exercise a failed UV successor against a real result.
    root.removeLogicalLayer(second)
    leaf.amount=150001;update(root,'Recover a smaller population');before=state(root)
    leaf.distributionMode=3;leaf.densityMap=r.Noise()
    update(root,'Missing receiver mapping')
    check(int(root.procEpoch)==before['epoch'] and fingerprint(root)==before['fingerprints'],'Missing UV retains preceding result')
    check('Receiver UV witness' in str(leaf.previewError) and 'UV channel 1' in str(leaf.previewError),'UV error identifies the receiver and repair')
    leaf.distributionMode=1;update(root,'Restore valid recipe')
    check(not str(leaf.previewError),'Error clears after restoring valid input')
    expected=fingerprint(root);scene=OUT/'Capacity_150001.max';r.saveMaxFile(str(scene),quiet=True)
    r.loadMaxFile(str(scene),quiet=True,useFileUnits=True);root=r.getNodeByName('Capacity 0.81.5').baseObject
    update(root,'Reopen expanded population')
    check(fingerprint(root)==expected and int(root.layerObjects[0].generatedCount)==150001,'Save/reopen preserves expanded placement identities')
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:write()
if data['status']!='complete':raise RuntimeError(data['error'])
