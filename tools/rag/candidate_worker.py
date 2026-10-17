"""One owned candidate stage. Verified bytes are the only executable runtime inputs."""
import importlib.abc
import importlib.util
import json
import os
from pathlib import Path
import sqlite3
import sys
import time

import candidate_support as support


class RuntimeLoader(importlib.abc.MetaPathFinder,importlib.abc.Loader):
    def __init__(self,root,seal,policy):self.root=root;self.seal=seal;self.policy=policy
    def find_spec(self,fullname,path=None,target=None):
        if fullname+'.py' in self.seal['runtime']:
            return importlib.util.spec_from_loader(fullname,self,origin=str(self.root/'tools/rag'/(fullname+'.py')))
    def create_module(self,spec):return None
    def exec_module(self,module):
        path=self.root/'tools/rag'/(module.__name__+'.py')
        raw,_=support.permitted(self.root,path,self.policy,support.reader(),self.seal['runtime'][path.name])
        module.__file__=str(path)
        exec(compile(raw,str(path),'exec'),module.__dict__)


def install_guard(root,seal,policy,outputs,deadline,bounds):
    """Policy applies to imports and pipeline reads, including transitive imports.

    Runtime imports compile verified source bytes; no .pyc or unverified local
    module fallback. Open auditing also applies the current policy to ordinary
    source/control reads and restricts writes to this operation's fresh outputs.
    """
    busy=False;counts={'read_bytes_upper_bound':0};tool=root/'tools/rag'
    def owned(path):
        for output in outputs:
            if path==output or path.is_relative_to(output):return True
            if path.parent==output.parent and path.name.startswith('.'+output.name+'.partial-'):return True
            if any(p.parent==output.parent and p.name.startswith('.'+output.name+'.partial-') for p in path.parents):return True
        return False
    def audit(event,args):
        nonlocal busy
        if busy:return
        if event in ('socket.connect','socket.connect_ex','socket.bind','socket.getaddrinfo','socket.sendto'):
            raise support.Blocked('network_forbidden','Candidate stages have no network access')
        if event not in ('open','exec'):return
        value=args[0] if event=='open' else getattr(args[0],'co_filename',None)
        if not isinstance(value,(str,bytes)):return
        if event=='exec' and os.fsdecode(value).startswith('<'):return
        path=support.absolute(os.fsdecode(value))
        if not path.is_relative_to(root):return
        busy=True
        try:
            if time.monotonic()>=deadline:raise support.Blocked('deadline_exceeded','Stage read/execution deadline reached')
            support.safe(path,True)
            mode=args[1] if event=='open' else None
            flags=args[2] if event=='open' else 0
            writing=event=='open' and ((isinstance(mode,str) and any(c in mode for c in 'wax+')) or bool(flags & (os.O_WRONLY|os.O_RDWR|os.O_CREAT|os.O_TRUNC|os.O_APPEND)))
            if writing:
                if not owned(path):raise support.Blocked('unsafe_write','Stage attempted a write outside its fresh outputs: '+str(path))
                return
            if support.identity(support.safe(root/'tools/rag/config.toml').lstat())!=policy['stamp']:
                raise support.Blocked('policy_changed','Current policy changed before a stage read/execution')
            relative=path.relative_to(root).as_posix()
            artifact=owned(path) or any(path==support.absolute(p) or path.is_relative_to(support.absolute(p)) for p in seal['evidence_roots'])
            if not artifact and support.policy_for(relative,False,policy['config'])[0]!='full':
                raise support.Blocked('policy_blocked','Policy denies stage content access: '+relative)
            if event=='exec':
                if path.parent!=tool or path.name not in seal['runtime']:
                    raise support.Blocked('unverified_execution','Unverified repository code cannot execute: '+relative)
                raw,_=support.permitted(root,path,policy,support.reader(),seal['runtime'][path.name])
                counts['read_bytes_upper_bound']+=len(raw)
            else:
                size=path.stat().st_size
                limit=bounds['artifact_bytes'] if artifact else min(bounds['artifact_bytes'],policy['config']['max_hash_bytes'])
                if size>limit:raise support.Blocked('read_bound','Stage input exceeds its per-file byte bound: '+relative)
                counts['read_bytes_upper_bound']+=size
                if counts['read_bytes_upper_bound']>bounds['stage_read_bytes']:
                    raise support.Blocked('read_bound','Stage aggregate read bound reached')
                if path.parent==tool and path.name in seal['runtime']:
                    raw,_=support.permitted(root,path,policy,support.reader(),seal['runtime'][path.name],limit)
                    counts['read_bytes_upper_bound']+=len(raw)
                elif relative in seal['inputs']:
                    if artifact:
                        raw,_=support.reader().read(path,limit)
                        if support.sha(raw)!=seal['inputs'][relative]:raise support.Blocked('evidence_changed','Frozen historical input changed: '+relative)
                    else:raw,_=support.permitted(root,path,policy,support.reader(),seal['inputs'][relative],limit)
                    counts['read_bytes_upper_bound']+=len(raw)
            if counts['read_bytes_upper_bound']>bounds['stage_read_bytes']:
                raise support.Blocked('read_bound','Stage aggregate read bound reached')
        finally:busy=False
    sys.addaudithook(audit)
    sys.path[:]=[p for p in sys.path if support.absolute(p or os.getcwd()) not in (tool,root)]
    sys.meta_path.insert(0,RuntimeLoader(root,seal,policy))
    original=sqlite3.connect
    def connect(*args,**kwargs):
        connection=original(*args,**kwargs)
        connection.set_progress_handler(lambda:int(time.monotonic()>=deadline),1000)
        return connection
    sqlite3.connect=connect
    return counts


