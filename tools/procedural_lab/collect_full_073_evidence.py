"""Collect allowlisted qualification receipts and source/artifact identities.

Excludes IPC descriptors, authentication, journals, scenes, binaries and full
private logs. Does not launch Max, install, commit, upload or alter artist files.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'docs/Full_Qualification_0.73_2026-10-07/evidence'

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def load(path):return json.loads(Path(path).read_text(encoding='utf-8-sig'))
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT).decode('utf-8')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--manifest',type=Path,required=True);parser.add_argument('--packages',type=Path,required=True)
    args=parser.parse_args();config=load(args.manifest);build=load(args.packages/'BUILD.json')
    DEST.mkdir(parents=True,exist_ok=True);copied=[]
    def copy(source,name):
        source=(ROOT/Path(source)).resolve();target=DEST/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
        copied.append(dict(file=name,source=source.relative_to(ROOT).as_posix(),sha256=sha(target),bytes=target.stat().st_size))
    for year in (2026,2027):
        for project in ('scatter','analyzer'):
            folder=ROOT/config['native'][str(year)][project]
            for name in ('receipt.json','tests.log'):copy(folder/name,f'{project}-max{year}/{name}')
    reports={'core':['approved-layout073.json','core073.json','ports073.json','containers073.json','groups073.json','node-move073.json','persistence073.json','analyzer-assignment073.json'],
             'idle':['idle-qualification.json','diagnostic-overhead.json'],
             'selection':['container-selection073.json'], 'playback':['result.txt'],
             'corona_mock':['corona-stop-073.json'], 'retirement':['retirement073.json'],
             'mcp_direct':['mcp073.json'], 'mcp_panel':['panel-runtime-result.json']}
    for name,path in config['campaigns'].items():
        folder=ROOT/path;receipt=load(folder/'qualification.json')
        assert receipt['passed'] and receipt['owned_process_stopped'] and receipt['installed_product_files_unchanged']
        copy(folder/'qualification.json',f'{name}/qualification.json')
        for report in reports[name]:copy(folder/report,f'{name}/{report}')
    real=ROOT/config['real_host'];protection=load(real/'protection.json')
    assert all(protection[k] for k in ('owned_process_stopped','original_scene_unchanged','installed_product_files_unchanged'))
    for name in ('launch.json','protection.json','pointer-container-selection.json','pointer-container-movement.json',
                 'pointer-ui-qualification.json','pointer-brush-before.json','pointer-brush-after.json','pointer-brush-undo.json','original-material-map-audit.json',
                 'pointer-container-first-redo-failed.json','pointer-undo-events.json','pointer-heap-state.json','pointer-brush-unsettled-after-undo.json',
                 'cold-undo-result.json','cold-undo-prepare.json','cold-undo-trace.json','host-undo-callbacks.json',
                 'garden-resource-stages.json','stress-resource-stages.json',config['navigation_report'],config['playback_report'],config['enabled_report'],
                 'original-render-settings.json','restored-render-settings.json',
                 'real-corona-qualification.json','real-production.json','real-ir-final.json','material-map-audit03.json','saved-stress-100k.json','saved-heavy-garden.json'):
        source=real/name
        if source.exists():copy(source,'real-assets/'+name)
    for name in ('generated-check.json','python-tests.xml','packaged-mcp-smoke.json'):copy(ROOT/config['offline']/name,'offline/'+name)
    copy(ROOT/'build/full-qualification-073-20261007/hardware.json','hardware.json')
    copy(ROOT/'build/mcp-qualification/real073-ui-assets07/page-clip-state.json','intermediate/page-clip-state.json')
    copy(args.packages/'BUILD.json','packages.json')
    mcp=args.packages/'CyrusMCP-0.73.0';copy(mcp/'package-manifest.json','mcp-package.json')
    before=load(ROOT/'build/approved-layout-073-20261006/workspace-before.json')
    paths=sorted(set(p for p in git('ls-files','--cached','--others','--exclude-standard','-z').split('\0') if p))
    now={p:sha(ROOT/p) for p in paths if (ROOT/p).is_file() and not p.startswith('docs/Full_Qualification_0.73_2026-10-07/evidence/')}
    protected=('CyrusLicensing/','tools/licensing_lab/','docs/licensing/')
    preserved={p:key for p,key in before.items() if p.startswith(protected)}
    assert all(now.get(p)==key for p,key in preserved.items()),'Protected licensing changed since initial inventory'
    source=ROOT/'AminScatter/scripts/AminScatterObject.ms';payload=re.search(r'global CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',source.read_text()).group(1)
    scene_folder=ROOT/'Test Scene/Cyrus_073_Qualification'
    scenes={p.relative_to(ROOT).as_posix():dict(sha256=sha(p),bytes=p.stat().st_size) for p in scene_folder.glob('*.max')}
    images={p.relative_to(ROOT).as_posix():dict(sha256=sha(p),bytes=p.stat().st_size) for p in scene_folder.glob('*.png')}
    snapshot=dict(development_version='0.73',version='0.73.0',serialization=54,calculation_model='CyrusUnified1',
        branch=git('branch','--show-current').strip(),head=git('rev-parse','HEAD').strip(),uncommitted=True,
        script_file_sha256=sha(source),loaded_script_payload_sha256=payload,source_hashes=now,
        changes_since_initial_inventory=dict(changed=[p for p,key in before.items() if p in now and now[p]!=key],added=[p for p in now if p not in before],removed=[p for p in before if p not in now]),
        worktree_status=git('status','--porcelain=v1','--untracked-files=all').splitlines(),protected_licensing_unchanged=True,
        protected_licensing_hashes=preserved,original_scene=protection['original_scene'],scenes=scenes,render_images=images,
        computer_use=True,artist_install=False,commit=False,push=False)
    (DEST/'current-snapshot.json').write_text(json.dumps(snapshot,indent=2)+'\n')
    (DEST/'index.json').write_text(json.dumps(dict(copied=copied,campaigns=config['campaigns'],real_host=config['real_host'],
        excluded='IPC connection descriptors, authentication secrets, journals, full private traces, vendor listings, native binaries and scene bytes',
        boundary='Exact finite qualification, not every feature combination or publication readiness'),indent=2)+'\n')
    print(f'PASS {len(copied)} allowlisted receipts, {len(now)} source/config/document fingerprints and {len(scenes)} saved scenes')

if __name__=='__main__':main()
