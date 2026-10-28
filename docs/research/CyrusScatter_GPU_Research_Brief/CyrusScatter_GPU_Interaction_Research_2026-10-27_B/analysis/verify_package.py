#!/usr/bin/env python3
"""Verify this extracted research package; optional archive parity. Standard library only."""
import argparse
import hashlib
import json
import re
import stat
import sys
import urllib.parse
import zipfile
from pathlib import Path, PurePosixPath

CORE_FILES = [
    '00_README.md', '01_EXECUTIVE_DECISION.md',
    '02_REQUIREMENTS_AND_CURRENT_SYSTEM.md', '03_PARALLELISM_AND_DATA_LAYOUT.md',
    '04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md', '05_COLLISION_AND_GUIDE_SOLVING.md',
    '06_GPU_DEFORMATION_AND_INSTANCING.md', '07_MAX_2027_INTEROP_FEASIBILITY.md',
    '08_ASYNC_PUBLICATION_AND_LIFETIMES.md', '09_MEMORY_PRECISION_AND_HARDWARE.md',
    '10_BENCHMARK_AND_VALIDATION_PLAN.md', '11_EDGE_CASE_AND_FAILURE_MATRIX.md',
    '12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md', '13_PHASED_IMPLEMENTATION_PLAN.md',
    '14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md',
    '15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md',
    '16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md', '17_SOURCE_LEDGER.md',
    '18_ACCEPTANCE_CHECKLIST.md', 'RESEARCH_METADATA.json', 'MANIFEST.sha256',
]

def digest(data):
    return hashlib.sha256(data).hexdigest()

def require(ok, message):
    if not ok:
        raise ValueError(message)

def safe_relative(name):
    p = PurePosixPath(name)
    return bool(name) and not p.is_absolute() and '..' not in p.parts and '\\' not in name

def parse_manifest(path):
    entries = {}
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        m = re.fullmatch(r'([0-9a-f]{64})  (.+)', line)
        require(m is not None, f'Malformed manifest line in {path.name}')
        sha, name = m.groups()
        require(safe_relative(name), f'Unsafe manifest path: {name}')
        require(name not in entries, f'Duplicate manifest path: {name}')
        entries[name] = sha
    return entries

def without_fences(text):
    lines, marker = [], None
    for line in text.splitlines():
        stripped = line.lstrip()
        if marker:
            if stripped.startswith(marker):
                marker = None
            continue
        if stripped.startswith('```') or stripped.startswith('~~~'):
            marker = stripped[:3]
            continue
        lines.append(line)
    return '\n'.join(lines)

def markdown_anchors(text):
    text = without_fences(text)
    result = set(re.findall(r'<a\s+id=[\"\x27]([^\"\x27]+)', text))
    counts = {}
    for line in text.splitlines():
        match = re.match(r'^#{1,6}\s+(.+?)\s*#*$', line)
        if not match:
            continue
        heading = re.sub(r'<[^>]+>', '', match.group(1)).lower()
        heading = re.sub(r'[^\w\- ]', '', heading)
        slug = heading.replace(' ', '-')
        n = counts.get(slug, 0)
        counts[slug] = n + 1
        result.add(slug if n == 0 else f'{slug}-{n}')
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', nargs='?', default='.')
    parser.add_argument('--zip', type=Path)
    args = parser.parse_args()
    root = Path(args.directory).resolve()
    for item in root.rglob('*'):
        require(not item.is_symlink(), f'Symlink not admitted: {item}')
    actual = {p.relative_to(root).as_posix(): p for p in root.rglob('*') if p.is_file()}
    require(set(CORE_FILES) <= actual.keys(), 'Missing required research file')
    manifest = parse_manifest(root / 'MANIFEST.sha256')
    require(set(manifest) == set(actual) - {'MANIFEST.sha256'}, 'Manifest/file inventory mismatch')
    for name, sha in manifest.items():
        require(digest(actual[name].read_bytes()) == sha, f'Hash mismatch: {name}')

    supplied = parse_manifest(root / 'inputs/MANIFEST.sha256')
    for name, sha in supplied.items():
        require(digest((root / 'inputs' / name).read_bytes()) == sha, f'Supplied input changed: {name}')
    meta = json.loads((root / 'RESEARCH_METADATA.json').read_text())
    require(meta['researcher_id'] == 'A', 'Wrong researcher ID')
    require(set(meta['artifact_inventory']) == set(actual), 'Metadata inventory mismatch')
    require(meta['baseline']['version'] == '0.87.4.3', 'Wrong baseline')

    ledger = json.loads((root / 'analysis/source_ledger.json').read_text())
    ids = [r['id'] for r in ledger]
    require(len(ids) == 143 and len(set(ids)) == 143, 'Source-ID count/uniqueness mismatch')
    ledger_anchors = markdown_anchors((root / '17_SOURCE_LEDGER.md').read_text())
    require(all(i.lower() in ledger_anchors for i in ids), 'Missing source-ledger anchor')

    links, external, md_count = 0, 0, 0
    for name, path in actual.items():
        if path.suffix != '.md':
            continue
        md_count += 1
        text = without_fences(path.read_text())
        for target in re.findall(r'!?\[[^\]\n]*\]\(([^)\n]+)\)', text):
            target = target.strip().split(' "', 1)[0].strip('<>')
            parts = urllib.parse.urlsplit(target)
            if parts.scheme or parts.netloc:
                external += 1
                continue
            rel = urllib.parse.unquote(parts.path)
            destination = (path.parent / rel).resolve() if rel else path.resolve()
            require(destination.is_relative_to(root), f'Link escapes package: {name}: {target}')
            require(destination.exists(), f'Broken relative link: {name}: {target}')
            if parts.fragment and destination.suffix == '.md':
                fragment = urllib.parse.unquote(parts.fragment)
                require(fragment in markdown_anchors(destination.read_text()),
                        f'Broken anchor: {name}: {target}')
            links += 1

    result = {'status':'Passed', 'required_core_files':len(CORE_FILES),
              'included_files':len(actual), 'sha256_files_verified':len(manifest),
              'unchanged_supplied_inputs_verified':len(supplied),
              'markdown_files_checked':md_count, 'local_links_and_anchors_checked':links,
              'external_links_recorded_not_network_retested':external,
              'source_records':len(ledger), 'inventory_matches':True}
    if args.zip:
        with zipfile.ZipFile(args.zip) as archive:
            infos = archive.infolist()
            names = [i.filename for i in infos]
            require(len(names) == len(set(names)), 'Duplicate ZIP member')
            expected = {root.name + '/' + name for name in actual}
            require(set(names) == expected, 'ZIP member inventory differs from extracted package')
            for info in infos:
                require(safe_relative(info.filename), f'Unsafe ZIP member: {info.filename}')
                mode = info.external_attr >> 16
                require(not stat.S_ISLNK(mode), f'ZIP symlink: {info.filename}')
                rel = PurePosixPath(info.filename).relative_to(root.name).as_posix()
                require(archive.read(info.filename) == actual[rel].read_bytes(),
                        f'ZIP byte mismatch: {rel}')
            require(archive.testzip() is None, 'ZIP CRC/integrity failure')
        result['zip_members_verified'] = len(infos)
        result['zip_safe_paths_crc_and_byte_parity'] = True
        result['zip_sha256'] = digest(args.zip.read_bytes())
    print(json.dumps(result, indent=2, sort_keys=True))

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, KeyError, zipfile.BadZipFile) as exc:
        print(f'FAIL: {exc}', file=sys.stderr)
        sys.exit(1)
