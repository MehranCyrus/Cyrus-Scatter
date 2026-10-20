"""Freeze qualified installer artifacts and scoped receipts; never install or push."""
from pathlib import Path
import hashlib,json,shutil,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/installer-0862-20261019-01';PACKAGE=BASE/'package03'
DIST=ROOT/'dist/CyrusScatter-0.86.2-20261019-installer01';DOC=ROOT/'docs/plans/preset-gallery-improvements'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def receipt(path):
 path=Path(path);return {'path':str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path),'sha256':sha(path),'bytes':path.stat().st_size}
def run(folder,name):
 path=folder/name;return {**receipt(path),'text':path.read_text(encoding='utf-8-sig')}
candidate=json.loads((PACKAGE/'candidate.json').read_text());build=json.loads((PACKAGE/'CyrusScatter-0.86.2-Setup.build.json').read_text())
for name,digest in build['sources'].items():assert sha(ROOT/name)==digest,name
assert sha(PACKAGE/'CyrusScatter-0.86.2-Setup.exe')==candidate['exe_sha256']==build['artifact_sha256']
recipient=Path((BASE/'recipient-latest.txt').read_text());ui=Path((BASE/'ui-latest.txt').read_text());old=Path((BASE/'old-probe-latest.txt').read_text())
assert 'PASSED 95 ' in (recipient/'result.txt').read_text();assert 'PASSED 70 ' in (ui/'result.txt').read_text();assert json.loads((recipient/'run.json').read_text())['package']==str(PACKAGE)
assert 'actual preceding core reproduces PathTooLongException' in (old/'result.txt').read_text()
assert '175 passed' in (BASE/'python-recheck.txt').read_text();generated=json.loads((BASE/'generated/generated-check.json').read_text());assert generated['passed']
original=json.loads((DOC/'QUALIFICATION_0862_COMPATIBILITY.json').read_text())
hosts={2024:('density0862-installer-max2024-05','density0862-installer-max2024-06'),2026:('density0862-installer-max2026-03','density0862-installer-max2026-04'),2027:('density0862-installer-max2027-02','density0862-installer-max2027-03')}
current={};pairs={}
for year,(install,restart) in hosts.items():
 first=ROOT/'build/mcp-qualification'/install;last=ROOT/'build/mcp-qualification'/restart
 mzp=json.loads((first/'mzp.json').read_text());core=json.loads((first/'loaded-installer.json').read_text());meta=json.loads((last/'launch.json').read_text());runtime=json.loads((last/'installed-runtime.json').read_text())
 assert mzp['status']=='passed' and core['status']=='passed' and runtime['status']=='passed'
 assert mzp['mzp_sha256']==candidate['packages'][str(year)]['mzp_sha256'];assert core['expected_sha256']==build['core_sha256']
 assert json.loads((last/'final-smoke.json').read_text())['status']=='passed';assert not meta['startup_filein_product'];assert (last/'shutdown.txt').exists()
 manifest=candidate['packages'][str(year)]['manifest'];prior=original['pairs'][str(year)]['manifest']
 for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusGallery.dll','CyrusScatter.ms'):assert manifest['files'][name]==prior['files'][name],(year,name)
 for name,record in candidate['packages'][str(year)]['logical_inventory'].items():
  if name.startswith(('Library/','Patterns/')):assert record['sha256']==prior['files'][name],(year,name)
 path=PACKAGE/f'CyrusScatter-0.86.2-Max{year}.mzp'
 with zipfile.ZipFile(path) as z:
  assert z.testzip() is None;assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
  for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
  assert manifest['version']=='0.86.2' and manifest['max_year']==year and manifest['licensing']['mode']=='offline-team'
  assert not any(n.startswith('Library/') for n in z.namelist());assert max(len(n) for n in z.namelist())<64
  adapter=z.read('install.ms').decode('utf-8-sig')
  assert f'if (maxVersion())[1]!={(year-1998)*1000} then (' in adapter and '__MAX_' not in adapter
  assert candidate['packages'][str(year)]['manifest']['files']['InstallInventory.txt'] in adapter
 pairs[str(year)]={'native_receipt':receipt(Path(candidate['packages'][str(year)]['native_receipt'])),'manifest':manifest,'logical_inventory':candidate['packages'][str(year)]['logical_inventory'],'unchanged_native_script_gallery_and_library':True}
 current[str(year)]={'host_version':subprocess.run(['powershell','-NoProfile','-Command',f"(Get-Item 'C:/Program Files/Autodesk/3ds Max {year}/3dsmax.exe').VersionInfo.FileVersion"],capture_output=True,text=True,check=True).stdout.strip(),'mzp':mzp,'loaded_core':core,'installed_startup':meta,'loaded_modules':run(last,'loaded.tsv'),'final_smoke':json.loads((last/'final-smoke.json').read_text()),'installed_runtime':runtime,'final_workflow':run(last,'final-workflow.log'),'final_layout':run(last,'final-layout.log'),'panel_contract':run(last,'ui-polish-contract.txt'),'shutdown':run(last,'shutdown.txt')}
