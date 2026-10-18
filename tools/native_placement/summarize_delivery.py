"""Summarize immutable timing windows; never reinterpret retained bytes as peak."""
from pathlib import Path
import bisect, collections, hashlib, json, math, statistics
ROOT=Path(__file__).resolve().parents[2]
HOSTS=ROOT/'build/mcp-qualification'
OUT=ROOT/'build/native-fields-0860-20261018-01/performance-final.json'
assert not OUT.exists()
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def n(v): return int(v.rstrip('L'))
def summarize(name,paint=False,saved=False):
    h=HOSTS/name
    filename='paint-benchmark.tsv' if paint else ('saved-native-baseline.tsv' if saved else 'native-baseline.tsv')
    samples=h/('paint-process-samples.tsv' if paint else ('saved-native-process-samples.tsv' if saved else 'native-process-samples.tsv'))
    rows=[tuple(map(int,line.split('\t'))) for line in samples.read_text().splitlines()[1:]]
    stamps=[r[0] for r in rows]
    groups=collections.defaultdict(list); fingerprints=collections.defaultdict(set)
    for line in (h/filename).read_text().splitlines():
        p=line.split('\t')
        kind='multi-area Paint' if paint else p.pop(0)
        iteration,count,start,end,freq=map(n,p[:5])
        hash=p[10] if paint else p[14]
        fingerprints[(kind,count)].add(hash)
        if iteration==0: continue
        lo=bisect.bisect_left(stamps,start);hi=bisect.bisect_right(stamps,end)
        assert hi>lo
        before=rows[max(0,lo-1)][1];peak=max(r[1] for r in rows[lo:hi])
        groups[(kind,count)].append(dict(iteration=iteration,update_ms=(end-start)*1000/freq,
            heap_before=n(p[5]),heap_after=n(p[7]),process_before=before,
            process_peak=peak,process_growth=peak-before,sample_count=hi-lo))
    assert all(len(v)==10 for v in groups.values())
    assert all(len(v)==1 for v in fingerprints.values())
    result=[]
    for (kind,count),measurements in sorted(groups.items()):
        ordered=sorted(r['update_ms'] for r in measurements)
        result.append(dict(kind=kind,count=count,ordered_fingerprint=next(iter(fingerprints[(kind,count)])),
            median_ms=statistics.median(ordered),empirical_p95_ms=ordered[math.ceil(.95*len(ordered))-1],
            median_process_peak=statistics.median(r['process_peak'] for r in measurements),
            median_process_growth=statistics.median(r['process_growth'] for r in measurements),
            samples=measurements))
    launch=json.loads((h/'launch.json').read_text())
    return dict(host=str(h.relative_to(ROOT)).replace('\\','/'),script_sha256=launch['script_sha256'],
        profile_template_sha256=launch['profile_template_sha256'],timings=result,
        receipts={p.name:sha(p) for p in (h/filename,samples,h/'launch.json')})
old='foundation-memory0854-nativeobserve-baseline-20261018-02'
new='foundation-memory0854-nativeaccept-controller-20261018-22'
final='foundation-memory0854-nativeaccept-controller-20261018-20'
result=dict(schema='cyrus.native-migration-performance/1',max_year=2027,
    count=dict(old=summarize(old),native11=summarize(new,saved=True)),
    paint=dict(old=summarize(old,True),native11=summarize(final,True)),
    limits=[
      'Ten warm samples, iteration zero excluded; fingerprint/reachability/logging outside Update.',
      'Count final11 loads the exact old plane/mountain scenes and repeats the N01 selected-Modify/history sequence. Every ordered fingerprint matches. Concurrent soak/desktop activity remains uncontrolled noise.',
      'Earlier independently authored Count comparisons had different variation identities; performance-11.json retains that limitation. They are not the Count comparison in this successor.',
      'Paint loads the exact old saved scene into final11; Modify panel is deselected in both. Profile template hashes match.',
      'Sequential runs on the same machine; desktop/OS noise is retained. p95 is empirical nearest-rank of ten samples, not a broad latency guarantee.',
      'Sampled process private commit includes Max/allocator/renderer memory and is not exact plugin peak or VRAM.',
      'Script heap capacity is not used memory. Old reachable object/array payload and native store high-water exclude other solver/SDK allocations; do not call their ratio total memory savings.'
    ])
for group in ('count','paint'):
    pair=list(result[group].values())
    assert pair[0]['profile_template_sha256']==pair[1]['profile_template_sha256']
    assert [r['ordered_fingerprint'] for r in pair[0]['timings']]==[r['ordered_fingerprint'] for r in pair[1]['timings']]
OUT.write_text(json.dumps(result,indent=2)+'\n')
for group,pairs in result.items():
    if group not in ('count','paint'):continue
    for route,item in pairs.items():
        for r in item['timings']: print(group,route,r['kind'],r['count'],round(r['median_ms'],1),round(r['empirical_p95_ms'],1),'private_peak_MiB',round(r['median_process_peak']/1048576,1))
