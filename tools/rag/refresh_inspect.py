"""Bounded observations of a sealed generation and its current inputs; no writes."""
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import stat
import subprocess
import time
import tomllib

import refresh_boundary as boundary
from refresh_boundary import load_config, path_key, policy_for, relative_path

SCHEMA = "cyrus.refresh-status/1"
VERSION = "0.4.1"
INDEX_SCHEMA = "cyrus.lexical-index/2"
parsed = json.loads
TOOL = Path(__file__).resolve().parent
LIMITS = {"artifact_bytes": 64*1024*1024, "source_bytes": 16*1024*1024,
          "parent_total_bytes": 32*1024*1024, "control_bytes": 2*1024*1024,
          "total_bytes": 384*1024*1024, "inputs": 256, "parents": 64,
          "chunks": 20000, "path_chars": 1024, "report_bytes": 256*1024,
          "worker_seconds": 20, "wall_seconds": 25, "git_seconds": 2,
          "evaluation_baselines": 8}
IMPLEMENTATION_FILES = ("refresh_status.py", "refresh_inspect.py", "refresh_boundary.py")
INTEGRITY_CHECKS = ('complete_publication', 'logical_identity_and_counts',
                    'all_artifact_fingerprints', 'chunk_export_equality', 'explicit_root',
                    'recorded_parent_scope', 'sqlite_metadata_identity', 'sqlite_quick_check',
                    'all_searchable_rows_and_fts_text', 'normalized_fts_context_path')


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))+"\n").encode("utf-8")


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


class ObservationError(ValueError):
    def __init__(self, outcome, reason):
        super().__init__(reason)
        self.outcome = outcome


def absolute(path):
    return Path(os.path.abspath(path))


def checked_path(path):
    path = absolute(path)
    for ancestor in [*reversed(path.parents), path]:
        if boundary.is_link(ancestor.lstat()):
            raise ObservationError("link_rejected", "Link/reparse point or ancestor rejected before content access")
    return path


class Reader:
    def __init__(self):
        self.deadline = time.monotonic()+LIMITS["worker_seconds"]
        self.bytes = self.inputs = self.parent_bytes = 0

    def check(self):
        if time.monotonic() >= self.deadline:
            raise ObservationError("not_checked", "Operation deadline reached")

    def read(self, path, limit, parent=False):
        self.check()
        self.inputs += 1
        if self.inputs > LIMITS["inputs"]:
            raise ObservationError("not_checked", "Input count bound reached")
        try:
            path = checked_path(path)
            before = path.lstat()
            if not stat.S_ISREG(before.st_mode):
                raise ObservationError("not_regular", "Expected a regular file")
            if before.st_size > limit:
                raise ObservationError("size_limited", "Per-file byte bound exceeded")
            if parent and self.parent_bytes+before.st_size > LIMITS["parent_total_bytes"]:
                raise ObservationError("not_checked", "Total enrolled-parent byte bound reached")
            if self.bytes+before.st_size > LIMITS["total_bytes"]:
                raise ObservationError("not_checked", "Total input byte bound reached")
            flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
            with os.fdopen(os.open(path, flags), "rb") as handle:
                if boundary.identity(before) != boundary.identity(os.fstat(handle.fileno())):
                    raise ObservationError("unstable", "File identity changed before reading")
                parts = []; count = 0
                while True:
                    self.check()
                    chunk = handle.read(min(1024*1024, limit-count+1))
                    if not chunk:
                        break
                    count += len(chunk); self.bytes += len(chunk)
                    if parent:
                        self.parent_bytes += len(chunk)
                    if count > limit or self.bytes > LIMITS["total_bytes"] or self.parent_bytes > LIMITS["parent_total_bytes"]:
                        raise ObservationError("unstable", "Input grew beyond a byte bound")
                    parts.append(chunk)
                after = os.fstat(handle.fileno())
            checked_path(path)
            if boundary.identity(before) != boundary.identity(after) or boundary.identity(before) != boundary.identity(path.lstat()):
                raise ObservationError("unstable", "Metadata/identity changed during the read")
            return b"".join(parts), boundary.identity(before)
        except FileNotFoundError as exc:
            # A disappearing entry after opening is an unstable read, not deletion.
            if 'before' in locals():
                raise ObservationError("unstable", "Path disappeared during observation") from exc
            raise ObservationError("missing", "Enrolled/input path is absent; rename is not established") from exc
        except OSError as exc:
            raise ObservationError("inaccessible", "Read or metadata access failed") from exc


