"""Owned Max 2027: test the public SDK merge against B38 before adoption."""
from pathlib import Path
import json, traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun))
report={'status':'running','scope':'Owned disposable Max 2027; SDK/Undo investigation'}
try:
    r.execute('global MCPFixtureDir=GardenRun;global SPGlobal,SPCore,SPFile;fileIn @"'+(Path(__file__).resolve().parents[3]/'tools/mcp/development_transport.ms').as_posix()+'"')
    r.execute('dotNet.loadAssembly "Autodesk.Max";SPGlobal=(dotNetClass "Autodesk.Max.GlobalInterface").Instance;SPCore=SPGlobal.COREInterface')
    r.execute('global SPMethods=(SPCore.GetType()).GetMethods();global SPMethodText="";for m in SPMethods where matchPattern m.Name pattern:"*Merge*" do SPMethodText+=(m.ToString()+"\\n")')
    report['sdk_methods']=str(r.SPMethodText)
    r.execute('with undo off (global SPBox=box name:"ScenePresetProbeBox";SPFile=GardenRun+"merge-probe.max";saveNodes #(SPBox) SPFile quiet:true;delete SPBox)')
    r.execute('undo "Previous artist move" on (global SPSentinel=box name:"PreviousArtistObject" pos:[10,0,0])')
    report['undo_before']=list(r.theHold.getUndoNames())
    try:
        r.execute('global SPMergeResult=SPCore.MergeFromFile SPFile true false false 1000 undefined 1000 0 true undefined false')
        report['sdk_result']=str(r.SPMergeResult)
        report['undo_after']=list(r.theHold.getUndoNames())
        report['nodes_after']=[str(n.name) for n in r.objects]
    except Exception:report['sdk_error']=traceback.format_exc()
    report['status']='complete'
except Exception:report.update(status='failed',error=traceback.format_exc())
(out/'probe.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(out/'ready.json').write_text(json.dumps({'status':'ready','version':'0.87.5','probe':True}),encoding='utf-8')

