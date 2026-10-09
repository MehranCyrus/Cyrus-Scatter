"""Write public research receipts from hash-pinned, privately retained evidence."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import subprocess


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream,'sha256').hexdigest()


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--run',type=Path,required=True);args=parser.parse_args()
    root=Path.cwd().resolve();run=args.run.resolve()
    assert run.is_relative_to(root/'build') and run.is_dir(),run
    capture=json.loads((run/'capture.json').read_text(encoding='utf-8-sig'))
    inputs=[]
    for item in capture['inputs']:
        original=Path(item['original']);copied=Path(item['copy'])
        assert digest(original)==digest(copied)==item['sha256'],original
        inputs.append({'path':str(original),'sha256':item['sha256'],'bytes':item['bytes'],'preserved':True})
    for name,sha in capture['sources'].items():assert digest(root/name)==sha,name
    read=lambda name:json.loads((run/name).read_text(encoding='utf-8-sig'))
    binary=[]
    for directory in ['layer-factory-loaded','adapter-layer-selected']:
        with (run/directory/'ledger.tsv').open(encoding='utf-8-sig',newline='') as stream:
            for row in csv.DictReader(stream,delimiter='\t'):
                assert row['completed']=='true' and not row['error'],row
                binary.append({**row,'artifact':directory+'/ledger.tsv'})
    patterns=['chaos-results.json','chaos-twenty-results.json','chaos-paint-results.json','forest-results-corrected.json','capture.json','final-save-program.json','final-close-project.json','cleanup.json','host/valid_*.txt','host/fixed_valid_baseline.tsv','host/fixed_repeat.tsv','host/fixed_add.tsv','host/fixed_restore.tsv','host/fixed_reverse_rebuild_list.tsv','host/fixed_order_restore.tsv','host/fixed_remove_middle.tsv','host/density_*.tsv','host/split_twenty_*.tsv','host/paint_*.tsv','host/paint_*_records.txt','host/forest-converted-contours.txt','host/loaded.tsv','host/max-version.txt','host/vendor-version.txt','host/vendor-fixture.max','*/ledger.tsv']
    artifacts={}
    for pattern in patterns:
        for path in run.glob(pattern):
            artifacts[path.relative_to(run).as_posix()]={'sha256':digest(path),'bytes':path.stat().st_size}
    cleanup=read('cleanup.json');assert cleanup['all_owned_processes_stopped'],cleanup
    output={
        'date':'2026-10-09','scope':'research only; official references, question-selected binary bodies and owned disposable Max tests',
        'run':run.relative_to(root).as_posix(),
        'starting_branch':capture['branch'],'starting_head':capture['head'],
        'ending_branch':subprocess.check_output(['git','branch','--show-current'],text=True).strip(),
        'ending_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
        'installed_inputs':inputs,'inspected_product_sources_preserved':capture['sources'],
        'max_version':(run/'host/max-version.txt').read_text(encoding='utf-8-sig').strip(),
        'vendor_api_versions':(run/'host/vendor-version.txt').read_text(encoding='utf-8-sig').strip(),
        'loaded_modules':(run/'host/loaded.tsv').read_text(encoding='utf-8-sig').splitlines(),
        'targeted_binary_ledger':binary,
        'measurements':{'chaos_three_receivers':read('chaos-results.json'),'chaos_twenty_to_twenty_one':read('chaos-twenty-results.json'),'forest_lite_flat_regions':read('forest-results-corrected.json'),'chaos_artist_authored_paint':read('chaos-paint-results.json')},
        'excluded':['property-only Chaos zero-model fixture','undefined target-list expansion probe','single-callback Chaos update/manual experiments','single-callback twenty-surface exports including hidden/redraw variants','Forest one-based transform exports and initial bitmap zero-output fixture','first click-only Chaos curved attempt as evidence of curved painting'],
        'limitations':['vendor transform text precision; no native IDs','explicit capture evaluates/updates; stable output does not prove cache reuse','coarse single-run call timers exclude setters/queued work; no stage timings, FPS or GPU upload counters','Forest Lite curved/whole-surface restrictions; no qualified exact-total counterpart','Chaos folded/stacked meshes, explicit per-layer receiver picking and paint reorder not qualified','no save/reopen or full Manual/Live scheduling qualification'],
        'cleanup':cleanup,'local_artifacts':artifacts,
        'official_sources':['https://docs.itoosoft.com/forestpack/forest-plugin/areas','https://docs.itoosoft.com/forestpack/forest-plugin/surfaces','https://docs.itoosoft.com/forestpack/lite-and-pro','https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter','https://docs.itoosoft.com/installation/forest-pack-installation-files']
    }
    destination=root/'docs/Vendor_Surface_Paint_Research_2026-10-09/EVIDENCE.json'
    destination.write_text(json.dumps(output,indent=2)+'\n',encoding='utf-8')
    print(f'{destination}: {len(inputs)} installed inputs and {len(capture["sources"])} product sources preserved; {len(artifacts)} local artifacts hashed')


if __name__=='__main__':main()
