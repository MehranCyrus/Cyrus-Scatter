"""Import owned building variants into the actual studio and capture matched views."""
from pathlib import Path
import base64
import importlib.util
import json
import sys
import time

spec = importlib.util.spec_from_file_location('grille_browser', Path(__file__).with_name('grille-browser.py'))
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)
browser, evaluate = api.browser, api.evaluate
ASSETS = Path(__file__).resolve().parents[3] / 'exports/building-20261016'
OUTPUT = ASSETS / 'building-comparison'
VIEWS = [
    ('establishing', [-135, 44, 140], [-40, -2, 17], 40),
    ('street-corner', [-135, 25, -100], [-40, -2, 17], 40),
    ('reverse', [55, 30, -80], [-40, -2, 17], 40),
    ('courtyard', [45, 35, 130], [-40, -2, 17], 40),
    ('facade-detail', [-85, -5, 76], [-45, -8, 29], 40),
]

if __name__ == '__main__':
    OUTPUT.mkdir(exist_ok=True)
    browser('set', 'viewport', '1600', '1000')
    architectural='--architectural' in sys.argv
    for variant in [v for v in sys.argv[1:] if not v.startswith('--')] or ['quantized-v3']:
        prefix=variant+('-architectural' if architectural else '')
        evaluate("await window.__cyrusStudio.controller.act('newProject'); JSON.stringify({ready:true})")
        started = time.monotonic()
        browser('upload', '#file-glb', str(ASSETS / f'building-{variant}.glb'))
        browser('wait', '--fn', 'window.__cyrusStudio.controller.pending === false && (window.__cyrusStudio.controller.project.instances.length === 1 || Boolean(window.__cyrusStudio.controller.error))')
        imported = time.monotonic() - started
        state = evaluate("const c=window.__cyrusStudio.controller; JSON.stringify({assets:c.project.assets.length,error:c.error,status:c.status})")
        if state['assets'] != 1:
            raise RuntimeError(json.dumps(state))
        results = []
        for name, position, target, fov in VIEWS:
            if variant.endswith(('-v4','-v5')):
                position=[a+b for a,b in zip(position,[40,19,-17])]
                target=[a+b for a,b in zip(target,[40,19,-17])]
            script = """const c=window.__cyrusStudio.controller;
            await c.act('updateProject',{title:'BAILEY · Architecture in motion',lighting:{exposure:EXPOSURE,shadows:SHADOWS,style:'LIGHT_STYLE'}});
            await c.act('mode','explore');
            c.host.perspective.position.fromArray(POSITION);c.host.perspective.lookAt(...TARGET);
            c.host.perspective.fov=FOV;c.host.perspective.updateProjectionMatrix();c.host.draw();
            JSON.stringify({image:c.host.canvas.toDataURL('image/png'),pose:c.host.capture(),asset:c.project.assets[0],layers:c.project.layers,stats:{...c.host.stats}});
            """.replace('POSITION', json.dumps(position)).replace('TARGET', json.dumps(target)).replace('FOV', str(fov)).replace('SHADOWS','true' if variant.endswith(('-v4','-v5')) else 'false').replace('EXPOSURE','.8' if architectural else '1').replace('LIGHT_STYLE','architectural' if architectural else 'soft')
            data = evaluate(script)
            image = data.pop('image')
            path = OUTPUT / f'{prefix}-{name}.png'
            path.write_bytes(base64.b64decode(image.split(',')[1]))
            results.append(dict(variant=variant, view=name, importSeconds=imported, screenshot=str(path), **data))
        browser('screenshot', str(OUTPUT / f'{prefix}-studio.png'))
        (OUTPUT / f'{prefix}-browser.json').write_text(json.dumps(results, indent=2) + '\n')
        print(json.dumps(dict(variant=variant, importSeconds=imported, stats=results[-1]['stats'],layers=len(results[-1]['layers']))), flush=True)
