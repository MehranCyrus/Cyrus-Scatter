"""Publish the local artist-trial report only after its retained checks pass."""
from pathlib import Path
import hashlib,json,os,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools'))
import build_max

def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def link(label,path):return f'[{label}]({path.as_posix()})'

out=ROOT/'dist/CyrusScatter-0.87.0-20261025-r4'
docs=ROOT/'docs/plans/scatter-interactions-garden-20261025'
payload=ROOT/'build/interactions087-final-payload-20261025-04'
producer=ROOT/'build/interactions087-release-20261025-06/AminScatter'
artist=ROOT/'build/mcp-qualification/interactions087-final-artist-20261025-12'
pointer=ROOT/'build/mcp-qualification/interactions087-pointer-20261025-09'
terraces=ROOT/'build/interactions087-final-terraces-20261025-04'
render=ROOT/'build/interactions087-final-render-20261025-04'
archive=out/'CyrusScatter-0.87.0-Max2027.mzp'
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
receipt=build_max.verify_native_receipt(producer/'receipt.json','AminScatter',2027,{n:payload/n for n in names})
build_max.verify_gallery(producer/'CyrusGallery.dll','0.87.0',2027)
build_max.verify_installer(producer/'CyrusInstaller.dll')
assert '0 tests failed out of 59' in (producer/'tests.log').read_text()
assert '573 passed' in (ROOT/'build/interactions087-pytest-20261025-06.log').read_text()
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.87.0' and manifest['max_year']==2027
    for n,h in manifest['files'].items():assert hashlib.sha256(z.read(n)).hexdigest()==h,n
    assert b'29000' in z.read('install.ms')
    for path in payload.iterdir():
        if path.name in manifest['files']:assert sha(path)==manifest['files'][path.name]
for folder in [artist,terraces,render]:
    identity=read(folder/'loaded-identity.json')
    assert identity['status']=='pass' and identity['host']==2027
    assert read(folder/'completed.json')['status']=='pass'
    for n in names:assert identity['modules'][n]['sha256']==sha(payload/n)
    assert read(folder/'launch.json')['payload_script_sha256']==sha(payload/'CyrusScatter.ms')
for name in ['final-command-undo-redo.json','other-stones.json','saved-trials.json']:
    assert read(artist/name)['status']=='pass'
