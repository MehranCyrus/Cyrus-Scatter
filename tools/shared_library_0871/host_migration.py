"""Actual native validation of legacy package migration and consolidation."""
from pathlib import Path
import hashlib,json,shutil,time,traceback
from pymxs import runtime as r
OUT=Path(str(r.GardenRun));DATA=Path(str(r.CyrusSharedLibraryRootOverride)).parent;checks=[]
def check(value,message):
    if not value:raise AssertionError(message)
    checks.append(message)
def wait(predicate):
    until=time.monotonic()+180
    while time.monotonic()<until:
        if predicate():return
        r.windows.processPostedMessages();r.execute('(dotNetClass "System.Windows.Forms.Application").DoEvents()');time.sleep(.01)
    raise AssertionError('operation timeout')
def operation(job):
    wait(lambda:bool(job.Terminal));check(str(job.State)=='complete','file operation: '+str(job.Error));return str(job.Result)
def reset_scene():
    r.resetMaxFile(r.Name('noPrompt'))
    if bool(r.GardenSupportedOCIO):r.execute('ColorPipelineMgr.Mode=#OCIO_Default')

def main():
    seed=r.CyrusSharedStore();operation(seed.Import(str(r.GardenLibraryArchive)));legacy=DATA/'legacy';legacy.mkdir()
    for index,path in enumerate(list(seed.RecipePaths())[:2]):
        path=Path(str(path));sha=hashlib.sha256(path.read_bytes()).hexdigest();shutil.copy2(path,legacy/f'look{index}.csrecipe.json');shutil.copytree(path.parent,legacy/'Presets'/sha)
    r.CyrusSharedLibraryInstance=None;r.CyrusSharedLibraryRootOverride=str(DATA/'migrated');store=r.CyrusSharedStore()
    operation(store.Migrate(str(legacy)));paths=list(store.RecipePaths());check(len(paths)==2 and len(list(store.Models()))==3,'native migration adopts complete recipes and three models')
    head=(Path(str(store.Root))/'catalog/current.json').read_bytes();operation(store.Migrate(str(legacy)));check((Path(str(store.Root))/'catalog/current.json').read_bytes()==head,'unchanged migration retains catalog head')
    originals=list((legacy/'Presets').glob('*/assets/*'));check(all(p.stat().st_ino!=(Path(str(store.Root))/'objects'/p.stem).stat().st_ino for p in originals),'migration initially retains original allocations')
    operation(store.ConsolidateMigrated(str(legacy)));check(all(p.stat().st_ino==(Path(str(store.Root))/'objects'/p.stem).stat().st_ino for p in originals),'explicit consolidation shares native dependency allocations at original paths')
    operation(store.ConsolidateMigrated(str(legacy)));check(all(p.exists() for p in originals),'repeat consolidation preserves original filenames')
    bad=DATA/'bad';shutil.copytree(legacy,bad);first=next((bad/'Presets').glob('*/assets/*.cmesh'));first.write_bytes(b'Owned corrupt package')
    job=store.Migrate(str(bad));wait(lambda:bool(job.Terminal));check(str(job.State)=='failed','present corrupt legacy package is rejected by actual native validation');check((Path(str(store.Root))/'catalog/current.json').read_bytes()==head,'failed native migration retains previous committed head')
    for path in paths:
        reset_scene();target=r.plane(width=500,length=500);digest=str(r.cyrusRecipeInfo(str(path))[10]);package=str(r.CyrusPresetPackageDirectory(str(path),digest));r.CyrusOpenReadyPreset(None,package,expected=digest,surface=target)
        wait(lambda:bool(r.CyrusReadyPresetEditor.finished));editor=r.CyrusReadyPresetEditor;check(editor.result is not None,'migrated complete recipe opens in a fresh scene: '+str(editor.status.text));r.destroyDialog(editor)
    (OUT/'migration.json').write_text(json.dumps(dict(status='pass',checks=checks),indent=2));(OUT/'completed.json').write_text(json.dumps(dict(status='pass',checks=len(checks))))
try:
    if r.theHold.Holding():r.theHold.Accept('Owned migration startup')
    main()
except Exception:(OUT/'error.txt').write_text(traceback.format_exc())
