"""Explicit Phase 4B preparation and mechanical validation; never activation."""
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

import candidate_support as support
from refresh_boundary import WorkerJob, kill_worker


class Parser(argparse.ArgumentParser):
    def error(self,message):raise support.Blocked('invalid_arguments',message)


def preflight(args):
    root=support.safe(args.root);index=support.safe(args.baseline_index)
    if root!=support.TOOL.parents[1]:raise support.Blocked('wrong_root','Use the coordinator in the explicitly selected repository/worktree')
    if not re.fullmatch('[a-z0-9][a-z0-9-]{2,79}',args.run_id):raise support.Blocked('invalid_run_id','Use a unique 3..80 character lowercase alphanumeric/hyphen run identity')
    if not 1<=args.stage_seconds<=support.BOUNDS['max_stage_seconds'] or not 1<=args.total_seconds<=support.BOUNDS['max_total_seconds']:
        raise support.Blocked('invalid_deadlines','Requested deadlines exceed the documented bounds')
    if not 1<=len(args.evaluation)<=support.BOUNDS['evaluations'] or len(args.baseline_evaluation)!=2*len(args.evaluation):
        raise support.Blocked('invalid_evaluations','Explicit 1..4 evaluation definitions and two historical profile receipts per definition are required')
    output=support.fresh(args.out,root/'_local/rag/candidates')
    if output.name!=args.run_id:raise support.Blocked('invalid_output','Fresh output directory name must equal --run-id')
    if not index.is_relative_to(root/'_local/rag/indexes'):raise support.Blocked('wrong_root','Baseline must be an explicit published index in this root')
    read=support.reader();policy=support.current_policy(root,read)
    run,logical,checks,omitted=support.detection.sealed_generation(root,index,read)
    if set(logical['identities']['runtime_sha256'])!=set(support.RUNTIME_NAMES):
        raise support.Blocked('unsupported_runtime','Baseline producer runtime scope is unsupported; no helper imported')
    inputs={};stamps={}
    def freeze(path,limit=support.BOUNDS['definition_bytes'],parent=False):
        path=support.safe(path);raw,stamp=support.permitted(root,path,policy,read,limit=limit,parent=parent)
        relative=path.relative_to(root).as_posix();inputs[relative]=support.sha(raw);stamps[relative]=list(stamp)
        return path,raw
    review=json.loads(freeze(args.review)[1]) if args.review else None
    runtime=support.review_runtime({**logical['identities']['runtime_sha256'],**support.EXTRAS},review)
    observations=[]
    for name,expected in sorted(runtime.items()):
        row=support.detection.observe(root,'tools/rag/'+name,expected,policy,read,support.BOUNDS['definition_bytes'])
        observations.append(row)
    blockers=[row for row in observations if row['outcome']!='unchanged']
    if blockers:
        exc=support.Blocked('required_runtime_unavailable','Required permitted runtime identities do not match the baseline/approved pipeline; no helper imported')
        exc.observations=observations;raise exc
    corpus,raw=freeze(args.corpus);candidate=json.loads(raw)
    active=Path(logical['identities']['corpus_path']);freeze(active)
    if support.sha(raw)!=logical['identities']['corpus_sha256']:
        proposal=(review or {}).get('corpus',{})
        if (proposal.get('old_sha256')!=logical['identities']['corpus_sha256'] or proposal.get('new_sha256')!=support.sha(raw)
                or not proposal.get('reason')):raise support.Blocked('semantic_review_pending','A separate candidate definition needs an explicit corpus review record; active corpus is never repaired')
    changes=support.review_definition(logical,candidate,review)
    parents=[];baseline_sources={s['path']:s for s in logical['sources']}
    for source in candidate['sources']:
        path,body=freeze(root/source['path'],support.detection.LIMITS['source_bytes'],True)
        if support.sha(body)!=source['sha256']:raise support.Blocked('candidate_source_mismatch','Candidate definition has not been reviewed against current full-parent bytes: '+source['path'])
        previous=baseline_sources.get(source['path'],{}).get('sha256')
        parents.append({'path':source['path'],'baseline_sha256':previous,
                        'candidate_sha256':source['sha256'],'baseline_outcome':'newly_enrolled' if previous is None else 'unchanged' if source['sha256']==previous else 'stale'})
    definitions=[]
    for definition in args.evaluation:
        path,body=freeze(definition);definitions.append({'path':str(path),'sha256':support.sha(body)})
    if len({d['sha256'] for d in definitions})!=len(definitions):raise support.Blocked('duplicate_evaluation','Each definition must be distinct')
    historical=[];evidence_roots=[str(index)];seen=set()
    for receipt_path in args.baseline_evaluation:
        path=support.safe(receipt_path)
        if path.name!='run.json' or not path.is_relative_to(root/'_local/rag/evaluations'):
            raise support.Blocked('invalid_baseline_evaluation','Select an explicit historical evaluation run.json in this root')
        receipt,results,labels=support.verify_evaluation_receipt(path,run['generation_id'],read)
        if results['configuration_identities']!=logical['identities']:
            raise support.Blocked('invalid_baseline_evaluation','Historical evaluation configuration does not match baseline publication')
        profile=results['variant']
        if profile not in ('plain','terminology'):raise support.Blocked('invalid_profile','Unsupported historical profile')
        matches=[d for d in definitions if d['sha256']==receipt['evaluation_sha256']]
        if not matches:
            proposals=(review or {}).get('evaluations',[])
            match=[p for p in proposals if p.get('old_sha256')==receipt['evaluation_sha256'] and p.get('reason')]
            matches=[d for d in definitions if any(p.get('new_sha256')==d['sha256'] for p in match)]
        if len(matches)!=1:raise support.Blocked('evaluation_review_pending','Historical receipt has no unique unchanged or separately reviewed candidate definition')
        definition=matches[0];key=(definition['path'],profile)
        if key in seen:raise support.Blocked('duplicate_baseline_evaluation','Ambiguous historical evaluation/profile receipt')
        seen.add(key)
        current=json.loads(support.permitted(root,Path(definition['path']),policy,read,definition['sha256'])[0])
        if receipt['evaluation_sha256']==definition['sha256'] and current!=labels:
            raise support.Blocked('invalid_baseline_evaluation','Unchanged definition disagrees with historical label snapshot')
        # Check preserved question semantics before any expensive audit/build.
        conclusions=[entry for entry in (review or {}).get('reference_conclusions',[])
                     if entry.get('old_evaluation_sha256')==receipt['evaluation_sha256']]
        alternatives=[entry for entry in (review or {}).get('evidence_alternatives',[])
                      if entry.get('old_evaluation_sha256')==receipt['evaluation_sha256']]
        support.compare_baseline(results,results,labels,current,bool(changes),conclusions,alternatives)
        tradeoffs=[entry for entry in (review or {}).get('retrieval_tradeoffs',[])
                   if entry.get('old_evaluation_sha256')==receipt['evaluation_sha256'] and entry.get('profile')==profile]
        if len(tradeoffs)>1:raise support.Blocked('invalid_tradeoff_review','Ambiguous manual retrieval review')
        for file in ('run.json','results.json','labels-snapshot.json'):
            target=path.parent/file;data,stamp=read.read(target,support.BOUNDS['artifact_bytes'])
            inputs[target.relative_to(root).as_posix()]=support.sha(data);stamps[target.relative_to(root).as_posix()]=list(stamp)
        evidence_roots.append(str(path.parent))
        historical.append({'definition':definition['path'],'profile':profile,'receipt':str(path),
                           'evaluation_sha256':receipt['evaluation_sha256'],'results_sha256':receipt['results_sha256'],
                           'conclusion_review':conclusions,'evidence_review':alternatives,'tradeoff_review':tradeoffs[0] if tradeoffs else None})
    registration=root/'.codex/config.toml'
    if registration.exists():freeze(registration)
    own={name:support.sha(read.read(support.TOOL/name,support.BOUNDS['definition_bytes'])[0]) for name in support.OWN}
    # Root identity and compact provenance are independent of source freshness.
    provenance=support.detection.git_provenance(root,logical['identities']['git_state'],read)
    if provenance['state']!='observed':raise support.Blocked('git_unavailable','Explicit repository/worktree provenance unavailable')
    seal={'runtime':runtime,'runtime_stamps':{name:list(support.identity(support.safe(root/'tools/rag'/name).lstat())) for name in runtime},
          'inputs':inputs,'stamps':stamps,'policy_sha256':policy['sha256'],
          'evidence_roots':evidence_roots,'implementation_sha256':own,
          'baseline_generation':run['generation_id'],'baseline_artifact_sha256':run['artifact_sha256'],
          'baseline_index':str(index),'baseline_run_sha256':support.sha(read.read(index/'run.json',support.BOUNDS['artifact_bytes'])[0]),
          'git':provenance['current']}
    return root,output,seal,{'generation':run['generation_id'],'source_count':run['source_count'],'chunk_count':run['chunk_count'],
         'sealed_integrity_checks':checks,'optional_checks_omitted':omitted,'runtime_observations':observations,
         'parents':parents,'source_update_needed':bool(changes),'definition_changes':changes,
         'candidate_corpus':str(corpus),'candidate_corpus_sha256':support.sha(raw),'definitions':definitions,
         'historical_evaluations':historical,'provenance':provenance,'running_consumer_generation':'unknown'}


