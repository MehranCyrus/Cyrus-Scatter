"""Mutation witnesses for selected source closure and nested producer admission."""
from pathlib import Path
import importlib.util
import json
import sys
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
import build_inputs


def fixture_tree(root):
    names = ['AminScatter/CMakeLists.txt', 'AminScatter/scripts/AminScatterObject.ms',
        'AminScatter/src/scatter.cpp', 'AminScatter/include/scatter.h', 'AminScatter/tests/test.cpp',
        'AminScatter/third_party/vendor/input.h', 'cmake/CyrusMaxSDK.cmake',
        'tools/build_max.py', 'tools/build_inputs.py', 'tools/procedural_lab/offline_build.py',
        'CyrusLicensing/CMakeLists.txt', 'CyrusLicensing/src/policy.cpp', 'CyrusLicensing/include/license/policy.h',
        'CyrusLicensing/tests/test.cpp', 'CyrusLicensing/team/team_public_key.h',
        'CyrusLicensing/third_party/nlohmann/json.hpp', 'CyrusLicensing/third_party/nlohmann/LICENSE.MIT',
        'AminScatter/ui/LibraryGallery.cs', 'AminScatter/tools/build_gallery.py', 'AminScatter/tools/build_installer.py',
        *['CyrusVegetationLab/experiments/stem-live/'+name for name in ('stem_core.cpp','stem_core.hpp','analysis.cpp','analysis.hpp','connectivity.cpp','connectivity.hpp')],
        'CyrusVegetationLab/core/include/cyrus_vegetation/prototype_v1.hpp','CyrusVegetationLab/core/fitter/fitter.cpp',
        'CyrusVegetationLab/core/fitter/private/math.hpp','CyrusVegetationLab/core/delivery/src/geometry.hpp','CyrusVegetationLab/core/PROVENANCE.json',
        *build_inputs.CORE_SOURCES]
    for name in names:
        path=root/name
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text('Public synthetic input: '+name,encoding='utf-8')
    return root


@pytest.mark.parametrize('name', ['CyrusLicensing/CMakeLists.txt','CyrusLicensing/src/policy.cpp',
    'CyrusLicensing/include/license/policy.h','CyrusLicensing/team/team_public_key.h',
    'AminScatter/shared/LibraryLocation.cs','AminScatter/tools/build_gallery.py',
    'AminScatter/setup/AnalyzerInstallEngine.cs','AminScatter/setup/LibraryOptions.cs',
    'AminScatter/setup/VerifiedBackup.cs','AminScatter/src/scatter.cpp','cmake/CyrusMaxSDK.cmake',
    'CyrusVegetationLab/experiments/stem-live/stem_core.cpp','CyrusVegetationLab/experiments/stem-live/analysis.cpp',
    'CyrusVegetationLab/experiments/stem-live/connectivity.cpp','CyrusVegetationLab/core/include/cyrus_vegetation/prototype_v1.hpp',
    'CyrusVegetationLab/core/fitter/private/math.hpp','CyrusVegetationLab/core/delivery/src/geometry.hpp'])
def test_selected_dependency_mutation_changes_manifest(tmp_path,name):
    root=fixture_tree(tmp_path)
    before=build_inputs.source_manifest(root,'AminScatter')
    assert name in before['files']
    (root/name).write_text('Changed public fixture',encoding='utf-8')
    assert build_inputs.source_manifest(root,'AminScatter')!=before


def test_selection_reads_only_public_trust_and_follows_options(tmp_path):
    root=fixture_tree(tmp_path)
    private=root/'CyrusLicensing/team/issuer-private.key'
    private.write_text('Never enroll this fixture')
    separate=root/'separate-trust/team_public_key.h'
    separate.parent.mkdir()
    separate.write_text('Resolved public authority')
    enabled=build_inputs.source_manifest(root,'AminScatter',{'max_year':2027,'team_license':True,'team_trust_header':str(separate)})
    disabled=build_inputs.source_manifest(root,'AminScatter',{'max_year':None,'team_license':False})
    assert build_inputs.key(separate,root) in enabled['files']
    assert 'CyrusLicensing/team/team_public_key.h' not in enabled['files']
    assert build_inputs.key(private,root) not in enabled['files']
    assert 'CyrusLicensing/src/policy.cpp' not in disabled['files']
    assert enabled!=disabled


