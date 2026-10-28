"""Keep the delivery's measured values tied to the sealed final host."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3];run=ROOT/'build/interactions08743-20261027-01';h=run/'host-03'
def read(name):return json.loads((h/('check-'+name+'.json')).read_text(encoding='utf-8'))
q=json.loads((run/'qualification-final.json').read_text());assert q['status']=='pass'
p=ROOT/'docs/plans/interaction-hide-wireframe-20261027/DELIVERY_08743.md';s=p.read_text(encoding='utf-8');scale=read('scale200');split=read('view-split');bend=read('bend');restore=read('restore')
s=s.replace('**2.8199 ms**','**'+str(scale['statistics']['total_ms'])+' ms**')
s=s.replace('wire draws **784 → 976**, solid draws **10,984 → 11,608**','wire draws **'+str(split['before']['mesh'][7])+' → '+str(split['after']['mesh'][7])+'**, solid draws **'+str(split['before']['mesh'][8])+' → '+str(split['after']['mesh'][8])+'**')
s=s.replace('Final r3 MZP |','Final r3 MZP, '+format(q['bytes'],',')+' bytes |')
s=s.replace('## Exact identities','The final plant-index review also found that an artificial upward footprint extent could dominate BVH splitting. The final r3 producer splits those reacting bounds horizontally; a native 5,000-plant test retains exactly one affected neighborhood. All final host assertions were repeated on r3.\n\n## Exact identities')
p.write_text(s,encoding='utf-8')
print('Final delivery uses sealed r3 measurements and identities.')
