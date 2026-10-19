"""Check the delivered demo in a moved directory and real channel/marker lifecycle."""
from pathlib import Path
import argparse, json, shutil, sys, time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('density0862-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
source=ROOT/'dist/CyrusScatter-0.86.2-20261019/Demo'
dest=host/'relocated-demo'
if not dest.exists():shutil.copytree(source,dest)
else:
 for path in source.iterdir():
  if path.is_file():assert (dest/path.name).read_bytes()==path.read_bytes(),path.name
expected=json.loads((source/'DEMO-IDENTITY.json').read_text(encoding='utf-8'))['publication_sha256']
script=host/'relocated-demo-check.ms'
script.write_text('''(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 fileIn @"'''+(dest/'OPEN DEMO.ms').as_posix()+'''"
 global Demo0862Root=(getNodeByName "CYRUS 0.86.2 | SELECT ME - six feature layers").baseObject
 if cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows!="'''+expected+'''" do throw "Moved demo result differs"
 for leaf in Demo0862Root.layerObjects where classof leaf.densityMap==Bitmaptexture do (
  if not matchPattern (substituteString leaf.densityMap.filename "\\\\" "/") pattern:(MCPFixtureDir+"relocated-demo/*") do throw "Map did not relocate"
 )
 CyrusMaskView=3;CyrusShowMeshMaskPreview Demo0862Root.layerObjects[4]
 local before=cyrusDensityOverlayStats(),hash=cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows
 CyrusMaskMarkers=true
 for size=1 to 3 do (CyrusMaskMarkerSize=size;completeRedraw())
 local after=cyrusDensityOverlayStats()
 if before[1]!=after[1] do throw "Marker size rebuilt the field"
 if hash!=(cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows) do throw "Markers changed plants"
 CyrusMaskMarkers=false;CyrusClearMeshMaskPreview undefined
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"relocated-demo-result.txt") "PASS: Moved demo opens, maps rebind, exact full output; all three marker sizes redraw without rebuilding the field or placements."
)
''',encoding='utf-8-sig')
send(host,script,'Moved demo and optional markers')
for phase in ('curvature','curvatureVerify','curvatureUndo'):
 (host/'demo-phase.txt').write_text(phase,encoding='utf-8')
 send(host,ROOT/'tools/density_0862/demo_lifecycle.ms',phase)
 time.sleep(1)
 log=(host/f'demo-{phase}.txt').read_text(encoding='utf-8-sig')
 assert 'PASS: complete' in log and 'FAIL:' not in log and 'ERROR:' not in log,log
 print(log)
print((host/'relocated-demo-result.txt').read_text(encoding='utf-8-sig'))
