"""Serial private-host scenario driver; no computer use or artist profile writes.

Use as unified_073_qualification.py --external .../system_075_campaign.py.
Select phase using CYRUS_075_PHASE=ui, behavior, or performance.
Each scenario stores independent reports before a later fixture can overwrite them.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import time
from runtime_driver import ROOT, run_script


def main():
    folder=Path(sys.argv[1]).resolve()
    phase=os.environ.get('CYRUS_075_PHASE','ui')
    if phase=='retained':
        source=ROOT/'tools/procedural_lab/Max_Playback_073_Regression.ms'
        definitions=source.read_text().split('if findString (toLower PTDir)',1)[0]
        (folder/'playback-definitions.ms').write_text(definitions)
    if phase=='performance':
        # Avoid timing navigation while the other owned campaigns contend for
        # CPU, graphics resources and the Max startup cache. No artist process
        # is inspected or stopped here.
        wait_for=[folder.parent/name for name in ('qualification075-ui-final','procedural07-ui-qualification075-behavior-final')]
        deadline=time.monotonic()+600
        while any(p.exists() and not (p/'qualification.json').exists() for p in wait_for):
            if time.monotonic()>deadline:raise TimeoutError('Other owned qualification campaigns did not settle before performance sampling')
            time.sleep(1)
    scenarios={
      'ui':[
        ('bindings', ['docs/System_Qualification_0.75_2026-10-09/Control_Bindings.ms'], None),
        ('layout', ['tools/procedural_lab/Max_Layout_075.ms'], 'L75Run()'),
        ('regions', ['tools/procedural_lab/Max_Layer_Regions_074.ms'], 'LRSetup();LRRun();LRViews();LRReopen();LRAdditional()'),
        ('manual-workflow', ['tools/procedural_lab/Max_Consolidation_075.ms'], 'C75Manual();C75Workflow();C75Spacing()'),
        ('grips', ['tools/procedural_lab/Max_UI_074_Grips.ms'], 'G074Run #main;G074Run #container;G074Run #popup;G074Lifecycle()'),
        ('sources', ['tools/procedural_lab/Max_System_075.ms'], 'Q75Sources()'),
        ('captions', ['tools/procedural_lab/Max_Captions_075.ms'], None),
        ('legacy', ['tools/procedural_lab/Max_Layer_Regions_074_Legacy.ms'], 'LRLegacyCheck @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/layer-regions-old-20261009-01/"'),
      ],
      'behavior':[
        ('containers', ['tools/procedural_lab/Max_Source_Containers_Acceptance.ms'], None),
        ('output', ['tools/procedural_lab/Max_Source_Containers_Output.ms'], None),
        ('edit-bindings', ['tools/procedural_lab/Max_Procedural_07_Bindings.ms'], None),
        ('publication', ['tools/procedural_lab/Max_Procedural_07_Regression.ms'], None),
        ('analyzer', ['tools/procedural_lab/Max_Unified_073_Analyzer_Assignment.ms'], 'U73AnalyzerAssignment()'),
        ('group-move', ['tools/procedural_lab/Max_Unified_073_Group_Move.ms'], 'U73GroupMove()'),
        ('node-move', ['tools/procedural_lab/Max_Unified_073_Node_Move.ms'], 'U73NodeMove()'),
        ('edit-persistence', ['tools/procedural_lab/Max_Unified_073_Persistence.ms'], 'U73EditPersistence()'),
        ('arrangement', ['docs/Arrangement_Research_0.75_2026-10-09/Probe.ms'], 'ARBasic();ARLine();ARAnalyzer();ARExtra()'),
        ('renderer-stop', ['tools/procedural_lab/Max_Corona_Stop_073.ms'], None),
      ],
      'performance':[
        ('navigation', ['tools/procedural_lab/Max_Unified_073_Navigation.ms'], 'P07Navigation "100k" 100000 frames:30 modes:#(0,1,2,3,4) containers:true'),
        ('playback', [], 'global PTDir=MCPFixtureDir,PTNativeExpected=#("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm");fileIn @"'+(ROOT/'tools/procedural_lab/Max_Playback_073_Regression.ms').as_posix()+'"'),
      ],
      'ui-remaining':[
        ('sources', ['tools/procedural_lab/Max_System_075.ms'], 'Q75Sources()'),
        ('captions', ['tools/procedural_lab/Max_Captions_075.ms'], None),
        ('grip-lifecycle', ['tools/procedural_lab/Max_UI_074_Grips.ms'], 'G074Lifecycle()'),
        ('legacy', ['tools/procedural_lab/Max_Layer_Regions_074.ms','tools/procedural_lab/Max_Layer_Regions_074_Legacy.ms'], 'LRChecks=#();LRLegacyCheck @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/layer-regions-old-20261009-01/"'),
        ('playback', [], 'global PTDir=MCPFixtureDir,PTNativeExpected=#("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm");fileIn @"'+(ROOT/'tools/procedural_lab/Max_Playback_073_Regression.ms').as_posix()+'"'),
      ],
      'retained':[
        ('display-repeat', [(folder/'playback-definitions.ms').relative_to(ROOT).as_posix()], 'global PTDir=MCPFixtureDir;PTLog=createFile (MCPFixtureDir+"retained-repeat.txt");try(PTDisplayModes();format "SUCCESS % assertions\\n" PTChecks to:PTLog;close PTLog)catch(close PTLog;throw())'),
        ('analyzer-playback', [], 'PTLog=createFile (MCPFixtureDir+"analyzer-playback.txt");try(fileIn @"'+(ROOT/'tools/procedural_lab/Max_Analyzer_Playback_073_Regression.ms').as_posix()+'";format "SUCCESS % cumulative assertions\\n" PTChecks to:PTLog;close PTLog)catch(close PTLog;throw())'),
      ],
      'lifecycle':[
        ('playback', [], 'global PTDir=MCPFixtureDir,PTNativeExpected=#("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm");fileIn @"'+(ROOT/'tools/procedural_lab/Max_Playback_073_Regression.ms').as_posix()+'"'),
      ]
    }[phase]
    results=[]
    for label,files,code in scenarios:
        row=dict(name=label,phase=phase,files={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in files},steps=[])
        if label=='playback':
            row['files']['tools/procedural_lab/Max_Playback_073_Regression.ms']=hashlib.sha256((ROOT/'tools/procedural_lab/Max_Playback_073_Regression.ms').read_bytes()).hexdigest()
            source=ROOT/'tools/procedural_lab/Max_Analyzer_Playback_073_Regression.ms'
            shutil.copy2(source,folder/'analyzer-fixture.ms')
            row['files'][source.relative_to(ROOT).as_posix()]=hashlib.sha256(source.read_bytes()).hexdigest()
        start=time.monotonic()
        try:
            for script in ['fileIn @"'+(ROOT/p).as_posix()+'"' for p in files]+([code] if code else []):
                result=run_script(folder,script,timeout=300)
                row['steps'].append(dict(code=script,result=result))
                if not result.startswith('SUCCESS '):raise RuntimeError(result)
            row['passed']=True
        except Exception as exc:
            row.update(passed=False,error=str(exc))
            # Timeout could leave a mutating request in flight; never issue another.
            if isinstance(exc,TimeoutError):raise
        finally:
            row['elapsed_s']=time.monotonic()-start
            results.append(row)
            dest=folder/('case-'+label);dest.mkdir(exist_ok=True)
            for p in folder.iterdir():
                if p.is_file() and p.suffix in ('.json','.txt','.tsv') and not p.name.startswith(('dev-','probe-')):
                    shutil.copy2(p,dest/p.name)
            (folder/'campaign.json').write_text(json.dumps(results,indent=2)+'\n')
            print(label+': '+('PASS' if row.get('passed') else row.get('error','FAIL')),flush=True)
    if phase in ('performance','ui-remaining','lifecycle'):
        # These clients perform bounded sampling and real renderer API calls.
        # They never use native UI automation or an artist profile.
        from live_idle_073_qualification import qualify as idle
        from corona_072_qualification import qualify as corona
        # Playback isolates timeline validity by disabling node-event batches.
        # Restore them before claiming ordinary idle/Live behavior.
        restored=run_script(folder,'AminScatterNodeEvents.enabled=true;CyrusAnalyzerEvents.enabled=true;P07Assert (AminScatterNodeEvents.enabled and CyrusAnalyzerEvents.enabled) "Node callbacks were not restored"',timeout=60)
        if not restored.startswith('SUCCESS '):raise RuntimeError(restored)
        operations=[] if phase=='lifecycle' else [('idle',lambda:idle(folder,integrated=True))]
        operations.append(('corona',lambda:corona(folder)))
        for label,operation in operations:
            row=dict(name=label,phase=phase)
            try:operation();row['passed']=True
            except Exception as exc:row.update(passed=False,error=str(exc))
            results.append(row)
            (folder/'campaign.json').write_text(json.dumps(results,indent=2)+'\n')
            print(label+': '+('PASS' if row['passed'] else row['error']),flush=True)
            if not row['passed']:break
    if not all(r['passed'] for r in results):raise SystemExit(1)


if __name__=='__main__':main()
