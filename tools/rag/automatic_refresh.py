"""Explicit standing authorization for bounded mechanical index refresh.

No policy exists by default. `prepare` writes an immutable proposal. `tick` is
an explicitly invoked update, gated by that exact proposal SHA256. It never
enrolls sources, changes authority, accepts metric losses or claims human review.
"""
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import sys
import time
import types
import uuid

import candidate_support as s

SCHEMA = 'cyrus.automatic-refresh/1'
HELPERS = tuple(dict.fromkeys((*s.OWN, 'automatic_refresh.py', 'refresh_evidence.py',
    'activation_contract.py', 'activation_client.py')))
PROVENANCE_FIELDS = ('knowledge_status', 'status_source', 'inventory_decision', 'inventory_reason',
    'referenced_by_current_docs', 'current_reference_sources', 'component', 'generated', 'generated_source')


def artifact(root, path, expected=None, limit=None):
    path = s.safe(path)
    if not path.is_relative_to(root / '_local/rag'):
        raise s.Blocked('artifact_scope', 'Refresh evidence must remain in this root local knowledge store')
    raw, _ = s.reader().read(path, limit or s.BOUNDS['artifact_bytes'])
    if expected is not None and s.sha(raw) != expected:
        raise s.Blocked('evidence_changed', 'Frozen refresh artifact changed: ' + str(path))
    return raw


def record(root, path):
    raw = artifact(root, path)
    return {'path': str(path), 'sha256': s.sha(raw)}


def frozen_json(root, item):
    return json.loads(artifact(root, Path(item['path']), item['sha256']))


def checked_helpers(root, policy, hashes):
    """Check data before importing pipeline/transaction helpers."""
    if set(hashes) != set((*HELPERS, *s.RUNTIME_NAMES, *s.EXTRAS)):
        raise s.Blocked('unsupported_runtime', 'Standing authorization has an unsupported runtime scope')
    for name, expected in hashes.items():
        s.permitted(root, root / 'tools/rag' / name, policy, s.reader(), expected)


def approved_import(name, root, policy, hashes):
    """Compile inspected source bytes instead of trusting import caches or .pyc."""
    path = root / 'tools/rag' / (name + '.py')
    raw, _ = s.permitted(root, path, policy, s.reader(), hashes[path.name])
    module = types.ModuleType(name)
    module.__file__ = str(path)
    sys.modules[name] = module
    exec(compile(raw, str(path), 'exec'), module.__dict__)
    return module


def parents(root, sources, policy):
    bodies = {}
    for source in sources:
        path = source['path']
        if path in bodies or len(bodies) >= s.detection.LIMITS['parents']:
            raise s.Blocked('parent_scope', 'Duplicate or oversized source enrollment')
        s.detection.relative_path(path)
        raw, _ = s.permitted(root, root / path, policy, s.reader(),
                            limit=s.detection.LIMITS['source_bytes'], parent=True)
        bodies[path] = raw
        if sum(map(len, bodies.values())) > s.detection.LIMITS['parent_total_bytes']:
            raise s.Blocked('parent_bound', 'Enrolled parent bytes exceed the refresh bound')
    return bodies


def snapshot(root, out, sources, bodies, index, evaluations):
    folder = out / 'parents'
    folder.mkdir()
    saved = {}
    for n, source in enumerate(sources):
        path = folder / (str(n) + '.txt')
        s.create(path, bodies[source['path']], raw=True)
        saved[source['path']] = record(root, path)
    run = json.loads(artifact(root, index / 'run.json'))
    return {'index': str(index), 'generation': run['generation_id'],
            'index_run': record(root, index / 'run.json'), 'sources': saved,
            'evaluations': [record(root, path) for path in evaluations]}


