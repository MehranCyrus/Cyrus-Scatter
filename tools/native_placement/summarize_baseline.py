"""Summarize saved N01 timing windows, separate diagnostics, and raw identities."""
from pathlib import Path
import argparse, collections, hashlib, json, math, re, statistics
ROOT=Path(__file__).resolve().parents[2]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def number(value):return int(value.rstrip('L'))
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
    assert args.host.startswith('foundation-memory0854-nativeobserve-')
    host=ROOT/'build/mcp-qualification'/args.host
    driver=json.loads((host/'native-baseline-driver.json').read_text());assert not driver['sampling_errors']
    samples=[tuple(map(int,line.split('\t'))) for line in (host/'native-process-samples.tsv').read_text().splitlines()[1:]]
    groups=collections.defaultdict(list);fingerprints=collections.defaultdict(set)
    for line in (host/'native-baseline.tsv').read_text().splitlines():
        fields=line.split('\t');assert len(fields)==19
        kind=fields[0];iteration,count=map(number,fields[1:3]);start,end,freq=map(number,fields[3:6]);key=(kind,count)
        fingerprints[key].add(fields[15])
        if not 1<=iteration<=driver['repetitions']:continue
        window=[row for row in samples if start<=row[0]<=end];assert window, (kind,iteration,count)
        prior=next((row for row in reversed(samples) if row[0]<=start),window[0])
        groups[key].append({'iteration':iteration,'update_ms':(end-start)*1000/freq,
            'heap_bytes_before':number(fields[6]),'heap_free_before':number(fields[7]),
            'heap_bytes_after':number(fields[8]),'heap_free_after':number(fields[9]),
            'history_depth':number(fields[14]),'displayed_points':number(fields[18]),
            'hash_ms':(number(fields[17])-number(fields[16]))*1000/freq,
            'process_private_before':prior[1],'process_private_peak':max(row[1] for row in window),
            'process_window_samples':len(window)})
    assert len(groups)==8 and all(len(v)==10 for v in groups.values())
    assert all(len(v)==1 for v in fingerprints.values())
    summary=[]
    for key,rows in sorted(groups.items()):
        times=sorted(row['update_ms'] for row in rows)
        summary.append({'kind':key[0],'count':key[1],'ordered_eight_field_sha256':next(iter(fingerprints[key])),
            'median_update_ms':statistics.median(times),'empirical_p95_nearest_rank_ms':times[math.ceil(.95*len(times))-1],
            'samples':rows})
    observations=[]
    pattern=r'(plane|mountain) Count=(\d+) values=#\((.*?)\) buffers=#\((.*?)\)'
    for line in (host/'native-observation.txt').read_text().splitlines():
        match=re.search(pattern,line);assert match,line
        fields=[number(v.strip()) for v in match[3].split(',')];assert len(fields)==16
        observations.append({'kind':match[1],'count':int(match[2]),'unique_arrays':fields[0],
            'array_capacity_slots':fields[1],'used_array_slots':fields[2],'unique_row_arrays':fields[3],
            'unique_matrix_values':fields[4],'unique_point_values':fields[5],'unique_strings':fields[6],
            'string_logical_units':fields[7],'known_sdk_object_payload_bytes':fields[13],
            'array_pointer_capacity_bytes':fields[14],'observer_microseconds':fields[15],
            'schedule_radius_live_counts_capacities':[number(v.strip()) for v in match[4].split(',')]})
    idle=(host/'native-idle.txt').read_text();assert idle.startswith('PASS:')
    launch=json.loads((host/'launch.json').read_text())
    paths=['launch.json','native-baseline.tsv','native-observation.txt','native-baseline-driver.json','native-process-samples.tsv','native-idle.txt','native-observer-check.txt','n01-plane.max','n01-mountain.max']
    result={'status':'scoped N01 baseline passed; complete N01 acceptance remains open','date':'2026-10-17',
        'baseline_plugin_checkpoint':'7379ea36240011808955991ddc07e3d35fd894e6',
        'version':'0.85.4 plus read-only observer; not a delivery','max_year':2027,
        'host':str(host.relative_to(ROOT)).replace('\\','/'),'pid':driver['pid'],
        'launch_sha256':sha(host/'launch.json'),'repetitions':10,'warmup_iteration':0,
        'timing_includes':'explicit Manual Update after an authored Count hold',
        'timing_excludes':'fingerprint, reachability traversal and file I/O',
        'fixture':'64x64 triangulated 100m plane / analytic mountain, pyramid source, Point Cloud, one sampled point per plant, existing 20k preview cap',
        'memory_qualification':'Unique reachable known SDK object and array capacity payload; excludes string capacity/allocator/GC/host ownership. Sampled process private commit is separate. Native schedule/radius capacities reported separately.',
        'limits':['No physical input latency, Mesh drawing or renderer qualification.','Ten warm repetitions do not measure whole-session history/peak lifetimes.','Sampler overhead not separately quantified.','Remaining N01: materialization/stage/scratch counters, complete peak coexistence, history pin ownership and Max hold/Size probes before N07.'],
        'idle_120_seconds':idle,'observations':observations,'timings':summary,
        'raw_receipt_sha256':{path:sha(host/path) for path in paths}}
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    for entry in summary:print(entry['kind'],entry['count'],'median_ms',round(entry['median_update_ms'],2),'p95_ms',round(entry['empirical_p95_nearest_rank_ms'],2))
    print('Saved',args.output)
if __name__=='__main__':main()
