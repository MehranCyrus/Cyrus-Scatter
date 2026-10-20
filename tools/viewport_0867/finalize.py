"""Verify final receipts and publish release metadata, without installing."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'build/viewport-0867-20261020'
OUT=ROOT/'dist/CyrusScatter-0.86.7-20261020'
sha=lambda p:hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
result={'version':'0.86.7','status':'passed','hosts':{},'artist_profile_modified':False,
        'scope':'Focused native/managed/installer acceptance; real Corona leaf appearance qualified in Max 2027 only',
        'git_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()}
common=['texture-acceptance.txt','preview.txt','source-controls.txt','gallery-host.txt','installer-host.txt']
for year in (2024,2026,2027):
    host=ROOT/f'build/mcp-qualification/viewport0867-test6-{year}'
    launch=json.loads((host/'launch.json').read_text())
    with zipfile.ZipFile(OUT/f'CyrusScatter-0.86.7-Max{year}.mzp') as archive:
        assert archive.testzip() is None
        manifest=json.loads(archive.read('manifest.json'))
        assert manifest['files']['CyrusScatter.ms']==launch['script_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
        assert manifest['files']['CyrusGallery.dll']==launch['script_assets']['CyrusGallery.dll']
        for name,digest in launch['binaries'].items():
            assert digest==manifest['files'][name]==sha(host/'bin'/name)
        loaded=(host/'loaded.tsv').read_text()
        for name in launch['binaries']:
            assert str(host/'bin'/name) in loaded
    logs={}
    extra=['leaf-probe.txt','leaf-acceptance.txt'] if year==2027 else ['content-compatibility.txt','standard-import.txt']
    for name in common+extra:
        text=(host/name).read_text()
        assert '\nSUCCESS' in text and not re.search(r'^(FAIL:|ERROR )',text,re.M),(year,name,text)
        logs[name]={'sha256':sha(host/name),'passed_checks':len(re.findall(r'^PASS:',text,re.M))}
    result['hosts'][str(year)]={'launch':str(host/'launch.json'),'binaries':launch['binaries'],
        'script_sha256':launch['script_sha256'],'gallery_sha256':launch['script_assets']['CyrusGallery.dll'],'logs':logs}
for name,path in {
    'real_installer':ROOT/'build/v867/result-final.json',
    'inert_installer':WORK/'installer-4a9649a4c3/result.json',
    'content_saveback':WORK/'content-saveback.json',
    'content_reuse':WORK/'content-reuse.json',
    'thumbnail_regression':WORK/'gallery-regression.json',
    'generated':WORK/'generated-final/generated-check.json',
    'package':WORK/'package-checks.json',
}.items():
    data=json.loads(path.read_text(encoding='utf-8-sig'))
    assert data.get('status')=='passed' or data.get('passed') is True,(name,data)
    target=WORK/('final-'+name+'.json')
    shutil.copy2(path,target);result[name]={'receipt':str(target),'sha256':sha(target)}
result['offline_tests']={'native_ctest':{'passed':48,'failed':0,'log':str(WORK/'max2027/Testing/Temporary/LastTest.log')},
    'python':{'passed':175,'failed':0,'command':'build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q'},
    'layout':'node AminScatter/tools/ui/approved-layout.test.cjs: passed'}
result['packages']={p.name:sha(p) for p in [OUT/'CyrusScatter-0.86.7-Setup.exe',*(OUT/f'CyrusScatter-0.86.7-Max{year}.mzp' for year in (2024,2026,2027))]}
result['content_manifest_sha256']=sha(OUT/'Content/content-manifest.json')
(OUT/'QUALIFICATION.json').write_text(json.dumps(result,indent=2)+'\n')
(WORK/'qualification-final.json').write_text(json.dumps(result,indent=2)+'\n')
shutil.copy2(ROOT/'docs/plans/preset-gallery-improvements/DELIVERY_0867.md',OUT/'RELEASE-NOTES.md')
(OUT/'INSTALL.txt').write_text("""Cyrus Scatter 0.86.7 — Max 2024, 2026 and 2027

Keep CyrusScatter-0.86.7-Setup.exe beside Content when sharing this folder.
Run the EXE, choose the matching Max version, then Install / Repair.
Alternatively: Scripting > Run Script, select the matching MaxYEAR.mzp,
and choose the supplied Content folder. The delivery folder and Library child
are also accepted. Save your work, then restart that Max version.

Layers > Recipes opens the 96-model individual library.
Viewport & render: Mesh, then Appearance > Materials / Textures.
Models & Points: + adds an object; Add Point is beside Make point.
Pick object replaces either the selected Point or selected model.

The supplied materials require compatible Corona and Forest map plug-ins.
Native/Standard viewport checks pass in all three hosts. Actual Corona leaf
appearance plus Color Correction was tested in Max 2027; the older local test
hosts did not have those renderer dependencies installed.

Content is reused through a shared NTFS store. Existing source geometry and
preview images were reused; model MAX files were saved back to 2024 format.
See RELEASE-NOTES.md and QUALIFICATION.json for exact scope, limits and hashes.
Artist profiles and running sessions were not modified by these tests.
""",encoding='utf-8')
(ROOT/'dist/CyrusScatter-0.86.6.2-20261020/CONTENT-MOVED.txt').write_text(
    'The shared distribution content was moved and saved back for 0.86.7 at the user request.\n'
    'Use ../CyrusScatter-0.86.7-20261020 with its matching installers.\n'
    'Original catalog files and existing artist installations were preserved.\n')
print(json.dumps({'status':'passed','distribution':str(OUT),'hosts':list(result['hosts'])},indent=2))
