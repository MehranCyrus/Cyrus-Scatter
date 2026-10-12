"""Package the verified Vite output for a conventional static cPanel host."""
from pathlib import Path
from datetime import date
import hashlib
import json
import re
import zipfile

SITE = Path(__file__).resolve().parents[1]


def main():
    built = SITE / 'dist'
    reference = json.loads((SITE/'src/content/reference.json').read_text(encoding='utf-8'))
    html = (built/'index.html').read_text(encoding='utf-8')
    script = re.search(r'src="\./assets/(index-[^"]+\.js)"', html)
    if not script:
        raise SystemExit('Build the website before packaging: no production entry script found.')
    tag = script[1].removesuffix('.js').removeprefix('index-')
    release = SITE.parent/'dist/website'/f'cpanel-{date.today().isoformat()}-{tag}'
    release.mkdir(parents=True, exist_ok=True)
    archive = release/f'CyrusScatter-website-{reference["developmentVersion"]}.zip'
    files = []
    for path in sorted(built.rglob('*')):
        if not path.is_file():
            continue
        relative = path.relative_to(built).as_posix()
        if path.suffix.lower()=='.md' or relative.startswith('sources/'):
            raise SystemExit(f'Private authoring/source file in public build: {relative}')
        if path.is_symlink() or any(part.startswith('.') for part in path.relative_to(built).parts):
            raise SystemExit(f'Unexpected hidden file/symlink in public build: {relative}')
        files.append((relative, path.read_bytes()))
    assert {'index.html','favicon.ico'}.issubset({name for name,_ in files})
    assert 'references' not in reference
    assert all('snapshot' not in d and 'path' not in d for d in reference['documents'])
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zipped:
        for name, data in files:
            info = zipfile.ZipInfo(name)
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            zipped.writestr(info, data, compresslevel=9)
    with zipfile.ZipFile(archive) as zipped:
        assert zipped.testzip() is None
        assert zipped.namelist() == [name for name,_ in files]
        assert all(zipped.read(name) == data for name,data in files)
    receipt = {
        'kind':'static-cpanel-upload', 'developmentVersion':reference['developmentVersion'],
        'entryScript':script[1], 'archive':archive.name, 'bytes':archive.stat().st_size,
        'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),
        'fileCount':len(files), 'files':[
            {'path':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()} for name,data in files
        ],
    }
    (release/'manifest.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    (release/'UPLOAD-INSTRUCTIONS.md').write_bytes((SITE/'CPANEL_UPLOAD.md').read_bytes())
    print(json.dumps({'archive':str(archive),'files':len(files),'MiB':round(receipt['bytes']/1024**2,2),'sha256':receipt['sha256']},indent=2))


if __name__ == '__main__':
    main()