def dispatch(task):
    kind=task['kind'];root=Path(task['root']);args=task['args']
    if kind=='audit':
        from build_manifest import run_audit
        code,path=run_audit(root,Path(args['out']),root/'tools/rag/config.toml')
        if code:raise support.Blocked('incomplete_audit','Full audit incomplete; retained diagnostics: '+str(path))
        return {'artifact':str(path)}
    if kind=='audit_compare':
        from verify_runs import compare_runs
        result=compare_runs(Path(args['first']),Path(args['second']))
        if not result['deterministic_artifacts_identical'] or not result['observed_inputs_unchanged']:
            support.create(Path(task['result']).with_name(Path(task['result']).stem+'-differences.json'),result)
            raise support.Blocked('audit_inputs_moved','Audit observations differ; changed paths retained in stage differences')
        return result
    if kind=='build':
        from retrieval import build
        run=build(root,Path(args['corpus']),Path(args['audit']),Path(args['out']))
        return {k:run[k] for k in ('generation_id','source_count','chunk_count','database_bytes')}
    if kind=='verify':
        from status import index_status
        from retrieval import search
        index=Path(args['index']);read=support.reader()
        try:
            run,_,checks,omitted=support.detection.sealed_generation(root,index,read,support.detection.boundary.NORMALIZER_SOURCE_SHA256)
            if omitted:raise support.Blocked('incomplete_integrity','Candidate integrity derivation omitted')
            status=index_status(index,True,root)
            if not status['ok'] or not status['all_sources_verified']:
                support.create(Path(task['result']).with_name(Path(task['result']).stem+'-source-issues.json'),status)
                raise support.Blocked('stale_candidate','Candidate source verification failed; index retained')
            response=search(index,'forRanges',1,'identifier',expected_root=root)
        except Exception as exc:
            if isinstance(exc,ValueError) and not isinstance(exc,(support.Blocked,support.detection.ObservationError)):
                problem=support.Blocked('invalid_publication',str(exc));problem.completed_checks=list(read.integrity_checks)
                raise problem from exc
            exc.completed_checks=list(read.integrity_checks)
            raise
        return {'generation':run['generation_id'],'sources':run['source_count'],'chunks':run['chunk_count'],
                'sources_verified':status['sources_verified'],'integrity_checks':checks,
                'checked_search_citations':len(response['results']),'representative_response_bytes':len(support.encoded(response))}
    if kind=='evaluate':
        from evaluation import run_evaluation
        result=run_evaluation(Path(args['index']),Path(args['definition']),Path(args['out']),args['profile'])
        return {'generation':result['index_generation'],'definition_sha256':result['evaluation_sha256'],
                'profile':result['variant'],'validation':result['validation'],
                'metrics':{k:result['metrics'][k] for k in ('base','anchors')},
                'full_metrics':str(Path(args['out'])/'results.json')}
    if kind=='pair_compare':
        from verify_indexes import compare
        result=compare(*[Path(args[k]) for k in ('first','second','eval_first','eval_second')])
        if not result['passed']:raise support.Blocked('non_deterministic_candidate','Candidate logical/evaluation exports differ')
        return result
    if kind=='baseline_compare':
        read=support.reader();old_receipt,old,old_labels=support.verify_evaluation_receipt(Path(args['baseline']),args['baseline_generation'],read)
        _,new,new_labels=support.verify_evaluation_receipt(Path(args['candidate']),args['candidate_generation'],read)
        result=support.compare_baseline(old,new,old_labels,new_labels,args['sources_changed'],args.get('conclusion_review'),args.get('evidence_review'))
        result=support.review_manual_tradeoffs(result,old,new,args.get('tradeoff_review'))
        result['latency']={'baseline_median':old_receipt['median_query_seconds'],
                           'baseline_p95':old_receipt['p95_query_seconds'],
                           'candidate_median':json.loads(Path(args['candidate']).read_bytes())['median_query_seconds'],
                           'candidate_p95':json.loads(Path(args['candidate']).read_bytes())['p95_query_seconds'],
                           'scope':'Sequential retrieval only; cache/background activity uncontrolled; not answer accuracy'}
        support.create(Path(args['out']),result)
        if not result['passed'] and not result['accepted_for_manual_candidate']:
            raise support.Blocked('retrieval_regression','Unresolved question-level regression; comparison retained')
        return {'passed':True,'strict_comparison_passed':result['passed'],
                'accepted_tradeoff_count':len(result['accepted_tradeoffs']),
                'unchanged_meaningful_results':result['unchanged_meaningful_results'],
                'question_differences':len(result['question_differences']),'comparison':args['out'],'latency':result['latency']}
    raise support.Blocked('unsupported_stage','Unsupported candidate stage')


