"""Deliver the editable demo and its two QA textures with a relocation-safe opener."""
from pathlib import Path
import argparse,hashlib,json,shutil,sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('density0862-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
dest=ROOT/'dist/CyrusScatter-0.86.2-20261019/Demo';dest.mkdir(parents=True,exist_ok=False)
for name in ('soft-patches.png','wide-bands.png'):shutil.copy2(ROOT/'tools/density_0862/patterns'/name,dest/name)
opener='''-- Run this file after extracting the whole Demo folder. Uses the installed plugin.
(
 local directory=getFilenamePath (getSourceFileName())
 if (maxVersion())[1]!=29000 do throw "Open this demonstration with Max 2027."
 if not loadMaxFile (directory+"Cyrus Scatter 0.86.2 - Feature Demo.max") useFileUnits:true do throw "The demonstration scene was not opened."
 local node=getNodeByName "CYRUS 0.86.2 | SELECT ME - six feature layers",root=node.baseObject
 if root.uiVersion()!="0.86.2" do throw "Install the complete Cyrus 0.86.2 package and restart Max first."
 with undo off for leaf in root.layerObjects where classof leaf.densityMap==Bitmaptexture do (
  local name=(getFilenameFile leaf.densityMap.filename)+".png"
  if findItem #("soft-patches.png","wide-bands.png") name==0 do throw "Unexpected demo image."
  local pixels=openBitmap (directory+name) colorSpace:ColorPipelineMgr.DataColorSpace
  leaf.densityMap=bitmaptexture name:("QA / "+name) bitmap:pixels
 )
 root.refreshAll();select node;max modify mode
)
'''
(dest/'OPEN DEMO.ms').write_text(opener,encoding='utf-8-sig')
request=host/'stage-demo.ms'
request.write_text('''(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 CyrusClearMeshMaskPreview undefined
 if not loadMaxFile (MCPFixtureDir+"Feature Demo 0.86.2 - working.max") quiet:true useFileUnits:true do throw "Owned source demo missing"
 local node=getNodeByName "CYRUS 0.86.2 | SELECT ME - six feature layers",root=node.baseObject,directory=@"'''+dest.as_posix()+'''/"
 root.refreshAll();global DeliveredDemoHash=cyrusRecipePublicationFingerprint root.groupSnapshotRows
 with undo off for leaf in root.layerObjects where classof leaf.densityMap==Bitmaptexture do (
  local name=(getFilenameFile leaf.densityMap.filename)+".png",pixels=openBitmap (directory+name) colorSpace:ColorPipelineMgr.DataColorSpace
  leaf.densityMap=bitmaptexture name:("QA / "+name) bitmap:pixels
 )
 root.refreshAll()
 if (cyrusRecipePublicationFingerprint root.groupSnapshotRows)!=DeliveredDemoHash do throw "Rebinding byte-identical QA maps changed the demonstration"
 select node;max modify mode
 if not saveMaxFile (directory+"Cyrus Scatter 0.86.2 - Feature Demo.max") quiet:true do throw "Demo save failed"
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"delivered-demo-hash.txt") DeliveredDemoHash
)
''',encoding='utf-8-sig')
send(host,request,'Save final self-contained demo folder')
receipt={'scope':'QA demo artwork only; not product patterns','publication_sha256':(host/'delivered-demo-hash.txt').read_text(encoding='utf-8-sig'),'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in dest.iterdir() if p.is_file()}}
(dest/'DEMO-IDENTITY.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(dest)
