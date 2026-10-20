"""Derive scoped 2027-only checks; keep original delivery fixtures untouched."""
from pathlib import Path
root=Path(__file__).resolve().parents[2];out=Path(__file__).parent
assert not any((out/name).exists() for name in ('package.py','RecipientChecks.cs','UiChecks.cs')), 'Initial scaffold only: preserve the maintained delivery tools'
s=(root/'tools/reliability_0870/package.py').read_text().replace('0.87.0','0.86.6').replace('build/reliability-0870-20261019','build/surface-brush-0866-20261019')
s=s.replace('qualified native10 pair','qualified surface-brush pair')
(out/'package.py').write_text(s,encoding='utf-8')
s=(root/'tools/installer_0862/RecipientChecks.cs').read_text().replace('if0862','if0866').replace('0.86.2','0.86.6')
s=s.replace('=="2024,2026,2027"','=="2027"').replace('three matching host packages','matched Max 2027 package').replace('Same-version upgrade publishes compact runtime','Original 0.87.0 to 0.86.6 upgrade publishes selected runtime')
(out/'RecipientChecks.cs').write_text(s,encoding='utf-8')
s=(root/'tools/installer_0862/UiChecks.cs').read_text().replace('if0862','if0866').replace('host.Items.Count==3','host.Items.Count==1').replace('All three installed Max versions are automatically detected','Only qualified Max 2027 is offered')
s=s.replace('host.Items[0].ToString(),host.Items[1].ToString(),host.Items[2].ToString()','host.Items[0].ToString()')
# Current compact runtime stores native/managed files under bin.
s=s.replace('Path.Combine(release,"CyrusGallery.dll")','Path.Combine(release,"bin","CyrusGallery.dll")')
(out/'UiChecks.cs').write_text(s,encoding='utf-8')
