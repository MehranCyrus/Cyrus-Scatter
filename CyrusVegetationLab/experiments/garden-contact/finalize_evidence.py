"""Collect exact local investigation evidence and verify preserved inputs/links."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess
ROOT=Path(__file__).resolve().parents[3]
DOC=ROOT/'docs/plans/scatter-interactions-garden-20261025'
BASE=ROOT/'build/garden-baseline-host-20261025-03'
REOPEN=ROOT/'build/garden-reopen-host-20261025-02'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def main():
    for p in [ROOT/'build/garden-assets-host-20261025-01/receipt.json',BASE/'receipt.json',REOPEN/'receipt.json',REOPEN/'loaded-identity.json']:
        assert read(p)['status']=='pass',str(p)
    preserved=[]
    for row in read(DOC/'ROCK_INPUTS.json')+read(Path(__file__).parent/'asset-inputs.json'):
        path=Path(row['path']); path=path if path.is_absolute() else ROOT/path
        assert sha(path)==row['sha256'],'Original input changed: '+str(path)
        preserved.append({'path':str(path),'sha256':sha(path)})
    frozen=ROOT/'CyrusVegetationLab/core/include/cyrus_vegetation/prototype_v1.hpp'
    assert sha(frozen)=='f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f'
    (DOC/'images').mkdir(exist_ok=True)
    shutil.copy2(BASE/'garden-baseline-viewport.png',DOC/'images/garden-baseline-diagnostic.png')
    scene=read(BASE/'scene-report.json'); spatial=read(BASE/'spatial-probe.json'); cold=read(REOPEN/'reopen-report.json')
    names=['Hero stone','Small stones','Small grass','Bushy grass','Lavender','Geranium','Small tree']
    table='\n'.join(f'| {name} | {requested:,} | {accepted:,} |' for name,requested,accepted in zip(names,scene['requested'],scene['counts']))
    text=f'''# Investigation results — exact bounded evidence

25 October 2026. **Existing Scatter baseline and integration plan; no integrated rock-mesh bending was implemented.**

## Final actual scene

![Real Max 2027 diagnostic mesh preview](images/garden-baseline-diagnostic.png)

This is an actual viewport capture using retained Scatter meshes and layer colors. It is not the AI reference, a beauty render or a contact simulation. The slab-like supplied hero stone and conservative projected cover do not reproduce the reference's rounded boulder silhouette or tight contact. Visible clearing beneath an overhang is a known limitation of this static cover approximation.

The scene is [Cyrus_Garden_Baseline_Max2027.max](../../../build/garden-baseline-host-20261025-03/Cyrus_Garden_Baseline_Max2027.max), {((BASE/'Cyrus_Garden_Baseline_Max2027.max').stat().st_size/1048576):.1f} MiB. It uses the exact extracted 0.86.9.2 Max 2027 pair and serialization schema 59. The report's legacy `scatter_version` field contains **schema 59**, not a release number. No new plugin version, installer or artist-profile installation was made.

| Layer | Requested candidates | Accepted |
|---|---:|---:|
{table}
| **Total** | **{sum(scene['requested']):,}** | **{sum(scene['counts']):,}** |

There are {spatial['unique_scene_sources']} distinct scene sources including six small-rock groups. The accepted placements have an expanded source-triangle equivalent of **{spatial['expanded_triangle_equivalent']:,}**. They are shared source instances; this figure is not a measured unique posed-geometry allocation.

Initial procedural evaluation took {scene['initial_placement_seconds']:.3f} s; evaluation after static masks took {scene['masked_placement_seconds']:.3f} s. Initial retained display/complete redraw took {scene['retained_display_seconds']:.3f} s. These are single-run CPU/wall measurements, not interactive FPS or a benchmark distribution. All seven layer preview errors were empty.

Final process snapshot: working set {scene['host_working_set_bytes']/1073741824:.2f} GiB, private bytes {scene['host_private_bytes']/1073741824:.2f} GiB, process peak working set {scene['host_peak_working_set_bytes']/1073741824:.2f} GiB. These include the host and loaded assets; they are not incremental feature allocation or exact total peak RAM/VRAM/history accounting. The placement-record payload alone is {spatial['record_payload_96_bytes']:,} bytes and excludes source meshes, textures, views, renderer, scratch and GPU resources.

## Spatial and footprint diagnostic

The offline probe consumes the actual exported placements. It indexes transformed **rest source AABBs** in 0.4 m grid cells; reachable deformation/swept bounds remain future work.

- {spatial['roots_inside_static_xy_hulls_before']} original plant roots lay inside the static rock XY hulls; the final masked result has **{spatial['roots_inside_static_xy_hulls_after']}**. Candidate rejection/underfill is expected in this fixture; no automatic refill was added.
- All current stone AABBs overlap the source AABBs of **{spatial['current_all_rocks_potentially_affected']} / {spatial['potential_reactor_count']}** plant placements ({spatial['current_all_rocks_potentially_affected_percent']:.1f}%). These are potential contacts, not solved contacts or bent plants.
- All {spatial['motion_samples']} shifted-hero samples exactly match the brute-force AABB overlap set. The script also records old/new union and leaving/restoration sets; no Max collider was animated by this offline test.
- Python grid construction took {spatial['grid_build_ms_python']:.3f} ms; median repeated query {spatial['query_median_ms_python']:.3f} ms; maximum sampled query {spatial['query_max_ms_python']:.3f} ms. This supports the design hypothesis of localized selection. It does not measure native fitting, Max input latency, publication, upload or frame rate.

Raw data: [spatial-probe.json](../../../build/garden-baseline-host-20261025-03/spatial-probe.json), [placements](../../../build/garden-baseline-host-20261025-03/placements.json), [source metrics](../../../build/garden-baseline-host-20261025-03/source-metrics.json), [footprints](../../../build/garden-baseline-host-20261025-03/footprints.json).

## Source preparation intake

Original-source Lavender 01 and Geranium passed the existing preparation executable when given the correct expected 560/22 guide counts (exit 0); logs and emitted metadata are retained under `build/garden-assets-host-20261025-01/`. The initial diagnostics deliberately passed expected count zero and therefore retained nonzero exits even for admissible models. Do not count those diagnostic exits as successful tests.

Both grass sources are outside the round-tube profile. Phlox found 69 guides but 54 unresolved; preparation remains blocked. The tree exceeded 40,000 connected parts. These are concrete source capability gaps, not integration bugs or evidence that the meshes should be deleted. No per-instance preparation cache or garden-wide contact solve was tested here.

## Cold reopen and warm reuse

The final baseline reopened in a fresh Max 2027 profile with exactly equal source ordinals, IDs and transforms. Cold display realization took {cold['cold_display_seconds']:.3f} s. Five ensure/display redraw calls took {', '.join(f'{x:.2f}' for x in cold['warm_ensure_and_redraw_ms'])} ms. Epoch, `procPreparedBuilds` and `previewBuildCount` remained unchanged. Those are existing Scatter placement/display counters, not plant-rig analysis counters. This is read-only reuse evidence, not a held-mouse test.

The final validation preflight enumerated actual loaded process module paths and hashes and checked the loaded script fingerprint before opening the scene. See [loaded identity](../../../build/garden-reopen-host-20261025-02/loaded-identity.json), [reopen result](../../../build/garden-reopen-host-20261025-02/reopen-report.json) and [receipt](../../../build/garden-reopen-host-20261025-02/receipt.json). The source working tree differs from the packaged script; the package scene does not qualify dirty production source edits.

## Earlier attempts retained

1. `garden-baseline-host-20261025-01`: scene composition reached presentation but failed because scripted Targetcamera creation had no target. Corrected by creating an explicit Targetobject. This is a failed fixture attempt.
2. `garden-baseline-host-20261025-02`: saved/rendered and exited zero, but visual inspection caught the footprint generator's omitted source object-offset transform. Its masks, placement totals and 17.8 M triangle figure are superseded by run 03. The full Scanline render completed in 194.6 s but rendered plants black. Sampled private bytes reached 10,602,840,064 bytes during that attempt; this is a sampled observation, not an exact peak. Rendering successfully returning did not qualify material fidelity.
3. `garden-baseline-host-20261025-03`: corrected offset mapping, clear diagnostic layer colors, final saved scene and actual viewport PNG. No beauty render or arbitrary rock contact claim.
4. `garden-reopen-host-20261025-01`: initial successful cold/warm check; repeated as run 02 to add independent loaded-module/script identity preflight. Earlier receipts retain their original hashes/scope.

All completed owned receipts report the original artist INI unchanged. Original asset hashes are rechecked by the evidence collector. No production source/template changes, commit, push, install or artist-session restart were performed by this task. Hash/path/link checks are local artifact checks; broad production test suites were not rerun for this investigation-only change.

## Remaining acceptance

The next work is the source/placement adapter and grass preparation profile, then nearby contact/cover publication and unique pose delivery. Actual mesh-rock fitting, natural tight clearance, strong-bend stem quality, multi-collider interactions, sustained physical dragging, integrated Undo/persistence and final renderer/Bake parity remain unqualified. Follow the phased plan and validation matrix before calling this production integration.
'''
    (DOC/'INVESTIGATION_RESULTS.md').write_text(text,encoding='utf-8')
    for file in DOC.glob('*.md'):
        body=file.read_text(encoding='utf-8')
        body=re.sub(r'\bI([0-6])\b',r'INT\1',body)
        file.write_text(body,encoding='utf-8')
    links=[]
    for file in [*DOC.glob('*.md'),Path(__file__).parent/'README.md']:
        for target in re.findall(r'\]\(([^)]+)\)',file.read_text(encoding='utf-8')):
            if target.startswith(('http:','https:','#')): continue
            path=(file.parent/target.split('#')[0]).resolve()
            assert path.exists(),f'Broken link: {file.name}: {target}'
            links.append({'from':str(file.relative_to(ROOT)),'target':target})
    sources=['AminScatter/tools/ui/templates/unified-core.ms','AminScatter/tools/ui/templates/recipes.ms',
             'AminScatter/include/placement_store.h','AminScatter/include/placement_binding.h','AminScatter/include/placement_publication.h',
             'AminScatter/include/procedural.h','AminScatter/src/source_geometry.inc','AminScatter/src/mesh_display.inc',
             'AminScatter/src/point_publication.inc','AminScatter/src/source_clearance.cpp',
             'CyrusVegetationLab/experiments/stem-live/analysis.cpp','CyrusVegetationLab/experiments/stem-live/preparation_host.inl',
             'CyrusVegetationLab/experiments/stem-live/stem_core.cpp','CyrusVegetationLab/experiments/stem-live/plugin.cpp',
             'CyrusVegetationLab/core/include/cyrus_vegetation/prototype_v1.hpp']
    artifact_paths=[BASE/'Cyrus_Garden_Baseline_Max2027.max',BASE/'receipt.json',BASE/'scene-report.json',BASE/'spatial-probe.json',REOPEN/'loaded-identity.json',REOPEN/'reopen-report.json',REOPEN/'receipt.json']
    result={'status':'pass','scope':'Local investigation artifact/input verification; not production release certification',
            'preserved_inputs':preserved,'frozen_contract_sha256':sha(frozen),'source_sha256':{p:sha(ROOT/p) for p in sources},
            'artifacts':{str(p.relative_to(ROOT)):sha(p) for p in artifact_paths},'local_links_checked':len(links),
            'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
            'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
            'production_mutation_scope':'None; new investigation scripts/docs and ignored owned artifacts only'}
    (DOC/'FINAL_EVIDENCE.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'status':'pass','preserved_input_entries':len(preserved),'links_checked':len(links),'records':sum(scene['counts'])}))
if __name__=='__main__': main()
