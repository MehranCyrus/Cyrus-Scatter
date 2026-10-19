"""Verify scoped evidence, publish immutable distribution copies, update navigation."""
from pathlib import Path
import csv, hashlib, io, json, re, shutil, subprocess, zipfile
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/compatibility-0862-20261019'
PKG=BASE/'package01';DOC=ROOT/'docs/plans/preset-gallery-improvements'
DIST=ROOT/'dist/CyrusScatter-0.86.2-20261019-multihost01'
HOST=ROOT/'build/mcp-qualification/density0862-compat-max2026-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
relative=lambda p:p.relative_to(ROOT).as_posix() if p.is_relative_to(ROOT) else p.as_posix()
candidate=load(PKG/'candidate.json');stages=load(HOST/'compatibility-campaign.json')
assert all(s['exit_code']==0 for s in stages)
assert {s['name'] for s in stages}=={'extended','lifecycle','field_numeric','channels','workflow','examples','save','thumbnail','layout','panel-contract','installer-wrapper'}
assert 'PASSED 68 ' in (BASE/'distribution01/result.txt').read_text()
for year in (2024,2026):assert 'PASSED 41 ' in (BASE/f'managed{year}/result.txt').read_text()
assert load(HOST/'physical-ui.json')['status']=='passed'
assert load(HOST/'installer-wrapper.json')['status']=='passed'
artifacts={};pairs={};evidence=[]
def record(p):return {'path':relative(p),'sha256':sha(p),'bytes':p.stat().st_size}
for year,data in candidate['packages'].items():
    native_receipt=Path(data['native_receipt']);assert sha(native_receipt)==data['native_receipt_sha256']
    native=load(native_receipt)
    for key in ('sources','binaries'):
        for name,digest in native[key].items():assert sha(ROOT/name)==digest,name
    package=PKG/f'CyrusScatter-0.86.2-Max{year}.mzp';assert sha(package)==data['mzp_sha256']
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None
        for name,digest in data['manifest']['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
    pairs[year]={'native_receipt':record(native_receipt),'manifest':data['manifest'],
        'runtime':'Preview: no installed runnable Max 2024' if year=='2024' else ('Current owned Max 2026 campaign' if year=='2026' else 'Unchanged exact MZP/pair from QUALIFICATION_0862_UI.json')}
assert sha(PKG/'CyrusScatter-0.86.2-Setup.exe')==candidate['exe_sha256']
assert not DIST.exists();DIST.mkdir()
for p in [PKG/'CyrusScatter-0.86.2-Setup.exe',*(PKG/f'CyrusScatter-0.86.2-Max{y}.mzp' for y in (2024,2026,2027))]:
    target=DIST/p.name;shutil.copy2(p,target);assert sha(target)==sha(p);artifacts[p.name]=record(target)
(DIST/'SHA256.txt').write_text(''.join(f'{a["sha256"]}  {name}\n' for name,a in artifacts.items()))
(DIST/'INSTALL.txt').write_text('''Cyrus Scatter 0.86.2 - universal installer for team testing

Max 2026 and 2027: scoped runtime qualification. Max 2024: PREVIEW ONLY;
SDK/native/managed/installer checks passed, but no local Max 2024 runtime was available.
No Max 2025 or earlier-than-2024 support is included.

Share CyrusScatter-0.86.2-Setup.exe. It contains all three matching payloads,
eight ready examples and three starter masks: Uniform, Soft patches, Wide bands.
It installs for the Windows user running it, using that user's Max profile.

1. Open the intended Max version once so its profile exists, then save and close it.
2. Run the EXE, select that Max year and choose Install / Repair.
3. Start/restart that Max version to load the matched native modules and script.
For a custom Max installation, use Scripting > Run Script with the matching
Max-year MZP instead, then restart Max. Use one installation route per host.

The EXE is unsigned and uses Windows .NET Framework 4.8. No SDK or developer
toolchain is required. Personal recipes and activation are preserved.
Each user still needs their own valid activation key: License / activation,
save a request, send it to the owner, then import the returned .cyruslicense.
The EXE contains the public verification authority, never the private issuer key.
User recipes save in that user's Documents/CyrusScatter/Library.

After installing, select terrain and open Cyrus Library from the Cyrus actions,
or Layers > Recipes. Load onto surface adds layers. Recipe mesh-channel/Paint
requirements still apply. In Amount choose a starter pattern or Image / Map.
Show mask stays enabled through relevant edits; Hide mask stops it.

Qualification used disposable local profiles. Artist profiles were not installed
or restarted. A second physical Windows machine and real Max 2024 runtime still
need team acceptance; 2024 must not be represented as fully runtime qualified.
''',encoding='utf-8')
for p in [BASE/'baseline.json',BASE/'distribution01/result.txt',PKG/'candidate.json',
          *(BASE/f'managed{y}/result.txt' for y in (2024,2026)),
          *(HOST/n for n in ('launch.json','loaded.tsv','compatibility-campaign.json','physical-ui.json','installer-wrapper.json','extended.log','workflow.log','examples-retry.log','save.log','thumbnail.log','layout.log','ui-polish-contract.txt')),
          ROOT/'build/mcp-qualification/density0862-compat-backsave01/installer-wrapper.json',
          DOC/'QUALIFICATION_0862_UI.json']:
    evidence.append(record(p))
for p in sorted(HOST.glob('cold-observe-*.txt')):evidence.append(record(p))
for p in sorted(BASE.glob('*.png')):evidence.append(record(p))
receipt={'version':'0.86.2','date':'2026-10-19','scope':'Explicitly requested Max 2024/2026 compatibility and shareable universal installer; no plugin implementation changes',
    'git_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'script_sha256':sha(ROOT/'AminScatter/scripts/AminScatterObject.ms'),'pairs':pairs,'artifacts':artifacts,'evidence':evidence,
    'artist_installation':False,'knowledge_activation':False,'git_push':False,'roadmap_resumed':False,
    'limitations':['Max 2024 has no installed runnable host; preview only','Scoped single-computer Max 2026/2027 qualification; not every Windows/GPU/renderer configuration',
        'Unsigned executable','Actual mixed-monitor/physical 4K transitions remain unqualified','No Max 2025 or earlier-than-2024 payload'],
    'fixture_correction':'Cold scene loading can restore saved native publication after loadMaxFile returns. Initial immediate baseline differed before any import. Reproduction without import and stable baseline/verification steps precede all eight retry Add/Undo/Redo witnesses. Initial failure is retained.'}
(DOC/'QUALIFICATION_0862_COMPATIBILITY.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
rows=[]
for name,a in artifacts.items():
    label='Universal EXE' if name.endswith('.exe') else ('Max '+name.split('Max')[1].split('.')[0]+(' preview MZP' if '2024' in name else ' MZP'))
    rows.append(f'| [{label}](../../../{a["path"]}) | {a["bytes"]:,} | `{a["sha256"]}` |')
section='''## Current multi-host installer — 19 October 2026

**Share the universal EXE below for team testing. Version remains 0.86.2.** This extends the exact UI follow-up to matching Max 2024 and 2026 builds. The Max 2027 MZP is byte-for-byte unchanged. [Exact qualification](QUALIFICATION_0862_COMPATIBILITY.json) records payloads, tests and limits; no plugin implementation was changed for compatibility.

| Installer | Bytes | SHA-256 |
| --- | ---: | --- |
'''+ '\n'.join(rows)+'''

| Host | Qualification |
| --- | --- |
| Max 2027 | Exact unchanged UI follow-up pair and MZP; its scoped runtime and 100/150% UI evidence remain applicable. |
| Max 2026 | Matching SDK/.NET 8 pair; fresh owned-host density, channel, library, complete image/Paint Save, Undo/Redo, late-failure recovery, panel, dropdown and idle checks. |
| Max 2024 | **Preview only.** Matching SDK/.NET Framework 4.8 pair, native and managed tests, exact installer checks. No runnable local Max 2024 is installed; scene, notification, viewport and render behavior remain unqualified. |

Both older SDK builds pass **45 native tests**. Their actual managed assemblies each pass **41 checks**, including patterns and layouts at default/100/150/200% scripted scales. The universal EXE passes **68 distribution checks**: three host descriptors, 2024 preview label, exact payloads, recipient-profile paths including Unicode, bundled examples and starter masks, repair, 0.86.1 upgrades, interrupted-upgrade rollback, cancellation and preserved personal-content sentinels. Tests use disposable local paths; they are not tests on another physical Windows machine.

Max 2026 verifies all eight examples on matching-format scene copies, additive layers, stable pre-import publication, exact Undo/Redo, complete image/Paint custom Save and reload, procedural Noise baking, missing dependencies and late-failure retention. Count changes through 250,000 preserve Undo and reuse sampled images; warm idle and gallery browsing do not solve/upload. Empty/image/procedural thumbnails, More settings, full-width names and the actual Modify controls pass. The packaged MZP wrapper also executes successfully inside the redirected Max 2026 profile. Physical interaction scope is recorded in the receipt.

**Test correction:** the first painted-example Undo assertion captured its baseline inside the cold scene-load call stack. A no-import reproduction showed deferred restoration of the saved native publication changing that snapshot before Load. The corrected fixture returns through host callbacks, explicitly updates and verifies a stable baseline before import. All eight repeat witnesses pass; the first failure and diagnostic evidence are retained. This is a fixture correction, not a plugin-code fix.

The EXE contains eight ready examples, matching-format scene copies and **Uniform, Soft patches and Wide bands**. It installs for the Windows user running it using their initialized Max profile. Open the intended Max once, save/close it, select its year in the EXE and Install / Repair, then start/restart Max. For custom Max installation paths use **Scripting > Run Script** with the matching MZP, then restart. The EXE is unsigned and requires Windows .NET Framework 4.8. No Max 2025 or earlier-than-2024 payload is included.

Team licensing remains enabled: recipients need their own valid generated activation key. The installer carries only the public verification authority. Personal recipes remain in that user's Documents/CyrusScatter/Library; installation preserves personal content and activation. No artist installation/restart, Git push, knowledge activation or further roadmap work was performed. A teammate must validate Max 2024 before treating it as runtime supported.

'''
path=DOC/'DELIVERY_0862.md';text=path.read_text(encoding='utf-8');head,rest=text.split('\n',1)
rest=rest.replace('## Current UI follow-up — 19 October 2026','## Qualified UI follow-up — 19 October 2026',1).replace('**Version remains 0.86.2. Use this installer pair.**','**Retained Max 2027 qualification; the universal distribution above is current. Version remains 0.86.2.**',1)
path.write_text(head+'\n\n'+section+rest.lstrip(),encoding='utf-8')
def edit(name,fn):
    p=ROOT/name;s=p.read_text(encoding='utf-8');t=fn(s);assert t!=s,name;p.write_text(t,encoding='utf-8')
edit('README.md',lambda s:s.replace('qualified for Max 2027.','qualified within scope for Max 2026/2027; Max 2024 preview.',1).replace('The earlier [0.86.1 compatibility delivery](docs/plans/preset-gallery-improvements/DELIVERY_0861.md) retains its original older-host receipts; no new older-host qualification is implied.','The current universal EXE includes matching Max 2024/2026/2027 payloads; 2024 remains preview because no runnable host was available. Earlier receipts retain their original identities.'))
edit('AminScatter/README.md',lambda s:s.replace('follow-up in Max 2027.','follow-up in Max 2026/2027, with a separately labeled Max 2024 SDK/managed preview.',1))
edit('docs/Release_Versioning.md',lambda s:s.replace('0.86.2 Max 2027 MZP/EXE;','0.86.2 host MZPs/universal EXE;').replace('qualification is Max 2027 only.','qualification originally covered Max 2027 only. The user explicitly requested the\n19 October same-version compatibility follow-up: current Max 2026 runtime checks,\nunchanged qualified Max 2027 payload and a Max 2024 SDK/managed preview.'))
edit('docs/Max_2027_Installation.md',lambda s:re.sub(r'The \*\*0.86.2 / schema 58\*\*.*?\n\n',
    'The **0.86.2 / schema 58** delivery includes matching Max 2024, 2026 and 2027 MZPs and one universal EXE. Max 2026/2027 have scoped runtime qualification; **Max 2024 remains preview** without a runnable local host. Eight ready examples and three starter masks are bundled. See the [current delivery](plans/preset-gallery-improvements/DELIVERY_0862.md) for exact files and limits. The explicit older-host request applies to this compatibility delivery; ordinary development remains Max 2027 by default. No artist installation/restart was performed.\n\n',s,count=1).replace(
    '2. Choose **Scripting > Run Script** with the [Max 2027 MZP](../dist/CyrusScatter-0.86.2-20261019/CyrusScatter-0.86.2-Max2027.mzp), or run the [Max 2027 EXE](../dist/CyrusScatter-0.86.2-20261019/CyrusScatter-0.86.2-Setup.exe). Use one route. Restart Max afterward so its script and native modules load together.',
    '2. Open the intended Max version once to initialize its user profile, then save/close it and run the [universal EXE](../dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Setup.exe). Select that year and Install / Repair. Alternatively use **Scripting > Run Script** with the matching-year MZP from the [delivery report](plans/preset-gallery-improvements/DELIVERY_0862.md); use this route for custom Max installation paths.'))
edit('docs/plans/preset-gallery-improvements/INSTALLER_CONTRACT.md',lambda s:s.replace('The [current delivery](DELIVERY_0862.md) contains only the newly qualified Max 2027 pair, its MZP and a single-host EXE. Older-host 0.86.1 receipts and installers retain their original labels.',
    'The [current delivery](DELIVERY_0862.md) contains matching Max 2024/2026/2027 MZPs in one universal EXE. Max 2026 has fresh scoped runtime qualification; the Max 2027 payload is unchanged from the qualified UI follow-up. Max 2024 remains preview with SDK/managed/installer checks only. Older receipts retain their original labels.').replace(
    'The empty final-artwork catalog is supported; QA images are excluded from the installer and supplied only with the demo.',
    'Three original product starter masks are included. An empty catalog is also supported; final artist-supplied artwork remains future content. The exact multi-host EXE passes 68 disposable distribution checks including per-user paths and all three upgrade paths.'))
edit('docs/plans/improvement-program/PROGRESS.md',lambda s:s.replace('pins the Max 2027 MZP, EXE, editable demo and qualification limits.',
    'pins the host-specific MZPs, universal EXE, editable demo and qualification limits. The explicit compatibility follow-up qualifies Max 2026 alongside the unchanged Max 2027 payload; Max 2024 remains SDK/managed preview.'))
edit('docs/plans/preset-gallery-improvements/README.md',lambda s:s.replace('D01–D11 are complete within their recorded scope;',
    'The universal EXE includes Max 2026/2027 runtime-qualified payloads and a clearly labeled Max 2024 preview. D01–D11 are complete within their recorded scope;',1))
edit('docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md',lambda s:s.replace('matching editable Max 2027 scenes','matching-host editable scene copies').replace('then restart Max 2027.','then restart the selected Max version. Max 2024 is preview only; consult the report before team testing.'))
p=ROOT/'docs/documentation-inventory.csv';rows=list(csv.DictReader(io.StringIO(p.read_text(encoding='utf-8'))))
name='docs/plans/preset-gallery-improvements/QUALIFICATION_0862_COMPATIBILITY.json';assert not any(r['path']==name for r in rows)
rows.append({'path':name,'decision':'retained-history','reason':'Exact 0.86.2 universal installer and older-host qualification; Max 2024 runtime unverified; knowledge activation remains paused.'})
stream=io.StringIO(newline='');writer=csv.DictWriter(stream,fieldnames=['path','decision','reason']);writer.writeheader();writer.writerows(rows);p.write_text(stream.getvalue(),encoding='utf-8',newline='')
print('Delivered:',DIST)
