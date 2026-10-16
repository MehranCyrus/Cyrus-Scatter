"""Render and attach a real example image; keep the initial viewport receipt."""
from pathlib import Path
import hashlib,json,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
command=json.loads((OUT/'command.json').read_text(encoding='utf-8'));folder=OUT/'gallery-examples'/command['folder']
record=json.loads((folder/'receipt.json').read_text(encoding='utf-8'));assert record['status']=='passed'
report={'status':'running','scope':'Explicit Scanline render of exact placement meshes in owned scene'}
try:
 with pymxs.undo(False):
  assert r.loadMaxFile(record['scene'],quiet=True,useFileUnits=True)
  root=next(node.baseObject for node in r.objects if str(r.classOf(node.baseObject))=='AminScatterObject');root.refreshAll()
  r.DemoRoot=root;r.DemoCamera=r.getNodeByName('Camera | Preset overview');r.DemoImagePath=str(folder/'render-preview.png')
  before=str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows));nodes=list(r.objects)
  r.fileIn(str(ROOT/'tools/gallery_0851/render_example.ms'))
  assert list(r.objects)==nodes and str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows))==before
  r.CyrusOpenRecipeSave(root,str(folder),path=record['recipe'],expected=r.cyrusRecipeInfo(record['recipe'])[10])
  editor=r.CyrusRecipeSaveEditor;editor.thumbnailFile=r.DemoImagePath;editor.thumbnailCapture=None;editor.saveEntry(True);editor.closeButton.pressed()
  thumbnail=Path(str(r.cyrusRecipeThumbnail(record['recipe'])));assert thumbnail.is_file()
  files={Path(record['recipe']),Path(record['scene'])}
  def collect(value):
   if isinstance(value,dict):
    if set(value)=={'bytes','file','sha256'}:
     file=(folder/value['file']).resolve();assert file.is_relative_to(folder.resolve())
     assert file.stat().st_size==value['bytes'] and hashlib.sha256(file.read_bytes()).hexdigest()==value['sha256'];files.add(file)
    for item in value.values():collect(item)
   elif isinstance(value,list):
    for item in value:collect(item)
  collect(json.loads(Path(record['recipe']).read_text(encoding='utf-8')))
  report.update(status='passed',recipe=record['recipe'],scene=record['scene'],thumbnail=str(thumbnail),files={path.relative_to(folder).as_posix():hashlib.sha256(path.read_bytes()).hexdigest() for path in files})
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(folder/'preview-receipt.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
