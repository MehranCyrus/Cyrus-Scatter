"""Matched geometry-only comparison, outside production GLB admission limits."""
from pathlib import Path
import base64
import importlib.util
import json

spec = importlib.util.spec_from_file_location('building_browser', Path(__file__).with_name('building-browser.py'))
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)
browser, evaluate = api.browser, api.evaluate
OUT = api.ASSETS / 'silhouette-comparison'
URL = 'http://127.0.0.1:5190/@fs/F:/Cursor/_Cyrus_Apps/CyrusScatter/presentation-studio/exports/building-20261016/quality-viewer.html?asset='
OUT.mkdir(exist_ok=True)
results = []
for asset in ['baseline-native.glb', 'building-support-creases-e0003-context-v4.glb']:
    state = evaluate("JSON.stringify(window.quality ? {ready:window.quality.ready,asset:window.quality.asset} : {})")
    if state.get('asset') != asset or not state.get('ready'):
        browser('open', URL + asset)
        browser('wait', '--fn', 'window.quality && (window.quality.ready || window.quality.error)')
    state = evaluate("JSON.stringify(window.quality)")
    if not state.get('ready'):
        raise RuntimeError(json.dumps(state))
    for name, position, target, fov in api.VIEWS:
        position = [a+b for a,b in zip(position,[40,19,-17])]
        target = [a+b for a,b in zip(target,[40,19,-17])]
        data = evaluate('const pose=window.quality.setView('+json.dumps(position)+','+json.dumps(target)+','+str(fov)+'); JSON.stringify({pose,image:window.quality.capture()})')
        filename = asset.removesuffix('.glb') + '-' + name + '.png'
        (OUT / filename).write_bytes(base64.b64decode(data.pop('image').split(',')[1]))
        results.append(dict(asset=asset, view=name, screenshot=filename, state=state, **data))
    print(asset + ' geometry-only comparison captured', flush=True)
(OUT / 'capture-receipt.json').write_text(json.dumps(results,indent=2)+'\n')
