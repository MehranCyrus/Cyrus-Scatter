"""Record this internal native-publication checkpoint; never release-certify it."""
import argparse,hashlib,json,statistics,subprocess
from datetime import datetime,timezone
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--host',required=True);parser.add_argument('--native',type=Path,required=True)
parser.add_argument('--run',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args();assert args.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/args.host;native=args.native.resolve();run=args.run.resolve()
receipt=json.loads((native/'receipt.json').read_text());launch=json.loads((host/'launch.json').read_text())
assert receipt['max_year']==launch['max_year']==2027 and all(stage['exit_code']==0 for stage in receipt['stages'])
assert not launch.get('native_reuse') and not launch['normal_profile_modified'] and not launch['placement_qualification']
assert all(digest(ROOT/path)==sha for path,sha in receipt['sources'].items()),'Source changed after frozen build'
assert digest(host/'scripts/CyrusScatter.ms')==launch['script_sha256']==digest(ROOT/'AminScatter/scripts/AminScatterObject.ms')
for path,sha in receipt['binaries'].items():assert digest(ROOT/path)==sha
for name,sha in launch['binaries'].items():assert digest(host/'bin'/name)==sha
for name,sha in launch['script_assets'].items():assert digest(host/'scripts'/name)==sha
checks={
 'controller-07.log':'MAX 2027 NATIVE CONTROLLER/HISTORY PASSED',
 'binding-07.log':'MAX 2027 NATIVE SOURCE/DATA PUBLICATION PASSED',
 'benchmark-07.log':'MAX 2027 MATCHED CONTROLLER BENCHMARK PASSED',
 'core-07.log':'CORE PASSED','presets-07.log':'ALL EIGHT PRESETS PASSED',
 'python-final.log':'168 passed',
}
for path,marker in checks.items():assert marker in (run/path).read_text(encoding='utf-8-sig'),path
assert '100% tests passed, 0 tests failed out of 43' in (native/'tests.log').read_text()
generated=json.loads((run/'generated-final/generated-check.json').read_text())
assert generated['generated_sha256']==launch['script_sha256']
modules=json.loads((run/'loaded-modules-07.json').read_text(encoding='utf-8-sig'))
assert {entry['Name'] for entry in modules}==set(launch['binaries'])
for entry in modules:
    assert Path(entry['Path']).resolve()==(host/'bin'/entry['Name']).resolve()
    assert entry['SHA256']==launch['binaries'][entry['Name']]
samples=[];groups={}
for line in (host/'controller-benchmark.tsv').read_text(encoding='utf-8-sig').splitlines():
    kind,nativeFlag,iteration,amount,start,end,frequency,heap,free,live,fingerprint=line.split('\t')
    numeric=lambda value:int(value.rstrip('L'))
    sample=dict(terrain=kind,native=nativeFlag=='true',iteration=numeric(iteration),count=numeric(amount),
                update_ms=(numeric(end)-numeric(start))*1000/numeric(frequency),heap=numeric(heap),heap_free=numeric(free),tracked_placement_bytes=numeric(live),fingerprint=fingerprint)
    samples.append(sample)
    if sample['iteration']>0:groups.setdefault((kind,sample['native'],sample['count']),[]).append(sample)
assert len(samples)==72 and len(groups)==12
summaries=[]
for (kind,nativeFlag,count),rows in sorted(groups.items()):
    assert len(rows)==5 and len({row['fingerprint'] for row in rows})==1
    opposite=groups[(kind,not nativeFlag,count)]
    assert rows[0]['fingerprint']==opposite[0]['fingerprint']
    summaries.append(dict(terrain=kind,native=nativeFlag,count=count,samples=5,
                          median_ms=statistics.median(row['update_ms'] for row in rows),
                          min_ms=min(row['update_ms'] for row in rows),max_ms=max(row['update_ms'] for row in rows)))
closure=json.loads((host/'closure-observation.json').read_text());assert closure['exited'] and closure['close_marker']
files=[native/'receipt.json',native/'tests.log',host/'launch.json',host/'startup-observation.json',host/'closure-observation.json',host/'loaded.tsv',
       host/'native-controller.txt',host/'native-binding.txt',host/'controller-benchmark.tsv',run/'loaded-modules-07.json',
       run/'generated-final/generated-check.json',*(run/path for path in checks)]
report={
 'recorded_utc':datetime.now(timezone.utc).isoformat(),'status':'internal scoped checkpoint; no 0.86.0 delivery',
 'head_before_checkpoint':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
 'product_metadata':'0.85.4/schema58/CyrusUnified1; migration default off','host':args.host,
 'native_receipt':str((native/'receipt.json').relative_to(ROOT)).replace('\\','/'),
 'sources':receipt['sources'],'binaries':receipt['binaries'],'loaded_modules':modules,
 'evidence':{str(path.relative_to(ROOT)).replace('\\','/'):digest(path) for path in files},
 'controller_scope':['Surface random on plane/mountain','5k/50k/200k and zero Count','ordinary Count Undo/Redo and unrelated history',
                     'Manual/Live/explicit Update','post-preparation failure retention/recovery','retained point/proxy/mesh switching',
                     'same-cardinality source replacement','passive panel browsing','independent copied native owners',
                     'deletion Undo/Redo','save/reopen with transient native session data','65s idle per terrain','scene retirement including deleted copies'],
 'publication_scope':['ordered detached source correspondence','actual evaluated mesh signature','receiver offset/join/empty provenance',
                      'sealed preparation receipt','shared immutable placements/radii','bounded 500-row cached pages','rejected successor retains previous frame','last-pin GC release'],
 'benchmark':{'description':'Matched controller refreshAll CPU Update windows; hash/file I/O outside timing; warm-up iteration zero excluded; five measured samples per terrain/route/count.',
              'not_measured':['presented FPS','physical mouse/keyboard latency','production rendering','cold native-only script heap','complete plugin/process/VRAM or peak scratch ownership'],
              'summaries':summaries,'samples':samples},
 'open':['optional Paint/mask/falloff/Analyzer/final Relax and radius-ring routing','active Edit and sparse history','render/PFlow/Bake consumers',
         'full N01/N08 resource/peak accounting and N09 acceptance','ready-preset native history and physical UI/renderer acceptance',
         'source geometry sharing, physics/animation extensions and all subsequent objective areas'],
 'delivery':{'version_bumped':False,'installer_created':False,'installed':False,'artist_session_modified':False},
 'limits':['Pure container is not a Max reference target or graphics publication by itself.',
           'Only first controller scope is integrated; supported default route remains the existing engine.',
           'Tracked placement bytes exclude metadata, allocator/GC overhead, solver scratch and GPU buffers.',
           'Receipt proves these working-file bytes; older unedited CRLF inputs may differ from normalized Git blobs.'],
 'corrected_iterations':[
    {'run':'binding-native-01','finding':'Windows RPC boolean typedef collided with a helper name; SDK compilation failed.','correction':'Renamed the helper pubBool.'},
    {'run':'foundation-memory0854-nativeaccept-binding-20261017-01','finding':'Owned process exited before readiness with code 0xffffffff.','correction':'Recorded startup exit; no plugin-test pass inferred; retried only after terminal exit.'},
    {'run':'controller-20261017-01','finding':'Unqualified layerID resolved before the later parameter declaration.','correction':'Use this.layerID; fresh host rerun.'},
    {'run':'controller-20261017-02','finding':'Actual getHandleByAnim IntegerPtr was rejected by the integer-only manifest reader.','correction':'Use the SDK integer-number predicate; Float/Double still rejected.'},
    {'run':'controller-20261017-03','finding':'Deleted copied setup retained 9,600,000 placement bytes after scene reset.','correction':'Weak numeric owner/handle retirement tickets resolve retained owners before full scene transition; do not pin owners or discard deletion Undo.'},
    {'run':'controller-04 initial','finding':'Immediate Count-handler assertion ran before the legitimate release-timer calculation completed.','correction':'Bounded observation of the existing timer, without forcing Update; exact output checks remain.'},
    {'run':'source review after native-06','finding':'A generic source-summary helper added integer counting to the existing script path.','correction':'Preserve the original BitArray presence loops; use native cached histograms only on native views. Native-07 repeats the complete final matrix and matched benchmark.'},
 ],
}
output=args.output.resolve();output.parent.mkdir(parents=True,exist_ok=True)
output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'output':str(output),'source_files':len(receipt['sources']),'benchmark_summaries':summaries},indent=2))
