"""Drive focused checks through the already launched disposable Max transport."""
from pathlib import Path
import argparse,json,time
ROOT=Path(__file__).resolve().parents[3]
p=argparse.ArgumentParser();p.add_argument('--host',type=Path,required=True);a=p.parse_args()
out=a.host.resolve();assert out.is_relative_to(ROOT/'build')
def wait_report(name,stamp=0,timeout=180):
    file=out/name;end=time.monotonic()+timeout
    while time.monotonic()<end:
        if file.exists() and file.stat().st_mtime>stamp:
            try:
                if file.suffix=='.json':
                    report=json.loads(file.read_text());status=report.get('status')
                    if status=='failed':raise RuntimeError(report)
                    if status=='complete':return report
                else:
                    report=file.read_text()
                    if 'ERROR ' in report:raise RuntimeError(report)
                    if report.rstrip().endswith('COMPLETE'):return report
            except json.JSONDecodeError:pass
        time.sleep(.25)
    raise TimeoutError(name)
def dispatch(name,relative,report,timeout=180):
    script=ROOT/relative;stamp=time.time();path=out/f'campaign-{name}.ms'
    path.write_text(('python.ExecuteFile' if script.suffix=='.py' else 'fileIn')+' @"'+script.as_posix()+'"\n')
    (out/'dev-request.txt').write_text(path.as_posix())
    result=wait_report(report,stamp,timeout);print(name+': complete',flush=True);return result
wait_report('workflow.json');print('workflow: complete',flush=True)
dispatch('pointer','tools/procedural_lab/selection08764/pointer.py','pointer.json')
dispatch('transforms','tools/procedural_lab/selection08764/transform_events.ms','transform-events.txt')
dispatch('lifecycle','tools/procedural_lab/selection08764/lifecycle.py','lifecycle.json')
garden=dispatch('garden','tools/procedural_lab/selection08762/garden_pick.py','garden-pick.json',600)
assert garden['epochs_before']==garden['epochs_after'] and garden['streams_before']==garden['streams_after'] and not any(garden['errors'])
dispatch('navigation','tools/procedural_lab/selection08762/garden_navigation.py','navigation.json')
(out/'campaign.json').write_text(json.dumps(dict(status='complete',garden_placements=sum(garden['placements']),garden_median_ms=garden['median_ms'],garden_max_ms=garden['max_ms']),indent=2))
