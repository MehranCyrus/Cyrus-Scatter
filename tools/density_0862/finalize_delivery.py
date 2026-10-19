"""Verify scoped evidence and publish the exact qualified 0.86.2 artifacts/docs."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,sys,zipfile

ROOT=Path(__file__).resolve().parents[2]
BUILD=ROOT/'build/density-recipes-0862-20261018-01'
NATIVE=Path('D:/CyrusScatterBuilds/density-recipes-0862-20261018-01/native04')
PACKAGE=BUILD/'package07';DIST=ROOT/'dist/CyrusScatter-0.86.2-20261019'
DOC=ROOT/'docs/plans/preset-gallery-improvements'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def read(path):return path.read_text(encoding='utf-8-sig')
def json_read(path):return json.loads(read(path))
def good_log(path,needle=None):
    text=read(path)
    assert not re.search(r'^(?:FAIL|ERROR)\b',text,re.M),path
    if needle:assert needle in text,(path,needle)
    return {'path':str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path),'sha256':sha(path),'pass_lines':len(re.findall(r'^PASS:',text,re.M))}
def copy_identical(source,dest):
    if dest.exists():assert dest.read_bytes()==source.read_bytes(),dest
    else:shutil.copy2(source,dest)

receipt=json_read(NATIVE/'receipt.json')
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
for path,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/path)==digest,path
assert '100% tests passed, 0 tests failed out of 45' in read(NATIVE/'tests.log')
script_sha=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
candidate=json_read(PACKAGE/'candidate.json')
assert candidate['native_receipt_sha256']==sha(NATIVE/'receipt.json')
assert candidate['manifest']['files']['CyrusScatter.ms']==script_sha
assert candidate['manifest']['licensing']['mode']=='offline-team'
for name in ('CyrusScatter-0.86.2-Max2027.mzp','CyrusScatter-0.86.2-Setup.exe'):
    assert sha(PACKAGE/name)==candidate['mzp_sha256' if name.endswith('.mzp') else 'exe_sha256']
with zipfile.ZipFile(PACKAGE/'CyrusScatter-0.86.2-Max2027.mzp') as archive:
    assert archive.testzip() is None
    assert not any(n.startswith('Patterns/') and n.endswith('.png') for n in archive.namelist())
    for name,digest in candidate['manifest']['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name

evidence=[]
host=ROOT/'build/mcp-qualification/density0862-m'
campaign=json_read(host/'final-campaign.json')
assert len(campaign)==9 and all(s['exit_code']==0 for s in campaign)
for name,needle in (
    ('initial.txt','White projected image works without terrain UVs'),
    ('extended.log','HEAVY 250000 candidates:'),('field-numeric.txt','maximum_error='),
    ('channels.txt','Missing UV7 is rejected with a plain channel number'),
    ('workflow.log','PASS campaign workflow'),('examples.log','PASS campaign examples'),
    ('save.log','PASS campaign save'),('demo-verify.txt','Reopen reproduces every full placement record'),
    ('lifecycle-liveIdle.txt','PASS: complete'),('lifecycle-unrelatedTime.txt','PASS: complete'),
    ('lifecycle-staleField.txt','PASS: complete'),('workflow-idleEnd.txt','Open gallery and idle'),
    ('relocated-demo-result.txt','PASS:'),('demo-curvatureVerify.txt','at the same frame'),
    ('demo-curvatureUndo.txt','exact channel values')):
    evidence.append(good_log(host/name,needle))

layouts=[]
for name,scale in (('density0862-o',1.0),('density0862-n',1.5),('density0862-k',2.0)):
    profile=ROOT/'build/mcp-qualification'/name;launch=json_read(profile/'launch.json')
    effective=launch['script_sha256']
    history=profile/'script-staging-history.json'
    if history.exists():effective=json_read(history)[-1]['script_sha256']
    assert effective==script_sha,name
    for binary,digest in launch['binaries'].items():
        assert sha(profile/'bin'/binary)==digest and digest==candidate['manifest']['files'][binary],binary
    path=Path(read(profile/'layout-latest.txt').strip())
    record=good_log(path,'PASS: all mounted visible control HWNDs fit')
    text=read(path);assert float(re.search(r'^scale=([\d.]+)',text).group(1))==scale and 'CLIPPED=#()' in text,text[-700:]
    record.update({'host':name,'scale':scale,'script_sha256':effective});layouts.append(record)
assert json_read(host/'launch.json')['script_sha256']==script_sha
for line in read(host/'loaded.tsv').splitlines():
    name,path=line.split('\t');assert Path(path).resolve().is_relative_to((host/'bin').resolve())
    assert sha(Path(path))==candidate['manifest']['files'][name]

managed=good_log(BUILD/'managed-final/result.txt','PASSED 41 managed gallery checks')
assert sha(BUILD/'managed-final/CyrusGallery.dll')==candidate['manifest']['files']['CyrusGallery.dll']
distribution=good_log(BUILD/'distribution07/result.txt','PASSED 35 universal distribution checks')
for name in ('name-checks.txt','viewport-redraw.txt'):
    evidence.append(good_log(ROOT/'build/mcp-qualification/density0862-j'/name,'PASS:'))
# j preceded only the final thumbnail-row layout change; explicitly retain its identity.
previous_launch=json_read(ROOT/'build/mcp-qualification/density0862-j/launch.json')
previous_history=json_read(ROOT/'build/mcp-qualification/density0862-j/script-staging-history.json')
ui_identity={'host':'density0862-j','script_sha256':previous_history[-1]['script_sha256'],'scope':'Physical long-name keyboard/Undo and no-solve/no-upload evidence before the final thumbnail-only row change; final source physical wheel/drag observed in density0862-n.'}

# Persist final general checks once, rather than depending on transient console output.
check_dir=BUILD/'delivery-checks';check_dir.mkdir(exist_ok=False)
for label,command in (
    ('generated',[sys.executable,'tools/procedural_lab/check_generated.py','--output',str(check_dir/'generated')]),
    ('python',[str(ROOT/'build/mcp-venv/Scripts/python.exe'),'-m','pytest','CyrusMCP/tests','tools/tests','-q'])):
    result=subprocess.run(command,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (check_dir/(label+'.log')).write_text(result.stdout+result.stderr,encoding='utf-8')
    assert result.returncode==0,result.stdout+result.stderr
generated=json_read(check_dir/'generated/generated-check.json')
assert generated['passed'] and generated['generated_sha256']==script_sha
python_log=read(check_dir/'python.log');assert '174 passed' in python_log,python_log

demo=DIST/'Demo';demo_id=json_read(demo/'DEMO-IDENTITY.json')
for name,digest in demo_id['files'].items():assert sha(demo/name)==digest,name
demo_readme='''# Cyrus Scatter 0.86.2 — editable feature demonstration

Install the matched Max 2027 package and restart Max first. Extract the entire Demo folder. In Max 2027 choose **Scripting > Run Script > OPEN DEMO.ms**. The opener rebinds the two included test maps relative to its folder. Keep them beside the MAX file when moving it. Save your own scenes before opening the demonstration.

Select `CYRUS 0.86.2 | SELECT ME - six feature layers` and choose a layer. The scene is Manual: edit, then **Update scatter** to change plants. **Show mask** follows field edits while the last published plants remain visible; **Hide mask** removes it. Try Image, Mesh and Combined views and change physical tile size or Invert. The orange image-only strip has no numeric-channel requirement.

| Layer in the list | What to inspect |
| --- | --- |
| 01 Density | Flat-plane Channel 2/X ramp: increasing density across the plane |
| 02 Paint | Receiver-bound Paint with density and scale fading at the borders |
| 03 Bands | Two inside spline Bands with opposite density and scale curves |
| 06 Image pattern only | World XY soft-patches image; tile size, rotation, Repeat and image response |
| 04 Mountain / Normals ON | Real Data Channel Curvature in Channel 3/X, surface alignment and existing terrain filters |
| 05 Mountain / Normals OFF | Upright models, image × Curvature, slope/altitude and include/exclude clearing |

Both receivers and all pyramid sources/guides remain editable. Saved cameras offer overview and closer views. Modify the mountain's Data Channel Curvature scale and inspect the channel mask, then Undo. World/Local projection needs no receiver UVs; UV mode is an explicit advanced choice.

The PNGs are independently generated **QA fixtures**, not final product pattern artwork. Only three fixtures were generated; this demo uses two. The product installer contains no pattern PNGs. Final artwork will come from the user. Saved Paint requires compatible receiver geometry, frame and units when used in a recipe on other terrain; the plugin does not recreate arbitrary modifier stacks or reproject Paint automatically.

The complete publication was compared after save/reopen and after moving this folder. This is a demonstration and scoped engineering test, not a production asset library or renderer qualification.
'''
(demo/'README.md').write_text(demo_readme,encoding='utf-8')
for name in ('CyrusScatter-0.86.2-Max2027.mzp','CyrusScatter-0.86.2-Setup.exe'):copy_identical(PACKAGE/name,DIST/name)
demo_zip=DIST/'CyrusScatter-0.86.2-Feature-Demo.zip';assert not demo_zip.exists()
with zipfile.ZipFile(demo_zip,'w',zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(demo.iterdir()):
        if path.is_file():archive.write(path,'Demo/'+path.name)
with zipfile.ZipFile(demo_zip) as archive:assert archive.testzip() is None
(DIST/'INSTALL.txt').write_text('Cyrus Scatter 0.86.2 — Max 2027 only\n\nSave your scene. Use either the unsigned EXE, or Scripting > Run Script with the .mzp. Restart Max afterward to load the complete script/native pair. Do not load loose scripts over older DLLs. Offline team licensing remains enabled.\n\nFor the editable demonstration, extract the Feature-Demo ZIP and run Demo/OPEN DEMO.ms after installing/restarting. The relative opener keeps its two QA maps portable. The installer excludes QA pattern artwork; final patterns will be supplied later.\n\nThe artist profile was not installed or restarted during qualification. Older Max versions retain only their separately labeled 0.86.1 packages/evidence.\n',encoding='utf-8')
artifacts={path.name:{'path':str(path.relative_to(ROOT)),'bytes':path.stat().st_size,'sha256':sha(path)} for path in sorted(DIST.iterdir()) if path.is_file() and path.name!='SHA256SUMS.txt'}
(DIST/'SHA256SUMS.txt').write_text(''.join(f"{item['sha256']}  {name}\n" for name,item in artifacts.items()),encoding='utf-8')
qualification={
    'status':'scoped-qualified','version':'0.86.2','date':'2026-10-19','max_year':2027,
    'git_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'working_tree_delivery':True,'git_push_performed':False,'artist_installed':False,'artist_restarted':False,
    'scene_schema':58,'recipe_format':6,'typed_recipe_fields':261,'library_capability':4,'asset_package_capability':2,'density_image_capability':2,
    'script_sha256':script_sha,'native_receipt':str(NATIVE/'receipt.json'),'native_receipt_sha256':sha(NATIVE/'receipt.json'),
    'sources':receipt['sources'],'binaries':receipt['binaries'],'package_manifest':candidate['manifest'],'artifacts':artifacts,
    'native_tests':45,'python_tests':174,'managed_checks':41,'distribution_checks':35,'generated_check':generated,
    'evidence':evidence,'layouts':layouts,'earlier_physical_ui_identity':ui_identity,'managed':managed,'distribution':distribution,
    'demo':demo_id,'qa_pattern_count':3,'product_pattern_png_count':0,
    'limits':[
        'New SDK and runtime qualification is Max 2027 only; 0.86.1 older-host evidence retains its original scope.',
        '100/150/200% custom-scale HWND bounds and owned-window navigation are qualified; physical 4K/mixed-monitor transitions are not.',
        'Overlay is bounded to at most 131072 triangles/faces; copied cache draws through immediate GW submissions, not a retained GPU overlay.',
        'Heavy operations remain synchronous and bounded. Counter/timing tests do not establish presented FPS or arbitrary scene performance.',
        'Portable asset adapters remain static mesh/Standard/PNG. Qualified live 2D maps can explicitly bake a linear 16-bit snapshot; editable procedural producers are not portable.',
        'Required Data Channel/VertexPaint data is validated, not automatically reconstructed. Receiver-bound Paint requires compatible topology/frame/units.',
        'External bitmap edits use Max reload/notifications, with no idle directory polling. Paint preview still uses a bounded serialized export into native storage.',
        'Only three QA images; final artwork is user-supplied later. No artist installation/restart, Git push or knowledge-index activation.'
    ]}
(DOC/'QUALIFICATION_0862.json').write_text(json.dumps(qualification,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'status':qualification['status'],'script_sha256':script_sha,'artifacts':artifacts},indent=2))