def checkpoint(root,seal):
    read=support.reader();policy=support.current_policy(root,read)
    if policy['sha256']!=seal['policy_sha256']:raise support.Blocked('policy_changed','Policy changed at stage boundary')
    for name,expected in seal['runtime'].items():
        _,stamp=support.permitted(root,root/'tools/rag'/name,policy,read,expected)
        if list(stamp)!=seal['runtime_stamps'][name]:raise support.Blocked('runtime_unstable','Runtime identity changed across stages: '+name)
    for relative,expected in seal['inputs'].items():
        path=root/relative
        if any(path.is_relative_to(Path(p)) for p in seal['evidence_roots']):
            raw,stamp=read.read(path,support.BOUNDS['artifact_bytes'])
            if support.sha(raw)!=expected:raise support.Blocked('evidence_changed','Historical evidence changed during preparation: '+relative)
        else:
            raw,stamp=support.permitted(root,path,policy,read,expected,support.BOUNDS['artifact_bytes'])
        if list(stamp)!=seal['stamps'][relative]:raise support.Blocked('input_unstable','Input identity changed across stages, including restored bytes: '+relative)
    for name,expected in seal['implementation_sha256'].items():
        if support.sha(read.read(support.TOOL/name,support.BOUNDS['definition_bytes'])[0])!=expected:
            raise support.Blocked('implementation_changed','Coordinator source changed during preparation')
    baseline=Path(seal['baseline_index'])
    for name,expected in {**seal['baseline_artifact_sha256'],'run.json':seal['baseline_run_sha256']}.items():
        if support.sha(read.read(baseline/name,support.BOUNDS['artifact_bytes'])[0])!=expected:
            raise support.Blocked('baseline_changed','Baseline publication changed; no repair attempted')
    provenance=support.detection.git_provenance(root,{},read)
    if provenance.get('current')!=seal['git']:raise support.Blocked('git_changed','Branch/HEAD/staging identity changed during preparation')


