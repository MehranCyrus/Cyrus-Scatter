"""Check the matched Gallery/shared-store identity through an owned host."""
from pathlib import Path
import json
import time
import traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
root_dir = Path(__file__).resolve().parents[3]
path = host / 'library-check.json'
report = {'status': 'running', 'scope': 'Owned host and private shared-library root; no artist preferences changed.'}
try:
    # Shared-library admission intentionally has an 80-character host limit.
    # The long campaign evidence directory is not a valid managed-store path.
    private_root = root_dir / 'build' / 'l8741' / host.name
    assert len(str(private_root)) <= 80, str(private_root)
    r.CyrusSharedLibraryRootOverride = str(private_root)
    r.CyrusSharedLibraryInstance = r.undefined
    store = r.CyrusSharedStore()
    report['store_root'] = str(store.Root)
    report['override'] = str(r.CyrusSharedLibraryRootOverride)
    assert Path(report['store_root']).resolve() == Path(report['override']).resolve(), report
    assembly = r.dotNet.loadAssembly(str(Path(str(r.CyrusRecipeScriptDirectory)) / 'CyrusGallery.dll'))
    report['gallery_version'] = str(assembly.GetName().Version.ToString())
    report['gallery_path'] = str(assembly.Location)
    report['scatter_version'] = str(r.WFRoot.uiVersion())
    assert report['gallery_version'] == report['scatter_version'], report
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    panel = r.WFRoot.mainUI
    until = time.monotonic() + 8.
    while not bool(panel.controlsReady) and time.monotonic() < until:
        r.windows.processPostedMessages()
        time.sleep(.02)
    assert panel.controlsReady, 'Modify panel did not finish mounting'
    report['panel_slot_count'] = len(panel.slots)
    panel.slots[0].open = True
    panel.bindSection(panel.editors[0])
    r.execute('WFRoot.mainUI.editors[1].flow_layersUI_recipesButton.pressed()')
    until = time.monotonic() + 1.
    while time.monotonic() < until:
        r.windows.processPostedMessages()
        time.sleep(.02)
    browser = r.CyrusRecipeBrowser
    assert browser != r.undefined, 'Recipes did not open the Library'
    report['notice'] = str(browser.panel.NoticeText)
    report['gallery_item_count'] = int(browser.panel.Gallery.ItemCount)
    assert not report['notice'], report['notice']
    r.destroyDialog(browser)
    report['status'] = 'pass'
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
finally:
    path.write_text(json.dumps(report, indent=2), encoding='utf-8')
