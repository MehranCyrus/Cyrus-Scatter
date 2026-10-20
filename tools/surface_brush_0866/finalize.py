"""Deliver only verified local artifacts; never install into an artist profile."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess,sys,re
ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/plans/preset-gallery-improvements';BASE=ROOT/'build/surface-brush-0866-20261019'
p=argparse.ArgumentParser();p.add_argument('package',type=Path);a=p.parse_args();build=a.package.resolve();assert build.is_relative_to(BASE)
read=lambda p:json.loads(p.read_text(encoding='utf-8'));sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
package=read(build/'package-receipt.json');exe=read(build/'exe-receipt.json');qualification=read(DOC/'QUALIFICATION_0866.json')
assert package['status']==exe['status']=='passed' and qualification['version']=='0.86.6'
archive=build/'CyrusScatter-0.86.6-Max2027.mzp';setup=build/'CyrusScatter-0.86.6-Setup.exe'
assert sha(archive)==package['mzp_sha256']==exe['mzp_sha256'] and sha(setup)==exe['exe_sha256']
for name,item in exe['logs'].items():assert sha(build/(name+'-results.txt'))==item['log_sha256']
dest=ROOT/'dist/CyrusScatter-0.86.6-20261019';dest.mkdir(exist_ok=False)
for source in (archive,setup,build/'package-receipt.json',build/'exe-receipt.json',build/'installer-host-receipt.json',setup.with_suffix('.build.json'),DOC/'QUALIFICATION_0866.json',Path(qualification['native_receipt'])):shutil.copy2(source,dest/source.name)
(dest/'SHA256SUMS.txt').write_text('\n'.join(sha(dest/p.name)+'  '+p.name for p in (archive,setup))+'\n')
(dest/'INSTALL.txt').write_text('Cyrus Scatter 0.86.6 — Max 2027 only\n\nRun CyrusScatter-0.86.6-Setup.exe, choose Max 2027 and Install / Repair.\nAlternatively use Scripting > Run Script in Max 2027 and choose the MZP.\nSave your work and restart Max after successful installation.\nThe package includes the complete corrected 0.86.5 library/Amount baseline.\nThe Windows installer is unsigned. Normal Cyrus activation still applies.\nNo Max 2024/2026 compatibility is claimed for this build.\n',encoding='utf-8')
counts={name:int(re.search(r'PASSED (\d+)',(build/(name+'-results.txt')).read_text()).group(1)) for name in exe['logs']}
report=f'''# Cyrus Scatter 0.86.6 — surface painting restored

Delivered for user testing on **19 October 2026**, **Max 2027 only**. The complete
library/Amount reliability feature set is retained under the user-corrected
**0.86.5 baseline**; this brush fix is **0.86.6**. Original 0.87.0 receipts and
artifacts retain their actual labels/hashes. No 0.86.3/0.86.4 qualification is invented.
Scene schema 58, recipe 7 and independent product versions remain unchanged.

## Install and share

- [Windows EXE](../../../dist/CyrusScatter-0.86.6-20261019/{setup.name}): choose Max 2027, then **Install / Repair**.
- [Max 2027 MZP](../../../dist/CyrusScatter-0.86.6-20261019/{archive.name}): **Scripting > Run Script**.

Save work and restart Max after a successful installation. Both contain the exact
qualified script/native pair, library and patterns. The EXE is unsigned and normal
Cyrus activation still applies. No artist installation/restart, older-host testing,
Git publication or live website deployment was performed.

## Result and implementation

Spheres, boxes, vertical sides and manifold curved surfaces accept Paint again.
The existing terrain vector path is preserved; general surfaces use native
per-face barycentric vector regions and surface-distance strokes. Paint does not
project through the sphere or disconnected sheets. Full XYZ transforms, including
nonuniform scale and mirrors, participate in physical distances. Degenerate and
nonmanifold geometry rejects with context and retains preceding results.

Paint/Erase, Fill/Clear, holes, density/scale fade curves, vector feedback,
independent copies, Manual/Live, Undo/Redo and scene persistence remain supported.
Curved borders export as 3D splines. Unchanged guarded snapshots restore exact
coverage; edited surface curves reconstruct their smaller enclosed region.
The host tests found and resolved both a small-brush refinement-depth limit and
the inappropriate generic knot limit on exact exported snapshots.

All prior library/Amount fixes remain: complete unit conversion and terrain Paint
transfer, receiver-aware procedural maps, channel/pattern switching and Clear,
valid empty-source publication, and minimized Library restoration.

## Evidence

- **46 native tests**, including **82 surface Paint assertions** and retained terrain/conversion tests.
- **175 Python tests** and generated UI validation covering **321 controls**.
- **21 brush host phases** through generated UI handlers and actual Max Painter SDK callbacks: sphere stroke/erase, opposite-side isolation, box/cylinder sides, cancellation, fade curves, exact spline snapshots, copies, unit transfer, transforms, topology failure/recovery, Manual/Live, idle reuse and scene reopen.
- **{len(qualification['records'])} recorded final-pair host cases/suites**, including all eight presets in millimetres, transformed feet, centimetre incompatible-destination recovery and a metre heightfield; plus lifecycle, Amount, receiver-map, elevation and damaged-package/capacity suites.
- **{counts['RecipientChecks']} exact-EXE recipient checks**, including legacy path limits, Unicode paths, repair, modified-file preservation, five injected rollback points, upgrade from original 0.87.0, unregister and personal-data preservation.
- **{counts['UiChecks']} actual EXE UI/layout/handler checks**, including scaled layout, successful installation and visible full repair errors in owned profiles.
- The exact MZP installer core loads in Max 2027 and installs/repairs the payload and dependency notices in a separate owned recipient directory.
- Archive integrity, every payload hash, Max/version guards, embedded package identity and Windows file/assembly version **0.86.6.0** verified. Private Painter probe is excluded.

The final owned sphere test took **708.506 ms for 13 Painter samples** including
feedback preparation. Its process private bytes rose from **4,788,584,448** before
the fixture to **5,021,683,712** after the full sequence, with a recorded peak
working set of **3,121,164,288** bytes. These are process observations including
Max/UI/history, not isolated native allocations or presented viewport FPS.

## Limits and acceptance

Curved receivers admit at most 100,000 triangles/200,000 vertices. Solver intervals,
propagation, contour refinement, curve input and payload size have separate work
limits; retained/staged reservation is bounded and preserves OS commit headroom.
Contour refinement targets 0.5% of brush radius; feather boundary sources use
2% of fade width spacing. These are bounded approximations, not exact isolines.
Arbitrary remeshing cannot preserve face correspondence. Terrain preset transfer
still requires a usable local-XY footprint; curved preset transfer requires matching
indexed topology. Edited curves have an 8,192-knot/sample cap; exact unchanged
snapshots use the native contour cap. A fully filled closed object has no border.

Tests drive real Painter callbacks and UI handlers but do not certify physical
mouse/tablet input, every production renderer, all scene sizes or older Max hosts.
Artist acceptance: test a copy of a working scene with sphere/box/curved painting,
erase and fade curves; save/reopen; then exercise the Library and Amount workflows.

## Exact identities

- MZP SHA-256: `{sha(archive)}`
- EXE SHA-256: `{sha(setup)}`
- Script SHA-256: `{qualification['script_sha256']}`
- Native receipt SHA-256: `{qualification['native_receipt_sha256']}`
- [Host qualification](QUALIFICATION_0866.json); package, EXE and native receipts accompany the installers.
- Source changes and reproducible fixtures: `tools/surface_brush_0866/`; [design/ownership record](BRUSH_0866.md).

Website status: current sources will be imported and checked locally; nothing is published.
'''
(DOC/'DELIVERY_0866.md').write_text(report,encoding='utf-8')
design=DOC/'BRUSH_0866.md';s=design.read_text().replace('## Required acceptance — pending','## Required acceptance — completed within recorded scope').replace('Status: implementation in progress. This file is a plan, not a qualification claim.','Status: implemented and qualified within the [0.86.6 delivery report](DELIVERY_0866.md). That report and its receipts own completed evidence and remaining artist acceptance.');design.write_text(s,encoding='utf-8')
for script in ('update_docs.py','update_public.py'):subprocess.run([sys.executable,'-X','utf8',str(Path(__file__).parent/script)],check=True)
print(dest)
