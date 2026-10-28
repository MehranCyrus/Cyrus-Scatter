#!/usr/bin/env python3
"""Verify this research packet's files, local links, hashes and optional ZIP.

Python 3.9+ standard library only. Does not fetch public URLs or validate GPU code.
Run from the packet root: python optional/verify_package.py . [--zip ../NAME.zip]
"""
import argparse
import ast
import hashlib
import json
import re
import stat
import sys
import zipfile
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlsplit

REQUIRED = [
    '00_README.md', '01_EXECUTIVE_DECISION.md',
    '02_REQUIREMENTS_AND_CURRENT_SYSTEM.md', '03_PARALLELISM_AND_DATA_LAYOUT.md',
    '04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md', '05_COLLISION_AND_GUIDE_SOLVING.md',
    '06_GPU_DEFORMATION_AND_INSTANCING.md', '07_MAX_2027_INTEROP_FEASIBILITY.md',
    '08_ASYNC_PUBLICATION_AND_LIFETIMES.md', '09_MEMORY_PRECISION_AND_HARDWARE.md',
    '10_BENCHMARK_AND_VALIDATION_PLAN.md', '11_EDGE_CASE_AND_FAILURE_MATRIX.md',
    '12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md', '13_PHASED_IMPLEMENTATION_PLAN.md',
    '14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md', '15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md',
    '16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md', '17_SOURCE_LEDGER.md', '18_ACCEPTANCE_CHECKLIST.md',
    'RESEARCH_METADATA.json', 'SOURCE_LEDGER.json', 'ARTIFACT_VERIFICATION.json',
    'MANIFEST.sha256', 'optional/README.md', 'optional/research_checks.py',
    'optional/executed_checks.json', 'optional/benchmark_cases.json', 'optional/verify_package.py',
]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def markdown_prose(text):
    """Ignore fenced code when checking prose links/anchors; check balanced fences."""
    lines, fence, size = [], None, 0
    for line in text.splitlines():
        m = re.match(r'^\s{0,3}(`{3,}|~{3,})', line)
        if m:
            ch, n = m[1][0], len(m[1])
            if fence is None:
                fence, size = ch, n
            elif ch == fence and n >= size:
                fence, size = None, 0
            continue
        if fence is None:
            lines.append(line)
    if fence:
        raise ValueError('Unclosed Markdown code fence')
    return '\n'.join(lines)


def anchors(text):
    result = set(re.findall(r'<a\s+id=["\']([^"\']+)["\']', text))
    duplicates = {}
    for line in text.splitlines():
        m = re.match(r'^#{1,6}\s+(.+?)\s*#*$', line)
        if not m:
            continue
        title = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', m[1])
        title = re.sub(r'<[^>]+>', '', title).lower().replace('`', '')
        slug = re.sub(r'[^\w\- ]', '', title).replace(' ', '-')
        count = duplicates.get(slug, 0)
        duplicates[slug] = count + 1
        result.add(slug if count == 0 else f'{slug}-{count}')
    return result