def bounded_relative(value):
    value = relative_path(value)
    if len(value) > LIMITS["path_chars"] or ':' in value:
        raise ValueError("Path character bound exceeded")
    return value


def sealed_generation(root, index, reader, normalizer_sha=None):
    """The existing publication model, independent of mutable corpus/runtime files.

    Hashes are locally owned receipts, not signatures. SQLite is inspected from
    the already fingerprinted bytes, avoiding a second open of a mutable DB path.
    """
    checks = []
    reader.integrity_checks = checks
    if index.name.startswith('.'):
        raise ValueError("Partial generation directory rejected")
    run = parsed(reader.read(index/'run.json', LIMITS['artifact_bytes'])[0])
    if not isinstance(run,dict):raise ValueError('Malformed publication receipt')
    if run.get('schema') != INDEX_SCHEMA:
        raise ObservationError('unsupported', 'Unsupported generation schema')
    if not run.get('complete') or (index/'failure.json').exists():
        raise ValueError('Generation is not a complete successful publication')
    checks.append('complete_publication')
    raw = {n:reader.read(index/n, LIMITS['artifact_bytes'])[0] for n in ('logical.json','chunks.jsonl','index.sqlite3')}
    logical = parsed(raw['logical.json'])
    if sha(raw['logical.json']) != run['generation_id'] or logical['schema'] != INDEX_SCHEMA:
        raise ValueError('Logical generation fingerprint/schema mismatch')
    if run['artifact_sha256'] != {n:sha(b) for n,b in raw.items()}:
        raise ValueError('Publication artifact fingerprints disagree')
    identities = logical['identities']; sources = logical['sources']; chunks = logical['chunks']
    if identities != run['identities'] or len(sources) != run['source_count'] or len(chunks) != run['chunk_count']:
        raise ValueError('Publication and logical metadata disagree')
    if not 0 < len(sources) <= LIMITS['parents'] or not 0 < len(chunks) <= LIMITS['chunks']:
        raise ValueError('Source/chunk count bound exceeded')
    if Path(identities['root']) != root:
        raise ObservationError('wrong_root', 'Generation belongs to a different explicit repository/worktree')
    if [parsed(line) for line in raw['chunks.jsonl'].splitlines()] != chunks:
        raise ValueError('Chunk export differs from logical publication')
    corpus = absolute(identities['corpus_path'])
    if not corpus.is_relative_to(root) or corpus == root:
        raise ValueError('Recorded corpus is outside repository')
    by_path = {}
    for source in sources:
        path = bounded_relative(source['path']); key = path_key(path)
        if key in by_path or len(source['sha256']) != 64:
            raise ValueError('Duplicate parent path or malformed parent hash')
        by_path[key] = source
    runtime = identities['runtime_sha256']
    if not 0 < len(runtime) <= 32 or any('/' in n or '\\' in n or bounded_relative(n) != n for n in runtime):
        raise ValueError('Unsupported runtime identity scope')
    checks.extend(['logical_identity_and_counts','all_artifact_fingerprints','chunk_export_equality','explicit_root','recorded_parent_scope'])
    connection = sqlite3.connect(':memory:')
    try:
        connection.deserialize(raw['index.sqlite3'])
        connection.execute('PRAGMA query_only=ON')
        connection.set_progress_handler(lambda: int(time.monotonic() >= reader.deadline),1000)
        metadata = connection.execute('SELECT value FROM metadata').fetchall()
        expected = {'schema':INDEX_SCHEMA,'generation_id':run['generation_id'],'identities':identities,'sources':sources}
        if len(metadata) != 1 or parsed(metadata[0][0]) != expected or len(raw['index.sqlite3']) != run['database_bytes']:
            raise ValueError('SQLite metadata/size disagrees with publication')
        checks.append('sqlite_metadata_identity')
        if connection.execute('PRAGMA quick_check').fetchall() != [('ok',)]:
            raise ValueError('SQLite quick_check failed')
        checks.append('sqlite_quick_check')
        rows = connection.execute('SELECT id,path,component,role,status,data FROM chunks ORDER BY id').fetchall()
        fts = connection.execute('SELECT rowid,text,context,path FROM search_chunks ORDER BY rowid').fetchall()
        if len(rows) != len(chunks) or len(fts) != len(chunks):
            raise ValueError('SQLite row counts disagree')
        # Independently derive the known normalization contract; never execute
        # the inspected producer, even when its bytes match the published hash.
        normalizer_matches = (normalizer_sha in boundary.NORMALIZER_SOURCE_SHA256S
                              and runtime.get('extract.py') in boundary.NORMALIZER_SOURCE_SHA256S
                              and identities.get('normalization_version') == 'unicode-persian/1')
        for n,chunk in enumerate(chunks,1):
            reader.check(); source = chunk['source']
            if source != by_path.get(path_key(chunk['path'])) or chunk['parent_sha256'] != source['sha256']:
                raise ValueError('Chunk parent is outside the recorded scope')
            if rows[n-1] != (n,source['path'],source['component'],source['role'],source['knowledge_status'],rows[n-1][5]) or parsed(rows[n-1][5]) != chunk:
                raise ValueError('Searchable chunk rows differ from export')
            if fts[n-1][:2] != (n,chunk['search_text']):
                raise ValueError('FTS text/row identity differs from export')
            if normalizer_matches and fts[n-1][2:] != (boundary.normalize_v1(chunk['context']),boundary.normalize_v1(chunk['path'])):
                raise ValueError('Normalized FTS context/path differs from export')
        checks.append('all_searchable_rows_and_fts_text')
        if normalizer_matches: checks.append('normalized_fts_context_path')
        omitted = [] if normalizer_matches else ['Normalized FTS context/path derivation: matching permitted known producer unavailable; sealed DB byte fingerprint still verified.']
    except sqlite3.Error as exc:
        code = getattr(exc, 'sqlite_errorcode', None)
        primary = code & 0xff if code is not None else None
        if primary == sqlite3.SQLITE_INTERRUPT:
            expired = time.monotonic() >= reader.deadline
            raise ObservationError('deadline_exceeded' if expired else 'verification_interrupted',
                                   'SQLite verification deadline reached (SQLITE_INTERRUPT)' if expired
                                   else 'SQLite verification interrupted; deadline not established') from exc
        if primary in (sqlite3.SQLITE_IOERR, sqlite3.SQLITE_CANTOPEN, sqlite3.SQLITE_NOMEM,
                       sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED, sqlite3.SQLITE_PERM,
                       sqlite3.SQLITE_READONLY, sqlite3.SQLITE_FULL):
            raise ObservationError('verification_unavailable', 'SQLite verification resource/access failure: '+str(exc)) from exc
        raise
    finally:
        connection.close()
    return run, logical, checks, omitted


