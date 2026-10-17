"""Candidate-only path, identity, ownership and comparison controls; no runtime imports."""
import datetime as dt
import copy
import json
import os
from pathlib import Path
import re
import sqlite3
import time
import uuid

import refresh_inspect as detection
from refresh_boundary import identity, load_config, path_key, policy_for

SCHEMA = 'cyrus.candidate-preparation/1'
VERSION = '0.5.0'
TOOL = Path(__file__).resolve().parent
OWN = ('prepare_candidate.py', 'candidate_support.py', 'candidate_worker.py', 'candidate_guard.py',
       'refresh_inspect.py', 'refresh_boundary.py')
# Supported producer contract, listed as data so startup never imports retrieval.
RUNTIME_NAMES = ('extract.py','retrieval.py','build_index.py','search.py','evaluation.py','evaluate.py',
    'verify_indexes.py','retrieval.toml','config.toml','catalog.py','rules.py','contracts.py','integrity.py',
    'lexical.py','status.py','ranking-v2.1.json','glossary-v1.json','locations.py','provenance.py',
    'adapter.py','adapter_worker.py','adapter_process.py','adapter-requirements.lock.txt')
EXTRAS = {'build_manifest.py':'b6bd150dcfa6f901095a3410b5d8339ca51d8b7eab02405e5304af013fbc901e',
          'reporting.py':'410c3ef3310a53a4488937a190184ac97109ddc9284e8545f9375d017da6f65b',
          'verify_runs.py':'482c187e94b339d47d1a703e71a265998e8198edaab6b02e5e6f46f0e7081ed4'}
BOUNDS = {'stage_seconds':90, 'total_seconds':1800, 'max_stage_seconds':120,
          'max_total_seconds':3600, 'captured_stream_bytes':1024*1024,
          'stage_read_bytes':2*1024**3, 'total_read_bytes':16*1024**3,
          'report_bytes':256*1024, 'definition_bytes':2*1024**2,
          'artifact_bytes':64*1024**2, 'evaluations':4, 'baseline_receipts':8}

encoded = detection.encoded
sha = detection.sha
absolute = detection.absolute


class Blocked(ValueError):
    def __init__(self, issue, message):
        super().__init__(message); self.issue=issue


def now():return dt.datetime.now(dt.timezone.utc).isoformat()


def safe(path, missing=False):
    path=absolute(path)
    for entry in [*reversed(path.parents),path]:
        try:
            if detection.boundary.is_link(entry.lstat()):raise Blocked('unsafe_path','Link/reparse point rejected: '+str(entry))
        except FileNotFoundError:
            if not missing:raise Blocked('missing','Required path is absent: '+str(entry))
    return path


def fresh(path, parent):
    path=safe(path,True);parent=safe(parent,True)
    if path==parent or not path.is_relative_to(parent):raise Blocked('unsafe_output','Output must be a fresh child of '+str(parent))
    if path.exists():raise Blocked('existing_destination','Destination already exists, including empty directories: '+str(path))
    return path


def create(path, value, raw=False):
    """Never replace a receipt, inventory, log or artifact, even on caller error."""
    safe(path,True)
    with Path(path).open('xb') as handle:handle.write(value if raw else encoded(value))


def publish(path,value):
    """An exclusive complete receipt becomes visible atomically; failed temps stay."""
    path=safe(path,True)
    temporary=path.with_name('.'+path.name+'.partial-'+uuid.uuid4().hex)
    with temporary.open('xb') as handle:
        handle.write(encoded(value));handle.flush();os.fsync(handle.fileno())
    # A hard link creates an exclusive final name on Windows and POSIX. Unlike
    # replace/rename, an existing receipt cannot be overwritten on either OS.
    os.link(temporary,path)
    temporary.unlink()


def reader(seconds=20):
    result=detection.Reader();result.deadline=time.monotonic()+seconds
    return result


def current_policy(root, read):
    raw,stamp=read.read(root/'tools/rag/config.toml',BOUNDS['definition_bytes'])
    return {'config':load_config(detection.PolicyBytes(raw)),'stamp':stamp,'sha256':sha(raw)}


def permitted(root, path, policy, read, expected=None, limit=None, parent=False):
    path=safe(path)
    if path==root or not path.is_relative_to(root):raise Blocked('wrong_root','Input must be inside the explicit root')
    if identity(safe(root/'tools/rag/config.toml').lstat())!=policy['stamp']:
        raise Blocked('policy_changed','Policy identity changed before dependent content access')
    relative=path.relative_to(root).as_posix()
    if policy_for(relative,False,policy['config'])[0]!='full':
        raise Blocked('policy_blocked','Current policy denies content access: '+relative)
    raw,stamp=read.read(path,min(limit or BOUNDS['definition_bytes'],policy['config']['max_hash_bytes']),parent)
    if expected is not None and sha(raw)!=expected:raise Blocked('changed_input','Required identity changed: '+relative)
    return raw,stamp


