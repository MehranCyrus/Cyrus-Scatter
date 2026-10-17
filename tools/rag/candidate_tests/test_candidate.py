"""Candidate preparation in owned disposable repositories; no production mutations."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest import mock

TOOL=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(TOOL),str(TOOL/'tests'),str(TOOL/'refresh_tests')]
import candidate_support as support
import prepare_candidate as preparation
import evaluation
import retrieval
import test_refresh as refresh
import fresh_process


class CandidateTests(unittest.TestCase):
    write=refresh.RefreshTests.write
    git=refresh.RefreshTests.git
    scan=refresh.RefreshTests.scan
    read_rows=refresh.RefreshTests.read_rows
    build=refresh.RefreshTests.build
    tearDown=refresh.RefreshTests.tearDown

    def setUp(self):
        refresh.RefreshTests.setUp(self)
        for name in (*support.OWN,*support.EXTRAS):
            self.write('tools/rag/'+name,(TOOL/name).read_bytes())
        source=self.definition['sources'][0]
        location={'path':self.current,'sha256':source['sha256'],'start_line':3,'end_line':3}
        question={'id':'guide','language':'en','category':'workflow','query':'forRanges','mode':'identifier',
            'information_need':'Find the current worker guide','required_qualifiers':['fixture applicability'],
            'review_status':'fixture agent review; human pending','split':'holdout','answerable':True,
            'required_evidence':[{'id':'guide','alternatives':[location],'canonical_paths':[self.current]}],
            'optional_evidence':[],'misleading_substitutions':[]}
        absent={**question,'id':'absent','query':'absentexactidentifier','answerable':False,'required_evidence':[]}
        self.labels={'schema':'cyrus.evaluation/1','dataset_kind':'challenge','review_status':'fixture; human pending',
                     'queries':[question,absent],'anchors':[]}
        self.dataset=self.write('tools/rag/fixture-evaluation.json',json.dumps(self.labels))
        self.historical=[]
        for profile in ('plain','terminology'):
            out=self.root/'_local/rag/evaluations'/('baseline-'+profile)
            evaluation.run_evaluation(self.index,self.dataset,out,profile)
            self.historical.append(out/'run.json')
        self.serial=0

    def args(self,**updates):
        self.serial+=1;run_id='candidate-fixture-'+str(self.serial)
        data=dict(root=self.root,baseline_index=self.index,corpus=self.corpus,evaluation=[self.dataset],
                  baseline_evaluation=self.historical,run_id=run_id,out=self.root/'_local/rag/candidates'/run_id,
                  review=None,stage_seconds=20,total_seconds=120,json=True,_token='owned-fixture')
        data.update(updates);return SimpleNamespace(**data)

    def command(self,args,human=False):
        command=[sys.executable,'-B',str(self.root/'tools/rag/prepare_candidate.py')]
        for key in ('root','baseline_index','corpus','out','run_id','stage_seconds','total_seconds'):
            command.extend(['--'+key.replace('_','-'),str(getattr(args,key))])
        for key in ('evaluation','baseline_evaluation'):
            for value in getattr(args,key):command.extend(['--'+key.replace('_','-'),str(value)])
        if args.review:command.extend(['--review',str(args.review)])
        if not human:command.append('--json')
        return command

    def cli(self,args=None,human=False,env=None):
        args=args or self.args()
        result=subprocess.run(self.command(args,human),capture_output=True,env=env,timeout=140)
        self.assertEqual(result.stderr,b'',result.stderr.decode(errors='replace'))
        if human:return result
        value=json.loads(result.stdout)
        self.assertEqual(value['schema'],support.SCHEMA)
        self.assertEqual(value['exit_code'],result.returncode)
        return value

    def preflight(self,args=None):
        with mock.patch.object(support,'TOOL',self.root/'tools/rag'):
            return preparation.preflight(args or self.args())

    def execute(self,args,hook=None):
        original=preparation.stage_process
        def stage(command,task,directory,seconds):
            result=original(command,task,directory,seconds)
            if hook:hook(task)
            return result
        with mock.patch.object(support,'TOOL',self.root/'tools/rag'),mock.patch.object(preparation,'stage_process',side_effect=stage):
            return preparation.execute(args)

    def protected(self):
        paths=[*self.index.iterdir(),self.corpus,self.registration,self.dataset,
               *(self.root/'tools/rag'/name for name in retrieval.RUNTIME_FILES),
               *(p for receipt in self.historical for p in receipt.parent.iterdir())]
        return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths if p.is_file()}

    def deny(self,path):return refresh.RefreshTests.deny(self,path)

    def changed_definition(self,paths):
        candidate=copy.deepcopy(self.definition);entries=[]
        for source in candidate['sources']:
            if source['path'] not in paths:continue
            previous=copy.deepcopy(source);body=(self.root/source['path']).read_bytes()
            source['sha256']=support.sha(body);source['ranges']=[[1,len(body.decode().splitlines())]]
            fields={k:'Inspected fixture diff, full parent and surrounding context; original authority retained'
                    for k in source if source[k]!=previous[k]}
            entries.append({'path':source['path'],'old_sha256':previous['sha256'],'new_sha256':source['sha256'],
                'field_reasons':fields,**{k:True for k in ('diff_inspected','ranges_checked','context_checked',
                'applicability_checked','authority_checked','generated_ownership_checked','canonical_checked')}})
        corpus=self.write('tools/rag/fixture-candidate-v2.json',json.dumps(candidate))
        review=self.write('tools/rag/fixture-review-v2.json',json.dumps({'sources':entries,
            'corpus':{'old_sha256':support.sha(self.corpus.read_bytes()),'new_sha256':support.sha(corpus.read_bytes()),
                      'reason':'Separate provisional fixture definition; human review pending'}}))
        return corpus,review

    def assert_failed(self,report):
        self.assertFalse(report['mechanically_validated']);self.assertNotEqual(report['exit_code'],0)
        self.assertEqual(report['human_review'],'pending')

    def test_complete_unchanged_rehearsal_and_preservation(self):
        before=self.protected();args=self.args();report=self.cli(args)
        self.assertEqual(report['exit_code'],0,report)
        self.assertTrue(report['rehearsal']);self.assertFalse(report['source_update_needed'])
        self.assertEqual(len(report['stages']),17)
        self.assertTrue(all(s['state']=='completed' for s in report['stages']))
        indexes=list(map(Path,report['artifacts']['indexes']))
        runs=[json.loads((i/'run.json').read_bytes()) for i in indexes]
        self.assertEqual(runs[0]['generation_id'],runs[1]['generation_id'])
        self.assertNotEqual(runs[0]['generation_id'],report['preflight']['generation'])
        for name in ('logical.json','chunks.jsonl'):
            self.assertEqual((indexes[0]/name).read_bytes(),(indexes[1]/name).read_bytes())
        self.assertEqual(json.loads((args.out/'receipt.json').read_bytes()),report)
        self.assertTrue((args.out/'input-inventory.json').exists())
        self.assertEqual(self.protected(),before)
        self.assertFalse((self.root/'_local/rag/candidate-preparation.lock').exists())
        self.assertTrue(all(s['value']['unchanged_meaningful_results'] for s in report['stages'] if s['kind']=='baseline_compare'))

    def test_changed_unreturned_and_untracked_sources_use_separate_reviewed_definition(self):
        before=self.protected()
        # Both are already untracked; neither is returned by a guide-only query.
        self.write(self.history,'# Past\n\nforRanges historical evidence schema 54.\n\nReviewed context.\n')
        self.write(self.unknown,'# Unknown\n\nforRanges unknown evidence.\n\nReviewed context.\n')
        corpus,review=self.changed_definition([self.history,self.unknown])
        report=self.cli(self.args(corpus=corpus,review=review))
        self.assertEqual(report['exit_code'],0,report)
        self.assertTrue(report['source_update_needed']);self.assertFalse(report['rehearsal'])
        self.assertEqual(sum(p['baseline_outcome']=='stale' for p in report['preflight']['parents']),2)
        self.assertEqual(self.protected(),before)
        self.assertTrue(any(not s['value']['unchanged_meaningful_results'] for s in report['stages'] if s['kind']=='baseline_compare'))

    def test_changed_source_without_definition_review_is_blocked(self):
        self.write(self.history,'changed unreturned source\n');before=self.protected()
        report=self.cli();self.assert_failed(report)
        self.assertEqual(report['issue'],'candidate_source_mismatch');self.assertEqual(before,self.protected())

    def test_same_size_change_with_restored_mtime_is_detected(self):
        path=self.root/self.current;stat=path.stat();path.write_bytes(path.read_bytes().replace(b'joins',b'links'))
        os.utime(path,ns=(stat.st_atime_ns,stat.st_mtime_ns))
        self.assertEqual(path.stat().st_size,stat.st_size)
        report=self.cli();self.assert_failed(report);self.assertEqual(report['issue'],'candidate_source_mismatch')

    def test_missing_and_renamed_parent_no_substitution(self):
        (self.root/self.history).rename(self.root/'docs/renamed.md')
        report=self.cli();self.assert_failed(report);self.assertEqual(report['issue'],'missing')

    def test_scope_and_authority_changes_are_not_silently_accepted(self):
        _,_,_,observation=self.preflight()
        baseline={'sources':copy.deepcopy(self.definition['sources'])}
        candidate=copy.deepcopy(self.definition);candidate['sources'].pop()
        with self.assertRaisesRegex(support.Blocked,'retirement review'):support.review_definition(baseline,candidate,None)
        candidate=copy.deepcopy(self.definition);candidate['sources'][1]['knowledge_status']='current'
        entry={'path':self.history,'old_sha256':candidate['sources'][1]['sha256'],'new_sha256':candidate['sources'][1]['sha256'],
            'field_reasons':{'knowledge_status':'fixture proposed promotion'},**{k:True for k in ('diff_inspected','ranges_checked',
            'context_checked','applicability_checked','authority_checked','generated_ownership_checked','canonical_checked')}}
        with self.assertRaisesRegex(support.Blocked,'promotion'):support.review_definition(baseline,candidate,{'sources':[entry]})
        self.assertFalse(observation['source_update_needed'])

    def test_review_record_cannot_alter_an_unchanged_parents_scope(self):
        baseline={'sources':copy.deepcopy(self.definition['sources'])}
        candidate=copy.deepcopy(self.definition);candidate['sources'][0]['ranges']=[[1,3]]
        flags={k:True for k in ('diff_inspected','ranges_checked','context_checked','applicability_checked',
                               'authority_checked','generated_ownership_checked','canonical_checked')}
        entry={'path':self.current,'old_sha256':candidate['sources'][0]['sha256'],
               'new_sha256':candidate['sources'][0]['sha256'],'field_reasons':{'ranges':'Explicit but out-of-scope fixture change'},**flags}
        with self.assertRaises(support.Blocked) as caught:support.review_definition(baseline,candidate,{'sources':[entry]})
        self.assertEqual(caught.exception.issue,'unchanged_scope_changed')

    def test_changed_invalid_and_missing_runtime_are_data(self):
        path=self.root/'tools/rag/extract.py';original=path.read_bytes()
        for raw in (b'invalid Python !\n',b'raise RuntimeError("must not execute")\n',None):
            with self.subTest(raw=raw):
                if raw is None:path.unlink()
                else:path.write_bytes(raw)
                report=self.cli();self.assert_failed(report)
                self.assertEqual(report['issue'],'required_runtime_unavailable')
                row=next(r for r in report['runtime_observations'] if r['path']=='tools/rag/extract.py')
                self.assertEqual(row['outcome'],'missing' if raw is None else 'changed')
                path.write_bytes(original)

    def test_invalid_policy_and_corpus_return_framed_reports(self):
        policy=self.root/'tools/rag/config.toml';saved=policy.read_bytes();policy.write_bytes(b'invalid toml !')
        report=self.cli();self.assert_failed(report)
        policy.write_bytes(saved);self.corpus.write_bytes(b'invalid json !')
        report=self.cli();self.assert_failed(report)

    def instrument(self,args,denied='',human=False):
        with tempfile.TemporaryDirectory(prefix='cyrus-candidate-audit-') as directory:
            directory=Path(directory);(directory/'sitecustomize.py').write_text(fresh_process.BOOTSTRAP)
            env=dict(os.environ,PYTHONPATH=str(directory),PYTHONDONTWRITEBYTECODE='1',
                CYRUS_TEST_RUNTIME=str(self.root/'tools/rag'),CYRUS_TEST_RUNTIME_NAMES=json.dumps(list(retrieval.RUNTIME_FILES)),
                CYRUS_TEST_AUDIT=str(directory),CYRUS_TEST_ACCESS_DENIED=denied)
            result=subprocess.run(self.command(args,human),capture_output=True,env=env,timeout=140)
            events=[event for path in directory.glob('*.json') for event in json.loads(path.read_bytes())]
            return result,events,len(list(directory.glob('*.json')))

    def test_fresh_process_policy_precedes_helper_opens_and_imports(self):
        for name in ('extract.py','rules.py','catalog.py','integrity.py','contracts.py','locations.py','adapter_process.py'):
            with self.subTest(name=name):
                policy=self.root/'tools/rag/config.toml';saved=policy.read_bytes();self.deny('tools/rag/'+name)
                try:
                    result,events,interpreters=self.instrument(self.args())
                    self.assertEqual(result.stderr,b'');report=json.loads(result.stdout);self.assert_failed(report)
                    self.assertGreaterEqual(interpreters,2)
                    self.assertFalse([e for e in events if e['event']=='exec'])
                    self.assertFalse([e for e in events if Path(e['path']).name==name])
                    self.assertEqual(next(r for r in report['runtime_observations'] if r['path']=='tools/rag/'+name)['outcome'],'policy_blocked')
                finally:policy.write_bytes(saved)

    def test_fresh_process_inaccessible_runtime_is_an_observation(self):
        result,events,_=self.instrument(self.args(),'extract.py')
        self.assertEqual(result.stderr,b'');report=json.loads(result.stdout);self.assert_failed(report)
        self.assertFalse([e for e in events if e['event']=='exec'])
        self.assertEqual(next(r for r in report['runtime_observations'] if r['path']=='tools/rag/extract.py')['outcome'],'inaccessible')

    def test_denied_corpus_has_zero_content_opens(self):
        self.deny(self.corpus.relative_to(self.root).as_posix())
        report=self.cli();self.assert_failed(report)
        self.assertEqual(report['issue'],'required_runtime_unavailable')
        # A policy change also changes the installed runtime; preflight stops
        # before reaching the denied corpus rather than importing stale controls.

    def test_changed_evaluation_requires_separate_versioned_review(self):
        altered=copy.deepcopy(self.labels);altered['queries'][0]['required_evidence'][0]['alternatives'][0]['sha256']='0'*64
        dataset=self.write('tools/rag/fixture-labels-v2.json',json.dumps(altered))
        report=self.cli(self.args(evaluation=[dataset]));self.assert_failed(report)
        self.assertEqual(report['issue'],'evaluation_review_pending')

    def test_invalid_labels_retain_failure_and_built_indexes_without_readiness(self):
        # A corrupt historical definition cannot be smuggled in as unchanged.
        altered=copy.deepcopy(self.labels);altered['queries'][0]['required_evidence'][0]['alternatives'][0]['end_line']=999
        dataset=self.write('tools/rag/fixture-labels-v2.json',json.dumps(altered))
        review=self.write('tools/rag/fixture-label-review.json',json.dumps({'evaluations':[{
            'old_sha256':support.sha(self.dataset.read_bytes()),'new_sha256':support.sha(dataset.read_bytes()),
            'reason':'Deliberately invalid fixture locator; retain real validation failure'}]}))
        before=self.protected();args=self.args(evaluation=[dataset],review=review);report=self.cli(args)
        self.assert_failed(report);self.assertTrue(any(s['kind']=='build' and s['state']=='completed' for s in report['stages']))
        self.assertTrue(list((self.root/'_local/rag/evaluations').glob('.*.partial-*/failure.json')))
        self.assertEqual(before,self.protected());self.assertFalse(json.loads((args.out/'receipt.json').read_bytes())['mechanically_validated'])

    def test_question_semantics_and_denominators_cannot_be_rewritten(self):
        altered=copy.deepcopy(self.labels);altered['queries'][0]['query']='improved score query'
        with self.assertRaisesRegex(support.Blocked,'Question/qualifier'):
            support.compare_baseline({'questions':[]},{'questions':[]},self.labels,altered,True)

    def test_honest_question_level_regression_keeps_draft(self):
        _,old,labels=support.verify_evaluation_receipt(self.historical[0],json.loads((self.index/'run.json').read_bytes())['generation_id'],support.reader())
        changed=copy.deepcopy(old);changed['questions'][0]['scores']['at_k']['5']['found_units']=0
        result=support.compare_baseline(old,changed,labels,labels,True)
        self.assertFalse(result['passed']);self.assertTrue(result['question_differences']);self.assertTrue(result['regressions'])

    def test_real_changed_evidence_regression_retains_draft_and_full_comparison(self):
        self.write(self.current,self.body.replace('forRanges','missingIdentifier'))
        corpus,review_path=self.changed_definition([self.current])
        changed=copy.deepcopy(self.labels)
        changed['queries'][0]['required_evidence'][0]['alternatives'][0]['sha256']=support.sha((self.root/self.current).read_bytes())
        dataset=self.write('tools/rag/fixture-labels-v2.json',json.dumps(changed))
        review=json.loads(review_path.read_bytes());review['evaluations']=[{
            'old_sha256':support.sha(self.dataset.read_bytes()),'new_sha256':support.sha(dataset.read_bytes()),
            'reason':'Rechecked the same intended evidence and locator against the changed parent; query and requirements preserved'}]
        review_path.write_text(json.dumps(review))
        args=self.args(corpus=corpus,review=review_path,evaluation=[dataset]);report=self.cli(args)
        self.assertEqual(report['state'],'draft',report);self.assertEqual(report['issue'],'retrieval_regression')
        self.assertEqual(report['exit_code'],1);self.assert_failed(report)
        comparison=json.loads((args.out/'comparisons/d1-plain.json').read_bytes())
        self.assertFalse(comparison['passed']);self.assertTrue(comparison['question_differences'])
        self.assertTrue(comparison['regressions']);self.assertFalse(comparison['exact_definition_bytes_equal'])
        self.assertTrue(all(Path(p,'run.json').exists() for p in report['artifacts']['indexes']))

    def test_historical_snapshot_tampering_is_detected(self):
        snapshot=self.historical[0].parent/'labels-snapshot.json';labels=json.loads(snapshot.read_bytes())
        labels['queries'][0]['query']='altered';snapshot.write_text(json.dumps(labels))
        report=self.cli();self.assert_failed(report);self.assertEqual(report['issue'],'invalid_baseline_evaluation')

    def test_mutation_during_preparation_invalidates_receipt(self):
        args=self.args();before=self.protected()
        def mutate(task):
            if task['kind']=='audit':self.write(self.history,'changed during preparation\n')
        report=self.execute(args,mutate);self.assert_failed(report)
        self.assertEqual(report['issue'],'changed_input');self.assertEqual(before,self.protected())
        self.assertFalse(json.loads((args.out/'receipt.json').read_bytes())['mechanically_validated'])

    def test_mutation_after_build_before_validation_retains_complete_generation(self):
        args=self.args()
        def mutate(task):
            if task['kind']=='build':self.write(self.history,'changed after build\n')
        report=self.execute(args,mutate);self.assert_failed(report)
        self.assertEqual(report['issue'],'changed_input')
        index=Path(report['artifacts']['indexes'][0]);self.assertTrue(json.loads((index/'run.json').read_bytes())['complete'])
        self.assertFalse(any(s['kind']=='verify' and s['state']=='completed' for s in report['stages']))

    def test_restored_bytes_between_stages_still_invalidate_identity(self):
        _,_,seal,_=self.preflight();path=self.root/self.history;body=path.read_bytes()
        path.write_bytes(body+b'changed\n');path.write_bytes(body)
        with self.assertRaisesRegex(support.Blocked,'identity changed'):
            with mock.patch.object(support,'TOOL',self.root/'tools/rag'):preparation.checkpoint(self.root,seal)

    def test_wrong_root_and_existing_empty_destinations_are_rejected(self):
        report=self.cli(self.args(root=self.root.parent));self.assert_failed(report)
        args=self.args();args.out.mkdir(parents=True)
        report=self.cli(args);self.assertEqual(report['issue'],'existing_destination');self.assertEqual(list(args.out.iterdir()),[])
        args=self.args();(self.root/'_local/rag/indexes'/(args.run_id+'-candidate-01')).mkdir()
        report=self.cli(args);self.assertEqual(report['issue'],'existing_destination');self.assertFalse(args.out.exists())

    def test_output_containment_and_reparse_rejection(self):
        report=self.cli(self.args(out=self.root/'outside'));self.assert_failed(report);self.assertEqual(report['issue'],'unsafe_output')
        path=self.root/'linked';target=self.root/'docs'
        if os.name=='nt':
            result=subprocess.run(['cmd','/c','mklink','/J',str(path),str(target)],capture_output=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        else:path.symlink_to(target,target_is_directory=True)
        try:
            with self.assertRaisesRegex(support.Blocked,'reparse'):support.safe(path/'older.md')
        finally:path.rmdir() if os.name=='nt' else path.unlink()

    def test_competing_and_interrupted_ownership_never_take_over(self):
        owner=support.Ownership(self.root,'first');owner.acquire();before=owner.path.read_bytes()
        try:
            report=self.cli();self.assert_failed(report);self.assertEqual(report['issue'],'ownership_uncertain')
            self.assertEqual(owner.path.read_bytes(),before)
        finally:owner.release()
        lock=self.write('_local/rag/candidate-preparation.lock',json.dumps({'pid':999999999,'token':'interrupted'}))
        before=lock.read_bytes();report=self.cli();self.assert_failed(report)
        self.assertEqual(report['issue'],'ownership_uncertain');self.assertEqual(lock.read_bytes(),before)

    def test_cancellation_reaps_only_owned_stage_and_releases_owned_lock(self):
        args=self.args()
        with mock.patch.object(support,'TOOL',self.root/'tools/rag'),mock.patch.object(preparation,'stage_process',side_effect=KeyboardInterrupt):
            report=preparation.execute(args)
        self.assertEqual(report['exit_code'],130);self.assert_failed(report)
        self.assertFalse((self.root/'_local/rag/candidate-preparation.lock').exists())
        self.assertEqual(report['stages'][0]['state'],'unavailable')

    def test_real_stage_cancellation_does_not_kill_another_process(self):
        args=self.args();args.out.mkdir(parents=True)
        unrelated=subprocess.Popen([sys.executable,'-B','-c','import time;time.sleep(20)'],
                                   creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
        try:
            original=preparation.threading.Event.wait
            def interrupt(event,timeout=None):
                if timeout==.03:raise KeyboardInterrupt
                return original(event,timeout)
            with mock.patch.object(preparation.threading.Event,'wait',interrupt):
                with self.assertRaises(KeyboardInterrupt):
                    preparation.stage_process([sys.executable,'-B','-c','import time;time.sleep(20)'],
                        {'name':'cancelled-stage','root':str(self.root)},args.out,10)
            receipt=json.loads((args.out/'cancelled-stage.command.json').read_bytes())
            self.assertEqual(receipt['issue'],'cancelled');self.assertTrue(receipt['owned_worker_reaped'])
            self.assertIsNone(unrelated.poll())
        finally:unrelated.terminate();unrelated.wait(timeout=5)

    def test_total_timeout_competing_invocation_and_abandoned_lock(self):
        with tempfile.TemporaryDirectory(prefix='cyrus-owned-timeout-') as directory:
            directory=Path(directory);signal=directory/'stage-started'
            bootstrap='''import sys,json,time,os
from pathlib import Path
if Path(sys.argv[0]).name=='candidate_worker.py':
    task=json.loads(Path(sys.argv[1]).read_bytes())
    if task['kind']=='audit':
        Path(os.environ['CYRUS_STARTED']).write_text(str(os.getpid()))
        time.sleep(30)
'''
            (directory/'sitecustomize.py').write_text(bootstrap)
            args=self.args(stage_seconds=20,total_seconds=10)
            env=dict(os.environ,PYTHONPATH=str(directory),CYRUS_STARTED=str(signal))
            first=subprocess.Popen(self.command(args),stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env,
                                   creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
            try:
                deadline=time.monotonic()+8
                while not signal.exists() and first.poll() is None and time.monotonic()<deadline:time.sleep(.05)
                self.assertTrue(signal.exists(),'Owned worker did not reach the fixture gate')
                competing=self.cli();self.assertEqual(competing['issue'],'ownership_uncertain')
                stdout,stderr=first.communicate(timeout=15);self.assertEqual(stderr,b'')
                report=json.loads(stdout);self.assert_failed(report)
                self.assertEqual(report['issue'],'total_deadline_exceeded');self.assertTrue(report['owned_process_reaped'])
                lock=self.root/'_local/rag/candidate-preparation.lock';self.assertTrue(lock.exists())
                before=lock.read_bytes();retry=self.cli();self.assertEqual(retry['issue'],'ownership_uncertain')
                self.assertEqual(lock.read_bytes(),before)
                self.assertTrue((args.out/'interrupted-receipt.json').exists())
            finally:
                if first.poll() is None:first.kill();first.wait(timeout=5)

    def test_actual_sqlite_interrupt_is_unavailable_with_completed_checks(self):
        with tempfile.TemporaryDirectory(prefix='cyrus-sqlite-interrupt-') as directory:
            directory=Path(directory)
            bootstrap='''import sys,json,sqlite3
from pathlib import Path
if Path(sys.argv[0]).name=='candidate_worker.py' and json.loads(Path(sys.argv[1]).read_bytes())['kind']=='verify':
    original=sqlite3.connect
    class Interrupt(sqlite3.Connection):
        def set_progress_handler(self,callback,n):super().set_progress_handler(lambda:1,1)
    def connect(*args,**kwargs):
        kwargs['factory']=Interrupt
        return original(*args,**kwargs)
    sqlite3.connect=connect
'''
            (directory/'sitecustomize.py').write_text(bootstrap)
            report=self.cli(env=dict(os.environ,PYTHONPATH=str(directory)))
            self.assert_failed(report)
            stage=next(s for s in report['stages'] if s['kind']=='verify' and s['state']!='omitted')
            self.assertEqual(stage['state'],'unavailable');self.assertEqual(stage['issue'],'sqlite_unavailable')
            self.assertIn('recorded_parent_scope',stage['completed_checks'])
            self.assertNotIn('sqlite_metadata_identity',stage['completed_checks'])

    def test_stage_timeout_and_output_bounds_reap_owned_process(self):
        for code,issue in (('import time;time.sleep(10)','stage_deadline_exceeded'),
                           ('import sys,time;sys.stdout.buffer.write(b"x"*3000000);sys.stdout.flush();time.sleep(10)','captured_output_bound')):
            with self.subTest(issue=issue):
                args=self.args();directory=args.out;directory.mkdir(parents=True)
                task={'name':'owned-stage','root':str(self.root)}
                with self.assertRaises(support.Blocked) as caught:
                    preparation.stage_process([sys.executable,'-B','-c',code],task,directory,.5 if 'sleep(10)'==code[-9:] else 2)
                self.assertEqual(caught.exception.issue,issue)
                receipt=json.loads((directory/'owned-stage.command.json').read_bytes())
                self.assertTrue(receipt['owned_worker_reaped']);self.assertLess(receipt['wall_seconds'],6)
                self.assertLessEqual((directory/'owned-stage.stdout.log').stat().st_size,support.BOUNDS['captured_stream_bytes'])

    def test_build_failure_retains_partial_and_diagnostics(self):
        # Out-of-range candidate corpus passes identity review but must fail the
        # existing builder's range validation, leaving its real staging receipt.
        self.write(self.current,self.body+'\nReviewed new fixture context.\n')
        candidate=copy.deepcopy(self.definition);old_sha=candidate['sources'][0]['sha256']
        candidate['sources'][0]['sha256']=support.sha((self.root/self.current).read_bytes())
        candidate['sources'][0]['ranges']=[[1,999]]
        corpus=self.write('tools/rag/fixture-candidate-v2.json',json.dumps(candidate))
        flags={k:True for k in ('diff_inspected','ranges_checked','context_checked','applicability_checked',
                               'authority_checked','generated_ownership_checked','canonical_checked')}
        review=self.write('tools/rag/fixture-review-v2.json',json.dumps({'sources':[{'path':self.current,
            'old_sha256':old_sha,'new_sha256':candidate['sources'][0]['sha256'],
            'field_reasons':{'sha256':'Reviewed changed fixture parent','ranges':'Deliberately invalid fixture range'},**flags}],
            'corpus':{'old_sha256':support.sha(self.corpus.read_bytes()),'new_sha256':support.sha(corpus.read_bytes()),'reason':'Failure fixture'}}))
        report=self.cli(self.args(corpus=corpus,review=review));self.assert_failed(report)
        self.assertTrue(list((self.root/'_local/rag/indexes').glob('.*.partial-*/failure.json')))

    def test_corrupt_candidate_sqlite_has_no_passing_receipt(self):
        args=self.args()
        def corrupt(task):
            if task['kind']=='build':(Path(task['args']['out'])/'index.sqlite3').write_bytes(b'not SQLite')
        report=self.execute(args,corrupt);self.assert_failed(report)
        self.assertEqual(report['issue'],'invalid_publication')
        self.assertTrue(any(s['kind']=='build' and s['state']=='completed' for s in report['stages']))

    def test_invalid_sqlite_with_matching_fingerprint_is_distinct_from_interruption(self):
        args=self.args()
        def corrupt(task):
            if task['kind']=='build':
                index=Path(task['args']['out']);db=index/'index.sqlite3';raw=db.read_bytes()
                db.write_bytes(b'Invalid database'+raw[16:])
                receipt=json.loads((index/'run.json').read_bytes())
                receipt['artifact_sha256']['index.sqlite3']=support.sha(db.read_bytes())
                (index/'run.json').write_bytes(support.encoded(receipt))
        report=self.execute(args,corrupt);self.assert_failed(report)
        self.assertEqual(report['issue'],'invalid_publication')
        stage=next(s for s in report['stages'] if s['kind']=='verify' and s['state']!='omitted')
        self.assertNotEqual(stage['state'],'unavailable');self.assertIn('all_artifact_fingerprints',stage['completed_checks'])

    def test_json_and_human_failure_agree(self):
        (self.root/'tools/rag/extract.py').unlink()
        report=self.cli();human=self.cli(human=True)
        self.assertEqual(human.returncode,report['exit_code'])
        self.assertIn(report['state'],human.stdout.decode());self.assertIn(report['issue'],human.stdout.decode())

    def test_exclusive_receipts_prevent_inventory_collision(self):
        path=self.write('_local/rag/owned-inventory.json','original inventory')
        with self.assertRaises(FileExistsError):support.create(path,{'command':'must not replace inventory'})
        with self.assertRaises(FileExistsError):support.publish(path,{'command':'must not replace inventory'})
        self.assertEqual(path.read_text(),'original inventory')
        self.assertTrue(list(path.parent.glob('.owned-inventory.json.partial-*')))


if __name__=='__main__':unittest.main()
