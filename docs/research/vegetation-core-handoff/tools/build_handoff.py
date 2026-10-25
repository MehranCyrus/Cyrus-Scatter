"""Package documentation and declarations; never execute supplied research code or a DCC."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import zipfile
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlsplit

HANDOFF = Path(__file__).resolve().parents[1]
REPO = HANDOFF.parents[2]
LIBRARY = HANDOFF.parent / 'vegetation-interaction'
EDITION = 'CyrusScatter_Vegetation_Core_Handoff_v1'
CONTEXT = [
    'AminScatter/include/placement_store.h',
    'AminScatter/src/mesh_display.inc',
    'CyrusPhysicsLab/README.md',
    'CyrusPhysicsLab/src/jolt_world.cpp',
    'CyrusPhysicsLab/tools/build.py',
    'docs/AGENT_WORKFLOW.md',
    'docs/DOCUMENTATION.md',
    'docs/ENGINEERING_FOUNDATION.md',
]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def record(path, relative):
    data = path.read_bytes()
    return {'path': relative, 'bytes': len(data), 'sha256': digest(data)}


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def git(*args):
    return subprocess.check_output(['git', '-c', 'core.safecrlf=false', '-C', str(REPO), *args], text=True).strip()


def check_links(root, paths):
    count = 0
    for path in paths:
        for target in re.findall(r'(?<!!)\[[^\]]+\]\((<[^>]+>|(?:[^()\n]|\([^()\n]*\))+)\)', path.read_text(encoding='utf-8')):
            target = target.strip('<>')
            split = urlsplit(target)
            if split.scheme or split.netloc or not split.path:
                continue
            linked = (path.parent / unquote(split.path)).resolve()
            if not linked.is_relative_to(root) or not linked.exists():
                raise ValueError(f'Missing/escaping package link: {path.relative_to(root)} -> {target}')
            count += 1
    return count


def verify_research(root):
    manifest = json.loads((root / 'sources/manifest.json').read_text(encoding='utf-8'))
    assert len(manifest['sources']) == 14
    assert len(manifest['associated_artifacts']) == 6
    for row in manifest['sources'] + manifest['associated_artifacts']:
        path = root / 'sources' / row['file']
        actual = record(path, row['file'])
        assert actual['bytes'] == row['bytes'] and actual['sha256'] == row['sha256'], row['id']
        if path.suffix.lower() == '.zip':
            with zipfile.ZipFile(path) as archive:
                assert archive.testzip() is None, row['id']
    receipt = json.loads((root / 'references/package-verification.json').read_text(encoding='utf-8'))
    assert receipt['outcome'] == 'pass'
    for name, expected in receipt['artifacts'].items():
        assert record(root / name, name)['sha256'] == expected['sha256']
    return manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--staging', type=Path, required=True, help='Fresh owned directory; must not exist')
    parser.add_argument('--output', type=Path, required=True, help='New ZIP path; must not exist')
    args = parser.parse_args()
    stage = args.staging.resolve()
    output = args.output.resolve()
    assert not stage.exists(), 'Use a fresh staging directory'
    assert not output.exists(), 'Do not overwrite a prior delivery'
    assert stage.is_relative_to(REPO / 'build'), 'Staging must be inside repository build/'
    assert output.suffix.lower() == '.zip'

    frozen = json.loads((HANDOFF / 'FROZEN-FILES.json').read_text(encoding='utf-8'))
    assert frozen['edition'] == EDITION
    for row in frozen['files']:
        assert record(HANDOFF / row['path'], row['path']) == row, row['path']
    verify_research(LIBRARY)
    inputs = []
    for directory in [LIBRARY, HANDOFF]:
        for path in sorted(directory.rglob('*')):
            if path.is_file():
                assert '__pycache__' not in path.parts and not path.is_symlink()
                inputs.append(path)
    inputs += [REPO / relative for relative in CONTEXT]
    before = {str(p): record(p, p.relative_to(REPO).as_posix()) for p in inputs}
    branch = git('branch', '--show-current')
    head = git('rev-parse', 'HEAD')
    tracked_diff = git('diff', '--name-only', 'HEAD')
    untracked = git('ls-files', '--others', '--exclude-standard')
    now = datetime.now(timezone.utc).isoformat()

    package = stage / EDITION
    package.mkdir(parents=True)
    for path in inputs:
        dest = package / path.relative_to(REPO)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, dest)
        assert record(dest, before[str(path)]['path']) == before[str(path)]

    (package / 'START-HERE.md').write_text(
        '# CyrusScatter vegetation core implementation packet v1\n\n'
        'Upload this same archive to all three GPT Web chats.\n\n'
        '- [Start and dispatch](docs/research/vegetation-core-handoff/README.md)\n'
        '- [Full document register](docs/research/vegetation-core-handoff/DOCUMENT-LIST.md)\n'
        '- [Chat A: collision](docs/research/vegetation-core-handoff/PROMPT-A-COLLISION.md)\n'
        '- [Chat B: rooted fitter](docs/research/vegetation-core-handoff/PROMPT-B-FITTER.md)\n'
        '- [Chat C: mesh and independent validation](docs/research/vegetation-core-handoff/PROMPT-C-DELIVERY-VALIDATION.md)\n\n'
        'Paste one role prompt per chat. Return three source ZIPs to the local coordinator. '
        'The starter supplies declarations, not implemented physics. All original research/evidence is preserved. '
        'Selected repository snapshots are read-only context; this is not a full plugin checkout. '
        'No Max test, release delivery or permission to publish is implied.\n', encoding='utf-8')
    (package / 'DOCUMENT-LIST.md').write_text(
        '# Document list\n\nSee the [complete register](docs/research/vegetation-core-handoff/DOCUMENT-LIST.md), '
        '[research index](docs/research/vegetation-interaction/README.md), and '
        '[52-page handbook](docs/research/vegetation-interaction/handbook.pdf).\n', encoding='utf-8')
    write_json(package / 'CONTEXT-SNAPSHOT.json', {
        'schema': 1, 'assembled_at_utc': now, 'branch': branch, 'head': head,
        'scope': 'Selected source bytes from the current dirty working tree, not a clean commit checkout',
        'tracked_changed_path_count': len(tracked_diff.splitlines()) if tracked_diff else 0,
        'untracked_file_count': len(untracked.splitlines()) if untracked else 0,
        'context_files': [before[str(REPO / relative)] for relative in CONTEXT],
        'context_limitation': 'Direct research links only; transitive includes/navigation may require full repository. Do not build these snapshots as a plugin.',
    })
    packed_handoff = package / HANDOFF.relative_to(REPO)
    packed_library = package / LIBRARY.relative_to(REPO)
    links = check_links(package, [package / 'START-HERE.md', package / 'DOCUMENT-LIST.md',
        *packed_handoff.rglob('*.md'),
        *(p for p in packed_library.rglob('*.md') if 'originals' not in p.parts)])
    verify_research(packed_library)
    fixtures = json.loads((packed_handoff / 'fixtures/catalog.json').read_text(encoding='utf-8'))
    assert len(fixtures['cases']) == 11 and len({c['id'] for c in fixtures['cases']}) == 11
    for path in package.rglob('*.json'):
        json.loads(path.read_text(encoding='utf-8'))
    write_json(package / 'PACKAGING-VERIFICATION.json', {
        'schema': 1, 'verified_at_utc': now, 'outcome': 'pass',
        'scope': 'Documentation, archive input integrity, frozen declarations and package structure only',
        'originals_hashed': 14, 'associated_artifacts_hashed': 6,
        'frozen_files_hashed': len(frozen['files']), 'local_markdown_file_links_checked': links,
        'authored_fixture_cases': 11, 'preserved_handbook_pages': 52,
        'cpp_interface_compilation': 'Not executed: no C++ compiler discovered on PATH or configured default VS location during preparation',
        'solver_implementation': 'Not supplied; these are external assignments',
        'solver_tests': 'Not executed', 'max_2027_tests': 'Not executed',
        'historical_library_verification': 'Preserved unchanged; its receipt is not a new solver execution',
    })
    rows = [record(p, p.relative_to(package).as_posix()) for p in sorted(package.rglob('*')) if p.is_file()]
    assert len({r['path'].casefold() for r in rows}) == len(rows)
    forbidden = {'.exe', '.dll', '.obj', '.lib', '.pdb', '.max', '.mzp', '.pyc'}
    assert not any(Path(r['path']).suffix.lower() in forbidden or '.git' in PurePosixPath(r['path']).parts for r in rows)
    write_json(package / 'PACKAGE-MANIFEST.json', {
        'schema': 1, 'edition': EDITION, 'assembled_at_utc': now,
        'hash_algorithm': 'SHA-256', 'self_excluded': 'PACKAGE-MANIFEST.json', 'files': rows,
    })
    for path in inputs:
        assert record(path, before[str(path)]['path']) == before[str(path)], 'Input changed during packaging'
    assert git('rev-parse', 'HEAD') == head and git('branch', '--show-current') == branch

    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(package.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(stage).as_posix())
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert len(names) == len({name.casefold() for name in names})
        expected = {EDITION + '/' + r['path'] for r in rows} | {EDITION + '/PACKAGE-MANIFEST.json'}
        assert set(names) == expected
        for row in rows:
            data = archive.read(EDITION + '/' + row['path'])
            assert len(data) == row['bytes'] and digest(data) == row['sha256'], row['path']
    result = {'outcome': 'pass', 'zip': str(output), **record(output, output.name),
        'archive_files': len(rows) + 1, 'originals': 14, 'associated_artifacts': 6,
        'frozen_files': len(frozen['files']), 'local_markdown_file_links': links,
        'scope': 'Package integrity only; no C++ solver or Max validation'}
    write_json(stage / 'zip-verification.json', result)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