def selected_base(root, approved, binding, policy_path, approved_sha):
    base = approved['baseline']
    if binding['index'] == base['index']:
        return base
    state = json.loads(artifact(root, policy_path.parent / 'selected.json', limit=s.BOUNDS['definition_bytes']))
    if state.get('schema') != SCHEMA or state.get('policy_sha256') != approved_sha or state['baseline']['index'] != binding['index']:
        raise s.Blocked('unreviewed_selection', 'Selected index is outside the authorized refresh chain')
    transaction = s.safe(state['transaction'])
    if not transaction.is_relative_to(root / '_local/rag/candidates'):
        raise s.Blocked('unreviewed_selection', 'Refresh transaction is outside the owned candidate store')
    ready = json.loads(artifact(root, transaction / 'ready.json', limit=s.BOUNDS['definition_bytes']))
    journal = json.loads(artifact(root, transaction / 'journal-replaced.json', limit=s.BOUNDS['definition_bytes']))
    if (ready['policy_sha256'] != approved_sha or ready['baseline'] != state['baseline']
            or journal['index'] != binding['index'] or journal['fingerprint']['sha256'] != state['registration_sha256']):
        raise s.Blocked('unreviewed_selection', 'Selected state lacks matching readiness and commit witnesses')
    return state['baseline']


def prepare(root, index, receipts, out, reason):
    """Freeze a current usable baseline. This does not enable or switch anything."""
    root = s.safe(root)
    if root != s.TOOL.parents[1] or not reason.strip() or not 2 <= len(receipts) <= 8 or len(receipts) % 2:
        raise s.Blocked('invalid_proposal', 'Explicit local root, rationale and 1..4 paired evaluation definitions required')
    out = s.fresh(out, root / '_local/rag/refresh')
    policy = s.current_policy(root, s.reader())
    normalizer = s.sha(s.permitted(root, root / 'tools/rag/extract.py', policy, s.reader())[0])
    run, logical, _, omitted = s.detection.sealed_generation(root, index, s.reader(), normalizer)
    if omitted:
        raise s.Blocked('incomplete_integrity', 'Baseline integrity verification is incomplete')
    hashes = {name: s.sha(s.permitted(root, root / 'tools/rag' / name, policy, s.reader())[0])
              for name in dict.fromkeys((*HELPERS, *s.RUNTIME_NAMES, *s.EXTRAS))}
    if {k: hashes[k] for k in s.RUNTIME_NAMES} != logical['identities']['runtime_sha256']:
        raise s.Blocked('runtime_changed', 'Approve a freshly built current-runtime generation first')
    bodies = parents(root, logical['sources'], policy)
    if any(s.sha(bodies[p['path']]) != p['sha256'] for p in logical['sources']):
        raise s.Blocked('stale_baseline', 'Standing authorization requires a fresh baseline')
    groups = {}
    for path in receipts:
        receipt, result, labels = s.verify_evaluation_receipt(path, run['generation_id'], s.reader())
        if result['configuration_identities'] != logical['identities']:
            raise s.Blocked('evaluation_mismatch', 'Baseline evaluation configuration differs')
        profiles = groups.setdefault(receipt['evaluation_sha256'], set())
        if result['variant'] in profiles:
            raise s.Blocked('duplicate_profile', 'Duplicate evaluation profile')
        profiles.add(result['variant'])
    if any(p != {'plain', 'terminology'} for p in groups.values()):
        raise s.Blocked('missing_profile', 'Each approved evaluation needs both profiles')
    provenance = s.detection.git_provenance(root, {}, s.reader())
    if provenance['state'] != 'observed':
        raise s.Blocked('git_unavailable', 'Cannot freeze branch provenance')
    out.mkdir(parents=True)
    value = {'schema': SCHEMA, 'root': str(root), 'authorization_reason': reason,
             'activation_authorized_by_invocation': 'tick --policy-sha256 requires this exact proposal identity',
             'semantic_review': 'agent-authored baseline; automatic successors receive mechanical checks only',
             'policy_sha256': policy['sha256'], 'helpers_sha256': hashes,
             'branch': provenance['current']['branch'],
             'baseline': snapshot(root, out, logical['sources'], bodies, index, receipts),
             'created_utc': s.now(), 'bounds': {'stage_seconds': 90, 'total_seconds': 1800}}
    s.publish(out / 'policy.json', value)
    return record(root, out / 'policy.json')


