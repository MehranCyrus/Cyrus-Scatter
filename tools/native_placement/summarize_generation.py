"""Retain every producer timing sample; distinguish it from full Update/FPS."""
from pathlib import Path
import argparse,collections,json,math,statistics,hashlib
ROOT=Path(__file__).resolve().parents[2]
def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('host');p.add_argument('--output',type=Path,required=True);args=p.parse_args()
    assert args.host.startswith('foundation-memory0854-nativegenerate-')
    host=ROOT/'build/mcp-qualification'/args.host;groups=collections.defaultdict(list);hashes=collections.defaultdict(set)
    for line in (host/'generation-benchmark.tsv').read_text().splitlines():
        row=line.split('\t');assert len(row)==16
        kind,count,iteration,mode=row[:4];count=int(count);iteration=int(iteration)
        hashes[(kind,count)].add(row[13])
        category='observation-overhead' if iteration>=20 else 'producer'
        if iteration in (0,20):continue
        n=lambda i:int(row[i].rstrip('L'))
        groups[(category,kind,count,mode)].append({'iteration':iteration,'milliseconds':(n(5)-n(4))*1000/n(6),
            'heap_before':n(7),'heap_free_before':n(8),'heap_after':n(9),'heap_free_after':n(10),
            'native_vector_bytes_before':n(11),'native_vector_bytes_after':n(12),'row_hash':row[13],
            'hash_milliseconds':(n(15)-n(14))*1000/n(6)})
    assert len(groups)==16 and all(len(v)==10 for v in groups.values())
    assert all(len(v)==1 for v in hashes.values())
    summaries=[]
    for key,samples in sorted(groups.items()):
        times=sorted(x['milliseconds'] for x in samples)
        summaries.append({'category':key[0],'terrain':key[1],'count':key[2],'mode':key[3],
            'median_ms':statistics.median(times),'empirical_p95_nearest_rank_ms':times[math.ceil(.95*len(times))-1],
            'samples':samples})
    result={'scope':'Direct canonical producer call, same evaluated geometry/settings/threads; not full Update, accepted placement, render or presented FPS.',
        'repetitions':10,'warmups_excluded':[0,20],'order':'alternating legacy/native or legacy/counters-on',
        'timing_excludes':'light GC, session reservation, diagnostics, hashing, file I/O',
        'memory_limit':'Native bytes track placement-owned vector requests only; excludes native solver/geometry/normal scratch, host/GC/allocator and GPU memory.',
        'host':host.relative_to(ROOT).as_posix(),'raw_sha256':hashlib.sha256((host/'generation-benchmark.tsv').read_bytes()).hexdigest(),
        'summaries':summaries}
    args.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    for entry in summaries:print(entry['category'],entry['terrain'],entry['count'],entry['mode'],'median',round(entry['median_ms'],3),'p95',round(entry['empirical_p95_nearest_rank_ms'],3))
if __name__=='__main__':main()