def main():
    if sys.stdin.buffer.readline(4)!=b'go\n':return 2
    payload=support.safe(Path(sys.argv[1]))
    if not payload.is_relative_to(support.TOOL.parents[1]/'_local/rag/candidates') or not payload.name.endswith('.input.json'):
        return 2
    task=json.loads(support.reader().read(payload,support.BOUNDS['definition_bytes'])[0])
    result_path=Path(task['result']);started=time.monotonic();counts={}
    try:
        root=Path(task['root']);seal=task['seal'];read=support.reader();policy=support.current_policy(root,read)
        if policy['sha256']!=seal['policy_sha256']:raise support.Blocked('policy_changed','Policy differs from the frozen preflight identity')
        for name,expected in seal['runtime'].items():support.permitted(root,root/'tools/rag'/name,policy,read,expected)
        counts=install_guard(root,seal,policy,[Path(p) for p in task['outputs']],task['deadline'],task['bounds'])
        value=dispatch(task);result={'state':'completed','value':value,'resources':counts}
    except BaseException as exc:
        causes=[];cause=exc
        while cause is not None and cause not in causes:causes.append(cause);cause=cause.__cause__
        sqlite_code=next((getattr(c,'sqlite_errorcode',None) for c in causes if isinstance(c,sqlite3.Error)),None)
        primary=sqlite_code & 0xff if sqlite_code is not None else None
        uncertainty=primary in (sqlite3.SQLITE_INTERRUPT,sqlite3.SQLITE_IOERR,sqlite3.SQLITE_CANTOPEN,
            sqlite3.SQLITE_BUSY,sqlite3.SQLITE_LOCKED,sqlite3.SQLITE_NOMEM,sqlite3.SQLITE_PERM,sqlite3.SQLITE_READONLY,sqlite3.SQLITE_FULL)
        expired=time.monotonic()>=task['deadline']
        issue='deadline_exceeded' if expired else 'sqlite_unavailable' if uncertainty else 'invalid_publication' if primary in (sqlite3.SQLITE_CORRUPT,sqlite3.SQLITE_NOTADB) else getattr(exc,'issue',getattr(exc,'outcome',type(exc).__name__))
        result={'state':'unavailable' if uncertainty or expired else 'blocked' if isinstance(exc,support.Blocked) else 'failed',
                'issue':issue,'reason':str(exc)[:2000],'resources':counts,
                'completed_checks':getattr(exc,'completed_checks',[])}
    result['duration_seconds']=round(time.monotonic()-started,6)
    # The result path is owned even when the guard has already timed out.
    # The parent persists error receipts if a deadline prevents this final write.
    support.create(result_path,result)
    return 0 if result['state']=='completed' else 2


if __name__=='__main__':raise SystemExit(main())