def tick(root, policy_path, approved_sha):
    """One owned refresh. Failures retain prior registration and detailed receipts.

    A failure after the atomic config replacement is reported as uncertain; the
    transaction journal, never a blind restore, determines recovery.
    """
    started = time.monotonic()
    output = None
    owner = transaction = None
    report = {'schema': SCHEMA, 'state': 'blocked', 'exit_code': 2,
              'activation_attempted': False, 'human_review': 'not performed', 'stages': []}
    try:
        root = s.safe(root)
        if root != s.TOOL.parents[1]:
            raise s.Blocked('wrong_root', 'Use this repository refresh coordinator')
        approved = json.loads(artifact(root, policy_path, approved_sha, s.BOUNDS['definition_bytes']))
        if approved.get('schema') != SCHEMA or approved.get('root') != str(root):
            raise s.Blocked('invalid_policy', 'Refresh authorization belongs to another schema/root')
        policy = s.current_policy(root, s.reader())
        if approved['policy_sha256'] != policy['sha256']:
            raise s.Blocked('policy_changed', 'Inspection policy changed; explicit review required')
        checked_helpers(root, policy, approved['helpers_sha256'])
        evidence = approved_import('refresh_evidence', root, policy, approved['helpers_sha256'])
        c = approved_import('activation_contract', root, policy, approved['helpers_sha256'])
        client = approved_import('activation_client', root, policy, approved['helpers_sha256'])
        pipeline = approved_import('prepare_candidate', root, policy, approved['helpers_sha256'])
        binding, config_raw, document = c.configuration(root)
        registered_args = document['mcp_servers'][c.SERVER]['args']
        if len(registered_args) < 7 or registered_args[6] != '--follow-project':
            raise s.Blocked('consumer_not_following', 'Enable the explicit project-following adapter before authorizing automatic activation')
        if len(registered_args) > 7 and registered_args[7:] != ['--refresh-policy', str(policy_path), '--refresh-policy-sha256', approved_sha]:
            raise s.Blocked('authorization_changed', 'Registered standing authorization differs from this operation')
        state_path = policy_path.parent / 'selected.json'
        base = selected_base(root, approved, binding, policy_path, approved_sha)
        if not 2 <= len(base['evaluations']) <= 8 or len(base['evaluations']) % 2:
            raise s.Blocked('evaluation_scope', 'Refresh baseline needs 1..4 evaluation profile pairs')
        baseline = Path(base['index'])
        prior_run = frozen_json(root, base['index_run'])
        run, logical, _, omitted = s.detection.sealed_generation(root, baseline, s.reader(), approved['helpers_sha256']['extract.py'])
        if omitted or run != prior_run or run['generation_id'] != base['generation']:
            raise s.Blocked('baseline_changed', 'Baseline publication identity/integrity differs')
        if run['identities']['runtime_sha256'] != {k: approved['helpers_sha256'][k] for k in s.RUNTIME_NAMES}:
            raise s.Blocked('runtime_changed', 'Selected generation has an unapproved runtime')
        git = s.detection.git_provenance(root, {}, s.reader())
        if git['state'] != 'observed' or git['current']['branch'] != approved['branch']:
            raise s.Blocked('branch_changed', 'Refresh authorization is branch-specific')
        current = parents(root, logical['sources'], policy)
        if all(s.sha(current[p['path']]) == p['sha256'] for p in logical['sources']):
            return {**report, 'state': 'unchanged', 'exit_code': 0, 'generation': run['generation_id']}
        if set(base['sources']) != {p['path'] for p in logical['sources']}:
            raise s.Blocked('snapshot_scope', 'Baseline snapshot enrollment differs')
        old = {path: artifact(root, Path(item['path']), item['sha256'], s.detection.LIMITS['source_bytes'])
               for path, item in base['sources'].items()}
        corp = {'schema': 'cyrus.corpus/1', 'sources': logical['sources']}
        datasets, historical, evidence_roots, historical_hashes = {}, [], [str(baseline), str(policy_path.parent)], {}
        for item in base['evaluations']:
            path = Path(item['path'])
            frozen_json(root, item)
            receipt, result, labels = s.verify_evaluation_receipt(path, run['generation_id'], s.reader())
            if result['configuration_identities'] != logical['identities']:
                raise s.Blocked('evaluation_mismatch', 'Refresh baseline evaluation differs')
            key = receipt['evaluation_sha256']
            if key in datasets and datasets[key] != labels:
                raise s.Blocked('labels_changed', 'Profile snapshots disagree')
            datasets[key] = labels
            historical.append((key, result['variant'], path))
            evidence_roots.append(str(path.parent))
            for name in ('run.json', 'results.json', 'labels-snapshot.json'):
                p = path.parent / name
                historical_hashes[p.relative_to(root).as_posix()] = s.sha(artifact(root, p))
        if not 1 <= len(datasets) <= 4 or len(historical) != 2 * len(datasets) or any(
                {profile for k, profile, _ in historical if k == key} != {'plain', 'terminology'} for key in datasets):
            raise s.Blocked('evaluation_scope', 'Refresh needs distinct plain/terminology baseline pairs')
        candidate, labels, changed = evidence.successor(corp, datasets, old, current)
        owner = s.Ownership(root, uuid.uuid4().hex)
        owner.acquire()
        run_id = 'refresh-' + time.strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8]
        output = s.fresh(root / '_local/rag/candidates' / run_id, root / '_local/rag/candidates')
        output.mkdir(parents=True)
        for name in ('stages', 'comparisons', 'transport'):
            (output / name).mkdir()
        report.update(state='preparing', output=str(output), changed_parents=changed,
                      prior_index=str(baseline), prior_generation=run['generation_id'])
        seal = {'runtime': {k: approved['helpers_sha256'][k] for k in (*s.RUNTIME_NAMES, *s.EXTRAS)},
                'inputs': {**historical_hashes, **{p: s.sha(raw) for p, raw in current.items()}},
                'policy_sha256': policy['sha256'], 'evidence_roots': evidence_roots}
        audits = [root / '_local/rag/out' / (run_id + '-audit-' + str(n)) for n in (1, 2)]
        indexes = [root / '_local/rag/indexes' / (run_id + '-' + str(n)) for n in (1, 2)]
        destinations = [output, *audits, *indexes]
        eval_outputs = {}
        for i, key in enumerate(datasets):
            for profile in ('plain', 'terminology'):
                paths = [root / '_local/rag/evaluations' / f'{run_id}-d{i}-{profile}-{n}' for n in (1, 2)]
                eval_outputs[key, profile] = paths
                destinations.extend(paths)
        for path in destinations[1:]:
            s.fresh(path, path.parent)
        def checkpoint(phase='before_replace'):
            if time.monotonic() - started > 1800:
                raise s.Blocked('total_deadline_exceeded', 'Refresh total deadline reached')
            artifact(root, policy_path, approved_sha)
            observed_policy = s.current_policy(root, s.reader())
            if observed_policy['sha256'] != policy['sha256']:
                raise s.Blocked('policy_changed', 'Policy changed during refresh')
            checked_helpers(root, observed_policy, approved['helpers_sha256'])
            for path, raw in current.items():
                s.permitted(root, root / path, observed_policy, s.reader(), s.sha(raw), s.detection.LIMITS['source_bytes'], True)
            actual, body, _ = c.configuration(root)
            if phase == 'before_replace' and (actual != binding or body != config_raw):
                raise s.Blocked('configuration_changed', 'Registration changed during preparation')
            if s.detection.git_provenance(root, {}, s.reader()).get('current') != git['current']:
                raise s.Blocked('git_changed', 'Branch/HEAD/staging changed during preparation')
            frozen_json(root, base['index_run'])
            for name, expected in run['artifact_sha256'].items():
                artifact(root, baseline / name, expected)
            for relative, expected in historical_hashes.items():
                artifact(root, root / relative, expected)
        total_reads = 0
        def stage(kind, args):
            nonlocal total_reads
            checkpoint()
            duration = min(90, 1800 - (time.monotonic() - started))
            name = f'{len(report["stages"]) + 1:02}-{kind}'
            task = {'name': name, 'kind': kind, 'args': args, 'root': str(root), 'seal': seal,
                    'outputs': list(map(str, destinations)), 'bounds': s.BOUNDS,
                    'result': str(output / 'stages' / (name + '.result.json')), 'deadline': time.monotonic() + duration}
            path = output / 'stages' / (name + '.input.json')
            s.create(path, task)
            command = pipeline.stage_process([sys.executable, '-B', str(root / 'tools/rag/candidate_worker.py'), str(path)], task, output / 'stages', duration)
            result = json.loads(artifact(root, Path(task['result'])))
            report['stages'].append({'name': name, **result})
            if command['exit_code'] != 0 or result['state'] != 'completed':
                raise s.Blocked(result.get('issue', 'stage_failed'), result.get('reason', 'Refresh stage failed'))
            total_reads += result.get('resources', {}).get('read_bytes_upper_bound', 0)
            if total_reads > s.BOUNDS['total_read_bytes']:
                raise s.Blocked('read_bound', 'Aggregate refresh stage read bound reached')
            checkpoint()
            return result['value']
        for path in audits:
            stage('audit', {'out': str(path)})
        stage('audit_compare', {'first': str(audits[0]), 'second': str(audits[1])})
        rows = {r['path']: r for r in map(json.loads, artifact(root, audits[0] / 'manifest.jsonl').splitlines())}
        for source in candidate['sources']:
            row = rows[source['path']]
            if any(source.get(k) != row.get(k) for k in PROVENANCE_FIELDS):
                raise s.Blocked('authority_changed', 'Catalog provenance changed; review required: ' + source['path'])
        corpus_path = output / 'corpus.json'
        s.create(corpus_path, candidate)
        definitions = {}
        for i, (key, dataset) in enumerate(labels.items()):
            definitions[key] = output / f'labels-{i}.json'
            s.create(definitions[key], dataset)
        for path in indexes:
            stage('build', {'out': str(path), 'corpus': str(corpus_path), 'audit': str(audits[0])})
            stage('verify', {'index': str(path)})
        target_run = json.loads(artifact(root, indexes[0] / 'run.json'))
        for key, profile, previous in historical:
            outputs = eval_outputs[key, profile]
            for index, destination in zip(indexes, outputs):
                stage('evaluate', {'index': str(index), 'definition': str(definitions[key]), 'out': str(destination), 'profile': profile})
            stage('pair_compare', dict(zip(('first', 'second', 'eval_first', 'eval_second'), map(str, [*indexes, *outputs]))))
            stage('baseline_compare', {'baseline': str(previous), 'candidate': str(outputs[0] / 'run.json'),
                'baseline_generation': run['generation_id'], 'candidate_generation': target_run['generation_id'],
                'sources_changed': True, 'out': str(output / 'comparisons' / (previous.parent.name + '.json'))})
        for path in indexes:
            stage('verify', {'index': str(path)})
        witness = client.verify(root, {**binding, 'index': str(indexes[0])}, target_run['generation_id'], len(candidate['sources']), output / 'transport')
        checkpoint()
        next_base = snapshot(root, output, candidate['sources'], current, indexes[0],
                             [p[0] / 'run.json' for p in eval_outputs.values()])
        s.create(output / 'ready.json', {'policy_sha256': approved_sha, 'baseline': next_base, 'consumer': witness})
        transaction = c.Ownership(root, uuid.uuid4().hex)
        transaction.acquire()
        after = c.replacement(root, binding, config_raw, indexes[0])
        report['activation_attempted'] = True
        c.publish_config(root, binding, config_raw, after, output, transaction, checkpoint)
        # Registration is the commit point. If this following chain receipt fails,
        # stop on the next tick; never guess a baseline or overwrite a later edit.
        next_state = {'schema': SCHEMA, 'policy_sha256': approved_sha, 'baseline': next_base,
                      'transaction': str(output), 'registration_sha256': s.sha(after)}
        s.safe(state_path, True)
        temporary = state_path.with_name('.selected-' + uuid.uuid4().hex + '.json')
        s.create(temporary, next_state)
        os.replace(temporary, state_path)
        report.update(state='activated', exit_code=0, selected_index=str(indexes[0]),
                      selected_generation=target_run['generation_id'], read_bytes_upper_bound=total_reads)
    except (Exception, KeyboardInterrupt) as exc:
        report.update(state='recovery_required' if report['activation_attempted'] else 'review_required',
                      issue=getattr(exc, 'issue', type(exc).__name__),
                      reason=str(exc)[:1500], exit_code=130 if isinstance(exc, KeyboardInterrupt) else 2)
    finally:
        for lock in (transaction, owner):
            if lock is not None and lock.stamp is not None:
                try:
                    lock.release()
                except Exception as exc:
                    report.update(state='recovery_required', issue='ownership_uncertain', reason=str(exc)[:1000], exit_code=2)
    report['duration_seconds'] = round(time.monotonic() - started, 6)
    if output is not None:
        s.publish(output / 'refresh-receipt.json', report)
    return report


