"""Download actual editable and compiled website artifacts using the studio menus."""
from pathlib import Path
import importlib.util
import hashlib
import json
import time

spec=importlib.util.spec_from_file_location('building_browser',Path(__file__).with_name('building-browser.py'))
api=importlib.util.module_from_spec(spec);spec.loader.exec_module(api)
browser,evaluate=api.browser,api.evaluate
folder=api.ASSETS
rows=[]
for menu,selector,name in [
    ('project-menu','save-project','BAILEY-editable.cyrus-presentation.zip'),
    ('output-menu','export-website','BAILEY-presentation.zip'),
]:
    path=folder/name
    if path.exists():raise RuntimeError('Preserve the existing artifact: '+str(path))
    browser('click',f'[data-testid="{menu}"]')
    start=time.monotonic();browser('download',f'[data-testid="{selector}"]',str(path));elapsed=time.monotonic()-start
    rows.append(dict(file=str(path),bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),elapsedSeconds=elapsed))
    print(json.dumps(rows[-1]),flush=True)
state=evaluate('const c=window.__cyrusStudio.controller;JSON.stringify({project:c.project,error:c.error,status:c.status,stats:{...c.host.stats},time:c.time})')
(folder/'authoring-state-v1.json').write_text(json.dumps(state,indent=2)+'\n')
(folder/'downloads-v1.json').write_text(json.dumps(rows,indent=2)+'\n')
if state.get('error'):raise RuntimeError(state['error'])
