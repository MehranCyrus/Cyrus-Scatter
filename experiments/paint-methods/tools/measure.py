"""Ten independent core benchmark repetitions; no Max process is launched."""
from pathlib import Path
import argparse,csv,hashlib,io,json,statistics,subprocess
LAB=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--build',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);a=ap.parse_args();output=a.output.resolve();output.mkdir(parents=True,exist_ok=True);exe=a.build.resolve()/'lab_benchmark.exe';rows=[]
    for repeat in range(10):
        r=subprocess.run([str(exe)],capture_output=True,text=True,check=True)
        if r.stderr.strip():raise RuntimeError(r.stderr)
        for row in csv.DictReader(io.StringIO(r.stdout)):row['repeat']=repeat;rows.append(row)
        print('repetition',repeat+1,flush=True)
    with (output/'core-timings.csv').open('w',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    summary=[]
    for method in range(1,5):
        group=[r for r in rows if int(r['method'])==method and r['scenario']=='growing' and int(r['gestures'])==1000]
        summary.append({'method':method,'scenario':'growing','gestures':1000,'independent_repetitions':len(group),'edit_1000_ms_median':statistics.median(float(r['edit_ms']) for r in group),'query_100k_ms_median':statistics.median(float(r['query_100k_ms']) for r in group),'query_100k_ms_min':min(float(r['query_100k_ms']) for r in group),'query_100k_ms_max':max(float(r['query_100k_ms']) for r in group),'state_bytes':int(group[0]['state_bytes']),'history_logical_bytes':int(group[0]['history_logical_bytes']),'accepted':int(group[0]['accepted'])})
    receipt={'benchmark_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'qualification':'Independent CPU process repetitions of 1000-unit plane / resolution 5. Not a physical latency, FPS, common accuracy-tier qualification or warmed host benchmark. History bytes conservatively double-count shared blocks.','summary':summary}
    (output/'core-summary.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(summary,indent=2))
if __name__=='__main__':main()
