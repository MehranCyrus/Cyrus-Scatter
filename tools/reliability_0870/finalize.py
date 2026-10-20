"""Publish local delivery artifacts and current navigation after recorded passes."""
from pathlib import Path
import hashlib,json,re,shutil,sys
ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/plans/preset-gallery-improvements';build=ROOT/'build/reliability-0870-20261019/package01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
if '--resume-docs' in sys.argv:
 source=Path(__file__).read_text(encoding='utf-8')
 tail=source[source.rindex("p=ROOT/'docs/plans/improvement-program/PROGRESS.md';"):]
 dest=ROOT/'dist/CyrusScatter-0.87.0-20261019';archive=dest/'CyrusScatter-0.87.0-Max2027.mzp'
 exec(compile(tail,__file__,'exec'));sys.exit(0)
package=json.loads((build/'package-receipt.json').read_text());install=json.loads((build/'install-receipt.json').read_text());qualification=json.loads((DOC/'QUALIFICATION_0870.json').read_text())
assert package['status']==install['status']=='passed' and len(qualification['records'])==38
archive=Path(package['mzp']);assert sha(archive)==package['mzp_sha256']
dest=ROOT/'dist/CyrusScatter-0.87.0-20261019';dest.mkdir(exist_ok=False)
for p in (archive,build/'package-receipt.json',build/'install-receipt.json',DOC/'QUALIFICATION_0870.json'):shutil.copy2(p,dest/p.name)
assert sha(dest/archive.name)==package['mzp_sha256']
report=f'''# Cyrus Scatter 0.87.0 — library and Amount reliability

Delivered for user testing on **19 October 2026**, **Max 2027 only**. Saved schema
58 and internal registration identities remain unchanged; recipe format is 7.
Earlier 0.86.2 Max 2024/2026/2027 deliveries retain their original qualification.

## Install

Use [CyrusScatter-0.87.0-Max2027.mzp](../../../dist/CyrusScatter-0.87.0-20261019/CyrusScatter-0.87.0-Max2027.mzp)
through **Scripting > Run Script**, then restart **Max 2027**. Save your work and
test copies of scenes. This task did not install into or restart an artist profile.
No EXE, older-host compatibility or live website deployment is claimed here.

- MZP SHA-256: `{package['mzp_sha256']}`
- Generated script SHA-256: `{qualification['script_sha256']}`
- Native build receipt SHA-256: `{qualification['native_receipt_sha256']}`
- [Host qualification receipt](QUALIFICATION_0870.json), [full acceptance ledger](RELIABILITY_0870.md), [format/support contract](FORMAT_7.md).
- Package and disposable installer receipts accompany the MZP in its delivery folder.

## Result

All eight bundled examples have newly captured format-7 recipes and validated
packages. Valley uses relative local elevation instead of assuming channel 2;
Mountain no longer assumes the original world altitude. Explicit artist channels
remain explicit requirements. Complete presets convert physical units and fit
supported Paint/path layouts between local-XY footprints without changing source
coverage. Model dimensions, spacing, brush/falloff distances and path widths stay
physical.

Map coordinates now supplies the actual receiver, face, position, time and map
channels to supported procedural graphs. Vertex Color → Color Correction → Output
and Checker own-UV workflows share placement and mask-preview evaluation. Clear,
pattern/image/map switching, independent surface-field toggles and nested edits
retain the intended state. Last-model removal publishes valid empty output;
replacement, Amount and history work again. Recipes restores a minimized Library
and safely updates its owner/destination context.

Invalid dependencies produce contextual errors and retain existing planting.
The original library bytes are preserved in
`build/reliability-0870-20261019/original-library-preserved`; historical receipts
and unrelated work are retained. New delivery inventory ships 98 current files;
obsolete sidecars are not included.

## Evidence and limits

The exact native10 pair passes all **45 native tests**, **175 Python tests**,
generated validation (**321 controls**), and **38 recorded final-pair host cases**:
33 preset scenarios plus lifecycle, Amount, elevation, maps and adversarial suites.
All eight examples pass in feet and millimetres with independent serialized-metre
oracles for source vertices and distance settings. Transformed centimetre/metre
tests cover both Paint examples plus Valley/Mountain. Small/large footprints,
new heightfields and folded-receiver rejection/repair are included. The separate
16-case centimetre/metre baseline retains its earlier pair09 identity.

History witnesses verify exact publication, owner/asset cleanup, Undo/Redo and
save/reopen. Map witnesses cover channels 0/2/3/7, missing channels, UV1/UV7,
multiple receivers, nested edits, Manual/Live animation, unrelated animation,
idle, tiny/huge scales and singular-transform recovery. Additional tests cover
leading/last-source removal, empty reopen, Point/gap roles, missing/corrupt assets,
three repeated imports and clean 10-population capacity rejection. A real unused
channel allocation exceeding the 256 MiB retained-mesh-array budget rejects and
recovers. This is not a whole-process memory or presented-FPS measurement.

Archive CRC, every payload hash, exact native/script identity, Max 2027/version
guards and starter masks pass. The packaged managed installer passes disposable
installation, idempotent repair, missing-file repair, interrupted-publication
rollback/retry and unregister/personal-data preservation. This verifies the engine
and package; physical Run Script dialog interaction remains an artist smoke check.

Paint requires single-valued local XY; folded/closed/stacked projections are
unsupported. Procedural maps support the bounded class set in format 7, not
arbitrary third-party or camera/renderer graphs. Arbitrary procedural graph export
and context-free baking of receiver-aware maps remain unsupported. Max scene
save/reopen retains those graphs. Windows foreground activation is requested;
the background test verified window restoration, but another application kept
foreground focus. Physical foreground interaction, mixed-monitor DPI, all
renderers and long production sessions are not certified by these tests.

Artist guides and website sources are aligned. Website content verification and
production build pass locally; nothing was published. Concept-poster version
labels retain their historical scope. No commit or push was performed.
'''
(DOC/'DELIVERY_0870.md').write_text(report,encoding='utf-8')
def replace(name,old,new):
 p=ROOT/name;s=p.read_text(encoding='utf-8');assert old in s,name;p.write_text(s.replace(old,new,1),encoding='utf-8')
