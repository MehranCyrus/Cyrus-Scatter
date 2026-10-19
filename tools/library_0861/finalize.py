"""Validate final receipts, publish ignored distribution files and retain compact evidence."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/library-surface-0861-20261018-01';PACKAGE=BASE/'package-shipping';DEST=ROOT/'dist/CyrusScatter-0.86.1-20261018';DOC=ROOT/'docs/plans/preset-gallery-improvements';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send
record={'version':'0.86.1','baseline_commit':'56b6e09db2b7e53f30fd60b6e4f51ea19296075f','schema':58,'artist_installed':False,'qualification':{},'artifacts':{},'source_script_sha256':sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')}
for year in (2024,2026,2027):
 native=BASE/f'native{year}';receipt=json.loads((native/'receipt.json').read_text());assert receipt['max_year']==year and all(stage['exit_code']==0 for stage in receipt['stages'])
 for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
 for name,digest in receipt['binaries'].items():assert sha(ROOT/name)==digest,name
 scope={'sdk_build':'pass','native_tests':44,'native_receipt_sha256':sha(native/'receipt.json'),'gallery_sha256':sha(native/'CyrusGallery.dll'),'native':{p.name:sha(p) for p in native.glob('*.dl*')}}
 if year==2024:scope.update(host='not tested; executable absent',status='preview; not runtime qualified',managed='net48; 30 standalone checks')
 else:
  host=ROOT/f'build/mcp-qualification/library-surface0861-max{year}-05';campaign=json.loads((host/'final-campaign.json').read_text());assert len(campaign)==4 and all(stage['exit_code']==0 for stage in campaign)
  launch=json.loads((host/'launch.json').read_text());assert launch['script_sha256']==record['source_script_sha256']
  for name,digest in launch['binaries'].items():assert sha(host/'bin'/name)==digest==sha(native/name)
  assert sha(host/'scripts/CyrusGallery.dll')==sha(native/'CyrusGallery.dll')
  identity=host/'final-identity.ms';identity.write_text('''(
local panel=CyrusRecipeBrowser.panel,panelType=panel.GetType(),assembly=panelType.Assembly,name=assembly.GetName()
local f=createFile (MCPFixtureDir+"final-identity.tsv")
format "%\\n%\\n%\\n%\\n%\\n" (SRoot.uiVersion()) CyrusLoadedScriptFingerprint CyrusRecipeScriptDirectory assembly.Location (name.Version.ToString()) to:f
close f
)
''',encoding='utf-8-sig');send(host,identity,'Final loaded identities '+str(year))
  values=(host/'final-identity.tsv').read_text(encoding='utf-8-sig').splitlines();expected=re.search('CyrusLoadedScriptFingerprint="([a-f0-9]+)"',(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf-8-sig'))[1]
  assert values[0]=='0.86.1' and values[1]==expected and Path(values[2]).resolve()==(host/'scripts').resolve() and Path(values[3]).resolve()==(host/'scripts/CyrusGallery.dll').resolve() and values[4]=='0.86.1.0'
  checks=sum(text.count('PASS:') for path in host.glob('*.txt') if path.name.startswith(('workflow-','example-','save-','extra-')) for text in [path.read_text(encoding='utf-8-sig')])
  scope.update(host='pass',status='scoped runtime qualified',profile=str(host.relative_to(ROOT)).replace('\\','/'),pid=launch['pid'],campaign=campaign,pass_lines=checks,loaded_identity=values)
 record['qualification'][str(year)]=scope
for filename in ('managed-qualification/result.txt','distribution-release-final/result.txt'):
 data=(BASE/filename).read_text();assert 'PASSED ' in data and 'FAIL:' not in data
record['managed_checks']=30;record['distribution_checks']=56;record['python_tests']=171
baseline=json.loads((BASE/'baseline.json').read_text());record['retained_scroll_sources']={name:sha(ROOT/name) for name in ['AminScatter/src/rollout_scroll.cpp','AminScatter/src/rollout_flow.cpp']};assert all(baseline['files'][name]==digest for name,digest in record['retained_scroll_sources'].items())
DEST.mkdir(parents=True,exist_ok=False)
for source in sorted([*PACKAGE.glob('*.mzp'),PACKAGE/'CyrusScatter-0.86.1-Setup.exe']):
 if source.suffix=='.mzp':
  with zipfile.ZipFile(source) as archive:
   assert archive.testzip() is None;manifest=json.loads(archive.read('manifest.json'));assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
   for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
   assert manifest['files']['CyrusScatter.ms']==record['source_script_sha256']
   for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusGallery.dll'):
    assert hashlib.sha256(archive.read(name)).hexdigest()==sha(BASE/('native'+str(manifest['max_year']))/name),name
 shutil.copy2(source,DEST/source.name);assert sha(source)==sha(DEST/source.name);record['artifacts'][source.name]={'sha256':sha(source),'bytes':source.stat().st_size}
exe=PACKAGE/'CyrusScatter-0.86.1-Setup.exe';assert json.loads(exe.with_suffix('.build.json').read_text())['artifact_sha256']==sha(exe);shutil.copy2(exe.with_suffix('.build.json'),DEST/'EXE-BUILD.json')
record['payload_pairs_verified']=True
record['installer_notice']='Unsigned EXE; three exact MZPs. Transactions exercised only in disposable paths, not artist profiles. Max 2024 remains a preview.'
(DEST/'QUALIFICATION.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8');(DOC/'QUALIFICATION_0861.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
for origin,name in [(BASE/'managed-qualification/result.txt','MANAGED_0861.txt'),(BASE/'distribution-release-final/result.txt','DISTRIBUTION_0861.txt')]:shutil.copy2(origin,DOC/name)
(DEST/'SHA256SUMS.txt').write_text(''.join(row['sha256']+'  '+name+'\n' for name,row in record['artifacts'].items()))
(DEST/'INSTALL.txt').write_text('Cyrus Scatter 0.86.1\nChoose the MZP matching Max 2027 or 2026 and use Scripting > Run Script, then restart that Max version.\nAlternatively run the universal unsigned EXE, select your host/profile and install, then restart.\nMax 2024 is a preview: matching SDK build and standalone managed checks passed, but no local Max 2024 host was available.\nSelect one terrain mesh, then run Cyrus Library (Customize > Cyrus category), or Layers > Recipes from a setup. Load onto surface adds layers and creates a setup when needed.\nPaint requires compatible geometry/frame/units; channel masks require their numeric channel. Existing layers and Undo are preserved.\nTeam licensing remains enabled; use the existing generated activation key workflow.\nNo artist profile was installed or restarted by this delivery.\n',encoding='utf-8')
print(json.dumps({'distribution':str(DEST),'artifacts':record['artifacts']},indent=2))
