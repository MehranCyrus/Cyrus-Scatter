"""Package a tested, source-matched Max 2027 Cyrus Scatter 0.87.4.4 build."""
from argparse import ArgumentParser, Namespace
from pathlib import Path
import hashlib
import importlib.util
import json
import shutil
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
VERSION = '0.87.4.4'
NAMES = ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh']


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


parser = ArgumentParser()
parser.add_argument('--producer', required=True, type=Path)
parser.add_argument('--stage', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
parser.add_argument('--payload', required=True, type=Path)
args = parser.parse_args()
producer, stage, payload = args.producer.resolve(), args.stage.resolve(), args.payload.resolve()
if not all(p.is_relative_to(ROOT / 'build') for p in (producer, stage, payload)):
    raise ValueError('Use dedicated owned build paths for the producer, stage and extracted payload')
receipt = json.loads((producer / 'receipt.json').read_text(encoding='utf-8'))
if receipt.get('status') != 'complete' or not receipt.get('tests_run') or receipt.get('max_year') != 2027:
    raise ValueError('A completed, tested Max 2027 producer receipt is required')
folder = stage / 'AminScatter'
folder.mkdir(parents=True, exist_ok=False)
for name in NAMES + ['CyrusGallery.dll', 'CyrusGallery.build.json']:
    shutil.copy2(producer / name, folder / name)
module('installer08744', ROOT / 'AminScatter/tools/build_installer.py').build(folder / 'CyrusInstaller.dll')
builder = module('package08744', ROOT / 'tools/build_max.py')
settings = Namespace(max_year=2027, tools_version='14.38.33130', windows_sdk='10.0.19041.0',
                     output=args.output.resolve(), team_trust_header=ROOT / 'CyrusLicensing/team/team_public_key.h',
                     content_dir=ROOT / 'dist/CyrusScatter-0.86.7-20261020/Content',
                     native_receipts={'AminScatter': producer / 'receipt.json'})
builder.package('AminScatter', 'Cyrus Scatter', VERSION, NAMES, 'AminScatterObject.ms', settings, stage)
archive = args.output / ('CyrusScatter-' + VERSION + '-Max2027.mzp')
payload.mkdir(parents=True, exist_ok=False)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    manifest = json.loads(z.read('manifest.json'))
    assert manifest['version'] == VERSION and manifest['max_year'] == 2027
    for name, expected in manifest['files'].items():
        assert hashlib.sha256(z.read(name)).hexdigest() == expected, name
    for name in NAMES + ['CyrusScatter.ms', 'CyrusGallery.dll', 'CyrusInstaller.dll']:
        (payload / name).write_bytes(z.read(name))
    assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
    identity = {'archive': str(archive.resolve()), 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
                'producer': str(producer / 'receipt.json'), 'tests_run': True,
                'qualification': receipt['qualification'],
                'files': {p.name: manifest['files'][p.name] for p in payload.iterdir()}}
    (payload / 'package-identity.json').write_text(json.dumps(identity, indent=2), encoding='utf-8')
print(json.dumps(identity, indent=2))
