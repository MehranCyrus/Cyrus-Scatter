"""Stage only verified original content and the eight current ready packages."""
from pathlib import Path
import argparse, hashlib, json, shutil

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser();p.add_argument('profile', type=Path);a = p.parse_args()
host = a.profile.resolve()
assert host.parent == ROOT / 'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
base = ROOT / 'build/presets-0853-20261016-01'
source, target = base / 'library', ROOT / 'AminScatter/library'
baseline = json.loads((base / 'library-baseline.json').read_text(encoding='utf-8'))
sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for name, digest in baseline.items():
    assert sha(target / name) == digest, 'Existing library changed: ' + name
inventory = json.loads((source / 'inventory.json').read_text(encoding='utf-8'))
files = set(baseline) - {'inventory.json'}
for entry in inventory['entries']:
    record = json.loads((host / f"library-{entry['id']}-capture.json").read_text(encoding='utf-8'))
    assert record['status'] == 'passed'
    recipe = source / entry['recipe'];data = json.loads(recipe.read_text(encoding='utf-8'))
    assert sha(recipe) == record['recipe_sha256']
    package = Path(record['package']).resolve()
    assert package.is_relative_to(source / 'Presets') and (package / 'cyrus.package.json').is_file()
    entry['ready_package'] = package.relative_to(source).as_posix()
    entry['ready_package_sha256'] = sha(package / 'cyrus.package.json')
    entry['ready_assets'] = {'meshes':record['nodes'], 'splines':record['splines']}
    for path in package.rglob('*'):
        if path.is_file():files.add(path.relative_to(source).as_posix())
    if data['presentation']['thumbnail']:
        entry['thumbnail'] = data['presentation']['thumbnail']['file']
        files.add(entry['thumbnail'])
    for layer in data['layers']:
        for paint in [layer['paint']] + [area['paint'] for area in layer['areas']]:
            if paint:files.add(paint['payload']['file'])
inventory.update(version='0.85.3', previous_qualification_version='0.85.2',
                 qualification_host=host.name, ready_preset_contract='asset graph 2; Add Layers; compatible current or included terrain; explicit Load + Update')
for name in sorted(files):
    src, dst = source / name, target / name
    assert src.is_file() and src.resolve().is_relative_to(source)
    if dst.exists() and name not in baseline:
        assert sha(src) == sha(dst), 'Unowned new-path collision: ' + name
    dst.parent.mkdir(parents=True, exist_ok=True);shutil.copy2(src, dst)
inventory['files'] = {name:sha(target / name) for name in sorted(files)}
(target / 'inventory.json').write_text(json.dumps(inventory, indent=2)+'\n', encoding='utf-8')
(base / 'library-staging.json').write_text(json.dumps({'files':len(files),'entries':8,
    'inventory_sha256':sha(target / 'inventory.json'),'preserved_original_scene_hashes':{name:h for name,h in baseline.items() if name.endswith('.max')}},indent=2)+'\n',encoding='utf-8')
print('Staged', len(files), 'files, including eight ready presets')
