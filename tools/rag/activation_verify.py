"""Read-only readiness and exact input seals, outside the installed runtime."""
import json
import hashlib
import os
from pathlib import Path
import stat
import time

import activation_contract as c


class Snapshot:
    def __init__(self,root):
        self.root=root;self.files={};self.bytes=0;self.count=0
        self.policy=c.s.current_policy(root,c.s.reader())
    def add(self,path,artifact=False,expected=None,limit=c.LIMIT,parent=False):
        path=c.inside(self.root,path)
        if artifact:
            if not path.is_relative_to(self.root/'_local/rag'):c.fail('unsafe_evidence','Artifact exception is restricted to local RAG data')
            raw,stamp=c.s.reader().read(path,limit)
        else:raw,stamp=c.s.permitted(self.root,path,self.policy,c.s.reader(),expected,limit,parent)
        self.count+=1;self.bytes+=len(raw)
        if self.count>3000 or self.bytes>384*1024**2:c.fail('read_bound','Readiness input count/byte budget exceeded')
        row={'sha256':c.s.sha(raw),'identity':list(stamp),'size':len(raw),'artifact':artifact}
        if expected is not None and row['sha256']!=expected:c.fail('changed_input','Required content identity differs: '+str(path))
        key=str(path)
        if key in self.files and self.files[key]!=row:c.fail('unstable_input','Input changed between observations: '+str(path))
        self.files[key]=row
        return raw
    def json(self,path,artifact=False):return json.loads(self.add(path,artifact))
    def check(self):
        policy=c.s.current_policy(self.root,c.s.reader())
        if policy!=self.policy:c.fail('policy_changed','Policy changed across verification')
        for path,row in self.files.items():
            p=Path(path)
            if not row['artifact']:
                raw,stamp=c.s.permitted(self.root,p,policy,c.s.reader(),row['sha256'],max(c.LIMIT,row['size']))
            else:raw,stamp=c.s.reader().read(p,max(c.LIMIT,row['size']))
            if list(stamp)!=row['identity'] or c.s.sha(raw)!=row['sha256']:c.fail('changed_input','Readiness invalidated: '+path)


def sealed(root,index,snapshot):
    index=c.inside(root,index,root/'_local/rag/indexes')
    # Bootstrap policy before content checks; known normalization derives from
    # verified extract bytes, never executing the inspected module.
    raw=c.s.permitted(root,root/'tools/rag/extract.py',snapshot.policy,c.s.reader(),limit=c.LIMIT)[0]
    run,logical,checks,omitted=c.s.detection.sealed_generation(root,index,c.s.reader(),c.s.sha(raw))
    if omitted:c.fail('incomplete_integrity','Sealed verification omitted required derivation')
    for name in ('run.json','logical.json','chunks.jsonl','index.sqlite3'):
        snapshot.add(index/name,True,limit=64*1024**2)
    return run,logical,checks


def fresh(root,index,snapshot):
    run,logical,checks=sealed(root,index,snapshot)
    identities=logical['identities']
    if set(identities['runtime_sha256'])!=set(c.s.RUNTIME_NAMES):c.fail('unsupported_runtime','Target runtime contract differs from the installed scope')
    for name,expected in sorted(identities['runtime_sha256'].items()):snapshot.add(root/'tools/rag'/name,expected=expected)
    snapshot.add(Path(identities['corpus_path']),expected=identities['corpus_sha256'])
    for source in logical['sources']:
        snapshot.add(root/source['path'],expected=source['sha256'],limit=c.s.detection.LIMITS['source_bytes'],parent=True)
    return run,logical,checks


def evaluation(snapshot,path,generation,logical,index=None):
    path=c.inside(snapshot.root,path,snapshot.root/'_local/rag/evaluations')
    if path.name!='run.json':c.fail('invalid_evidence','Select an evaluation run.json')
    for name in ('run.json','results.json','labels-snapshot.json'):snapshot.add(path.parent/name,True,limit=64*1024**2)
    receipt,results,labels=c.s.verify_evaluation_receipt(path,generation,c.s.reader())
    if results['configuration_identities']!=logical['identities']:c.fail('invalid_evidence','Evaluation does not identify the sealed configuration')
    if index is not None and Path(receipt['index_path'])!=index:c.fail('invalid_evidence','Evaluation selected a different index path')
    return receipt,results,labels


