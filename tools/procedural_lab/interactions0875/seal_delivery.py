"""Seal scoped final package/Max evidence and copy owned example scenes."""
from pathlib import Path
import hashlib,json,math,re,shutil,statistics,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[3];RUN=ROOT/'build/interactions0875-20261027-01';HOST=RUN/'host-final-pair';DOC=ROOT/'docs/plans/shared-pose-viewport-0875-20261027'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
sys.path.insert(0,str(ROOT/'tools'));import build_inputs
producer=RUN/'native-final-pair/receipt.json';native=read(producer);assert native['status']=='complete' and native['tests_run'] and native['max_year']==2027
build_inputs.verify_frozen(native['input_manifest'],ROOT)
for path,digest in native['sources'].items():assert sha(ROOT/path)==digest,path
identity=read(RUN/'payload-final-pair/package-identity.json');archive=Path(identity['archive']);assert sha(archive)==identity['sha256']
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'));assert manifest['version']=='0.87.5' and manifest['max_year']==2027
    for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
loaded=read(HOST/'loaded-identity.json')
for name,item in loaded['modules'].items():assert item['sha256']==sha(Path(item['path']))==manifest['files'][name],name
paired=RUN/'payload-final-pair/CyrusScatter.ms'
assert sha(paired)==manifest['files']['CyrusScatter.ms']==read(RUN/'generated-seal/generated-check.json')['generated_sha256']
assert loaded['script_fingerprint']==re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]{64})"',paired.read_text(encoding='utf-8-sig'))[1]
runtime=['grass','fern','two-sources','authored-fern','bake','all-hidden','failure','record-undo','undo-read','redo-read','save-Grass','save-Fern','save-Authored','reload-saved','warm','library-configured','bench-gpu-200','bench-cpu-200','bench-gpu-1000','bench-cpu-1000','drag-before','drag-after']
checks={}
for phase in runtime:
    file=HOST/('runtime-'+phase+'.json');data=read(file);assert data['status']=='pass',phase;checks[phase]={'path':str(file),'sha256':sha(file)}
for phase in ['setup','view-mesh-wire','view-texture-wire','view-split','pending']:
    file=HOST/('check-'+phase+'.json');assert read(file)['status']=='pass',phase;checks[phase]={'path':str(file),'sha256':sha(file)}
before=read(HOST/'runtime-drag-before.json');after=read(HOST/'runtime-drag-after.json');assert before['transform']!=after['transform'] and after['statistics']['updates']>before['statistics']['updates']
assert after['counters']['streams'][1]==before['counters']['streams'][1]
measurements=[]
for count in (200,1000):
    for mode in ('gpu','cpu'):
        d=read(HOST/f'runtime-bench-{mode}-{count}.json');samples=d['samples'];a=d['after']['streams'];b=d['before']['streams']
        measurements.append({'plants':count,'mode':mode,'steps':len(samples),'native_edit_median_ms':statistics.median(x['timing']['edit_ms'] for x in samples),'first_redraw_command_median_ms':statistics.median(x['timing']['first_redraw_ms'] for x in samples),'kernel_total_median_ms':statistics.median(x['statistics']['total_ms'] for x in samples),'wall_with_event_waits_median_ms':statistics.median(x['wall_update_redraw_ms'] for x in samples),'geometry_bytes':a[1]-b[1],'pose_bytes':a[6]-b[6],'source_binding_bytes':a[7]-b[7],'max_warned_guides':max(x['statistics']['quality_warning_guides'] for x in samples),'max_reported_stem_edge_change':max(x['statistics']['maximum_checked_stem_edge_change'] for x in samples)})
gpu=read(RUN/'gpu-final-pair/gpu-audit.json');assert gpu['status']=='pass' and gpu['shader_sha256']==sha(ROOT/'AminScatter/src/deformation_shader.inc')
examples={};destination=archive.parent/'TestScenes';destination.mkdir(exist_ok=True)
for kind in ('Grass','Fern','Authored'):
    saved=read(HOST/('runtime-save-'+kind+'.json'));source=Path(saved['scene']);target=destination/source.name
    assert source.resolve().is_relative_to(HOST);shutil.copy2(source,target);assert sha(source)==sha(target)
    examples[kind]={'path':str(target),'sha256':sha(target),'bytes':target.stat().st_size}
launch=read(HOST/'launch.json');artist=Path.home()/'AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
fixture=read(ROOT/'build/interactions08741-20261027-01/fixture-manifest.json');original=ROOT/'Test Scene/New Plants test.max';original_ok=sha(original)==fixture['plant_scene']['sha256'];assert original_ok
report={'status':'scoped_pass','version':'0.87.5','max_year':2027,'native_capability':12,'scene_schema':63,'recipe_version':9,'edit_storage_version':3,'managed_version':'0.87.5.0','branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'source_receipt':str(producer),'source_files_verified':len(native['sources']),'archive':str(archive),'archive_sha256':sha(archive),'bytes':archive.stat().st_size,'installer':read(RUN/'installer-final-pair/receipt.json'),'loaded_identity':loaded,'generated':read(RUN/'generated-seal/generated-check.json'),'artist_ini_observed_unchanged':sha(artist)==launch['artist_ini_sha256'],'original_scene_preserved':original_ok,'checks':checks,'physical_pointer':{'updates':after['statistics']['updates']-before['statistics']['updates'],'last_fit_ms':after['statistics']['fit_ms'],'geometry_bytes':after['counters']['streams'][1]-before['counters']['streams'][1],'pose_bytes':after['counters']['streams'][6]-before['counters']['streams'][6]},'gpu_math':gpu,'measurements':measurements,'test_scenes':examples,'limitations':['Dense/deep stress quality warnings remain, identically in both producers; not whole-scene visual quality acceptance.','Kernel timings, redraw commands, SDK logical bytes and event waits are separate from presented FPS or measured PCIe traffic.','Max 2027 on the tested hardware only; production-renderer frames and other hosts/GPUs are unqualified.','One early development source-switch exception remains an undiagnosed historical observation; later final-profile checks passed.','Knowledge retrieval was stale; original sources were inspected. No corpus refresh, artist installation or Git push was performed.']}
text=json.dumps(report,indent=2)+'\n';(RUN/'qualification-final.json').write_text(text,encoding='utf-8');(DOC/'QUALIFICATION_0875.json').write_text(text,encoding='utf-8')
print(json.dumps({'status':report['status'],'archive':str(archive),'sha256':report['archive_sha256'],'source_files_verified':report['source_files_verified'],'artist_ini_observed_unchanged':report['artist_ini_observed_unchanged'],'scenes':examples,'physical_pointer':report['physical_pointer']},indent=2))
