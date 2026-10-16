"""Stage a managed/script successor while proving every native build input unchanged."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--native',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
native=a.native.resolve();out=a.output.resolve()
assert native.is_relative_to(ROOT/'build') and out.is_relative_to(ROOT/'build') and not out.exists()
spec=importlib.util.spec_from_file_location('offline_build',ROOT/'tools/procedural_lab/offline_build.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
receipt=json.loads((native/'receipt.json').read_text());assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
current=module.source_hashes('AminScatter');assert current.keys()==receipt['sources'].keys()
allowed={'AminScatter/scripts/AminScatterObject.ms','AminScatter/ui/LibraryGallery.cs','AminScatter/tools/build_gallery.py'}
for path,digest in receipt['sources'].items():
 if path not in allowed:assert current[path]==digest,'Native source changed; requires a new native build: '+path
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
out.mkdir(parents=True)
for path,digest in receipt['binaries'].items():
 source=ROOT/path
 if source.name=='CyrusGallery.dll':continue
 assert sha(source)==digest
 shutil.copy2(source,out/source.name)
subprocess.run([sys.executable,str(ROOT/'AminScatter/tools/build_gallery.py'),'--output',str(out/'CyrusGallery.dll')],check=True)
assert current==module.source_hashes('AminScatter'),'Sources changed during staging'
record={'project':'scatter','max_year':2027,'stages':[{'stage':'verify_unchanged_native_inputs_and_copy_exact_binaries','exit_code':0},{'stage':'compile_managed_successor','exit_code':0}],
        'sources':current,'binaries':{path.relative_to(ROOT).as_posix():sha(path) for path in out.iterdir() if path.suffix in {'.dlx','.dlh','.dlm','.dll'}},
        'native_test_receipt':str(native/'receipt.json'),'native_test_receipt_sha256':sha(native/'receipt.json'),
        'host_launched':False,'installed':False,'qualification':'Native compilation/tests inherited solely for byte-identical native inputs and artifacts; changed managed helper and script require fresh Max qualification.'}
(out/'receipt.json').write_text(json.dumps(record,indent=2)+'\n')
print('Staged exact native artifacts and newly compiled managed successor:',out)
