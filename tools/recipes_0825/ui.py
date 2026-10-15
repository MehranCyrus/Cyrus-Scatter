"""Actual recipe controls and passive browser work in the owned Max editor."""
from pathlib import Path
import json,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.name.startswith('foundation-roadmap-recipes0825-')
data={'status':'started','checks':[]}
def save():(OUT/'recipe-ui.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def check(v,label):
    data['checks'].append({'passed':bool(v),'label':label});save()
    if not v:raise AssertionError(label)
def counters(root):
    native=r.CyrusPointOwner(r.getNodeByName('Recipe 0.82.5 source'))
    stats=list(r.cyrusRetainedStats(native)) if r.isValidNode(native) else [0]*7
    return [int(root.procEpoch),int(root.groupBuilds),[int(x.procPreparedBuilds) for x in root.layerObjects],[list(x.receiverCacheStats())[:2] for x in root.layerObjects],[int(x) for x in r.cyrusMeshDensityStats()],[int(stats[5]),int(stats[6])]]
try:
    with pymxs.undo(False):
        r.loadMaxFile(str(OUT/'recipe-qualified.max'),quiet=True)
        node=r.getNodeByName('Recipe 0.82.5 source');root=node.baseObject
        root.updateMode=1;r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode')
        r.modPanel.setCurrentObject(root)
        if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
        root.managerUI.open=True;root.mainUI.bindSection(root.managerUI)
        root.refreshAll();r.CyrusPointSync();r.completeRedraw();r.completeRedraw();baseline=counters(root)
        root.managerUI.flow_layersUI_recipesButton.pressed();browser=r.CyrusRecipeBrowser
        check(browser is not None,'Actual Layers Recipes button opens the library')
        directory=OUT/('ui-library-'+Path(str(r.MCPFixtureLast)).stem)
        browser.directory=str(directory);browser.refresh()
        browser.recipeName.text='UI saved complete setup';browser.saveLayers.selection=r.BitArray(1,2,3)
        browser.saveRecipe.pressed();data['save_status']=str(browser.status.text)
        check('Saved all supported' in data['save_status'],'Actual Save Everything handler succeeds')
        check(len(list(directory.glob('*.csrecipe.json')))==1,'Save handler writes one native recipe manifest')
        check(counters(root)==baseline,'Saving through the real UI does no calculation/preparation/upload work')
        times=[]
        for _ in range(30):
            start=time.perf_counter();browser.refreshButton.pressed();times.append((time.perf_counter()-start)*1000)
        check(counters(root)==baseline,'Thirty passive browser refreshes preserve work counters')
        browser.reviewButton.pressed();data['review_status']=str(browser.status.text)
        check(len(browser.roleList.items)>0,'Review lists dependency roles')
        browser.suggestButton.pressed();check(all('UNBOUND' not in str(x) for x in browser.roleList.items),'Explicit name matching proposes scene bindings')
        check(counters(root)==baseline,'Review and binding suggestions do not solve scattering')
        browser.importButton.pressed();data['import_status']=str(browser.status.text)
        check('Imported as one Undo.' in data['import_status'],'Actual Import handler commits the reviewed recipe')
        check(int(root.updateMode)==1 and int(root.procEpoch)==baseline[0],'Actual UI import preserves Manual publication')
        check(len(root.layerObjects)==9,'UI Add appends the three selected layers')
        data['refresh_ms']={'median':sorted(times)[len(times)//2],'p95':sorted(times)[int(.95*(len(times)-1))]}
        r.destroyDialog(browser)
        check(r.CyrusRecipeBrowser is None,'Closing the library releases its view')
        r.RecipeUIRoot=root;r.RecipeUINode=node
        data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise
