"""Finalize only review artifacts; never build, install or modify product sources."""
from pathlib import Path
import csv, datetime, hashlib, json, re, zipfile

REPORT = Path(__file__).resolve().parent.parent
ROOT = REPORT.parents[2]
BUILD = ROOT / 'build/full-system-review-08763-20261029-01'
E = REPORT / 'evidence'
identity = json.loads((E / 'identity.json').read_text())
sources = json.loads((E / 'source-hashes.json').read_text())

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def dump(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

def ref(path, symbol, start, end=None):
    return dict(path=path, symbol=symbol, start=start, end=end or start,
                build_sha256=sources[path],
                final_workspace_sha256=sha(ROOT / path),
                matches_tested_source=sha(ROOT / path) == sources[path])

findings = [
 dict(id='FS-01', title='Scene-load staging is never recognized as abandoned',
      subsystem='Library / native Scene preset staging', type=['persistence', 'maintainability'],
      severity='P2', confidence='high', evidence_status='reproduced', origin='preexisting; not introduced by R1-R7',
      trigger='Prepare a Scene preset, then lose its owning process before merge/cancel cleanup; run storage recovery.',
      expected='Remove dead owned staging copies while retaining active or unverifiable directories.',
      actual='No ownership marker is written; recovery retains the abandoned copy as unverified.',
      impact='Disk accumulation on repeated interruptions; supported attachments can be up to 2 GiB each. No published-content loss observed.',
      cause='PrepareScene creates a stage without MarkStage; conservative recovery intentionally retains unmarked folders.',
      references=[ref('AminScatter/shared/SharedLibrary.Scenes.cs','PrepareScene',61,63),
                  ref('AminScatter/shared/SharedLibrary.Management.cs','MarkStage / RecoverStaging',135,147)],
      reproduction=dict(command='python docs/reviews/full-system-08763-20261029-01/drivers/run_supplemental.py',
                        driver='drivers/library_probe.cs',fixture='Disposable store, injected native validator, inert 524288-byte scene; child exits after PrepareScene without DiscardPreparedScene.',
                        evidence=['evidence/library-probe.log','evidence/library-host.json']),
      measurement=dict(marker_written=False,recovered=0,retained=1,retained_bytes=524288),
      limits='Reproduces file ownership lifecycle, not an actual Max crash. Real native Scene save/merge is independently covered.',
      minimal_repair='Call existing MarkStage immediately after creating the load stage within cleanup-protected scope.',
      ownership_and_invalidation='Stage owned by PID plus process-start identity; no scene schema, placement or catalog invalidation change.',
      risk='Low if marker-write failure cleans only the private stage; never broaden deletion to unknown folders.',
      acceptance=['Dead child stage recovered','Live child and unmarked foreign directory retained','Normal merge/cancel cleanup works','Twenty interrupted cycles leave no owned copies and preserve published hashes']),
 dict(id='FS-02', title='Saved provenance and licensing guidance identify obsolete versions',
      subsystem='Scene writer / licensing UI',type=['usability','maintainability'],severity='P3',confidence='high',
      evidence_status='reproduced', component_status={'scene_metadata':'reproduced in managed and actual Max', 'licensing_strings':'statically demonstrated'},
      origin='preexisting',trigger='Save a Scene preset or open licensing guidance in the tested 0.87.6.3 build.',
      expected='Current verified writer identity or deliberately version-neutral guidance.',
      actual='New Scene metadata says 0.87.5.5; licensing text says 0.80.0.',
      impact='Misleading support/provenance. No incompatible-load failure demonstrated; metadata currently validates as text.',
      cause='Hardcoded product versions independent of verified build identity.',
      references=[ref('AminScatter/shared/SharedLibrary.Scenes.cs','SaveScene metadata',44,46),
                  ref('AminScatter/tools/ui/templates/licensing.ms','dialog / missing-native guidance',3,22),
                  ref('AminScatter/include/scene_preset.h','metadata validation',20)],
      reproduction=dict(driver='drivers/host_library.py',command='Use the private Max 2027 launcher sequence in 06_TEST_REPORT.md; host_library.py saves and reads the manifest.',
                        evidence=['evidence/library-host.json','evidence/library-probe.log']),
      minimal_repair='Pass verified writer identity through an existing bounded interface; share it or remove unnecessary release wording from licensing messages.',
      ownership_and_invalidation='Product build metadata, not independent licensing-foundation version; keep historical preset provenance unchanged.',
      risk='Low. Avoid changing schema/host compatibility rules or rewriting old metadata.',
      acceptance=['New metadata equals loaded version','Old presets still load under existing rules','Generator/script/package identities agree','No obsolete package guidance']),
 dict(id='OPT-01',title='Local interactions still copy and scan retained state',subsystem='Native interaction snapshots',
      type=['performance'],severity='P2',confidence='high',evidence_status='measured opportunity',
      origin='preexisting; consolidates previous global-bookkeeping observation, not a new correctness regression',
      trigger='Move one collider slightly while all distant plants already have retained poses.',
      expected='Optimization goal: unchanged pose/obstacle metadata reused where justified, local work remains local.',
      actual='One affected plant / two contact queries; total time and allocation grow with retained population.',
      impact='Avoidable CPU/allocation pressure; not established as the dominant artist frame cost.',
      cause='Copies retained pose/count/warning containers, rebuilds worldObstacles, rescans pose statistics and reuse.',
      references=[ref('AminScatter/src/interactions_engine.cpp','snapshot successor / worldObstacles',156,163),
                  ref('AminScatter/src/interactions_engine.cpp','retained statistics / reuse',285,298)],
      reproduction=dict(command='python docs/reviews/full-system-08763-20261029-01/drivers/run_native_probe.py --benchmark',
                        driver='drivers/extra_probe.cpp',fixture='local-posed; SI units; one warm-up, eight ordinary samples, separate allocation sample; fixed input.',
                        evidence=['evidence/benchmark.csv','evidence/benchmark-summary.json']),
      measurement=[dict(posed_plants=128,separate_colliders=128,median_ms=.0287,allocations=208,cumulative_bytes=27547),
                   dict(posed_plants=1024,separate_colliders=1024,median_ms=.1457,allocations=1104,cumulative_bytes=192450),
                   dict(posed_plants=8192,separate_colliders=8192,median_ms=1.36645,allocations=8272,cumulative_bytes=1511362,instrumented_fit_ms=.0142)],
      limits='Both posed plants and obstacles grow. Ordinary new allocation traffic is not peak RSS/VRAM. Timings exclude instrumented sample; no matched optimized implementation exists.',
      minimal_repair='First reuse unchanged obstacle slots and maintain statistic deltas; consider shared/chunked pose metadata only after remeasurement.',
      ownership_and_invalidation='Immutable previous snapshots, deterministic merge order and complete failure rollback remain required.',
      risk='Medium; stale metadata or mutation of old snapshots can corrupt preview/render/Undo ownership.',
      acceptance=['Equivalent full recomputation including disable/restore','At least 50 percent less cumulative allocation in 8192 fixture','No small-batch regression','Unchanged evaluation returns prior snapshot','Measure real garden separately']),
 dict(id='GAP-01',title='Pose-payload ceiling does not qualify construction peak',subsystem='Interaction resource admission',
      type=['test gap'],severity='P2',confidence='high about boundary; failure frequency unknown',evidence_status='statically demonstrated',
      origin='open in previous review; not new',trigger='Unusually heavy prepared plants and contact populations produce many simultaneous successor poses.',
      expected='Account for old/new/result/scratch lifetimes and retain previous complete result on predictable admission failure.',
      actual='256 MiB aggregate pose payload is checked after per-job construction and merge; other generations and scratch have separate lifetimes.',
      impact='Construction peak may exceed payload limit. No OOM, leak or crash reproduced in this review.',
      cause='A result-payload guard is not a pre-allocation process-memory reservation.',
      references=[ref('AminScatter/src/interactions_engine.cpp','worker results / merge / payload check',253,298)],
      reproduction=dict(method='Static reachable path: results construction, successor merge with old snapshot retained, aggregate guard.',
                        evidence=['03_PERFORMANCE.md','evidence/native-tests.log']),
      minimal_repair='Instrument exact lifetimes, then add predictable reservations and controlled allocation-failure tests in an isolated build.',
      ownership_and_invalidation='Separate CPU old/new/scratch/render and GPU owners; preserve last complete publication.',
      risk='Medium; overconservative admission can reject valid work; do not silently reduce authored Count or merely raise limits.',
      acceptance=['Bounded repeated-edit soak','Injected allocation rejection retains previous complete result','Report peak and cumulative memory separately','Modest scene output and latency unchanged'])
]

closure_descriptions = {
 'R1':'Off/Collider/React transitions no longer require a missing neighbor rig; native and five Max transitions pass.',
 'R2':'All four responses with Inside margin and Under reach pass; incremental movement/restore matrix passes.',
 'R3':'Overrides borrowed and indices built once; 1024-neighbor allocation witness is 39856 calls / 1358775 bytes.',
 'R4':'Shared draw-aware admission and five bounded host limits pass; extreme memory/device-loss cases remain unqualified.',
 'R5':'Mixed fixture retains eight fixed vertices and twelve fixed triangles; CPU/compact math agrees.',
 'R6':'Numerical envelope contains distant fixed geometry; small render succeeds but is not the entire distant-fixed fixture.',
 'R7':'One patch into one million rows uses 208 tracked bytes; 500 cumulative edits/select/compact/receipt cases pass.'}
dump(REPORT/'findings.json', dict(schema='cyrus.independent-review-findings/1',product='Cyrus Scatter',version='0.87.6.3',
     max_year=2027,build_identity=identity,source_manifest='evidence/source-hashes.json',
     findings=findings,previous_findings=[dict(id=k,evidence_status='already fixed/not applicable',scope='Recorded tested snapshot only',conclusion=v) for k,v in closure_descriptions.items()]))

# Strict artifact checks before packaging. Actual grants, private key fixtures,
# models and compiled outputs belong outside this directory and are forbidden.
required=[f'{n:02}_{name}.md' for n,name in enumerate(['SUMMARY','FINDINGS','COVERAGE','PERFORMANCE','LIBRARY_AND_RECIPES','LICENSING_AND_SECURITY','TEST_REPORT','RECOMMENDED_SEQUENCE'])]+['findings.json','coverage.csv','REVIEW_BRIEF.txt']
for name in required:
    assert (REPORT/name).is_file(), name
for path in REPORT.glob('*.md'):
    for link in re.findall(r'\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
        target=link.split('#')[0].strip('<>')
        if target and not re.match(r'^[a-z]+:',target):
            assert (path.parent/target).exists(), (path.name,target)
rows=list(csv.DictReader((REPORT/'coverage.csv').open(encoding='utf-8-sig')))
assert len(rows)==555
assert len(sources)==638
assert not identity['fresh_vs_qualified_source_differences']
assert all(r['matches_tested_source'] for f in findings for r in f['references']), 'A finding source changed: revise applicability before publishing'

for name in ('native-regression.json','host-receipt.json','library-host-receipt.json','garden-host-receipt.json','render-host-receipt.json'):
    assert (E/name).is_file(), name
for p in REPORT.rglob('*.py'):
    compile(p.read_text(encoding='utf-8-sig'),str(p),'exec')

forbidden={'.max','.dll','.dlx','.lib','.exe','.obj','.pdb','.test-license','.license','.cyruslicense','.key','.pem','.pfx','.zip'}
files=sorted(p for p in REPORT.rglob('*') if p.is_file() and '__pycache__' not in p.parts and p.name!='manifest.json')
for p in files:
    assert p.suffix.lower() not in forbidden, p
    assert 'synthetic-license-fixtures' not in p.parts, p
    if p.suffix in ('.txt','.log','.json','.md','.csv','.xml'):
        text=p.read_text(encoding='utf-8-sig',errors='replace')
        assert not re.search(r'-----BEGIN (?:EC |RSA )?PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{30,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}',text), 'Potential secret payload: '+str(p)

manifest=dict(schema='cyrus.review-bundle/1',created_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
              qualification_scope=identity['qualification_scope'],product_source_modified=False,
              files={p.relative_to(REPORT).as_posix():dict(sha256=sha(p),bytes=p.stat().st_size) for p in files},
              excludes='Manifest self-hash; __pycache__; binaries; scenes; actual grant/request/key fixtures; unrelated diffs. ZIP hash is stored separately.')
dump(REPORT/'manifest.json',manifest)
archive=BUILD/'CyrusScatter-0.87.6.3-Full-System-Review-20261029.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in files+[REPORT/'manifest.json']:
        z.write(p,p.relative_to(REPORT).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
    assert all(hashlib.sha256(z.read(name)).hexdigest()==entry['sha256'] for name,entry in manifest['files'].items())
receipt=dict(path=str(archive),sha256=sha(archive),bytes=archive.stat().st_size,files=len(files)+1,
             archive_integrity=True,all_manifest_hashes=True,concurrent_source_changes=len(identity['changed_since_fresh_build']),
             new_defects=['FS-01','FS-02'],measured_opportunities=['OPT-01'],known_qualification_gaps=['GAP-01'])
dump(BUILD/'bundle-receipt.json',receipt)
(BUILD/(archive.name+'.sha256')).write_text(receipt['sha256']+'  '+archive.name+'\n',encoding='utf-8')
print(json.dumps(receipt,indent=2))
