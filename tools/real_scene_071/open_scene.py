"""Open a working copy of the landscape demo with the pinned 0.7.1 build."""
from pathlib import Path
import argparse,datetime,json,shutil,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch,digest
from preview import CANDIDATE,SCRIPT_HASH,MODULES
ANALYZER_HASH='737c50438892916cff7ece1b90fc606f7d6d08f695effc7e0bab76b3e9b15131'

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--scene',default='Cyrus_071_Garden_Pavilion.max')
 parser.add_argument('--verify-only',action='store_true')
 parser.add_argument('--smoke-test',action='store_true')
 args=parser.parse_args()
 scene=(ROOT/'Test Scene/Cyrus_071_Courtyard'/args.scene).resolve()
 if not scene.is_relative_to(ROOT/'Test Scene/Cyrus_071_Courtyard') or scene.suffix.lower()!='.max':raise ValueError('Choose a delivered demo scene')
 if not scene.is_file():raise FileNotFoundError(scene)
 native=ROOT/'build/real-scene-071/native-full'
 script=CANDIDATE/'source/AminScatter/scripts/AminScatterObject.ms'
 if digest(script)!=SCRIPT_HASH:raise RuntimeError('The qualified Scatter script changed')
 for name,sha in {**MODULES,'CyrusSurfaceAnalyzer.dlx':ANALYZER_HASH}.items():
  if digest(native/name)!=sha:raise RuntimeError('Native build identity changed: '+name)
 analyzer=ROOT/'build/real-scene-071/source/CyrusSurfaceAnalyzer.ms'
 manifest=json.loads((ROOT/'build/real-scene-071/identity.json').read_text())
 if digest(analyzer)!=manifest['analyzer_script_sha256']:raise RuntimeError('The frozen Analyzer script changed')
 if args.verify_only:
  print('PASS: demo scene, Scatter script, Analyzer script and five matching Max 2027 modules are available.')
  return
 stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'-'+uuid.uuid4().hex[:8]
 folder=ROOT/'build/user-tests/real-scene-071'/stamp
 # Keep the preview visibly distinct from the same scene opened in the artist's
 # normal Max profile, which may still have an older installed plugin.
 working=folder/'project/scenes'/('PREVIEW_0_7_1__'+scene.name)
 # The extra script runs only after launch() has created the isolated directories.
 extra='fileIn @"'+analyzer.as_posix()+'"\n'
 extra+='(dotNetClass "System.IO.File").Copy @"'+scene.as_posix()+'" @"'+working.as_posix()+'" false\n'
 extra+='if not(loadMaxFile @"'+working.as_posix()+'" quiet:true useFileUnits:true) do throw "Could not open the demonstration copy"\n'
 extra+='local n=getNodeByName "CYRUS 0.7.1 | Courtyard - Edit layer"\n'
 extra+='if isValidNode n and not n.baseObject.cyrusEnabled do (local active=for candidate in objects where classof candidate.baseObject==AminScatterObject and candidate.baseObject.cyrusEnabled collect candidate;if active.count>0 do n=active[1])\n'
 extra+='if not isValidNode n do throw "The preview Scatter controller is missing."\n'
 extra+='if n.baseObject.uiVersion()!="0.7.1" or CyrusOpenLayerEditor==undefined do throw "The 0.7.1 Layer Editor is not loaded in this preview. Keep this session separate from the installed plugin."\n'
 extra+='if isValidNode n do (n.baseObject.refreshAll();if n.baseObject.groupPolicy==3 do n.baseObject.evaluateGroups();for leaf in n.baseObject.layerObjects do if (leaf.cacheSnapshot())[4]!="" do throw (leaf.cacheSnapshot())[4];select n;max modify mode;modPanel.setCurrentObject n.baseObject;if not n.baseObject.mainUI.controlsReady do n.baseObject.mainUI.mountTimer.tick())\n'
 extra+='n.baseObject.layersUI.open=true\n'
 extra+='n.baseObject.mainUI.selectLayerView (n.baseObject.selectedLayer()) expand:true\n'
 extra+='if CyrusLayerEditor==undefined or CyrusLayerEditor.root!=n.baseObject do throw "The preview Layer Editor did not open for its Scatter controller."\n'
 extra+='(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"editor-ready.json") '+json.dumps(json.dumps({'ui_version':'0.7.1','layer_editor_opened':True}))+'\n'
 extra+='if isValidNode n do (local counts=createFile (MCPFixtureDir+"scene-counts.tsv");for leaf in n.baseObject.layerObjects do format "%\\t%\\n" leaf.paintSetName leaf.generatedCount to:counts;close counts)\n'
 extra+='viewport.setRenderLevel #smoothhighlights;completeRedraw()\n'
 process,metadata=launch(folder,script,native,extra=extra,transport=False,visible=not args.smoke_test,extra_modules=('CyrusSurfaceAnalyzer.dlx',))
 print('Opening a new Max 2027 working copy: '+str(working),flush=True)
 deadline=time.monotonic()+240
 try:
  while not(folder/'ready.json').exists():
   error=folder/'startup-error.txt'
   if error.exists():raise RuntimeError(error.read_text(encoding='utf-8-sig'))
   if process.poll() is not None or time.monotonic()>deadline:raise RuntimeError('Private launch did not finish. See '+str(folder))
   time.sleep(.5)
  counts=[line.rsplit('\t',1) for line in (folder/'scene-counts.tsv').read_text(encoding='utf-8-sig').splitlines()]
  editor=json.loads((folder/'editor-ready.json').read_text(encoding='utf-8-sig'))
  if editor!={'ui_version':'0.7.1','layer_editor_opened':True}:raise RuntimeError('The preview UI readiness receipt is invalid.')
  metadata.update(status='PASS',scene=str(scene),working_copy=str(working),development_transport=False,ui=editor,populations=[{'name':name,'instances':int(count)} for name,count in counts])
  (folder/'open-result.json').write_text(json.dumps(metadata,indent=2)+'\n')
  print('Ready. Use the Max window named '+working.name+'. The 0.7.1 Layer Editor opens automatically.')
  print('To reopen it: Modify > Layer Manager > Edit layer. Camera 04 shows the model containers.')
 finally:
  if args.smoke_test and process.poll() is None:process.terminate();process.wait(timeout=30)

if __name__=='__main__':main()
