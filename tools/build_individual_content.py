"""Index an explicitly prepared individual-model library for local installation.

Does not prepare geometry, run Max, render, or publish private model content.
"""
from pathlib import Path
import argparse
import collections
import hashlib
import json


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def contained(root, name):
    parts = name.split('/')
    if not name or '\\' in name or any(p in ('', '.', '..') or ':' in p for p in parts):
        raise ValueError('Invalid relative content path: ' + name)
    path = root.joinpath(*parts)
    if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root):
        raise ValueError('Missing or escaping content file: ' + name)
    return path


def build(folder):
    folder = folder.resolve(strict=True)
    library = folder / 'Library'
    catalog = json.loads((library / 'model-catalog.json').read_text(encoding='utf-8'))
    if ((catalog.get('format'), catalog.get('formatVersion')) != ('cyrus.individual-model-library', 1)
            or catalog.get('max_year') not in (2024,2027)):
        raise ValueError('Unexpected model catalog format/host')
    entries = catalog['entries']
    if len(entries) != 96 or catalog.get('source_cards') != 104:
        raise ValueError('Expected the mapped 104-card / 96-individual delivery')
    identifiers, paths, names = set(), set(), set()
    for entry in entries:
        identity = entry['id']
        if identity in identifiers or entry['name'].casefold() in names:
            raise ValueError('Duplicate model identity/name: ' + identity)
        identifiers.add(identity)
        names.add(entry['name'].casefold())
        if entry['geometry_count'] != 1 or entry['node_name'] != 'CyrusModel_' + identity:
            raise ValueError('Expected one complete source per model: ' + identity)
        scene = contained(library, entry['scene'])
        if scene.stat().st_size != entry['scene_bytes'] or digest(scene) != entry['scene_sha256']:
            raise ValueError('Prepared scene identity changed: ' + identity)
        thumbnail = contained(library, entry['thumbnail'])
        if thumbnail.stat().st_size > 2 * 1024 * 1024:
            raise ValueError('Thumbnail exceeds gallery limit: ' + identity)
        with thumbnail.open('rb') as stream:
            if stream.read(2) != b'\xff\xd8':
                raise ValueError('Expected original Corona JPEG: ' + identity)
        if entry['scene'] in paths:
            raise ValueError('Two entries share one scene: ' + identity)
        paths.add(entry['scene'])
    files = {}
    total = 0
    for path in sorted(library.rglob('*')):
        if path.is_dir():
            continue
        name = path.relative_to(folder).as_posix()
        contained(folder, name)
        size = path.stat().st_size
        if size <= 0 or size > 2 * 1024**3:
            raise ValueError('Content file outside declared size bounds: ' + name)
        total += size
        files[name] = {'bytes': size, 'sha256': digest(path)}
    if len(files) > 4096 or total > 16 * 1024**3:
        raise ValueError('Content exceeds installer profile')
    manifest = {'format': 'cyrus.scatter.content', 'schema': 1,
                'version': catalog['version'], 'max_year': 2027, 'files': files}
    if catalog['max_year']==2024:
        manifest.update(schema=2,max_year=2024,hosts={'2024':1,'2026':1,'2027':1})
    encoded = (json.dumps(manifest, indent=2, ensure_ascii=True) + '\n').encode('utf-8')
    if len(encoded) > 1024 * 1024:
        raise ValueError('Content manifest exceeds installer profile')
    target = folder / 'content-manifest.json'
    target.write_bytes(encoded)
    report = {'version': catalog['version'], 'source_cards': 104, 'individual_models': len(entries),
              'categories': dict(sorted(collections.Counter(e['category'] for e in entries).items())),
              'files': len(files), 'bytes': total, 'manifest_sha256': digest(target),
              'scope': 'File/identity/category/thumbnail metadata checks; no host qualification'}
    (folder.parent / 'CONTENT-REPORT.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('content', type=Path)
    build(parser.parse_args().content)
