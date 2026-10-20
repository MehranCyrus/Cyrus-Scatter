"""Record a README-only encoding correction without recompiling unchanged code.

The original compiled receipt and qualified binaries remain immutable. This
successor verifies every source/code/shared dependency and binary before copying
the pair. Only README.md may differ; compilation and feature tests are explicitly
not rerun for this documentation-only change.
"""
from pathlib import Path
import hashlib,json,shutil
root=Path(__file__).resolve().parents[3]
run=root/'build/physics-grip-015-20261018-01'
old=run/'qualified';new=run/'qualified-docs'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
receipt=json.loads((old/'receipt.json').read_text())
changed={p:sha(root/'CyrusPhysicsLab'/p) for p,h in receipt['source_hashes'].items() if sha(root/'CyrusPhysicsLab'/p)!=h}
assert set(changed)=={'README.md'} and not receipt['faults']
for p,h in receipt['shared_source_hashes'].items():assert sha(root/p)==h
for p,h in receipt['binaries'].items():assert sha(old/p)==h
(root/'CyrusPhysicsLab/README.md').read_text(encoding='utf-8')
new.mkdir(exist_ok=False)
for p in old.iterdir():
    if p.is_file() and p.name!='receipt.json':shutil.copy2(p,new/p.name)
receipt['documentation_only_successor']={
    'compiled_receipt':str(old/'receipt.json'),'compiled_receipt_sha256':sha(old/'receipt.json'),
    'changes':{p:{'before':receipt['source_hashes'][p],'after':h} for p,h in changed.items()},
    'compilation_repeated':False,'native_and_script_unchanged':True,
    'reason':'Correct mixed Windows/UTF-8 punctuation encoding in README; every compiled source and payload binary is unchanged.'}
receipt['source_hashes'].update(changed)
(new/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print('PASS documentation-only successor:',new)