def plan(root,output,run_id,observation):
    audits=[root/'_local/rag/out'/f'{run_id}-audit-{n:02}' for n in (1,2)]
    indexes=[root/'_local/rag/indexes'/f'{run_id}-candidate-{n:02}' for n in (1,2)]
    tasks=[];destinations=[output,*audits,*indexes]
    def add(kind,args):tasks.append({'name':f'{len(tasks)+1:02}-{kind}','kind':kind,'args':args})
    for audit in audits:add('audit',{'out':str(audit)})
    add('audit_compare',{'first':str(audits[0]),'second':str(audits[1])})
    for index in indexes:
        add('build',{'out':str(index),'corpus':observation['candidate_corpus'],'audit':str(audits[0])})
        add('verify',{'index':str(index)})
    for number,definition in enumerate(observation['definitions'],1):
        for profile in ('plain','terminology'):
            evaluations=[root/'_local/rag/evaluations'/f'{run_id}-d{number}-{profile}-{n:02}' for n in (1,2)]
            destinations.extend(evaluations)
            for index,destination in zip(indexes,evaluations):
                add('evaluate',{'index':str(index),'definition':definition['path'],'out':str(destination),'profile':profile})
            add('pair_compare',dict(zip(('first','second','eval_first','eval_second'),map(str,[*indexes,*evaluations]))))
            baseline=next(h for h in observation['historical_evaluations'] if h['definition']==definition['path'] and h['profile']==profile)
            add('baseline_compare',{'baseline':baseline['receipt'],'candidate':str(evaluations[0]/'run.json'),
                'baseline_generation':observation['generation'],'candidate_generation':None,
                'conclusion_review':baseline.get('conclusion_review',[]),
                'evidence_review':baseline.get('evidence_review',[]),
                'tradeoff_review':baseline.get('tradeoff_review'),
                'sources_changed':observation['source_update_needed'],'out':str(output/'comparisons'/f'd{number}-{profile}.json')})
    # Reverify both after all measurement work, not only immediately after build.
    for index in indexes:add('verify',{'index':str(index)})
    return tasks,destinations


