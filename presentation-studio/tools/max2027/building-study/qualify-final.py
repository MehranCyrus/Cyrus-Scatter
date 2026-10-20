"""Replace the owned studio asset through its review UI, preserving the presentation."""
import base64
import hashlib
import importlib.util
import json
from pathlib import Path
import time
import sys

spec = importlib.util.spec_from_file_location('browser_api', Path(__file__).with_name('grille-browser.py'))
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)
out = api.ASSETS / ('final-browser-' + (sys.argv[1] if len(sys.argv) > 1 else 'v1'))
out.mkdir(exist_ok=False)
source_hash = 'e006b8463f6ed02f537c4584a7749b49af5f1217aba7d01e3a79172a3efb2caa'
path = api.ASSETS / 'reproduction-v4/delivery/optimized.glb'
target_hash = hashlib.sha256(path.read_bytes()).hexdigest()
before = api.evaluate('const c=window.__cyrusStudio.controller; JSON.stringify({project:c.project,stats:{...c.host.stats}})')
if len(before['project']['assets']) != 1 or before['project']['assets'][0]['hash'] != source_hash:
    raise RuntimeError('The owned browser must contain the previously verified compressed presentation.')
(out / 'before.json').write_text(json.dumps(before, indent=2), encoding='utf-8')

def capture(stage):
    rows = []
    for seconds in [2, 7, 16, 29, 38]:
        data = api.evaluate('const c=window.__cyrusStudio.controller; await c.act("mode","playback"); await c.act("time",' + str(seconds) + ');c.host.draw(); JSON.stringify({image:c.host.canvas.toDataURL("image/png"),pose:c.host.capture(),stats:{...c.host.stats}})')
        (out / f'{stage}-{seconds:02d}.png').write_bytes(base64.b64decode(data.pop('image').split(',')[1]))
        rows.append(dict(seconds=seconds, **data))
    return rows

original = capture('source')
api.evaluate('const c=window.__cyrusStudio.controller; await c.act("selectInstance",c.project.instances[0].id); JSON.stringify({ready:true})')
started = time.monotonic()
api.browser('scrollintoview', '[data-action="fileReplace"]')
api.browser('click', '[data-action="fileReplace"]')
api.browser('upload', '#file-replace', str(path))
api.browser('wait', '--fn', 'Boolean(window.__cyrusStudio.controller.replacement) || (!window.__cyrusStudio.controller.pending && Boolean(window.__cyrusStudio.controller.error))')
error = api.evaluate('JSON.stringify({error:window.__cyrusStudio.controller.error})').get('error')
if error:
    raise RuntimeError(error)
review = api.evaluate('const c=window.__cyrusStudio.controller,r=c.replacement; JSON.stringify({asset:r.asset,suggestions:r.suggestions})')
(out / 'review.json').write_text(json.dumps(review, indent=2), encoding='utf-8')
unmatched = [n for n in review['asset']['nodes'] if n['key'] not in review['suggestions']]
if unmatched:
    raise RuntimeError(f'{len(unmatched)} nodes lack an identity match; inspect the review before accepting.')
api.browser('scrollintoview', '[data-action="uiAcceptReplacement"]')
api.browser('click', '[data-action="uiAcceptReplacement"]')
api.browser('wait', '--fn', 'window.__cyrusStudio.controller.replacement === null && !window.__cyrusStudio.controller.pending')
elapsed = time.monotonic() - started
after = api.evaluate('const c=window.__cyrusStudio.controller; JSON.stringify({project:c.project,stats:{...c.host.stats},error:c.error})')
assert after['project']['assets'][0]['hash'] == target_hash
for field in ['id', 'title', 'layers', 'stops', 'segments', 'opening', 'revealDuration', 'lighting']:
    assert before['project'][field] == after['project'][field], f'Presentation changed: {field}'
assert not after.get('error'), after.get('error')
compressed = capture('compressed')
api.evaluate('const c=window.__cyrusStudio.controller; await c.act("time",2); JSON.stringify({ready:true})')
state = api.evaluate('const c=window.__cyrusStudio.controller; JSON.stringify({project:c.project,stats:{...c.host.stats}})')
(api.ASSETS / 'final-presentation-v1/authoring-state.json').write_text(json.dumps(state, indent=2), encoding='utf-8')
report = dict(source=before['project']['assets'][0]['hash'], compressed=target_hash, replacementReviewNodes=len(review['asset']['nodes']), replacementElapsedSeconds=elapsed, presentationPreserved=True, sourceViews=original, compressedViews=compressed, after=after)
(out / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps({k: v for k, v in report.items() if k not in ['sourceViews', 'compressedViews', 'after']}))
