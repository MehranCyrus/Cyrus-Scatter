import importlib.util
from pathlib import Path
import pytest

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('team_build',ROOT/'tools/build_max.py')
build=importlib.util.module_from_spec(spec);spec.loader.exec_module(build)

def test_package_requires_selected_authority_and_native_import(tmp_path):
    kid='cyrus-team-'+'a'*32
    header=tmp_path/'team_public_key.h'
    header.write_text('inline constexpr char CyrusTeamKeyID[]="'+kid+'";')
    valid=kid.encode()+b'cyrusLicenseImport'
    assert build.require_team_authority(valid,header)==kid
    for data in [b'unlicensed',kid.encode(),b'cyrusLicenseImport',b'cyrus-team-'+b'b'*32+b'cyrusLicenseImport']:
        with pytest.raises(RuntimeError):build.require_team_authority(data,header)

def test_package_still_rejects_laboratory_authority():
    for encoding in ['ascii','utf-16le']:
        with pytest.raises(RuntimeError):build.reject_development_binary('AminScatter.dlx','cyrusOwnedLabClock'.encode(encoding))
