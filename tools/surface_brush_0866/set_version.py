"""Apply the user-selected 0.86.6 identity; preserve historical 0.87.0 receipts."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
paths=['AminScatter/tools/ui/templates/unified-core.ms','CyrusMCP/tests/test_feature_catalog.py',
       'tools/procedural_lab/check_generated.py','AminScatter/tools/ui/templates/approved-main-ui.ms',
       'AminScatter/tools/ui/templates/recipes.ms','AminScatter/ui/LibraryGallery.cs']
for name in paths:
 p=ROOT/name;s=p.read_text(encoding='utf-8');p.write_text(s.replace('0.87.0','0.86.6'),encoding='utf-8')
p=ROOT/'CyrusMCP/cyrus_mcp/feature-catalog.json';d=json.loads(p.read_text());d['development_version']='0.86.6';p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=ROOT/'docs/Release_Versioning.md';s=p.read_text(encoding='utf-8')
s=s.replace('| Scatter UI | 0.87.0 |','| Scatter UI | 0.86.6 |').replace('| Scatter native/package | 0.87.0 Max 2027;', '| Scatter native/package | 0.86.6 Max 2027 candidate;')
marker='## Choosing the next version\n'
decision='''
**19 October 2026 user-selected correction and surface brush delivery:** the user
assigns the completed library/Amount reliability changes to **0.86.5** and this
surface Paint restoration to **0.86.6**, explicitly superseding the 0.87.0 minor
selection below. The original 0.87.0 artifacts and qualification remain unchanged
and identified by their original hashes. The 0.86.5 baseline denotes that same
feature set, not a claim that old artifacts were compiled with a different label.
0.86.6 includes the complete baseline and restored sphere/box/curved painting.
Scene schema 58, recipe 7 and independent product versions remain unchanged;
curved Paint has an additive vector payload discriminator and requires its matched
native modules. [Implementation/acceptance](plans/preset-gallery-improvements/BRUSH_0866.md)
owns the new Max 2027 qualification and MZP/EXE delivery. No artist installation,
restart, older-host qualification or website publication is authorized.

'''
assert marker in s
if '**19 October 2026 user-selected correction and surface brush delivery:**' not in s:s=s.replace(marker,marker+decision,1)
s=s.replace('**Active 19 October reliability goal — delivered 0.87.0.**','**Historical 19 October reliability delivery — originally labeled 0.87.0; feature baseline corrected to 0.86.5 above.**')
p.write_text(s,encoding='utf-8')
print('0.86.6 product identity selected; historical receipts preserved')
