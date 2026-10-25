"""Verify the exact native/script/package/owned-host chain and assemble artist delivery."""
from pathlib import Path
import argparse, hashlib, json, shutil, zipfile
ROOT=Path(__file__).resolve().parents[2];PROJECT=ROOT/'CyrusVegetationLab'
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def require(value,message):
    if not value:raise RuntimeError(message)
def read(path):return json.loads(Path(path).read_text(encoding='utf-8-sig'))
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for key in ('build','host','package','output'):parser.add_argument('--'+key,type=Path,required=True)
    args=parser.parse_args();build=args.build.resolve();host=args.host.resolve();pack=args.package.resolve();out=args.output.resolve()
    require(out.is_relative_to(ROOT/'dist'),'Artist delivery belongs under dist/')
    require(not out.exists(),'Choose a fresh artist delivery directory')
    native=read(build/'receipt.json');package=read(pack/'package.json')
    require(native['status']=='complete' and native['host']==2027,'Incomplete or wrong-host build')
    for base,key in [(PROJECT,'source_hashes'),(ROOT,'shared_source_hashes')]:
        for name,expected in native[key].items():require(sha(base/name)==expected,'Changed build input: '+name)
    require('100% tests passed, 0 tests failed out of 39' in (build/'tests.log').read_text(),'Native test result differs')
    for name,expected in native['binaries'].items():require(sha(build/name)==expected,'Native artifact changed: '+name)
    provenance=read(PROJECT/'core/PROVENANCE.json')
    require(sha(PROJECT/'core/include/cyrus_vegetation/prototype_v1.hpp')==provenance['frozen_header_sha256'],'Frozen declaration differs')
    copied=0
    for origin in provenance['origins']:
        require(sha(ROOT/origin['original_archive'])==origin['archive_sha256'],'Original handoff archive changed')
        for item in origin['files']:
            require(sha(PROJECT/item['path'])==item['sha256'],'Copied core differs: '+item['path']);copied+=1
    frozen=ROOT/'docs/research/vegetation-core-handoff'
    for item in read(frozen/'FROZEN-FILES.json')['files']:require(sha(frozen/item['path'])==item['sha256'],'Original frozen packet differs')
    receipts={prefix:read(host/(prefix+'receipt.json')) for prefix in ('','restart-')}
    for prefix,r in receipts.items():
        require(r['status']=='pass' and not r['development'] and not r['normal_profile_modified'],'Unqualified owned host receipt')
        require(r['binaries']==native['binaries'],'Host/build pair differs')
        require(r['script_sha256']==native['source_hashes']['scripts/CyrusVegetationLab.ms'],'Host script differs')
        require(not (host/(prefix+'error.txt')).exists(),'Host error remains')
    rows={row['case']:row['stats'] for row in map(json.loads,(host/'stats.jsonl').read_text().splitlines())}
    require(set(rows)=={'fit_button','cached_reads','moved_stone','blocked_root','rigid_transform','reopened','after_render','21_blades'},'Host cases incomplete')
    for name,s in rows.items():
        require(s['fitted'] and s['root_error_m']<=1e-7 and s['relative_length_error']<=.001 and s['visible_penetration_m']<=1e-5,'Independent delivered-mesh check failed: '+name)
        require(s['queries']<=20000,'Query budget exceeded')
    for field in ('fit_attempts','successful_fits','revision','queries'):
        require(rows['fit_button'][field]==rows['cached_reads'][field],'Cached reads ran or replaced a fit')
    require(rows['blocked_root']['error'] and rows['blocked_root']['successful_fits']==rows['moved_stone']['successful_fits'],'Failure retention counters differ')
    for name in ('reopened','after_render'):require(rows[name]['fit_attempts']==0 and rows[name]['queries']==0,'Cold load/render refitted geometry')
    require(rows['21_blades']['blades']==21 and rows['21_blades']['vertices']==378 and rows['21_blades']['faces']==336,'Maximum patch result differs')
    restarted=read(host/'restart-stats.json');require(restarted['successful_fits']==1 and restarted['fit_attempts']==1 and restarted['visible_penetration_m']<=1e-5,'Installed Fit did not run successfully')
    mzp=pack/'CyrusVegetationLab-0.1.0-Max2027.mzp';require(sha(mzp)==package['package_sha256'],'Package identity changed')
    with zipfile.ZipFile(mzp) as archive:
        require(archive.testzip() is None,'Package CRC failed')
        manifest=json.loads(archive.read('manifest.json'))
        for name,expected in manifest['payload'].items():require(hashlib.sha256(archive.read(name)).hexdigest()==expected,'Package payload changed: '+name)
        require(json.loads(archive.read('native/build-identity.json'))==native,'Packaged native receipt differs')
        for name,expected in native['binaries'].items():require(hashlib.sha256(archive.read('native/'+name)).hexdigest()==expected,'Packaged native pair differs')
    expected_package=host/'package'
    for name,expected in manifest['payload'].items():require(sha(expected_package/name)==expected,'Host installed a different package payload: '+name)
    summary={'product':'CyrusVegetationLab','version':'0.1.0','host':2027,'status':'bounded artist prototype qualified','integrated_into_scatter':False,
        'build':str(build),'host_profile':str(host),'package':str(mzp),'package_sha256':sha(mzp),'binaries':native['binaries'],
        'core_identity':restarted['core'],'copied_core_files_verified':copied,'frozen_packet_files_verified':4,'native_ctest_groups_passed':39,
        'scripted_owned_host':True,'fresh_installed_restart':True,'renderer':'3ds Max 2027 Default Scanline Renderer',
        'normal_profile_modified':False,'artist_installation_performed':False,'physical_ui_input_tested':False,'cases':rows,'installed_restart_stats':restarted,
        'receipts':{(prefix+'receipt.json'):sha(host/(prefix+'receipt.json')) for prefix in receipts},
        'host_bootstrap_sha256':{(prefix+'start.ms'):sha(host/(prefix+'start.ms')) for prefix in receipts},
        'scope_limits':['Prepared tapered ribbons; complete standard Sphere; one static collider','Explicit Fit only; no timeline dynamics or wind','No arbitrary plant/rock mesh authoring or self-collision','No strict aggregate allocator or peak-process-memory qualification','Scanline tested; other renderers and physical mouse interaction unqualified','Full research matrix of 68 cases and eight experiments remains Pending']}
    out.mkdir(parents=True)
    for name in ('CyrusVegetationLab-0.1.0-Max2027.mzp','OpenCyrusVegetationLab.ms','README.md','package.json'):shutil.copy2(pack/name,out/name)
    for name in ('Grass_Stone_Max2027.max','Grass_Stone_Preview.png'):shutil.copy2(host/name,out/name)
    (out/'docs').mkdir();shutil.copy2(PROJECT/'docs/IMPLEMENTATION.md',out/'docs/IMPLEMENTATION.md')
    report=f'''# Cyrus Vegetation Lab 0.1.0 — scoped Max 2027 qualification

Qualified on 24 October 2026 for the bounded artist test described in [README](../README.md). This is an independent native prototype; Scatter remains 0.86.9.2 / schema 59. The original A/B/C evidence and the full research matrix retain their separate status.

## Exact delivery

- Core identity: `{restarted['core']}`.
- MZP SHA-256: `{sha(mzp)}`.
- Native DLX SHA-256: `{native['binaries']['CyrusVegetationLab.dlx']}`.
- Storage DLH SHA-256: `{native['binaries']['CyrusVegetationStorage.dlh']}`.
- Script SHA-256: `{native['source_hashes']['scripts/CyrusVegetationLab.ms']}`.
- Build: `{build}`. Exact commands, selected source hashes and binary hashes are in its `receipt.json`; compiler/dependency logs are retained there.
- Host: `{host}`. Both initial and fresh installed restart receipts passed with exact loaded paths/hashes. The normal Max INI remained byte-identical. No artist installation/restart or artist-scene reset was performed.

## Executed evidence

MSVC 19.38 / C++20 / Release with the matched Max 2027 SDK. Pinned Jolt `1b2e77e3c6c09709e5edc79dc208459b8ff32051`, double world positions, deterministic SSE2 profile, no compute backend. All 613 upstream dependency source/build/license records were checked by configuration. The copied A/B/C provenance ({copied} implementation/support files plus the frozen declaration) and four original packet files were verified again before delivery.

**39/39 native CTest groups passed:** 15 collision, 19 fitter, four delivery groups, and the new lab integration group. The latter exercises 7/21 blades, metre/inch/centimetre/millimetre scale conversion, independent validation after Max-float quantization, planted and locked-root failure controls, immutable predecessor retention, source-preserving reset, bounded save/load, identity rejection and limits.

**Scripted Max 2027 controls passed:** Create Demo; Fit; moving the sphere followed by explicit refit; cached redraw/snapshot reads; blocked-root and blocked-clamp retention; nonuniform sphere and scaled grass rejection; complete-sphere admission; unsupported box rejection; Instance ambiguity rejection; system-unit mismatch retention; rigid group transforms; Reset; Undo/Redo; independent Copy; Bake Mesh with topology/UV/material retention; save/reopen with sphere binding; 21-blade fit. These run actual rollout handlers, not physical mouse input.

Every accepted fit passed independent visible-triangle checking against its copied stone snapshot after conversion to the float coordinates delivered to Max. The delivered host controls measured zero planted-guide root error and zero reported visible penetration. The largest reported relative span-length error was {max(s['relative_length_error'] for s in rows.values()):.9g} (tolerance 0.001). The 21-blade result contains 378 vertices / 336 triangles and used {rows['21_blades']['queries']} public queries (budget 20,000). These are bounded fixture results, not a general performance or arbitrary-scene guarantee.

An actual 900 × 700 Max 2027 Scanline render completed. Save/reopen and renderer reads recorded zero fit attempts and zero collision queries; geometry stayed unchanged. The accompanying preview is that Max render. Other renderers, UI scaling/mouse ergonomics, general assets and presented viewport FPS remain unqualified.

The MZP CRC and every payload hash passed. Its installer was executed only inside the owned profile, followed by a **fresh Max process loading the installed native paths and startup script**. The scene reopened there, Fit ran successfully, the delivered launcher opened and a further scene save passed. Startup hashes both native modules and the script before explicit loading and rejects other already loaded paths. Historical failed development attempts remain under `build/vegetation-lab-host-20261024-*`; the final receipt above supersedes those attempts only for this bounded product.

## Limits and next acceptance

One complete standard Sphere, 1–21 generated tapered ribbons, explicit static fitting. The 15 mm guide envelope conservatively bounds the narrower tip. No arbitrary stone/plant assets, multiple colliders, wind, dynamics or self-collision. Native payload estimates and bounded public queries do not certify aggregate Jolt allocations, catastrophic OOM recovery or process peak memory. The full research matrix still has 68 cases and eight experiments Pending.

Next acceptance is the user's visual/interaction check in Max 2027: install the MZP via Scripting > Run Script, save and restart, run OpenCyrusVegetationLab.ms, create a demo, move the sphere and Fit again. Arbitrary asset preparation and mesh colliders need a subsequent, separately scoped implementation and qualification.
'''
    (PROJECT/'docs/QUALIFICATION.md').write_text(report,encoding='utf-8');(out/'docs/QUALIFICATION.md').write_text(report,encoding='utf-8')
    (PROJECT/'docs/QUALIFICATION.json').write_text(json.dumps(summary,indent=2)+'\n');(out/'docs/QUALIFICATION.json').write_text(json.dumps(summary,indent=2)+'\n')
    summary['delivery_files']={p.relative_to(out).as_posix():sha(p) for p in out.rglob('*') if p.is_file()}
    (out/'delivery.json').write_text(json.dumps(summary,indent=2)+'\n');require(sha(out/mzp.name)==sha(mzp),'Copied delivery archive differs');print(out)
if __name__=='__main__':main()
