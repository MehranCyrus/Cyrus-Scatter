"""Collect bounded qualification receipts; never copies scenes or plugins."""
import hashlib
import json
from pathlib import Path
import shutil
import statistics
import subprocess

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent


def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    evidence=OUT/'evidence';evidence.mkdir(exist_ok=True)
    index=dict(version='0.75',date='2026-10-09',base_commit='108e26c6322cd8bcad392bf6fa266ccc6b96b20c',
               computer_use=False,normal_profile_installation=False,hosts=[],files={},performance=[])
    for host in sorted((ROOT/'build/mcp-qualification').iterdir()):
        if 'qualification075' not in host.name:continue
        q=host/'qualification.json'
        if not q.exists():raise RuntimeError('Unfinished owned host: '+str(host))
        data=json.loads(q.read_text())
        assert data['owned_process_stopped'],host
        assert data['installed_product_files_unchanged'],host
        assert data['host_python_sources_unchanged'],host
        row=dict(name=host.name,passed=data['passed'],stopped=True,installed_files_unchanged=True,
                 script_sha256=data['launch']['script_sha256'],binaries=data['launch']['binaries'])
        if (host/'campaign.json').exists():row['scenarios']=json.loads((host/'campaign.json').read_text())
        if 'error' in data:row['error']=data['error']
        index['hosts'].append(row)
        dest=evidence/host.name;dest.mkdir(exist_ok=True)
        for p in host.rglob('*'):
            if not p.is_file() or p.suffix not in ('.json','.tsv','.txt'):continue
            # Host runtime profiles, diagnostics streams and temporary requests
            # are excluded. Only root reports and per-case result snapshots.
            rel=p.relative_to(host)
            if len(rel.parts)>1 and not rel.parts[0].startswith('case-'):continue
            if p.name.startswith(('probe-','dev-')) or p.stat().st_size>300000:continue
            target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
            index['files'][target.relative_to(OUT).as_posix()]=digest(target)
        for p in host.glob('*-navigation.json'):
            d=json.loads(p.read_text())
            # CSPObject's trials are arrays of key/value pairs.
            trials=[]
            for raw in d['trials']:
                t=dict(raw) if isinstance(raw,list) else raw
                samples=sorted(t['step_ms'])
                trials.append(dict(mode=t['mode'],generated=t['generated'],shown=t['shown'],
                                   median_ms=statistics.median(samples),p95_ms=samples[min(len(samples)-1,int(.95*len(samples)))],
                                   zero_rebuilds=t['zero_rebuilds'],zero_brush_work=t['zero_brush_work']))
            index['performance'].append(dict(host=host.name,initial_update_ms=d['initial_update_ms'],
                population=d['population'],viewport=d['viewport'],source_faces=d['source_faces'],
                working_set_bytes=d['working_set_bytes'],metric=d['metric'],trials=trials))
    for name in ('scatter','analyzer','generated','generated-final'):
        source=ROOT/'build/qualification075'/name
        for p in source.iterdir():
            if p.name not in ('receipt.json','tests.log','generated-check.json'):continue
            target=evidence/(name+'-'+p.name);shutil.copy2(p,target)
            index['files'][target.relative_to(OUT).as_posix()]=digest(target)
    for name in ('pytest.xml','pytest.log','layout-tests.log'):
        p=ROOT/'build/qualification075'/name
        target=evidence/name;shutil.copy2(p,target)
        index['files'][target.relative_to(OUT).as_posix()]=digest(target)
    index['current_sources']={p:digest(ROOT/p) for p in (
        'AminScatter/tools/ui/templates/unified-core.ms','AminScatter/tools/ui/approved-layout.cjs',
        'AminScatter/tools/ui/approved-layout-rows.cjs','AminScatter/scripts/AminScatterObject.ms',
        'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms')}
    for p in (OUT/'fixtures').glob('*'):
        if p.is_file():index['files'][p.relative_to(OUT).as_posix()]=digest(p)
    index['scope_note']='Scripted host/native/offline evidence; unchecked controls and physical/long-session/render gates remain explicit in CHECKLIST.md.'
    (OUT/'EVIDENCE.json').write_text(json.dumps(index,indent=2)+'\n')
    print(json.dumps({k:index[k] for k in ('performance','current_sources')},indent=2))


if __name__=='__main__':main()