class Ownership:
    """O_EXCL ownership; abandoned/uncertain owners are never taken over."""
    def __init__(self,root,token):self.path=root/'_local/rag/candidate-preparation.lock';self.token=token;self.stamp=None
    def acquire(self):
        safe(self.path,True);self.path.parent.mkdir(parents=True,exist_ok=True)
        try:create(self.path,{'schema':SCHEMA,'pid':os.getpid(),'token':self.token,'created_utc':now()})
        except FileExistsError as exc:raise Blocked('ownership_uncertain','Another or interrupted operation owns '+str(self.path)+'; no automatic takeover') from exc
        self.stamp=identity(self.path.lstat())
    def release(self):
        if self.stamp is None:return
        raw,stamp=reader().read(self.path,4096)
        if stamp!=self.stamp or json.loads(raw).get('token')!=self.token:
            raise Blocked('ownership_uncertain','Lock ownership changed; retained for explicit inspection')
        self.path.unlink();self.stamp=None


def review_runtime(runtime, review):
    """A manual revision may pin reviewed successor bytes, never import them."""
    result=dict(runtime);seen=set()
    for change in (review or {}).get('runtime',[]):
        name=change.get('name')
        if name not in runtime or name in seen:
            raise Blocked('unsupported_runtime','Runtime review must name each known helper at most once')
        seen.add(name)
        if (change.get('old_sha256')!=runtime[name] or not isinstance(change.get('new_sha256'),str)
                or not re.fullmatch('[0-9a-f]{64}',change['new_sha256'])
                or not isinstance(change.get('reason'),str) or not change['reason'].strip()
                or change.get('diff_inspected') is not True or change.get('tests_reviewed') is not True):
            raise Blocked('runtime_review_pending','Exact prior/successor hashes and inspected test rationale required: '+name)
        result[name]=change['new_sha256']
    return result


def review_definition(baseline, candidate, review):
    """Hash-bound manual enrollment/retirement; never implicit authority promotion."""
    if candidate.get('schema')!='cyrus.corpus/1':raise Blocked('unsupported_corpus','Unsupported candidate corpus schema')
    old={s['path']:s for s in baseline['sources']};new={s['path']:s for s in candidate['sources']}
    added=set(new)-set(old);removed=set(old)-set(new)
    enrollment=(review or {}).get('enrollment',{})
    if (len(new)!=len(candidate['sources']) or len(set(map(path_key,new)))!=len(new)
            or [p for p in new if p in old]!=[p for p in old if p in new]):
        raise Blocked('scope_changed','Candidate must preserve surviving paths, spelling and relative order; duplicate/case-alias paths are rejected')
    retirements=(review or {}).get('retirements',[])
    if (not isinstance(retirements,list) or any(not isinstance(r,dict) for r in retirements)
            or len(retirements)!=len(removed) or {r.get('path') for r in retirements}!=removed):
        raise Blocked('retirement_review_pending','Every removed source requires exactly one explicit retirement review')
    changes=[]
    for entry in retirements:
        path=entry['path']
        if (entry.get('old_sha256')!=old[path]['sha256']
                or not all(isinstance(entry.get(k),str) and entry[k].strip()
                           for k in ('reason','historical_evidence','replacement_or_omission'))
                or not all(entry.get(k) is True for k in ('agent_reviewed','references_checked','evaluation_requirements_checked'))):
            raise Blocked('retirement_review_pending','Retirement requires prior hash, history, disposition and reviewed dependencies: '+path)
        changes.append({'path':path,'fields':['retired'],'enrolled':False,'retired':True,'review':entry})
    if added and (set(enrollment.get('added',[]))!=added
            or not isinstance(enrollment.get('reason'),str) or not enrollment['reason'].strip()
            or enrollment.get('agent_reviewed') is not True):
        raise Blocked('scope_changed','New sources require a separate explicit enrollment review; automatic refresh cannot enroll')
    proposals={c['path']:c for c in (review or {}).get('sources',[])}
    for path,source in new.items():
        previous=old.get(path,{})
        if source==previous:continue
        fields=sorted(k for k in set(source)|set(previous) if source.get(k)!=previous.get(k))
        entry=proposals.get(path,{})
        if (entry.get('old_sha256')!=previous.get('sha256') or entry.get('new_sha256')!=source['sha256']
                or set(entry.get('field_reasons',{}))!=set(fields)
                or any(not isinstance(v,str) or not v.strip() for v in entry.get('field_reasons',{}).values())
                or not all(entry.get(k) is True for k in ('diff_inspected','ranges_checked','context_checked',
                    'applicability_checked','authority_checked','generated_ownership_checked','canonical_checked'))):
            raise Blocked('semantic_review_pending','Separate field-specific agent review required: '+path)
        if previous.get('knowledge_status') in ('historical','unknown','archive') and source['knowledge_status']=='current':
            raise Blocked('authority_promotion','Authority promotion is outside this preparation workflow: '+path)
        metadata_fields={'status_source','inventory_decision','inventory_reason','referenced_by_current_docs',
            'current_reference_sources','component','generated','generated_source','review_status','applicability',
            'canonical','selection_reason'}
        atomic_review=(set(fields)<=metadata_fields|{'contract_sections'}
                       and entry.get('contract_sections_reviewed') is True)
        if (source['sha256']==previous.get('sha256') and not (
                (set(fields)<=metadata_fields or atomic_review) and entry.get('unchanged_metadata_reviewed') is True)):
            raise Blocked('unchanged_scope_changed','Unchanged parents must preserve their complete source definitions, including ranges, roles, applicability and canonical ownership: '+path)
        changes.append({'path':path,'fields':fields,'enrolled':path in added,'review':entry})
    return changes