def stage_process(command,task,stage_dir,seconds):
    name=task['name'];process=None;job=None;threads=[];overflow=threading.Event();errors=[];counts={}
    started=time.monotonic();exit_code=None;issue=None
    def pump(stream,path):
        count=0
        try:
            with path.open('xb') as handle:
                while True:
                    raw=stream.read(65536)
                    if not raw:break
                    remaining=support.BOUNDS['captured_stream_bytes']-count
                    handle.write(raw[:max(0,remaining)]);count+=len(raw)
                    if count>support.BOUNDS['captured_stream_bytes']:overflow.set();break
        except Exception as exc:errors.append(type(exc).__name__);overflow.set()
        counts[path.name]=min(count,support.BOUNDS['captured_stream_bytes'])
    try:
        process=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
            cwd=task['root'],env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',PYTHONNOUSERSITE='1',GIT_OPTIONAL_LOCKS='0'),
            creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0),start_new_session=os.name!='nt')
        job=WorkerJob(process.pid)
        for stream,suffix in ((process.stdout,'stdout'),(process.stderr,'stderr')):
            thread=threading.Thread(target=pump,args=(stream,stage_dir/(name+'.'+suffix+'.log')),daemon=True);thread.start();threads.append(thread)
        process.stdin.write(b'go\n');process.stdin.flush();process.stdin.close()
        while process.poll() is None:
            if overflow.wait(.03):issue='captured_output_bound';break
            if time.monotonic()-started>=seconds:issue='stage_deadline_exceeded';break
        exit_code=process.poll()
    except KeyboardInterrupt:issue='cancelled'
    except OSError:issue='owned_worker_unavailable'
    finally:
        if job is not None:job.close()
        if process is not None:
            if process.poll() is None:kill_worker(process)
            process.wait(timeout=3)
            for thread in threads:thread.join(timeout=3)
            for stream in (process.stdin,process.stdout,process.stderr):
                if stream is not None and not stream.closed:stream.close()
    receipt={'command':command,'exit_code':exit_code,'wall_seconds':round(time.monotonic()-started,6),
             'issue':issue,'captured_bytes':counts,'capture_errors':errors,'owned_worker_reaped':process is not None and process.poll() is not None}
    support.create(stage_dir/(name+'.command.json'),receipt)
    if issue=='cancelled':raise KeyboardInterrupt
    if issue:raise support.Blocked(issue,'Owned stage stopped; logs and partial artifacts retained')
    if errors:raise support.Blocked('capture_failure','Cannot persist bounded stage diagnostics')
    return receipt


