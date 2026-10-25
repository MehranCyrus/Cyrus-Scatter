"""Verify documentation integrity; this never runs a DCC or tests a solver."""
from __future__ import annotations

import hashlib
import json
import re
import sys
import zipfile
from collections import Counter
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

sys.dont_write_bytecode = True
import build_handbook as book

ROOT = book.ROOT


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.append(attrs['id'])
        if tag == 'a' and 'href' in attrs:
            self.hrefs.append(attrs['href'])


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    from pypdf import PdfReader

    errors = []
    manifest = json.loads((ROOT / 'sources/manifest.json').read_text(encoding='utf-8'))
    sources = manifest['sources']
    if len(sources) != manifest['source_count'] or len({r['id'] for r in sources}) != len(sources):
        errors.append('Original source count/identity does not match the manifest')
    declared = {(ROOT / 'sources' / r['file']).resolve() for r in sources}
    if declared != {p.resolve() for p in (ROOT / 'sources/originals').iterdir() if p.is_file()}:
        errors.append('Original source files do not match the manifest inventory')
    for row in sources:
        path = ROOT / 'sources' / row['file']
        if not path.is_file() or path.stat().st_size != row['bytes'] or sha(path) != row['sha256']:
            errors.append('Original integrity: ' + row['id'])
    associated = manifest.get('associated_artifacts', [])
    embedded_member_hashes = 0
    embedded_result_agreements = {}
    for row in associated:
        path = ROOT / 'sources' / row['file']
        if not path.is_file() or path.stat().st_size != row['bytes'] or sha(path) != row['sha256']:
            errors.append('Associated artifact integrity: ' + row['id'])
        elif path.suffix == '.zip':
            with zipfile.ZipFile(path) as archive:
                if archive.testzip() is not None:
                    errors.append('Associated ZIP CRC: ' + row['id'])
                if row['id'] == 'R13-E01':
                    prefix = 'cyrus_jolt_reuse/'
                    provenance = json.loads(archive.read(prefix + 'provenance_manifest.json'))
                    for member, expected in provenance['artifacts'].items():
                        data = archive.read(prefix + member)
                        embedded_member_hashes += 1
                        if len(data) != expected['bytes'] or hashlib.sha256(data).hexdigest() != expected['sha256']:
                            errors.append('R13 declared member integrity: ' + member)
                    external_result = next((a for a in associated if a['id'] == 'R13-E02'), None)
                    agreement = external_result is not None and (
                        (ROOT / 'sources' / external_result['file']).read_bytes() ==
                        archive.read(prefix + 'experiments/probe_results.json'))
                    embedded_result_agreements['R13-E02'] = agreement
                    if not agreement:
                        errors.append('R13 separate result JSON must match its final archive member')
                if row['id'] == 'R14-E01':
                    prefix = 'collision_study/'
                    provenance = json.loads(archive.read(prefix + 'pin_provenance.json'))
                    for member, expected in provenance['artifact_sha256'].items():
                        data = archive.read(prefix + member)
                        embedded_member_hashes += 1
                        if hashlib.sha256(data).hexdigest() != expected:
                            errors.append('R14 declared member integrity: ' + member)
                    for identity, member in [('R14-E02', 'harness_results.json'), ('R14-E03', 'analytic_results.json')]:
                        copied = next((a for a in associated if a['id'] == identity), None)
                        agreement = copied is not None and (
                            (ROOT / 'sources' / copied['file']).read_bytes() == archive.read(prefix + member))
                        embedded_result_agreements[identity] = agreement
                        if not agreement:
                            errors.append('R14 result copy must match its archive member: ' + member)

    markdown = sorted(p for p in ROOT.rglob('*.md') if 'originals' not in p.parts)
    md_link_count = 0
    for path in markdown:
        text = path.read_text(encoding='utf-8')
        for match in book.INLINE.finditer(text):
            if match.group(1) is None:
                continue
            href = match.group(2).strip('<>')
            parts = urlsplit(href)
            if parts.scheme or href.startswith('//'):
                continue
            md_link_count += 1
            local = (path.parent / unquote(parts.path)).resolve() if parts.path else path
            if not local.exists() and local != ROOT / 'references/package-verification.json':
                errors.append(f'Missing local link: {path.name} -> {href}')
            elif parts.fragment and local.suffix == '.md':
                headings = re.findall(r'^#+ (.+)$', local.read_text(encoding='utf-8'), re.M)
                anchors = {book.slug(h) for h in headings}
                if unquote(parts.fragment) not in anchors:
                    errors.append(f'Missing Markdown anchor: {path.name} -> {href}')

    parsed = Links()
    parsed.feed((ROOT / 'handbook.html').read_text(encoding='utf-8'))
    duplicate = [key for key, count in Counter(parsed.ids).items() if count > 1]
    errors += ['Duplicate HTML id: ' + key for key in duplicate]
    html_links = 0
    for href in parsed.hrefs:
        parts = urlsplit(href)
        if parts.scheme:
            continue
        html_links += 1
        if parts.path:
            if not (ROOT / unquote(parts.path)).resolve().exists():
                errors.append('Missing HTML file link: ' + href)
        elif parts.fragment not in parsed.ids:
            errors.append('Missing HTML anchor: ' + href)

    matrix = (ROOT / 'checklists/VALIDATION-MATRIX.md').read_text(encoding='utf-8')
    cases = re.findall(r'^\| (V\d+) \|.+\| Pending \|$', matrix, re.M)
    all_cases = re.findall(r'^\| (V\d+) \|', matrix, re.M)
    expected_ids = [f'V{i:02d}' for i in range(1, len(all_cases) + 1)]
    if not cases or cases != all_cases or cases != expected_ids:
        errors.append('Validation cases must be sequential, unique and explicitly Pending')
    if len(book.CHAPTERS) != 9:
        errors.append('Expected nine numbered chapters')
    experiments = (ROOT / 'checklists/SOLVER-DECISION-EXPERIMENTS.md').read_text(encoding='utf-8')
    experiment_ids = re.findall(r'^## (R12-E\d+):', experiments, re.M)
    if experiment_ids != [f'R12-E{i}' for i in range(1, 9)]:
        errors.append('Expected eight sequential R12 decision experiments')
    pending_experiments = re.findall(r'^\*\*Status: Pending\. Matrix:', experiments, re.M)
    if len(pending_experiments) != len(experiment_ids):
        errors.append('Every decision experiment must remain explicitly Pending')
    for path in ROOT.rglob('*.json'):
        json.loads(path.read_text(encoding='utf-8'))

    reader = PdfReader(ROOT / 'handbook.pdf')
    text = '\n'.join(p.extract_text() or '' for p in reader.pages)
    normalized = ' '.join(re.findall(r'\w+', text.lower()))
    checked_headings = 0
    for path in [*book.CHAPTERS, *book.APPENDICES]:
        for kind, value in book.blocks(path):
            if kind == 'heading':
                heading = ' '.join(re.findall(r'\w+', value[1].lower()))
                checked_headings += 1
                if heading not in normalized:
                    errors.append(f'PDF missing heading: {path.name}: {value[1]}')
    if any(len((page.extract_text() or '').strip()) < 100 for page in reader.pages):
        errors.append('PDF unexpectedly contains an empty or nearly empty page')

    receipt = {
        'schema': 1, 'verified_at_utc': datetime.now(timezone.utc).isoformat(),
        'scope': 'Documentation integrity and text coverage; no solver/host qualification',
        'outcome': 'pass' if not errors else 'fail', 'errors': errors,
        'checks': {'original_files_hashed': len(sources), 'associated_artifacts_hashed': len(associated),
            'embedded_declared_member_hashes_checked': embedded_member_hashes,
            'embedded_result_json_agreement': all(embedded_result_agreements.values()) if embedded_result_agreements else None,
            'embedded_result_json_agreements': embedded_result_agreements,
            'canonical_numbered_chapters': len(book.CHAPTERS),
            'pending_validation_cases': len(cases), 'owned_markdown_files': len(markdown),
            'pending_solver_decision_experiments': len(experiment_ids),
            'local_markdown_links_checked': md_link_count, 'local_html_links_checked': html_links,
            'pdf_pages': len(reader.pages), 'pdf_headings_present': checked_headings},
        'presentation_review': 'See VERIFICATION.md; page rendering is a separate visual check',
        'artifacts': {name: {'bytes': (ROOT / name).stat().st_size, 'sha256': sha(ROOT / name)}
            for name in ['handbook.html', 'handbook.pdf']},
    }
    (ROOT / 'references/package-verification.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(receipt, indent=2))
    if errors:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
