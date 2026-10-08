"""Query selected anchors in an owned Ghidra project; no target execution."""
import argparse
import importlib.util
import json
from pathlib import Path


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--run',type=Path,required=True)
    parser.add_argument('--schema',action='store_true')
    parser.add_argument('--anchors',action='store_true')
    args=parser.parse_args();run=args.run.resolve()
    if not run.is_relative_to(Path.cwd()/'build'):raise ValueError('Use build run')
    if args.schema:
        schema=json.loads((run/'live-schema.json').read_text())
        print(json.dumps([t for t in schema['tools'] if t['path'] in ['/open_project','/get_disassembly','/get_function_disassembly','/get_function_xrefs']],indent=2));return
    backend_path=Path('docs/ForestPack_Research_2026-10-08/reproduce/backend.py')
    spec=importlib.util.spec_from_file_location('backend',backend_path)
    backend=importlib.util.module_from_spec(spec);spec.loader.exec_module(backend)
    if args.anchors:
        prior=Path('docs/ForestPack_Research_2026-10-08/reproduce/find_anchors.py')
        spec=importlib.util.spec_from_file_location('anchors',prior)
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        entries=[(s['text'],hex(0x180000000+int(s['rva'],16))) for s in json.loads((run/'brush-anchors.json').read_text()) if int(s['rva'],16)<0x300000]
        source=module.JAVA.replace('__ENTRIES__',','.join('{'+json.dumps(a)+','+json.dumps(b)+'}' for a,b in entries)).replace('__OUTPUT__',json.dumps((run/'brush-xrefs.tsv').as_posix()))
        (run/'brush-anchor-request.json').write_text(json.dumps({'code':source}),encoding='utf-8')
        response=backend.request(18091,'POST','/run_script_inline',{'code':source},60)
        (run/'brush-anchor-response.txt').write_text(response,encoding='utf-8')
        print(response[-8500:])


if __name__=='__main__':main()