def test_added_removed_and_unavailable_inputs_are_not_silent(tmp_path):
    root=fixture_tree(tmp_path)
    before=build_inputs.source_manifest(root,'AminScatter')
    added=root/'CyrusLicensing/include/license/added.h'
    added.write_text('New dependency')
    assert build_inputs.source_manifest(root,'AminScatter')!=before
    added.unlink()
    (root/'AminScatter/src/scatter.cpp').unlink()
    assert build_inputs.source_manifest(root,'AminScatter')!=before
    (root/'AminScatter/shared/LibraryLocation.cs').unlink()
    with pytest.raises(FileNotFoundError,match='Required build input'):
        build_inputs.source_manifest(root,'AminScatter')


@pytest.mark.parametrize('input_name',['source.cs','reference.dll','compiler.exe','generated.cs'])
def test_changed_consumed_input_leaves_managed_receipt_pending(tmp_path,input_name):
    paths=[tmp_path/name for name in ('source.cs','reference.dll','compiler.exe','generated.cs')]
    for path in paths:path.write_text('before')
    output=tmp_path/'CyrusInstaller.dll';output.write_bytes(b'compiled fixture')
    captured=build_inputs.frozen(paths,{'flags':['/deterministic+'],'host':2027},tmp_path)
    build_inputs.managed_pending(output,'installer-core')
    (tmp_path/input_name).write_text('changed during compilation')
    with pytest.raises(ValueError,match='Build inputs changed'):
        build_inputs.managed_complete(output,'installer-core',captured,tmp_path,{})
    assert json.loads(output.with_suffix('.build.json').read_text())['status']=='pending'


@pytest.mark.parametrize('name',['AminScatter/setup/AnalyzerInstallEngine.cs','AminScatter/setup/LibraryOptions.cs',
    'AminScatter/shared/LibraryLocation.cs','AminScatter/setup/VerifiedBackup.cs','AminScatter/tools/build_installer.py'])
def test_mzp_and_exe_core_admission_reject_stale_nested_inputs(tmp_path,monkeypatch,name):
    root=fixture_tree(tmp_path)
    spec=importlib.util.spec_from_file_location('test_core_producer',ROOT/'AminScatter/tools/build_installer.py')
    producer=importlib.util.module_from_spec(spec);spec.loader.exec_module(producer)
    spec=importlib.util.spec_from_file_location('test_core_consumer',ROOT/'tools/build_max.py')
    consumer=importlib.util.module_from_spec(spec);spec.loader.exec_module(consumer)
    monkeypatch.setattr(producer,'ROOT',root);monkeypatch.setattr(consumer,'ROOT',root)
    output=root/'CyrusInstaller.dll';output.write_bytes(b'owned core artifact')
    names=(*build_inputs.CORE_SOURCES,'AminScatter/tools/build_installer.py','tools/build_inputs.py')
    captured=build_inputs.frozen([root/p for p in names],{'producer':'installer-core'},root)
    build_inputs.managed_complete(output,'installer-core',captured,root,{})
    assert producer.verify_core(output)['status']=='complete'
    assert consumer.verify_installer(output)['status']=='complete'
    (root/name).write_text('changed after producer receipt')
    with pytest.raises(ValueError,match='Build inputs changed'):producer.verify_core(output)
    with pytest.raises(ValueError,match='Build inputs changed'):consumer.verify_installer(output)


def test_weak_historical_receipt_is_not_upgraded_in_place(tmp_path):
    output=tmp_path/'old.dll';output.write_bytes(b'old fixture')
    old={'artifact_sha256':build_inputs.digest(output),'source_sha256':'0'*64}
    receipt=output.with_suffix('.build.json');receipt.write_text(json.dumps(old))
    original=receipt.read_bytes()
    with pytest.raises(ValueError,match='version 2'):
        build_inputs.verify_managed(output,'installer-core',tmp_path)
    assert receipt.read_bytes()==original


def test_effective_configuration_is_part_of_identity(tmp_path):
    source=tmp_path/'input.cpp';source.write_text('unchanged')
    before=build_inputs.frozen([source],{'host':2027,'defines':['LICENSE=1'],'flags':['/O2']},tmp_path)
    after=build_inputs.frozen([source],{'host':2027,'defines':['LICENSE=0'],'flags':['/O2']},tmp_path)
    assert before['files']==after['files'] and build_inputs.identity(before)!=build_inputs.identity(after)


def test_first_clean_nmake_dependency_records_preserve_spaces(tmp_path):
    include=tmp_path/'Selected SDK with spaces'/'include.h'
    include.parent.mkdir();include.write_text('public selected header')
    folder=tmp_path/'build';folder.mkdir()
    dependency=folder/'source.cpp.obj.d'
    dependency.write_text(str(include)+'\n',encoding='utf-8')
    manifest={'configuration':{'cache':{'CMAKE_GENERATOR':'NMake Makefiles'}}}
    assert build_inputs.compiler_dependencies(folder,manifest,{})=={include.resolve()}