full=ROOT/'build/mcp-qualification/density0862-installer-max2024-04';campaign=json.loads((full/'installer-campaign.json').read_text());assert len(campaign)==10 and all(s['exit_code']==0 for s in campaign)
full_logs={p.name:{**receipt(p),'text':p.read_text(encoding='utf-8-sig')} for p in full.glob('*.txt') if not p.name.startswith(('generation-','dev-','pointer-')) and 'PASS:' in p.read_text(encoding='utf-8-sig',errors='replace')}
for p in full.glob('*.log'):
 if p.name!='listener.log':full_logs[p.name]={**receipt(p),'text':p.read_text(encoding='utf-8-sig')}
assert not DIST.exists();DIST.mkdir(parents=True)
artifacts={}
for name in ['CyrusScatter-0.86.2-Setup.exe',*[f'CyrusScatter-0.86.2-Max{year}.mzp' for year in hosts]]:
 shutil.copy2(PACKAGE/name,DIST/name);assert sha(DIST/name)==sha(PACKAGE/name);artifacts[name]=receipt(DIST/name)
(DIST/'SHA256SUMS.txt').write_text(''.join(r['sha256']+'  '+n+'\n' for n,r in artifacts.items()),encoding='utf-8')
(DIST/'INSTALL.txt').write_text('''Cyrus Scatter 0.86.2 — corrected installer, Max 2024 / 2026 / 2027
Open your Max version once, save and close it. Run CyrusScatter-0.86.2-Setup.exe,
select that version and Install / Repair, then start/restart Max.
Details is optional and contains full errors and a log location.
For custom Max installation paths, run the matching Max-year MZP through
Scripting > Run Script, then restart Max. Do not install loose scripts/DLLs.
Eight ready examples and three starter masks are included. Personal recipes and
activation are preserved. Each team member needs their own valid activation.
This unsigned development installer requires Windows .NET Framework 4.8.
Scoped tests cover Max 2024/2026/2027; no Max 2025 or earlier-than-2024 payload.
Do not substitute an older 0.86.2 installer: use SHA256SUMS.txt to identify this fix.
''',encoding='utf-8')
fixtures={str(p.relative_to(ROOT)):sha(p) for p in sorted((ROOT/'tools/installer_0862').glob('*')) if p.is_file()}
record={'version':'0.86.2','date':'2026-10-19','scope':'Same-version installer path/UI correction and newly installed Max 2024 runtime qualification; Scatter algorithms unchanged','git_head':subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,capture_output=True,text=True,check=True).stdout.strip(),'uncommitted_work':True,'script_sha256':generated['generated_sha256'],'build':build,'pairs':pairs,'artifacts':artifacts,'host_evidence':current,'max2024_full_campaign':{'host':str(full.relative_to(ROOT)),'pair_note':'All eight examples/full regressions ran on the identical Scatter/native/gallery/library bytes with installer core01. Final core02 changes only destination-volume admission; its exact MZP, loaded core, installed restart, selected-terrain workflow, asset hashes and panel checks pass separately above.','campaign':campaign,'logs':full_logs},'offline':{'recipient':run(recipient,'result.txt'),'actual_exe_ui':run(ui,'result.txt'),'legacy_old_core':run(old,'result.txt'),'python':run(BASE,'python-recheck.txt'),'transport_recheck':run(BASE,'transport-recheck.txt'),'generated':generated},'fixtures':fixtures,'artist_installation':False,'knowledge_activation':False,'git_push':False,'roadmap_resumed':False,'limitations':['This machine default Max 2024 admitted the old deep archive path; old-core reproduction required legacy path limits in an isolated CLR. No claim that the artist machine configuration was reproduced exactly.','Full Max 2024 tests and final three-host workflow/panel checks use scripts in owned profiles; no new physical mouse/keyboard, renderer, renderfarm, mixed-monitor or other-machine qualification. Scripted 150% installer layout is not physical 4K/mixed-monitor qualification.','Initial broad Python run had one transient MCP HTTP WinError 10053; its 12-test transport recheck and complete 175-test rerun passed without source changes.','A first installed-startup fixture compared forward-slash expectations to Windows backslashes; corrected path comparison passed. First final-panel probes used a destroyed fixture owner after workflow scene changes; explicitly mounting a fresh current owner passed. No product code change concealed either fixture failure.','Unsigned installer; Windows .NET Framework 4.8 and initialized local NTFS Max profile required. Custom Max executable paths use matching MZP. No Max 2025 or older-than-2024 payload.','Native SDK tests were not rerun for this installer-only correction. Matching source/binary receipt hashes and unchanged prior 45-test native qualification are preserved; actual host tests are fresh.']}
(DOC/'QUALIFICATION_0862_INSTALLER.json').write_text(json.dumps(record,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps(artifacts,indent=2));print('Frozen exact installers and scoped qualification; no installation/push')
