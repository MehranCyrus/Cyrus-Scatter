from pathlib import Path
from types import SimpleNamespace
import hashlib
import json
import subprocess
import sys
import zipfile

root = Path(__file__).resolve().parents[2]
work = Path(__file__).resolve().parent
sha = lambda data: hashlib.sha256(data).hexdigest()
script = root / 'AminScatter/scripts/AminScatterObject.ms'
tested_script = sha(script.read_bytes())
subprocess.run(['node', 'tools/ui/generate.cjs'], cwd=root / 'AminScatter', check=True)
assert sha(script.read_bytes()) == tested_script, 'Generator changed the tested script'
sys.path.insert(0, str(root / 'tools'))
import build_max
args = SimpleNamespace(max_year=2027, tools_version='14.38.33130',
                       windows_sdk='10.0.19041.0', output=root / 'dist')
build_max.package('AminScatter', 'Cyrus Scatter', '0.62',
                  ['AminScatter.dlx', 'CyrusScatterEdit.dlm'],
                  'AminScatterObject.ms', args, root / 'build/max2027-release')
package = root / 'dist/CyrusScatter-0.62-Max2027.mzp'
with zipfile.ZipFile(package) as z, zipfile.ZipFile(root / 'dist/CyrusScatter-0.61-Max2027.mzp') as old:
    assert z.testzip() is None
    manifest = json.loads(z.read('manifest.json'))
    for name, expected in manifest['files'].items():
        assert sha(z.read(name)) == expected, name
    assert z.read('AminScatterObject.ms') == script.read_bytes()
    for name in ('AminScatter.dlx', 'CyrusScatterEdit.dlm'):
        assert z.read(name) == old.read(name), name
    assert not any('Probe' in name for name in z.namelist())
    result = {'package': str(package.relative_to(root)), 'sha256': sha(package.read_bytes()),
              'zip_integrity': 'PASS', 'all_manifest_hashes': 'PASS',
              'generator_idempotence': 'PASS', 'script_matches_tested_source': 'PASS',
              'native_payload_matches_061': 'PASS', 'experimental_probe_excluded': 'PASS',
              'manifest': manifest}
(work / 'package-verification.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: v for k, v in result.items() if k != 'manifest'}, indent=2))
