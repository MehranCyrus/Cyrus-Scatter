"""Verify experiment receipts, retain producer evidence, and write the scoped report."""
from pathlib import Path
import hashlib,json,math,statistics,shutil
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
HOST=ROOT/'build/vegetation-dense-live-20261024-04';POINTER=ROOT/'build/vegetation-dense-pointer-20261024-01'
BUILD=ROOT/'build/vegetation-dense-probe-20261024-05';PHYSBUILD=ROOT/'build/vegetation-dense-probe-20261024-06'
OUT=ROOT/'dist/CyrusVegetation-Dense-Live-Test-20261024'
def load(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def require(ok,message):
    if not ok:raise RuntimeError(message)
def distribution(values):
    a=sorted(values);return {'median':statistics.median(a),'p95':a[max(0,math.ceil(len(a)*.95)-1)],'min':a[0],'max':a[-1],'samples':len(a)}
def main():
    source=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/Shrubs/A084 - Lavender - 05/model.max'
    catalog=load(ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library/model-catalog.json')
    entry=next(x for x in catalog['entries'] if x['id']=='A084');require(sha(source)==entry['scene_sha256'],'Original source asset changed')
    final=load(HOST/'final.json');physical=load(POINTER/'pointer-final.json');audit=load(HOST/'candidate-audit.json');intrusion=load(POINTER/'original-geometry-intrusion.json')
    require((final['vertices'],final['triangles'])==(577792,832240),'Full geometry changed')
    for folder in (HOST,POINTER):
        receipt=load(folder/'receipt.json');require(receipt['status']=='pass' and not receipt['normal_profile_modified'] and not receipt['development'],'Owned host did not pass')
    for folder in (BUILD,PHYSBUILD):
        receipt=load(folder/'probe-receipt.json');require(receipt['status']=='complete' and sha(folder/'CyrusDenseVegetationProbe.dlx')==receipt['binary_sha256'],'Native producer differs')
        require('100% tests passed, 0 tests failed out of 5' in (folder/'tests.log').read_text(),'Variant tests incomplete')
    require(audit['validation_status']==0 and audit['independent_penetration_m']==0,'Full C candidate audit did not pass')
    require(intrusion['validation_status']==1 and intrusion['independent_penetration_m']>.05,'Original intrusion control failed')
    rows=final['history'];accepted=[r for r in rows if r['accepted']]
    require(len(accepted)==31,'Unexpected sweep/live sample count')
    for r in accepted:require(r['visible_penetration_m']==0 and r['root_mesh_error_m']<1e-7,'Delivered float geometry contact/root failure')
    live=load(HOST/'live.json');unrelated=load(HOST/'unrelated.json');away=load(HOST/'away.json');blocked=load(HOST/'blocked-root.json');unsupported=load(HOST/'unsupported.json')
    require(live['attempts']==unrelated['attempts'] and live['generation']==unrelated['generation'],'Unrelated edits refitted the model')
    require(away['last']['max_vertex_displacement_m']<1e-7,'Moving away did not restore rest shape')
    require(away['generation']==blocked['generation']==unsupported['generation'],'Failure replaced prior generation')
    physical_updates=physical['history'][1:]
    require(physical['attempts']>=4 and physical['successes']>=3,'Physical movement witness incomplete')
    held_captures=sum(bool(r.get('mouse_left_down_at_capture')) for r in physical_updates)
    held_publications=sum(bool(r.get('accepted') and r.get('mouse_left_down_at_publish')) for r in physical_updates)
    phases={k:distribution([r[k] for r in accepted]) for k in ('guide_ms','deform_ms','triangle_check_ms','max_mesh_stage_ms','publish_ms','redraw_ms','total_ms')}
    latencies=distribution([r['request_to_redraw_ms'] for r in rows if r['accepted'] and 'request_to_redraw_ms' in r])
    hang=load(ROOT/'build/vegetation-dense-live-20261024-02/hang-observation.json')
    # Preserve exact pre-instrumentation producer source; never rewrite the live source.
    current=(HERE/'probe.cpp').read_bytes()
    before=current.replace(b'auto started=Clock::now();Json row={{"accepted",false},{"error",""},{"mouse_left_down_at_capture",(GetAsyncKeyState(VK_LBUTTON)&0x8000)!=0},\n        {"monotonic_capture_ms",std::chrono::duration<double,std::milli>(started.time_since_epoch()).count()}};',b'auto started=Clock::now();Json row={{"accepted",false},{"error",""}};').replace(b'row["accepted"]=true;row["mouse_left_down_at_publish"]=(GetAsyncKeyState(VK_LBUTTON)&0x8000)!=0;',b'row["accepted"]=true;')
    expected=load(BUILD/'probe-receipt.json')['sources'][str((HERE/'probe.cpp').relative_to(ROOT))]
    require(hashlib.sha256(before).hexdigest()==expected,'Producer source reconstruction differs')
    snapshot=BUILD/'source-snapshot';snapshot.mkdir(exist_ok=True);(snapshot/'probe.cpp').write_bytes(before)
    max_strain=max(r['max_edge_relative_change'] for r in accepted);max_fraction=max(r['fraction_face_edges_over_10pct'] for r in accepted);min_gap=min(r['min_surface_gap_m'] for r in accepted)
    summary={'scope':'Private dense-model experiment, not CyrusScatter integration or a product delivery','host_year':2027,'source':entry,'source_path':str(source),'source_sha256_verified':sha(source),
        'vertices':final['vertices'],'triangles':final['triangles'],'guides':1,'guide_nodes':9,'prepared_base_plane_anchor_vertices':final['base_anchors'],'preparation_ms':final['preparation_ms'],
        'cold_control':final['cold_control'],'original_quadratic_failure':hang,'phases_ms':phases,'automatic_movement_latency_ms':latencies,'accepted_updates':len(accepted),'native_attempts':final['attempts'],
        'min_visible_surface_gap_m':min_gap,'max_face_edge_relative_change':max_strain,'max_fraction_face_edges_over_10_percent_change':max_fraction,
        'actual_rest_mesh_intrusion_m':intrusion['independent_penetration_m'],'full_independent_candidate_audit':audit,'physical_updates':physical_updates,'mouse_held_captures':held_captures,'mouse_held_publications':held_publications,
        'continuous_mouse_held_drag_qualified':False,'presented_fps_measured':False,'material_preview':'Plain two-sided material; regenerated geometric normals; not Corona/opacity qualification',
        'source_asset_unchanged':True,'scatter_sources_changed':False,'qualified_lab_010_native_sources_changed':False,'new_product_installer_created':False,'original_research_matrix_status':'68 cases and eight experiments remain Pending',
        'artifacts':{'automated_host':str(HOST),'pointer_host':str(POINTER),'native_build':str(BUILD),'pointer_native_build':str(PHYSBUILD)},
        'native_binaries':{folder.name:sha(folder/'CyrusDenseVegetationProbe.dlx') for folder in (BUILD,PHYSBUILD)},
        'producer_source_snapshot_sha256':hashlib.sha256(before).hexdigest()}
    OUT.mkdir(parents=True,exist_ok=False)
    for name in ('Rest.png','Bent.png'):shutil.copy2(HOST/name,OUT/name)
    for name in ('sweep.tsv','memory.tsv','cold-control.json','candidate-audit.json','final.json'):shutil.copy2(HOST/name,OUT/name)
    shutil.copy2(POINTER/'pointer-final.json',OUT/'pointer-final.json');shutil.copy2(POINTER/'original-geometry-intrusion.json',OUT/'original-geometry-intrusion.json')
    phase_rows='\n'.join(f'| {label} | {phases[key]["median"]:.3f} | {phases[key]["p95"]:.3f} |' for key,label in [('guide_ms','Jolt world + 9-node guide fit'),('deform_ms','577,792-vertex deformation / float conversion'),('triangle_check_ms','832,240-triangle contact + edge-strain check'),('max_mesh_stage_ms','Max mesh copy / staging / bounds'),('publish_ms','Max output-object publication'),('redraw_ms','Redraw request, deferred'),('total_ms','Total native update')])
    report=f'''# Dense lavender / moving sphere — Max 2027 experiment

24 October 2026. **Result: dense geometry can react automatically, but this whole-clump preparation and full-resolution update path are not ready for fluid, natural Scatter interaction.** The core fit is cheap; source admission, dense deformation/verification, per-instance delivery and botanical preparation are the significant work.

This is a private experiment. CyrusScatter and the qualified Vegetation Lab 0.1.0 native/script pair are unchanged. No new production feature, installer, renderer support or research-matrix acceptance is claimed.

## Asset and controls

Selected the existing **A084 — Lavender 05**, after inspecting six real flower/grass/lavender models. It has **577,792 vertices / 832,240 triangles**, height {final['height_m']:.4f} m, and one combined geometry node. No subdivision, decimation or replacement primitive was used. The original file remains unchanged; SHA-256 `{sha(source)}`. See the [catalog source]({source.as_posix()}). Inventory: `build/vegetation-dense-inventory-20261024-01/inventory.tsv`.

The experiment bound all source vertices to one nine-node clamped guide, preserving topology, UV map topology and face material IDs in the copied mesh. It prepares immutable rest data once and always computes from that rest state. This deliberately coarse whole-clump mapping has only **{final['base_anchors']} vertex at the minimum-Z anchor plane**; it is not a rig defining every individual stem root. Source material/normal fidelity is not qualified: witnesses use a plain two-sided material and regenerated geometric normals.

The moving sphere has radius 0.1672 m, initially moves across the upper canopy, and requests 1 mm clearance. A separate 0.1 mm solver guard covers the bounded float conversion. The sphere is a moving contact probe, not a falling rigid body or a ground-settling test.

## A scaling failure found before bending

The original C render-ID uniqueness check is a nested loop in `CyrusVegetationLab/core/delivery/src/geometry.hpp`. For this asset it performs up to **{int(hang['pair_comparisons']):,} ID comparisons**. The first owned Max attempt remained inside cold admission for at least **{hang['elapsed_since_prepare_seconds']:.1f} seconds**, was unresponsive, and was stopped using only its verified owned PID. Source inspection explains the quadratic scaling. Failure evidence remains at `build/vegetation-dense-live-20261024-02/hang-observation.json`.

An **experiment-only**, hash-pinned variant replaces that check with sorting a copied ID vector and checking adjacent duplicates. Original reviewed C sources stay untouched. The new ID buffer is 4,622,336 bytes for this asset (at most 16 MB in the private 2M-vertex profile); it is additional scratch, not a whole-process cap. A standalone execution admitted 577,792 IDs in about 15 ms. The original four C test groups plus a new large-ID/late-duplicate/zero-ID/order control passed **5/5 groups**, separately in the automated and pointer builds.

With the variant, preparation took **{final['preparation_ms']:.1f} ms**. Full cold C realization took {final['cold_control']['evaluate_ms']:.1f} ms and independent rest validation {final['cold_control']['validate_ms']:.1f} ms. Source and binding admission belong in a reusable preparation cache, rather than being repeated for each drag sample.

## Full-resolution automatic movement

A native 16 ms main-thread timer observes the sphere pose and coalesces unchanged input. Seventeen direct poses and twelve event-loop-driven sphere movements were exercised. The latter issued no Fit/Update command inside their movement loop. The final run published **{len(accepted)} complete successors** across sweep/live/away/restore controls. Every published float mesh passed the probe's whole-triangle sphere check and minimum-Z anchor check before its output object was replaced.

| Phase | Median ms | P95 ms |
| --- | ---: | ---: |
{phase_rows}

The CPU update median corresponds to at most **{1000/phases['total_ms']['median']:.1f} updates/s before presentation costs**. This is **not presented FPS**. The redraw call is deferred and does not time actual GPU upload, draw completion or monitor presentation. Automatic request-to-redraw-request latency: median {latencies['median']:.1f} ms, P95 {latencies['p95']:.1f} ms; maximum {latencies['max']:.1f} ms. No 30/60 FPS claim is supported.

Source preparation count remained one. Unrelated box movement left attempts and generation unchanged. Moving the sphere away restored the rest geometry to within {away['last']['max_vertex_displacement_m']:.3g} m. Blocked-root and unsupported-scale controls retained the previous generation. The prototype still processes a whole mesh on changed sphere inputs even when the resulting pose is unchanged; broad-phase/pose-equality reuse is a clear missing optimization.

## Contact passes; natural vegetation does not

A separate exact C control found **{intrusion['independent_penetration_m']*1000:.1f} mm penetration** in the original unbent plant at the chosen intrusive sphere pose. The bent candidate passed full independent C validation with zero reported penetration, and the cached sampler differed from C's double sampler by only {audit['fast_sampler_difference_m']:.3g} m. The delivered float positions were separately checked by the probe against every triangle.

The first candidate audit correctly returned ResourceLimit: the 40,000 guide-query budget cannot admit 832,240 visible obstacle/triangle pairs. A fresh run used an explicit **{audit['visible_pair_budget']:,} pair audit budget**, separately from the guide's 40,000-query budget, and passed. Raising the declaration does not make those checks inexpensive.

The visible result is too conservative: the smallest accepted surface gap in the tested samples was **{min_gap*1000:.1f} mm** despite a 1 mm target. The guide envelope reaches about 0.554 m radius and moves the entire clump. At the strongest sampled bend, up to **{max_fraction*100:.1f}% of tested face-edge occurrences changed length by more than 10%**, with a maximum relative edge change of {max_strain*100:.1f}%. Edges shorter than 10 micrometres are excluded; shared edges are counted per triangle. This is deformation evidence, not a physical material model. A contact/guide validation pass does not establish botanical realism.

Render witnesses use the same camera and full geometry, with the sphere farther away in Rest and closer in Bent:

![Original shape with sphere farther away]({(OUT/'Rest.png').as_posix()})

![Coarse whole-clump bend with sphere nearer]({(OUT/'Bent.png').as_posix()})

## Physical pointer check

Computer Use targeted only the returned window titled **DVP_OWNED_POINTER_TEST_20261024.max**, in owned Max PID 14412. Three X-gizmo drags were performed. A deeper push at sphere core X ≈0.378 m reached the fitter's 800-iteration limit and retained the previous result. Moving back to X ≈0.581 m converged and visibly bent the plant; moving away to X ≈0.925 m restored its shape. The original source was never edited.

Instrumentation recorded **{held_captures} captures and {held_publications} publications while the left button was down** for those drag-triggered updates. The observed successful updates were captured after release. **Continuous held-drag feedback is therefore unproven**, even though automatic updates after real pointer movement and between scripted pose changes work. The input stroke duration and Max interaction scheduling were not separately profiled, so these observations do not prove that Max intrinsically prevents continuous feedback. An interaction-aware continuous input hook and a longer held-drag witness are still required. Physical accepted updates are listed in `pointer-final.json`; this is not a passing smooth-drag qualification.

## What this means for CyrusScatter

Current source inspection shows why this is more than adding a Collider checkbox:

1. **Preserve placement and source instancing.** `AminScatter/include/point_preview.h` groups shared source triangles with instance matrices. `src/mesh_display.inc` reuses geometry/instance buffers, and `src/point_publication.inc` stages coherent successors. Updating a shared source mesh would bend every copy. Keep those placements/source caches intact and add per-affected-instance deformation state/delivery keyed by stable layer + instance + source revisions.
2. **Add explicit directional roles.** A stone layer supplies collider instances/proxies; a vegetation layer selects those collider layers and owns clearance/stiffness/preparation settings. Existing source-clearance rules govern acceptance/removal and should not silently become deformation rules. Roots and instance identities stay fixed.
3. **Use local active sets and recovery.** Broad-phase queries should consider plant bounds and collider influence, then perform narrow contact tests. Query the union of old/new affected regions so plants recover when the stone leaves. Skip unchanged poses and keep distant plants in the shared source stream. The present probe has only one plant, not a scalable layer spatial index.
4. **Prepare stems and attached parts.** This imported clump has no tested per-stem binding data. Multiple guides, true rooted stem groups and appropriate leaf/flower-head following are needed to avoid treating all branches as a wide tube. Reuse that preparation across instances. This is the strongest visual issue found.
5. **Separate interactive delivery from final quality.** Current 0.86.9.2 evidence distinguishes live Edit gizmo feedback from full mesh commit on release. Its generic Live node callback is batched with mouseUp:true / delay:150. Continuous collider interaction needs a dedicated bounded scheduling/presentation path. First measure a reduced interactive mesh/cage plus full-resolution refinement; only consider a shader deformation path if those measured costs still require it. Renderer/Bake output must consume the same accepted pose at full quality.

The next useful acceptance is one properly prepared multi-stem asset, one stone-layer/plant-layer dependency, a bounded nearby population, old-region recovery, a cheaper interactive representation, and measured updates **during a sustained physical drag**. This test does not authorize or implement that integration.

## Memory, identity and limits

`memory.tsv` samples whole-process Working Set and Private Bytes after load, preparation, cold control, sweep and finish; values include Max, plugins, original/output meshes, rendering and allocator retention. They are not VRAM or an isolated per-instance/peak-memory measurement. For the final run preparation added roughly {(int((HOST/'memory.tsv').read_text().splitlines()[1].split()[2].rstrip('L'))-int((HOST/'memory.tsv').read_text().splitlines()[0].split()[2].rstrip('L')))/1048576:.1f} MiB Private Bytes over the loaded-source sample. Per-tick gesture Undo growth and lifecycle stress remain unqualified.

All execution used **Max 2027**, matched SDK, MSVC Release, the pinned Jolt commit and the separate private DLX. Automated and pointer host receipts verify loaded paths, script/native identity and an unchanged normal Max INI. Other artist windows/profiles were not mutated. Both owned processes quit after their fixtures completed. No integration/version bump/install into the artist profile was performed. Other renderer/material fidelity, multiple plants/stones, true dynamics, long drags, animation seeking and production-memory/Undo gates remain open. The research library's 68 cases and eight experiments retain their original Pending status.

Evidence roots: `{HOST}`, `{POINTER}`, `{BUILD}`, `{PHYSBUILD}`. Full native/core identities, hang observation, sampler/triangle audit, raw timings and pointer records accompany this report. Baked witness scenes are at [bent scene]({(HOST/'Dense_Lavender_Bent_Max2027.max').as_posix()}) and [restored scene]({(HOST/'Dense_Lavender_Restored_Max2027.max').as_posix()}); they are ordinary scene snapshots, not self-installing live systems.
'''
    (HERE/'REPORT.md').write_text(report,encoding='utf-8');(HERE/'REPORT.json').write_text(json.dumps(summary,indent=2)+'\n');(OUT/'REPORT.md').write_text(report,encoding='utf-8');(OUT/'REPORT.json').write_text(json.dumps(summary,indent=2)+'\n')
    summary['delivery_files']={p.relative_to(OUT).as_posix():sha(p) for p in OUT.rglob('*') if p.is_file()};(OUT/'manifest.json').write_text(json.dumps(summary,indent=2)+'\n');print(OUT)
if __name__=='__main__':main()
