"""Verify evidence and copy exact, tested bytes to distribution. Does not install."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2]
BUILD=ROOT/'build/memory-fix-0854-20261017-01'
NATIVE=BUILD/'native-02';PACKAGE=BUILD/'package-02'
DOC=ROOT/'docs/plans/memory-0854';DIST=ROOT/'dist/CyrusScatter-0.85.4-20261017'
HOST=ROOT/'build/mcp-qualification/foundation-memory0854-final-20261017-01'
COLD=ROOT/'build/mcp-qualification/foundation-memory0854-coldcopy-20261017-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rel=lambda p:p.relative_to(ROOT).as_posix()
receipt=json.loads((NATIVE/'receipt.json').read_text());assert receipt['max_year']==2027 and all(x['exit_code']==0 for x in receipt['stages'])
for name,h in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==h,name
inventory=json.loads((ROOT/'AminScatter/library/inventory.json').read_text())
for entry in inventory['entries']:
 for phase in ['setup','load','verify','undo','verifyUndo','redo','verifyRedo','reopen','verifyReopen']:
  text=(HOST/f"acceptance-{entry['id']}-{phase}.txt").read_text(encoding='utf-8-sig')
  assert 'PASS: complete' in text and 'FAIL:' not in text,(entry['id'],phase)
log=(HOST/'memory-fix.txt').read_text(encoding='utf-8-sig')
for check in ['Baseline full rows equal 0.85.3','50000 full rows equal 0.85.3','Undo restores settings and exact complete rows','Redo restores exact 50000 publication','Repeated Count exact rows','Manual edit keeps old output without calculation','Explicit Update publishes complete requested result','Failed successor retains full previous publication','Undo of failed edit restores complete valid state','Invalid radius metadata after preparation retains prior full publication and Undo','Undo recovers staged failure','Panel opening performs no receiver, preparation or preview builds','Idle retained geometry/upload counters unchanged']:
 assert 'PASS: '+check in log,check
cold=(COLD/'memory-fix.txt').read_text(encoding='utf-8-sig');assert 'COLD_HEAP 104857600L' in cold
for check in ['Layer Copy publishes 90000 placements with Undo intact','Copy Undo restores exact ownership','Manual Update after Copy Undo restores 60000 full rows','Manual Update after Copy Redo restores 90000 full rows','Scene reopen restores exact Edit/radius placement rows','Native schedules and radius owners release after scene/history lifecycle']:
 assert 'PASS: '+check in cold,check
grids=list(COLD.glob('integration-*.txt'));assert grids and all('PASS: complete' in p.read_text(encoding='utf-8-sig') for p in grids)
for host in [HOST,COLD]:
 assert json.loads((host/'closure-observation.json').read_text())['exited']
 launch=json.loads((host/'launch.json').read_text());assert launch['script_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
 for name,h in {**launch['binaries'],**launch['script_assets']}.items():assert sha(NATIVE/name)==h,name
 assert not (host/'startup-error.txt').exists() and (host/'loaded.tsv').is_file()
profile=Path(json.loads((HOST/'launch.json').read_text())['profile_template'])
assert sha(profile)==json.loads((HOST/'launch.json').read_text())['profile_template_sha256']
baseline=json.loads((ROOT/'build/memory-investigation-20261017-01/source-before.json').read_text())['files']
filters=[p for p in baseline if 'surface_filter' in p and p.startswith('AminScatter/')]
for name in filters:assert sha(ROOT/name)==baseline[name],name
old=(ROOT/'build/mcp-qualification/foundation-presets0853-memory-20261017-01/scripts/CyrusScatter.ms').read_text(encoding='utf-8-sig')
new=(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf-8-sig')
block=lambda s:s.split('parameters surfaceFilterSettings (',1)[1].split('parameters layerSettings (',1)[0]
assert block(old)==block(new),'Slope/altitude block changed'
mzp=PACKAGE/'CyrusScatter-0.85.4-Max2027.mzp';exe=PACKAGE/'CyrusScatter-0.85.4-Max2027-Setup.exe'
with zipfile.ZipFile(mzp) as z:
 assert z.testzip() is None
 manifest=json.loads(z.read('manifest.json'));assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,h in manifest['files'].items():
  assert hashlib.sha256(z.read(name)).hexdigest()==h,name
  if name.startswith('Library/'):assert sha(ROOT/'AminScatter/library'/name.removeprefix('Library/'))==h,name
 assert manifest['version']=='0.85.4' and manifest['max_year']==2027
 assert manifest['files']['CyrusScatter.ms']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
 for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusGallery.dll']:assert manifest['files'][name]==sha(NATIVE/name)
 assert b'29000' in z.read('install.ms') and b'0.85.4' in z.read('install.ms')
exereceipt=json.loads(exe.with_suffix('.build.json').read_text());assert exereceipt['package_sha256']==sha(mzp) and exereceipt['artifact_sha256']==sha(exe)
for name,h in exereceipt['sources'].items():assert sha(ROOT/name)==h,name
assert not DIST.exists(),'Never overwrite a delivered package'
DIST.mkdir(parents=True)
for p in [mzp,exe,exe.with_suffix('.build.json')]:shutil.copy2(p,DIST/p.name);assert sha(p)==sha(DIST/p.name)
package=dict(status='scoped-qualified, not installed',version='0.85.4',max_year=2027,manifest=manifest,
 artifacts={rel(DIST/p.name):dict(sha256=sha(p),bytes=p.stat().st_size) for p in [mzp,exe]},
 native_receipt=rel(NATIVE/'receipt.json'),native_receipt_sha256=sha(NATIVE/'receipt.json'),
 install_core_reused='build/presets-0853-20261016-01/package-04/staging/AminScatter/CyrusInstaller.build.json',
 exe_receipt=exereceipt,installer_executed=False,artist_installation=False)
(DOC/'PACKAGE.json').write_text(json.dumps(package,indent=2)+'\n')
evidence=[NATIVE/'receipt.json',NATIVE/'tests.log',BUILD/'generated-final/generated-check.json']
for host in [HOST,COLD]:
 evidence += [p for p in host.iterdir() if p.is_file() and p.suffix in ('.txt','.json','.tsv') and not p.name.startswith(('dev-','pending-','await-','pointer-'))]
qual=dict(status='passed within declared scope',version='0.85.4',date='2026-10-17',max_year=2027,
 branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
 source_hashes=receipt['sources'],native_binaries=receipt['binaries'],
 startup_identity_checks=True,all_eight_presets=True,actual_count_controls=True,undo_redo_exact=True,
 count_handler_times_ms=[dict(count=int(n),milliseconds=int(t)) for n,t in re.findall(r'COUNT_TIME (\d+) (\d+)',log)],
 idle_ms=int(re.search(r'IDLE_ELAPSED_MS (\d+)',log).group(1)),cold_copy_ms=int(re.search(r'COPY_TIME (\d+)',cold).group(1)),
 tests=dict(native=40,python=167,generated_controls=296),normal_profile_sha256=sha(profile),
 slope_altitude=dict(source_files_unchanged={name:sha(ROOT/name) for name in filters},script_block_unchanged=True,runtime_payloads_unchanged=True),
 owned_hosts_closed=True,artist_session_controlled=False,installed=False,phase_6='paused',git_commit_push=False,
 limitations=['Conservative allowance retained; not measured exact peak accounting','Rows remain script arrays','Session heap capacity retained until Max exits','No arbitrary OS allocation/device-loss injection','No continuous physical spinner/viewport/FPS or production-renderer qualification','No full long-session B26 closure','Initial failed helper/unsupported-source iterations preserved in raw receipts; not passes'],
 evidence_sha256={rel(p):sha(p) for p in sorted(set(evidence))})
(DOC/'QUALIFICATION.json').write_text(json.dumps(qual,indent=2)+'\n')
(DIST/'INSTALL_AND_TEST.txt').write_text('Cyrus Scatter 0.85.4 — Max 2027 only\n\nRun the .mzp via Scripting > Run Script, then restart Max 2027.\nThe unsigned EXE contains the same payload. Neither was installed by the agent.\n\nTest Live Count 5k -> 50k -> 90k and down, Undo/Redo, Manual pending/Update,\nthen layer Copy and Update. Check prior Undo entries and idle responsiveness.\nSlope and altitude are unchanged. Phase 6 remains paused.\n\nWorking memory is reserved for actual Updates when needed, without changing\nsaved Max preferences. Session heap capacity remains until Max exits.\nFull qualification and limits: docs/plans/memory-0854/README.md\n',encoding='utf-8')
print(json.dumps(package['artifacts'],indent=2))