def verify_evaluation_receipt(path,generation,read):
    receipt=json.loads(read.read(safe(path),BOUNDS['definition_bytes'])[0])
    raw=read.read(safe(path.parent/'results.json'),BOUNDS['artifact_bytes'])[0];results=json.loads(raw)
    labels=json.loads(read.read(safe(path.parent/'labels-snapshot.json'),BOUNDS['definition_bytes'])[0])
    if (not receipt.get('complete') or receipt['index_generation']!=generation
            or sha(raw)!=receipt['results_sha256'] or results['index_generation']!=generation
            or results['evaluation_sha256']!=receipt['evaluation_sha256']
            or results.get('schema')!='cyrus.retrieval-evaluation/2'
            or labels.get('schema')!='cyrus.evaluation/1'):
        raise Blocked('invalid_baseline_evaluation','Baseline evaluation identity/export mismatch: '+str(path))
    expected=[(group,q) for group,items in (('base',labels['queries']),('anchors',labels['anchors'])) for q in items]
    if len(expected)!=len(results['questions']) or any(
            actual.get('group')!=group or any(actual.get(k)!=v for k,v in question.items())
            for (group,question),actual in zip(expected,results['questions'])):
        raise Blocked('invalid_baseline_evaluation','Historical label snapshot and scored question records disagree')
    if [(t['group'],t['id']) for t in receipt['query_timings']]!=[(group,q['id']) for group,q in expected]:
        raise Blocked('invalid_baseline_evaluation','Historical timing question identities disagree')
    return receipt,results,labels


def reviewed_conclusions(before,after,changes,sources_changed):
    """Only explicit manually reviewed snapshot answer notes may differ.

    These notes are not scored by retrieval. Questions, evidence requirements,
    qualifiers, splits and answerability still have to match exactly below.
    """
    normalized=copy.deepcopy(before);seen=set()
    for entry in changes or []:
        group=entry.get('group');identifier=entry.get('id');key=(group,identifier)
        field={'base':'queries','anchors':'anchors'}.get(group)
        if not sources_changed or field is None or key in seen:
            raise Blocked('evaluation_semantics_changed','Invalid or duplicate snapshot conclusion review')
        seen.add(key)
        prior=[q for q in normalized[field] if q['id']==identifier]
        current=[q for q in after[field] if q['id']==identifier]
        if (len(prior)!=1 or len(current)!=1 or not isinstance(entry.get('reason'),str) or not entry['reason'].strip()
                or entry.get('old_value')!=prior[0].get('reference_conclusion')
                or entry.get('new_value')!=current[0].get('reference_conclusion')
                or not isinstance(entry.get('new_value'),str) or not entry['new_value'].strip()
                or entry.get('agent_reviewed') is not True):
            raise Blocked('evaluation_semantics_changed','Exact inspected old/new reference conclusion required')
        prior[0]['reference_conclusion']=entry['new_value']
    return normalized


