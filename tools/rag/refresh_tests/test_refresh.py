"""Observable Phase 4A behavior in disposable repositories; production inputs stay untouched."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import threading
import unittest
from unittest import mock

TOOL=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(TOOL),str(TOOL/'tests')]
import refresh_inspect as detector
import refresh_status as cli
import retrieval
import test_retrieval as fixtures
import fresh_process


class RefreshTests(unittest.TestCase):
    git=fixtures.RetrievalFixtures.git
    scan=fixtures.RetrievalFixtures.scan
    read_rows=fixtures.RetrievalFixtures.read_rows
    build=fixtures.RetrievalFixtures.build
    tearDown=fixtures.RetrievalFixtures.tearDown

    def write(self,path,content):
        target=self.root/path;target.parent.mkdir(parents=True,exist_ok=True)
        if isinstance(content,bytes):target.write_bytes(content)
        else:target.write_text(content,encoding='utf-8',newline='\n')
        return target

    def setUp(self):
        fixtures.RetrievalFixtures.setUp(self)
        for name in retrieval.RUNTIME_FILES:
            self.write('tools/rag/'+name,(TOOL/name).read_bytes())
        self.git('add',self.current)
        self.git('commit','-qm','Track owned detector fixture parent')
        self.index=self.build()
        self.registration=self.write('.codex/config.toml',
            "[mcp_servers.cyrus_knowledge]\nargs = "+json.dumps(['--root',str(self.root),'--index',str(self.index)])+'\n')

    def inspect(self):return detector.inspect(self.root,self.index)

    def outcomes(self,report):return {r['path']:r for r in report['parents']}

    def protected(self):
        paths=[*self.index.iterdir(),self.corpus,self.registration]
        return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths if p.is_file()}

    def deny(self,path):
        policy=self.root/'tools/rag/config.toml'
        policy.write_text(policy.read_text(encoding='utf-8').replace('skip_path_patterns = [','skip_path_patterns = ['+json.dumps(path)+', '),encoding='utf-8')

    def copy_detector(self):
        for name in detector.IMPLEMENTATION_FILES:
            self.write('tools/rag/'+name,(TOOL/name).read_bytes())
        return self.root/'tools/rag/refresh_status.py'

    def fresh_cli(self,access_denied='',human=False):
        before=self.protected()
        result,events,interpreters=fresh_process.run(self.copy_detector(),self.root,self.index,
                                                    retrieval.RUNTIME_FILES,access_denied,human)
        self.assertEqual(before,self.protected())
        self.assertEqual(result.stderr,b'',result.stderr)
        self.assertEqual(interpreters,2,'Audit must run before imports in parent and worker')
        self.assertFalse([e for e in events if e['event']=='exec'],'Inspected runtime code executed')
        if human:return result,events
        report=json.loads(result.stdout)
        self.assertEqual(report['schema'],detector.SCHEMA)
        self.assertEqual(result.returncode,report['exit_code'])
        self.assertEqual(report['generation_integrity']['state'],'valid')
        self.assertEqual(report['source_freshness']['unchanged'],4)
        self.assertEqual(report['consumer_binding']['state'],'matches')
        self.assertEqual(set(report['detector']['implementation_sha256']),set(detector.IMPLEMENTATION_FILES))
        return report,events

    def test_fresh_process_denied_helpers_have_zero_opens_or_transitive_execution(self):
        # Each historically imported dependency is individually denied, including
        # rules itself and adapter_process in the parent CLI startup path.
        for name in ('extract.py','rules.py','catalog.py','integrity.py','contracts.py','locations.py','adapter_process.py'):
            with self.subTest(helper=name):
                policy=self.root/'tools/rag/config.toml';saved=policy.read_bytes()
                self.deny('tools/rag/'+name)
                before=self.protected()
                try:
                    report,events=self.fresh_cli()
                    self.assertFalse([e for e in events if Path(e['path']).name.startswith(name[:-3]+'.')])
                    row=next(r for r in report['inputs'] if r['path']=='tools/rag/'+name)
                    self.assertEqual(row['outcome'],'policy_blocked');self.assertIsNone(row['observed_sha256'])
                    self.assertEqual(report['exit_code'],2);self.assertEqual(before,self.protected())
                finally:policy.write_bytes(saved)

    def test_fresh_process_missing_helpers_return_json_without_corruption(self):
        for name in ('extract.py','rules.py','catalog.py','integrity.py','contracts.py','locations.py','adapter_process.py'):
            with self.subTest(helper=name):
                path=self.root/'tools/rag'/name;saved=path.read_bytes();path.unlink()
                try:
                    report,_=self.fresh_cli()
                    row=next(r for r in report['inputs'] if r['path']=='tools/rag/'+name)
                    self.assertEqual(row['outcome'],'missing');self.assertIsNone(row['observed_sha256'])
                    self.assertEqual(report['compatibility']['state'],'incompatible');self.assertEqual(report['exit_code'],1)
                finally:path.write_bytes(saved)

    def test_fresh_process_unusable_and_inaccessible_helpers_are_data(self):
        # Syntax errors and executable failure payloads cannot become startup code.
        for name,raw in (('extract.py',b'invalid Python !\n'),('rules.py',b'raise RuntimeError("must never execute")\n'),
                         ('adapter_process.py',b'from extract import forbidden_transitive_import\n')):
            with self.subTest(helper=name):
                path=self.root/'tools/rag'/name;saved=path.read_bytes();path.write_bytes(raw)
                try:
                    report,_=self.fresh_cli()
                    row=next(r for r in report['inputs'] if r['path']=='tools/rag/'+name)
                    self.assertEqual(row['outcome'],'changed');self.assertEqual(report['exit_code'],1)
                finally:path.write_bytes(saved)
        report,events=self.fresh_cli(access_denied='extract.py')
        self.assertTrue(any(Path(e['path']).name=='extract.py' for e in events))
        self.assertEqual(next(r for r in report['inputs'] if r['path']=='tools/rag/extract.py')['outcome'],'inaccessible')
        self.assertEqual(report['exit_code'],2)

    def test_fresh_process_human_missing_helper_agrees_with_json(self):
        (self.root/'tools/rag/extract.py').unlink()
        report,_=self.fresh_cli();result,_=self.fresh_cli(human=True)
        self.assertEqual(result.returncode,report['exit_code'])
        text=result.stdout.decode('utf-8')
        self.assertIn('integrity: valid',text);self.assertIn('tools/rag/extract.py: missing',text)
        self.assertIn('Integrity unfinished/omitted:',text)

    def test_sqlite_real_deadline_interrupt_is_unavailable_with_completed_checks(self):
        readers=[];original_reader=detector.Reader;original_connect=detector.sqlite3.connect;interrupts=[]
        def reader():
            instance=original_reader();readers.append(instance);return instance
        class Connection:
            def __init__(self,connection):self.connection=connection
            def __getattr__(self,name):return getattr(self.connection,name)
            def set_progress_handler(self,callback,n):
                readers[-1].deadline=0
                self.connection.set_progress_handler(callback,1)
            def execute(self,*args):
                try:return self.connection.execute(*args)
                except detector.sqlite3.Error as exc:
                    interrupts.append(exc.sqlite_errorcode);raise
        before=self.protected()
        with mock.patch.object(detector,'Reader',side_effect=reader),mock.patch.object(detector.sqlite3,'connect',side_effect=lambda *a,**k:Connection(original_connect(*a,**k))):
            report=self.inspect()
        self.assertIn(detector.sqlite3.SQLITE_INTERRUPT,interrupts)
        integrity=report['generation_integrity']
        self.assertEqual(integrity['state'],'unavailable');self.assertEqual(integrity['completeness'],'incomplete')
        self.assertEqual(integrity['issue'],'deadline_exceeded');self.assertIn('deadline',integrity['reason'])
        self.assertIn('recorded_parent_scope',integrity['completed_checks'])
        self.assertNotIn('sqlite_metadata_identity',integrity['completed_checks'])
        self.assertIn('sqlite_metadata_identity',integrity['omitted_checks'])
        self.assertEqual(report['exit_code'],2);self.assertEqual(before,self.protected())

    def test_sqlite_non_deadline_operational_error_is_not_a_timeout(self):
        # Exercise an actual SQLite query error without changing any artifact.
        original=detector.sqlite3.connect
        class Connection:
            def __init__(self,connection):self.connection=connection
            def __getattr__(self,name):return getattr(self.connection,name)
            def execute(self,sql,*args):
                return self.connection.execute('SELECT * FROM missing_review_table' if sql=='SELECT value FROM metadata' else sql,*args)
        with mock.patch.object(detector.sqlite3,'connect',side_effect=lambda *a,**k:Connection(original(*a,**k))):report=self.inspect()
        self.assertEqual(report['generation_integrity']['state'],'invalid')
        self.assertEqual(report['generation_integrity']['issue'],'internal_inconsistency')
        self.assertNotIn('deadline',report['generation_integrity']['reason'])

    def test_sqlite_interrupt_without_deadline_is_explicit_uncertainty(self):
        original=detector.sqlite3.connect
        class Connection:
            def __init__(self,connection):self.connection=connection
            def __getattr__(self,name):return getattr(self.connection,name)
            def set_progress_handler(self,callback,n):self.connection.set_progress_handler(lambda:1,1)
        with mock.patch.object(detector.sqlite3,'connect',side_effect=lambda *a,**k:Connection(original(*a,**k))):report=self.inspect()
        self.assertEqual(report['generation_integrity']['state'],'unavailable')
        self.assertEqual(report['generation_integrity']['issue'],'verification_interrupted')
        self.assertEqual(report['exit_code'],2)

    def test_sqlite_late_deadline_retains_completed_database_checks_and_human_reason(self):
        import contextlib
        import io
        readers=[];original_reader=detector.Reader;original_connect=detector.sqlite3.connect
        def reader():
            instance=original_reader();readers.append(instance);return instance
        class Connection:
            def __init__(self,connection):self.connection=connection
            def __getattr__(self,name):return getattr(self.connection,name)
            def execute(self,sql,*args):
                if sql.startswith('SELECT id,path'):
                    readers[-1].deadline=0
                    self.connection.set_progress_handler(lambda:1,1)
                return self.connection.execute(sql,*args)
        with mock.patch.object(detector,'Reader',side_effect=reader),mock.patch.object(detector.sqlite3,'connect',side_effect=lambda *a,**k:Connection(original_connect(*a,**k))):report=self.inspect()
        self.assertEqual(report['generation_integrity']['issue'],'deadline_exceeded')
        self.assertIn('sqlite_metadata_identity',report['generation_integrity']['completed_checks'])
        self.assertIn('sqlite_quick_check',report['generation_integrity']['completed_checks'])
        self.assertIn('all_searchable_rows_and_fts_text',report['generation_integrity']['omitted_checks'])
        output=io.StringIO()
        with mock.patch.object(cli,'guarded',return_value=report),contextlib.redirect_stdout(output):
            result=cli.main(['--root',str(self.root),'--index',str(self.index)])
        self.assertEqual(result,2);self.assertIn('integrity: unavailable',output.getvalue())
        self.assertIn('SQLite verification deadline reached',output.getvalue())
        self.assertIn('Integrity unfinished/omitted: all_searchable_rows_and_fts_text',output.getvalue())

    def test_sqlite_corrupt_bytes_are_rejected_even_with_matching_artifact_receipt(self):
        # Distinguish real database validation from the earlier hash-mismatch test.
        db=self.index/'index.sqlite3';raw=db.read_bytes()
        db.write_bytes(b'Invalid database'+raw[16:])
        path=self.index/'run.json';run=json.loads(path.read_bytes())
        run['artifact_sha256']['index.sqlite3']=detector.sha(db.read_bytes())
        path.write_bytes(detector.encoded(run));before=self.protected()
        report=self.inspect();integrity=report['generation_integrity']
        self.assertEqual(integrity['state'],'invalid');self.assertEqual(integrity['issue'],'internal_inconsistency')
        self.assertIn('all_artifact_fingerprints',integrity['completed_checks'])
        self.assertNotIn('sqlite_quick_check',integrity['completed_checks'])
        self.assertEqual(report['exit_code'],2);self.assertEqual(before,self.protected())

    def test_owned_boundary_matches_policy_and_multilingual_derivation_contracts(self):
        from rules import load_config, policy_for
        from extract import normalize
        original=load_config(self.root/'tools/rag/config.toml')
        independent=detector.load_config(detector.PolicyBytes((self.root/'tools/rag/config.toml').read_bytes()))
        self.assertEqual(original,independent)
        for path in ('_local/data.py','.git/HEAD','Private/x.txt','docs/ARTIST_GUIDE.md',
                     'Test Scene/a.md','docs/maps/hello.py','tools/rag/extract.py',
                     'secrets/a.py','.env','docs/private/secret.txt','docs/ordinary.md'):
            for is_dir in (False,True):
                self.assertEqual(policy_for(path,is_dir,original),detector.policy_for(path,is_dir,independent))
        for text in ('فارسی ي ك ى\u200cBrush\ufeff','ＦｏｒＲａｎｇｅｓ\u200d Foo\nBar','docs/Path ABC.md'):
            self.assertEqual(normalize(text),detector.boundary.normalize_v1(text))

    def test_intact_complete_scope_and_logical_determinism(self):
        before=self.protected();a=self.inspect();b=self.inspect()
        self.assertEqual(a['exit_code'],0);self.assertEqual(a['generation_integrity']['state'],'valid')
        self.assertEqual(a['source_freshness'],dict(state='unchanged',completeness='complete',enrolled=4,attempted=4,completed=4,unchanged=4))
        self.assertEqual(a['consumer_binding']['state'],'matches')
        self.assertEqual(a['consumer_binding']['running_consumer_generation'],'unknown')
        self.assertEqual(detector.logical_report(a),detector.logical_report(b))
        self.assertEqual(before,self.protected());self.assertEqual(a['candidate_state'],'not_prepared')
        self.assertIn('human_review_pending',a['review_state'])
        self.assertEqual([r['path'] for r in a['parents']],sorted(self.outcomes(a),key=lambda p:(p.casefold(),p)))

    def test_changed_returned_and_unreturned_parents(self):
        found=retrieval.search(self.index,'forRanges',1,'identifier')['results']
        self.assertEqual(found[0]['path'],self.current)
        self.assertNotIn(self.unknown,[r['path'] for r in found])
        for path in (self.current,self.unknown):self.write(path,(self.root/path).read_bytes()+b'Changed\n')
        a=self.inspect();rows=self.outcomes(a)
        self.assertEqual(a['exit_code'],1);self.assertEqual(a['source_freshness']['state'],'stale')
        for path in (self.current,self.unknown):self.assertEqual(rows[path]['outcome'],'changed')
        self.assertEqual(a['source_freshness']['completed'],4)

    def test_repeated_already_dirty_edits_are_rehashed(self):
        self.write(self.current,self.body+'First change\n');a=self.inspect()
        self.assertIn(' M',self.git('status','--porcelain','--',self.current).decode())
        self.write(self.current,self.body+'Second change\n');b=self.inspect()
        self.assertEqual(self.outcomes(b)[self.current]['outcome'],'changed')
        self.assertNotEqual(self.outcomes(a)[self.current]['observed_sha256'],self.outcomes(b)[self.current]['observed_sha256'])

    def test_enrolled_untracked_source_change(self):
        self.assertIn('??',self.git('status','--porcelain','--',self.unknown).decode())
        self.write(self.unknown,b'Changed untracked source\n')
        self.assertEqual(self.outcomes(self.inspect())[self.unknown]['outcome'],'changed')

    def test_same_size_change_with_restored_mtime(self):
        p=self.root/self.current;info=p.stat();raw=p.read_bytes();p.write_bytes(raw.replace(b'Guide',b'Other'))
        os.utime(p,ns=(info.st_atime_ns,info.st_mtime_ns))
        self.assertEqual(p.stat().st_size,info.st_size);self.assertEqual(p.stat().st_mtime_ns,info.st_mtime_ns)
        self.assertEqual(self.outcomes(self.inspect())[self.current]['outcome'],'changed')

    def test_missing_and_rename_never_substitute(self):
        (self.root/self.current).rename(self.root/'docs/renamed.md')
        a=self.inspect();self.assertEqual(self.outcomes(a)[self.current]['outcome'],'missing')
        self.assertEqual(a['exit_code'],1);self.assertNotIn('docs/renamed.md',self.outcomes(a))
        self.assertIn('rename is not established',self.outcomes(a)[self.current]['reason'])

    def test_inaccessible_and_mixed_changed_unknown_preserve_findings(self):
        self.write(self.unknown,b'Changed\n');original=detector.os.open
        def opened(path,*args,**kwargs):
            if Path(path)==self.root/self.current:raise PermissionError('Owned denial')
            return original(path,*args,**kwargs)
        with mock.patch.object(detector.os,'open',side_effect=opened):a=self.inspect()
        self.assertEqual(self.outcomes(a)[self.current]['outcome'],'inaccessible')
        self.assertEqual(self.outcomes(a)[self.unknown]['outcome'],'changed')
        self.assertEqual(a['source_freshness']['state'],'stale');self.assertEqual(a['source_freshness']['completeness'],'incomplete')
        self.assertEqual(a['exit_code'],2)

    def test_new_policy_denial_precedes_every_parent_content_open(self):
        self.deny(self.current);opened=[];original=detector.os.open
        def opening(path,*args,**kwargs):
            opened.append(Path(path))
            if Path(path)==self.root/self.current:raise AssertionError('Forbidden parent content was opened')
            return original(path,*args,**kwargs)
        before=self.protected()
        with mock.patch.object(detector.os,'open',side_effect=opening):a=self.inspect()
        self.assertNotIn(self.root/self.current,opened)
        self.assertEqual(self.outcomes(a)[self.current]['outcome'],'policy_blocked')
        self.assertEqual(a['compatibility']['state'],'incompatible');self.assertEqual(a['generation_integrity']['state'],'valid')
        self.assertEqual(a['exit_code'],2);self.assertEqual(before,self.protected())

    def test_invalid_and_unreadable_policy_never_fall_back(self):
        p=self.root/'tools/rag/config.toml';saved=p.read_bytes()
        p.write_bytes(b'not valid = [')
        with mock.patch.object(detector,'observe',wraps=detector.observe) as observe:
            a=self.inspect();self.assertTrue(all(r['outcome']=='policy_unknown' for r in a['parents']))
            self.assertTrue(all(call.args[3] is None for call in observe.call_args_list))
        p.write_bytes(saved);original=detector.os.open
        def opening(path,*args,**kwargs):
            if Path(path)==p:raise PermissionError('Owned unreadable policy')
            if Path(path) in [self.root/s for s in self.outcomes(a)]:raise AssertionError('Parent read despite unreadable policy')
            return original(path,*args,**kwargs)
        with mock.patch.object(detector.os,'open',side_effect=opening):b=self.inspect()
        self.assertTrue(all(r['outcome']=='policy_unknown' for r in b['parents']));self.assertEqual(b['exit_code'],2)

    def test_denied_runtime_helper_is_not_opened_for_identity_or_derivation(self):
        self.deny('tools/rag/extract.py');original=detector.os.open;opened=[]
        def opening(path,*args,**kwargs):
            if Path(path).name=='extract.py':opened.append(str(path));raise AssertionError('Denied helper opened')
            return original(path,*args,**kwargs)
        with mock.patch.object(detector.os,'open',side_effect=opening):a=self.inspect()
        self.assertEqual(opened,[]);self.assertEqual(a['generation_integrity']['state'],'valid')
        self.assertTrue(a['generation_integrity']['omitted_checks']);self.assertEqual(a['exit_code'],2)

    def test_link_or_reparse_metadata_rejected_before_content_open(self):
        target=self.root/self.current;info=target.lstat();original=detector.boundary.is_link
        def is_link(metadata):return original(metadata) or detector.boundary.identity(metadata)==detector.boundary.identity(info)
        original_open=detector.os.open
        def opening(path,*args,**kwargs):
            if Path(path)==target:raise AssertionError('Link target content opened')
            return original_open(path,*args,**kwargs)
        with mock.patch.object(detector.boundary,'is_link',side_effect=is_link),mock.patch.object(detector.os,'open',side_effect=opening):a=self.inspect()
        self.assertEqual(self.outcomes(a)[self.current]['outcome'],'link_rejected');self.assertEqual(a['exit_code'],2)

    @unittest.skipUnless(os.name=='nt','Windows junction fixture')
    def test_real_junction_ancestor_is_rejected_without_following_it(self):
        docs=self.root/'docs';moved=self.root/'original-docs';docs.rename(moved)
        result=subprocess.run(['cmd','/c','mklink','/J',str(docs),str(moved)],capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr)
        try:
            a=self.inspect()
            self.assertTrue(all(r['outcome']=='link_rejected' for r in a['parents']))
            self.assertEqual(a['exit_code'],2)
        finally:
            # Remove only the verified owned junction, then restore its fixture directory.
            self.assertTrue(detector.boundary.is_link(docs.lstat()))
            docs.rmdir();moved.rename(docs)

    @unittest.skipUnless(os.name=='nt','Windows native case semantics')
    def test_case_only_rename_uses_windows_identity_without_guessing(self):
        target=self.root/self.current;target.rename(target.with_name('ARTIST_guide.md'))
        a=self.inspect();self.assertEqual(self.outcomes(a)[self.current]['outcome'],'unchanged')
        self.assertEqual(len(a['parents']),4)

    def test_cross_root_and_wrong_worktree_are_rejected(self):
        other=self.root/'_local/rag/other';other.mkdir(parents=True)
        a=detector.inspect(other,self.index);self.assertEqual(a['generation_integrity']['state'],'wrong_root')
        self.assertFalse(a['parents'])
        worktree=self.root/'_local/rag/worktree'
        self.git('worktree','add','--detach',str(worktree))
        b=detector.inspect(worktree,self.index);self.assertEqual(b['generation_integrity']['state'],'wrong_root')
        self.assertFalse(b['parents']);self.assertEqual(b['exit_code'],2)

    def test_changed_corpus_does_not_adopt_new_scope(self):
        definition=copy.deepcopy(self.definition);definition['sources'].append(dict(definition['sources'][0],path='private/not-open.txt'))
        self.corpus.write_bytes(detector.encoded(definition));before=self.protected()
        a=self.inspect();self.assertEqual(a['generation_integrity']['state'],'valid')
        self.assertEqual(a['compatibility']['state'],'incompatible');self.assertEqual(len(a['parents']),4)
        self.assertNotIn('private/not-open.txt',self.outcomes(a));self.assertEqual(before,self.protected())

    def test_runtime_configuration_changes_are_not_corruption(self):
        for name in ('adapter.py','retrieval.toml','ranking-v2.1.json','glossary-v1.json','extract.py'):
            path=self.root/'tools/rag'/name;path.write_bytes(path.read_bytes()+b'\n')
        a=self.inspect();self.assertEqual(a['generation_integrity']['state'],'valid')
        self.assertEqual(a['compatibility']['state'],'incompatible');self.assertEqual(a['source_freshness']['state'],'unchanged')
        self.assertEqual(sum(r['outcome']=='changed' for r in a['inputs']),5);self.assertEqual(a['exit_code'],1)

    def test_corrupt_incomplete_and_unsupported_publications(self):
        db=self.index/'index.sqlite3';raw=db.read_bytes();db.write_bytes(raw[:-1]+bytes([raw[-1]^1]))
        a=self.inspect();self.assertEqual(a['generation_integrity']['state'],'invalid');self.assertFalse(a['parents'])
        db.write_bytes(raw);run_path=self.index/'run.json';run=json.loads(run_path.read_bytes())
        run['complete']=False;run_path.write_bytes(detector.encoded(run))
        self.assertEqual(self.inspect()['generation_integrity']['state'],'invalid')
        run['schema']='unsupported';run_path.write_bytes(detector.encoded(run))
        self.assertEqual(self.inspect()['generation_integrity']['state'],'unsupported')

    def test_concurrent_source_mutation_is_synchronized_and_unknown(self):
        target=self.root/self.current;identity=detector.boundary.identity(target.stat())
        ready=threading.Event();done=threading.Event();original=detector.os.fdopen
        def writer():
            if ready.wait(5):target.write_bytes(target.read_bytes()+b'Concurrent change\n');done.set()
        thread=threading.Thread(target=writer);thread.start()
        class Handle:
            def __init__(self,handle):self.handle=handle;self.fired=False
            def __enter__(self):return self
            def __exit__(self,*args):self.handle.close()
            def fileno(self):return self.handle.fileno()
            def read(self,n):
                raw=self.handle.read(n)
                if not self.fired and detector.boundary.identity(os.fstat(self.fileno()))==identity:
                    self.fired=True;ready.set()
                    if not done.wait(5):raise AssertionError('Owned synchronized writer did not complete')
                return raw
        try:
            with mock.patch.object(detector.os,'fdopen',side_effect=lambda *a,**k:Handle(original(*a,**k))):a=self.inspect()
        finally:ready.set();thread.join(6)
        self.assertFalse(thread.is_alive());self.assertEqual(self.outcomes(a)[self.current]['outcome'],'unstable')
        self.assertIsNone(self.outcomes(a)[self.current]['observed_sha256']);self.assertEqual(a['exit_code'],2)

    def test_unrelated_edits_do_not_make_enrolled_evidence_stale(self):
        self.write('unrelated.txt','Unrelated content')
        a=self.inspect();self.assertEqual(a['exit_code'],0);self.assertEqual(a['source_freshness']['state'],'unchanged')
        self.assertEqual(a['provenance']['worktree_status'],'not_scanned')

    def test_deadline_retains_an_already_confirmed_change(self):
        self.write(self.current,self.body+'Changed before the deadline\n')
        original=detector.Reader.read
        def reading(reader,path,*args,**kwargs):
            result=original(reader,path,*args,**kwargs)
            if Path(path)==self.root/self.current:reader.deadline=0
            return result
        with mock.patch.object(detector.Reader,'read',new=reading):a=self.inspect()
        self.assertEqual(self.outcomes(a)[self.current]['outcome'],'changed')
        self.assertEqual(a['source_freshness']['state'],'stale');self.assertEqual(a['source_freshness']['completeness'],'incomplete')
        self.assertEqual(a['exit_code'],2)

    def test_policy_change_during_inspection_blocks_later_parent_reads(self):
        original=detector.Reader.read
        def reading(reader,path,*args,**kwargs):
            result=original(reader,path,*args,**kwargs)
            if Path(path)==self.root/self.current:self.deny(self.unknown)
            return result
        with mock.patch.object(detector.Reader,'read',new=reading):a=self.inspect()
        self.assertEqual(self.outcomes(a)[self.current]['outcome'],'unchanged')
        self.assertEqual(self.outcomes(a)[self.unknown]['outcome'],'policy_unknown')
        self.assertEqual(a['exit_code'],2)

    def test_different_registration_is_not_running_consumer_evidence(self):
        self.registration.write_text(self.registration.read_text().replace(str(self.index).replace('\\','\\\\'),'C:/other/index'),encoding='utf-8')
        a=self.inspect();self.assertEqual(a['consumer_binding']['state'],'differs')
        self.assertEqual(a['consumer_binding']['running_consumer_generation'],'unknown')
        self.assertEqual(a['source_freshness']['state'],'unchanged');self.assertEqual(a['exit_code'],1)

    def test_explicit_evaluation_baseline_and_unavailable_baseline(self):
        path='labels.json';label=self.write(path,'Original labels')
        generation=self.inspect()['selected']['generation'];expected=detector.sha(label.read_bytes())
        results=self.write('_local/rag/evaluations/owned/results.json',detector.encoded({'index_generation':generation,'evaluation_sha256':expected}))
        receipt=self.write('_local/rag/evaluations/owned/run.json',detector.encoded({'complete':True,'index_generation':generation,'evaluation_sha256':expected,'results_sha256':detector.sha(results.read_bytes())}))
        self.write(path,'Changed labels')
        a=detector.inspect(self.root,self.index,[(path,str(receipt))])
        self.assertEqual(a['evaluation_definitions'][0]['outcome'],'changed');self.assertEqual(a['exit_code'],1)
        b=detector.inspect(self.root,self.index,[(path,str(receipt)+'-missing')])
        self.assertEqual(b['evaluation_definitions'][0]['outcome'],'baseline_unavailable');self.assertEqual(b['exit_code'],2)

    def test_resource_bounds_and_explicit_report_size_failure(self):
        with mock.patch.dict(detector.LIMITS,source_bytes=1):a=self.inspect()
        self.assertTrue(all(r['outcome']=='size_limited' for r in a['parents']));self.assertEqual(a['exit_code'],2)
        with mock.patch.dict(detector.LIMITS,inputs=4):b=self.inspect()
        self.assertEqual(b['exit_code'],2)
        report=detector.base_report(self.root,self.index);report['next_actions']=['x'*detector.LIMITS['report_bytes']]
        wire=cli.wire(report);c=json.loads(wire)
        self.assertLess(len(wire),detector.LIMITS['report_bytes']);self.assertIn('report_size_exceeded',c['report_error'])
        self.assertEqual(c['exit_code'],2)

    def test_actual_cli_success_and_owned_cancellation_preserve_bytes(self):
        before=self.protected()
        command=[sys.executable,'-B',str(TOOL/'refresh_status.py'),'--root',str(self.root),'--index',str(self.index),'--json']
        completed=subprocess.run(command,capture_output=True,timeout=30)
        self.assertEqual(completed.returncode,0,completed.stderr);self.assertEqual(json.loads(completed.stdout)['schema'],detector.SCHEMA)
        processes=[];original=subprocess.Popen
        def start(*args,**kwargs):
            process=original(*args,**kwargs);processes.append(process)
            process.communicate=mock.Mock(side_effect=KeyboardInterrupt)
            return process
        with mock.patch.object(cli.subprocess,'Popen',side_effect=start):cancelled=cli.guarded(self.root,self.index,[])
        self.assertEqual(cancelled['exit_code'],130);self.assertTrue(all(p.poll() is not None for p in processes))
        self.assertEqual(before,self.protected())

    def test_owned_wall_timeout_cleanup_preserves_bytes(self):
        before=self.protected();processes=[];original=subprocess.Popen
        def start(*args,**kwargs):
            process=original(*args,**kwargs);processes.append(process)
            process.communicate=mock.Mock(side_effect=subprocess.TimeoutExpired('owned fixture',25))
            return process
        with mock.patch.object(cli.subprocess,'Popen',side_effect=start):a=cli.guarded(self.root,self.index,[])
        self.assertEqual(a['exit_code'],2);self.assertIn('deadline',a['report_error'])
        self.assertTrue(all(p.poll() is not None for p in processes));self.assertEqual(before,self.protected())


if __name__=='__main__':unittest.main()
