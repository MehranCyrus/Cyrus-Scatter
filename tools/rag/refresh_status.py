"""Explicit, read-only Phase 4A inspection; stdout only, no candidate or activation."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

from refresh_boundary import WorkerJob, kill_worker
from refresh_inspect import LIMITS, base_report, encoded, inspect


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise ValueError(message)


def failed(root, index, reason, code=2):
    report = base_report(root,index)
    report.update(exit_code=code,report_error=reason)
    report['checks']['omitted']=['Full observation unavailable: '+reason]
    report['next_actions']=['Resolve the inspection failure and retry explicitly; no generation or binding was changed']
    return report


def wire(report):
    raw=encoded(report)
    if len(raw)>LIMITS['report_bytes']:
        report=failed(report['repository'],report['selected']['index'],'report_size_exceeded: complete report was not emitted; no issues silently pruned')
        report['omitted_report_bytes']=len(raw)
        raw=encoded(report)
    return raw


def guarded(root,index,evaluations):
    command=[sys.executable,'-B',str(Path(__file__).resolve()),'--root',str(root),'--index',str(index),'--json','--_worker']
    for path,receipt in evaluations:command.extend(['--evaluation',path,receipt])
    process=None;job=None
    try:
        process=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                                 creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0),start_new_session=os.name!='nt')
        # The child waits for stdin, so no Git subprocess can escape this kill scope.
        job=WorkerJob(process.pid)
        raw,errors=process.communicate(b'go\n',timeout=LIMITS['wall_seconds'])
        if process.returncode not in (0,1,2) or errors or len(raw)>LIMITS['report_bytes']:
            return failed(root,index,'Owned inspection worker failed or exceeded its output bound')
        return json.loads(raw)
    except subprocess.TimeoutExpired:
        return failed(root,index,'Inspection wall deadline exceeded; owned worker was stopped')
    except KeyboardInterrupt:
        return failed(root,index,'Inspection cancelled; owned worker was stopped',130)
    except (OSError,ValueError):
        return failed(root,index,'Cannot establish or read the owned bounded inspection worker')
    finally:
        if job is not None:job.close()
        if process is not None:
            if process.poll() is None:kill_worker(process)
            process.wait(timeout=3)
            for stream in (process.stdin,process.stdout,process.stderr):
                if stream is not None:stream.close()


def main(argv=None):
    if hasattr(sys.stdout,'reconfigure'):sys.stdout.reconfigure(encoding='utf-8')
    parser=Parser(description=__doc__)
    parser.add_argument('--root',type=Path,required=True)
    parser.add_argument('--index',type=Path,required=True)
    parser.add_argument('--json',action='store_true')
    parser.add_argument('--evaluation',nargs=2,action='append',default=[],metavar=('RELATIVE_DEFINITION','RECEIPT'))
    parser.add_argument('--_worker',action='store_true',help=argparse.SUPPRESS)
    args=None
    try:
        args=parser.parse_args(argv)
        if len(args.evaluation)>LIMITS['evaluation_baselines']:raise ValueError('Evaluation baseline count bound exceeded')
        if args._worker:
            if sys.stdin.buffer.readline(4)!=b'go\n':raise ValueError('Owned worker start gate missing')
            report=inspect(args.root,args.index,args.evaluation)
        else:
            report=guarded(args.root,args.index,args.evaluation)
    except KeyboardInterrupt:
        report=failed(getattr(args,'root',None),getattr(args,'index',None),'Inspection cancelled',130)
    except Exception as exc:
        report=failed(getattr(args,'root',None),getattr(args,'index',None),'Inspection unavailable: '+type(exc).__name__)
    raw=wire(report);report=json.loads(raw)
    if args is None or args.json or args._worker:
        sys.stdout.buffer.write(raw);sys.stdout.buffer.flush()
    else:
        print(f"Generation: {report['selected']['generation']} | integrity: {report['generation_integrity']['state']}")
        if report['generation_integrity'].get('reason'):print('Integrity: '+report['generation_integrity']['reason'])
        for check in report['generation_integrity']['omitted_checks']:print('Integrity unfinished/omitted: '+check)
        print(f"Compatibility: {report['compatibility']['state']} | sources: {report['source_freshness']['state']} ({report['source_freshness']['completeness']})")
        print(f"Parents: {report['source_freshness']['completed']}/{report['source_freshness']['enrolled']} determinate | consumer config: {report['consumer_binding']['state']} | running consumer: unknown")
        for category in ('parents','inputs','evaluation_definitions'):
            for row in report[category]:
                if row['outcome']!='unchanged':print(f"{category}: {row['path']}: {row['outcome']}"+(' — '+row['reason'] if row.get('reason') else ''))
        if report.get('report_error'):print(report['report_error'])
        for action in report['next_actions']:print('Action: '+action)
        print('Human review pending | candidate not prepared | no update or activation performed')
    return report['exit_code']


if __name__=='__main__':
    raise SystemExit(main())