def review_evidence_alternatives(before, after, changes, sources_changed):
    """Explicit equivalent-owner additions; never remove/weaken existing units."""
    result=copy.deepcopy(before);seen=set()
    for entry in changes or []:
        field={'base':'queries','anchors':'anchors'}.get(entry.get('group'))
        key=(field,entry.get('id'))
        if not sources_changed or field is None or key in seen:
            raise Blocked('evidence_review_pending','Invalid/duplicate evidence-owner review')
        seen.add(key)
        previous=next((q for q in result[field] if q['id']==entry.get('id')),None)
        current=next((q for q in after[field] if q['id']==entry.get('id')),None)
        if (not previous or not current or entry.get('old_value')!=previous.get('required_evidence')
                or entry.get('new_value')!=current.get('required_evidence')
                or entry.get('agent_reviewed') is not True
                or not all(isinstance(entry.get(k),str) and entry[k].strip() for k in ('reason','equivalence_evidence'))):
            raise Blocked('evidence_review_pending','Exact prior/current evidence and substantive equivalence review required')
        a,b=entry['old_value'],entry['new_value']
        if len(a)!=len(b):raise Blocked('evidence_review_pending','Evidence units cannot be added or removed')
        def clean(v):
            if isinstance(v,dict):return {k:clean(x) for k,x in v.items() if k not in ('sha256','start_line','end_line')}
            if isinstance(v,list):return [clean(x) for x in v]
            return v
        for old_unit,new_unit in zip(a,b):
            if (clean({k:v for k,v in old_unit.items() if k not in ('alternatives','canonical_paths')})
                    !=clean({k:v for k,v in new_unit.items() if k not in ('alternatives','canonical_paths')})
                    or not all(clean(x) in [clean(y) for y in new_unit['alternatives']] for x in old_unit['alternatives'])
                    or not set(old_unit['canonical_paths'])<=set(new_unit['canonical_paths'])
                    or not set(new_unit['canonical_paths'])<={x['path'] for x in new_unit['alternatives']}):
                raise Blocked('evidence_review_pending','Only reviewed equivalent alternatives may be added; existing owners and requirements remain')
        previous['required_evidence']=copy.deepcopy(b)
    return result


def compare_baseline(old,new,labels_before,labels_after,sources_changed,conclusion_review=None,evidence_review=None):
    """Provenance is excluded explicitly; questions and evidence are never pruned."""
    def stable_questions(dataset):
        def clean(value):
            if isinstance(value,dict):return {k:clean(v) for k,v in value.items() if k not in ('sha256','start_line','end_line')}
            if isinstance(value,list):return [clean(v) for v in value]
            return value
        return clean({'queries':dataset['queries'],'anchors':dataset['anchors']})
    reviewed=reviewed_conclusions(labels_before,labels_after,conclusion_review,sources_changed)
    reviewed=review_evidence_alternatives(reviewed,labels_after,evidence_review,sources_changed)
    if stable_questions(reviewed)!=stable_questions(labels_after):
        raise Blocked('evaluation_semantics_changed','Question/qualifier/split/evidence requirement changes need separate review; exact comparability is unavailable')
    before={(q['group'],q['id']):q for q in old['questions']};after={(q['group'],q['id']):q for q in new['questions']}
    if before.keys()!=after.keys():raise Blocked('evaluation_denominators_changed','Question IDs/denominators changed')
    differences=[];regressions=[]
    for key,q in after.items():
        previous=before[key]
        if q!=previous:differences.append({'group':key[0],'id':key[1],
            'scores_before':previous['scores'],'scores_after':q['scores'],
            'ranked_paths_before':[r['path'] for r in previous['ranked_results']],
            'ranked_paths_after':[r['path'] for r in q['ranked_results']],
            'evidence_changed':previous['required_evidence']!=q['required_evidence'],
            'qualifiers_changed':previous['resolved_source_qualifiers']!=q['resolved_source_qualifiers']})
        for k in ('5','10'):
            a=previous['scores']['at_k'][k];b=q['scores']['at_k'][k]
            if (b['found_units']<a['found_units'] or b['source_precision']<a['source_precision']
                    or len(b['misleading_hits'])>len(a['misleading_hits'])):
                regressions.append({'group':key[0],'id':key[1],'at_k':k,'reason':'coverage/precision/misleading evidence regression'})
        if q['scores']['canonical_reciprocal_rank']<previous['scores']['canonical_reciprocal_rank']:
            regressions.append({'group':key[0],'id':key[1],'reason':'canonical source ranking regression'})
        if not q['answerable'] and q['scores']['at_k']['10']['returned_count']>previous['scores']['at_k']['10']['returned_count']:
            regressions.append({'group':key[0],'id':key[1],'reason':'More related results for an unanswerable question; unresolved review required'})
    unchanged=old['metrics']==new['metrics'] and old['questions']==new['questions']
    if not sources_changed and not unchanged:regressions.append({'reason':'Unchanged evidence must preserve every meaningful result and metric'})
    return {'passed':not regressions,'unchanged_meaningful_results':unchanged,'sources_changed':sources_changed,
            'exact_definition_bytes_equal':old['evaluation_sha256']==new['evaluation_sha256'],
            'metrics_before':old['metrics'],'metrics_after':new['metrics'],
            'question_differences':differences,'regressions':regressions,
            'reviewed_reference_conclusion_changes':conclusion_review or [],
            'reviewed_equivalent_evidence_changes':evidence_review or [],
            'excluded_fields':['index_generation','configuration_identities','run/query timings'],
            'human_review':'pending; historical and candidate labels are agent-authored'}