class PolicyBytes:
    def __init__(self, raw): self.raw = raw
    def read_bytes(self): return self.raw
    def __str__(self): return 'bounded current inspection policy'


def observe(root, path, expected, policy, reader, limit, parent=False):
    row = {'path':path,'recorded_sha256':expected,'observed_sha256':None,'outcome':'not_checked'}
    try:
        bounded_relative(path)
        if policy is None:
            raise ObservationError('policy_unknown','Current policy unavailable or invalid; content was not read')
        if boundary.identity(checked_path(root/'tools/rag/config.toml').lstat()) != policy['stamp']:
            raise ObservationError('policy_unknown','Inspection policy changed during observation; content was not read')
        if policy_for(path,False,policy['config'])[0] != 'full':
            raise ObservationError('policy_blocked','Current policy denies full content access; content was not read')
        raw,_ = reader.read(root/path,min(limit,policy['config']['max_hash_bytes']),parent)
        row.update(observed_sha256=sha(raw),outcome='unchanged' if sha(raw)==expected else 'changed')
    except ObservationError as exc:
        row.update(outcome=exc.outcome,reason=str(exc))
    except (OSError,ValueError):
        row.update(outcome='policy_unknown',reason='Policy/path could not be checked safely; content was not read')
    return row


def git_command(root, *args):
    # No worktree walk: only root/branch/HEAD and the staging file are observed.
    result = subprocess.run(['git','-c','core.fsmonitor=false','-C',str(root),*args],
                            stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=LIMITS['git_seconds'],
                            env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'),creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    if result.returncode or len(result.stdout)>LIMITS['control_bytes']:
        raise ValueError('Git provenance unavailable or exceeds output bound')
    return result.stdout.decode('utf-8').strip()


def git_provenance(root, recorded, reader):
    try:
        reader.check()
        if absolute(git_command(root,'rev-parse','--show-toplevel')) != root:
            raise ValueError('Explicit root is not the repository/worktree top level')
        git_dir = absolute(git_command(root,'rev-parse','--absolute-git-dir'))
        current = {'branch':git_command(root,'branch','--show-current'),'head':git_command(root,'rev-parse','HEAD')}
        # Actual index file identity is bounded; it is not the catalog's ls-files
        # digest and is therefore not compared to that differently defined hash.
        try: current['staging_file_sha256'] = sha(reader.read(git_dir/'index',LIMITS['control_bytes'])[0])
        except ObservationError as exc: current['staging_file_state'] = exc.outcome
        return {'state':'observed','current':current,'changed_fields':sorted(k for k in ('branch','head') if current[k]!=recorded.get(k)),
                'worktree_status':'not_scanned','recorded_staging_identity':recorded.get('index_sha256'),
                'staging_comparison':'unavailable: recorded identity hashes ls-files output, not index file bytes'}
    except (OSError,ValueError,subprocess.SubprocessError):
        return {'state':'unknown','reason':'Git root/provenance unavailable; no repository scan attempted'}


def registration(root,index,reader,policy):
    result = {'running_consumer_generation':'unknown','running_consumer_reason':'Configuration does not prove any running process binding; no session contacted'}
    row = observe(root,'.codex/config.toml',None,policy,reader,LIMITS['control_bytes'])
    if row['outcome'] not in ('changed','unchanged'):
        return dict(result,state='absent' if row['outcome']=='missing' else 'unknown',observation=row)
    try:
        # The second bounded read must match the observed hash, never a later config.
        if boundary.identity(checked_path(root/'tools/rag/config.toml').lstat())!=policy['stamp']:
            raise ValueError('Policy changed before registration read')
        raw,_ = reader.read(root/'.codex/config.toml',LIMITS['control_bytes'])
        if sha(raw)!=row['observed_sha256']:
            raise ValueError('Registration changed during observation')
        server = tomllib.loads(raw.decode('utf-8')).get('mcp_servers',{}).get('cyrus_knowledge')
        if server is None: return dict(result,state='absent')
        args = server['args']
        if args.count('--root')!=1 or args.count('--index')!=1: raise ValueError('Ambiguous registration')
        configured_root = Path(args[args.index('--root')+1]);configured_index = Path(args[args.index('--index')+1])
        if not configured_root.is_absolute() or not configured_index.is_absolute():raise ValueError('Binding must be absolute')
        return dict(result,state='matches' if configured_root==root and configured_index==index else 'differs',
                    configured_root=str(configured_root),configured_index=str(configured_index),configuration_sha256=sha(raw))
    except (OSError,KeyError,ValueError,TypeError,IndexError,UnicodeError):
        return dict(result,state='unknown',reason='Registration malformed, unsupported or unstable')


def base_report(root,index):
    return {'schema':SCHEMA,'detector':{'version':VERSION,'implementation_sha256':dict.fromkeys(IMPLEMENTATION_FILES),'limits':LIMITS,'configuration_sha256':sha(encoded(LIMITS))},
            'repository':str(root),'selected':{'index':str(index),'generation':None},
            'observation':{'started_utc':dt.datetime.now(dt.timezone.utc).isoformat(),'ended_utc':None,
                           'scope':'Individually checked observations over an interval; not an atomic filesystem snapshot'},
            'generation_integrity':{'state':'unknown','completeness':'not_checked','completed_checks':[],'omitted_checks':[]},
            'compatibility':{'state':'unknown'},'source_freshness':{'state':'unknown','completeness':'not_checked','enrolled':0,'attempted':0,'completed':0},
            'parents':[],'inputs':[],'evaluation_definitions':[],
            'provenance':{'state':'unknown'},'consumer_binding':{'state':'unknown','running_consumer_generation':'unknown'},
            'review_state':'human_review_pending; unchanged bytes do not establish semantic approval',
            'candidate_state':'not_prepared','next_actions':[],'exit_code':2,
            'volatile_fields':['observation.started_utc','observation.ended_utc','observation.duration_seconds'],
            'checks':{'attempted':[],'completed':[],'omitted':[]}}


def finish(report, reader, started):
    report['observation'].update(ended_utc=dt.datetime.now(dt.timezone.utc).isoformat(),duration_seconds=round(time.monotonic()-started,6))
    report['resources']={'read_bytes':reader.bytes,'attempted_input_reads':reader.inputs,'parent_bytes':reader.parent_bytes}
    return report


def inspect(root,index,evaluations=()):
    root,index = absolute(root),absolute(index);started=time.monotonic();reader=Reader();report=base_report(root,index)
    policy=None
    policy_row={'path':'tools/rag/config.toml','recorded_sha256':None,
                'observed_sha256':None,'outcome':'not_checked','kind':'policy'}
    try:
        checked_path(root);checked_path(index)
        # The explicit policy control is bootstrapped with bounded reads. No
        # current helper/parent content is opened under an unknown deny policy.
        try:
            raw,stamp=reader.read(root/'tools/rag/config.toml',LIMITS['control_bytes'])
            policy_row.update(observed_sha256=sha(raw),outcome='observed')
            policy={'config':load_config(PolicyBytes(raw)),'stamp':stamp}
        except (OSError,ValueError) as exc:
            if isinstance(exc,ObservationError):policy_row.update(outcome=exc.outcome,reason=str(exc))
            report['checks']['omitted'].append('Policy-dependent content checks blocked: current policy invalid/unreadable')
        for name in IMPLEMENTATION_FILES:
            # Only these three detector-owned startup files execute. Installed
            # retrieval helpers are data, never Python import dependencies.
            try:
                report['detector']['implementation_sha256'][name]=sha(reader.read(TOOL/name,LIMITS['control_bytes'])[0])
            except (OSError,ValueError) as exc:
                report['detector']['implementation_sha256'][name]=None
                report['checks']['omitted'].append('Detector implementation identity '+name+': '+str(exc))
        normalizer=observe(root,'tools/rag/extract.py',None,policy,reader,LIMITS['control_bytes'])
        report['checks']['attempted'].append('generation_integrity')
        run,logical,checks,omitted = sealed_generation(root,index,reader,normalizer['observed_sha256'])
        report['selected']['generation']=run['generation_id']
        report['generation_integrity']={'state':'valid','completeness':'complete' if not omitted else 'incomplete',
                                        'completed_checks':checks,'omitted_checks':omitted}
        report['checks']['completed'].append('generation_integrity')
    except (OSError,ValueError,KeyError,TypeError,AttributeError,sqlite3.Error) as exc:
        issue=exc.outcome if isinstance(exc,ObservationError) else 'access_failure' if isinstance(exc,OSError) else 'internal_inconsistency'
        state=issue if issue in ('unsupported','wrong_root') else 'unavailable' if isinstance(exc,(ObservationError,OSError)) else 'invalid'
        completed=getattr(reader,'integrity_checks',[])
        report['generation_integrity'].update(state=state,completeness='incomplete',issue=issue,reason=str(exc)[:240],
                                             completed_checks=completed,omitted_checks=[c for c in INTEGRITY_CHECKS if c not in completed])
        report['checks']['omitted'].append('Current inputs/parents/binding: selected generation could not be safely trusted')
        report['next_actions']=['Investigate selected publication integrity/access/root; retain artifacts and do not rebuild or switch automatically']
        return finish(report,reader,started)
    identities=logical['identities']
    policy_row['recorded_sha256']=identities['runtime_sha256'].get('config.toml')
    if policy_row['observed_sha256'] is not None:
        policy_row['outcome']='unchanged' if policy_row['observed_sha256']==policy_row['recorded_sha256'] else 'changed'
    report['current_policy']={'state':'loaded' if policy is not None else 'unavailable_or_invalid','observation':policy_row}
    report['checks']['attempted'].extend(['current_input_identities','all_enrolled_parents','project_registration','git_provenance'])
    for name,expected in sorted(identities['runtime_sha256'].items()):
        if name=='config.toml': row=dict(policy_row)
        elif name=='extract.py':
            row=dict(normalizer,recorded_sha256=expected)
            if row['observed_sha256'] is not None:
                row['outcome']='unchanged' if row['observed_sha256']==expected else 'changed'
        else: row=observe(root,'tools/rag/'+name,expected,policy,reader,LIMITS['control_bytes'])
        row['kind']='policy' if name=='config.toml' else 'runtime'
        report['inputs'].append(row)
    corpus=Path(identities['corpus_path']).relative_to(root).as_posix()
    row=observe(root,corpus,identities['corpus_sha256'],policy,reader,32*1024*1024);row['kind']='corpus';report['inputs'].append(row)
    inputs=report['inputs']; changed=any(r['outcome']=='changed' for r in inputs)
    uncertain=any(r['outcome'] not in ('changed','unchanged','missing') for r in inputs)
    missing=any(r['outcome']=='missing' for r in inputs)
    report['compatibility']={'state':'incompatible' if changed or missing else 'unknown' if uncertain else 'compatible',
                             'observation_completeness':'incomplete' if uncertain else 'complete',
                             'scope':'Recorded corpus and all existing runtime fingerprint inputs; project registration is separate'}
    for source in sorted(logical['sources'],key=lambda s:(path_key(s['path']),s['path'])):
        report['parents'].append(observe(root,source['path'],source['sha256'],policy,reader,LIMITS['source_bytes'],True))
    rows=report['parents'];complete=sum(r['outcome'] in ('unchanged','changed','missing') for r in rows)
    stale=any(r['outcome'] in ('changed','missing') for r in rows)
    report['source_freshness']={'state':'stale' if stale else 'unknown' if complete!=len(rows) else 'unchanged',
                               'completeness':'complete' if complete==len(rows) else 'incomplete','enrolled':len(rows),
                               'attempted':len(rows),'completed':complete,'unchanged':sum(r['outcome']=='unchanged' for r in rows)}
    if len(evaluations)>LIMITS['evaluation_baselines']:raise ValueError('Evaluation baseline count bound exceeded')
    for path,receipt in sorted(evaluations):
        try:
            receipt=absolute(receipt)
            if receipt.name!='run.json' or not receipt.is_relative_to(root/'_local/rag/evaluations'):
                raise ValueError('Evaluation receipt must be an explicit owned evaluation run.json')
            accepted=parsed(reader.read(receipt,LIMITS['control_bytes'])[0])
            if not accepted.get('complete') or accepted['index_generation']!=run['generation_id']:
                raise ValueError('Evaluation receipt does not identify a complete evaluation of this generation')
            results_raw=reader.read(receipt.parent/'results.json',LIMITS['artifact_bytes'])[0]
            results=parsed(results_raw)
            if sha(results_raw)!=accepted['results_sha256'] or results['index_generation']!=run['generation_id'] or results['evaluation_sha256']!=accepted['evaluation_sha256']:
                raise ValueError('Evaluation result fingerprint or identity mismatch')
            expected=accepted['evaluation_sha256']
            if len(expected)!=64:raise ValueError('Invalid evaluation definition identity')
            row=observe(root,bounded_relative(path),expected,policy,reader,LIMITS['control_bytes'])
            row.update(baseline='operator-selected complete evaluation receipt; human semantic acceptance not implied')
        except (OSError,ValueError,KeyError,TypeError):
            row={'path':path,'outcome':'baseline_unavailable','reason':'Evaluation receipt invalid, inaccessible or for another generation'}
        report['evaluation_definitions'].append(row)
    if not evaluations:
        report['checks']['omitted'].append('Evaluation definitions: no accepted baseline identity in generation; no paths guessed')
    report['consumer_binding']=registration(root,index,reader,policy)
    report['provenance']=git_provenance(root,identities['git_state'],reader)
    for name,done in [('current_input_identities',not uncertain),('all_enrolled_parents',complete==len(rows)),
                      ('project_registration',report['consumer_binding']['state']!='unknown'),('git_provenance',report['provenance']['state']!='unknown')]:
        if done:report['checks']['completed'].append(name)
        else:report['checks']['omitted'].append(name+': one or more observations incomplete; see per-input outcomes')
    uncertain = uncertain or complete!=len(rows) or report['consumer_binding']['state']=='unknown' or report['provenance']['state']=='unknown'
    uncertain = uncertain or any(h is None for h in report['detector']['implementation_sha256'].values())
    uncertain = uncertain or any(r['outcome'] not in ('changed','unchanged','missing') for r in report['evaluation_definitions'])
    action = changed or missing or stale or report['consumer_binding']['state']=='differs' or bool(report['provenance'].get('changed_fields'))
    action = action or any(r['outcome'] in ('changed','missing') for r in report['evaluation_definitions'])
    report['exit_code']=2 if uncertain else 1 if action else 0
    report['next_actions']=(['Resolve blocked/unknown checks under current policy; retry explicitly'] if uncertain else [])
    if changed or missing or stale:
        report['next_actions'].append('Review affected hashes, ranges, qualifiers and labels before authorizing a separate candidate workflow; retain this generation')
    if report['consumer_binding']['state']=='differs':
        report['next_actions'].append('Review configured versus selected binding; do not infer or change any running session')
    if report['provenance'].get('changed_fields'):
        report['next_actions'].append('Review changed Git provenance separately; it does not by itself make enrolled parent bytes stale')
    if any(r['outcome'] in ('changed','missing') for r in report['evaluation_definitions']):
        report['next_actions'].append('Review changed evaluation definitions separately; no label acceptance performed')
    if not report['next_actions']:report['next_actions']=['No mechanical source update indicated by this observation; human semantic review remains pending']
    return finish(report,reader,started)


def logical_report(report):
    """Only documented observation timestamps/duration are volatile."""
    value=json.loads(encoded(report))
    for key in ('started_utc','ended_utc','duration_seconds'):value['observation'].pop(key,None)
    return value
