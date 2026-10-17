"""Freeze internal N02 component evidence; never marks the full roadmap done."""
from pathlib import Path
import hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2]
RUN=ROOT/'build/native-foundation-0860-20261017-01'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def evidence(path):return {'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}
def main():
    native=RUN/'store-native-03';receipt=json.loads((native/'receipt.json').read_text())
    assert receipt['max_year']==2027 and not receipt['preview_fault_lab']
    assert all(s['exit_code']==0 for s in receipt['stages'])
    for path,expected in receipt['sources'].items():assert sha(ROOT/path)==expected,path
    host=ROOT/'build/mcp-qualification/foundation-memory0854-nativestore-20261017-04'
    launch=json.loads((host/'launch.json').read_text())
    assert launch['max_year']==2027 and launch['normal_profile_modified'] is False
    assert not (host/'startup-error.txt').exists() and (host/'ready.json').exists()
    for phase in ['construct','retain','release']:
        text=(host/f'native-store-{phase}.txt').read_text(encoding='utf-8-sig')
        assert 'PASS: complete' in text and 'FAIL:' not in text
    assert 'CORE PASSED' in (RUN/'store-regression.log').read_text(encoding='utf-8-sig')
    assert 'ALL EIGHT PRESETS PASSED' in (RUN/'store-preset-regression.log').read_text(encoding='utf-8-sig')
    assert '167 passed' in (RUN/'foundation-python.log').read_text(encoding='utf-8-sig')
    unchanged=['AminScatter/tools/ui/templates/unified-core.ms','AminScatter/scripts/AminScatterObject.ms',
        'AminScatter/include/surface_filter.h','AminScatter/src/surface_filter.cpp','AminScatter/src/surface_filter_bridge.inc']
    for path in unchanged:
        prior=subprocess.check_output(['git','show','7379ea3:'+path],cwd=ROOT)
        assert hashlib.sha256(prior).hexdigest()==sha(ROOT/path),path
    receipts=[native/'receipt.json',native/'tests.log',host/'launch.json',host/'loaded.tsv',
        *[host/f'native-store-{p}.txt' for p in ['construct','retain','release']],
        RUN/'store-host-04.log',host/'closure-observation.json',RUN/'store-regression.log',RUN/'store-preset-regression.log',
        RUN/'foundation-python.log',RUN/'foundation-final-generated.log',
        RUN/'store-native-01-startup-minidump.dmp',RUN/'startup-dump-summary.json',
        RUN/'N02-native02-qualification.json',RUN/'store-core-03/2.log']
    assert json.loads((host/'closure-observation.json').read_text())['exited'] is True
    result={'status':'internal N02 component passes; not a product delivery or N01-N09 completion',
        'date':'2026-10-17','target_delivery':'0.86.0','source_version':'0.85.4','schema':58,'max_year':2027,
        'baseline_implementation_checkpoint':'7379ea36240011808955991ddc07e3d35fd894e6',
        'native_receipt':evidence(native/'receipt.json'),'source_hashes':receipt['sources'],
        'native_binary_hashes':receipt['binaries'],'current_host':evidence(host/'launch.json'),
        'checks':{'native_suites':42,'python_tests':167,'generated':'passed',
            'native_core':'immutable layout, tokens, exact IDs, source use, bounded pages, release, allocation failures/retry, concurrent producer/worker pins',
            'actual_max_current_pair':'raw/edited full-field round trips, detached pages, wrong type/token, flat selection/compaction, GC and owning-module Brush lease reads/release',
            'actual_max_preceding_prototype_pair':'existing core and all eight ready preset Load/Undo/Redo/save/reopen; store-native-01 / nativestore-20261017-02'},
        'limits':['Main placement pipeline still uses existing arrays; no active-pipeline speedup claim.',
            'N01 stage/scratch/materialization/peak/history attribution and hold probes remain open.',
            'N02 controller retirement, complete native semantic fingerprint and integrated full memory accounting remain open.',
            'Native counters cover placement-owned vector requests, not allocator/shared_ptr headers or interning-map/string scratch.',
            'One private startup failed before tests; same pair retried successfully. Raw dump stack pointers are not a causal unwind. Broader startup qualification remains open.',
            'No physical input, production renderer, 60-minute soak, shipping fault-exclusion/package or recipient installation acceptance from this component checkpoint.'],
        'slope_altitude_and_authoritative_ui_unchanged':{path:sha(ROOT/path) for path in unchanged},
        'installer_created':False,'artist_installation':False,'artist_restart':False,
        'evidence':[evidence(path) for path in receipts]}
    out=ROOT/'docs/plans/native-placement/N02_QUALIFICATION.json';out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Recorded internal N02 qualification:',len(receipt['sources']),'matched source inputs; no delivery claimed')
if __name__=='__main__':main()
