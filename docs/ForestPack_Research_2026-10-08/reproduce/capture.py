"""Read-only Forest inventory; raw vendor material stays in an ignored run.

Run from the repository root with a fresh --output directory. Does not load Max.
"""
import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import struct
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def scan(path, folder, pe_class):
    data = path.read_bytes()
    pe = pe_class(data)
    imports = pe.imports()
    strings = []
    for encoding, pattern in [('ascii', rb'[\x20-\x7e]{5,}'), ('utf-16le', rb'(?:[\x20-\x7e]\x00){5,}')]:
        for hit in re.finditer(pattern, data):
            try:
                rva = pe.rva(hit.start())
            except ValueError:
                continue
            strings.append(dict(rva=hex(rva), encoding=encoding, text=hit.group().decode(encoding)))
    exports = []
    export_rva, export_size = pe.directories[0]
    if export_rva:
        fields = struct.unpack_from('<IIHHIIIIIII', data, pe.offset(export_rva))
        ordinal_base, functions, names, func_table, name_table, ordinal_table = fields[5:]
        for index in range(names):
            name_rva = struct.unpack_from('<I', data, pe.offset(name_table) + index * 4)[0]
            ordinal = struct.unpack_from('<H', data, pe.offset(ordinal_table) + index * 2)[0]
            address = struct.unpack_from('<I', data, pe.offset(func_table) + ordinal * 4)[0]
            exports.append(dict(name=pe.string(name_rva), ordinal=ordinal_base+ordinal, rva=hex(address),
                                forwarded=export_rva <= address < export_rva+export_size,
                                region=pe.region(address)))
    rtti_names = sorted(set(x['text'] for x in strings if x['text'].startswith(('.?AV', '.?AU'))))
    selected_names = [x for x in rtti_names if re.search(r'forest|cloud|render|thread|cache|tree|area|surface|scatter', x, re.I)]
    folder.mkdir()
    for name, value in [('imports.json', imports), ('exports.json', exports), ('strings.json', strings),
                        ('rtti-candidates.json', rtti_names), ('selected-rtti.json', pe.rtti(selected_names))]:
        (folder/name).write_text(json.dumps(value, indent=2), encoding='utf-8')
    summary = dict(name=path.name, bytes=len(data), sha256=digest(path), image_base=hex(pe.base),
                   clr_directory=pe.directories[14], sections=pe.sections, unwind_records=len(pe.unwind),
                   named_exports=len(exports), imports=len(imports),
                   imported_modules=sorted(set(x['module'] for x in imports)),
                   rtti_candidates=len(rtti_names), selected_rtti_names=selected_names)
    (folder/'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    return summary


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    repo = Path.cwd()
    output = args.output.resolve()
    if not output.is_relative_to(repo/'build'):
        raise ValueError('Raw research must remain under ignored repository build/')
    output.mkdir(parents=True, exist_ok=False)
    spec = importlib.util.spec_from_file_location('prior_pe', repo/'docs/TyFlow_Architecture_Research_2026-10-06/reproduce/static_pe.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    installed = Path('C:/ProgramData/Autodesk/ApplicationPlugins/ForestPackLite2027')
    chosen = [installed/'PackageContents.xml', *sorted((installed/'Contents/plugins/2027').glob('Forest*.*')),
              *sorted((installed/'Contents/scripts').rglob('*'))]
    originals = []
    for path in chosen:
        if not path.is_file():
            continue
        relative = path.relative_to(installed)
        destination = output/'inputs'/relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        originals.append(dict(path=str(path), copy=str(destination), sha256=digest(path), copy_sha256=digest(destination), bytes=path.stat().st_size))
    git = {label: subprocess.check_output(command, text=True).strip() for label, command in [
        ('status', ['git','status','--short']), ('branch',['git','branch','--show-current']), ('head',['git','rev-parse','HEAD'])]}
    sources = ['AminScatter/src/point_display.cpp','AminScatter/src/mesh_display.inc','AminScatter/src/input_validity.cpp',
               'AminScatter/src/procedural.cpp','AminScatter/src/execution.cpp','AminScatter/tools/ui/templates/unified-core.ms',
               'AminScatter/scripts/AminScatterObject.ms','CyrusLicensing/README.md']
    snapshot = dict(captured_utc=datetime.now(timezone.utc).isoformat(), git=git, originals=originals,
                    source_hashes={s:digest(repo/s) for s in sources if (repo/s).is_file()})
    (output/'start-snapshot.json').write_text(json.dumps(snapshot, indent=2), encoding='utf-8')
    static = output/'static'
    static.mkdir()
    summaries = [scan(Path(item['copy']), static/Path(item['path']).stem, module.PE)
                 for item in originals if Path(item['path']).suffix in {'.dlo','.dll'}]
    (output/'module-summary.json').write_text(json.dumps(summaries, indent=2), encoding='utf-8')
    print(json.dumps(dict(output=str(output), modules=[{k:s[k] for k in ['name','bytes','image_base','unwind_records','named_exports','rtti_candidates','selected_rtti_names']} for s in summaries]),indent=2))


if __name__ == '__main__':
    main()
