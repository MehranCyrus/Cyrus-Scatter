"""Read historical artifacts and verify their hashes without rerunning their scenes."""
from research_tools import ROOT,EVIDENCE,HERE,record,digest,run_logged,stamp
import importlib.util
import json
import subprocess

def historical():
    checks=[]
    for folder in ['Viewport_Performance_Implementation_2026-10-01','Viewport_Performance_Round2_2026-10-01']:
        base=ROOT/'docs'/folder
        data=json.loads((base/'evidence/index.json').read_text(encoding='utf-8-sig'))
        failures=[]; missing=[]; matched=0
        for item in data['files']:
            p=base/item['path']
            if not p.is_file():missing.append(item['path'])
            elif digest(p)!=item['sha256']:failures.append(item['path'])
            else:matched+=1
        checks.append(dict(folder=folder,index_sha256=digest(base/'evidence/index.json'),matched=matched,missing=missing,mismatched=failures))
    spec=importlib.util.spec_from_file_location('historical_summarizer',ROOT/'tools/performance/summarize_viewport.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    summaries=[]
    for folder,sub in [('Viewport_Performance_Implementation_2026-10-01','matrix'),
                       ('Viewport_Performance_Round2_2026-10-01','candidate-matrix'),
                       ('Viewport_Performance_Round2_2026-10-01','matrix')]:
        base=ROOT/'docs'/folder/'evidence'/sub
        result=module.summarize(base)
        record(f'recomputed-{folder}-{sub}.json',result)
        summaries.append(dict(folder=folder,sub=sub,frames=result['frame_count'],
            cases={k:dict(n=v['samples'],wall=v['metrics']['wall_ms'],callback=v['metrics']['scatter_callback_ms'],
               rebuilds=v['preview_rebuild_deltas'],analyzer=v['analyzer_run_deltas'],pflow=v['pflow_build_deltas'],
               populations=v['populations'],errors=v['errors']) for k,v in result['cases'].items()}))
    cpu=json.loads((ROOT/'docs/Performance_Evidence_2026-10-01.json').read_text())
    artifacts=[]
    for key in ['native_benchmark','saved_scene_benchmark']:
        item=cpu[key];p=__import__('pathlib').Path(item['artifact'])
        artifacts.append(dict(kind=key,path=str(p),exists=p.is_file(),hash_matches=p.is_file() and digest(p)==item['artifact_sha256']))
    scene=cpu['saved_scene_benchmark']['report']; outputs=scene['output_sha256']
    paired=outputs['reference']==outputs['candidate']
    scene_path=__import__('pathlib').Path(scene['scene'])
    scene_check=dict(path=str(scene_path),exists=scene_path.is_file(),sha256=digest(scene_path) if scene_path.is_file() else None,
                     historical_sha256=scene['scene_sha256'])
    record('historical-audit.json',dict(audited_utc=stamp(),scope='Hash verification and arithmetic reanalysis only; historical performance remains class C',
        indexes=checks,cpu_artifacts=artifacts,scene=scene_check,recorded_cpu_output_pairs_equal=paired,
        recorded_cpu_output_pairs=len(outputs['reference']),viewport=summaries))
    print(json.dumps(dict(indexes=checks,cpu_artifacts=artifacts,scene=scene_check,recorded_pairs=len(outputs['reference']),pairs_equal=paired),indent=2))
    for matrix in summaries:
        for case,data in matrix['cases'].items():
            print(matrix['folder'],matrix['sub'],case,'n=',data['n'],'wall median/p95=',data['wall']['median'],data['wall']['p95'],
                  'callback median=',data['callback']['median'],'rebuilds=',data['rebuilds'])

def finish():
    original=json.loads((EVIDENCE/'source-fingerprint.json').read_text())
    changed=[]
    for item in original['files']:
        p=ROOT/item['path']
        if not p.exists() or digest(p)!=item['sha256']: changed.append(item['path'])
    diff=subprocess.check_output(['git','-c','core.autocrlf=false','diff','--no-ext-diff','--binary'],cwd=ROOT)
    diff_matches=diff==(EVIDENCE/'working-tree-diff.txt').read_bytes()
    status=subprocess.check_output(['git','status','--porcelain=v1','-uall'],cwd=ROOT).decode('utf-8')
    def unrelated(s):return sorted(x for x in s.splitlines() if 'docs/Codebase_Research_2026-10-01/' not in x)
    status_matches=unrelated(status)==unrelated((EVIDENCE/'git-status-before.txt').read_text(encoding='utf-8'))
    installed=__import__('pathlib').Path('C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/scripts/AminScatter/AminScatterObject.ms')
    installed_sha=digest(installed) if installed.is_file() else None
    record('preservation.json',dict(verified_utc=stamp(),fingerprinted_files=len(original['files']),changed=changed,
           tracked_diff_byte_identical=diff_matches,unrelated_status_identical=status_matches,
           installed_script_path=str(installed),installed_script_sha256=installed_sha,
           installed_script_matches_source=installed_sha==digest(ROOT/'AminScatter/scripts/AminScatterObject.ms')))
    run_logged('git-status-after',['git','status','--porcelain=v1','-uall'])
    manifest=[dict(path=p.relative_to(HERE).as_posix(),bytes=p.stat().st_size,sha256=digest(p)) for p in sorted(HERE.rglob('*'))
              if p.is_file() and '__pycache__' not in p.parts and p.name!='artifact-manifest.json']
    record('artifact-manifest.json',dict(captured_utc=stamp(),files=manifest))
    print('Source preservation:',len(original['files']),'files;',len(changed),'changed. Manifest:',len(manifest),'artifacts.')
    if changed or not diff_matches or not status_matches: raise RuntimeError('Original source/Git state changed; investigate before finalizing')

if __name__=='__main__':
    import sys
    {'historical':historical,'finish':finish}[sys.argv[1]]()
