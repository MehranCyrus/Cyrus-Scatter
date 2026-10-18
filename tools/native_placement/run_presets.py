"""Eight ready packages on the native route; Undo/Redo without source packages."""
import argparse,json,shutil,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
source=(ROOT/'tools/memory_0854/presets.ms').read_text(encoding='utf-8-sig')
source=source.replace('PresetTestRoot.updateMode=1;CyrusPerfHeadless=false','PresetTestRoot.updateMode=1;if isProperty PresetTestRoot #procNativeRoute do PresetTestRoot.procNativeRoute=true;CyrusPerfHeadless=false')
source=source.replace('PresetTestRoot.refreshAll()', 'if isProperty PresetTestRoot #procNativeRoute do PresetTestRoot.procNativeRoute=true;PresetTestRoot.refreshAll()')
source=source.replace('global PresetLoadedLayers=', 'check (PresetTestRoot.procNativePublication!=undefined and (for rows in PresetTestRoot.groupSnapshotRows where not cyrusPlacementIsNative rows collect rows).count==0) "Every preset population uses native publication" log\n   global PresetLoadedLayers=')
script=host/'native-presets.ms';script.write_text(source,encoding='utf-8-sig')
inventory=json.loads((ROOT/'AminScatter/library/inventory.json').read_text())
for entry in inventory['entries']:
    identity=entry['id'];(host/'acceptance-id.txt').write_text(identity)
    owned=host/('native-package-'+identity);missing=host/('native-package-'+identity+'-unavailable')
    assert owned.parent==host and not owned.exists() and not missing.exists()
    shutil.copytree(ROOT/'AminScatter/library'/entry['ready_package'],owned)
    (host/'preset-path.txt').write_text(owned.as_posix())
    for phase in ['setup','load','verify','undo','verifyUndo','redo','verifyRedo','reopen','verifyReopen']:
        (host/'acceptance-phase.txt').write_text(phase)
        if phase=='verify':
            probe=host/'native-preset-ready.ms';probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"preset-ready.txt") ((CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) as string)')
            deadline=time.monotonic()+120
            while True:
                send(host,probe,'ready')
                if (host/'preset-ready.txt').read_text(encoding='utf-8-sig')=='true':break
                if time.monotonic()>deadline:raise TimeoutError('Observe preset progress before retry')
                time.sleep(.5)
        if phase=='undo':owned.rename(missing)
        send(host,script,identity+' '+phase)
        result=(host/f'acceptance-{identity}-{phase}.txt').read_text(encoding='utf-8-sig')
        assert 'PASS: complete' in result and 'FAIL:' not in result,result
print('ALL EIGHT NATIVE PRESETS, PACKAGE-INDEPENDENT UNDO/REDO AND PERSISTENCE PASSED',flush=True)
