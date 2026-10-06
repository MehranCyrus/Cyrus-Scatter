"""Keep displayed development labels and native/package metadata consistent."""
import importlib.util
from pathlib import Path

import pytest

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('cyrus_version_test',ROOT/'tools/build_max.py')
builder=importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


@pytest.mark.parametrize('label,metadata',[('0.72','0.72.0'),('0.7.1','0.7.1')])
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
