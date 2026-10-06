"""Validate/copy concise receipts; never launches Max or alters qualification."""
import argparse
from datetime import datetime,timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/Integrated_UI_0.72_2026-10-06/evidence'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--qualified',required=True,type=Path)
    parser.add_argument('--playback',required=True,type=Path)
    parser.add_argument('--packages',required=True,type=Path)
    args=parser.parse_args()
    host=args.qualified.resolve()
    assert host.parent==ROOT/'build/mcp-qualification'
    stage=ROOT/'build/ui-072-20261006'/host.name.removeprefix('procedural07-ui-072-')
    controls=load(stage/'receipt.json')
    assert controls['passed'] and controls['full'] and controls['artist_profile_unchanged']
    script=digest(ROOT/'AminScatter/scripts/AminScatterObject.ms')
    assert controls['script_sha256']==script
    profile=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
    assert digest(profile)==controls['profile_sha256_before']==controls['profile_sha256_after']
    idle=load(host/'idle-qualification.json')
    corona=load(host/'corona072-result.json')
    assert idle['passed'] and idle['launch_script_sha256']==script
    assert corona['passed'] and corona['script_sha256']==script
    assert load(args.playback/'receipt.json')['passed']
    assert load(args.playback/'receipt.json')['sources_and_binaries']['AminScatterObject.ms']==script
    builds=load(args.packages/'BUILD.json')
    for year,record in builds.items():
        assert record['script_sha256']==script
        for name,row in record['packages'].items():
            assert digest(args.packages/('Max'+year)/name)==row['sha256']
    tests=ET.parse(ROOT/'build/ui-072-20261006/python-tests.xml').getroot()[0]
    assert int(tests.attrib['tests'])==140 and int(tests.attrib['failures'])==int(tests.attrib['errors'])==0
    for state,hidden in [('selected',False),('empty',True)]:
        rows=load(host/f'native-rollup-{state}.json')['rows']
        assert len(rows)==16 and all(r['explicitly_hidden']==hidden for r in rows)
    OUT.mkdir(parents=True,exist_ok=False)
    files={
        'max-controls.json':stage/'receipt.json',
        'playback-final.json':args.playback/'receipt.json',
        'packages.json':args.packages/'BUILD.json',
        'generated-check.json':ROOT/'build/procedural-07/generated-check.json',
        'python-tests.xml':ROOT/'build/ui-072-20261006/python-tests.xml',
        'launch.json':host/'launch.json',
    }
    for name in ['ui072-acceptance.json','corona-stop-072.json','procedural-acceptance.json',
                 'bindings-acceptance.json','review-regressions.json',
                 'source-containers.json','source-container-edge-cases.json','source-container-events.json','source-container-output.json',
                 'layer-editor-071-brush-live.json','layer-editor-071-events.json',
                 'idle-qualification.json','ui072-100k-navigation.json','retained-ui-072.json',
                 'native-rollup-selected.json','native-rollup-empty.json',
                 'direct-diagnostics.json','corona072-result.json','corona072-trace.json']:
        files[name]=host/name
    for condition in idle['cases']:
        for suffix in ('start','end'):
            name=condition['case']+'-'+suffix+'.json'
            files['idle/'+name]=host/name
    for year in (2026,2027):
        for project,folder in [('scatter',ROOT/f'build/ui-072-20261006/native-max{year}'),
                               ('analyzer',ROOT/f'build/playback-20261006/analyzer-max{year}')]:
            receipt=load(folder/'receipt.json')
            assert all(s['exit_code']==0 for s in receipt['stages'])
            assert all(digest(ROOT/n)==sha for n,sha in receipt['sources'].items())
            files[f'native-{year}-{project}.json']=folder/'receipt.json'
            files[f'native-{year}-{project}-tests.log']=folder/'tests.log'
    for run in ('03','04'):
        source=ROOT/f'build/playback-20261006/ui072-regression{run}/receipt.json'
        if source.exists():files[f'intermediate/playback{run}.json']=source
    for name,source in files.items():
        target=OUT/name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
    paths=subprocess.check_output(['git','ls-files','-co','--exclude-standard'],cwd=ROOT,text=True).splitlines()
    prefixes=('AminScatter/','CyrusSurfaceAnalyzer/','CyrusMCP/','cmake/','tools/')
    sources={n:digest(ROOT/n) for n in sorted(set(paths)) if n.startswith(prefixes) and (ROOT/n).is_file()}
    protected_status=subprocess.check_output(['git','status','--porcelain','--','CyrusLicensing','tools/licensing_lab','docs/licensing'],cwd=ROOT,text=True)
    assert not protected_status,'Unrelated licensing changes must be preserved and accounted for'
    snapshot=dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(),
                  backup_commit='75564c4',branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
                  development_version='0.72',package_version='0.72.0',serialization=53,
                  script_sha256=script,source_files=sources,
                  computer_use=False,artist_scene_opened=False,normal_profile_installed=False,
                  artist_ini_sha256=digest(profile),licensing_changed=False,
                  limits=['Raw local bytes; Git text normalization can differ. Frozen script is LF.',
                          'Whole-process CPU/memory is not Cyrus-only; no presented FPS or pointer/DPI qualification.'])
    (OUT/'snapshot.json').write_text(json.dumps(snapshot,indent=2)+'\n',encoding='utf-8')
    index={p.relative_to(OUT).as_posix():dict(sha256=digest(p),bytes=p.stat().st_size)
           for p in sorted(OUT.rglob('*')) if p.is_file()}
    (OUT/'index.json').write_text(json.dumps(dict(schema='cyrus.evidence-index/1',files=index),indent=2)+'\n',encoding='utf-8')
    print(f'PASS {len(index)} preserved receipts; {len(sources)} inventoried source/configuration files')


if __name__=='__main__':main()
