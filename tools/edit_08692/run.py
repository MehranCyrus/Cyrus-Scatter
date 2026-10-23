"""Focused queued-UI lifecycle checks. Never launches an older Max host."""
from pathlib import Path
import argparse,json,sys,time
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/'tools/edit_0869'))
from compatibility_host import launch_owned,bind_suite,run_case,verify_owned,close_owned

ASSERTIONS={'setup':['requested'],'a':['requested'],'b':['requested'],'rapid':['requested'],
            'probe':['sampled'],'verify':['owner','preserved_1','preserved_2'],
            'save':['requested'],'reopen':['saved_1','saved_2'],'wide':['wide_columns'],
            'author':['authored'],'undo':['history'],'redo':['history'],
            'map':['map'],'fresh':['requested'],'inspect_cold':['sampled'],
            'reopen_verify':['saved_1','saved_2']}

def request(folder,case):
    result=run_case(folder,HERE/'lifecycle.ms',case,ASSERTIONS[case],timeout=60,entrypoint='UILRun')
    print(json.dumps({k:result[k] for k in ('scenario_id','request_id','status')}),flush=True)
    return result

def settled(folder,verify=True):
    # These sleeps are in the driver, after the mutating request returned. Max's
    # actual Qt event loop, not a nested WinForms pump, processes the queued work.
    deadline=time.monotonic()+40
    while True:
        time.sleep(1)
        verify_owned(folder)
        request(folder,'probe')
        if (folder/'lifecycle-ready.txt').read_text()=='true':
            break
        if time.monotonic()>=deadline:
            raise TimeoutError('Selected owner did not settle; original request is not replayed')
    time.sleep(2)
    verify_owned(folder)
    return request(folder,'verify') if verify else None

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('action',choices=['launch','bind','close','exercise',*ASSERTIONS])
    p.add_argument('--folder',type=Path,required=True);p.add_argument('--payload',type=Path)
    p.add_argument('--cycles',type=int,default=10)
    a=p.parse_args();folder=a.folder.resolve()
    bindings={'ui-lifecycle':HERE/'lifecycle.ms','ui-lifecycle-driver':HERE/'run.py'}
    if a.action=='launch':
        if a.payload is None:p.error('launch requires --payload')
        result=launch_owned(folder,2027,a.payload,bindings=bindings,visible=True,interactive_startup=True,require_edit_version=True,timeout=60)
        print(json.dumps({k:result[k] for k in ('pid','run_id','artifact_id','version')}))
    elif a.action=='bind':bind_suite(folder,bindings)
    elif a.action=='close':close_owned(folder)
    elif a.action=='exercise':
        for i in range(a.cycles):
            for case in ('a','b'):
                request(folder,case);settled(folder)
        request(folder,'rapid');settled(folder)
        time.sleep(5);verify_owned(folder)
        print('PASS: independent native event-loop survival after owner switches',flush=True)
    elif a.action in ('setup','a','b','rapid','fresh'):
        request(folder,a.action);settled(folder)
    elif a.action=='reopen':
        request(folder,'reopen');settled(folder,verify=False)
        request(folder,'reopen_verify');request(folder,'verify')
    else:request(folder,a.action)
