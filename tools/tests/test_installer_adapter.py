"""Package-output witnesses for the Scatter hosted installer identity guard.

Native/managed compilation admission has separate producer tests. These tests
use synthetic admitted binaries to exercise the real package/template path.
The owned Max fixture separately proves stale-loaded assembly rejection.
"""
from pathlib import Path
from types import SimpleNamespace
import hashlib
import importlib.util
import json
import shutil
import zipfile

import pytest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('adapter_build_max', ROOT/'tools/build_max.py')
build_max = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_max)


def package_fixture(tmp_path, monkeypatch, helper, mvid, missing_token=None):
    root = tmp_path/'source'
    stage = tmp_path/'stage'
    project = root/'AminScatter'
    shutil.copytree(ROOT/'AminScatter/installer', project/'installer')
    template = project/'installer/install.ms'
    if missing_token:
        template.write_text(template.read_text().replace(missing_token, 'omitted guard'), encoding='utf-8')
    for name in ('tools/build_max.py', 'tools/build_inputs.py', 'AminScatter/CMakeLists.txt',
                 'AminScatter/scripts/AminScatterObject.ms'):
        path = root/name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('Owned packaging-only fixture', encoding='utf-8')
    for name in ('AminScatter/third_party/clipper2/LICENSE',
                 'AminScatter/third_party/clipper2/CYRUS-CHANGES.md',
                 'AminScatter/third_party/geodesic/LICENSE',
                 'AminScatter/third_party/geodesic/CYRUS_CHANGES.md',
                 'CyrusLicensing/third_party/nlohmann/LICENSE.MIT',
                 'AminScatter/third_party/libjpeg-turbo-3.2.0/LICENSE.md',
                 'AminScatter/third_party/libjpeg-turbo-3.2.0/README.ijg',
                 'AminScatter/third_party/libjpeg-turbo-3.2.0/CYRUS-NOTICE.txt'):
        path = root/name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('Owned notice fixture', encoding='utf-8')
    output = stage/'AminScatter'
    output.mkdir(parents=True)
    for name, data in {'AminScatter.dlx': b'admitted native fixture',
                       'CyrusInstaller.dll': helper, 'CyrusGallery.dll': b'admitted gallery fixture',
                       'receipt.json': b'{}', 'CyrusInstaller.build.json': b'{}',
                       'CyrusGallery.build.json': b'{}'}.items():
        (output/name).write_bytes(data)
    receipt = {'schema': 'cyrus.managed-build/2', 'producer': 'installer-core',
               'input_manifest_sha256': '1'*64, 'module_version_id': mvid}
    gallery = {**receipt, 'producer': 'gallery'}
    native = {'schema': 'cyrus.native-build/2', 'input_manifest_sha256': '2'*64,
              'producer_receipts': {'gallery': build_max.build_inputs.producer_link(output/'CyrusGallery.dll', gallery)}}
    monkeypatch.setattr(build_max, 'ROOT', root)
    monkeypatch.setattr(build_max, 'scatter_version', lambda: '0.86.8.7')
    monkeypatch.setattr(build_max, 'verify_native_receipt', lambda *args: native)
    monkeypatch.setattr(build_max, 'verify_installer', lambda *args: receipt)
    monkeypatch.setattr(build_max, 'verify_gallery', lambda *args: gallery)
    monkeypatch.setattr(build_max, 'require_team_authority', lambda *args: None)
    monkeypatch.setattr(build_max, 'library_payload', lambda *args: {})
    monkeypatch.setattr(build_max, 'pattern_payload', lambda *args: {})
    args = SimpleNamespace(max_year=2027, tools_version='14.38.33130', windows_sdk='10.0.19041.0',
                           team_trust_header=root/'public.h', output=tmp_path/'packages')
    build_max.package('AminScatter', 'Cyrus Scatter', '0.86.8.7', ['AminScatter.dlx'],
                      'AminScatterObject.ms', args, stage)
    return args.output/'CyrusScatter-0.86.8.7-Max2027.mzp'


@pytest.mark.parametrize('helper,mvid', [
    (b'first admitted helper', '11111111-2222-3333-4444-555555555555'),
    (b'different admitted helper', 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
])
def test_scatter_archive_binds_admitted_helper_before_host_paths(tmp_path, monkeypatch, helper, mvid):
    package = package_fixture(tmp_path, monkeypatch, helper, mvid)
    with zipfile.ZipFile(package) as archive:
        adapter = archive.read('install.ms').decode('utf-8')
        expected = hashlib.sha256(helper).hexdigest()
        assert archive.read('CyrusInstaller.dll') == helper
        assert expected in adapter and mvid in adapter
        assert '__HELPER_' not in adapter and '__INSTALL_HASH__' not in adapter
        assert '(maxVersion())[1]!=29000' in adapter
        assert adapter.index('CurrentDomain.GetAssemblies()') < adapter.index('helperReady=true') < adapter.index('.ForMax ')
        assert 'Save your work, restart Max' in adapter
        assert 'if helperReady and paths!=undefined do' in adapter
        assert hashlib.sha256(archive.read('InstallInventory.txt')).hexdigest() in adapter
        manifest = json.loads(archive.read('manifest.json'))
        assert manifest['files']['CyrusInstaller.dll'] == expected
        assert manifest['files']['install.ms'] == hashlib.sha256(archive.read('install.ms')).hexdigest()


@pytest.mark.parametrize('missing_token', ['__HELPER_SHA256__', '__HELPER_MVID__'])
def test_scatter_package_refuses_missing_helper_identity_guard(tmp_path, monkeypatch, missing_token):
    with pytest.raises(RuntimeError, match='Missing Scatter installer helper identity guard'):
        package_fixture(tmp_path, monkeypatch, b'admitted helper', '11111111-2222-3333-4444-555555555555', missing_token)
