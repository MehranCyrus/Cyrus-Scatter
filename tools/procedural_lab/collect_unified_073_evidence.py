"""Allowlisted receipts and source/artifact audit; no private logs/credentials.

Run after final qualification and packaging. This does not install, launch Max,
change product sources, commit or touch artist scenes.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT=Path(__file__).resolve().parents[2]
BUILD=ROOT/'build/unified-073-20261006'
OUT=ROOT/'docs/Unified_System_0.73_2026-10-06/evidence'
DIST=ROOT/'dist/unified-0.73-selection-fix-20261006'
CAMPAIGNS={
    'core':'unified073-selectionfix-core01','ui':'unified073-selectionfix-ui01',
    'playback':'unified073-selectionfix-playback01','navigation':'unified073-selectionfix-100k01',
    'mcp-direct':'unified073-selectionfix-mcp-direct01','mcp-panel':'unified073-selectionfix-mcp-panel01',
    'analyzer-assignment':'unified073-selectionfix-analyzer01','retirement':'unified073-selectionfix-retirement01',
    'selection':'unified073-selectionfix-selection06'}


def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def save(name,value):(OUT/name).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,stderr=subprocess.PIPE).decode('utf-8')


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    copied=[]
    def copy(path,name):
        dest=OUT/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
        copied.append(dict(path=name,source=path.relative_to(ROOT).as_posix(),sha256=digest(dest),bytes=dest.stat().st_size))
    for year in (2026,2027):
        for tool in ('native','analyzer'):
            directory=BUILD/f'{tool}-max{year}'
            receipt=load(directory/'receipt.json')
            assert all(row['exit_code']==0 for row in receipt['stages'])
            for path,expected in {**receipt['sources'],**receipt['binaries']}.items():assert digest(ROOT/path)==expected,path
            for name in ('receipt.json','tests.log'):copy(directory/name,f'{tool}-max{year}/{name}')
    copy(BUILD/'python-tests.xml','python-tests.xml')
    copy(BUILD/'generated-check.json','generated-check.json')
    reports={
        'core':('core073.json','containers073.json','ports073.json','groups073.json','persistence073.json',
                'group-move-diagnostics.json','group-retained-comparison.json'),
        'ui':('ui073-acceptance.json','corona-stop-073.json','idle-qualification.json','diagnostic-overhead.json'),
        'playback':('result.txt',),
        'navigation':('unified073-final-100k-navigation.json',),
        'mcp-direct':('mcp073.json',),
        'mcp-panel':('panel-runtime-result.json','panel-save-reopen.json'),
        'analyzer-assignment':('analyzer-assignment073.json','baseline-parity073.json'),
        'retirement':('retirement073.json',),
        'selection':('container-selection073.json','selection-reopen-warmup.json','selection-counter-comparison.json',)}
    script=digest(ROOT/'AminScatter/scripts/AminScatterObject.ms')
    for label,name in CAMPAIGNS.items():
        directory=ROOT/'build/mcp-qualification'/name
        receipt=load(directory/'qualification.json')
        assert receipt['passed'] and receipt['owned_process_stopped'] and receipt['installed_product_files_unchanged']
        assert receipt['launch']['script_sha256']==script
        for path,expected in receipt['fixtures'].items():assert digest(ROOT/path)==expected,path
        if 'external_fixture' in receipt:
            client=receipt['external_fixture'];assert digest(Path(client['path']))==client['sha256']
        if label.startswith('mcp-'):
            assert receipt['host_python_sources_unchanged']
            for path,expected in receipt['host_python_sources'].items():assert digest(ROOT/path)==expected,path
        copy(directory/'qualification.json',label+'/qualification.json')
        for filename in reports[label]:copy(directory/filename,label+'/'+filename)
    original=load(BUILD/'baseline/runtime.json');current=load(ROOT/'build/mcp-qualification'/CAMPAIGNS['analyzer-assignment']/'baseline-parity073.json')
    assert all(original[key]==current[key] for key in ('base','paint'))
    save('baseline-comparison.json',dict(baseline=original,current=current,position_source_fingerprints_identical=True,
        fingerprint_scope='position and source index, not full matrices/materials'))
    packages=load(DIST/'BUILD.json')
    for record in packages.values():
        for name,item in record['packages'].items():assert digest(DIST/f'Max{record["max_year"]}'/name)==item['sha256']
    mcp=load(DIST/'CyrusMCP-0.73.0/package-manifest.json')
    for item in mcp['files']:assert digest(DIST/'CyrusMCP-0.73.0'/item['path'])==item['sha256']
    for source in (ROOT/'CyrusMCP/cyrus_mcp').rglob('*'):
        if source.is_file() and source.suffix in ('.py','.json'):
            assert digest(source)==digest(DIST/'CyrusMCP-0.73.0/host/cyrus_mcp'/source.relative_to(ROOT/'CyrusMCP/cyrus_mcp'))
    wheel=next((DIST/'CyrusMCP-0.73.0/wheels').glob('cyrus_scatter_mcp-0.73.0-*.whl'))
    with zipfile.ZipFile(wheel) as archive:
        for source in (ROOT/'CyrusMCP/cyrus_mcp').rglob('*'):
            if source.is_file() and source.suffix in ('.py','.json'):
                assert hashlib.sha256(archive.read('cyrus_mcp/'+source.relative_to(ROOT/'CyrusMCP/cyrus_mcp').as_posix())).hexdigest()==digest(source)
    save('packages.json',dict(native=packages,mcp=mcp,mcp_source_equivalent=True))
    before=load(BUILD/'baseline/source-hashes.json')
    paths=sorted(set(git('ls-files','-c','-o','--exclude-standard','-z').split('\0'))-{''})
    now={name:digest(ROOT/name) for name in paths if (ROOT/name).is_file() and not name.startswith('docs/')}
    protected=('CyrusLicensing/','tools/licensing_lab/','docs/licensing/')
    comparable={name:key for name,key in now.items() if not name.lower().endswith('.md') and not name.startswith(protected)}
    assert not git('diff','--name-only','HEAD','--',*protected).strip(),'Protected licensing changed'
    preservation={name:digest(ROOT/name) for name in paths if (ROOT/name).is_file() and name.startswith(protected)}
    save('current-snapshot.json',dict(development_version='0.73',package_version='0.73.0',serialization=54,
        calculation_model='CyrusUnified1',branch=git('branch','--show-current').strip(),head=git('rev-parse','HEAD').strip(),
        uncommitted=True,baseline_inventory_count=len(before),source_hashes=now,
        baseline_scope='Non-Markdown source/configuration, excluding docs and protected licensing. Additional inventory entries are not claimed as newly created.',
        comparable_current_count=len(comparable),
        compared_to_initial=dict(changed=[name for name,key in before.items() if name in comparable and comparable[name]!=key],
            retired=[name for name in before if name not in comparable],added=[name for name in comparable if name not in before]),
        worktree_status=git('status','--porcelain=v1').splitlines(),protected_licensing_hashes=preservation,
        licensing_tracked_diff_empty=True,artist_install=False,computer_use=False,commit=False,push=False))
    attempts=[
        ('unified073-final-core04','idle fixture: raw embedded writes did not request redraw; all five core probes passed; final core05 and actual-handler ui01 pass'),
        ('unified073-final-mcp-panel01','fixture read cold embedded records before root publication binding'),
        ('unified073-final-mcp-panel02','diagnostic reproduction: 49 accepted versus 50 raw; scope/diagnostic reset passed'),
        ('unified073-final-analyzer-assignment01','fixture resolution32 below native minimum48'),
        ('unified073-final-analyzer-assignment02','fixture outside-border channel has no receiver outside coincident boundary'),
        ('unified073-final-analyzer-assignment03','same outside-border diagnostic reproduction; corrected assignment04 passes'),
        ('unified073-guard-ui01','Max exited before bootstrap with 4294967295 during concurrent private startup; script/UI acceptance did not run. Cause unproven; retry serially on unchanged bits.'),
        ('unified073-selectionfix-selection01','Regression fixture opened the Source rollout by property assignment without invoking its rolledUp handler, leaving fields unbound; corrected fixture invokes the actual expansion handler. No product change between these attempts.'),
        ('unified073-selectionfix-selection02','Negative fixture cleared general rollout owners, then called a normal ready-panel bind without restoring them; the invalid fixture transition caused updateMode/undefined. Restore the simulated owners before normal binding.'),
        ('unified073-selectionfix-selection03','Fixture tried to call dropdown.selected, which is the selected item string; use the production selectConsumer function called by the native selection event. No positive mount timer invocation or product change.'),
        ('unified073-selectionfix-selection04','Scene reset/load changed the command-panel task; fixture now enters Modify before testing selection. Explicit mounting still not used.'),
        ('unified073-selectionfix-selection05','Fixture froze retained-buffer counters before the first cold-scene preview draw. Isolated diagnostic showed unchanged epoch/candidate/membership counts; preview owners appeared and initial uploads occurred, then subsequent selection reused them. Warm the cold scene with no selection before the passive-UI baseline.')]
    audit=[]
    for name,diagnosis in attempts:
        receipt_path=ROOT/'build/mcp-qualification'/name/'qualification.json'
        receipt=load(receipt_path)
        assert not receipt['passed'] and receipt['owned_process_stopped']
        audit.append(dict(campaign=name,receipt_sha256=digest(receipt_path),passed=False,
            diagnosis=diagnosis,installed_product_files_unchanged=receipt['installed_product_files_unchanged']))
    denial_path=ROOT/'build/mcp-qualification/unified073-final-retirement02/qualification.json'
    denial=load(denial_path)
    assert denial['passed'] and denial['owned_process_stopped']
    assert load(denial_path.parent/'retirement073.json')['controllers'][0][1][1]==54
    reproduction=ROOT/'build/mcp-qualification/unified073-selection-reproduce01'
    reproduced=load(reproduction/'selection-reproduction.json')
    assert len(reproduced['caught_router_errors'])==21 and reproduced['explicit_mount_calls']==0
    save('attempt-audit.json',dict(failed_intermediate_receipts=audit,
        diagnostic_reproductions=[dict(campaign=denial_path.parent.name,receipt_sha256=digest(denial_path),
            diagnostic_execution_passed=True,acceptance=False,
            diagnosis='Max continued opening an older scene after an on-update exception and relabelled the record as 54. A persistent schema-validity marker now denies calculation, publication, copying and re-save/reopen bypass.'),
            dict(campaign=reproduction.name,receipt_sha256=digest(reproduction/'qualification.json'),
                 diagnostic_execution_passed=True,acceptance=False,
                 diagnosis='Previous delivered script: 21 original mainUI/undefined router errors witnessed, including one explicit cold-handler probe; natural selection did not manually run the mount timer. Earlier UI tests forced timer mounting and missed asynchronous rollout exceptions.')],
        actual_production_fixes=['helper cloned rollout explicit view reference; final shared/inactive/global context tests pass',
            'persistent development-schema denial; final retirement guard test passes',
            'container child rollups capture their panel and guard readiness/reentrancy; natural selection and closed handler regression passes']))
    save('index.json',dict(campaigns=CAMPAIGNS,copied=copied,
        private_material_excluded='Connection descriptors, authentication secrets, journals, scenes, binaries, full private logs and vendor analysis',
        purpose='Matching evidence, not every possible feature combination or production readiness'))
    print(f'PASS evidence: {len(copied)} allowlisted files; {len(before)} baseline/{len(now)} current non-doc-directory source entries; wheel/host package matches source')


if __name__=='__main__':main()
