"""Record the scoped UI follow-up without rewriting earlier qualification."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,zipfile

ROOT=Path(__file__).resolve().parents[2]
RUN=ROOT/'build/ui-polish-0862-20261019'
PAIR=Path('D:/CyrusScatterBuilds/ui-polish-0862-20261019/pair03')
DOC=ROOT/'docs/plans/preset-gallery-improvements'
DEST=ROOT/'dist/CyrusScatter-0.86.2-20261019-ui02'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:p.read_text(encoding='utf-8-sig')
receipt=json.loads(read(PAIR/'receipt.json'))
for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
assert all(s['exit_code']==0 for s in receipt['stages'])
assert '100% tests passed, 0 tests failed out of 45' in read(PAIR/'tests.log')
assert 'PASSED 42' in read(RUN/'managed02/result.txt')
assert sha(RUN/'managed02/CyrusGallery.dll')==sha(PAIR/'CyrusGallery.dll')
assert 'PASSED 35' in read(RUN/'distribution01/result.txt')
assert json.loads(read(RUN/'generated-final02/generated-check.json'))['passed']
w=ROOT/'build/mcp-qualification/density0862-w'
x=ROOT/'build/mcp-qualification/density0862-x'
assert all(s['exit_code']==0 for s in json.loads(read(w/'final-campaign.json')))
for host in (w,x):
 assert sha(host/'scripts/CyrusScatter.ms')==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
 for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusScatterEdit.dlm','CyrusBrushStorage.dlh'):
  assert sha(host/'bin'/name)==sha(PAIR/name)
 for name in ('thumbnail-campaign.txt','ui-polish-contract.txt','physical-pattern-load.txt'):
  assert 'PASS' in read(host/name) and 'FAIL' not in read(host/name),str(host/name)
 assert 'CLIPPED=#()' in read(Path(read(host/'layout-latest.txt').strip()))
 assert 'open=true' in read(host/'dropdown-final.txt') and 'open=false' not in read(host/'dropdown-final.txt')
 assert len(list((host/'scripts/Patterns').glob('*.png')))==3
 for p in (ROOT/'AminScatter/patterns').glob('*'):
  if p.is_file():assert sha(p)==sha(host/'scripts/Patterns'/p.name)
assert 'PASS' in read(w/'physical-library-load.txt') and 'PASS' in read(w/'physical-idle.txt')
candidate=json.loads(read(RUN/'package01/candidate.json'))
assert not DEST.exists();DEST.mkdir(parents=True)
artifacts=[]
for name,key in [('CyrusScatter-0.86.2-Max2027.mzp','mzp_sha256'),('CyrusScatter-0.86.2-Setup.exe','exe_sha256')]:
 source=RUN/'package01'/name;assert sha(source)==candidate[key]
 shutil.copy2(source,DEST/name)
 artifacts.append({'path':(DEST/name).relative_to(ROOT).as_posix(),'bytes':source.stat().st_size,'sha256':sha(source)})
with zipfile.ZipFile(DEST/'CyrusScatter-0.86.2-Max2027.mzp') as z:
 assert z.testzip() is None
 manifest=json.loads(z.read('manifest.json'))
 for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
 assert hashlib.sha256(z.read('CyrusScatter.ms')).hexdigest()==sha(w/'scripts/CyrusScatter.ms')
for p in (RUN/'package01/payload/Library').rglob('*'):
 if p.is_file():assert sha(p)==sha(w/'scripts/Library-0.86.2'/p.relative_to(RUN/'package01/payload/Library'))
evidence=[]
paths=[RUN/'baseline.json',RUN/'generated-final02/generated-check.json',RUN/'managed02/result.txt',RUN/'distribution01/result.txt']
for host in (w,x):
 paths.extend(host/name for name in ('launch.json','script-staging-history.json','ui-polish-contract.txt','thumbnail-campaign.txt','thumbnail-checks.txt','dropdown-final.txt','physical-pattern-load.txt'))
 paths.append(Path(read(host/'layout-latest.txt').strip()))
paths.extend(w/name for name in ('final-campaign.json','extended.log','workflow.log','examples.log','save.log','physical-library-load.txt','physical-idle.txt','field-numeric.txt','channels.txt') if (w/name).is_file())
paths.extend(RUN.glob('*.png'))
for p in paths:evidence.append({'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)})
result={'version':'0.86.2','schema':58,'date':'2026-10-19','scope':'Amount panel, dropdown focus, starter masks and Layer/Model name presentation',
 'version_reason':'User requested fixes in the existing version; no persistence schema or placement contract change.',
 'supersedes_installers_only':'QUALIFICATION_0862_CORRECTION.json','previous_receipt_sha256':sha(DOC/'QUALIFICATION_0862_CORRECTION.json'),
 'git_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
 'native_pair_receipt':str(PAIR/'receipt.json'),'native_pair_sha256':sha(PAIR/'receipt.json'),
 'native_test_scope':'45 tests ran on native01. Pair03 changes generated UI only, with native source/binary identity verified. Final script received fresh host tests.',
 'sources':receipt['sources'],'artifacts':artifacts,'manifest':manifest,'evidence':evidence,
 'tests':{'native':45,'python':175,'managed':42,'distribution':35,'python_command':'build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q','python_result':'175 passed in 14.24s; exec session 47898',
 'host_scope':'Max 2027, owned profiles w (100%) and x (150%); final full campaign in w and targeted UI/thumbnail/layout tests in x',
 'physical':'First-click Coordinates dropdown survives idle and explicit status refresh at 100%/150%; Layers copy dropdown at 150%; Escape dismissal; wheel/background drag; More settings; direct map picker and cancel; product pattern double-click; packaged three-layer meadow Load onto surface.'},
 'limits':['Physical mixed-monitor transitions and a physical 4K display were not tested. Max UI scale was explicitly 100% and 150%.',
 'Three original grayscale starter masks only; final artwork still comes from the user.',
 'ImgTag uses a magenta transparency key so grayscale black remains opaque. Pure magenta in custom color thumbnails remains a presentation limitation; it does not change density sampling.',
 'Map adapters, renderer support and recipe portability remain scoped by the existing delivery contracts.'],
 'artist_installation_performed':False,'git_push_performed':False,'knowledge_activation_performed':False,'further_roadmap_work':'paused'}
(DOC/'QUALIFICATION_0862_UI.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
(DEST/'SHA256.txt').write_text('\n'.join(a['sha256']+'  '+Path(a['path']).name for a in artifacts)+'\n',encoding='utf-8')
table='\n'.join('| ['+('Max 2027 MZP' if a['path'].endswith('.mzp') else 'Unsigned Max 2027 EXE')+'](../../../'+a['path']+') | '+f"{a['bytes']:,}"+' | `'+a['sha256']+'` |' for a in artifacts)
section=f'''## Current UI follow-up — 19 October 2026

**Version remains 0.86.2. Use this installer pair.** [Exact qualification](QUALIFICATION_0862_UI.json) supersedes the earlier installer pair; earlier receipts and artifacts remain historical evidence.

| Current installer | Bytes | SHA-256 |
| --- | ---: | --- |
{table}

Save your scene, run the EXE **or Scripting > Run Script** with the MZP, then restart Max 2027. The version caption is unchanged. No artist installation/restart or Git push was performed. Further roadmap work and knowledge activation remain paused.

### What changed

- Fixed first-click dropdown dismissal. Native message tracing reproduced a focus transfer from the combo to its outer Qt host. The owned input hook now establishes that host focus before the original combo handler runs. Selection, keyboard, dismissal and wheel behavior remain native. No timer, placement evaluation or buffer upload is added.
- Amount now says **Use image**, with **Choose pattern** above paired **Image / Map** buttons. Map opens Max's browser directly with no image prerequisite; choosing a map enables the input. Cancel preserves it. The selected-map field appears only when assigned and retains native drag/drop. Empty thumbnails reserve no blank row.
- Bundled **Uniform, Soft patches and Wide bands** as three original starter masks. This supersedes the earlier empty-product-catalog decision at the user's request. Final artwork can still replace/extend them later.
- Disabled image/channel controls collapse. Explanatory paragraphs move to tooltips. **More settings / Fewer settings** groups image sampling/portability, mask display and population/retries directly beneath its button.
- Models now match Layers: Name label and color, then a full-width name edit. Both list views ellipsize only the name and reserve space for metadata. Full authored names, including separator characters and non-ASCII text, remain unchanged and are available in the edit/tooltip.
- Grayscale thumbnail black is opaque instead of being the default transparency key. The existing bounded native stretch display is retained. Pure magenta in a custom color thumbnail remains a presentation limitation; Show mask and density sampling are unaffected.

### Evidence and artist checks

Native **45/45**, Python **175**, managed gallery **42** and installer distribution **35** checks passed. Generated/catalog consistency accounts for 320 controls. Exact source, package and loaded native/script identities are recorded. Native tests ran on native01; pair03 reused its verified binaries for the final UI script and received fresh host tests.

Owned Max 2027 tests at **100% and 150% UI scale** cover empty/image/procedural/missing-map panels, Map/Clear, Undo/Redo, panel and scene reopening, long names, More settings and horizontal layout bounds. Physical first-click dropdown tests survive idle/status refresh; wheel and background drag work. A packaged meadow loaded through the visible library onto a selected plain terrain. All eight examples pass compatible-terrain Add/Undo/Redo. Saved image/Paint/model recipes, missing dependencies and late-failure rollback pass in the final 100% campaign. These scales do not establish physical mixed-monitor or 4K-display qualification.

The final campaign also checks density/mesh/combined fields, Data Channel edits, persistent mask refresh, Manual retention, relevant Live updates, unrelated animation and heavy idle reuse. Candidate count changes through 250,000 retain exact Undo and reuse the sampled image. Fifty passive binds do not calculate, prepare or rebake.

**Pending is expected in Manual after edits.** It means the previous result is retained until Update; it does not mean background calculation. Explicit Update cleared every pending layer in the three-layer fixture; passive binding/idle then kept the same clean publication. In Live, persistent Pending after a relevant edit requires checking diagnostics.

Artist checks: reopen Amount with no map; choose each starter pattern; choose a Max map directly; reopen dropdowns after clicking elsewhere; use More settings, scroll and drag; rename Layers/Models with long labels; confirm metadata remains visible; press Update and check Pending becomes OK. Existing recipe/channel/Paint compatibility rules still apply.

'''
path=DOC/'DELIVERY_0862.md';old=read(path)
assert '## Current UI follow-up' not in old
old=old.replace('## Same-version correction — 19 October 2026','## Earlier same-version correction — 19 October 2026',1)
old=old.replace('**Use these corrected installers. Version remains 0.86.2 at the user\'s request.**','**Historical correction installers, superseded by the UI follow-up above. Version remained 0.86.2 at the user\'s request.**',1)
first,rest=old.split('\n',1);path.write_text(first+'\n\n'+section+rest.lstrip(),encoding='utf-8')
def replace(path,old,new):
 text=read(path);assert old in text,str(path);path.write_text(text.replace(old,new,1),encoding='utf-8')
replace(ROOT/'README.md','The same-version correction fixes empty/procedural-map Amount errors and cropped thumbnails; use the latest installers in that report.','The latest same-version UI follow-up fixes dropdown focus, simplifies Amount, bundles three starter masks and preserves metadata beside long Layer/Model names; use the latest installers in that report.')
replace(ROOT/'docs/plans/improvement-program/PROGRESS.md','The same-version correction fixes empty/procedural-map Amount errors and whole-image thumbnail scaling, with all eight library examples and every layer panel rechecked.','The same-version corrections fix empty/procedural-map Amount errors, whole-image thumbnail display and dropdown focus. The current UI follow-up simplifies Amount, installs three starter masks and ellipsizes Layer/Model names while retaining metadata; all eight examples and actual panel workflows were rechecked.')
replace(ROOT/'docs/plans/improvement-program/PROGRESS.md','D04 follows the user’s 19 October steering: only three generated QA fixtures; final product artwork comes later from the user.','D04 follows the latest 19 October steering: install three original grayscale starter patterns so Choose pattern works immediately; final product artwork still comes later from the user.')
replace(ROOT/'docs/plans/improvement-program/PROGRESS.md','User-supplied final artwork; qualify picker/mapping with three generated test masks only','Three original installed starter masks; user-supplied final artwork remains later')
replace(ROOT/'docs/plans/improvement-program/PROGRESS.md','Layer Name label/color row followed by a full-width name input; long-name editing and DPI/navigation regression','Layer/Model Name label/color row followed by full-width inputs; names ellipsize without hiding metadata; DPI, dropdown and navigation regression')
print(json.dumps({'artifacts':artifacts,'receipt':str(DOC/'QUALIFICATION_0862_UI.json')},indent=2))
