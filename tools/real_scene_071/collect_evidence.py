"""Freeze small receipts and verify the original input before delivery."""
from pathlib import Path
import datetime,hashlib,json,shutil,statistics,subprocess

ROOT=Path(__file__).resolve().parents[2]
HOST=ROOT/'build/mcp-qualification/procedural07-real-scene-071-full'
OUT=ROOT/'docs/Real_Scene_0.7.1_2026-10-05/evidence'
OUT.mkdir(parents=True,exist_ok=True)

def digest(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
 return h.hexdigest()

identity=json.loads((ROOT/'build/real-scene-071/input-identity.json').read_text())
original=Path(identity['input'])
assert original.stat().st_size==identity['bytes'] and digest(original)==identity['sha256'],'Artist input changed'
campaign=json.loads((HOST/'campaign.json').read_text())
oracle=json.loads((HOST/'independent-oracle.json').read_text())
assert campaign['complete'] and oracle['status']=='PASS'
assert oracle['sha256']==digest(HOST/'published-placements.csv'),'Oracle is stale'
assert (HOST/'published-placements.csv').read_bytes()==(HOST/'published-placements-after.csv').read_bytes()
render=json.loads((HOST/'render-final.json').read_text())
assert render['finished'] and all(v[3]=='' for v in render['views'])
names=['campaign.json','navigation.json','independent-oracle.json','advanced-campaign.json','rare-options.json','brush-history.json','curved-path.json','path-acceptance.json','flower-corridor.json','pointer-paint.json','pending-status.json','path-clearance-diagnostic.json','terrain-roundtrip.json','surface-diagnostic.json','render-final.json','loaded.tsv','curved-path.csv']
for name in names:shutil.copy2(HOST/name,OUT/name)
for name in ['identity.json','input-identity.json']:shutil.copy2(ROOT/'build/real-scene-071'/name,OUT/name)
shutil.copy2(ROOT/'build/mcp-qualification/procedural07-real-scene-071/relink.json',OUT/'asset-relink.json')
launches=sorted((ROOT/'build/user-tests/real-scene-071').glob('*/open-result.json'),key=lambda p:p.stat().st_mtime)
assert launches,'Fresh-process launch is unverified'
launch=json.loads(launches[-1].read_text())
assert [p['instances'] for p in launch['populations']]==[oracle['counts'][str(i)] for i in range(1,9)],'Fresh process counts differ'
assert digest(Path(launch['scene']))==digest(Path(launch['working_copy'])),'The freshly opened scene differs from delivery'
launch['verified_scene_sha256']=digest(Path(launch['scene']))
(OUT/'fresh-process-launch.json').write_text(json.dumps(launch,indent=2)+'\n')
nav=json.loads((HOST/'navigation.json').read_text())
timings=[]
for trial in nav['trials']:
 mode,values,before,after,mesh=trial
 timings.append({'mode':mode,'sample_count':len(values),'median_sync_ms':statistics.median(values),'min_sync_ms':min(values),'max_sync_ms':max(values),'upload_count_unchanged':before[5]==after[5],'upload_bytes_unchanged':before[6]==after[6],'retained_failures_before_after':[before[8],after[8]],'mesh_telemetry':mesh})
(OUT/'navigation-summary.json').write_text(json.dumps({'metric':nav['metric'],'trials':timings},indent=2)+'\n')
files=[]
for path in sorted((ROOT/'Test Scene/Cyrus_071_Courtyard').iterdir()):
 if path.suffix.lower() in ('.max','.png'):files.append({'path':str(path.relative_to(ROOT)),'bytes':path.stat().st_size,'sha256':digest(path)})
source_files=[*sorted((ROOT/'tools/real_scene_071').glob('*.py')),*sorted((ROOT/'tools/real_scene_071').glob('*.ms')),ROOT/'tools/real_scene_071/Open_Garden_Pavilion.cmd',ROOT/'tools/procedural_lab/layer_editor_071/private_host.py']
manifest={'recorded_at':datetime.datetime.now().astimezone().isoformat(),'original_preserved':True,'input':identity,'final_population_counts':oracle['counts'],'exact_instances':oracle['instances'],'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'working_tree':subprocess.check_output(['git','status','--short'],cwd=ROOT,text=True).splitlines(),'outputs':files,'fixture_sources':[{'path':str(p.relative_to(ROOT)),'sha256':digest(p)} for p in source_files]}
(OUT/'delivery-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'original_preserved':True,'instances':oracle['instances'],'collision_pairs':oracle['collision_pairs_checked'],'files':len(files),'evidence':str(OUT)},indent=2))
