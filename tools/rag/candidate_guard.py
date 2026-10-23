"""One finite owned orchestration process; no helpers, networking or global kills."""
import json
import os
from pathlib import Path
import subprocess
import sys
import threading
import time
import uuid

import candidate_support as support
from refresh_boundary import WorkerJob,kill_worker


def guarded_operation(args,argv=None):
    if not 1<=args.total_seconds<=support.BOUNDS['max_total_seconds']:
        raise support.Blocked('invalid_deadline','Total operation deadline outside documented bounds')
    token=uuid.uuid4().hex
    # Windows venv python.exe redirects to another process. Use the base
    # interpreter so the launched PID matches the child's ownership receipt.
    command=[sys._base_executable,'-B',str(support.TOOL/'prepare_candidate.py'),*(sys.argv[1:] if argv is None else argv),'--json','--_orchestrator','--_token',token]
    process=None;job=None;threads=[];overflow=threading.Event();buffers=[bytearray(),bytearray()]
    limits=[support.BOUNDS['report_bytes'],support.BOUNDS['captured_stream_bytes']]
    issue=None;code=2;started=time.monotonic()
    def pump(stream,number):
        try:
            while True:
                raw=stream.read(65536)
                if not raw:break
                remaining=limits[number]-len(buffers[number]);buffers[number].extend(raw[:remaining])
                if len(raw)>remaining:overflow.set();break
        except OSError:overflow.set()
    try:
        process=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
            creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0),start_new_session=os.name!='nt',
            env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',PYTHONNOUSERSITE='1',GIT_OPTIONAL_LOCKS='0'))
        job=WorkerJob(process.pid)
        for n,stream in enumerate((process.stdout,process.stderr)):
            thread=threading.Thread(target=pump,args=(stream,n),daemon=True);thread.start();threads.append(thread)
        process.stdin.write(b'go\n');process.stdin.flush();process.stdin.close()
        while process.poll() is None:
            if overflow.wait(.03):issue='orchestration_output_bound';break
            if time.monotonic()-started>=args.total_seconds:issue='total_deadline_exceeded';break
    except KeyboardInterrupt:issue='cancelled';code=130
    except (OSError,ValueError):issue='orchestration_unavailable'
    finally:
        if job is not None:job.close()
        if process is not None:
            if process.poll() is None:kill_worker(process)
            process.wait(timeout=3)
            for thread in threads:thread.join(timeout=3)
            for stream in (process.stdin,process.stdout,process.stderr):
                if stream is not None and not stream.closed:stream.close()
    if issue is None:
        try:
            report=json.loads(buffers[0])
            if buffers[1] or process.returncode!=report['exit_code']:raise ValueError('Unframed worker failure')
            return report
        except (ValueError,KeyError,TypeError):issue='orchestration_result_unavailable'
    report={'schema':support.SCHEMA,'version':support.VERSION,'state':'cancelled' if code==130 else 'unavailable',
            'mechanically_validated':False,'human_review':'pending','exit_code':code,'issue':issue,
            'reason':'Owned orchestration stopped; partial stage evidence retained. Any surviving ownership lock requires explicit review; no automatic takeover.',
            'stages':[{'state':'omitted','reason':'Complete per-stage outcome unavailable; inspect retained stage receipts'}],
            'output':str(args.out),'duration_seconds':round(time.monotonic()-started,6),
            'owned_process_reaped':process is not None and process.poll() is not None}
    # Only this child-created output is eligible for an interruption receipt.
    # An existing output belonging to any other invocation is never written.
    try:
        output=support.safe(args.out);root=support.safe(args.root)
        if not output.is_relative_to(root/'_local/rag/candidates'):raise ValueError('Unsafe output')
        owner=json.loads(support.reader().read(output/'owner.json',4096)[0])
        if process is not None and owner=={'pid':process.pid,'token':token}:
            support.create(output/'interrupted-receipt.json',report)
    except (OSError,ValueError):pass
    return report