@contextmanager
def watch_lease(root):
    """An OS lease expires on process death; transaction locks never do.

    Keep the lease inode/name after release so all contenders lock the same file.
    Its bytes carry no authority and are never interpreted as a PID to kill.
    """
    path = s.safe(root / '_local/rag/refresh/watch.lock', True)
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = path.open('a+b')
    locked = False
    try:
        if handle.tell() == 0:
            handle.write(b'0')
            handle.flush()
        handle.seek(0)
        try:
            if os.name == 'nt':
                import msvcrt
                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            locked = True
        except OSError as exc:
            raise s.Blocked('watcher_busy', 'Another live process owns the refresh watcher lease') from exc
        yield
    finally:
        if locked:
            handle.seek(0)
            if os.name == 'nt':
                msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(handle, fcntl.LOCK_UN)
        handle.close()


def watch_signature(root, policy_path, approved_sha):
    """Hash bounded actual inputs, not timestamps, before deciding to retry."""
    approved = json.loads(artifact(root, policy_path, approved_sha, s.BOUNDS['definition_bytes']))
    if approved.get('schema') != SCHEMA or approved.get('root') != str(root):
        raise s.Blocked('invalid_policy', 'Refresh policy schema/root differs')
    policy = s.current_policy(root, s.reader())
    if policy['sha256'] != approved['policy_sha256']:
        raise s.Blocked('policy_changed', 'Current inspection policy requires review')
    checked_helpers(root, policy, approved['helpers_sha256'])
    c = approved_import('activation_contract', root, policy, approved['helpers_sha256'])
    binding, raw, _ = c.configuration(root)
    base = selected_base(root, approved, binding, policy_path, approved_sha)
    run, logical, _, omitted = s.detection.sealed_generation(root, Path(binding['index']), s.reader(), approved['helpers_sha256']['extract.py'])
    if omitted or run != frozen_json(root, base['index_run']) or set(base['sources']) != {p['path'] for p in logical['sources']}:
        raise s.Blocked('incomplete_integrity', 'Selected index integrity is incomplete')
    bodies = parents(root, logical['sources'], policy)
    provenance = s.detection.git_provenance(root, {}, s.reader())
    if provenance['state'] != 'observed':
        raise s.Blocked('git_unavailable', 'Cannot observe branch provenance')
    return s.sha(s.encoded({'registration': s.sha(raw), 'generation': run['generation_id'],
                           'git': provenance['current'], 'parents': {p: s.sha(b) for p, b in bodies.items()}}))


