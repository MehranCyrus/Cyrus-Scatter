"""Compare actual studio renderings of the owned grille reduction variants."""
from pathlib import Path
import base64
import json
import subprocess
import time

APP = Path(__file__).resolve().parents[3]
OUTPUT = APP / 'exports/building-20261016/grille-comparison'
ASSETS = OUTPUT.parent
CLI = 'C:/Users/Mehran/AppData/Local/npm-cache/_npx/6de2aa2fded2970c/node_modules/agent-browser/bin/agent-browser-win32-x64.exe'
PREFIX = [CLI, '--session', 'building-study']


def browser(*args, script=None):
    p = subprocess.run(PREFIX + list(args), input=script, capture_output=True, text=True, encoding='utf-8', errors='replace')
    if p.returncode:
        raise RuntimeError(p.stderr or p.stdout)
    return p.stdout.strip()


def evaluate(script):
    script = '(async () => {' + script.replace('JSON.stringify(', 'return JSON.stringify(') + '})()'
    value = json.loads(browser('eval', '--stdin', script=script))
    return json.loads(value) if isinstance(value, str) else value


if __name__ == '__main__':
    OUTPUT.mkdir(parents=True, exist_ok=True)
    results = []
    for variant in ['original', 'panel-10', 'panel-5', 'panel-2', 'panel-1']:
        evaluate("await window.__cyrusStudio.controller.act('newProject'); JSON.stringify({ready:true})")
        started = time.monotonic()
        browser('upload', '#file-glb', str(ASSETS / ('grille-' + variant + '.glb')))
        browser('wait', '--fn', 'window.__cyrusStudio.controller.pending === false && window.__cyrusStudio.controller.project.instances.length === 1')
        imported = time.monotonic() - started
        for view, angle, distance in [('front', 0, 3.5), ('oblique', .55, 3.5), ('detail', 0, 1.8)]:
            script = """const c=window.__cyrusStudio.controller;
            await c.act('updateProject',{lighting:{exposure:1,shadows:false}});
            await c.act('mode','explore');
            const bounds=c.project.assets[0].bounds, center=bounds.min.map((v,i)=>(v+bounds.max[i])/2);
            const angle=ANGLE,nx=.905*Math.cos(angle)-.425*Math.sin(angle),nz=-.905*Math.sin(angle)-.425*Math.cos(angle);
            c.host.perspective.position.set(center[0]+nx*DISTANCE,center[1]+.25,center[2]+nz*DISTANCE);
            c.host.perspective.lookAt(...center);c.host.perspective.fov=40;c.host.perspective.updateProjectionMatrix();c.host.draw();
            JSON.stringify({image:c.host.canvas.toDataURL('image/png'),pose:c.host.capture(),asset:c.project.assets[0],stats:c.host.stats});
            """.replace('ANGLE', str(angle)).replace('DISTANCE', str(distance))
            data = evaluate(script)
            image = data.pop('image')
            path = OUTPUT / f'{variant}-{view}.png'
            path.write_bytes(base64.b64decode(image.split(',')[1]))
            results.append(dict(variant=variant, view=view, importSeconds=imported, screenshot=str(path), **data))
        (OUTPUT / 'browser-comparison.json').write_text(json.dumps(results, indent=2) + '\n')
        print(variant + ' rendered', flush=True)
