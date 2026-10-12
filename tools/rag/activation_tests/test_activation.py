"""Owned real filesystem and SDK STDIO witnesses. No production apply calls."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import unittest
import uuid
from unittest import mock

TOOL=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(TOOL),str(TOOL/'candidate_tests'),str(TOOL/'refresh_tests'),str(TOOL/'tests')]
import activation_contract as c
import activate
import activation_verify as verification
import candidate_support as s
import test_candidate


class ActivationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture=test_candidate.CandidateTests('test_complete_unchanged_rehearsal_and_preservation')
        cls.fixture.setUp();f=cls.fixture;cls.root=f.root
        for name in c.OWN:f.write('tools/rag/'+name,(TOOL/name).read_bytes())
        cls.sdk=TOOL.parents[1]/'_local/rag/mcp-venv/Scripts/python.exe'
        # Inspect the fixture inputs before launching its candidate pipeline.
        assert cls.root.is_relative_to(TOOL.parents[1]/'_local/rag/test-data')
        assert s.detection.sealed_generation(cls.root,f.index,s.reader())[0]['source_count']==4
        args=f.args(stage_seconds=45,total_seconds=300)
        result=f.cli(args)
        assert result['exit_code']==0,result
        cls.evidence=args.out/'receipt.json';cls.target=Path(result['artifacts']['indexes'][0]);cls.baseline=f.index
        cls.review=f.write('review-packet.txt','Fixture-only semantic packet; operator simulation, no human consent.\n')
        f.write('ACTIVATION_FIXTURE.json',json.dumps({'schema':'cyrus.activation-fixture/1','root':str(cls.root),'warning':'TEST ONLY; NEVER PRODUCTION CONSENT'}))
        cls.registration=f.registration
        cls.config=("# unrelated secret-like setting preserved byte for byte\r\nother = 'fixture-only'\r\n"
            "[mcp_servers.other]\r\ncommand = 'never-started'\r\n\r\n[mcp_servers.cyrus_knowledge]\r\n"
            "command = '"+str(cls.sdk)+"'\r\nargs = ['-B', '"+str(cls.root/'tools/rag/adapter.py')+"', '--root', '"+str(cls.root)+"', '--index', '"+str(cls.baseline)+"'] # retain comment\r\n"
            "cwd = '"+str(cls.root)+"'\r\nenabled_tools = ['knowledge_search', 'knowledge_status']\r\n").encode()
        cls.serial=0
    @classmethod
    def tearDownClass(cls):cls.fixture.tearDown()
    def setUp(self):
        self.registration.write_bytes(self.config)
        self.originals={}
    def tearDown(self):
        for path,raw in self.originals.items():path.write_bytes(raw)
        self.registration.write_bytes(self.config)
        lock=self.root/'_local/rag/activation.lock'
        if lock.exists():
            # Test owns the disposable root and has waited for its child to exit.
            self.assertTrue(self.root.is_relative_to(TOOL.parents[1]/'_local/rag/test-data'));lock.unlink()
    def change(self,path,raw):
        if path not in self.originals:self.originals[path]=path.read_bytes()
        path.write_bytes(raw)
    def out(self):
        type(self).serial+=1
        return self.root/'_local/rag/activations'/('fixture-op-'+str(self.serial))
    def command(self,operation,output=None,**kwargs):
        output=output or self.out()
        args=[sys.executable,'-B',str(TOOL/'activate.py'),operation,'--root',str(self.root),'--out',str(output),'--fixture','--json']
        for name,value in kwargs.items():
            if value is not None:args.extend(['--'+name.replace('_','-'),str(value)])
        completed=subprocess.run(args,stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=200,
            env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1'))
        self.assertEqual(completed.stderr,b'');result=json.loads(completed.stdout)
        self.assertEqual(completed.returncode,result['exit_code']);return result,output
    def prepare(self,action='activate',target=None,**kwargs):
        return self.command('prepare',action=action,target=target or self.target,evidence=self.evidence,review=self.review,**kwargs)
    def consent(self,plan,**updates):
        value=c.read_json(plan)
        record={'schema':'cyrus.activation-fixture-approval/1','root':str(self.root),'plan_sha256':c.fingerprint(plan)['sha256'],
            'target_generation':value['target_generation'],'action':value['action'],'warning':'TEST ONLY; NEVER PRODUCTION CONSENT'}
        record.update(updates);path=self.root/('approval-'+uuid.uuid4().hex+'.json');s.create(path,record);return path
    def ready(self):
        result,out=self.prepare();self.assertEqual(result['exit_code'],0,result);return out/'plan.json'
    def apply(self,plan,**kwargs):return self.command('apply',plan=plan,fixture_approval=self.consent(plan),**kwargs)
    def test_01_real_stdio_activation_rollback_and_byte_preservation(self):
        plan=self.ready();self.assertEqual(self.registration.read_bytes(),self.config)
        result,out=self.apply(plan);self.assertEqual(result['state'],'configuration_switched_verified',result)
        expected=self.config.replace(("'"+str(self.baseline)+"'").encode(),("'"+str(self.target)+"'").encode())
        self.assertEqual(self.registration.read_bytes(),expected)
        self.assertEqual((out/'prior-config.bin').read_bytes(),self.config)
        self.assertTrue(c.read_json(out/'knowledge_status-response.json')['result']['structuredContent']['all_sources_verified'])
        rollback,ro=self.prepare('rollback',self.baseline);self.assertEqual(rollback['exit_code'],0,rollback)
        result,_=self.apply(ro/'plan.json');self.assertEqual(result['state'],'previous_binding_restored',result)
        self.assertTrue(result['previous_binding_currently_usable']);self.assertEqual(self.registration.read_bytes(),self.config)
    def test_missing_approval_cannot_mutate_or_create_outputs(self):
        plan=self.ready();result,out=self.command('apply',plan=plan)
        self.assertEqual(result['issue'],'human_confirmation_required');self.assertFalse(out.exists())
        self.assertEqual(self.registration.read_bytes(),self.config)
    def test_wrong_root_plan_and_target_approval(self):
        plan=self.ready()
        for field,value in (('root',str(self.root.parent)),('plan_sha256','0'*64),('target_generation','0'*64),('action','rollback')):
            with self.subTest(field=field):
                record=self.consent(plan,**{field:value});result,_=self.command('apply',plan=plan,fixture_approval=record)
                self.assertEqual(result['issue'],'approval_mismatch');self.assertEqual(self.registration.read_bytes(),self.config)
    def test_fixture_approval_cannot_authorize_production_root(self):
        with self.assertRaises(s.Blocked) as cm:activate.validate_root(TOOL.parents[1],True)
        self.assertEqual(cm.exception.issue,'fixture_only')
    def test_private_worker_discards_supplied_consent_and_requires_terminal(self):
        plan=self.ready();request={'root':str(self.root),'out':str(self.out()),'operation':'apply','fixture':False,
            'plan':str(plan),'fixture_approval':None,'approval':{'kind':'interactive_human_confirmation','plan_sha256':c.fingerprint(plan)['sha256']}}
        # A production-root check would reject this fixture first. Patch only
        # root enrollment in-process; exercise the actual private worker branch,
        # which must discard the supplied claim and call the terminal contract.
        token=__import__('uuid').uuid4().hex;gate=self.root/'_local/rag/activations'/('.start-'+token+'.json')
        s.create(gate,{'request':request,'token':token})
        import io
        class Output:
            def __init__(self):self.buffer=io.BytesIO()
        output=Output()
        with (mock.patch.object(activate,'validate_root',return_value=self.root),mock.patch.object(activate.sys,'stdin',io.StringIO('')),
                mock.patch.object(activate.sys,'stdout',output)):
            code=activate.main(['--_worker',str(gate)])
        self.assertEqual(code,2);self.assertEqual(json.loads(output.buffer.getvalue())['issue'],'human_confirmation_required')
        self.assertEqual(self.registration.read_bytes(),self.config);self.assertFalse(Path(request['out']).exists())
    def test_configuration_edit_invalidates_ready_plan(self):
        plan=self.ready();self.registration.write_bytes(self.config+b'# later editor\r\n')
        result,_=self.apply(plan);self.assertEqual(result['issue'],'configuration_changed')
        self.assertEqual(self.registration.read_bytes(),self.config+b'# later editor\r\n')

    def delegated(self,plan,**updates):
        value=c.read_json(plan)
        record={'schema':'cyrus.delegated-activation/1','root':str(self.root),
            'plan_sha256':c.fingerprint(plan)['sha256'],'target_generation':value['target_generation'],
            'action':value['action'],'review_packet_sha256':value['review_packet_sha256'],
            'semantic_review':'agent; human review not performed',
            'user_instruction':'TEST ONLY: simulated delegation in an owned disposable repository',
            'decision_reason':'TEST ONLY: exact packet reviewed; no production approval represented'}
        record.update(updates)
        path=self.root/'_local/rag/activations'/('delegated-'+uuid.uuid4().hex+'.json')
        s.create(path,record);return path

    def test_delegated_authorization_is_explicit_and_not_human_confirmation(self):
        plan=self.ready()
        result,out=self.command('apply',plan=plan,delegated_approval=self.delegated(plan))
        self.assertEqual(result['state'],'configuration_switched_verified',result)
        witness=c.read_json(out/'approval-witness.json')
        self.assertEqual(witness['kind'],'delegated_user_authorization')
        self.assertEqual(witness['semantic_review'],'agent; human review not performed')

    def test_delegated_authorization_rejects_other_packet_or_target(self):
        plan=self.ready()
        for change in ({'review_packet_sha256':'0'*64},{'target_generation':'0'*64},
                       {'semantic_review':'human accepted'},{'user_instruction':''}):
            with self.subTest(change=change):
                result,_=self.command('apply',plan=plan,delegated_approval=self.delegated(plan,**change))
                self.assertEqual(result['issue'],'approval_mismatch',result)
                self.assertEqual(self.registration.read_bytes(),self.config)
    def test_competing_and_abandoned_ownership_are_not_taken_over(self):
        lock=self.root/'_local/rag/activation.lock';s.create(lock,{'pid':99999999,'token':'unknown'})
        result,out=self.prepare();self.assertEqual(result['issue'],'ownership_uncertain');self.assertFalse(out.exists())
        self.assertEqual(c.read_json(lock)['token'],'unknown')
    def test_missing_corrupt_runtime_corpus_and_stale_targets(self):
        cases=[(self.target/'chunks.jsonl',b'corrupt'),(self.root/'tools/rag/ranking-v2.1.json',b'{}'),
               (self.fixture.corpus,self.fixture.corpus.read_bytes()+b' '),(self.root/self.fixture.unknown,b'changed unreturned parent')]
        for path,body in cases:
            with self.subTest(path=path):
                original=path.read_bytes();self.change(path,body);result,_=self.prepare();self.assertNotEqual(result['exit_code'],0,result)
                self.assertEqual(self.registration.read_bytes(),self.config);path.write_bytes(original)
        artifact=self.target/'chunks.jsonl';moved=artifact.with_suffix('.held');artifact.rename(moved)
        try:result,_=self.prepare();self.assertNotEqual(result['exit_code'],0)
        finally:moved.rename(artifact)
    def test_current_policy_denial_blocks_before_target_parent_access(self):
        policy=self.root/'tools/rag/config.toml';raw=policy.read_bytes()
        self.change(policy,raw.replace(b'skip_path_patterns = [',b'skip_path_patterns = ["docs/ARTIST_GUIDE.md", '))
        result,_=self.prepare();self.assertNotEqual(result['exit_code'],0);self.assertEqual(self.registration.read_bytes(),self.config)
    def test_incomplete_candidate_and_failed_stage_evidence(self):
        raw=self.evidence.read_bytes();record=json.loads(raw);record['mechanically_validated']=False
        self.change(self.evidence,s.encoded(record));result,_=self.prepare();self.assertEqual(result['issue'],'incomplete_evidence')
        self.evidence.write_bytes(raw)
        p=self.evidence.parent/'stages/01-audit.command.json';record=c.read_json(p);record['exit_code']=2
        self.change(p,s.encoded(record));result,_=self.prepare();self.assertEqual(result['issue'],'incomplete_evidence')
    def test_evaluation_corruption_blocks(self):
        receipt=c.read_json(self.evidence);p=Path(next(s['value']['full_metrics'] for s in receipt['stages'] if s['kind']=='evaluate'))
        self.change(p,p.read_bytes()+b' ');result,_=self.prepare();self.assertNotEqual(result['exit_code'],0)
    def test_valid_receipts_with_real_score_regression_are_rejected(self):
        receipt=c.read_json(self.evidence)
        rows=[r for r in receipt['stages'] if r['kind']=='evaluate' and r['value']['profile']=='plain']
        for row in rows:
            path=Path(row['value']['full_metrics']);results=c.read_json(path)
            results['questions'][0]['scores']['at_k']['10']['found_units']=0
            raw=s.encoded(results);self.change(path,raw)
            run=path.parent/'run.json';record=c.read_json(run);record['results_sha256']=s.sha(raw);self.change(run,s.encoded(record))
        result,_=self.prepare();self.assertEqual(result['issue'],'retrieval_regression',result)
    def test_link_reparse_target_is_rejected(self):
        link=self.root/'_local/rag/indexes/fixture-junction'
        if os.name=='nt':
            completed=subprocess.run(['cmd','/c','mklink','/J',str(link),str(self.target)],capture_output=True,timeout=5)
            self.assertEqual(completed.returncode,0,completed.stderr)
        else:link.symlink_to(self.target,target_is_directory=True)
        try:
            result,_=self.prepare(target=link);self.assertEqual(result['issue'],'unsafe_path')
        finally:
            if os.name=='nt':os.rmdir(link)
            else:link.unlink()
    def test_wrong_root_unsupported_layout_and_ambiguous_flags(self):
        for body in (self.config.replace(b"'--index',",b"'--index', '--index',"),
                self.config.replace(b"args = [",b"args = [\r\n"),self.config.replace(str(self.root).encode(),str(self.root.parent).encode())):
            self.registration.write_bytes(body);result,_=self.prepare();self.assertNotEqual(result['exit_code'],0)
            self.assertEqual(self.registration.read_bytes(),body)
        self.registration.write_bytes(self.config)
        result,_=self.prepare(target=TOOL.parents[1]/'_local/rag/indexes/20261012-phase3-acceptance-final-02');self.assertEqual(result['issue'],'wrong_root')
    def test_existing_outputs_and_receipts_never_overwritten(self):
        result,out=self.prepare();before={p.name:p.read_bytes() for p in out.iterdir() if p.is_file()}
        result,_=self.prepare(output=out);self.assertNotEqual(result['exit_code'],0)
        self.assertEqual(before,{p.name:p.read_bytes() for p in out.iterdir() if p.is_file()})
        with self.assertRaises(FileExistsError):s.publish(out/'receipt.json',{})
    def test_interruption_before_replace_leaves_configuration_unchanged(self):
        plan=self.ready();result,out=self.apply(plan,fixture_fault='before_replace')
        self.assertEqual(result['state'],'interrupted_configuration_unknown');self.assertEqual(self.registration.read_bytes(),self.config)
        self.assertTrue((out/'journal-prepared.json').exists());self.assertTrue((self.root/'_local/rag/activation.lock').exists())
    def test_interruption_after_replace_is_observed_as_changed(self):
        plan=self.ready();result,out=self.apply(plan,fixture_fault='after_replace')
        self.assertEqual(result['state'],'interrupted_configuration_unknown');self.assertNotEqual(self.registration.read_bytes(),self.config)
        self.assertEqual(c.configuration(self.root)[0]['index'],str(self.target))
        self.assertFalse((out/'journal-replaced.json').exists());self.assertTrue((out/'prior-config.bin').exists())
    def test_after_confirmation_recovery_reverifies_previous_binding(self):
        plan=self.ready();result,out=self.apply(plan,fixture_fault='after_confirmation')
        self.assertNotEqual(self.registration.read_bytes(),self.config)
        (self.root/'_local/rag/activation.lock').unlink() # known dead owned fixture PID
        result,ro=self.prepare('rollback',self.baseline);self.assertEqual(result['exit_code'],0,result)
        result,_=self.apply(ro/'plan.json',recover_from=out);self.assertEqual(result['state'],'previous_binding_restored',result)
        self.assertEqual(self.registration.read_bytes(),self.config)
    def test_consumer_failure_after_switch_and_later_edit_block_recovery(self):
        plan=self.ready();result,out=self.apply(plan,fixture_fault='consumer_failure')
        self.assertEqual(result['state'],'configuration_switched_consumer_pending',result);self.assertNotEqual(self.registration.read_bytes(),self.config)
        self.registration.write_bytes(self.registration.read_bytes()+b'# later edit\r\n');later=self.registration.read_bytes()
        result,ro=self.prepare('rollback',self.baseline);self.assertEqual(result['exit_code'],0,result)
        result,_=self.apply(ro/'plan.json',recover_from=out);self.assertEqual(result['issue'],'recovery_blocked')
        self.assertEqual(self.registration.read_bytes(),later)
    def test_changed_input_after_plan_blocks_apply(self):
        plan=self.ready();self.change(self.review,self.review.read_bytes()+b'new decision')
        result,_=self.apply(plan);self.assertEqual(result['issue'],'changed_input');self.assertEqual(self.registration.read_bytes(),self.config)
    def test_staging_change_invalidates_plan(self):
        plan=self.ready();path=self.root/'.git/index';self.originals[path]=path.read_bytes()
        self.fixture.write('stage-fixture.txt','owned staging mutation\n');self.fixture.git('add','stage-fixture.txt')
        result,_=self.apply(plan);self.assertEqual(result['issue'],'git_changed',result);self.assertEqual(self.registration.read_bytes(),self.config)
    def test_concurrent_edit_before_and_after_replace_is_preserved(self):
        for phase in ('before_replace','after_replace'):
            self.registration.write_bytes(self.config);binding,raw,_=c.configuration(self.root)
            output=self.out();output.mkdir(parents=True);owner=c.Ownership(self.root,'editor-fixture');owner.acquire()
            def edit(stage):
                if stage==phase:self.registration.write_bytes(self.registration.read_bytes()+b'# external editor\r\n')
            try:
                with self.assertRaises(s.Blocked) as cm:c.publish_config(self.root,binding,raw,c.replacement(self.root,binding,raw,self.target),output,owner,edit)
                self.assertEqual(cm.exception.issue,'configuration_changed' if phase=='before_replace' else 'post_write_conflict')
                self.assertTrue(self.registration.read_bytes().endswith(b'# external editor\r\n'))
            finally:owner.release()
    def test_restored_old_bytes_after_replace_are_not_reported_as_unchanged(self):
        plan=self.ready();value=c.read_json(plan);output=self.out()
        request={'root':str(self.root),'out':str(output),'operation':'apply','fixture':True,'plan':str(plan),
            'approval':{'kind':'fixture_simulation','plan_sha256':c.fingerprint(plan)['sha256'],'root':str(self.root),
                'target_generation':value['target_generation'],'action':'activate'}}
        original=c.publish_config
        def publish(root,binding,raw,after,out,owner,checkpoint):
            def restore(stage):
                checkpoint(stage)
                if stage=='after_replace':self.registration.write_bytes(raw)
            return original(root,binding,raw,after,out,owner,restore)
        with mock.patch.object(c,'publish_config',side_effect=publish):result=activate.execute(request,'restore-fixture')
        self.assertEqual(result['state'],'recovery_blocked',result);self.assertTrue(result['configuration_may_have_changed'])
        self.assertEqual(self.registration.read_bytes(),self.config)
    def test_actual_atomic_replace_io_failure_retains_prior_config(self):
        binding,raw,_=c.configuration(self.root);out=self.out();out.mkdir(parents=True);owner=c.Ownership(self.root,'io-fixture');owner.acquire()
        try:
            with mock.patch.object(c.os,'replace',side_effect=PermissionError('fixture denied')):
                with self.assertRaises(PermissionError):c.publish_config(self.root,binding,raw,c.replacement(self.root,binding,raw,self.target),out,owner,lambda _:None)
            self.assertEqual(self.registration.read_bytes(),raw);self.assertTrue((out/'prior-config.bin').exists())
        finally:owner.release()
    def test_windows_sharing_denial_at_real_replace_retains_config(self):
        if os.name!='nt':self.skipTest('Windows file sharing contract')
        import ctypes
        from ctypes import wintypes
        kernel=ctypes.WinDLL('kernel32',use_last_error=True)
        kernel.CreateFileW.argtypes=[wintypes.LPCWSTR,wintypes.DWORD,wintypes.DWORD,ctypes.c_void_p,wintypes.DWORD,wintypes.DWORD,wintypes.HANDLE]
        kernel.CreateFileW.restype=wintypes.HANDLE;kernel.CloseHandle.argtypes=[wintypes.HANDLE]
        handle=kernel.CreateFileW(str(self.registration),0x80000000,3,None,3,0,None)
        self.assertNotEqual(handle,ctypes.c_void_p(-1).value)
        binding,raw,_=c.configuration(self.root);out=self.out();out.mkdir(parents=True);owner=c.Ownership(self.root,'sharing-fixture');owner.acquire()
        try:
            with self.assertRaises(PermissionError):c.publish_config(self.root,binding,raw,c.replacement(self.root,binding,raw,self.target),out,owner,lambda _:None)
            self.assertEqual(self.registration.read_bytes(),raw);self.assertTrue((out/'prior-config.bin').exists())
        finally:kernel.CloseHandle(handle);owner.release()
    def test_deadline_terminates_owned_worker_only(self):
        unrelated=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)'])
        try:
            result,_=self.prepare(seconds=1);self.assertEqual(result['issue'],'deadline_exceeded',result)
            self.assertIsNone(unrelated.poll());self.assertTrue(result['owned_process_reaped'])
        finally:unrelated.terminate();unrelated.wait(timeout=3)
    def test_cancellation_reaps_owned_process(self):
        from refresh_boundary import WorkerJob
        request={'root':str(self.root),'out':str(self.out()),'operation':'prepare','fixture':True,
            'action':'activate','target':str(self.target),'evidence':str(self.evidence),'review':str(self.review)}
        with mock.patch.object(activate.time,'monotonic',side_effect=KeyboardInterrupt):
            # Before spawn is still a real cancellation; deeper process witness
            # below raises after an owned job has been created.
            with self.assertRaises(KeyboardInterrupt):activate.guarded(request,90)
        original=WorkerJob
        with mock.patch.object(activate,'WorkerJob',side_effect=lambda pid: original(pid)):
            with mock.patch.object(activate.threading.Event,'wait',side_effect=KeyboardInterrupt):result=activate.guarded(request,90)
        self.assertEqual(result['issue'],'cancelled');self.assertTrue(result['owned_process_reaped'])
    def test_stale_active_does_not_prevent_fresh_successor_but_rollback_fails(self):
        # A separate real candidate pipeline owns the changed fixture parents.
        old=(self.root/self.fixture.unknown).read_bytes();self.change(self.root/self.fixture.unknown,old+b'\nReviewed update.\n')
        corpus,review=self.fixture.changed_definition([self.fixture.unknown])
        result=self.fixture.cli(self.fixture.args(corpus=corpus,review=review,stage_seconds=45,total_seconds=300))
        self.assertEqual(result['exit_code'],0,result)
        target=Path(result['artifacts']['indexes'][0]);evidence=Path(result['output'])/'receipt.json'
        result,out=self.command('prepare',action='activate',target=target,evidence=evidence,review=self.review)
        self.assertEqual(result['exit_code'],0,result)
        plan=c.read_json(out/'plan.json');self.assertEqual(plan['previous_condition']['source_freshness']['state'],'stale')
        result,_=self.command('prepare',action='rollback',target=self.baseline,evidence=evidence,review=self.review)
        self.assertNotEqual(result['exit_code'],0);self.assertEqual(self.registration.read_bytes(),self.config)


if __name__=='__main__':unittest.main()