def verify(root, zip_path=None):
    root = root.resolve()
    errors = []
    for p in root.rglob('*'):
        if p.is_symlink():
            errors.append(f'Symlink not allowed in deliverable: {p.relative_to(root)}')
    files = {p.relative_to(root).as_posix(): p for p in root.rglob('*') if p.is_file()}
    missing = sorted(set(REQUIRED) - files.keys())
    if missing:
        errors.append('Missing required files: ' + ', '.join(missing))
    texts, parsed_json = {}, {}
    for rel, p in files.items():
        try:
            if p.suffix == '.md':
                texts[rel] = markdown_prose(p.read_text(encoding='utf-8'))
            elif p.suffix == '.json':
                parsed_json[rel] = json.loads(p.read_text(encoding='utf-8'))
            elif p.suffix == '.py':
                ast.parse(p.read_text(encoding='utf-8'), filename=rel)
        except (ValueError, SyntaxError, UnicodeError) as exc:
            errors.append(f'{rel}: {exc}')
    anchor_sets = {rel: anchors(t) for rel, t in texts.items()}
    local_links = 0
    external_links = 0
    for rel, text in texts.items():
        # All authored relative links use plain Markdown destinations without spaces.
        for m in re.finditer(r'!?\[[^\]\n]+\]\(([^\s)]+)(?:\s+"[^"]*")?\)', text):
            href = m[1]
            parsed = urlsplit(href)
            if parsed.scheme or parsed.netloc:
                external_links += 1
                continue
            local_links += 1
            candidate = (root / rel).parent / unquote(parsed.path) if parsed.path else root / rel
            target = candidate.resolve()
            try:
                target_rel = target.relative_to(root).as_posix()
            except ValueError:
                errors.append(f'{rel}: link escapes packet: {href}')
                continue
            if target_rel not in files:
                errors.append(f'{rel}: missing local target {href}')
            elif parsed.fragment and target.suffix == '.md' and unquote(parsed.fragment) not in anchor_sets.get(target_rel, set()):
                errors.append(f'{rel}: missing anchor {href}')
    manifest = {}
    if 'MANIFEST.sha256' in files:
        for line in files['MANIFEST.sha256'].read_text().splitlines():
            if not line:
                continue
            m = re.fullmatch(r'([0-9a-f]{64})  (.+)', line)
            if not m:
                errors.append('Malformed manifest line: ' + line)
                continue
            sha, rel = m.groups()
            if rel in manifest:
                errors.append('Duplicate manifest member: ' + rel)
            manifest[rel] = sha
        expected = set(files) - {'MANIFEST.sha256'}
        if set(manifest) != expected:
            errors.append('Manifest member mismatch: ' + repr(sorted(set(manifest) ^ expected)))
        for rel, sha in manifest.items():
            if rel not in files or digest(files[rel].read_bytes()) != sha:
                errors.append('Manifest hash mismatch: ' + rel)
    meta = parsed_json.get('RESEARCH_METADATA.json', {})
    if set(meta.get('artifact_inventory', [])) != set(files):
        errors.append('Metadata inventory does not exactly match packet files')
    cases = parsed_json.get('optional/benchmark_cases.json', {}).get('cases', [])
    if [c.get('id') for c in cases] != [f'B{i:02}' for i in range(1, 19)]:
        errors.append('Benchmark case IDs incomplete or out of order')
    for i, c in enumerate(cases, 1):
        if c.get('seed') != 20261027+i or c.get('execution_status') != 'Not executed':
            errors.append('Benchmark seed/execution status mismatch: ' + c.get('id', '?'))
    ledger = parsed_json.get('SOURCE_LEDGER.json', {}).get('source_records', [])
    if len(ledger) != 116 or len({r.get('id') for r in ledger}) != 116:
        errors.append('Source ledger count/unique IDs mismatch')
    for r in ledger:
        if r['id'].lower() not in anchor_sets.get('17_SOURCE_LEDGER.md', set()):
            errors.append('Source ID has no Markdown anchor: ' + r['id'])
    checks = parsed_json.get('optional/executed_checks.json', {})
    if checks.get('passed') != 10 or any(c.get('status') != 'PASS' for c in checks.get('checks', [])):
        errors.append('Recorded analytic check status/count mismatch')
    zip_result = {'status': 'Not requested'}
    if zip_path:
        try:
            with zipfile.ZipFile(zip_path) as z:
                names = z.namelist()
                if len(names) != len(set(names)):
                    errors.append('Duplicate ZIP member paths')
                expected_names = {root.name + '/' + rel for rel in files}
                actual_names = {i.filename for i in z.infolist() if not i.is_dir()}
                if actual_names != expected_names:
                    errors.append('ZIP contents differ from packet inventory')
                for info in z.infolist():
                    p = PurePosixPath(info.filename)
                    if p.is_absolute() or '..' in p.parts or '\\' in info.filename or (p.parts and ':' in p.parts[0]):
                        errors.append('Unsafe ZIP member: ' + info.filename)
                    if stat.S_ISLNK(info.external_attr >> 16):
                        errors.append('ZIP contains symlink: ' + info.filename)
                bad = z.testzip()
                if bad:
                    errors.append('ZIP CRC failure: ' + bad)
                matched = 0
                for rel, p in files.items():
                    name = root.name + '/' + rel
                    if name in actual_names:
                        if z.read(name) != p.read_bytes():
                            errors.append('ZIP bytes differ from local file: ' + rel)
                        else:
                            matched += 1
                zip_result = {'status': 'PASS' if not errors else 'FAIL', 'file_members': len(actual_names),
                              'byte_identical_members': matched, 'crc': 'PASS' if bad is None else 'FAIL',
                              'safe_member_paths': not any('ZIP member' in e or 'ZIP contains symlink' in e for e in errors)}
        except (OSError, zipfile.BadZipFile) as exc:
            errors.append('ZIP open/validation failed: ' + str(exc))
            zip_result = {'status': 'FAIL', 'error': str(exc)}
    return {'schema': 'cyrus.gpu.research.package-check/1', 'status': 'PASS' if not errors else 'FAIL',
            'required_files': len(REQUIRED), 'file_count': len(files), 'markdown_files': len(texts),
            'local_links_checked': local_links, 'external_links_not_refetched': external_links,
            'json_files_parsed': len(parsed_json), 'python_sources_syntax_checked': sum(p.suffix=='.py' for p in files.values()),
            'manifest_hashes_checked': len(manifest), 'source_records': len(ledger),
            'zip': zip_result, 'errors': errors,
            'limits': 'Structural/artifact validation only; public URLs not refetched; no GPU, Max, fitter or renderer execution.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--zip', dest='zip_path', type=Path)
    args = parser.parse_args()
    result = verify(args.directory, args.zip_path)
    print(json.dumps(result, indent=2))
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    sys.exit(main())
