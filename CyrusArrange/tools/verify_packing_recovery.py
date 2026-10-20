"""Independent actual complete-mesh proof for owned Quantity recovery acceptance."""
import argparse,copy,json
from pathlib import Path
import verify_device_imported as v

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('run',type=Path);run=p.parse_args().run.resolve()
    r=json.loads((run/'receipt.json').read_text())
    v.require(r['status']=='passed'and r['exit_code']==0 and r['test_script']=='tests/max/arrange_packing_recovery_tests.ms','Successful exact-pair packing Max fixture required')
    for k in ('loaded_path_matches','loaded_storage_path_matches','binaries_unchanged','private_ini_matches','artist_profiles_unchanged'):v.require(r[k]is True,'Packing host guard failed: '+k)
    for name in ('verify_packing_recovery.py','verify_device_imported.py','verify_base_support.py','verify_shelves_stairs.py','verify_road_scene.py'):v.require(r['sources']['tools/'+name]==v.sha(Path(__file__).parent/name),'Verifier differs from frozen packing pair')
    cases={};data={};settings={}
    for name in ('packing-original','protected-original','minimum-original','random','obstacle-original'):
        meshes=v.read_meshes(run/(name+'-meshes.txt'));cfg=v.settings(run/(name+'-settings.txt'));data[name]=meshes;settings[name]=cfg
        v.require(cfg['requested']==2,'Authored global quantity was changed')
        if name=='random':v.require(cfg['random']and not cfg['fit']and abs(cfg['scale'][0]-.8)<1e-7 and abs(cfg['scale'][1]-1.1)<1e-7,'Inline random-scale contract changed')
        else:v.require(not cfg['random']and not cfg['fit'],'Original-size case silently enabled scale variation/fit')
        physical=copy.deepcopy(cfg)
        if name=='obstacle-original':
            v.require(len(meshes['output'])==1 and cfg['obstacles']==1,'Explicit obstacle must leave exactly one actual copy and one unfilled')
            physical['requested']=1 # Prove the actual single output; authored requested=2 stays explicit below.
        result=v.check(meshes,physical,name);result.update(authored_requested=cfg['requested'],expected_unfilled=cfg['requested']-len(meshes['output']));cases[name]=result
    controls=v.negatives(data['packing-original'],settings['packing-original'],'packing-original',front_shift_mm=2000)
    result=dict(status='passed',host_receipt_sha256=v.sha(run/'receipt.json'),cases=cases,negative_controls=controls,exports={n:v.sha(run/(n+'-meshes.txt'))for n in cases},scope='Actual final source/output topology, transforms, uniform scale, foot support, full component-envelope/static collision and output separation. Obstacle case deliberately preserves 2 requested/1 placed/1 unfilled; no claimed full two-copy capacity there.')
    (run/'independent-packing-recovery.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))

if __name__=='__main__':main()