def first(name,text):
 p=ROOT/name;s=p.read_text(encoding='utf-8');parts=s.split('\n\n',2);p.write_text(parts[0]+'\n\n'+text+'\n\n'+parts[2],encoding='utf-8')
p=ROOT/'README.md';s=p.read_text();s=re.sub(r'\*\*Current delivery:.*?(?=\n\n)', '**Current delivery: Scatter 0.87.0 / schema 58 / CyrusUnified1, qualified within scope for Max 2027.** The [library and Amount report](docs/plans/preset-gallery-improvements/DELIVERY_0870.md) owns the exact MZP, supported behavior and evidence. It adds receiver-aware maps, reusable Paint across units/footprints, relative-elevation presets and Clear/source/window lifecycle fixes. Earlier [0.86.2 older-host deliveries](docs/plans/preset-gallery-improvements/DELIVERY_0862.md) retain their original scope. The [execution ledger](docs/plans/improvement-program/PROGRESS.md) owns remaining work; unrelated roadmap work is outside this delivery.',s,count=1,flags=re.S);s=s.replace('[qualified MZP/EXE and artist tests](docs/plans/preset-gallery-improvements/DELIVERY_0862.md)','[qualified Max 2027 MZP and artist tests](docs/plans/preset-gallery-improvements/DELIVERY_0870.md)');s=s.replace('The unsigned universal EXE provides a host selector.','The prior 0.86.2 universal EXE retains its separate host scope.');p.write_text(s)
first('AminScatter/README.md','Current development/package version **0.87.0**, saved schema **58**, model **CyrusUnified1**. The [current Max 2027 delivery](../docs/plans/preset-gallery-improvements/DELIVERY_0870.md) qualifies library portability, receiver-aware maps and lifecycle fixes within its recorded scope. Earlier 0.86.2 host deliveries remain separate. Licensing and internal registration identities are unchanged.')
replace('AminScatter/README.md','[Latest qualification](../docs/plans/preset-gallery-improvements/DELIVERY_0862.md)','[Latest qualification](../docs/plans/preset-gallery-improvements/DELIVERY_0870.md)')
replace('docs/ARTIST_GUIDE.md','# Cyrus Scatter 0.86.2 — current artist workflow','# Cyrus Scatter 0.87.0 — current artist workflow')
first('docs/ARTIST_GUIDE.md','This Max 2027 delivery fixes library portability, map/channel switching, Clear, empty-source output and Library restoration. Complete presets transfer supported Paint/path layouts across units and local-XY footprints. Map coordinates evaluates supported procedural graphs on the receiving surface. The [delivery report](plans/preset-gallery-improvements/DELIVERY_0870.md) records the exact MZP, tests and limits; earlier host deliveries retain their original scope.')
replace('docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md','The [0.87.0 reliability ledger](RELIABILITY_0870.md) owns current qualification progress and limits.','The [0.87.0 delivery report](DELIVERY_0870.md) owns the exact Max 2027 package, qualification and limits.')
first('docs/Max_2027_Installation.md','The **0.87.0 / schema 58** delivery provides a matched Max 2027 MZP with eight revised examples and three starter masks. See the [current delivery](plans/preset-gallery-improvements/DELIVERY_0870.md). The earlier [0.86.2 multi-host delivery](plans/preset-gallery-improvements/DELIVERY_0862.md) retains its distinct Max 2024/2026/2027 scope. No artist installation/restart was performed.')
p=ROOT/'docs/Max_2027_Installation.md';s=p.read_text();s=re.sub(r'^2\. Open the intended Max version.*$', '2. In Max 2027, use **Scripting > Run Script** and select [CyrusScatter-0.87.0-Max2027.mzp](../dist/CyrusScatter-0.87.0-20261019/CyrusScatter-0.87.0-Max2027.mzp). Follow the installer result before restarting.',s,flags=re.M);s=s.replace('The [0.86.2 package record](plans/preset-gallery-improvements/DELIVERY_0862.md)','The [0.87.0 package record](plans/preset-gallery-improvements/DELIVERY_0870.md)');p.write_text(s)
p=ROOT/'docs/README.md';s=p.read_text();s=re.sub(r'\*\*Current delivery:.*?(?=\n\n)','**Current delivery: 0.87.0, schema 58, scoped Max 2027 qualification.** [Exact MZP and evidence](plans/preset-gallery-improvements/DELIVERY_0870.md). Earlier deliveries and independent Physics Lab reports retain their own scope. The execution ledger records remaining work.',s,count=1,flags=re.S);s=s.replace('[0.86.2 delivery and artist checklist](plans/preset-gallery-improvements/DELIVERY_0862.md)','[0.87.0 delivery and artist checklist](plans/preset-gallery-improvements/DELIVERY_0870.md)');p.write_text(s)
first('docs/plans/preset-gallery-improvements/README.md','**Current 0.87.0 delivery:** [Max 2027 MZP and scoped qualification](DELIVERY_0870.md). See [format 7](FORMAT_7.md) for receiver maps, relative elevation and reusable Paint. Historical contracts below retain their original scope unless superseded by that contract.')
p=ROOT/'docs/plans/improvement-program/PROGRESS.md';s=p.read_text();s=s.replace('**Current delivery: 0.86.2 D01–D11 scoped qualification is complete; see the [delivery report](../preset-gallery-improvements/DELIVERY_0862.md). Unrelated roadmap work remains paused.**','**Current delivery: 0.87.0 library/Amount scoped qualification is complete; see the [delivery report](../preset-gallery-improvements/DELIVERY_0870.md). Unrelated roadmap work remains outside this delivery.**').replace('## Active 0.87.0 library and Amount goal','## Delivered 0.87.0 library and Amount goal').replace('**0.87.0 is planned, not delivered.**','**0.87.0 is delivered for Max 2027 user testing with its verified MZP.**');start=s.index('## Prior Amount/library investigation');end=s.find('\n## ',start+4);s=s[:start]+'## Prior Amount/library investigation\n\nThe [19 October audit](../preset-gallery-improvements/AMOUNT_MAP_AUDIT_20261019.md) records the original failures. Their scoped corrections and full acceptance are in [0.87.0](../preset-gallery-improvements/DELIVERY_0870.md). Older receipts below keep their original identities.\n'+s[end:];p.write_text(s)
p=ROOT/'docs/BACKLOG.md';s=p.read_text();s=re.sub(r'^\| B31 .*$', '| B31 | Fixed in [0.87.0](plans/preset-gallery-improvements/DELIVERY_0870.md): Clear disables image density and removes its map | Final Manual/Live, patterns/channels, preview, Undo/Redo and scene-reopen tests pass |',s,flags=re.M);s=re.sub(r'^\| B32 .*$', '| B32 | Fixed within [0.87.0](plans/preset-gallery-improvements/DELIVERY_0870.md): native receiver-aware context supplies supported map graphs with their own channels/frame/time | Final channel/UV, nested edits, animation, multiple receivers, bounds and preview agreement pass. Arbitrary graph export and third-party/renderer contexts remain outside support |',s,flags=re.M);s+='\n## Library and source lifecycle — 0.87.0\n\nThe [delivery report](plans/preset-gallery-improvements/DELIVERY_0870.md) records revised reusable examples, physical units/Paint transfer, valid empty-source publication, minimized Library restoration, and atomic invalid-dependency recovery. Windows foreground focus, physical mixed-monitor use and arbitrary production sessions remain separate acceptance; restored window bounds and safe owner rebinding pass.\n';p.write_text(s)
p=DOC/'RELIABILITY_0870.md';s=p.read_text().replace('| Delivery | Current guides/website sources, exact source/native identity, Max 2027 host evidence and runnable verified MZP with install directions | Pending |','| Delivery | Current guides/website sources, exact source/native identity, Max 2027 host evidence and runnable verified MZP with install directions | Complete within scope; [delivery report](DELIVERY_0870.md), 38 final-pair host records, exact MZP and disposable installer pass |');s+='\n- Final acceptance: all 38 recorded final-pair suites/cases passed. The preserved original library is hash-verified before source promotion. The exact MZP passes archive/hash/host/version checks and the packaged installer passes disposable install/repair/rollback/retry/unregister tests. Website content verification and local production build pass. See DELIVERY_0870.md for limits and user installation directions.\n';p.write_text(s)
p=DOC/'FORMAT_7.md';s=p.read_text().replace('0.87.0 candidate','0.87.0').replace('This contract describes the implemented candidate. Release acceptance remains in','This contract describes the implemented delivery. Scoped release acceptance is in');p.write_text(s)
p=ROOT/'docs/Release_Versioning.md';s=p.read_text().replace('planned 0.87.0','delivered 0.87.0');p.write_text(s)
# Re-pin only reviewed sources changed by this delivery, preserving old gallery identities.
p=ROOT/'website/content/source-manifest.json';d=json.loads(p.read_text());changed=('README.md','AminScatter/README.md','docs/README.md','docs/ARTIST_GUIDE.md','docs/ARCHITECTURE.md','docs/Max_2027_Installation.md','docs/BACKLOG.md','docs/Release_Versioning.md','docs/plans/improvement-program/PROGRESS.md','docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md','docs/plans/preset-gallery-improvements/README.md','docs/plans/preset-gallery-improvements/RELIABILITY_0870.md')
for name in changed:
 if name in d['reviewedSourceHashes']:d['reviewedSourceHashes'][name]=sha(ROOT/name)
p.write_text(json.dumps(d,indent=2)+'\n')
print(dest/archive.name)
