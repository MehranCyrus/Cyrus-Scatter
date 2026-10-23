"""Stage the exact approved EXE as a static download; never bundle model content."""
from pathlib import Path
import hashlib
import json
import re
import shutil

SITE = Path(__file__).resolve().parents[1]


def release_spec():
    release = json.loads((SITE / 'content/release.json').read_text(encoding='utf-8'))
    name = release['installer']['filename']
    assert re.fullmatch(r'CyrusScatter-0\.\d+\.\d+(?:\.\d+)?-Setup\.exe', name), name
    assert name == f'CyrusScatter-{release["version"]}-Setup.exe'
    assert release['installer']['path'] == 'downloads/' + name
    assert re.fullmatch(r'\d{4}-\d{2}-\d{2}', release['isoDate'])
    return release


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify(path, release):
    assert path.is_file() and not path.is_symlink(), f'Missing regular installer: {path}'
    assert path.stat().st_size == release['installer']['bytes'], 'Installer size differs'
    assert digest(path) == release['installer']['sha256'], 'Installer hash differs'


def main():
    release = release_spec()
    folder = f'CyrusScatter-{release["version"]}-{release["isoDate"].replace("-", "")}'
    source = SITE.parent / 'dist' / folder / release['installer']['filename']
    verify(source, release)
    target = SITE / 'dist' / release['installer']['path']
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink():
        raise ValueError('Refusing a linked download destination')
    temporary = target.with_suffix('.tmp')
    shutil.copyfile(source, temporary)
    verify(temporary, release)
    temporary.replace(target)
    assert [p.name for p in target.parent.iterdir()] == [target.name], 'Only the main EXE belongs in downloads'
    print(f'Staged verified EXE: {target.name} ({target.stat().st_size:,} bytes)')


if __name__ == '__main__':
    main()
