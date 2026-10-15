"""Bounded cold/warm recipe metadata pages, including damaged entries."""
from pathlib import Path
import json,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.name.startswith('foundation-roadmap-recipes0825-')
data={'status':'started','checks':[],'timings_ms':{}}
def save():(OUT/'recipe-library-performance.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def check(v,label):
    data['checks'].append({'passed':bool(v),'label':label});save()
    if not v:raise AssertionError(label)
def counters(root):
    owner=r.CyrusPointOwner(r.getNodeByName('Recipe 0.82.5 source'));native=list(r.cyrusRetainedStats(owner))
    return [int(root.procEpoch),int(root.groupBuilds),[int(x.procPreparedBuilds) for x in root.layerObjects],[int(x) for x in r.cyrusMeshDensityStats()],[int(native[5]),int(native[6])]]
try:
    with pymxs.undo(False):
        # Open with open_fixture.ms in a preceding serialized request so Max's
        # file callbacks and retained-display timers have returned to its loop.
        root=r.getNodeByName('Recipe 0.82.5 source').baseObject;r.CyrusPerfHeadless=False
        root.refreshAll();r.CyrusPointSync();r.completeRedraw();r.completeRedraw();before=counters(root)
        source=json.loads((OUT/'recipes-qualification.json').read_text())['recipe_file'];payload=Path(source).read_bytes()
        directory=OUT/'library-2000';directory.mkdir(exist_ok=True)
        # Reuse the owned corpus on later campaigns. Rewriting ~100 MB directly
        # before timing also benchmarks OS/background storage work, not browsing.
        for i in range(2000):
            entry=directory/f'entry-{i:04}.csrecipe.json'
            if not entry.exists():entry.write_bytes(payload)
        if not (directory/'broken.csrecipe.json').exists():(directory/'broken.csrecipe.json').write_bytes(b'{broken')
        if not (directory/'future.csrecipe.json').exists():(directory/'future.csrecipe.json').write_bytes(payload.replace(b'"formatVersion": 1',b'"formatVersion": 99'))
        r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser;browser.directory=str(directory);browser.page=1
        start=time.perf_counter();browser.refresh();data['timings_ms']['cold_first_page']=(time.perf_counter()-start)*1000
        check(len(browser.files)==2002 and len(browser.entries)<=128,'Library enumerates 2,002 files but admits only one bounded page')
        check('invalid entries skipped' in str(browser.status.text),'Damaged entries remain isolated')
        timings=[]
        for _ in range(30):
            start=time.perf_counter();browser.refresh();timings.append((time.perf_counter()-start)*1000)
        data['timings_ms']['warm_median']=sorted(timings)[15];data['timings_ms']['warm_p95']=sorted(timings)[int(.95*(len(timings)-1))]
        check(data['timings_ms']['warm_p95']<100,'Warm page refresh p95 remains below the proposed 100 ms local target')
        for _ in range(5):browser.nextButton.pressed()
        check(browser.page==6 and len(browser.metadataCache)<=512,'Paging keeps metadata cache within 512 entries')
        check(counters(root)==before,'Large-library browsing causes no solve, mask reads, preparation or uploads')
        r.destroyDialog(browser);data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise
