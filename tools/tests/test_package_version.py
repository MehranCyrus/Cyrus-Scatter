"""Keep displayed development labels and native/package metadata consistent."""
import importlib.util
import json
from pathlib import Path

import pytest

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('cyrus_version_test',ROOT/'tools/build_max.py')
builder=importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


def test_placement_qualification_binary_is_never_allowed_by_default():
    marker='Cyrus Scatter NEVER SHIP native placement ownership qualification'.encode('utf-16le')
    with pytest.raises(RuntimeError):builder.reject_development_binary('AminScatter.dlx',marker)
    builder.reject_development_binary('AminScatter.dlx',marker,allow_owned_placement=True)
    with pytest.raises(RuntimeError):builder.reject_development_binary('AminScatter.dlx',b'normal product',allow_owned_placement=True)
    with pytest.raises(RuntimeError):builder.reject_development_binary('AminScatter.dlx',marker+b'CYRUS_LICENSE_EXPERIMENT_NEVER_SHIP',allow_owned_placement=True)


@pytest.mark.parametrize('label,metadata',[('0.72','0.72.0'),('0.7.1','0.7.1'),('0.82.6.1','0.82.6.1'),('0.83.0','0.83.0')])
def test_short_and_full_development_labels_have_exact_package_versions(tmp_path,monkeypatch,label,metadata):
    script=tmp_path/'AminScatter/scripts/AminScatterObject.ms'
    script.parent.mkdir(parents=True)
    script.write_text('fn uiVersion = "'+label+'"\n')
    (tmp_path/'AminScatter/CMakeLists.txt').write_text('project(CyrusScatter VERSION '+metadata+' LANGUAGES CXX)\n')
    monkeypatch.setattr(builder,'ROOT',tmp_path)
    assert builder.scatter_version()==metadata


def test_mismatched_native_metadata_cannot_be_packaged(tmp_path,monkeypatch):
    script=tmp_path/'AminScatter/scripts/AminScatterObject.ms'
    script.parent.mkdir(parents=True)
    script.write_text('fn uiVersion = "0.72"\n')
    (tmp_path/'AminScatter/CMakeLists.txt').write_text('project(CyrusScatter VERSION 0.7.1 LANGUAGES CXX)\n')
    monkeypatch.setattr(builder,'ROOT',tmp_path)
    with pytest.raises(ValueError,match='metadata differs'):
        builder.scatter_version()


@pytest.mark.parametrize('encoding',['ascii','utf-16le'])
def test_preview_fault_build_cannot_enter_a_package(encoding):
    with pytest.raises(RuntimeError,match='Refusing development'):
        builder.reject_development_binary('AminScatter.dlx',b'prefix'+'cyrusOwnedPreviewFault'.encode(encoding))


def test_owned_preview_exception_does_not_allow_licensing_lab_authority():
    builder.reject_development_binary('AminScatter.dlx',b'cyrusOwnedPreviewFault',allow_owned_preview=True)
    with pytest.raises(RuntimeError):
        builder.reject_development_binary('AminScatter.dlx',b'cyrusOwnedPreviewFault cyrusOwnedLabClock',allow_owned_preview=True)


def test_library_package_requires_exact_content_and_confined_paths(tmp_path):
    (tmp_path/'sample.max').write_bytes(b'qualified demonstration fixture')
    inventory={'version':'0.82.6.1','max_year':2027,'files':{'sample.max':builder.sha((tmp_path/'sample.max').read_bytes())}}
    (tmp_path/'inventory.json').write_text(json.dumps(inventory))
    payload=builder.library_payload(tmp_path,'0.82.6.1')
    assert payload['Library/sample.max']==(tmp_path/'sample.max').read_bytes()
    assert b'@"sample.max"' in payload['LibraryFiles.ms']
    (tmp_path/'sample.max').write_bytes(b'replaced')
    with pytest.raises(ValueError,match='hash mismatch'):builder.library_payload(tmp_path,'0.82.6.1')
    inventory['files']={'../outside.max':'a'*64};(tmp_path/'inventory.json').write_text(json.dumps(inventory))
    with pytest.raises(ValueError,match='Unsafe'):builder.library_payload(tmp_path,'0.82.6.1')
    with pytest.raises(ValueError,match='version/host'):builder.library_payload(tmp_path,'0.83.0')


def test_ready_mesh_payload_requires_content_addressed_preset_path(tmp_path):
    name='Presets/'+'a'*64+'/assets/'+'b'*64+'.cmesh'
    path=tmp_path/name;path.parent.mkdir(parents=True);path.write_bytes(b'bounded fixture')
    inventory={'version':'0.85.3','max_year':2027,'files':{name:builder.sha(path.read_bytes())}}
    (tmp_path/'inventory.json').write_text(json.dumps(inventory))
    assert builder.library_payload(tmp_path,'0.85.3')['Library/'+name]==path.read_bytes()
    for rejected in ('loose.cmesh','Presets/short/assets/'+('b'*64)+'.cmesh',name.replace('.cmesh','.dll')):
        inventory['files']={rejected:builder.sha(path.read_bytes())}
        (tmp_path/'inventory.json').write_text(json.dumps(inventory))
        with pytest.raises(ValueError,match='Unsupported bundled'):builder.library_payload(tmp_path,'0.85.3')