def execute(args):
    report={'schema':support.SCHEMA,'version':support.VERSION,'run_id':getattr(args,'run_id',None),
        'mechanically_validated':False,'state':'blocked','human_review':'pending',
        'activation':'not_implemented','automatic_refresh':'not_implemented','stages':[],
        'started_utc':support.now(),'observation_scope':'Individually checked interval; no atomic filesystem snapshot',
        'bounds':dict(support.BOUNDS),'exit_code':2}
    started=time.monotonic();ownership=None;output=None;seal=None;root=None;owned_output=False
    try:
        root,output,seal,observation=preflight(args)
        tasks,destinations=plan(root,output,args.run_id,observation)
        for path in destinations:
            parent=root/'_local/rag'/('candidates' if path==output else 'out' if path in [Path(t['args']['out']) for t in tasks if t['kind']=='audit'] else 'indexes' if 'indexes' in path.parts else 'evaluations')
            support.fresh(path,parent)
        ownership=support.Ownership(root,uuid.uuid4().hex);ownership.acquire()
        output.mkdir(parents=True,exist_ok=False)
        owned_output=True
        (output/'stages').mkdir();(output/'comparisons').mkdir()
        support.create(output/'owner.json',{'pid':os.getpid(),'token':getattr(args,'_token',uuid.uuid4().hex)})
        support.create(output/'input-inventory.json',seal)
        report.update(state='preparing',output=str(output),preflight=observation,implementation_sha256=seal['implementation_sha256'],
                      artifacts={'indexes':[str(p) for p in destinations if p.parent==root/'_local/rag/indexes'],
                                 'audits':[str(p) for p in destinations if p.parent==root/'_local/rag/out']})
        report['stages']=[{'name':t['name'],'kind':t['kind'],'state':'omitted','reason':'Not reached'} for t in tasks]
        total_read=0
        for task,row in zip(tasks,report['stages']):
            checkpoint(root,seal)
            remaining=args.total_seconds-(time.monotonic()-started)
            if remaining<=0:raise support.Blocked('total_deadline_exceeded','Total operation deadline reached')
            duration=min(args.stage_seconds,remaining)
            task.update(root=str(root),seal=seal,outputs=list(map(str,destinations)),bounds=support.BOUNDS,
                        result=str(output/'stages'/(task['name']+'.result.json')),deadline=time.monotonic()+duration)
            if task['kind']=='baseline_compare':
                task['args']['candidate_generation']=json.loads(support.reader().read(Path(task['args']['candidate']),support.BOUNDS['definition_bytes'])[0])['index_generation']
            input_path=output/'stages'/(task['name']+'.input.json');support.create(input_path,task)
            row.update(state='running');row.pop('reason',None)
            receipt=stage_process([sys.executable,'-B',str(support.TOOL/'candidate_worker.py'),str(input_path)],task,output/'stages',duration)
            if not Path(task['result']).exists():raise support.Blocked('worker_result_unavailable','Stage did not return a framed result; see retained command/stdout/stderr receipts')
            result=json.loads(support.reader().read(Path(task['result']),support.BOUNDS['artifact_bytes'])[0])
            row.update(result);row['command_receipt']=str(output/'stages'/(task['name']+'.command.json'))
            if result['state']!='completed':raise support.Blocked(result.get('issue','stage_failed'),result.get('reason','Stage failed'))
            if receipt['exit_code']!=0:raise support.Blocked('worker_exit','Stage exit and result disagree')
            total_read+=result.get('resources',{}).get('read_bytes_upper_bound',0)
            if total_read>support.BOUNDS['total_read_bytes']:raise support.Blocked('read_bound','Aggregate operation read bound reached')
            checkpoint(root,seal)
        checkpoint(root,seal)
        report.update(state='mechanically_validated',mechanically_validated=True,exit_code=0,
                      source_update_needed=observation['source_update_needed'],
                      rehearsal=not observation['source_update_needed'],read_bytes_upper_bound=total_read)
    except KeyboardInterrupt:
        report.update(state='cancelled',issue='cancelled',reason='Owned operation cancelled; partial artifacts retained',exit_code=130)
    except Exception as exc:
        issue=getattr(exc,'issue',getattr(exc,'outcome',type(exc).__name__))
        report.update(state='draft' if issue in ('semantic_review_pending','evaluation_review_pending','retrieval_regression','evaluation_semantics_changed') else 'blocked',
                      issue=issue,reason=str(exc)[:2000],exit_code=1 if issue in ('semantic_review_pending','evaluation_review_pending','retrieval_regression','evaluation_semantics_changed') else 2)
        if hasattr(exc,'observations'):report['runtime_observations']=exc.observations
    finally:
        if ownership is not None:
            try:ownership.release()
            except Exception as exc:report.update(state='blocked',mechanically_validated=False,issue='ownership_uncertain',reason=str(exc)[:2000],exit_code=2)
    for row in report['stages']:
        if row['state']=='running':row.update(state='unavailable',reason=report.get('reason','Stage interrupted'))
    report.update(ended_utc=support.now(),duration_seconds=round(time.monotonic()-started,6))
    if report['exit_code']!=0:report['mechanically_validated']=False
    raw=support.encoded(report)
    if len(raw)>support.BOUNDS['report_bytes']:
        report={'schema':support.SCHEMA,'version':support.VERSION,'state':'unavailable','mechanically_validated':False,
                'issue':'report_bound','reason':'Complete report exceeds bound; no successful validation published, no silent issue pruning',
                'omitted_report_bytes':len(raw),'output':str(output),'human_review':'pending','exit_code':2}
        raw=support.encoded(report)
    if owned_output:
        try:
            support.publish(output/'receipt.json',report)
        except Exception as exc:report.update(state='unavailable',mechanically_validated=False,issue='receipt_publication_failed',reason=str(exc)[:1000],exit_code=2)
    return report


