"""Honor download publication state; stage only an explicitly approved installer."""
from pathlib import Path
import hashlib
import json
import re
import shutil

SITE = Path(__file__).resolve().parents[1]


def release_spec():
    release = json.loads((SITE / 'content/release.json').read_text(encoding='utf-8'))
    assert re.fullmatch(r'0\.\d+\.\d+(?:\.\d+)?', release['version'])
    assert release['runtimeTestedYears'] == [2027]
    if release['installer'] is None:
        return release
    name = release['installer']['filename']
    assert re.fullmatch(r'CyrusScatter-0\.\d+\.\d+(?:\.\d+)?-Setup\.exe', name), name
    assert name == f'CyrusScatter-{release["version"]}-Setup.exe'
    assert release['maxYears'] == [2024,2026,2027] and release['analyzer']['included'] is False
    assert release['runtimeTestedYears'] == [2027]
    assert release['installer']['format'] == 'EXE'
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
    if release['installer'] is None:
        forbidden = {'.exe', '.mzp', '.zip', '.dll', '.dlx', '.dlh', '.dlm', '.max'}
        unexpected = [p.relative_to(SITE / 'dist').as_posix()
                      for p in (SITE / 'dist').rglob('*')
                      if p.is_file() and p.suffix.lower() in forbidden]
        if unexpected:
            raise ValueError('Downloads are unpublished; unexpected payloads: ' + ', '.join(unexpected))
        print('Website-only build: installer downloads are unpublished; no binary or archive staged.')
        return
    folder = f'CyrusScatter-{release["version"]}-{release["isoDate"].replace("-", "")}'
    source = SITE.parent / 'dist' / folder / release['installer']['filename']
    verify(source, release)
    producer=json.loads(source.with_suffix('.build.json').read_text(encoding='utf-8'))
    assert producer['status']=='complete' and producer['producer']=='installer-exe'
    assert producer['version']==release['version'] and producer['max_years']==release['maxYears']
    assert producer['artifact_sha256']==release['installer']['sha256']
    with source.open('rb') as stream:assert stream.read(2)==b'MZ','Expected a Windows EXE'
    target = SITE / 'dist' / release['installer']['path']
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink():
        raise ValueError('Refusing a linked download destination')
    temporary = target.with_suffix('.tmp')
    shutil.copyfile(source, temporary)
    verify(temporary, release)
    temporary.replace(target)
    assert [p.name for p in target.parent.iterdir()] == [target.name], 'Only the approved installer belongs in downloads'
    print(f'Staged verified EXE: {target.name} ({target.stat().st_size:,} bytes)')


if __name__ == '__main__':
    main()
