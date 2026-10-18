"""Repeat complete Count parity using frozen old scenes, including variation IDs."""
import argparse,json
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
old=ROOT/'build/mcp-qualification/foundation-memory0854-nativeobserve-baseline-20261018-02'
hashes={}
for line in (old/'native-baseline.tsv').read_text().splitlines():
    parts=line.split('\t');key=(parts[0],int(parts[2]))
    if key in hashes:assert hashes[key]==parts[15]
    hashes[key]=parts[15]
script=h/'saved-counts.ms';passed=[]
for kind in ('plane','mountain'):
    script.write_text('''loadMaxFile @"'''+(old/f'n01-{kind}.max').as_posix()+'''" quiet:true useFileUnits:true
global SCNode=getNodeByName "N01 '''+kind+''' controller",SCRoot=SCNode.baseObject,SCLeaf=SCRoot.layerObjects[1]
clearSelection();max create mode
''');send(h,script,'saved '+kind)
    for count in (5000,50000,90000,200000,5000):
        script.write_text(f'''SCLeaf.amount={count};SCRoot.refreshAll()
if SCLeaf.previewError!="" do throw SCLeaf.previewError
if not cyrusPlacementIsNative SCRoot.groupSnapshotRows[1] do throw "Native publication required"
if (cyrusRecipePublicationFingerprint SCRoot.groupSnapshotRows)!="{hashes[(kind,count)]}" do throw "Saved baseline full Count fingerprint mismatch"
''');send(h,script,f'{kind} {count}');passed.append([kind,count,hashes[(kind,count)]])
(h/'saved-counts.json').write_text(json.dumps({'status':'passed','cases':passed,
    'scope':'Complete ordered fields of exact old saved scenes; concurrent soak means no timing claim.'},indent=2)+'\n')
print('EXACT SAVED BASELINE COUNT PARITY PASSED',flush=True)