def watch(root, policy_path, approved_sha, interval=60, max_seconds=43200, retry=False):
    """Bounded session loop; an identical failed input is not rebuilt repeatedly."""
    root = s.safe(root)
    if root != s.TOOL.parents[1] or not 30 <= interval <= 3600 or not interval <= max_seconds <= 43200:
        raise s.Blocked('watch_bounds', 'Use this root, 30..3600 second interval, and at most a 12-hour session')
    started = time.monotonic()
    previous = None
    last = {'schema': SCHEMA, 'state': 'starting', 'exit_code': 0}
    with watch_lease(root):
        status_path = policy_path.parent / 'watch-status.json'
        if status_path.exists() and not retry:
            saved = json.loads(artifact(root, status_path, limit=32 * 1024))
            if saved.get('policy_sha256') == approved_sha and saved.get('state') == 'review_required':
                previous, last = saved.get('input_signature'), saved
        while time.monotonic() - started < max_seconds:
            try:
                signature = watch_signature(root, policy_path, approved_sha)
                if signature != previous:
                    last = tick(root, policy_path, approved_sha)
                    previous = signature
                    # A successful switch changes the observation key once. The
                    # following tick verifies the newly selected baseline.
                    compact = {k: v for k, v in last.items() if k != 'stages'}
                    compact.update(observed_utc=s.now(), input_signature=signature, policy_sha256=approved_sha,
                                   watcher_pid=os.getpid(), watcher_running=True, retry='Changed inputs or explicit --retry')
                    target = s.safe(policy_path.parent / 'watch-status.json', True)
                    temporary = target.with_name('.watch-status-' + uuid.uuid4().hex + '.json')
                    s.create(temporary, compact)
                    os.replace(temporary, target)
                    last = compact
                if last['state'] == 'recovery_required' or last.get('exit_code') == 130:
                    break
            except (Exception, KeyboardInterrupt) as exc:
                last = {'schema': SCHEMA, 'state': 'stopped', 'exit_code': 2,
                        'issue': getattr(exc, 'issue', type(exc).__name__), 'reason': str(exc)[:1500]}
                break
            remaining = max_seconds - (time.monotonic() - started)
            if remaining > 0:
                try: time.sleep(min(interval, remaining))
                except KeyboardInterrupt:
                    last = {**last, 'state': 'cancelled', 'exit_code': 130}
                    break
        compact = {k: v for k, v in last.items() if k != 'stages'}
        compact.update(watcher_running=False, observed_utc=s.now(), watcher_pid=os.getpid())
        target = s.safe(policy_path.parent / 'watch-status.json', True)
        temporary = target.with_name('.watch-status-' + uuid.uuid4().hex + '.json')
        s.create(temporary, compact)
        os.replace(temporary, target)
    return compact