def main(argv=None):
    parser=Parser(description=__doc__);args=None
    for flag in ('root','baseline-index','corpus','out'):parser.add_argument('--'+flag,type=Path,required=True)
    parser.add_argument('--run-id',required=True)
    parser.add_argument('--evaluation',type=Path,action='append',required=True)
    parser.add_argument('--baseline-evaluation',type=Path,action='append',required=True)
    parser.add_argument('--review',type=Path)
    parser.add_argument('--stage-seconds',type=float,default=support.BOUNDS['stage_seconds'])
    parser.add_argument('--total-seconds',type=float,default=support.BOUNDS['total_seconds'])
    parser.add_argument('--json',action='store_true')
    parser.add_argument('--_orchestrator',action='store_true',help=argparse.SUPPRESS)
    parser.add_argument('--_token',default='',help=argparse.SUPPRESS)
    try:
        args=parser.parse_args(argv)
        if args._orchestrator:
            if sys.stdin.buffer.readline(4)!=b'go\n' or not args._token:raise support.Blocked('start_gate','Owned orchestration gate missing')
            report=execute(args)
        else:
            from candidate_guard import guarded_operation
            report=guarded_operation(args,argv)
    except Exception as exc:report={'schema':support.SCHEMA,'state':'blocked','issue':getattr(exc,'issue','invalid_arguments'),
        'reason':str(exc)[:2000],'mechanically_validated':False,'human_review':'pending','exit_code':2}
    if hasattr(sys.stdout,'reconfigure'):sys.stdout.reconfigure(encoding='utf-8')
    if args is None or args.json:sys.stdout.buffer.write(support.encoded(report));sys.stdout.buffer.flush()
    else:
        print('Candidate preparation: '+report['state']+' | mechanical validation: '+str(report['mechanically_validated']))
        if report.get('preflight'):print('Baseline generation: '+report['preflight']['generation']+' | source update needed: '+str(report['preflight']['source_update_needed']))
        for row in report.get('stages',[]):print(row['name']+': '+row['state'])
        if report.get('issue'):print(report['issue']+': '+report['reason'])
        if report.get('output'):print('Evidence: '+report['output'])
        print('Human semantic review pending | registration unchanged | activation is a separate command')
    return report['exit_code']


if __name__=='__main__':raise SystemExit(main())
