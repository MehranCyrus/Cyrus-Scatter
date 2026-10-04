"""Assemble the verified local trial folder; no artist installation or upload."""
from pathlib import Path
import hashlib
import json
import shutil
from build import ROOT, BASE


def main():
    release=ROOT/'dist/layers-first-1.2.0'
    docs=ROOT/'docs/Layers_First_2026-10-03'
    evidence=json.loads((docs/'evidence/MANIFEST.json').read_text())
    for year in (2026,2027):
        mzp=release/f'CyrusScatter-1.2.0-Max{year}.mzp'
        assert hashlib.sha256(mzp.read_bytes()).hexdigest()==evidence['packages'][str(year)]['sha256']
    demo=BASE/'hosts/layers-first-release/Cyrus_Scatter_1.2_Layers_Demo.max'
    assert hashlib.sha256(demo.read_bytes()).hexdigest()==evidence['demo_sha256']
    shutil.copy2(demo,release/demo.name)
    shutil.copytree(docs,release/'docs/Layers_First_2026-10-03',dirs_exist_ok=True)
    for name in ('ARTIST_GUIDE.md','CAPABILITIES.md'):
        shutil.copy2(docs/name,release/name)
    (release/'README.md').write_text('''# Cyrus Scatter 1.2 trial

Read [START_HERE.txt](START_HERE.txt) and the [artist guide](ARTIST_GUIDE.md).

- Install only the MZP matching your Max version, then restart Max.
- The supplied Layers demo is a **Max 2027** scene. It is not a Max 2026 demo.
- [Full implementation and test report](docs/Layers_First_2026-10-03/REPORT.md)
- [Completed work and remaining gates](docs/Layers_First_2026-10-03/CHECKLIST.md)
- [Native/MCP capability map](CAPABILITIES.md)
- [Optional offline MCP installation](Cyrus-MCP-1.1.0/README.md)

Max 2027.1 was tested in isolated profiles. Max 2026 passed SDK/native tests; actual Max 2026 host testing remains. Other renderers/DPI configurations require qualification. Brush-constrained Relax and several MCP automation paths remain explicitly unavailable. The ML work is versioned records, not a trained system.

Nothing in this folder has been installed into the artist's active Max profile automatically. Keep an existing scene copy for comparison. SHA256SUMS.txt records this handoff's file identities.
''',encoding='utf-8')
    sums=[]
    for path in sorted(release.rglob('*')):
        if path.is_file() and path.name!='SHA256SUMS.txt':
            sums.append(hashlib.sha256(path.read_bytes()).hexdigest()+'  '+path.relative_to(release).as_posix())
    (release/'SHA256SUMS.txt').write_text('\n'.join(sums)+'\n')
    print(f'Handoff ready: {release} ({len(sums)} verified files)')


if __name__=='__main__':main()
