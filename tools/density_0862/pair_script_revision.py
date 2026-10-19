"""Pin a script-only pair to an immutable tested native build; never claim a rebuild."""
from pathlib import Path
import argparse,hashlib,json,shutil,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from offline_build import source_hashes
p=argparse.ArgumentParser();p.add_argument('--native',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
native=a.native.resolve();out=a.output.resolve();assert not out.exists()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
receipt=json.loads((native/'receipt.json').read_text(encoding='utf-8'))
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
assert not receipt.get('script_only_revision')
sources=source_hashes('AminScatter')
delta=[n for n in sources if sources[n]!=receipt['sources'].get(n)]
assert set(sources)==set(receipt['sources']) and delta==['AminScatter/scripts/AminScatterObject.ms'],delta
for name,digest in receipt['binaries'].items():assert sha(ROOT/name)==digest,name
out.mkdir(parents=True)
binaries={}
for name in ['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusGallery.dll']:
    source=native/name;assert source.as_posix() in receipt['binaries']
    shutil.copy2(source,out/name);binaries[(out/name).as_posix()]=sha(out/name)
for name in ('CyrusGallery.build.json','tests.log'):shutil.copy2(native/name,out/name)
data={**receipt,'sources':sources,'binaries':binaries,'stages':[{'stage':'verify_unchanged_native_sources_and_binary_hashes','exit_code':0}],
 'script_only_revision':{'native_build_receipt':(native/'receipt.json').as_posix(),'native_build_receipt_sha256':sha(native/'receipt.json'),'original_script_sha256':receipt['sources'][delta[0]],'revised_script_sha256':sources[delta[0]],'native_tests_log_sha256':sha(native/'tests.log')},
 'qualification':'Verified script-only pairing. No native rebuild or repeated native tests: original native build/test receipt remains immutable and all native source/binary bytes match. Generated MAXScript requires fresh host qualification.'}
(out/'receipt.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps(data['script_only_revision'],indent=2))
