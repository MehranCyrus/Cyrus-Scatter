"""Read-only compact front door. Existing retrieval, MCP and selected indexes stay intact."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tomllib

from context_projection import render

MAX_WIRE = 4 * 1024 * 1024


def regular(path, limit):
    path = Path(path)
    # Reject links/junctions at every existing ancestor, including selection files.
    for parent in (path, *path.parents):
        try:
            attributes = parent.lstat()
        except FileNotFoundError:
            continue
        if stat.S_ISLNK(attributes.st_mode) or getattr(attributes, 'st_file_attributes', 0) & getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0):
            raise ValueError('Linked context input is not supported')
    if not path.is_file() or path.stat().st_size > limit:
        raise ValueError('Missing or oversized context input: ' + str(path))
    raw = path.read_bytes()
    if len(raw) > limit:
        raise ValueError('Context input grew beyond its bound')
    return raw


def index_binding(root, explicit=None, legacy=False):
    selection = root / '_local/rag/harness/selected.json'
    if explicit:
        index = Path(os.path.abspath(explicit))
        info = {'mode': 'explicit', 'scope': 'Caller-selected evidence scope'}
        expected = None
    elif (selection.exists() or selection.is_symlink()) and not legacy:
        saved = json.loads(regular(selection, 64 * 1024))
        if saved.get('schema') != 'cyrus.context-selection/1':
            raise ValueError('Unsupported context selection')
        index = Path(os.path.abspath(root / saved['index']))
        expected = saved['generation']
        if not re.fullmatch('[0-9a-f]{64}', expected):
            raise ValueError('Invalid pinned generation')
        info = {'mode': 'scoped', 'scope': saved['scope'],
                'exclusions': saved['exclusions'], 'review_receipt': saved['review_receipt']}
        receipt = root / saved['review_receipt']
        if not receipt.resolve().is_relative_to((root / '_local/rag').resolve()):
            raise ValueError('Review receipt must stay inside the owned knowledge store')
        receipt_bytes = regular(receipt, 1024 * 1024)
        if hashlib.sha256(receipt_bytes).hexdigest() != saved['review_sha256']:
            raise ValueError('Context review receipt changed')
        review = json.loads(receipt_bytes)
        if (review.get('schema') != 'cyrus.context-review/1'
                or review.get('status') != 'approved_scoped'
                or review.get('generation') != expected
                or review.get('agent_reviewed') is not True):
            raise ValueError('Context scope has no matching reviewed acceptance')
    else:
        entry = tomllib.loads(regular(root / '.codex/config.toml', 64 * 1024).decode('utf-8'))['mcp_servers']['cyrus_knowledge']
        args = entry['args']
        if len(args) not in (7, 11) or args[:5] != ['-B', str(root / 'tools/rag/adapter.py'), '--root', str(root), '--index'] or args[6] != '--follow-project':
            raise ValueError('Unsupported project knowledge binding')
        index = Path(os.path.abspath(args[5]))
        info = {'mode': 'legacy-project', 'scope': 'Existing explicit project enrollment; check freshness',
                'scoped_snapshot_available': False}
        expected = None
    store = root / '_local/rag/indexes'
    if not index.is_relative_to(store) or index == store:
        raise ValueError('Index must stay inside this repository knowledge store')
    publication = json.loads(regular(index / 'run.json', MAX_WIRE))
    if not publication.get('complete') or publication['identities']['root'] != str(root):
        raise ValueError('Incomplete or foreign knowledge generation')
    generation = publication['generation_id']
    if expected and expected != generation:
        raise ValueError('Pinned context generation changed')
    info['generation'] = generation
    return index, info


def execute(root, index, selection, name, arguments):
    request = {'name': name, 'arguments': arguments, 'root': str(root),
               'index': str(index), 'generation': selection['generation']}
    # Reuse the existing network-denied, identity-checking worker unchanged.
    process = subprocess.run([sys.executable, '-I', '-B', str(root / 'tools/rag/adapter_worker.py')],
                             input=json.dumps(request).encode('utf-8'), capture_output=True,
                             timeout=15, creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
    if len(process.stdout) > MAX_WIRE or len(process.stderr) > 64 * 1024:
        raise ValueError('Worker output exceeded the context bound')
    if process.returncode:
        raise ValueError('Read-only knowledge worker failed; use the existing full tool for diagnostics')
    result = json.loads(process.stdout)
    if result.get('ok') and result.get('index_generation') != selection['generation']:
        raise ValueError('Worker returned another generation')
    return result


def facts(root):
    path = root / 'docs/KNOWLEDGE_BASELINE.json'
    data = json.loads(regular(path, 64 * 1024))
    if data.get('schema') != 'cyrus.knowledge-baseline/1':
        raise ValueError('Unsupported delivered facts')
    proof_path = root / data['delivery_receipt']
    if not proof_path.resolve().is_relative_to(root):
        raise ValueError('Delivery proof is outside repository')
    proof = json.loads(regular(proof_path, 1024 * 1024))
    if proof.get('status') != 'scoped_pass':
        raise ValueError('Delivery receipt has no scoped pass')
    for key, source in [('version', 'version'), ('scene_schema', 'scene_schema'),
                        ('recipe_format', 'recipe_format'), ('edit_storage', 'edit_storage'),
                        ('max_year', 'max_year'), ('interactions', 'interactions')]:
        if type(data['delivered'][key]) is not type(proof[source]) or data['delivered'][key] != proof[source]:
            raise ValueError('Delivered fact disagrees with its qualification receipt: ' + key)
    text = regular(root / 'AminScatter/CMakeLists.txt', 512 * 1024).decode('utf-8-sig')
    match = re.search(r'^project\(CyrusScatter VERSION ([0-9.]+) LANGUAGES CXX\)', text, re.M)
    if not match:
        raise ValueError('Working Scatter version is unavailable')
    return {**data, 'schema': 'cyrus.context-facts/1', 'ok': True,
            'working_tree_version': match[1],
            'working_tree_qualification': 'Not inferred from a source version or this knowledge snapshot',
            'delivery_receipt_sha256': hashlib.sha256(regular(proof_path, 1024 * 1024)).hexdigest()}


def main(argv=None):
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--index', type=Path)
    parser.add_argument('--legacy', action='store_true', help='Inspect the original project index explicitly')
    parser.add_argument('--detail', choices=['compact', 'full'], default='compact')
    parser.add_argument('--max-chars', type=int, default=24000)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('facts')
    status = sub.add_parser('status'); status.add_argument('--verify-sources', action='store_true')
    search = sub.add_parser('search'); search.add_argument('query')
    search.add_argument('--mode', choices=['keyword', 'identifier', 'path'], default='keyword')
    search.add_argument('--top-k', type=int, choices=range(1, 11), default=2)
    search.add_argument('--component'); search.add_argument('--role'); search.add_argument('--knowledge-status')
    args = parser.parse_args(argv)
    try:
        if not 512 <= args.max_chars <= MAX_WIRE:
            raise ValueError('--max-chars must be 512..4194304')
        if args.index and args.legacy:
            raise ValueError('Choose explicit index or legacy binding')
        root = Path(os.path.abspath(args.root))
        if args.command == 'facts':
            value = render(facts(root), {'mode': 'delivered-facts'}, args.detail, args.max_chars)
        else:
            index, selection = index_binding(root, args.index, args.legacy)
            if args.command == 'status':
                name, arguments = 'knowledge_status', {'verify_sources': args.verify_sources}
            else:
                name = 'knowledge_search'
                arguments = {'query': args.query, 'mode': args.mode, 'top_k': args.top_k}
                arguments.update({key: getattr(args, key) for key in ['component', 'role', 'knowledge_status'] if getattr(args, key) is not None})
            value = render(execute(root, index, selection, name, arguments), selection, args.detail, args.max_chars)
        print(json.dumps(value, ensure_ascii=False, separators=(',', ':')))
        return 0 if value.get('ok') else 2
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as exc:
        print(json.dumps({'schema': 'cyrus.context-error/1', 'ok': False,
                          'error_type': 'context_unavailable', 'error': str(exc),
                          'action': 'Inspect the explicit binding or use direct original sources; no fallback was selected.'}))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
