"""Copy only verified scene artifacts to a fresh user-facing folder and ZIP."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,shutil,zipfile
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('host',type=Path);p.add_argument('destination',type=Path);a=p.parse_args()
host=a.host.resolve();destination=a.destination.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-feature-demo0824-')
assert destination.is_relative_to(ROOT/'Test Scene') and not destination.exists()
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
receipt=json.loads((host/'demo-delivery-scene.json').read_text());assert receipt['status']=='passed' and receipt['max_year']==2027
assert receipt['all_five_full_row_publications_restored'] and not receipt['contains_temporary_preview_meshes'] and receipt['external_assets']==0
launch=json.loads((host/'launch.json').read_text());assert launch['max_year']==2027 and not launch['normal_profile_modified']
native=json.loads((ROOT/'build/mesh-mask-0824-20261015-01/script-03/receipt.json').read_text())
spec=importlib.util.spec_from_file_location('offline',ROOT/'tools/procedural_lab/offline_build.py')
offline=importlib.util.module_from_spec(spec);spec.loader.exec_module(offline)
assert native['sources']==offline.source_hashes('AminScatter')
assert sha(host/'scripts/CyrusScatter.ms')==launch['script_sha256']==native['sources']['AminScatter/scripts/AminScatterObject.ms']
for name,h in launch['binaries'].items():assert sha(host/'bin'/name)==h
scene=Path(receipt['scene']);assert scene.parent==host and sha(scene)==receipt['scene_sha256']
assert all(sha(host/name)==h for name,h in receipt['previews'].items())
destination.mkdir()
files={scene.name:scene,'START HERE.md':Path(__file__).with_name('START HERE.md'),
    'Scene verification.json':host/'demo-delivery-scene.json',**{n:host/n for n in receipt['previews']}}
for name,path in files.items():shutil.copy2(path,destination/name)
manifest={'scene_version':'0.82.4','max_year':2027,'counts':receipt['counts'],'total_accepted':receipt['total_accepted'],
    'file_hashes':{name:sha(destination/name) for name in files},'external_assets':0,'computer_use_used':False,
    'source_script_sha256':launch['script_sha256'],'native_binaries':launch['binaries'],'phase6':'paused'}
(destination/'Manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
archive=destination/'CyrusScatter 0.82.4 Feature Demo.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for name in [*files,'Manifest.json']:z.write(destination/name,name)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    for name,h in manifest['file_hashes'].items():assert hashlib.sha256(z.read(name)).hexdigest()==h
(destination/'CyrusScatter 0.82.4 Feature Demo.sha256').write_text(receipt['scene_sha256']+'  '+scene.name+'\n'+sha(archive)+'  '+archive.name+'\n')
delivery={'status':'passed','scene':str(destination/scene.name),'scene_sha256':receipt['scene_sha256'],
    'zip':str(archive),'zip_sha256':sha(archive),'counts':receipt['counts'],'total_accepted':receipt['total_accepted'],
    'assertions':receipt['assertions'],'plugin_code_changed':False,'computer_use_used':False,'installed':False,'phase6':'paused'}
(host/'delivery.json').write_text(json.dumps(delivery,indent=2)+'\n')
print(json.dumps(delivery,indent=2))
