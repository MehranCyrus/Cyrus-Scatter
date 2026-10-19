"""Blank/procedural/image states and Undo in the actual Modify Amount page."""
from pathlib import Path
import argparse,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('density0862-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
def command(label,code):
    script=host/(label+'.ms');script.write_text(code,encoding='utf-8-sig');send(host,script,label)
for name in ('initial','ui_setup','layout_prepare','thumbnail_checks'):
    send(host,ROOT/('tools/density_0862/'+name+'.ms'),name)
print((host/'thumbnail-checks.txt').read_text(encoding='utf-8-sig'))
command('thumbnail-undo','max undo')
command('thumbnail-undo-check','if DLayer.densityMap!=ThumbnailOriginal do throw "Undo lost original map"; DRoot.bindNativeUI(); DRoot.mainUI.editors[6].distributionUI_syncControls()')
command('thumbnail-redo','max redo')
command('thumbnail-redo-check','if DLayer.densityMap!=undefined do throw "Redo did not clear map"; DRoot.bindNativeUI(); DRoot.mainUI.editors[6].distributionUI_syncControls()')
command('blank-mount','''(
 CyrusClearMeshMaskPreview undefined
 with undo off (
  resetMaxFile #noPrompt
  DNode=AminScatterObject name:"Fresh no-map panel witness";DRoot=DNode.baseObject;DRoot.newLayer();DLayer=DRoot.selectedLayer()
 )
 select DNode;max modify mode;DRoot.bindNativeUI()
)''')
send(host,ROOT/'tools/density_0862/panel_checks.ms','Load panel checks')
command('blank-check','DCheckRootPanels DRoot "fresh-blank"')
command('blank-reopen','clearSelection()')
command('blank-remount','select DNode;max modify mode;DRoot.bindNativeUI()')
command('blank-remount-check','DCheckRootPanels DRoot "fresh-blank-reopened"')
command('blank-save','if not (saveMaxFile (MCPFixtureDir+"blank-panel.max") quiet:true) do throw "Blank fixture save failed"')
command('blank-load','loadMaxFile (MCPFixtureDir+"blank-panel.max") quiet:true;DNode=getNodeByName "Fresh no-map panel witness";DRoot=DNode.baseObject;select DNode;max modify mode;DRoot.bindNativeUI()')
command('blank-load-check','DCheckRootPanels DRoot "fresh-blank-scene-reopened"')
(host/'thumbnail-campaign.txt').write_text('PASS: blank/image/Noise/empty Bitmap/missing image/Clear/basic/Advanced/50 binds/Undo/Redo/panel reopen/scene reopen\n',encoding='utf-8')
print('PASS: thumbnail campaign')