@contextmanager
def owned_control():
    """Observe control-pipe EOF without a blocked buffered reader at shutdown."""
    import _thread
    import threading
    stop = threading.Event()
    descriptor = sys.stdin.fileno()
    if os.name == 'nt':
        import ctypes
        import msvcrt
        from ctypes import wintypes
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        peek = kernel.PeekNamedPipe
        peek.argtypes = [wintypes.HANDLE, ctypes.c_void_p, wintypes.DWORD,
                         ctypes.c_void_p, ctypes.POINTER(wintypes.DWORD), ctypes.c_void_p]
        peek.restype = wintypes.BOOL
        handle = msvcrt.get_osfhandle(descriptor)
        def readable():
            available = wintypes.DWORD()
            if not peek(handle, None, 0, None, ctypes.byref(available), None):
                return True  # Closed/broken control pipe: cancel owned work.
            return available.value > 0
    else:
        import select
        def readable():
            return bool(select.select([descriptor], [], [], 0)[0])
    def observe():
        while not stop.wait(.1):
            try:
                if not readable(): continue
                if os.read(descriptor, 1): continue
            except OSError:
                pass
            if not stop.is_set(): _thread.interrupt_main()
            return
    observer = threading.Thread(target=observe, daemon=True)
    observer.start()
    try:
        yield
    finally:
        stop.set()
        observer.join()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    p = sub.add_parser('prepare')
    p.add_argument('--root', type=Path, required=True)
    p.add_argument('--index', type=Path, required=True)
    p.add_argument('--evaluation', type=Path, action='append', required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--reason', required=True)
    for action in ('tick', 'watch'):
        t = sub.add_parser(action)
        t.add_argument('--root', type=Path, required=True)
        t.add_argument('--policy', type=Path, required=True)
        t.add_argument('--policy-sha256', required=True)
        if action == 'watch':
            t.add_argument('--interval', type=float, default=60)
            t.add_argument('--max-seconds', type=float, default=43200)
            t.add_argument('--retry', action='store_true', help='explicitly retry an unchanged previously rejected input')
            t.add_argument('--owned-gate', action='store_true', help=argparse.SUPPRESS)
            t.add_argument('--diagnostics', action='store_true', help='write bounded watcher lifecycle diagnostics to stderr')
    args = parser.parse_args()
    try:
        if args.action == 'prepare':
            value = prepare(args.root, args.index, args.evaluation, args.out, args.reason)
        elif args.action == 'watch':
            if args.diagnostics:
                print('knowledge watcher entering pid=' + str(os.getpid()), file=sys.stderr, flush=True)
            if args.owned_gate:
                if sys.stdin.buffer.readline(4) != b'go\n':
                    raise s.Blocked('start_gate', 'Owned watcher start gate missing')
            try:
                if args.owned_gate:
                    with owned_control():
                        value = watch(args.root, args.policy, args.policy_sha256, args.interval, args.max_seconds, args.retry)
                else:
                    value = watch(args.root, args.policy, args.policy_sha256, args.interval, args.max_seconds, args.retry)
            finally:
                if args.diagnostics:
                    print('knowledge watcher leaving pid=' + str(os.getpid()), file=sys.stderr, flush=True)
        else:
            value = tick(args.root, args.policy, args.policy_sha256)
    except Exception as exc:
        value = {'schema': SCHEMA, 'state': 'blocked', 'exit_code': 2,
                 'issue': getattr(exc, 'issue', type(exc).__name__), 'reason': str(exc)[:1500]}
    sys.stdout.buffer.write(s.encoded(value))
    return value.get('exit_code', 0)


if __name__ == '__main__':
    raise SystemExit(main())
