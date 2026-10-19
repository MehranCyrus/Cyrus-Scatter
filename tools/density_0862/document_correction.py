"""Update maintained delivery guidance after the correction receipt exists."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/plans/preset-gallery-improvements'
receipt=json.loads((DOC/'QUALIFICATION_0862_CORRECTION.json').read_text(encoding='utf-8'))
assert receipt['version']=='0.86.2'
report=DOC/'DELIVERY_0862.md';text=report.read_text(encoding='utf-8')
assert '## Same-version correction' not in text
rows=[]
for name,item in receipt['artifacts'].items():
    label='Max 2027 MZP' if name.endswith('.mzp') else 'Unsigned Max 2027 EXE'
    rows.append(f"| [{label}](../../../{item['path']}) | {item['bytes']:,} | `{item['sha256']}` |")
section='''## Same-version correction — 19 October 2026

**Use these corrected installers. Version remains 0.86.2 at the user's request.** The [correction receipt](QUALIFICATION_0862_CORRECTION.json) supersedes the original installer pair below; the original receipt and artifacts are preserved as historical evidence. The original demo ZIP remains compatible and was requalified against the corrected pair.

| Current installer | Bytes | SHA-256 |
| --- | ---: | --- |
'''+ '\n'.join(rows)+'''

Save your scene, run the EXE **or Scripting > Run Script** with this MZP, then restart Max 2027. The visible version caption is unchanged; use these artifact paths and hashes to distinguish the correction. A same-version upgrade/repair was tested in disposable paths. No artist installation or restart was performed.

### Reproduced cause and correction

The installed script matched the original delivery. Its generated line 10552 assigned `undefined` to a MAXScript BitmapControl when Amount bound a layer without a map, a procedural Noise map, or an empty Bitmaptexture. All three reproduced the reported exception in an owned Max 2027 host. Earlier tests had mounted Amount only after assigning bitmap images, so they missed this normal artist workflow.

Physical checking also revealed that BitmapControl cropped the image instead of showing the whole tile. Amount now uses native **ImgTag with `#bmp_stretch`**, which supports clearing an empty image and displays the full tile. The generator, semantic inventory and help catalog recognize this control. Browsing does not render a procedural map, create resized image copies, close map-owned bitmaps or change authored density settings. Autodesk's [ImgTag API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/Rollout-User-Interface-Controls-3/GUID-0A492074-4A5B-4D18-B65A-E859FC8E2454.html) documents the control; actual Max probes and the full generated rollout tests establish this correction's behavior.

### Correction qualification

- Fresh empty setup, no map, bitmap, Noise, empty/missing bitmap, Clear, actual picker callbacks, basic/Advanced, Undo/Redo, panel reopening and scene reopening pass in Max 2027 at 100% and 150% UI scales. Every loaded recipe layer's Amount page is checked, including layers with no image.
- All eight bundled examples pass compatible-terrain Add/Undo/Redo. Library new-setup and additive workflows, saved image/Paint/model recipes, transformed mapping frames, saved-scene reopening, missing dependency preflight and post-staging failure rollback pass.
- Existing density/preview tests pass: projection/UV/channel components, image/mesh/combined numeric fields, explicit procedural Bake, persistent Invert/Undo, real Data Channel Curvature edits, stale-field handling, Manual retention, relevant Live updates, unrelated animation and idle reuse. Count changes through 250,000 preserve exact Undo and reuse the image tile. These fixtures are not an all-scene performance guarantee.
- Fifty passive Amount binds leave calculation, preparation and density counters unchanged. The generated layout audit checks visible control HWNDs at both tested scales. Native tests: 45/45; Python: 175; managed gallery: 41; same-version installer distribution: 35. Source/generated/catalog consistency passes. A generator regression test now covers comment punctuation, property names, literals and named arguments.

The generator also incorrectly treated a period at the end of a comment as a property-access operator. It now ignores comments when qualifying control identifiers, preventing an unqualified thumbnail reference. Native tests ran on `native02`; final `pair03` reused those exact native binaries after verifying unchanged native sources, then received fresh host tests with the corrected generated script. The native tests were not reported as rerun for the script-only pairing.

Final script SHA-256: `'''+receipt['source_script_sha256']+'''`. Final exact-pair host receipts use `density0862-s` and `density0862-t`, plus a cold start in `density0862-u`. Mouse-driven packaged-library loading, pattern selection, Show/Invert/Hide and wheel/drag navigation were checked in that cold-start host. The initial reproduction uses `density0862-p`; earlier correction candidates in `q/r` remain distinct evidence, including the visual finding that prompted whole-image scaling. No new pattern art, C++ placement behavior, slope/altitude changes, roadmap resumption, index activation or Git push is included.

**Artist regression:** open an empty setup's Amount panel; load a library example and switch through every layer; select and clear an image; choose Noise; reopen Amount; use Show mask/Invert/Hide; save and reload a supported image/Paint recipe; Undo/Redo. The final product pattern collection still awaits the user's artwork; only the existing three QA images were used for testing.

## Original delivery evidence — retained

The installers in the following historical table are superseded by the correction above. Their hashes and original test scope remain unchanged.

'''
title,body=text.split('\n',1)
text=title+'\n\n'+section+body.lstrip('\n')
text=text.replace('## Installers and demonstration','## Original installers and demonstration (superseded installer pair)',1)
report.write_text(text,encoding='utf-8')
for name,needle,addition in [
 ('README.md','The earlier [0.86.1 compatibility delivery]','The same-version correction fixes empty/procedural-map Amount errors and cropped thumbnails; use the latest installers in that report. The earlier [0.86.1 compatibility delivery]'),
 ('docs/plans/improvement-program/PROGRESS.md','No artist installation or Git push was performed.','The same-version correction fixes empty/procedural-map Amount errors and whole-image thumbnail scaling, with all eight library examples and every layer panel rechecked. No artist installation or Git push was performed.')]:
    path=ROOT/name;content=path.read_text(encoding='utf-8');assert needle in content;path.write_text(content.replace(needle,addition,1),encoding='utf-8')
path=ROOT/'docs/BACKLOG.md';content=path.read_text(encoding='utf-8');assert '| B30 |' not in content
lines=content.splitlines(True);at=next(i for i,line in enumerate(lines) if line.startswith('| B29 |'))+1
lines.insert(at,'| B30 | Fixed in the [same-version 0.86.2 correction](plans/preset-gallery-improvements/DELIVERY_0862.md#same-version-correction--19-october-2026): Amount assigned undefined to BitmapControl for no map/procedural maps; its thumbnail also cropped images. Native ImgTag now clears safely and shows the complete tile | Reproduced original failure, actual generated picker/panel callbacks, blank setup/reopen, Undo/Redo, all eight library examples and per-layer Amount checks at 100/150% pass; physical mixed-monitor transitions remain separate |\n')
path.write_text(''.join(lines),encoding='utf-8')
print('Maintained report, README, execution ledger and defect register updated; original receipt retained.')
