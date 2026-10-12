"""Bounded actual read-only JSON-RPC STDIO witness, using the selected SDK server."""
import json
import os
from pathlib import Path
import queue
import subprocess
import threading
import time

import activation_contract as c
from refresh_boundary import WorkerJob, kill_worker


def verify(root,binding,generation,source_count,output,seconds=18):
    started=time.monotonic();deadline=started+seconds;messages=queue.Queue(maxsize=16)
    overflow=threading.Event();wires=[];errors=bytearray();threads=[];process=None;job=None
    command=[binding['command'],'-B',str(root/'tools/rag/adapter.py'),'--root',str(root),'--index',binding['index']]
    def read_output(stream):
        total=0
        try:
            while True:
                line=stream.readline(128*1024+1)
                if not line:return
                total+=len(line)
                if len(line)>128*1024 or total>1024*1024:overflow.set();return
                wires.append(line)
                messages.put_nowait(json.loads(line))
        except (OSError,ValueError,queue.Full):overflow.set()
    def read_errors(stream):
        try:
            while True:
                chunk=stream.read(4096)
                if not chunk:return
                if len(errors)+len(chunk)>64*1024:overflow.set();return
                errors.extend(chunk)
        except (OSError,ValueError):overflow.set()
    def send(value):
        process.stdin.write(c.s.encoded(value));process.stdin.flush()
    def receive(request_id):
        while time.monotonic()<deadline:
            if overflow.is_set():c.fail('consumer_output_bound','Consumer transport invalid or exceeded bounds')
            try:value=messages.get(timeout=min(.05,max(.001,deadline-time.monotonic())))
            except queue.Empty:continue
            if value.get('id')==request_id:return value
        c.fail('consumer_deadline','Isolated consumer deadline reached')
    try:
        process=subprocess.Popen(command,cwd=root,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
            creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0),start_new_session=os.name!='nt',
            env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',PYTHONNOUSERSITE='1'))
        job=WorkerJob(process.pid)
        for function,stream in ((read_output,process.stdout),(read_errors,process.stderr)):
            t=threading.Thread(target=function,args=(stream,),daemon=True);t.start();threads.append(t)
        send({'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-11-25',
            'capabilities':{},'clientInfo':{'name':'cyrus-phase4c-isolated','version':'1'}}})
        if 'result' not in receive(1):c.fail('consumer_initialize','SDK server did not initialize')
        send({'jsonrpc':'2.0','method':'notifications/initialized'})
        values=[]
        for number,name,args in ((2,'knowledge_status',{'verify_sources':True}),
                (3,'knowledge_search',{'query':'forRanges','mode':'identifier','top_k':1})):
            send({'jsonrpc':'2.0','id':number,'method':'tools/call','params':{'name':name,'arguments':args}})
            response=receive(number);c.s.create(output/(name+'-response.json'),response)
            result=response.get('result',{});value=result.get('structuredContent',{})
            if result.get('isError') or not value.get('ok') or value.get('index_generation')!=generation:
                c.fail('consumer_acceptance_failed','Actual isolated tool response failed or identified another generation; inspect retained response')
            if not value.get('verification_checks'):c.fail('consumer_scope','Tool response did not identify its verification scope')
            values.append(value)
        status,search=values
        if not status.get('all_sources_verified') or status.get('sources_verified')!=source_count:
            c.fail('consumer_scope','Full enrolled-parent verification was incomplete')
        if not search.get('results'):c.fail('consumer_citations','Meaningful identifier search returned no evidence')
        policy=c.s.current_policy(root,c.s.reader())
        for result in search['results']:
            for citation in [result,*result.get('equivalent_sources',[])]:
                raw,_=c.s.permitted(root,root/citation['path'],policy,c.s.reader(),citation['parent_sha256'],c.s.detection.LIMITS['source_bytes'],True)
                text=raw.decode('utf-8');loc=citation['locator'];fragment=text[loc['start_offset']:loc['end_offset']]
                if citation is result and fragment!=result['original_text']:c.fail('consumer_citations','Citation text differs from current parent')
                if loc['start_line']!=text.count('\n',0,loc['start_offset'])+1: c.fail('consumer_citations','Citation start line is inconsistent')
        return {'passed':True,'generation':generation,'all_sources_verified':True,'sources':source_count,
            'checked_results':len(search['results']),'scope':'isolated actual STDIO client; existing desktop and CLI sessions unobserved',
            'duration_seconds':round(time.monotonic()-started,6)}
    finally:
        if process is not None:
            if process.stdin and not process.stdin.closed:process.stdin.close()
            try:process.wait(timeout=2)
            except subprocess.TimeoutExpired:pass
        if job is not None:job.close()
        if process is not None:
            if process.poll() is None:kill_worker(process)
            process.wait(timeout=3)
            for thread in threads:thread.join(timeout=2)
            for stream in (process.stdout,process.stderr):stream.close()
        # No stderr contents in receipts: third-party launch failures may contain
        # configuration values. Bounded protocol output contains repository data.
        c.s.create(output/'transport-summary.json',{'command':command,'pid':None if process is None else process.pid,
            'reaped':process is not None and process.poll() is not None,'wire_bytes':sum(map(len,wires)),
            'stderr_bytes':len(errors),'stderr_sha256':c.s.sha(errors),'overflow':overflow.is_set()})