def evidence(root,path,target,action,snapshot):
    path=c.inside(root,path,root/'_local/rag/candidates')
    if path.name!='receipt.json':c.fail('invalid_evidence','Select a Phase 4B candidate receipt.json')
    receipt=snapshot.json(path,True)
    if receipt.get('schema')!=c.s.SCHEMA or receipt.get('state')!='mechanically_validated' or receipt.get('exit_code')!=0 or not receipt.get('mechanically_validated'):
        c.fail('incomplete_evidence','Candidate receipt is incomplete or failed')
    inventory=snapshot.json(path.parent/'input-inventory.json',True)
    indexes=[c.inside(root,p,root/'_local/rag/indexes') for p in receipt['artifacts']['indexes']]
    baseline=c.inside(root,inventory['baseline_index'],root/'_local/rag/indexes')
    if len(indexes)!=2 or indexes[0]==indexes[1]:c.fail('invalid_evidence','Two distinct explicit candidate publications are required')
    if action=='activate' and target not in indexes or action=='rollback' and target!=baseline:
        c.fail('wrong_target','Target is not the selected candidate or this evidence baseline for the requested action')
    seals=[sealed(root,p,snapshot) for p in [baseline,*indexes]]
    old,first,second=seals
    if first[1]!=second[1] or first[0]['generation_id']!=second[0]['generation_id']:
        c.fail('non_deterministic_candidate','Paired logical publications differ')
    if inventory['baseline_generation']!=old[0]['generation_id'] or receipt['preflight']['generation']!=old[0]['generation_id']:
        c.fail('invalid_evidence','Historical baseline identity differs')
    definitions=receipt['preflight']['definitions']
    if not 1<=len(definitions)<=c.s.BOUNDS['evaluations'] or len({d['path'] for d in definitions})!=len(definitions):c.fail('invalid_evidence','Explicit distinct definition scope is required')
    current={}
    for definition in definitions:
        current[definition['path']]=json.loads(snapshot.add(Path(definition['path']),expected=definition['sha256']))
    # Every completed stage needs its own retained input/result/command witness.
    stages=receipt['stages'];kinds={}
    for stage in stages:
        if not __import__('re').fullmatch(r'[0-9]{2}-[a-z_]+',stage['name']):c.fail('invalid_evidence','Unsupported stage identity')
        kinds[stage['kind']]=kinds.get(stage['kind'],0)+1
        base=path.parent/'stages'/stage['name']
        task=snapshot.json(base.with_suffix('.input.json'),True)
        result=snapshot.json(base.with_suffix('.result.json'),True)
        command=snapshot.json(base.with_suffix('.command.json'),True)
        if stage['state']!='completed' or result.get('state')!='completed' or stage['value']!=result.get('value') or command.get('exit_code')!=0 or command.get('issue') or command.get('capture_errors') or not command.get('owned_worker_reaped'):
            c.fail('incomplete_evidence','Stage failed, is missing or disagrees with its completion record')
        if task['kind']!=stage['kind'] or task['name']!=stage['name'] or Path(task['root'])!=root:
            c.fail('invalid_evidence','Stage input root or identity differs')
    n=len(definitions)
    expected={'audit':2,'audit_compare':1,'build':2,'verify':4,'evaluate':4*n,'pair_compare':2*n,'baseline_compare':2*n}
    if kinds!=expected or len({s['name'] for s in stages})!=len(stages):c.fail('incomplete_evidence','Candidate stage scope is incomplete')
    # Freeze all retained coordinator witnesses (no silent new or omitted files).
    for item in sorted(path.parent.rglob('*')):
        c.s.safe(item)
        if item.is_file():snapshot.add(item,True,limit=64*1024**2)
    comparisons=[];selected_evaluations=[]
    for definition in definitions:
        for profile in ('plain','terminology'):
            historical=[h for h in receipt['preflight']['historical_evaluations'] if h['definition']==definition['path'] and h['profile']==profile]
            if len(historical)!=1:c.fail('incomplete_evidence','Historical profile is missing or ambiguous')
            previous=evaluation(snapshot,Path(historical[0]['receipt']),old[0]['generation_id'],old[1],baseline)
            paired=[]
            for index,seal in zip(indexes,seals[1:]):
                inputs=[]
                for stage in stages:
                    if stage['kind']!='evaluate':continue
                    task=snapshot.json(path.parent/'stages'/(stage['name']+'.input.json'),True)
                    args=task['args']
                    if args['definition']==definition['path'] and args['profile']==profile and Path(args['index'])==index:inputs.append(args)
                if len(inputs)!=1:c.fail('incomplete_evidence','Paired evaluation selection is missing or ambiguous')
                location=c.inside(root,inputs[0]['out'],root/'_local/rag/evaluations')/'run.json'
                item=evaluation(snapshot,location,seal[0]['generation_id'],seal[1],index)
                if item[0]['evaluation_sha256']!=definition['sha256'] or item[2]!=current[definition['path']] or item[1]['variant']!=profile:
                    c.fail('invalid_evidence','Current definition, profile and evaluation snapshot differ')
                paired.append(item)
                if target==index:selected_evaluations.append(str(location))
            if paired[0][1]!=paired[1][1]:c.fail('retrieval_regression','Paired meaningful results differ')
            compared=c.s.compare_baseline(previous[1],paired[0][1],previous[2],paired[0][2],receipt['source_update_needed'],historical[0].get('conclusion_review'),historical[0].get('evidence_review'))
            compared=c.s.review_manual_tradeoffs(compared,previous[1],paired[0][1],historical[0].get('tradeoff_review'))
            if not compared['passed'] and not compared['accepted_for_manual_candidate']:
                c.fail('retrieval_regression','Historical comparison has unresolved regressions')
            comparisons.append({'definition':definition['path'],'profile':profile,'passed':True,
                'strict_comparison_passed':compared['passed'],'accepted_tradeoff_count':len(compared['accepted_tradeoffs']),
                'unchanged_meaningful_results':compared['unchanged_meaningful_results']})
            if target==baseline:selected_evaluations.append(historical[0]['receipt'])
    return {'receipt':str(path),'baseline_index':str(baseline),'baseline_generation':old[0]['generation_id'],
        'candidate_indexes':list(map(str,indexes)),'candidate_generation':first[0]['generation_id'],
        'definitions':definitions,'selected_evaluations':selected_evaluations,'comparisons':comparisons,
        'rehearsal':receipt['rehearsal'],'semantic_approval':'pending; agent evidence cannot authorize a switch'}