assert read(artist/'full-scene-reopen.json')['error']==''
summary=read(terraces/'statistics-summary.json')
audit=read(artist/'full-scene-audit-summary.json')
assert summary['status']==audit['status']=='pass'
held=read(pointer/'pointer-first-result.json');assert held['status']=='pass'
assert len((pointer/'pointer-first-frames.tsv').read_text().splitlines())==held['frames']+1
original=ROOT/'Test Scene/Terraces_Final.max'
assert sha(original)=='69ff41356a5312dba7841bc47bbe49b6ce77a8ca79168fd045c8c17c618a8378'
ini=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
assert sha(ini)=='6579ecf2ecd5004b6d4bf955b73fcf91cf5392afda9425da9311d42720d87a2c'
scenes={p.name:{'path':str(p),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted((out/'Trials').glob('*.max'))}
assert set(scenes)=={'Terraces_087_Responsive.max','Terraces_087_Detailed.max'}
evidence=[producer/'receipt.json',producer/'tests.log',terraces/'receipt.json',terraces/'statistics-summary.json',terraces/'moves.tsv',render/'receipt.json',render/'delivery-audit.json',render/'material-bake.json',render/'render-bridge.json',pointer/'pointer-first-result.json',pointer/'pointer-first-frames.tsv',artist/'loaded-identity.json',artist/'final-command-undo-redo.json',artist/'other-stones.json',artist/'saved-trials.json',artist/'full-scene-reopen.json',artist/'full-scene-audit-summary.json',artist/'full-scene-audit.json']
helper=Path(__file__).with_name('select_trial_stone.ms')
helper_result=(artist/'dev-result.txt').read_text(encoding='utf-8-sig')
assert helper_result.startswith('SUCCESS ')
helper_request=Path(helper_result.removeprefix('SUCCESS ').strip())
assert helper.read_text(encoding='utf-8').strip() in helper_request.read_text(encoding='utf-8-sig')
qualification={'status':'scoped_artist_trial','version':'0.87.0','saved_schema':60,'host':2027,
    'archive':{'path':str(archive),'sha256':sha(archive)},'payload':{n:sha(payload/n) for n in manifest['files'] if (payload/n).is_file()},
    'producer_input_manifest_sha256':receipt['input_manifest_sha256'],'native_tests':59,'python_tests':573,
    'terraces':summary,'full_scene_audit':audit,'held_pointer':held,'physical_undo_redo':'Inconclusive in final pointer run 09: Redo assertion failed and Computer Use subsequently reported manual input. Preserve the failed attempt; do not claim it was a proven plugin defect or that it was fixed. The separate final command Undo/Redo passes.',
    'scenes':scenes,'trial_helper':{'sha256':sha(helper),'request':str(helper_request),'result':'pass','scope':'Actual Max 2027 supplied-scene stone selection helper; source guard and selected stone scope.'},'original_scene_sha256':sha(original),'artist_ini_sha256':sha(ini),'artist_installed_or_restarted':False,
    'installer_scope':'Archive integrity/guards/hashes and exact extracted-payload host qualification. Installer handlers were not executed in an artist or disposable installation profile for this version.',
    'evidence':{str(p.relative_to(ROOT)):sha(p) for p in evidence},
    'remaining_artist_checks':['Physical Undo/Redo without concurrent input','Bending feel and gap at stronger contact','Other plant topologies and production materials/renderers','Long-session, animation seek/rescale and broader fault/soak coverage']}
(docs/'QUALIFICATION_0870.json').write_text(json.dumps(qualification,indent=2)+'\n')
table='\n'.join(f"| {r['plants']:,} | {r['update_seconds']:.3f} | {r['command_median_ms']:.2f} / {r['command_worst_ms']:.2f} | {r['fit_median_ms']:.2f} | {r['preview_median_ms']:.2f} | {r['redraw_median_ms']:.2f} | {r['affected_min_max'][0]}–{r['affected_min_max'][1]} |" for r in summary['tiers'])
bake=summary['delivery_audit']
report=f'''# CyrusScatter 0.87.0 — Max 2027 Interactions trial

25 October 2026. Scoped artist-test delivery. The integrated layer contact workflow is implemented; production-wide qualification remains separate. Original Paint, Cyrus Edit storage 2 and the independently versioned Analyzer/content remain in place. No artist installation, restart, Git commit or push was performed.

## Files and installation

- {link('Max 2027 installer',archive)} — run through **Scripting > Run Script**, follow its result, then restart Max. This version has no new Max 2024/2026 package or combined EXE. Existing library content is reused.
- {link('Detailed trial scene',out/'Trials/Terraces_087_Detailed.max')} — 20M idle / 10M navigation face limits; recommended for inspecting the rigid tree and foliage.
- {link('Responsive trial scene',out/'Trials/Terraces_087_Responsive.max')} — 8M / 5M; display limits can substitute boxes. Both scenes have the same placements and 5% leaf/blade preparation.
- {link('Select test stone helper',out/'Trials/Select_Test_Stone.ms')} — run after opening the supplied scene to select the hero and restrict Edit markers to the three stones. It does not open or discard a scene; it was executed successfully in final artist session 12.
- {link('Artist workflow',docs/'ARTIST_GUIDE_0870.md')}, {link('execution and issue history',docs/'EXECUTION_0870.md')}, {link('machine-readable qualification and scene hashes',docs/'QUALIFICATION_0870.json')}.

Installer SHA-256: `{sha(archive)}`. Producer 06 uses the Max 2027 SDK, Release/MSVC 19.38, Ninja, verified compiler dependency closure and no development fault injection. All four native modules, generated script and 0.87.0 managed Gallery/Installer payloads are bound by package hashes. Archive integrity/version/host guards pass. Actual installer handlers and fresh installed startup were not repeated for 0.87.0; exact extracted bytes were host-tested. Never mix a loose script with older native modules.

## What works

The **Interactions** panel gives each layer a clear **Collider** or **React to colliders** role. Analyze, review and accept each source's inferred roots/branches; instances share its rest rig while keeping independent compact poses. Closed rock meshes use native triangle queries. The broad phase includes plant reach and old/new stone neighborhoods; it restores departing plants. Covered rooted groups are reversibly hidden while placement identities remain stored. Search bounds, root coverage and visible contact gap are separate.

Native C++ owns preparation, geometry/index storage, bounded contact fitting, pose lifetimes and sparse preview data. Workers consume copied numeric data; host access and publication stay on the host thread. Complete successors replace previous complete results. Pending Manual counts/seeds wait for Update scatter. One unshared Cyrus Edit modifier per controller is admitted. This is static rooted contact, with a validated fast rotation fit and iterative fallback; it adds no wind or inertial simulation and does not load a Jolt runtime.

The artist trial has **12,416 reacting plants, ten rigid trees and three stones**. Eight plant populations reuse four prepared assets: small grass, bushy grass, lavender and geranium. The supplied boulder component is reused at three sizes. The original terrace architecture is retained; the old static foreground rock is hidden in the derived scenes. Source materials use diagnostic colours. This is an interaction fixture rather than a finished landscape render.

## Measured performance

The exact package repeated eight individual native Cyrus Edit stone commands at each tier. Every contact generation advanced; placement epoch/build counts stayed unchanged. These are CPU command times and synchronous redraw samples, **not presented FPS**. The terrace campaign ran separately from our native builds, audits and other Max qualification hosts. Local density differs between tiers, so this is not an equal-density scaling benchmark.

| Reacting plants | Whole Update (s) | Move median / worst (ms) | Fit median (ms) | Preview median (ms) | Redraw median (ms) | Affected plants |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
{table}

Sampled private process memory was {min(r['initial_private_bytes'] for r in summary['tiers'])/1e9:.2f}–{max(r['initial_private_bytes'] for r in summary['tiers'])/1e9:.2f} GB decimal, including the original scene, source meshes, Max and plug-ins. This is not complete GPU/global allocation or transient peak accounting. The same fixed numeric replay improved from build 31's 1,021.9 ms median move to build 50's 59.00 ms (worst 68.36 ms); initial fit decreased from 1,972.6 to 74.15 ms. The execution log records intermediate failures and causal changes. Different regenerated scene layouts are not used as a controlled before/after comparison.

## Correctness and interaction evidence

- **59/59 native tests** and **573 Python tests** pass. Generated checks account for 347 controls, 13 panels and 37 feature IDs; layout checks pass. Offline passes alone do not establish Max behavior.
- Exact payload render/lifecycle run 04 passes roles/gap restaging, edits made while Collider is off, deletion/Undo, pending Manual preservation, save/reopen, PFlow separation, owner hide/unhide and an actual Scanline render of private posed outputs. The actual world-SI-float Bake audit checks **{bake['triangles']:,} triangles**, zero penetration/touching pairs, minimum surface gap **{bake['minimum_surface_gap_m']*1000:.5f} mm**. Test material IDs 1/2/3 and source UV values are retained. This does not qualify all renderers, production shaders or every pose.
- Exact payload pointer run 09's first archived gesture passes **{held['frames']} observed frames**, with a held contact successor, renderer-committed stone feedback and the actual Max gizmo matching before release. Later pointer/Undo checks are inconclusive: a Redo assertion failed and Computer Use reported manual input. These attempts remain retained; neither a confirmed plugin cause nor a completed physical Redo repair is claimed. Historical run 08 belongs to the earlier withdrawn package.
- Separate final artist run 12 passes a hero stone command with native Undo/Redo and a pending 10,011 amount retaining 10,000 placements. Both smaller stone rows move independently, other stone transforms stay fixed, and Undo restores them. Both trial copies are saved; the detailed scene reopens and rebuilds its own valid contact runtime. Your current test window was left alone.
- The reopened final trial's independent complete-mesh replay checks **{audit['triangles']:,} triangles in {audit['actors']} nearby plants**: zero penetrating vertices, zero touching/crossing triangles, root drift **{audit['root_anchor_error_m']:.3g} m**, maximum rigid-leaf edge change **{audit['maximum_rigid_part_edge_change']:.3g}**, maximum stem-edge change **{audit['maximum_stem_edge_change']*100:.2f}%**. This exhaustive double-precision diagnostic is separate from the actual float Bake check and is not an interactive operation.

## Issues found and fixes

The issue log retains strict witness failures, source/branch admission problems, preview cost, stale Edit restaging, render-output ownership and failed fixtures. Key later fixes were frozen gesture feedback/SDK pointer exception containment, a host-thread GPU-readiness wake so completed geometry can appear during a held drag, and planted tube/frame handling. A full saved-garden audit caught 53.57% lavender basal skin strain despite collision clearance. Preserving a clear first span and aligning the joint frame to its actual averaged tangent reduced that lavender case to 11.60%. A freshly checked flexible-base fit remains available when the fixed span prevents clearance. Earlier packages r1–r3 are withdrawn; their successful subchecks are historical.

## Limits and next artist checks

Preparation currently admits reviewed ordered tube stems and ordered folded blades. Unsupported topology, mirrored/sheared/nonuniform transforms and ambiguous shared/stacked Edit ownership are rejected. Proxies need an explicit source mesh snapshot. New copied Edit instances need Update scatter. Recipe export rejects prepared definitions/active roles rather than dropping their data. Saved schema 60 opens schema 59 with Interactions off; preserve original scenes when upgrading.

Strong bending can still distort stems: the provisional 25% edge-change ceiling is a coarse trial gate, not a biomechanical or natural-bending guarantee. Conservative stem/foliage envelopes can leave extra clearance even at zero gap. Trees in this fixture are rigid. Wind, inertia, plant self-collision, two-way contact, deforming collider meshes and broad animation/seek/rescale/soak coverage remain outside this trial. Source, actor, guide, query, pose and output budgets can reject a successor while retaining the previous complete result.

Please concentrate artist testing on drag feel, gap/root coverage, strong-bend appearance and **physical Undo/Redo without concurrent input**. Test other sources/materials/renderers on copies. The original `Terraces_Final.max` hash remains `{sha(original)}` and the artist INI hash remains unchanged. No website publication or artist-profile installation is implied by these local artifacts.
'''
(docs/'DELIVERY_0870.md').write_text(report,encoding='utf-8')
documentation=out/'Documentation';documentation.mkdir(exist_ok=True)
for name in ['ARTIST_GUIDE_0870.md','DELIVERY_0870.md','EXECUTION_0870.md','QUALIFICATION_0870.json']:
    shutil.copyfile(docs/name,documentation/name)
shutil.copyfile(Path(__file__).with_name('select_trial_stone.ms'),out/'Trials/Select_Test_Stone.ms')
receipts=out/'Evidence';receipts.mkdir(exist_ok=True)
for index,path in enumerate(evidence):shutil.copyfile(path,receipts/f'{index:02d}-{path.name}')
(out/'START_HERE.md').write_text('# CyrusScatter 0.87.0 — Max 2027 trial\n\nRun **CyrusScatter-0.87.0-Max2027.mzp** through **Scripting > Run Script**, follow the result and restart Max. Open **Trials/Terraces_087_Detailed.max** to inspect the tree/foliage, or the Responsive copy for lower drawing limits. Then run **Trials/Select_Test_Stone.ms** through **Scripting > Run Script** to select the hero stone and restrict Edit markers to the three stones.\n\nSee **Documentation/ARTIST_GUIDE_0870.md** for Analyze/review/React controls and **Documentation/DELIVERY_0870.md** for tests, statistics and limits. The final physical Undo/Redo test remains an artist check; the separate command Undo/Redo passed. Original scene preserved; no artist installation or restart performed.\n',encoding='utf-8')
print(json.dumps({'status':qualification['status'],'archive_sha256':sha(archive),'scenes':scenes,'report':str(docs/'DELIVERY_0870.md')},indent=2))
