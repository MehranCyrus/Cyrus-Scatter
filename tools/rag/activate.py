"""Explicit Phase 4C prepare/apply CLI. Preparation is read-only by default."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import threading
import time
import uuid
from types import SimpleNamespace

import activation_contract as c
from refresh_boundary import WorkerJob,kill_worker


def validate_root(value,fixture=False):
    root=c.s.safe(value);home=c.s.TOOL.parents[1]
    if fixture:
        if not root.is_relative_to(home/'_local/rag/test-data') or root==home:c.fail('fixture_only','Simulated approval cannot authorize the real repository or another root')
        marker=c.read_json(root/'ACTIVATION_FIXTURE.json')
        if marker!={'schema':'cyrus.activation-fixture/1','root':str(root),'warning':'TEST ONLY; NEVER PRODUCTION CONSENT'}:
            c.fail('fixture_only','Owned disposable fixture marker is missing or invalid')
    elif root!=home:c.fail('wrong_root','Use this command from the explicitly selected repository/worktree')
    return root


def confirmation(plan,plan_sha):
    return 'APPROVE '+plan['action']+' '+plan_sha+' '+plan['target_generation']


def terminal(stream):
    try:
        if stream is None or not stream.isatty():return False
        if os.name=='nt':
            import ctypes,msvcrt
            from ctypes import wintypes
            kernel=ctypes.WinDLL('kernel32',use_last_error=True);mode=wintypes.DWORD()
            query=kernel.GetConsoleMode;query.argtypes=[wintypes.HANDLE,ctypes.POINTER(wintypes.DWORD)];query.restype=wintypes.BOOL
            return bool(query(msvcrt.get_osfhandle(stream.fileno()),ctypes.byref(mode)))
        return True
    except (AttributeError,OSError,ValueError):return False


def approval(args,root):
    path=c.inside(root,args.plan,root/'_local/rag/activations');raw=c.s.reader().read(path,c.LIMIT)[0]
    plan=json.loads(raw);digest=c.s.sha(raw)
    delegated=getattr(args,'delegated_approval',None)
    if delegated:
        if args.fixture_approval:c.fail('approval_mismatch','Choose one explicit authorization mechanism')
        record_path=c.inside(root,delegated,root/'_local/rag/activations')
        record_raw=c.s.reader().read(record_path,64*1024)[0];record=json.loads(record_raw)
        expected={'schema':'cyrus.delegated-activation/1','root':str(root),'plan_sha256':digest,
            'target_generation':plan['target_generation'],'action':plan['action'],
            'review_packet_sha256':plan['review_packet_sha256'],'semantic_review':'agent; human review not performed'}
        if (any(record.get(k)!=v for k,v in expected.items()) or set(record)!=set(expected)|{'user_instruction','decision_reason'}
                or any(not isinstance(record[k],str) or not 1<=len(record[k].strip())<=4096 for k in ('user_instruction','decision_reason'))):
            c.fail('approval_mismatch','Delegated authorization must bind the exact plan/root/action/target and reviewed packet')
        return {'kind':'delegated_user_authorization','plan_sha256':digest,'root':str(root),
            'target_generation':plan['target_generation'],'action':plan['action'],
            'record':str(record_path),'record_sha256':c.s.sha(record_raw),
            'semantic_review':'agent; human review not performed',
            'scope':'Recorded explicit user delegation, not a claim of interactive human confirmation or identity authentication'}
    if args.fixture_approval:
        validate_root(root,True)
        simulated=c.read_json(c.inside(root,args.fixture_approval))
        expected={'schema':'cyrus.activation-fixture-approval/1','root':str(root),'plan_sha256':digest,
            'target_generation':plan['target_generation'],'action':plan['action'],'warning':'TEST ONLY; NEVER PRODUCTION CONSENT'}
        if simulated!=expected:c.fail('approval_mismatch','Simulated fixture approval does not match this exact action/root/plan/target')
        return {'kind':'fixture_simulation','plan_sha256':digest,'root':str(root),'target_generation':plan['target_generation'],'action':plan['action']}
    if not terminal(sys.stdin):c.fail('human_confirmation_required','Real apply requires an interactive human terminal; JSON records and piped approval are not accepted')
    print('Review packet: '+plan['review_packet']+' (SHA256 '+plan['review_packet_sha256']+')',file=sys.stderr)
    print('This confirms semantic acceptance of that packet and authorizes only this project index binding change.',file=sys.stderr)
    print('Root: '+str(root)+'\nCurrent: '+plan['previous_index']+'\nTarget: '+plan['target_index'],file=sys.stderr)
    print('Type exactly: '+confirmation(plan,digest),file=sys.stderr)
    if input()!=confirmation(plan,digest):c.fail('approval_mismatch','Confirmation does not match the exact action/plan/generation')
    return {'kind':'interactive_human_confirmation','plan_sha256':digest,'root':str(root),
            'target_generation':plan['target_generation'],'action':plan['action'],
            'scope':'Operator terminal confirmation; no authentication platform or proof of personal identity'}


def execute(request,token):
    from activation_verify import readiness,check_plan,dependencies,current_git
    root=validate_root(request['root'],request.get('fixture',False))
    output=c.s.fresh(Path(request['out']),root/'_local/rag/activations')
    if not re.fullmatch('[a-z0-9][a-z0-9-]{2,79}',output.name):c.fail('invalid_operation','Fresh 3..80 lowercase operation identity required')
    owner=c.Ownership(root,token);owned=False;replaced=False;retain=False
    report={'schema':'cyrus.activation-receipt/1','operation':request['operation'],'root':str(root),'output':str(output),
        'state':'configuration_unchanged','exit_code':2,'existing_consumers':'unobserved','started_utc':c.s.now()}
    expected_after=None;before=None
    try:
        owner.acquire();output.mkdir(parents=True);owned=True
        c.s.create(output/'owner.json',{'pid':os.getpid(),'token':token})
        c.s.create(output/'request.json',{k:v for k,v in request.items() if k!='approval'})
        if request['operation']=='prepare':
            plan,snapshot=readiness(root,c.inside(root,request['target'],root/'_local/rag/indexes'),Path(request['evidence']),request['action'],Path(request['review']),output)
            binding,_,_=c.configuration(root)
            if binding!=plan['configuration']:c.fail('configuration_changed','Configuration moved during plan preparation')
            snapshot.check();c.s.publish(output/'plan.json',plan)
            report.update(state='prepared',exit_code=0,plan=str(output/'plan.json'),plan_sha256=c.fingerprint(output/'plan.json')['sha256'],
                target_generation=plan['target_generation'],mechanically_ready=True,human_approval='pending',
                no_binding_change=plan['previous_index']==plan['target_index'])
        else:
            path=c.inside(root,request['plan'],root/'_local/rag/activations')
            plan_raw,plan_stamp=c.s.reader().read(path,c.LIMIT);plan=json.loads(plan_raw)
            consent=request.get('approval',{})
            if consent.get('plan_sha256')!=c.s.sha(plan_raw) or consent.get('root')!=str(root) or consent.get('target_generation')!=plan['target_generation'] or consent.get('action')!=plan['action']:
                c.fail('approval_mismatch','Approval does not bind the exact current plan/root/action/target')
            if consent.get('kind') not in ('interactive_human_confirmation','fixture_simulation','delegated_user_authorization') or consent['kind']=='fixture_simulation' and not request.get('fixture'):
                c.fail('human_confirmation_required','Apply has no explicit operator confirmation')
            if plan['previous_index']==plan['target_index']:c.fail('no_binding_change','Selected target already bound; no switch performed')
            # Optional recovery guard is an exact post-switch witness, never a
            # request to restore raw backup bytes over arbitrary later edits.
            if request.get('recover_from'):
                previous=c.inside(root,request['recover_from'],root/'_local/rag/activations')
                journal=c.read_json(previous/'journal-replaced.json')
                current,_,_=c.configuration(root)
                if current['fingerprint']!=journal['fingerprint'] or current['index']!=journal['index']:
                    c.fail('recovery_blocked','Later configuration edit or uncertain replacement; preserve it and prepare a separately reviewed plan')
            snapshot=check_plan(root,plan,output)
            if consent['kind']=='delegated_user_authorization':
                snapshot.add(c.inside(root,consent['record'],root/'_local/rag/activations'),True,expected=consent['record_sha256'])
            snapshot.add(path,True,expected=consent['plan_sha256'])
            if snapshot.files[str(path)]['identity']!=list(plan_stamp):c.fail('changed_input','Approved plan identity changed during verification')
            before,raw,_=c.configuration(root);after=c.replacement(root,before,raw,Path(plan['target_index']));expected_after=c.s.sha(after)
            c.s.create(output/'approval-witness.json',consent)
            report.update(plan=str(path),plan_sha256=consent['plan_sha256'],action=plan['action'],
                previous_index=plan['previous_index'],target_index=plan['target_index'],target_generation=plan['target_generation'])
            def checkpoint(stage):
                nonlocal replaced
                if stage=='after_replace':replaced=True
                # Fixture-only controlled crash witnesses; no production switch
                # or unbounded sleeping can be enabled through these test flags.
                point=request.get('fixture_fault') if request.get('fixture') else None
                if point==stage:os._exit(91)
                if stage=='before_replace':
                    snapshot.check()
                    if current_git(root)!=plan['git']:c.fail('git_changed','Worktree changed immediately before replacement')
            actual=c.publish_config(root,before,raw,after,output,owner,checkpoint);replaced=True
            report.update(state='configuration_switched_consumer_pending',configuration_after=actual)
            # Config is now a different legitimate input. Recheck all other inputs
            # and actual selected binding; this is not an unchanged audit claim.
            snapshot.files.pop(str(root/'.codex/config.toml'),None);snapshot.check()
            from activation_client import verify
            if request.get('fixture_fault')=='consumer_failure' and request.get('fixture'):
                c.fail('consumer_acceptance_failed','Fixture acceptance failure after real atomic replacement')
            consumer=verify(root,actual,plan['target_generation'],plan['sources'],output)
            final,_,_=c.configuration(root)
            if final!=actual:c.fail('post_write_conflict','Configuration changed during consumer verification; preserve later edit')
            snapshot.check()
            if dependencies(actual)!=plan['dependencies']:c.fail('dependencies_changed','Pinned environment changed during consumer acceptance')
            if current_git(root)!=plan['git']:c.fail('git_changed','Worktree changed during consumer acceptance')
            report.update(state='previous_binding_restored' if plan['action']=='rollback' else 'configuration_switched_verified',
                exit_code=0,isolated_consumer=consumer,previous_binding_currently_usable=plan['action']=='rollback')
    except KeyboardInterrupt:
        report.update(issue='cancelled',exit_code=130);retain=True
    except Exception as exc:
        # Do not log exception strings: a TOML parser or SDK failure can include
        # sensitive values. Issue, phase and hashed observations are actionable.
        report.update(issue=getattr(exc,'issue',getattr(exc,'outcome',type(exc).__name__)),exit_code=2)
    finally:
        if owned and request['operation']=='apply' and expected_after is not None:
            try:
                actual,_,_=c.configuration(root)
                changed=actual['fingerprint']!=before['fingerprint'] or replaced
                if changed:
                    if report['exit_code']!=0:report['state']='configuration_switched_consumer_pending' if actual['fingerprint']['sha256']==expected_after else 'recovery_blocked'
                    report['configuration_observed_after']=actual;replaced=True
                elif report['exit_code']!=0:report['state']='configuration_unchanged'
            except Exception:
                report['state']='recovery_blocked';retain=True
        if owner.stamp is not None and not retain:
            try:owner.release()
            except Exception:report.update(state='recovery_blocked',issue='ownership_uncertain',exit_code=2)
        report['ended_utc']=c.s.now();report['configuration_may_have_changed']=replaced or retain
        if owned:c.s.publish(output/'receipt.json',report)
    return report


def guarded(request,seconds):
    process=None;job=None;buffers=[bytearray(),bytearray()];threads=[];overflow=threading.Event();started=time.monotonic();token=uuid.uuid4().hex;issue=None
    def pump(stream,n):
        try:
            while True:
                raw=stream.read1(4096)
                if not raw:return
                remaining=1024*1024-len(buffers[n]);buffers[n].extend(raw[:remaining])
                if n==1 and request['operation']=='apply' and not request.get('fixture'):
                    sys.stderr.buffer.write(raw[:remaining]);sys.stderr.buffer.flush()
                if len(raw)>remaining:overflow.set();return
        except (OSError,ValueError):overflow.set()
    gate=Path(request['root'])/'_local/rag/activations'/('.start-'+token+'.json');gate_stamp=None
    try:
        c.s.safe(gate,True);gate.parent.mkdir(parents=True,exist_ok=True)
        process=subprocess.Popen([sys.executable,'-B',str(c.s.TOOL/'activate.py'),'--_worker',str(gate)],
            stdin=None if request['operation']=='apply' and not request.get('fixture') and not request.get('delegated_approval') else subprocess.DEVNULL,
            stdout=subprocess.PIPE,stderr=subprocess.PIPE,
            creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0),start_new_session=os.name!='nt',
            env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',PYTHONNOUSERSITE='1',GIT_OPTIONAL_LOCKS='0'))
        job=WorkerJob(process.pid)
        for n,stream in enumerate((process.stdout,process.stderr)):
            t=threading.Thread(target=pump,args=(stream,n),daemon=True);t.start();threads.append(t)
        # Start gate is created only after process-tree ownership exists. It
        # carries no consent. The mutation worker obtains consent itself.
        c.private_copy(gate,c.s.encoded({'request':request,'token':token}));gate_stamp=c.s.identity(gate.lstat())
        while process.poll() is None:
            if overflow.wait(.03):issue='output_bound';break
            if time.monotonic()-started>=seconds:issue='deadline_exceeded';break
    except KeyboardInterrupt:issue='cancelled'
    except (OSError,ValueError):issue='worker_unavailable'
    finally:
        if job is not None:job.close()
        if process is not None:
            if process.poll() is None:kill_worker(process)
            process.wait(timeout=3)
            for t in threads:t.join(timeout=2)
            for stream in (process.stdin,process.stdout,process.stderr):
                if stream is not None and not stream.closed:stream.close()
        if gate_stamp is not None:
            try:
                if c.s.identity(c.s.safe(gate).lstat())==gate_stamp:gate.unlink()
            except (OSError,ValueError):pass
    if issue is None:
        try:
            report=json.loads(buffers[0])
            if report['exit_code']!=process.returncode:raise ValueError()
            return report
        except (ValueError,KeyError,TypeError):issue='worker_interrupted'
    report={'schema':'cyrus.activation-receipt/1','state':'interrupted_configuration_unknown',
        'issue':issue,'exit_code':130 if issue=='cancelled' else 2,'configuration_may_have_changed':request['operation']=='apply',
        'owned_process_reaped':process is not None and process.poll() is not None,
        'recovery':'Inspect actual registration and journals; no automatic lock takeover or configuration restoration'}
    try:
        output=c.s.safe(request['out']);root=c.s.safe(request['root'])
        c.inside(root,output,root/'_local/rag/activations')
        if c.read_json(output/'owner.json')=={'pid':process.pid,'token':token}:c.s.create(output/'interrupted-receipt.json',report)
    except (OSError,ValueError):pass
    return report


def main(argv=None):
    if argv is None:argv=sys.argv[1:]
    if len(argv)==2 and argv[0]=='--_worker':
        try:
            gate=c.s.safe(argv[1],True)
            if not re.fullmatch(r'\.start-[0-9a-f]{32}\.json',gate.name) or not gate.is_relative_to(c.s.TOOL.parents[1]/'_local/rag'):
                c.fail('start_gate','Invalid owned start gate')
            deadline=time.monotonic()+5
            while not gate.exists():
                if time.monotonic()>=deadline:c.fail('start_gate','Owned start gate unavailable')
                time.sleep(.02)
            value=c.read_json(gate,64*1024);request=value['request']
            root=validate_root(request['root'],request.get('fixture',False))
            if gate!=root/'_local/rag/activations'/('.start-'+value['token']+'.json'):c.fail('start_gate','Start gate root/token mismatch')
            request.pop('approval',None)
            if request['operation']=='apply':request['approval']=approval(SimpleNamespace(**request),root)
            report=execute(request,value['token'])
        except Exception as exc:report={'state':'configuration_unchanged','issue':getattr(exc,'issue','worker_failed'),'exit_code':2}
        sys.stdout.buffer.write(c.s.encoded(report));return report['exit_code']
    parser=argparse.ArgumentParser(description=__doc__);subs=parser.add_subparsers(dest='operation',required=True)
    for name in ('prepare','apply'):
        p=subs.add_parser(name);p.add_argument('--root',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
        p.add_argument('--seconds',type=float,default=90);p.add_argument('--json',action='store_true')
        p.add_argument('--fixture',action='store_true',help=argparse.SUPPRESS)
        p.add_argument('--fixture-fault',choices=('before_replace','after_replace','after_confirmation','consumer_failure'),help=argparse.SUPPRESS)
        if name=='prepare':
            p.add_argument('--action',choices=('activate','rollback'),default='activate');p.add_argument('--target',type=Path,required=True)
            p.add_argument('--evidence',type=Path,required=True);p.add_argument('--review',type=Path,required=True)
        else:
            p.add_argument('--plan',type=Path,required=True);p.add_argument('--recover-from',type=Path)
            p.add_argument('--fixture-approval',type=Path,help=argparse.SUPPRESS)
            p.add_argument('--delegated-approval',type=Path,help='exact-plan record of an explicit user delegation; does not assert human semantic review')
    args=parser.parse_args(argv)
    try:
        root=validate_root(args.root,args.fixture)
        if not 1<=args.seconds<=180:c.fail('invalid_deadline','Use a finite 1..180 second wall deadline')
        request={k:str(v) if isinstance(v,Path) else v for k,v in vars(args).items()}
        if args.operation=='apply' and not args.fixture and not args.delegated_approval and not terminal(sys.stdin):
            c.fail('human_confirmation_required','Real apply requires an interactive terminal; supplied JSON cannot authorize it')
        report=guarded(request,args.seconds)
    except KeyboardInterrupt:report={'state':'configuration_unchanged','issue':'cancelled','exit_code':130}
    except Exception as exc:report={'state':'configuration_unchanged','issue':getattr(exc,'issue',getattr(exc,'outcome',type(exc).__name__)),'exit_code':2}
    if args.json:sys.stdout.buffer.write(c.s.encoded(report))
    else:
        print('Activation workflow: '+report['state'])
        if report.get('issue'):print('Issue: '+report['issue'])
        if report.get('plan'):print('Plan: '+report['plan'])
    return report['exit_code']


if __name__=='__main__':raise SystemExit(main())