def dependencies(binding):
    command=Path(binding['command']);location=command.parent.parent
    if command.name.casefold() not in ('python.exe','python') or location.name!='mcp-venv':c.fail('unsupported_environment','Use the existing pinned mcp-venv interpreter')
    files={};total=0;directories={}
    for directory,dirs,names in os.walk(c.s.safe(location),followlinks=False):
        directory=c.s.safe(directory);dirs[:]=[n for n in dirs if n!='__pycache__']
        selected=sorted(n for n in names if not n.endswith('.pyc'))
        directories[directory]=(list(c.s.identity(directory.lstat())[:2]),sorted([*dirs,*selected]))
        if len(directories)>5000:c.fail('dependency_bound','Dependency directory bound exceeded')
        for name in sorted(names):
            path=directory/name
            if path.suffix=='.pyc':continue
            # Parent paths are checked once per directory before and after the
            # inventory, rather than thousands of repeated ancestor traversals.
            before=path.lstat()
            if c.s.detection.boundary.is_link(before) or not stat.S_ISREG(before.st_mode) or before.st_size>64*1024**2:
                c.fail('unsafe_environment','Dependency must be a bounded regular nonlink file')
            digest=hashlib.sha256();count=0
            descriptor=os.open(path,os.O_RDONLY|getattr(os,'O_BINARY',0)|getattr(os,'O_NOFOLLOW',0))
            with os.fdopen(descriptor,'rb') as handle:
                if c.s.identity(os.fstat(handle.fileno()))!=c.s.identity(before):c.fail('dependencies_changed','Dependency changed before read')
                while True:
                    chunk=handle.read(1024*1024)
                    if not chunk:break
                    count+=len(chunk);digest.update(chunk)
                    if count>64*1024**2 or total+count>256*1024**2:c.fail('dependency_bound','Dependency byte bound exceeded')
                after=os.fstat(handle.fileno())
            if c.s.identity(before)!=c.s.identity(after) or c.s.identity(before)!=c.s.identity(path.lstat()):
                c.fail('dependencies_changed','Dependency changed during observation')
            row={'sha256':digest.hexdigest(),'identity':list(c.s.identity(before)),'size':count};total+=count;files[str(path)]=row
            if len(files)>5000 or total>256*1024**2:c.fail('dependency_bound','Pinned environment inventory exceeds bounds')
    for directory,(stamp,names) in directories.items():
        directory=c.s.safe(directory)
        actual=sorted(p.name for p in directory.iterdir() if p.name!='__pycache__' and p.suffix!='.pyc')
        if list(c.s.identity(directory.lstat())[:2])!=stamp or actual!=names:c.fail('dependencies_changed','Dependency directory changed during observation')
    if not files or str(command) not in files:c.fail('environment_missing','Pinned interpreter inventory incomplete')
    return {'files':files,'file_count':len(files),'total_bytes':total,'scope':'noncache environment files; no installation or upgrade'}


