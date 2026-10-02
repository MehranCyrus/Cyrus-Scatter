"""Isolated probes. Run only after validate.py builds and host tests finish."""
from research_tools import ROOT,HERE,EVIDENCE,SCRATCH,run_logged,record,digest
from validate import environment
import argparse
import json
import statistics
import shutil

def sdk():
    env=environment()
    results=[]
    for year in (2026,2027):
        sdkroot=ROOT/f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk'
        dest=SCRATCH/f'sdk-probe-{year}'
        dest.mkdir(parents=True,exist_ok=True)
        argv=[shutil.which('cl.exe',path=env['PATH']),'/nologo','/O2','/MD','/EHsc','/LD','/DUNICODE','/D_UNICODE','/DNOMINMAX',
              '/std:c++20' if year==2027 else '/std:c++17',f'/I{sdkroot / "include"}',
              HERE/'sdk_probe.cpp',f'/Fo{dest}/',f'/Fe{dest / "sdk-probe.dll"}',
              '/link',f'/LIBPATH:{sdkroot / "lib/x64/Release"}',
              'core.lib','geom.lib','mesh.lib','gfx.lib','maxutil.lib','GraphicsDriver.lib','GraphicsUtility.lib','optimesh.lib']
        run_logged(f'sdk-probe-{year}',argv,env,cwd=dest)
        results.append(dict(year=year,status='compiled and linked; never loaded or called',
            sha256=digest(dest/'sdk-probe.dll'),sample_present=(sdkroot/'howto/objects/viewportinstance/instanceobject.cpp').exists()))
    record('sdk-probes.json',results)

def projection():
    env=environment();dest=SCRATCH/'projection';dest.mkdir(parents=True,exist_ok=True)
    argv=[shutil.which('cl.exe',path=env['PATH']),'/nologo','/O2','/Ob2','/DNDEBUG','/MD','/EHsc','/std:c++20',f'/I{ROOT / "AminScatter/include"}',
          HERE/'projection_probe.cpp',ROOT/'AminScatter/src/execution.cpp',f'/Fo{dest}/',f'/Fe{dest / "projection-probe.exe"}']
    run_logged('projection-compile',argv,env,cwd=dest)
    run_logged('projection-raw',[dest/'projection-probe.exe'],env,cwd=dest)
    rows=[json.loads(x) for x in (EVIDENCE/'projection-raw.txt').read_text().splitlines()]
    summary=[]
    for triangles in sorted({x['triangles'] for x in rows if x['type']=='projection'}):
        group=[x for x in rows if x.get('triangles')==triangles]
        item=dict(triangles=triangles,queries=group[0]['queries'],trials=len(group))
        for key in ['scan_ms','tree_build_ms','tree_query_ms','tree_build_query_ms']:
            item[key]=dict(median=statistics.median(x[key] for x in group),min=min(x[key] for x in group),max=max(x[key] for x in group))
        item['position_mismatches']=sum(x['position_mismatches'] for x in group)
        item['triangle_mismatches']=sum(x['triangle_mismatches'] for x in group)
        summary.append(item)
    record('projection-summary.json',dict(executable_sha256=digest(dest/'projection-probe.exe'),
        scope='Standalone queries on planar synthetic grids; not complete scatter or Max benchmark; no replacement shipped',
        warmups=2,tie=rows[0],cases=summary,sizes=rows[-1]))

def threads():
    exe=SCRATCH/'max2027/AminScatter/scatter_benchmark.exe';results=[];hashes={}
    for block in range(3):
        for policy in ([1,0] if block%2==0 else [0,1]):
            dest=SCRATCH/f'threads-{block}-{policy}'
            label=f'threads-{block}-{policy}'
            run_logged(label,[exe,dest,policy,7])
            rows=[json.loads(x) for x in (EVIDENCE/f'{label}.txt').read_text().splitlines()]
            for row in rows:
                row.update(block=block,policy=policy)
                if 'case' in row:
                    sha=digest(dest/(row['case']+'.bin'));row['sha256']=sha
                    if row['case'] in hashes and hashes[row['case']]!=sha: raise RuntimeError('Serial/automatic output differs')
                    hashes[row['case']]=sha
            results.extend(rows)
    summary=[]
    for case in sorted(hashes):
        item={'case':case,'sha256':hashes[case]}
        for policy in (1,0):
            rows=[x for x in results if x.get('case')==case and x['policy']==policy]
            values=[t for x in rows for t in x['samples_ms']]
            item[str(policy)]=dict(median_ms=statistics.median(values),min_ms=min(values),max_ms=max(values),
                                  participants=rows[0]['participants'],n=len(values),block_medians_ms=[x['median_ms'] for x in rows])
        summary.append(item)
    record('threads-summary.json',dict(executable_sha256=digest(exe),
        scope='Existing 17-case synthetic native suite, current serial vs current automatic; not a Max benchmark',
        trial_order='serial/auto, auto/serial, serial/auto; one warmup and seven trials per case per block; existing harness sorts samples within a block',
        cases=summary,raw=results))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['sdk','projection','threads']);a=p.parse_args()
    globals()[a.action]()
