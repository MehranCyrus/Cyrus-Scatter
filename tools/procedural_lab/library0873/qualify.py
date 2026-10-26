"""Owned Max 2027 startup regression; normal config paths, no root override.

Run only through the isolated launcher. The fixture LibraryBinding must retain
the read-only installed content and use build/l873a/fallback as its managed root.
"""
from pathlib import Path
import hashlib
import json
import time
import traceback
from pymxs import runtime as rt

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(str(rt.GardenRun))
DATA = ROOT / 'build/l873a'
ENV = DATA / 'appdata'
CONFIG = ENV / 'CyrusScatter/personal-library.txt'
FALLBACK = DATA / 'fallback'
SECOND = DATA / 'chosen'
report = {'version': '0.87.3', 'root_override_used': False}


def save():
    (OUT / 'checks.json').write_text(json.dumps(report, indent=2), encoding='utf8')


def settle(seconds=.25):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        rt.windows.processPostedMessages()
        time.sleep(.01)


def same_path(a, b):
    return Path(str(a)).resolve() == Path(b).resolve()


def open_and_check(root, expected):
    assert rt.CyrusSharedLibraryRootOverride == rt.undefined
    rt.CyrusOpenRecipeLibrary(root)
    settle()
    browser = rt.CyrusRecipeBrowser
    assert str(browser.panel.NoticeText) == '', str(browser.panel.NoticeText)
    assert int(browser.panel.Gallery.ItemCount) == 96
    assert same_path(rt.CyrusSharedStore().Root, expected)
    rt.destroyDialog(browser)


def main():
    DATA.mkdir(exist_ok=False)
    ENV.mkdir()
    owner = rt.AminScatterObject()
    root = owner.baseObject
    assert str(root.uiVersion()) == '0.87.3'
    env = rt.dotNetClass('System.Environment')
    original_env = str(env.GetEnvironmentVariable('LOCALAPPDATA'))
    artist_config = Path(original_env) / 'CyrusScatter/personal-library.txt'
    artist_before = artist_config.read_bytes() if artist_config.exists() else None
    rt.execute('CyrusPerfHeadless=true;CyrusPointSuspended=true')
    try:
        env.SetEnvironmentVariable('LOCALAPPDATA', str(ENV))
        rt.CyrusSharedLibraryRootOverride = rt.undefined
        rt.CyrusSharedLibraryInstance = rt.undefined
        assert not CONFIG.exists()
        open_and_check(root, FALLBACK)
        report['missing_config_fallback_open'] = True
        assert not CONFIG.exists(), 'Opening must not choose a new saved preference'
        rt.CyrusSharedUseRoot(str(SECOND))
        assert rt.CyrusSharedLibraryRootOverride == rt.undefined
        assert same_path(CONFIG.read_text(encoding='utf8').strip(), SECOND)
        rt.CyrusSharedLibraryInstance = rt.undefined
        open_and_check(root, SECOND)
        report['normal_config_open_and_persistence'] = True
        before = CONFIG.read_bytes()
        rejected = False
        try:
            rt.CyrusSharedUseRoot(str(DATA / ('long-' + 'x' * 90)))
        except Exception:
            rejected = True
        assert rejected and CONFIG.read_bytes() == before
        assert same_path(rt.CyrusSharedStore().Root, SECOND)
        report['invalid_root_preserves_preference'] = True
        save()
    finally:
        env.SetEnvironmentVariable('LOCALAPPDATA', original_env)

    # Existing artist-test scene: load only, never overwrite it.
    scene = ROOT / 'dist/CyrusScatter-0.87.2-20261026-r2/Trials/Small_Test_Interaction_0.87.2.max'
    report['input_scene_sha256'] = hashlib.sha256(scene.read_bytes()).hexdigest()
    rt.loadMaxFile(str(scene), quiet=True, useFileUnits=True,
                   missingDLLsAction=rt.Name('logmsg'))
    owner = next(n for n in rt.objects
                 if str(rt.classOf(n.baseObject)) == 'AminScatterObject'
                 and n.baseObject.overlapOwner == rt.undefined)
    root = owner.baseObject
    rt.CyrusPerfHeadless = False
    rt.CyrusPointSuspended = False
    rt.CyrusPointSync()
    rt.completeRedraw()
    settle(2)
    assert int(root.version) == 61 and str(root.uiVersion()) == '0.87.3'
    stats = json.loads(str(root.interactionsStatistics()))
    assert stats['plants'] == 3650 and stats['obstacles'] == 2 and not stats['error']
    assert [int(l.generatedCount) for l in root.layerObjects] == [71, 3579, 536, 2526, 2]
    report['interaction_scene'] = stats

    rt.execute('global L873Owner,L873Root,L873Env,L873OriginalEnv,L873Epoch,L873Builds')
    rt.L873Owner, rt.L873Root = owner, root
    rt.L873Env, rt.L873OriginalEnv = str(ENV), original_env
    root.layerObjects[0].amount = 209
    root.selectLayer(5)
    rt.select(owner)
    rt.execute('max modify mode;subObjectLevel=0;modPanel.setCurrentObject L873Root')
    settle(.5)
    rt.L873Epoch, rt.L873Builds = int(root.procEpoch), int(root.groupBuilds)
    env.SetEnvironmentVariable('LOCALAPPDATA', str(ENV))
    rt.CyrusSharedLibraryInstance = rt.undefined
    rt.execute('global MCPFixtureDir=GardenRun;fileIn @"' +
               (ROOT / 'tools/mcp/development_transport.ms').as_posix() + '"')
    report['artist_config_unchanged'] = (
        artist_before == (artist_config.read_bytes() if artist_config.exists() else None))
    assert report['artist_config_unchanged']
    report['status'] = 'ready for physical Recipes button'
    save()
    (OUT / 'ready.json').write_text('{"status":"ready"}', encoding='utf8')


try:
    main()
except Exception:
    save()
    (OUT / 'error.txt').write_text(traceback.format_exc(), encoding='utf8')
