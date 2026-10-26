"""Reject the stale managed identity that blocked the library in 0.86.8.5."""
from pathlib import Path
import importlib.util
import json
import pytest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('gallery_build_max', ROOT/'tools/build_max.py')
build_max = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_max)

@pytest.mark.parametrize('mismatch', ['version', 'host', 'artifact', 'source', 'shared_source', None])
def test_packaging_requires_verified_matching_gallery(tmp_path, mismatch):
    gallery = tmp_path/'CyrusGallery.dll'
    gallery.write_bytes(b'owned receipt admission fixture')
    version = build_max.scatter_version()
    assembly_version='.'.join(version.split('.')+['0']*(4-len(version.split('.'))))
    receipt = {
        'assembly_version': assembly_version, 'max_year': 2027,
        'artifact_sha256': build_max.sha(gallery.read_bytes()),
        'source_sha256': build_max.sha((ROOT/'AminScatter/ui/LibraryGallery.cs').read_bytes()),
        'shared_source_sha256': build_max.sha((ROOT/'AminScatter/shared/LibraryLocation.cs').read_bytes()),
    }
    inputs=build_max.build_inputs.frozen([ROOT/p for p in (
        'AminScatter/ui/LibraryGallery.cs',*(str(p.relative_to(ROOT)).replace('\\','/') for p in sorted((ROOT/'AminScatter/shared').glob('*.cs'))),
        'AminScatter/CMakeLists.txt','AminScatter/tools/build_gallery.py','tools/build_inputs.py')],
        {'producer':'gallery','max_year':2027,'assembly_version':assembly_version},ROOT)
    receipt.update(schema=build_max.build_inputs.MANAGED_SCHEMA,status='complete',producer='gallery',
        input_manifest=inputs,input_manifest_sha256=build_max.build_inputs.identity(inputs))
    if mismatch == 'version': receipt['assembly_version'] = '0.86.8.3'
    if mismatch == 'host': receipt['max_year'] = 2024
    if mismatch in ('artifact', 'source', 'shared_source'): receipt[mismatch+'_sha256'] = '0'*64
    gallery.with_suffix('.build.json').write_text(json.dumps(receipt), encoding='utf-8')
    if mismatch:
        with pytest.raises(ValueError, match='Gallery release/host/source/artifact'):
            build_max.verify_gallery(gallery, version, 2027)
    else:
        build_max.verify_gallery(gallery, version, 2027)
