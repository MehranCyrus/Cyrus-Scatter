"""Update current navigation; retain historical release reports."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def edit(name,old,new):
    p=ROOT/name;s=p.read_text(encoding='utf-8');assert old in s,name;p.write_text(s.replace(old,new,1),encoding='utf-8')
edit('README.md','**Current delivery: Scatter 0.86.6 / schema 58 / CyrusUnified1, qualified within scope for Max 2027.**',
     '**Current delivery: Scatter 0.86.7 / schema 58 / CyrusUnified1, with matched Max 2024, 2026 and 2027 installers.** See the [0.86.7 delivery and qualification limits](docs/plans/preset-gallery-improvements/DELIVERY_0867.md). Historical baseline: ')
p=ROOT/'README.md';s=p.read_text();start=s.index('The current private library successor');end=s.index('The separate [panel loading',start)
s=s[:start]+'''The private **0.86.7 individual library** retains 96 prepared models and their
original previews, covering all 104 catalog cards. It fixes automatic thumbnail
loading and adds **Appearance > Materials / Textures** for Mesh preview.
**Models & Points** uses **+** to add objects, places **Add Point** beside **Make
point**, and lets **Pick object** replace either a Point or a model.
The shared `dist/CyrusScatter-0.86.7-20261020/Content` folder belongs beside the
EXE. Prepared files were saved back to Max 2024 format; model geometry and image
assets were reused. Corona/Forest material dependencies still require matching
host plug-ins. Actual Corona leaf material tests were performed in Max 2027;
the older local hosts lack those dependencies. See the delivery report for
exact scope and receipts. Private content and installers remain outside Git.

'''+s[end:];p.write_text(s)
edit('README.md','[qualified Max 2027 MZP/EXE and artist tests](docs/plans/preset-gallery-improvements/DELIVERY_0866.md)',
     '[0.86.7 installers, checks and limits](docs/plans/preset-gallery-improvements/DELIVERY_0867.md)')
edit('docs/ARTIST_GUIDE.md','# Cyrus Scatter 0.86.6 — current artist workflow','# Cyrus Scatter 0.86.7 — current artist workflow')
edit('docs/ARTIST_GUIDE.md','The private **0.86.6.2 individual library**','The private **0.86.7 individual library**')
p=ROOT/'docs/ARTIST_GUIDE.md';s=p.read_text();start=s.index('Two current limitations');end=s.index('This Max 2027 delivery',start)
s=s[:start]+'''Library thumbnails now load as you scroll. In **Viewport & render**, choose
**Mesh** and **Appearance > Materials / Textures** to preview supported source
materials, source UV channels and leaf cutout opacity. Layer, Model and Bands
remain identification-color choices. Material edits update appearance without
applying pending Manual placement changes.

The preview uses bounded 256-pixel material tiles and two-sided alpha cutouts;
it is not a Corona render. Standard and Corona Legacy/Physical base color and
opacity, Multi/Sub IDs, Bitmap, Checker and supported UV map chains are covered.
Forest Color uses a preview without per-instance Forest variation. World/vertex
dependent maps and unsupported shaders use a stated fallback. Missing source UV
channels retain the previous complete display until repaired. Source render
materials remain intact. The supplied library requires compatible Corona and,
where used, Forest map plug-ins in each Max version.

'''+s[end:]
s=s.replace('**Models & Points** starts with Add Point and Add Model.','**Models & Points** uses the **+** below the source list to add a model. **Add Point** sits beside **Make point**. The former Add currently selected scene objects action is removed.')
s=s.replace('**Pick object** is enabled for one selected Point;','**Pick object** is enabled for one selected Point or model and replaces that row with the picked object;')
p.write_text(s)
p=ROOT/'docs/Max_2027_Installation.md';s=p.read_text();start=s.index('The **0.86.6');end=s.index('## Install',start)
s=s[:start]+'''The **0.86.7 / schema 58** delivery provides matched Max 2024, 2026 and 2027
MZPs and one Windows EXE. See the [delivery report](plans/preset-gallery-improvements/DELIVERY_0867.md)
for exact evidence and renderer dependency limits. Artist profiles and sessions
were not installed into or restarted.

'''+s[end:]
start=s.index('For the private');end=s.index('\n\n',s.index('retain the separately qualified',start))
s=s[:start]+'''Keep `dist/CyrusScatter-0.86.7-20261020/CyrusScatter-0.86.7-Setup.exe`
beside its **Content** folder. Choose your Max version in the EXE, then
**Install / Repair**. Alternatively use **Scripting > Run Script** with the
matching `CyrusScatter-0.86.7-MaxYEAR.mzp`. When asked for content, the delivery
folder, Content, and its Library child are accepted.

Save your work and restart Max after installation. The three host payloads share
one verified content store using NTFS hard links; old installed releases remain
usable while Max is open. Existing unchanged installed assets are reused. The
distribution must still accompany the installer when sharing it.
Corona/Forest plug-ins matching the host are required by the supplied materials.
The instructions below retain the separate historical 0.86.6 build evidence.'''+s[end:];p.write_text(s)
edit('docs/Release_Versioning.md','| Scatter UI | 0.86.6.2 individual-model candidate; 0.86.6 qualified | Individual models replace mixed demos; historical 0.86.6.1/0.88.0 receipts retain their identities |',
     '| Scatter UI | 0.86.7 | Thumbnail scheduling, textured Mesh appearance and source controls; historical receipts retain their identities |')
edit('docs/Release_Versioning.md','| Scatter native/package | 0.86.6.2 candidate / Max 2027; [qualified 0.86.6 acceptance](plans/preset-gallery-improvements/DELIVERY_0866.md) | Exact unchanged native bytes retained; matched new script/gallery/package identities required |',
     '| Scatter native/package | 0.86.7 / Max 2024, 2026, 2027 | Distinct matched SDK/managed payloads and shared content; [delivery scope](plans/preset-gallery-improvements/DELIVERY_0867.md) |')
edit('docs/Release_Versioning.md','## Choosing the next version\n','''## Choosing the next version

**20 October 2026 user-selected delivery: 0.86.7.** This is the explicitly
requested successor to 0.86.6.2. It adds bounded native material/UV/opacity Mesh
preview, fixes thumbnail scheduling, revises source controls and shares existing
content across matched 2024/2026/2027 installers. Saved scene schema 58, recipe 7,
and independently versioned products stay unchanged. The external content
manifest adds schema 2 with an explicit three-host set; models use Max 2024 file
format. This choice records the user's label and full delivery scope rather
than applying an unrelated roadmap milestone. Historical qualification stays
with its original artifacts.
''')
edit('docs/plans/improvement-program/PROGRESS.md','## Panel selection and threading investigation','''## 0.86.7 library, appearance and compatibility — 20 October 2026

The user-authorized B33/B34 and Models & Points changes are implemented.
See [delivery scope and receipts](../preset-gallery-improvements/DELIVERY_0867.md).
Thumbnail wheel scheduling, native material appearance, source replacement,
shared content installation and distinct 2024/2026/2027 SDK payloads are covered.
The 96 existing model files were saved back, not rebuilt; original maps/previews
remain byte-identical. Corona leaf + Color Correction acceptance is Max 2027;
older hosts qualify native Standard/Multi/Sub behavior and missing-dependency
rollback, not installed Corona rendering. No artist profile/session, Git push,
website publication or unrelated panel rewrite is part of this delivery.
The dated 0.86.6.2 handoff below is historical, not current open status.

## Panel selection and threading investigation''')
p=ROOT/'docs/BACKLOG.md';s=p.read_text()
lines=s.splitlines()
for i,line in enumerate(lines):
    if line.startswith('| B33 |'):lines[i]='| B33 | Fixed within 0.86.7: wheel scrolling now schedules newly visible thumbnails after idle | Actual control regression and hosted Max 2024/2026/2027 checks cover wheel without clicks, warm revisit, resize, category/search replacement and disposal. See [delivery](plans/preset-gallery-improvements/DELIVERY_0867.md) |'
    if line.startswith('| B34 |'):lines[i]='| B34 | Implemented in 0.86.7: explicit Materials / Textures Mesh appearance | Native Standard/Multi/Sub/UV checks in three hosts; actual Corona leaf + Color Correction in Max 2027. Bounded maps, independent opacity, Manual retention and fallbacks are documented in the [delivery](plans/preset-gallery-improvements/DELIVERY_0867.md). Full renderer fidelity and arbitrary map graphs remain outside scope |'
p.write_text('\n'.join(lines)+'\n')