def current_git(root):
    result=c.s.detection.git_provenance(root,{},c.s.reader())
    if result.get('state')!='observed':c.fail('git_unavailable','Current worktree branch/HEAD/staging unavailable')
    return result['current']


def readiness(root,target,evidence_path,action,review,output):
    snapshot=Snapshot(root);binding,raw,_=c.configuration(root)
    git=current_git(root)
    snapshot.add(Path(binding['path']))
    review=c.inside(root,review);snapshot.add(review,review.is_relative_to(root/'_local/rag'))
    for name in c.OWN:snapshot.add(root/'tools/rag'/name)
    observed=c.s.detection.inspect(root,Path(binding['index']))
    run,logical,checks=fresh(root,target,snapshot)
    proof=evidence(root,evidence_path,target,action,snapshot)
    # This contract evaluates the selected target under current policy. The old
    # binding's current freshness is reported separately and may legitimately fail.
    env=dependencies(binding)
    from activation_client import verify
    selected=dict(binding,index=str(target))
    client=verify(root,selected,run['generation_id'],run['source_count'],output)
    if dependencies(binding)!=env:c.fail('dependencies_changed','Pinned environment changed during consumer verification')
    snapshot.check()
    if current_git(root)!=git:c.fail('git_changed','Worktree branch/HEAD/staging changed during verification')
    return {'schema':c.SCHEMA,'action':action,'root':str(root),'root_file_id':list(c.s.identity(root.lstat())[:2]),
        'git':git,
        'configuration':binding,'previous_index':binding['index'],'previous_generation':observed['selected']['generation'],
        'previous_condition':{k:observed[k] for k in ('generation_integrity','compatibility','source_freshness')},
        'target_index':str(target),'target_generation':run['generation_id'],'sources':run['source_count'],'chunks':run['chunk_count'],
        'target_integrity_checks':checks,'all_target_sources_verified':True,'evidence':proof,
        'review_packet':str(review),'review_packet_sha256':snapshot.files[str(review)]['sha256'],
        'inputs':snapshot.files,'dependencies':env,'isolated_consumer':client,
        'mechanically_ready':True,'human_approval':'required for this exact plan and target; preparation is not approval',
        'recovery':'Retain prior-config.bin and journal. Never restore over later edits; prepare a new verified rollback plan.',
        'existing_desktop_consumer':'unobserved','created_utc':c.s.now()},snapshot


def check_plan(root,plan,output):
    if plan.get('schema')!=c.SCHEMA or Path(plan['root'])!=root or not plan.get('mechanically_ready'):
        c.fail('invalid_plan','Plan root/schema/readiness differs')
    binding,_,_=c.configuration(root)
    if binding!=plan['configuration']:c.fail('configuration_changed','Current registration identity or binding changed after preparation')
    if list(c.s.identity(root.lstat())[:2])!=plan['root_file_id']:c.fail('wrong_root','Root filesystem identity changed')
    if current_git(root)!=plan['git']:c.fail('git_changed','Worktree branch/HEAD/staging changed after preparation')
    snapshot=Snapshot(root);snapshot.files=plan['inputs'];snapshot.check()
    if dependencies(binding)!=plan['dependencies']:c.fail('dependencies_changed','Pinned environment identities changed')
    # Independently repeat every target integrity/compatibility/parent/evidence
    # gate at apply time, not just the earlier Boolean or previous receipt.
    run,logical,checks=fresh(root,Path(plan['target_index']),snapshot)
    if run['generation_id']!=plan['target_generation']:c.fail('wrong_target','Target generation changed')
    evidence(root,Path(plan['evidence']['receipt']),Path(plan['target_index']),plan['action'],snapshot)
    snapshot.check()
    return snapshot