def review_manual_tradeoffs(comparison, old, new, review=None):
    """Accept exact inspected ranking tradeoffs only for explicit manual candidates.

    The strict comparison stays false and automatic refresh never calls this
    function. Lost top-ten evidence, newly misleading results, lost canonical
    sources and increased negative-query result counts cannot be waived.
    """
    result={**comparison,'accepted_for_manual_candidate':False,'accepted_tradeoffs':[]}
    if review is None:return result
    required={'schema','old_evaluation_sha256','new_evaluation_sha256','profile',
              'comparison_sha256','agent_reviewed','reason','regressions'}
    if (not isinstance(review,dict) or set(review)!=required
            or review['schema']!='cyrus.retrieval-tradeoff-review/1'
            or review['old_evaluation_sha256']!=old['evaluation_sha256']
            or review['new_evaluation_sha256']!=new['evaluation_sha256']
            or review['profile']!=old['variant'] or review['profile']!=new['variant']
            or review['comparison_sha256']!=sha(encoded(comparison))
            or review['agent_reviewed'] is not True
            or not isinstance(review['reason'],str) or not review['reason'].strip()
            or not comparison['sources_changed'] or not comparison['regressions']):
        raise Blocked('invalid_tradeoff_review','Exact inspected changed-source comparison and review identities required')
    entries=review['regressions']
    if (not isinstance(entries,list) or len(entries)!=len(comparison['regressions'])
            or any(not isinstance(e,dict) or set(e)!={'finding','reason'}
                   or e['finding']!=finding or not isinstance(e['reason'],str) or not e['reason'].strip()
                   for e,finding in zip(entries,comparison['regressions']))):
        raise Blocked('invalid_tradeoff_review','Every exact regression needs its own inspected reason, in recorded order')
    before={(q['group'],q['id']):q for q in old['questions']}
    after={(q['group'],q['id']):q for q in new['questions']}
    if before.keys()!=after.keys():raise Blocked('invalid_tradeoff_review','Question scope changed')
    for key,q in after.items():
        previous=before[key];a=previous['scores'];b=q['scores']
        old_hits=a['at_k']['10']['unit_hits'];new_hits=b['at_k']['10']['unit_hits']
        if len(old_hits)!=len(new_hits) or any(x and not y for x,y in zip(old_hits,new_hits)):
            raise Blocked('unwaivable_retrieval_regression','A required top-ten evidence unit was lost')
        if a['canonical_reciprocal_rank']>0 and b['canonical_reciprocal_rank']==0:
            raise Blocked('unwaivable_retrieval_regression','A previously retrieved canonical source was lost')
        for k in ('5','10'):
            # Locations may move under a separately reviewed definition. Compare
            # labeled claim identities, not mutable line/hash provenance.
            def identity(hit):
                return encoded({**{name:value for name,value in hit.items() if name not in ('ranks','evidence')},
                                'evidence_path':hit['evidence']['path']})
            previous_bad={identity(hit) for hit in a['at_k'][k]['misleading_hits']}
            if any(identity(hit) not in previous_bad for hit in b['at_k'][k]['misleading_hits']):
                raise Blocked('unwaivable_retrieval_regression','New misleading evidence entered the measured window')
        if not q['answerable'] and b['at_k']['10']['returned_count']>a['at_k']['10']['returned_count']:
            raise Blocked('unwaivable_retrieval_regression','An unanswerable query returned additional related results')
    result.update(accepted_for_manual_candidate=True,accepted_tradeoffs=entries,
                  tradeoff_review_sha256=sha(encoded(review)),tradeoff_review_reason=review['reason'])
    return result
